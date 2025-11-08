/datum/antagonist/debt_enforcer
	name = "\improper Debt Enforcer"
	roundend_category = "debt enforcers"
	antagpanel_category = "Traitor"
	pref_flag = ROLE_DEBT_ENFORCER
	antag_moodlet = /datum/mood_event/focused
	antag_hud_name = "traitor"
	ui_name = "AntagInfoDebtEnforcer"
	suicide_cry = "JUSTICE IS SERVED!!"
	preview_outfit = /datum/outfit/traitor
	/// Ambiguous employer description
	var/employer_description = "The Bounty Collective"

	/// List of Indebted we're tracking
	var/list/datum/antagonist/indebted/tracked_indebted = list()
	/// Hints we've received about each Indebted
	var/list/hints_by_indebted = list()
	/// Current task we're working on
	var/datum/enforcer_task/current_task
	/// List of completed tasks
	var/list/datum/enforcer_task/completed_tasks = list()
	/// Timer for next task
	var/task_timer
	/// Reference to our task handler
	var/datum/enforcer_task_handler/task_handler

/datum/antagonist/debt_enforcer/on_gain()
	. = ..()

	// Find all Indebted
	find_indebted()

	// Give clandestine gear
	give_clandestine_gear()

	// Create task handler
	task_handler = new(src)

	// Start first task after a delay
	addtimer(CALLBACK(src, PROC_REF(give_first_task)), 10 MINUTES)

/datum/antagonist/debt_enforcer/proc/find_indebted()
	for(var/datum/mind/M in get_crewmember_minds())
		var/datum/antagonist/indebted/indebted = M.has_antag_datum(/datum/antagonist/indebted)
		if(indebted && !indebted.debt_paid)
			tracked_indebted += indebted
			hints_by_indebted[indebted] = list()

/datum/antagonist/debt_enforcer/proc/give_clandestine_gear()
	if(!ishuman(owner.current))
		return

	var/mob/living/carbon/human/H = owner.current

	// Silenced Makarov
	var/obj/item/gun/ballistic/automatic/pistol/suppressed/silenced = new()
	if(!H.equip_to_slot_if_possible(silenced, ITEM_SLOT_BACKPACK))
		if(!H.equip_to_slot_if_possible(silenced, ITEM_SLOT_HANDS))
			silenced.forceMove(get_turf(H))

	// Sleepy pen
	var/obj/item/pen/sleepy/sleepy_pen = new()
	if(!H.equip_to_slot_if_possible(sleepy_pen, ITEM_SLOT_BACKPACK))
		if(!H.equip_to_slot_if_possible(sleepy_pen, ITEM_SLOT_HANDS))
			sleepy_pen.forceMove(get_turf(H))

	// Suppressor
	var/obj/item/suppressor/suppressor = new()
	if(!H.equip_to_slot_if_possible(suppressor, ITEM_SLOT_BACKPACK))
		suppressor.forceMove(get_turf(H))

/datum/antagonist/debt_enforcer/proc/receive_hint_about_indebted(datum/antagonist/indebted/indebted_target)
	if(!indebted_target || indebted_target.debt_paid)
		return

	if(!(indebted_target in tracked_indebted))
		tracked_indebted += indebted_target
		hints_by_indebted[indebted_target] = list()

	var/hint = generate_hint_about_indebted(indebted_target)
	if(hint)
		hints_by_indebted[indebted_target] += hint

		// Find which indebted this is
		var/debt_number = tracked_indebted.Find(indebted_target)
		to_chat(owner.current, span_notice("<b>New hint about Debt [debt_number]:</b> [hint]"))

/datum/antagonist/debt_enforcer/proc/generate_hint_about_indebted(datum/antagonist/indebted/indebted_target)
	if(!indebted_target || !indebted_target.owner || !indebted_target.owner.current)
		return null

	var/mob/living/carbon/human/indebted_mob = indebted_target.owner.current
	if(!ishuman(indebted_mob))
		return null

	var/list/possible_hints = list()

	// Job/role hints
	if(indebted_target.owner.assigned_role)
		possible_hints += "Target is a [indebted_target.owner.assigned_role.title]."

	// Department hints
	if(indebted_target.owner.assigned_role)
		var/datum/job/job = SSjob.GetJob(indebted_target.owner.assigned_role.title)
		if(job?.departments_bitflags)
			var/list/dept_list = list()
			if(job.departments_bitflags & DEPARTMENT_BITFLAG_SERVICE)
				dept_list += "Service"
			if(job.departments_bitflags & DEPARTMENT_BITFLAG_SUPPLY)
				dept_list += "Supply"
			if(job.departments_bitflags & DEPARTMENT_BITFLAG_SCIENCE)
				dept_list += "Science"
			if(job.departments_bitflags & DEPARTMENT_BITFLAG_SECURITY)
				dept_list += "Security"
			if(job.departments_bitflags & DEPARTMENT_BITFLAG_ENGINEERING)
				dept_list += "Engineering"
			if(job.departments_bitflags & DEPARTMENT_BITFLAG_MEDICAL)
				dept_list += "Medical"
			if(job.departments_bitflags & DEPARTMENT_BITFLAG_COMMAND)
				dept_list += "Command"
			if(dept_list.len > 0)
				possible_hints += "Target is part of [english_list(dept_list)]."

	// Clothing hints
	if(indebted_mob.wear_suit)
		possible_hints += "Target is wearing a [indebted_mob.wear_suit.name]."
	if(indebted_mob.w_uniform)
		possible_hints += "Target is wearing a [indebted_mob.w_uniform.name]."

	// Species hints
	if(indebted_mob.dna?.species)
		var/datum/species/species = indebted_mob.dna.species
		possible_hints += "Target is of the species [species.name]."

	// Location hints
	var/area/current_area = get_area(indebted_mob)
	if(current_area)
		possible_hints += "Target was last seen in [current_area.name]."

	// Pronouns
	if(indebted_mob.client?.prefs)
		var/pronouns = indebted_mob.client.prefs.read_preference(/datum/preference/text/pronouns)
		if(pronouns)
			possible_hints += "Target goes by [pronouns]."

	if(possible_hints.len > 0)
		return pick(possible_hints)

	return null

