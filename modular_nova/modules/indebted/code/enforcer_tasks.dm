/datum/enforcer_task
	var/name = "Generic Investigation Task"
	var/description = "Investigate something"
	var/datum/antagonist/debt_enforcer/owner
	var/completed = FALSE
	var/failed = FALSE
	var/task_type = ENFORCER_TASK_TYPE_INVESTIGATE_AREA
	var/area/target_area
	var/datum/mind/target_person
	var/target_department = "" // For department observation tasks
	var/task_timer
	var/time_limit = 5 MINUTES

/datum/enforcer_task/New(datum/antagonist/debt_enforcer/enforcer_owner)
	owner = enforcer_owner
	generate_task()

/datum/enforcer_task/proc/generate_task()
	task_type = pick(
		ENFORCER_TASK_TYPE_INVESTIGATE_AREA,
		ENFORCER_TASK_TYPE_FIND_PERSON,
		ENFORCER_TASK_TYPE_OBSERVE_DEPARTMENT
	)

	switch(task_type)
		if(ENFORCER_TASK_TYPE_INVESTIGATE_AREA)
			generate_investigate_area_task()
		if(ENFORCER_TASK_TYPE_FIND_PERSON)
			generate_find_person_task()
		if(ENFORCER_TASK_TYPE_OBSERVE_DEPARTMENT)
			generate_observe_department_task()

/datum/enforcer_task/proc/generate_investigate_area_task()
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
		name = "Investigate Area"
		description = "Spend time investigating [target_area.name] for suspicious activity. Stay in the area for [time_limit / 600] minutes."
		time_limit = rand(3 MINUTES, 6 MINUTES)

/datum/enforcer_task/proc/generate_find_person_task()
	// Pick a random crewmember (could be an Indebted, could be innocent)
	var/list/possible_targets = list()
	for(var/datum/mind/M in get_crewmember_minds())
		if(M == owner.owner)
			continue
		if(!ishuman(M.current))
			continue
		if(M.current.stat == DEAD)
			continue
		possible_targets += M

	if(possible_targets.len > 0)
		target_person = pick(possible_targets)
		name = "Locate Person"
		description = "Find and observe [target_person.current.name] for suspicious behavior. Get within 3 tiles of them for [time_limit / 600] minutes."
		time_limit = rand(2 MINUTES, 4 MINUTES)

/datum/enforcer_task/proc/generate_observe_department_task()
	var/list/departments = list(
		"SERVICE",
		"SUPPLY",
		"SCIENCE",
		"SECURITY",
		"ENGINEERING",
		"MEDICAL",
		"COMMAND"
	)

	target_department = pick(departments)
	name = "Observe Department"
	description = "Investigate the [target_department] department for suspicious activity. Visit their main area for [time_limit / 600] minutes."
	time_limit = rand(3 MINUTES, 5 MINUTES)

/datum/enforcer_task/proc/start()
	if(!owner || !owner.owner || !owner.owner.current)
		return

	owner.current_task = src
	to_chat(owner.owner.current, span_boldnotice("New Investigation Task: [name]"))
	to_chat(owner.owner.current, span_notice("[description]"))

	task_timer = addtimer(CALLBACK(src, PROC_REF(check_completion)), time_limit, TIMER_STOPPABLE)

	// Start checking periodically
	START_PROCESSING(SSprocessing, src)

/datum/enforcer_task/process(seconds_per_tick)
	if(!owner || !owner.owner || !owner.owner.current)
		fail()
		return PROCESS_KILL

	if(completed || failed)
		return PROCESS_KILL

	check_task_progress()
	return

