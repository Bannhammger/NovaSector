/// Enhanced Milking Machine Features
/// Quality of life improvements and additional functionality

// These defines are from milking_machine.dm - copy them here too
#define MILKING_PUMP_MODE_OFF "off"
#define MILKING_PUMP_MODE_LOW "low"
#define MILKING_PUMP_MODE_MEDIUM "medium"
#define MILKING_PUMP_MODE_HARD "hard"

#define MILKING_PUMP_STATE_OFF "off"
#define MILKING_PUMP_STATE_ON "on"

#define CLIMAX_RETRIEVE_MULTIPLIER 2
#define MILKING_PUMP_MAX_CAPACITY 100

/*
* PORTABLE MILKING MACHINE (from SPLURT)
* Smaller, wearable version for on-the-go milking
*/

/obj/item/milking_machine_portable
	name = "portable milking machine"
	desc = "A compact pump and tubing assembly designed to collect fluids. Can be worn on belt."
	icon = 'modular_nova/modules/modular_items/lewd_items/icons/obj/lewd_items/lewd_items.dmi'
	icon_state = "milking_portable_off"
	w_class = WEIGHT_CLASS_SMALL
	slot_flags = ITEM_SLOT_BELT

	/// Is the pump currently on?
	var/pump_on = FALSE
	/// The container attached to the pump
	var/obj/item/reagent_containers/attached_container
	/// Milking speed multiplier
	var/milking_speed = 50
	/// Which organ are we milking?
	var/target_organ_slot = ORGAN_SLOT_BREASTS
	/// Currently processing?
	var/in_use = FALSE

/obj/item/milking_machine_portable/Initialize(mapload)
	. = ..()
	update_icon_state()

/obj/item/milking_machine_portable/Destroy()
	if(attached_container)
		attached_container.forceMove(drop_location())
		attached_container = null
	return ..()

/obj/item/milking_machine_portable/examine(mob/user)
	. = ..()
	. += span_notice("[src] is currently [pump_on ? "on" : "off"].")
	if(attached_container)
		. += span_notice("[attached_container] contains [attached_container.reagents.total_volume]/[attached_container.reagents.maximum_volume] units.")
		. += span_notice("Alt-Click to remove container.")
	else
		. += span_notice("Click with a container to attach one.")
	. += span_notice("Click to toggle on/off.")
	. += span_notice("Ctrl-Click to change target organ.")

/obj/item/milking_machine_portable/update_icon_state()
	. = ..()
	icon_state = "milking_portable_[pump_on ? "on" : "off"][attached_container ? "_full" : ""]"

/obj/item/milking_machine_portable/attack_self(mob/user)
	if(!attached_container)
		balloon_alert(user, "no container!")
		return

	pump_on = !pump_on
	balloon_alert(user, pump_on ? "turned on" : "turned off")
	update_icon_state()

	if(pump_on)
		START_PROCESSING(SSobj, src)
	else
		STOP_PROCESSING(SSobj, src)

/obj/item/milking_machine_portable/click_alt(mob/user)
	if(!attached_container)
		balloon_alert(user, "no container!")
		return CLICK_ACTION_BLOCKING

	user.put_in_hands(attached_container)
	attached_container = null
	balloon_alert(user, "container removed")
	update_icon_state()
	return CLICK_ACTION_SUCCESS

/obj/item/milking_machine_portable/click_ctrl(mob/user)
	var/list/organ_options = list(
		"Breasts" = ORGAN_SLOT_BREASTS,
		"Testicles" = ORGAN_SLOT_TESTICLES,
		"Vagina" = ORGAN_SLOT_VAGINA
	)

	var/choice = tgui_input_list(user, "Select target organ", "Milking Target", organ_options)
	if(!choice)
		return CLICK_ACTION_BLOCKING

	target_organ_slot = organ_options[choice]
	balloon_alert(user, "targeting [lowertext(choice)]")
	return CLICK_ACTION_SUCCESS

