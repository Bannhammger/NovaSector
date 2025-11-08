/datum/dynamic_ruleset/roundstart/indebted
	name = "Indebted"
	config_tag = "Roundstart Indebted"
	preview_antag_datum = /datum/antagonist/indebted
	pref_flag = ROLE_INDEBTED
	weight = 5
	min_pop = 5
	max_antag_cap = list("denominator" = 30)

/datum/dynamic_ruleset/roundstart/indebted/assign_role(datum/mind/candidate)
	candidate.add_antag_datum(/datum/antagonist/indebted)

/datum/dynamic_ruleset/midround/from_living/debt_enforcer
	name = "Debt Enforcer"
	config_tag = "Midround Debt Enforcer"
	preview_antag_datum = /datum/antagonist/debt_enforcer
	midround_type = LIGHT_MIDROUND
	false_alarm_able = TRUE
	pref_flag = ROLE_DEBT_ENFORCER
	jobban_flag = ROLE_DEBT_ENFORCER
	ruleset_flags = RULESET_VARIATION
	weight = 8
	min_pop = 5

/datum/dynamic_ruleset/midround/from_living/debt_enforcer/antag_check(mob/candidate)
	// Only spawn if there are Indebted to hunt
	for(var/datum/mind/M in get_crewmember_minds())
		var/datum/antagonist/indebted/indebted = M.has_antag_datum(/datum/antagonist/indebted)
		if(indebted && !indebted.debt_paid)
			return !candidate.is_antag()
	return FALSE

/datum/dynamic_ruleset/midround/from_living/debt_enforcer/assign_role(datum/mind/candidate)
	candidate.add_antag_datum(/datum/antagonist/debt_enforcer)

/datum/dynamic_ruleset/midround/from_living/debt_enforcer/false_alarm()
	priority_announce(
		"Attention crew, we have received reports of suspicious activity on station. Please remain vigilant.",
		"[command_name()] Security Update",
	)