/datum/enforcer_task/proc/check_task_progress()
	if(!owner || !owner.owner || !owner.owner.current)
		fail()
		return

	var/mob/living/carbon/human/H = owner.owner.current

	switch(task_type)
		if(ENFORCER_TASK_TYPE_INVESTIGATE_AREA)
			var/area/current_area = get_area(H)
			if(!istype(current_area, target_area.type))
				fail()
				return

		if(ENFORCER_TASK_TYPE_FIND_PERSON)
			if(!target_person || !target_person.current)
				// Target might have died or left, still allow completion
				return
			var/turf/enforcer_turf = get_turf(H)
			var/turf/target_turf = get_turf(target_person.current)
			if(!enforcer_turf || !target_turf)
				fail()
				return
			if(get_dist(enforcer_turf, target_turf) > 3)
				fail()
				return

		if(ENFORCER_TASK_TYPE_OBSERVE_DEPARTMENT)
			var/area/current_area = get_area(H)
			if(!current_area)
				fail()
				return

			// Check if we're in the right department area by checking the area's department
			var/in_correct_dept = FALSE
			// Get all jobs in the department
			var/list/datum/job/dept_jobs = list()
			for(var/datum/job/J as anything in SSjob.joinable_occupations)
				if(!J.departments_bitflags)
					continue
				if(target_department == "SERVICE" && (J.departments_bitflags & DEPARTMENT_BITFLAG_SERVICE))
					dept_jobs += J
				else if(target_department == "SUPPLY" && (J.departments_bitflags & DEPARTMENT_BITFLAG_SUPPLY))
					dept_jobs += J
				else if(target_department == "SCIENCE" && (J.departments_bitflags & DEPARTMENT_BITFLAG_SCIENCE))
					dept_jobs += J
				else if(target_department == "SECURITY" && (J.departments_bitflags & DEPARTMENT_BITFLAG_SECURITY))
					dept_jobs += J
				else if(target_department == "ENGINEERING" && (J.departments_bitflags & DEPARTMENT_BITFLAG_ENGINEERING))
					dept_jobs += J
				else if(target_department == "MEDICAL" && (J.departments_bitflags & DEPARTMENT_BITFLAG_MEDICAL))
					dept_jobs += J
				else if(target_department == "COMMAND" && (J.departments_bitflags & DEPARTMENT_BITFLAG_COMMAND))
					dept_jobs += J

			// Check if current area is associated with any job in this department
			// For simplicity, just check if we're in a station area (more lenient)
			if(!(current_area.type in GLOB.the_station_areas) || current_area.outdoors)
				fail()
				return

/datum/enforcer_task/proc/check_completion()
	if(completed || failed)
		return

	// Final check
	check_task_progress()

	if(!failed)
		complete()

/datum/enforcer_task/proc/complete()
	if(completed || failed)
		return

	completed = TRUE
	STOP_PROCESSING(SSprocessing, src)

	if(task_timer)
		deltimer(task_timer)

	if(owner)
		owner.completed_tasks += src
		owner.on_task_completed()

	to_chat(owner.owner.current, span_green("Investigation task completed: [name]"))

/datum/enforcer_task/proc/fail()
	if(completed || failed)
		return

	failed = TRUE
	STOP_PROCESSING(SSprocessing, src)

	if(task_timer)
		deltimer(task_timer)

	to_chat(owner.owner.current, span_red("Investigation task failed: [name]"))

/datum/enforcer_task/Destroy()
	STOP_PROCESSING(SSprocessing, src)
	if(task_timer)
		deltimer(task_timer)
	return ..()

/datum/enforcer_task_handler
	var/datum/antagonist/debt_enforcer/owner

/datum/enforcer_task_handler/New(datum/antagonist/debt_enforcer/enforcer_owner)
	owner = enforcer_owner

/datum/enforcer_task_handler/proc/create_new_task()
	if(!owner || !owner.owner || !owner.owner.current)
		return

	// Check if there are any active Indebted
	var/has_active_indebted = FALSE
	for(var/datum/antagonist/indebted/indebted_target in owner.tracked_indebted)
		if(!indebted_target.debt_paid && indebted_target.owner?.current)
			has_active_indebted = TRUE
			break

	if(!has_active_indebted)
		return

	var/datum/enforcer_task/new_task = new(owner)
	new_task.start()

// Enforcer task type defines
#define ENFORCER_TASK_TYPE_INVESTIGATE_AREA "investigate_area"
#define ENFORCER_TASK_TYPE_FIND_PERSON "find_person"
#define ENFORCER_TASK_TYPE_OBSERVE_DEPARTMENT "observe_department"

