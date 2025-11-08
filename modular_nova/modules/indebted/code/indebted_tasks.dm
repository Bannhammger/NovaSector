/datum/indebted_task
	var/name = "Generic Task"
	var/description = "Do something"
	var/datum/antagonist/indebted/owner
	var/completed = FALSE
	var/failed = FALSE
	var/task_type = TASK_TYPE_STAY_AREA
	var/area/target_area
	var/obj/item/target_item
	var/task_timer
	var/time_limit = 5 MINUTES

/datum/indebted_task/New(datum/antagonist/indebted/indebted_owner)
	owner = indebted_owner
	generate_task()

/datum/indebted_task/proc/generate_task()
	task_type = pick(
		TASK_TYPE_STAY_AREA,
		TASK_TYPE_HOLD_ITEM,
		TASK_TYPE_STEAL_ITEM
	)

	switch(task_type)
		if(TASK_TYPE_STAY_AREA)
			generate_stay_area_task()
		if(TASK_TYPE_HOLD_ITEM)
			generate_hold_item_task()
		if(TASK_TYPE_STEAL_ITEM)
			generate_steal_item_task()

/datum/indebted_task/proc/generate_stay_area_task()
	var/list/valid_areas = list()
	for(var/area/A in GLOB.areas)
		if(!(A.type in GLOB.the_station_areas))
			continue
		if(A.outdoors)
			continue
		if(istype(A, /area/shuttle))
			continue
		valid_areas += A

	if(valid_areas.len > 0)
		target_area = pick(valid_areas)
		name = "Stay in Area"
		description = "Remain in [target_area.name] for [time_limit / 600] minutes without leaving."
		time_limit = rand(3 MINUTES, 8 MINUTES)

/datum/indebted_task/proc/generate_hold_item_task()
	var/list/valid_items = list(
		/obj/item/stack/spacecash,
		/obj/item/coin,
		/obj/item/reagent_containers/food/drinks/bottle,
		/obj/item/toy,
		/obj/item/paper,
		/obj/item/clothing/glasses,
		/obj/item/clothing/gloves,
		/obj/item/clothing/shoes,
	)

	var/item_type = pick(valid_items)
	var/obj/item/template = new item_type()
	name = "Hold Item"
	description = "Carry a [template.name] on your person for [time_limit / 600] minutes."
	target_item = template
	time_limit = rand(5 MINUTES, 10 MINUTES)

/datum/indebted_task/proc/generate_steal_item_task()
	var/list/valid_steal_items = list(
		/obj/item/stack/spacecash,
		/obj/item/coin,
		/obj/item/reagent_containers/food/drinks/bottle,
		/obj/item/toy,
		/obj/item/paper,
		/obj/item/clothing/glasses,
		/obj/item/clothing/gloves,
		/obj/item/clothing/shoes,
		/obj/item/pda,
		/obj/item/radio,
	)

	var/item_type = pick(valid_steal_items)
	var/obj/item/template = new item_type()
	name = "Steal and Hold Item"
	description = "Steal a [template.name] and keep it on your person for [time_limit / 600] minutes."
	target_item = template
	time_limit = rand(8 MINUTES, 15 MINUTES)
	qdel(template)

/datum/indebted_task/proc/start()
	if(!owner || !owner.owner || !owner.owner.current)
		return

	owner.current_task = src
	to_chat(owner.owner.current, span_boldnotice("New Task: [name]"))
	to_chat(owner.owner.current, span_notice("[description]"))

	task_timer = addtimer(CALLBACK(src, PROC_REF(check_completion)), time_limit, TIMER_STOPPABLE)

	// Start checking periodically
	START_PROCESSING(SSprocessing, src)

/datum/indebted_task/process(seconds_per_tick)
	if(!owner || !owner.owner || !owner.owner.current)
		fail()
		return PROCESS_KILL

	if(completed || failed)
		return PROCESS_KILL

	check_task_progress()
	return

/datum/indebted_task/proc/check_task_progress()
	if(!owner || !owner.owner || !owner.owner.current)
		fail()
		return

	var/mob/living/carbon/human/H = owner.owner.current

	switch(task_type)
		if(TASK_TYPE_STAY_AREA)
			var/area/current_area = get_area(H)
			if(!istype(current_area, target_area.type))
				fail()
				return

		if(TASK_TYPE_HOLD_ITEM)
			if(!target_item)
				return
			var/has_item = FALSE
			var/list/all_items = H.get_all_contents()
			for(var/obj/item/I in all_items)
				if(istype(I, target_item.type))
					has_item = TRUE
					break
			if(!has_item)
				fail()
				return

		if(TASK_TYPE_STEAL_ITEM)
			if(!target_item)
				return
			var/has_item = FALSE
			var/list/all_items = H.get_all_contents()
			for(var/obj/item/I in all_items)
				if(istype(I, target_item.type))
					has_item = TRUE
					break
			if(!has_item)
				fail()
				return

/datum/indebted_task/proc/check_completion()
	if(completed || failed)
		return

	// Final check
	check_task_progress()

	if(!failed)
		complete()

/datum/indebted_task/proc/complete()
	if(completed || failed)
		return

	completed = TRUE
	STOP_PROCESSING(SSprocessing, src)

	if(task_timer)
		deltimer(task_timer)

	if(owner)
		owner.completed_tasks += src
		owner.on_task_completed()

	to_chat(owner.owner.current, span_green("Task completed: [name]"))

/datum/indebted_task/proc/fail()
	if(completed || failed)
		return

	failed = TRUE
	STOP_PROCESSING(SSprocessing, src)

	if(task_timer)
		deltimer(task_timer)

	if(owner)
		owner.on_task_failed()

	to_chat(owner.owner.current, span_red("Task failed: [name]"))

/datum/indebted_task/Destroy()
	STOP_PROCESSING(SSprocessing, src)
	if(task_timer)
		deltimer(task_timer)
	if(target_item)
		QDEL_NULL(target_item)
	return ..()

/datum/indebted_task_handler
	var/datum/antagonist/indebted/owner

/datum/indebted_task_handler/New(datum/antagonist/indebted/indebted_owner)
	owner = indebted_owner

/datum/indebted_task_handler/proc/create_new_task()
	if(!owner || owner.debt_paid)
		return

	var/datum/indebted_task/new_task = new(owner)
	new_task.start()

// Task type defines
#define TASK_TYPE_STAY_AREA "stay_area"
#define TASK_TYPE_HOLD_ITEM "hold_item"
#define TASK_TYPE_STEAL_ITEM "steal_item"

