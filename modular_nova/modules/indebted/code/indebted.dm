/datum/antagonist/indebted
	name = "\improper Indebted"
	roundend_category = "indebted"
	antagpanel_category = "Traitor"
	pref_flag = ROLE_INDEBTED
	antag_moodlet = /datum/mood_event/focused
	antag_hud_name = "traitor"
	ui_name = "AntagInfoIndebted"
	suicide_cry = "I'M FREE!!"
	preview_outfit = /datum/outfit/traitor

	/// The target we need to headhunt
	var/datum/mind/target
	/// Current task we're working on
	var/datum/indebted_task/current_task
	/// List of completed tasks
	var/list/datum/indebted_task/completed_tasks = list()
	/// List of hints we've received about our target
	var/list/hints_received = list()
	/// Number of strikes (out of 3)
	var/strikes = 0
	/// Whether we've completed our objective (killed target)
	var/debt_paid = FALSE
	/// Timer for next task
	var/task_timer
	/// Reference to our task handler
	var/datum/indebted_task_handler/task_handler

/datum/antagonist/indebted/on_gain()
	. = ..()

	// Find a target
	forge_target()

	// Give clandestine gear
	give_clandestine_gear()

	// Create task handler
	task_handler = new(src)

	// Start first task after a delay
	addtimer(CALLBACK(src, PROC_REF(give_first_task)), 3 MINUTES)

/datum/antagonist/indebted/on_removal()
	if(task_handler)
		QDEL_NULL(task_handler)
	if(task_timer)
		deltimer(task_timer)
	if(target?.current)
		UnregisterSignal(target.current, COMSIG_LIVING_DEATH)
	return ..()

/datum/antagonist/indebted/proc/on_target_death(mob/living/dead_guy, gibbed)
	SIGNAL_HANDLER
	debt_paid = TRUE
	to_chat(owner.current, span_green("Your debt has been paid! You are free."))
	// Cancel any ongoing tasks
	if(task_timer)
		deltimer(task_timer)
	if(current_task)
		current_task.fail()
		current_task = null

/datum/antagonist/indebted/proc/forge_target()
	var/list/possible_targets = list()
	for(var/datum/mind/possible_target in get_crewmember_minds())
		if(possible_target == owner)
			continue
		if(!ishuman(possible_target.current))
			continue
		if(possible_target.current.stat == DEAD)
			continue
		if(possible_target.has_antag_datum(/datum/antagonist/indebted))
			continue
		if(possible_target.has_antag_datum(/datum/antagonist/debt_enforcer))
			continue
		possible_targets += possible_target

	if(possible_targets.len > 0)
		target = pick(possible_targets)
		var/datum/objective/assassinate/kill_objective = new()
		kill_objective.owner = owner
		kill_objective.target = target
		kill_objective.update_explanation_text()
		objectives += kill_objective

		// Register signal to detect when target dies
		if(target.current)
			RegisterSignal(target.current, COMSIG_LIVING_DEATH, PROC_REF(on_target_death))
	else
		// No valid targets, give a free objective
		var/datum/objective/custom/free_objective = new()
		free_objective.owner = owner
		free_objective.explanation_text = "Your target could not be found. You are free from your debt."
		objectives += free_objective
		debt_paid = TRUE

/datum/antagonist/indebted/proc/give_clandestine_gear()
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

	// Suppressor (in case they want to silence other weapons)
	var/obj/item/suppressor/suppressor = new()
	if(!H.equip_to_slot_if_possible(suppressor, ITEM_SLOT_BACKPACK))
		suppressor.forceMove(get_turf(H))

/datum/antagonist/indebted/proc/give_first_task()
	if(debt_paid || !owner.current)
		return
	task_handler.create_new_task()

/datum/antagonist/indebted/proc/on_task_completed()
	if(debt_paid || !owner.current)
		return

	// Give a hint
	give_hint()

	// Schedule next task after 3 minutes
	task_timer = addtimer(CALLBACK(src, PROC_REF(give_next_task)), 3 MINUTES, TIMER_STOPPABLE)

/datum/antagonist/indebted/proc/give_next_task()
	if(debt_paid || !owner.current)
		return
	task_handler.create_new_task()