/datum/antagonist/debt_enforcer/forge_objectives()
	// Create objectives to eliminate each Indebted
	for(var/datum/antagonist/indebted/indebted_target in tracked_indebted)
		if(indebted_target.debt_paid)
			continue

		var/datum/objective/assassinate/kill_objective = new()
		kill_objective.owner = owner
		kill_objective.target = indebted_target.owner
		kill_objective.update_explanation_text()
		objectives += kill_objective

/datum/antagonist/debt_enforcer/on_removal()
	if(task_handler)
		QDEL_NULL(task_handler)
	if(task_timer)
		deltimer(task_timer)
	return ..()

/datum/antagonist/debt_enforcer/proc/give_first_task()
	if(!owner.current)
		return
	// Only give tasks if there are active Indebted
	var/has_active_indebted = FALSE
	for(var/datum/antagonist/indebted/indebted_target in tracked_indebted)
		if(!indebted_target.debt_paid && indebted_target.owner?.current)
			has_active_indebted = TRUE
			break

	if(has_active_indebted)
		task_handler.create_new_task()

/datum/antagonist/debt_enforcer/proc/on_task_completed()
	if(!owner.current)
		return

	// Give a hint about one of the Indebted
	give_task_hint()

	// Schedule next task after 10 minutes
	task_timer = addtimer(CALLBACK(src, PROC_REF(give_next_task)), 10 MINUTES, TIMER_STOPPABLE)

/datum/antagonist/debt_enforcer/proc/give_next_task()
	if(!owner.current)
		return

	// Only give tasks if there are active Indebted
	var/has_active_indebted = FALSE
	for(var/datum/antagonist/indebted/indebted_target in tracked_indebted)
		if(!indebted_target.debt_paid && indebted_target.owner?.current)
			has_active_indebted = TRUE
			break

	if(has_active_indebted)
		task_handler.create_new_task()

/datum/antagonist/debt_enforcer/proc/give_task_hint()
	if(tracked_indebted.len == 0)
		return

	// Pick a random Indebted to give a hint about
	var/datum/antagonist/indebted/target_indebted = pick(tracked_indebted)
	if(target_indebted && !target_indebted.debt_paid)
		var/hint = generate_hint_about_indebted(target_indebted)
		if(hint)
			if(!(target_indebted in hints_by_indebted))
				hints_by_indebted[target_indebted] = list()
			hints_by_indebted[target_indebted] += hint

			var/debt_number = tracked_indebted.Find(target_indebted)
			to_chat(owner.current, span_notice("<b>New hint about Debt [debt_number] (from task):</b> [hint]"))

/datum/antagonist/debt_enforcer/greet()
	. = ..()
	to_chat(owner.current, span_boldwarning("You are a debt enforcer - an unpermitted bounty hunter operating outside Nanotrasen and SolFed jurisdiction."))
	to_chat(owner.current, span_notice("Who hired you doesn't matter. What does is if you can get the job done."))
	to_chat(owner.current, span_notice("You are a regular crew member, but you must complete investigation tasks every 10 minutes to narrow down suspects."))
	to_chat(owner.current, span_notice("You will receive hints about the indebted whenever they fail their tasks, and from completing your own investigation tasks."))
	to_chat(owner.current, span_warning("If an indebted completes their objective (kills their target), they are free and you cannot hunt them anymore."))
	to_chat(owner.current, span_danger("Your activities are illegal. Keep them hidden from security."))
	owner.announce_objectives()

/datum/antagonist/debt_enforcer/roundend_report()
	var/list/result = list()
	result += printplayer(owner)

	result += "<br>[owner.name] <B>was an unpermitted debt enforcer operating outside official jurisdiction.</B>"

	result += "<br>Tracked Indebted: [tracked_indebted.len]"

	var/eliminated_count = 0
	for(var/datum/antagonist/indebted/indebted_target in tracked_indebted)
		if(!considered_alive(indebted_target.owner))
			eliminated_count++
		else if(indebted_target.debt_paid)
			result += "<br>  - [indebted_target.owner.current?.name || "Unknown"]: Debt paid, target eliminated"

	result += "<br>Eliminated: [eliminated_count]/[tracked_indebted.len]"
	result += "<br>Investigation tasks completed: [completed_tasks.len]"

	if(hints_by_indebted.len > 0)
		result += "<br>Hints received:"
		for(var/datum/antagonist/indebted/indebted_target in hints_by_indebted)
			var/debt_number = tracked_indebted.Find(indebted_target)
			result += "<br>  Debt [debt_number]:"
			for(var/hint in hints_by_indebted[indebted_target])
				result += "<br>    - [hint]"

	return result.Join("<br>")