/obj/item/milking_machine_portable/attackby(obj/item/attacking_item, mob/user, params)
	if(!istype(attacking_item, /obj/item/reagent_containers))
		return ..()

	if(attached_container)
		balloon_alert(user, "already has container!")
		return

	if(!user.transferItemToLoc(attacking_item, src))
		balloon_alert(user, "stuck to hand!")
		return

	attached_container = attacking_item
	balloon_alert(user, "container attached")
	update_icon_state()

/obj/item/milking_machine_portable/process(seconds_per_tick)
	if(!pump_on || !attached_container || in_use)
		return

	var/mob/living/carbon/human/user = loc
	if(!ishuman(user))
		return

	var/obj/item/organ/genital/target_organ = user.get_organ_slot(target_organ_slot)
	if(!target_organ || !target_organ.internal_fluid_count)
		return

	// Check if topless/bottomless as needed
	var/exposed = FALSE
	switch(target_organ_slot)
		if(ORGAN_SLOT_BREASTS)
			exposed = user.is_topless()
		if(ORGAN_SLOT_TESTICLES, ORGAN_SLOT_VAGINA)
			exposed = user.is_bottomless()

	if(!exposed)
		return

	// Transfer fluid
	in_use = TRUE
	target_organ.transfer_internal_fluid(attached_container.reagents, 1 * seconds_per_tick)

	// Arousal increase (slow)
	if(prob(10))
		user.adjust_arousal(2)

	// Occasional moan
	if(prob(5))
		user.emote("moan")

	in_use = FALSE

/*
* MILKING MACHINE UPGRADES
* Installable upgrades for the stationary machine
*/

/obj/item/milking_upgrade
	name = "milking machine upgrade"
	desc = "An upgrade module for milking machines."
	icon = 'modular_nova/modules/modular_items/lewd_items/icons/obj/lewd_items/lewd_items.dmi'
	icon_state = "milking_upgrade"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/milking_upgrade/capacity
	name = "capacity upgrade"
	desc = "Increases the internal tank capacity of a milking machine from 100u to 200u."
	var/capacity_bonus = 100

/obj/item/milking_upgrade/efficiency
	name = "efficiency upgrade"
	desc = "Increases fluid extraction rate by 50%."
	var/efficiency_multiplier = 1.5

/obj/item/milking_upgrade/comfort
	name = "comfort upgrade"
	desc = "Reduces pain and increases pleasure during milking. Adds soft padding."
	var/pain_reduction = 0.5
	var/pleasure_bonus = 0.5

/obj/item/milking_upgrade/arousal
	name = "stimulation upgrade"
	desc = "Significantly increases arousal generation. For those who want to climax faster."
	var/arousal_multiplier = 2.0

/*
* ENHANCED CHAIR WITH UPGRADES
*/

/obj/structure/chair/milking_machine/upgraded
	/// Installed upgrades
	var/list/installed_upgrades = list()
	/// Maximum number of upgrades
	var/max_upgrades = 4
	/// Current capacity bonus
	var/capacity_bonus = 0
	/// Current efficiency multiplier
	var/efficiency_multiplier = 1.0
	/// Pain reduction amount
	var/pain_reduction = 0
	/// Pleasure bonus amount
	var/pleasure_bonus = 0
	/// Arousal multiplier
	var/arousal_multiplier = 1.0

/obj/structure/chair/milking_machine/upgraded/Initialize(mapload)
	. = ..()
	update_upgrades()

/obj/structure/chair/milking_machine/upgraded/examine(mob/user)
	. = ..()
	. += span_notice("It has [length(installed_upgrades)]/[max_upgrades] upgrades installed.")
	if(length(installed_upgrades))
		. += span_notice("Installed upgrades:")
		for(var/obj/item/milking_upgrade/upgrade in installed_upgrades)
			. += span_notice("  - [upgrade.name]")

