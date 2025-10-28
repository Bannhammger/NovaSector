/// E-Stim Chastity Cage System
/// Electric stimulation chastity device with remote control

/obj/item/chastity_estim_controller
	name = "e-stim cage controller"
	desc = "A remote control for electric stimulation chastity devices. Handle with care."
	icon = 'modular_nova/modules/modular_items/lewd_items/icons/obj/lewd_items/chastity.dmi'
	icon_state = "estim_controller"
	w_class = WEIGHT_CLASS_SMALL

	/// The linked e-stim cage
	var/obj/item/clothing/sextoy/chastity_cage/estim/linked_cage
	/// Current stimulation intensity (0-3)
	var/intensity = 0
	/// Frequency of automatic shocks when locked (0 = manual only)
	var/shock_frequency = 0
	/// Next time an automatic shock can occur
	var/next_shock_time = 0

/obj/item/chastity_estim_controller/Initialize(mapload, obj/item/clothing/sextoy/chastity_cage/estim/cage)
	. = ..()
	if(cage)
		linked_cage = cage
		cage.controller = src

/obj/item/chastity_estim_controller/Destroy()
	if(linked_cage)
		linked_cage.controller = null
	linked_cage = null
	return ..()

/obj/item/chastity_estim_controller/examine(mob/user)
	. = ..()
	if(linked_cage)
		. += span_notice("Linked to: [linked_cage]")
		. += span_notice("Current intensity: [intensity]/3")
		. += span_notice("Shock frequency: [shock_frequency > 0 ? "[shock_frequency] seconds" : "Manual only"]")
	else
		. += span_warning("Not linked to any cage!")
	. += span_notice("Click to adjust settings. Alt-Click to send a shock.")

/obj/item/chastity_estim_controller/attack_self(mob/user)
	if(!linked_cage)
		balloon_alert(user, "no cage linked!")
		return

	var/list/options = list(
		"Set Intensity" = "intensity",
		"Set Frequency" = "frequency",
		"Send Shock Now" = "shock",
		"Toggle Auto-Shock" = "toggle"
	)

	var/choice = tgui_input_list(user, "E-Stim Controller", "Select Option", options)
	if(!choice)
		return

	switch(options[choice])
		if("intensity")
			var/new_intensity = tgui_input_number(user, "Set stimulation intensity (0-3)", "Intensity", intensity, 3, 0)
			if(!isnull(new_intensity))
				intensity = clamp(new_intensity, 0, 3)
				balloon_alert(user, "intensity: [intensity]")

		if("frequency")
			var/new_freq = tgui_input_number(user, "Set automatic shock frequency in seconds (0 = manual only)", "Frequency", shock_frequency, 300, 0)
			if(!isnull(new_freq))
				shock_frequency = clamp(new_freq, 0, 300)
				balloon_alert(user, "frequency: [shock_frequency]s")

		if("shock")
			send_shock(user)

		if("toggle")
			if(shock_frequency > 0)
				shock_frequency = 0
				balloon_alert(user, "auto-shock off")
			else
				shock_frequency = 30
				balloon_alert(user, "auto-shock on")

/obj/item/chastity_estim_controller/click_alt(mob/user)
	send_shock(user)
	return CLICK_ACTION_SUCCESS