/datum/antagonist/indebted/proc/on_task_failed()
	if(debt_paid || !owner.current)
		return

	// Give hint to enforcers
	notify_enforcers()

	// Check if we have enforcers
	var/has_enforcers = FALSE
	for(var/datum/mind/M in get_crewmember_minds())
		if(M.has_antag_datum(/datum/antagonist/debt_enforcer))
			has_enforcers = TRUE
			break

	if(!has_enforcers)
		// No enforcers, give a strike
		strikes++
		to_chat(owner.current, span_boldwarning("You have failed a task. Strike [strikes]/3."))

		if(strikes >= 3)
			apply_punishment()
	else
		to_chat(owner.current, span_warning("You have failed a task. Your employers are not pleased..."))

/datum/antagonist/indebted/proc/notify_enforcers()
	if(!target)
		return

	for(var/datum/mind/M in get_crewmember_minds())
		var/datum/antagonist/debt_enforcer/enforcer = M.has_antag_datum(/datum/antagonist/debt_enforcer)
		if(enforcer)
			enforcer.receive_hint_about_indebted(src)

/datum/antagonist/indebted/proc/give_hint()
	if(!target || !target.current)
		return

	var/hint = generate_hint()
	if(hint)
		hints_received += hint
		to_chat(owner.current, span_notice("<b>New hint about your target:</b> [hint]"))

/datum/antagonist/indebted/proc/generate_hint()
	if(!target || !target.current)
		return null

	var/mob/living/carbon/human/target_mob = target.current
	if(!ishuman(target_mob))
		return null

	var/list/very_useful_hints = list()
	var/list/maybe_useful_hints = list()
	var/list/not_helpful_hints = list()

	// Very useful hints
	if(target_mob.dna?.species)
		var/datum/species/species = target_mob.dna.species
		very_useful_hints += "[target_mob.name] is of the species [species.name]."

	if(target.assigned_role)
		very_useful_hints += "[target_mob.name] is a [target.assigned_role.title]."

	// Maybe useful hints
	if(target_mob.wear_suit)
		maybe_useful_hints += "[target_mob.name] was last seen wearing [target_mob.wear_suit.name]."

	if(target.assigned_role)
		var/datum/job/job = SSjob.GetJob(target.assigned_role.title)
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
				maybe_useful_hints += "[target_mob.name] is part of [english_list(dept_list)]."

	// Check for quirks
	if(target_mob.mind)
		for(var/datum/quirk/Q in target_mob.mind.quirks)
			maybe_useful_hints += "[target_mob.name] carries the quirk [Q.name]."
			break // Only one quirk hint

	// Check if they're an antag
	for(var/datum/antagonist/antag in target.antag_datums)
		if(antag.show_in_roundend)
			maybe_useful_hints += "[target_mob.name] is a [antag.name]."
			break

	// Check if oversized
	if(target_mob.dna?.features["body_size"])
		var/body_size = target_mob.dna.features["body_size"]
		if(body_size > 1)
			maybe_useful_hints += "[target_mob.name] is oversized."
		else
			not_helpful_hints += "[target_mob.name] is not oversized."

	// Not helpful hints
	if(target_mob.held_items[1])
		var/obj/item/held = target_mob.held_items[1]
		if(held)
			not_helpful_hints += "[target_mob.name] was last seen holding [held.name]."

	var/area/target_area = get_area(target_mob)
	if(target_area)
		not_helpful_hints += "[target_mob.name] was last seen in [target_area.name]."

	// Pronouns
	if(target_mob.client?.prefs)
		var/pronouns = target_mob.client.prefs.read_preference(/datum/preference/text/pronouns)
		if(pronouns)
			maybe_useful_hints += "[target_mob.name] goes by [pronouns]."

	// Weighted selection based on task completion
	var/task_count = completed_tasks.len
	var/very_useful_weight = min(30 + (task_count * 10), 80)
	var/maybe_useful_weight = 50
	var/not_helpful_weight = max(50 - (task_count * 5), 20)

	var/list/selected_pool = list()
	if(very_useful_hints.len > 0 && prob(very_useful_weight))
		selected_pool = very_useful_hints
	else if(maybe_useful_hints.len > 0 && prob(maybe_useful_weight))
		selected_pool = maybe_useful_hints
	else if(not_helpful_hints.len > 0)
		selected_pool = not_helpful_hints

	if(selected_pool.len == 0)
		// Fallback
		if(very_useful_hints.len > 0)
			selected_pool = very_useful_hints
		else if(maybe_useful_hints.len > 0)
			selected_pool = maybe_useful_hints
		else if(not_helpful_hints.len > 0)
			selected_pool = not_helpful_hints

	if(selected_pool.len > 0)
		return pick(selected_pool)

	return null