/obj/structure/chair/milking_machine/upgraded/attackby(obj/item/attacking_item, mob/user, list/modifiers, list/attack_modifiers)
	// Install upgrades
	if(istype(attacking_item, /obj/item/milking_upgrade))
		if(length(installed_upgrades) >= max_upgrades)
			balloon_alert(user, "fully upgraded!")
			return

		if(attacking_item in installed_upgrades)
			balloon_alert(user, "already installed!")
			return

		if(!user.transferItemToLoc(attacking_item, src))
			return

		installed_upgrades += attacking_item
		update_upgrades()
		balloon_alert(user, "upgrade installed")

		user.visible_message(
			span_notice("[user] installs [attacking_item] into [src]."),
			span_notice("You install [attacking_item] into [src].")
		)
		return

	return ..()

/obj/structure/chair/milking_machine/upgraded/proc/update_upgrades()
	capacity_bonus = 0
	efficiency_multiplier = 1.0
	pain_reduction = 0
	pleasure_bonus = 0
	arousal_multiplier = 1.0

	for(var/obj/item/milking_upgrade/upgrade in installed_upgrades)
		if(istype(upgrade, /obj/item/milking_upgrade/capacity))
			var/obj/item/milking_upgrade/capacity/cap = upgrade
			capacity_bonus += cap.capacity_bonus

		if(istype(upgrade, /obj/item/milking_upgrade/efficiency))
			var/obj/item/milking_upgrade/efficiency/eff = upgrade
			efficiency_multiplier *= eff.efficiency_multiplier

		if(istype(upgrade, /obj/item/milking_upgrade/comfort))
			var/obj/item/milking_upgrade/comfort/com = upgrade
			pain_reduction += com.pain_reduction
			pleasure_bonus += com.pleasure_bonus

		if(istype(upgrade, /obj/item/milking_upgrade/arousal))
			var/obj/item/milking_upgrade/arousal/aro = upgrade
			arousal_multiplier *= aro.arousal_multiplier

	// Update capacities
	milk_vessel.reagents.maximum_volume = MILKING_PUMP_MAX_CAPACITY + capacity_bonus
	girlcum_vessel.reagents.maximum_volume = MILKING_PUMP_MAX_CAPACITY + capacity_bonus
	semen_vessel.reagents.maximum_volume = MILKING_PUMP_MAX_CAPACITY + capacity_bonus

/obj/structure/chair/milking_machine/upgraded/retrieve_liquids_from_selected_organ(seconds_per_tick)
	if(!current_mob || !current_selected_organ)
		return FALSE

	var/fluid_multiplier = 1
	var/static/list/fluid_retrieve_amount = list("off" = 0, "low" = 1, "medium" = 2, "hard" = 3)

	if(current_mob.has_status_effect(/datum/status_effect/climax))
		fluid_multiplier = CLIMAX_RETRIEVE_MULTIPLIER

	// Apply efficiency upgrade
	fluid_multiplier *= efficiency_multiplier

	var/obj/item/reagent_containers/target_container

	switch(current_selected_organ.type)
		if(/obj/item/organ/genital/breasts)
			target_container = milk_vessel
		if(/obj/item/organ/genital/vagina)
			target_container = girlcum_vessel
		if(/obj/item/organ/genital/testicles)
			target_container = semen_vessel

	if(!target_container || current_selected_organ.internal_fluid_count <= 0)
		return FALSE

	current_selected_organ.transfer_internal_fluid(target_container.reagents, fluid_retrieve_amount[current_mode] * fluid_multiplier * seconds_per_tick)
	return TRUE