/obj/item/chastity_estim_controller/proc/send_shock(mob/user)
	if(!linked_cage)
		balloon_alert(user, "no cage linked!")
		return FALSE

	var/mob/living/carbon/human/victim = linked_cage.loc
	if(!ishuman(victim) || !linked_cage.is_inside_lewd_slot(victim))
		balloon_alert(user, "cage not worn!")
		return FALSE

	// Apply shock effects based on intensity
	var/shock_message
	var/damage = 0
	var/stun_time = 0
	var/arousal_change = 0

	switch(intensity)
		if(0)
			shock_message = "feels a faint tingle from the e-stim cage"
			arousal_change = 5
		if(1)
			shock_message = "gasps as the e-stim cage sends mild shocks through them"
			damage = 2
			arousal_change = 10
			stun_time = 1 SECONDS
		if(2)
			shock_message = "moans as intense stimulation pulses through the e-stim cage"
			damage = 5
			arousal_change = 20
			stun_time = 2 SECONDS
		if(3)
			shock_message = "cries out as the e-stim cage delivers a powerful shock"
			damage = 10
			arousal_change = 30
			stun_time = 3 SECONDS

	victim.visible_message(
		span_warning("[victim] [shock_message]!"),
		span_userdanger("You [shock_message]!")
	)

	// Apply effects
	if(damage > 0)
		victim.apply_damage(damage, STAMINA)

	if(stun_time > 0)
		victim.Stun(stun_time)

	// Add arousal if your system supports it
	if(arousal_change > 0 && victim.client?.prefs?.read_preference(/datum/preference/toggle/erp/sex_toy))
		// You'll need to add your arousal adjustment proc here
		// victim.adjust_arousal(arousal_change)
		pass()

	// Emote
	if(intensity >= 2)
		victim.emote(pick("moan", "gasp", "twitch"))

	// Visual effect
	victim.do_jitter_animation(intensity * 50)

	// Sound
	playsound(victim, 'sound/items/weapons/taser2.ogg', 50, TRUE)

	// Prevent spam
	next_shock_time = world.time + 3 SECONDS

	// Log for admin purposes
	message_admins("[ADMIN_LOOKUPFLW(user)] used e-stim controller on [ADMIN_LOOKUPFLW(victim)] at intensity [intensity].")
	victim.log_message("was shocked by [key_name(user)] via e-stim cage at intensity [intensity]", LOG_ATTACK)

	return TRUE

/obj/item/chastity_estim_controller/process(seconds_per_tick)
	if(!linked_cage || shock_frequency <= 0)
		return

	var/mob/living/carbon/human/victim = linked_cage.loc
	if(!ishuman(victim) || !linked_cage.is_inside_lewd_slot(victim))
		return

	if(world.time >= next_shock_time)
		if(!victim.stat)
			send_shock(victim)
			next_shock_time = world.time + (shock_frequency SECONDS)

/*
*	E-STIM CHASTITY CAGE
*/

/obj/item/clothing/sextoy/chastity_cage/estim
	name = "e-stim chastity cage"
	desc = "An advanced chastity cage with built-in electric stimulation. Comes with a remote controller."
	icon_state = "estim_cage"
	worn_icon_state = "worn_estim_cage"

	/// The controller for this cage
	var/obj/item/chastity_estim_controller/controller

/obj/item/clothing/sextoy/chastity_cage/estim/Initialize(mapload, obj/item/chastity_remote/newremote = null)
	. = ..()
	// Create controller
	controller = new /obj/item/chastity_estim_controller(get_turf(src), src)

/obj/item/clothing/sextoy/chastity_cage/estim/Destroy()
	if(controller)
		QDEL_NULL(controller)
	return ..()

/obj/item/clothing/sextoy/chastity_cage/estim/examine(mob/user)
	. = ..()
	if(controller)
		. += span_notice("It has an integrated e-stim system controlled by a remote.")

/obj/item/clothing/sextoy/chastity_cage/estim/lewd_equipped(mob/living/carbon/human/user, slot, initial)
	. = ..()
	// Start processing for auto-shocks if enabled
	if(controller?.shock_frequency > 0)
		START_PROCESSING(SSobj, controller)

	to_chat(user, span_warning("You feel the e-stim contacts press against sensitive areas..."))

/obj/item/clothing/sextoy/chastity_cage/estim/dropped(mob/user)
	. = ..()
	if(controller)
		STOP_PROCESSING(SSobj, controller)

/*
*	STORAGE BOX
*/

/obj/item/storage/box/chastity_cage/estim
	name = "e-stim chastity cage box"
	desc = "A box containing an e-stim chastity cage, key, and remote controller."

/obj/item/storage/box/chastity_cage/estim/PopulateContents()
	var/obj/item/chastity_remote/remote = new(src)
	var/obj/item/clothing/sextoy/chastity_cage/estim/cage = new(src, remote)
	// Controller and remote are both created
	if(cage.controller)
		cage.controller.forceMove(src)