/datum/antagonist/indebted/proc/apply_punishment()
	var/mob/living/carbon/human/H = owner.current
	if(!ishuman(H))
		return

	// Check preference flags (we'll need to add these)
	// For now, randomly pick one
	var/punishment_type = pick(
		"police_warrant",
		"neural_failure",
		"implanted_termination"
	)

	switch(punishment_type)
		if("police_warrant")
			apply_police_warrant()
		if("neural_failure")
			apply_neural_failure()
		if("implanted_termination")
			apply_implanted_termination()

/datum/antagonist/indebted/proc/apply_police_warrant()
	// TODO: Implement Spacepol/Solfed warrant system
	to_chat(owner.current, span_boldwarning("An anonymous tip has been sent to security about your activities!"))

/datum/antagonist/indebted/proc/apply_neural_failure()
	var/mob/living/carbon/human/H = owner.current
	if(!ishuman(H))
		return

	// Give a debilitating brain trauma
	var/obj/item/organ/brain/brain = H.get_organ_slot(ORGAN_SLOT_BRAIN)
	if(brain)
		brain.apply_organ_damage(50) // Significant damage
		to_chat(H, span_boldwarning("You feel a sharp pain in your head! Your neural pathways have been damaged!"))

/datum/antagonist/indebted/proc/apply_implanted_termination()
	var/mob/living/carbon/human/H = owner.current
	if(!ishuman(H))
		return

	// Instant death via electroshock
	H.electrocute_act(200, "Debt Enforcement Implant", 1, TRUE)
	H.apply_damage(200, BURN, BODY_ZONE_HEAD)

	// If revived, they'll be slurred
	ADD_TRAIT(H, TRAIT_SLURRED_SPEECH, "debt_enforcement")

	to_chat(H, span_boldwarning("Your debt enforcement implant activates!"))

/datum/antagonist/indebted/forge_objectives()
	// Objectives are created in forge_target()
	return

/datum/antagonist/indebted/greet()
	. = ..()
	to_chat(owner.current, span_boldwarning("You are indebted to someone or a group of someones. You have a target to headhunt, but you don't know their name."))
	to_chat(owner.current, span_notice("Who you owe doesn't matter. What does is completing the job before the enforcers find you."))
	to_chat(owner.current, span_notice("You are a regular crew member, but you must complete tasks for your employers every 3 minutes to get hints about your target."))
	to_chat(owner.current, span_notice("Failure to complete tasks will give hints to debt enforcers hunting you."))
	to_chat(owner.current, span_warning("You can only kill your target. Any other kills will alert your employers."))
	to_chat(owner.current, span_danger("Your activities are illegal. Keep them hidden from security."))
	owner.announce_objectives()

/datum/antagonist/indebted/roundend_report()
	var/list/result = list()
	result += printplayer(owner)

	result += "<br>[owner.name] <B>was indebted to unknown parties and operating outside official jurisdiction.</B>"

	var/target_name = target?.current ? target.current.name : "Unknown"
	result += "<br>Target: [target_name]"

	if(debt_paid)
		result += span_greentext("Debt paid - target eliminated!")
	else
		result += span_redtext("Debt unpaid - target still alive")

	result += "<br>Tasks completed: [completed_tasks.len]"
	result += "<br>Strikes: [strikes]/3"

	if(hints_received.len > 0)
		result += "<br>Hints received:"
		for(var/hint in hints_received)
			result += "<br>  - [hint]"

	return result.Join("<br>")