/obj/structure/chair/milking_machine/upgraded/increase_current_mob_arousal(seconds_per_tick)
	var/static/list/arousal_amounts = list("off" = 0, "low" = 1, "medium" = 2, "hard" = 3)
	var/static/list/pleasure_amounts = list("off" = 0, "low" = 0.2, "medium" = 1, "hard" = 1.5)
	var/static/list/pain_amounts = list("off" = 0, "low" = 0, "medium" = 0.2, "hard" = 0.5)

	// Apply upgrade bonuses
	current_mob.adjust_arousal(arousal_amounts[current_mode] * arousal_multiplier * seconds_per_tick)
	current_mob.adjust_pleasure(max(0, pleasure_amounts[current_mode] + pleasure_bonus) * seconds_per_tick)
	current_mob.adjust_pain(max(0, pain_amounts[current_mode] - pain_reduction) * seconds_per_tick)

/*
* AUTO-MILKING MODE
* Automatically manages pumping to maximize fluid output
*/

/obj/structure/chair/milking_machine/upgraded/proc/enable_auto_mode()
	set name = "Enable Auto-Milking"
	set desc = "Automatically adjusts pump speed for optimal extraction."

	if(!current_mob || !current_selected_organ)
		return

	// Auto mode intelligently switches between modes based on arousal
	if(current_mob.arousal < 30)
		current_mode = MILKING_PUMP_MODE_LOW
	else if(current_mob.arousal < 60)
		current_mode = MILKING_PUMP_MODE_MEDIUM
	else
		current_mode = MILKING_PUMP_MODE_HARD

	pump_state = MILKING_PUMP_STATE_ON
	update_all_visuals()

/*
* COLLECTION BOTTLES (pre-labeled)
*/

/obj/item/reagent_containers/cup/beaker/milking_bottle
	name = "collection bottle"
	desc = "A bottle designed for collecting... biological fluids."
	icon = 'modular_nova/modules/modular_items/lewd_items/icons/obj/lewd_items/lewd_items.dmi'
	icon_state = "collection_bottle"
	volume = 100
	possible_transfer_amounts = list(5, 10, 15, 20, 25, 30, 50, 100)

/obj/item/reagent_containers/cup/beaker/milking_bottle/breast_milk
	name = "breast milk collection bottle"
	desc = "A bottle pre-labeled for breast milk collection."

/obj/item/reagent_containers/cup/beaker/milking_bottle/girlcum
	name = "vaginal fluid collection bottle"
	desc = "A bottle pre-labeled for vaginal fluid collection."

/obj/item/reagent_containers/cup/beaker/milking_bottle/semen
	name = "semen collection bottle"
	desc = "A bottle pre-labeled for semen collection."

/*
* MILKING MACHINE CONSTRUCTION KIT (Enhanced)
* Note: You'll need to create this type or modify existing construction_kit/milker
*/

/*
* ENHANCED UI ACTIONS
*/

// Add to ui_act in your main milking_machine.dm:
/obj/structure/chair/milking_machine/upgraded/ui_act(action, params)
	. = ..()
	if(.)
		return

	if(action == "autoMode")
		enable_auto_mode()
		return TRUE

	if(action == "emptyAllTanks")
		if(!beaker)
			return FALSE

		// Transfer all fluids to beaker
		milk_vessel.reagents.trans_to(beaker, milk_vessel.reagents.total_volume)
		girlcum_vessel.reagents.trans_to(beaker, girlcum_vessel.reagents.total_volume)
		semen_vessel.reagents.trans_to(beaker, semen_vessel.reagents.total_volume)

		to_chat(usr, span_notice("You empty all tanks into the beaker."))
		update_all_visuals()
		return TRUE

	if(action == "removeUpgrade")
		if(!length(installed_upgrades))
			return FALSE

		var/obj/item/milking_upgrade/upgrade_to_remove = tgui_input_list(usr, "Select upgrade to remove", "Remove Upgrade", installed_upgrades)
		if(!upgrade_to_remove)
			return FALSE

		installed_upgrades -= upgrade_to_remove
		upgrade_to_remove.forceMove(drop_location())
		update_upgrades()

		to_chat(usr, span_notice("You remove [upgrade_to_remove] from [src]."))
		return TRUE

/*
* MILKING MACHINE VARIANTS
*/

/obj/structure/chair/milking_machine/upgraded/deluxe
	name = "deluxe milking machine"
	desc = "A high-end milking machine with enhanced features and comfort."
	max_upgrades = 6 // More upgrade slots
	machine_color = "teal"

/obj/structure/chair/milking_machine/upgraded/deluxe/Initialize(mapload)
	. = ..()
	// Pre-install comfort upgrade
	var/obj/item/milking_upgrade/comfort/comfort = new(src)
	installed_upgrades += comfort
	update_upgrades()

/*
* MEDICAL MILKING MACHINE
* For medical purposes (collecting samples, relieving pressure)
*/

/obj/structure/chair/milking_machine/medical
	name = "medical milking apparatus"
	desc = "A clinical-grade fluid extraction device. For medical purposes only."
	machine_color = "teal"
	/// Automatically labeled containers?
	var/auto_label = TRUE

/obj/structure/chair/milking_machine/medical/replace_beaker(mob/living/user, obj/item/reagent_containers/new_beaker)
	. = ..()

	if(auto_label && new_beaker && current_selected_organ)
		var/label_name = "Unknown"
		switch(current_selected_organ.type)
			if(/obj/item/organ/genital/breasts)
				label_name = "Breast Milk"
			if(/obj/item/organ/genital/vagina)
				label_name = "Vaginal Fluid"
			if(/obj/item/organ/genital/testicles)
				label_name = "Semen"

		if(current_mob)
			label_name += " - [current_mob.name]"

		new_beaker.name = label_name
		to_chat(user, span_notice("[new_beaker] auto-labeled as '[label_name]'."))

/*
* STORAGE/VENDING
*/

/obj/item/storage/box/milking_machine_kit
	name = "milking machine kit"
	desc = "Contains everything needed to set up a milking station."

/obj/item/storage/box/milking_machine_kit/PopulateContents()
	new /obj/item/construction_kit/milker(src)
	new /obj/item/reagent_containers/cup/beaker/milking_bottle/breast_milk(src)
	new /obj/item/reagent_containers/cup/beaker/milking_bottle/girlcum(src)
	new /obj/item/reagent_containers/cup/beaker/milking_bottle/semen(src)
	new /obj/item/reagent_containers/cup/beaker/large(src) // Extra beaker

/obj/item/storage/box/milking_upgrades
	name = "milking machine upgrade kit"
	desc = "A set of upgrade modules for milking machines."

/obj/item/storage/box/milking_upgrades/PopulateContents()
	new /obj/item/milking_upgrade/capacity(src)
	new /obj/item/milking_upgrade/efficiency(src)
	new /obj/item/milking_upgrade/comfort(src)
	new /obj/item/milking_upgrade/arousal(src)

/*
* CRAFTABLE PORTABLE MILKER
*/

/datum/crafting_recipe/portable_milker
	name = "Portable Milking Machine"
	result = /obj/item/milking_machine_portable
	reqs = list(
		/obj/item/stack/cable_coil = 5,
		/obj/item/stack/sheet/plastic = 3,
		/obj/item/stock_parts/micro_laser = 1,
	)
	tool_paths = list(/obj/item/screwdriver, /obj/item/wrench)
	time = 3 SECONDS
	category = CAT_EQUIPMENT

// Undefine so they don't conflict with main milking_machine.dm
#undef MILKING_PUMP_MODE_OFF
#undef MILKING_PUMP_MODE_LOW
#undef MILKING_PUMP_MODE_MEDIUM
#undef MILKING_PUMP_MODE_HARD
#undef MILKING_PUMP_STATE_OFF
#undef MILKING_PUMP_STATE_ON
#undef CLIMAX_RETRIEVE_MULTIPLIER
#undef MILKING_PUMP_MAX_CAPACITY

