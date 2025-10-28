/// Chastity system for NovaSector
/// Adapted from SPLURT's chastity system to work with existing genital organ framework

/obj/item/chastity_remote
	name = "chastity remote"
	desc = "A small remote control for locking and unlocking chastity devices. Don't lose it!"
	icon = 'modular_nova/modules/modular_items/lewd_items/icons/obj/lewd_items/chastity.dmi'
	icon_state = "chastity_remote"
	w_class = WEIGHT_CLASS_TINY
	/// The linked chastity cage
	var/obj/item/clothing/sextoy/chastity_cage/linked_cage

/obj/item/chastity_remote/Initialize(mapload, obj/item/clothing/sextoy/chastity_cage/cage)
	. = ..()
	if(cage)
		linked_cage = cage
		cage.linked_remote = src

/obj/item/chastity_remote/Destroy()
	if(linked_cage)
		linked_cage.linked_remote = null
	linked_cage = null
	return ..()

/obj/item/chastity_remote/examine(mob/user)
	. = ..()
	if(linked_cage)
		. += span_notice("Linked to: [linked_cage]")
		. += span_notice("The cage is currently [linked_cage.locked ? "locked" : "unlocked"].")
	else
		. += span_warning("Not linked to any cage!")
	. += span_notice("Click to toggle lock. Alt-Click to locate linked cage.")

/obj/item/chastity_remote/attack_self(mob/user)
	if(!linked_cage)
		balloon_alert(user, "no cage linked!")
		return

	// Check if someone is wearing it
	var/mob/living/carbon/human/wearer = linked_cage.loc
	if(ishuman(wearer) && linked_cage.is_inside_lewd_slot(wearer))
		// Check preference - can they remove it?
		// Use sex_toy preference as stand-in - you can add chastity_allow_removal preference later
		if(!wearer.client?.prefs?.read_preference(/datum/preference/toggle/erp/sex_toy))
			balloon_alert(user, "they won't allow!")
			to_chat(user, span_warning("[wearer] has disabled chastity removal in their preferences!"))
			return

	// Toggle lock
	linked_cage.locked = !linked_cage.locked
	balloon_alert(user, linked_cage.locked ? "locked" : "unlocked")
	playsound(src, 'sound/machines/terminal/terminal_button01.ogg', 30, TRUE)

	// Message to wearer if worn
	if(ishuman(wearer) && linked_cage.is_inside_lewd_slot(wearer))
		to_chat(wearer, span_purple("You feel the [linked_cage] [linked_cage.locked ? "lock tightly" : "unlock"]..."))

/obj/item/chastity_remote/click_alt(mob/user)
	if(!linked_cage)
		balloon_alert(user, "no cage linked!")
		return CLICK_ACTION_BLOCKING

	// Point to the cage
	user.point_at(linked_cage)
	balloon_alert(user, "located cage")
	return CLICK_ACTION_SUCCESS

/obj/item/clothing/sextoy/chastity_cage
	name = "chastity cage"
	desc = "A device designed to prevent... certain activities. Requires a key to remove once locked."
	icon = 'modular_nova/modules/modular_items/lewd_items/icons/obj/lewd_items/chastity.dmi'
	icon_state = "standard_cage"
	worn_icon = 'modular_nova/modules/modular_items/lewd_items/icons/mob/lewd_clothing/chastity_worn.dmi'
	worn_icon_state = "worn_standard_cage"
	lefthand_file = 'modular_nova/modules/modular_items/lewd_items/icons/mob/lewd_inhands/lewd_inhand_left.dmi'
	righthand_file = 'modular_nova/modules/modular_items/lewd_items/icons/mob/lewd_inhands/lewd_inhand_right.dmi'
	w_class = WEIGHT_CLASS_TINY
	lewd_slot_flags = LEWD_SLOT_PENIS
	clothing_flags = INEDIBLE_CLOTHING

	/// The remote that controls this cage
	var/obj/item/chastity_remote/linked_remote
	/// Is the cage currently locked?
	var/locked = FALSE
	/// Can this cage be resized based on genital size?
	var/resizeable = TRUE
	/// Current sprite variant based on size
	var/cage_sprite = 2
	/// Tool required to break the cage
	var/break_require = TOOL_WIRECUTTER
	/// Time to break the cage
	var/break_time = 25 SECONDS

/obj/item/clothing/sextoy/chastity_cage/Initialize(mapload, obj/item/chastity_remote/newremote = null)
	. = ..()
	if(newremote)
		linked_remote = newremote
		newremote.linked_cage = src
	else
		// Generate a new remote
		linked_remote = new /obj/item/chastity_remote(get_turf(src), src)

	// Set random color
	color = pick(list(COLOR_LIGHT_PINK, COLOR_STRONG_VIOLET, null))

/obj/item/clothing/sextoy/chastity_cage/Destroy()
	if(linked_remote)
		linked_remote.linked_cage = null
	linked_remote = null
	return ...()

/obj/item/clothing/sextoy/chastity_cage/examine(mob/user)
	. = ..()
	. += span_notice("It is currently [locked ? "locked" : "unlocked"].")
	if(linked_remote)
		. += span_notice("Linked to a chastity remote. Use the remote to lock/unlock.")
	if(!locked)
		. += span_notice("Alt-Click to manually lock it.")
	. += span_notice("Use wirecutters to forcefully remove it (takes [DisplayTimeText(break_time)]).")

	// Show imbued reagents
	var/datum/component/reagent_clothing/clothing_component = GetComponent(/datum/component/reagent_clothing)
	if(clothing_component && length(clothing_component.imbued_reagent))
		. += span_notice("Imbued with: [english_list(clothing_component.imbued_reagent)]")
		. += span_purple("Imbued reagents will slowly absorb into the wearer through genital contact.")

/obj/item/clothing/sextoy/chastity_cage/click_alt(mob/user)
	if(locked)
		balloon_alert(user, "already locked!")
		return CLICK_ACTION_BLOCKING

	if(is_inside_lewd_slot(user))
		balloon_alert(user, "remove it first!")
		return CLICK_ACTION_BLOCKING

	locked = TRUE
	balloon_alert(user, "locked")
	playsound(src, 'sound/machines/terminal/terminal_button01.ogg', 30, TRUE)
	return CLICK_ACTION_SUCCESS

	// Removed - now uses remote instead of keys

/obj/item/clothing/sextoy/chastity_cage/attackby(obj/item/attacking_item, mob/user, params)
	// Break with tools
	if(attacking_item.tool_behaviour == break_require)
		var/mob/living/carbon/human/wearer = loc
		if(!ishuman(wearer) || !is_inside_lewd_slot(wearer))
			balloon_alert(user, "not worn!")
			return

		user.visible_message(
			span_warning("[user] starts cutting [src] off [wearer]!"),
			span_warning("You start cutting [src] off [wearer]...")
		)

		if(!do_after(user, break_time, target = wearer))
			return

		user.visible_message(
			span_warning("[user] cuts [src] off [wearer]!"),
			span_notice("You successfully cut [src] off!")
		)

		wearer.apply_damage(5, BRUTE, BODY_ZONE_PRECISE_GROIN)
		wearer.emote("scream")

		// Force remove and destroy
		wearer.dropItemToGround(src, force = TRUE)
		qdel(src)
		return

	return ..()

// Override lewd_equipped to handle locking and preferences
/obj/item/clothing/sextoy/chastity_cage/lewd_equipped(mob/living/carbon/human/user, slot, initial)
	. = ..()

	// Check if they allow chastity (can be bypassed if cage not locked)
	if(!user.client?.prefs?.read_preference(/datum/preference/toggle/erp/sex_toy))
		balloon_alert(user, "erp disabled!")
		user.dropItemToGround(src, force = TRUE)
		return

	to_chat(user, span_userlove("You feel the [src] [locked ? "lock around you tightly" : "fit snugly"]..."))

	// Apply imbued reagent effects (only on forged variants)
	var/datum/component/reagent_clothing/clothing_component = GetComponent(/datum/component/reagent_clothing)
	if(clothing_component && length(clothing_component.imbued_reagent))
		START_PROCESSING(SSobj, src)

// Override dropped to stop processing and check preferences
/obj/item/clothing/sextoy/chastity_cage/dropped(mob/user)
	// Check if locked and preferences prevent removal
	if(locked && ishuman(user))
		var/mob/living/carbon/human/wearer = user
		// Use sex_toy preference as stand-in - you can add chastity_allow_removal preference later
		if(!wearer.client?.prefs?.read_preference(/datum/preference/toggle/erp/sex_toy))
			balloon_alert(user, "locked on!")
			to_chat(user, span_warning("The [src] is locked and you can't remove it! Use the remote to unlock it first."))
			// Try to re-equip it
			wearer.penis = src
			lewd_equipped(wearer, "penis")
			return

	. = ..()
	STOP_PROCESSING(SSobj, src)

/*
*	CHEMICAL IMBUING SYSTEM (forged cages only)
*/

/// Process imbued reagent effects (only works if component exists)
/obj/item/clothing/sextoy/chastity_cage/process(seconds_per_tick)
	var/mob/living/carbon/human/wearer = loc
	if(!ishuman(wearer) || !is_inside_lewd_slot(wearer))
		STOP_PROCESSING(SSobj, src)
		return

	var/datum/component/reagent_clothing/clothing_component = GetComponent(/datum/component/reagent_clothing)
	if(!clothing_component || !length(clothing_component.imbued_reagent))
		STOP_PROCESSING(SSobj, src)
		return

	// Apply small amounts of imbued reagents to the wearer over time
	for(var/reagent_type in clothing_component.imbued_reagent)
		wearer.reagents.add_reagent(reagent_type, 0.5 * seconds_per_tick)

		// Special effects for specific reagents
		switch(reagent_type)
			if(/datum/reagent/drug/aphrodisiac/crocin)
				if(prob(10 * seconds_per_tick))
					to_chat(wearer, span_purple("You feel a warm tingle from the [src]..."))
				if(prob(5 * seconds_per_tick))
					wearer.emote(pick("blush", "gasp"))

			if(/datum/reagent/drug/aphrodisiac/crocin/hexacrocin)
				if(prob(15 * seconds_per_tick))
					to_chat(wearer, span_purple("An intense warmth radiates from the [src]!"))
				if(prob(8 * seconds_per_tick))
					wearer.emote(pick("moan", "blush", "gasp"))

			if(/datum/reagent/drug/aphrodisiac/camphor)
				if(prob(8 * seconds_per_tick))
					to_chat(wearer, span_blue("A cooling sensation spreads from the [src]..."))

			if(/datum/reagent/drug/aphrodisiac/camphor/pentacamphor)
				if(prob(12 * seconds_per_tick))
					to_chat(wearer, span_blue("An icy tingle spreads from the [src]!"))

			if(/datum/reagent/consumable/capsaicin)
				if(prob(15 * seconds_per_tick))
					to_chat(wearer, span_danger("The [src] burns painfully!"))
					wearer.adjust_pain(2 * seconds_per_tick)
				if(prob(5 * seconds_per_tick))
					wearer.emote(pick("scream", "cry"))

			if(/datum/reagent/pax)
				if(prob(5 * seconds_per_tick))
					to_chat(wearer, span_notice("You feel strangely calm despite the [src]..."))

			if(/datum/reagent/drug/aphrodisiac)
				if(prob(10 * seconds_per_tick))
					wearer.adjust_arousal(1 * seconds_per_tick)

/*
*	METAL CHASTITY CAGE VARIANT
*/

/obj/item/clothing/sextoy/chastity_cage/metal
	name = "metal chastity cage"
	desc = "A heavy-duty metal chastity device. Much more secure than plastic."
	icon_state = "metal_cage"
	worn_icon_state = "worn_metal_cage"
	break_time = 40 SECONDS // Harder to break

/obj/item/clothing/sextoy/chastity_cage/metal/Initialize(mapload, obj/item/chastity_remote/newremote = null)
	. = ..()
	color = null // Metal doesn't get random colors

/*
*	CHASTITY BELT (with cage attachment)
*/

/obj/item/clothing/underwear/chastity_belt
	name = "chastity belt"
	desc = "A belt designed to hold a chastity cage in place. Can be worn as underwear."
	icon = 'modular_nova/modules/modular_items/lewd_items/icons/obj/lewd_items/chastity.dmi'
	icon_state = "belt"
	body_parts_covered = GROIN

	/// The cage currently attached to this belt
	var/obj/item/clothing/sextoy/chastity_cage/attached_cage


/obj/item/clothing/underwear/chastity_belt/Initialize(mapload, obj/item/clothing/sextoy/chastity_cage/initial_cage)
	. = ..()
	if(initial_cage)
		attached_cage = initial_cage
		initial_cage.forceMove(src)

/obj/item/clothing/underwear/chastity_belt/Destroy()
	if(attached_cage)
		QDEL_NULL(attached_cage)
	return ..()

/obj/item/clothing/underwear/chastity_belt/examine(mob/user)
	. = ..()
	if(attached_cage)
		. += span_notice("It has \a [attached_cage] attached to it.")
		. += span_notice("Alt-Click to remove the cage.")
	else
		. += span_notice("Click with a chastity cage to attach one.")

	// Show imbued reagents
	var/datum/component/reagent_clothing/clothing_component = GetComponent(/datum/component/reagent_clothing)
	if(clothing_component && length(clothing_component.imbued_reagent))
		. += span_notice("Imbued with: [english_list(clothing_component.imbued_reagent)]")
		. += span_purple("Imbued reagents will slowly absorb into the wearer through skin contact.")

/obj/item/clothing/underwear/chastity_belt/click_alt(mob/user)
	if(!attached_cage)
		balloon_alert(user, "no cage attached!")
		return CLICK_ACTION_BLOCKING

	// Check if someone is wearing it
	if(ismob(loc))
		balloon_alert(user, "remove belt first!")
		return CLICK_ACTION_BLOCKING

	user.put_in_hands(attached_cage)
	attached_cage = null
	balloon_alert(user, "cage removed")
	return CLICK_ACTION_SUCCESS

/obj/item/clothing/underwear/chastity_belt/attackby(obj/item/attacking_item, mob/user, params)
	if(istype(attacking_item, /obj/item/clothing/sextoy/chastity_cage))
		if(attached_cage)
			balloon_alert(user, "already has cage!")
			return

		var/obj/item/clothing/sextoy/chastity_cage/cage = attacking_item
		if(!user.transferItemToLoc(cage, src))
			return

		attached_cage = cage
		balloon_alert(user, "cage attached")
		return

	return ..()

/obj/item/clothing/underwear/chastity_belt/equipped(mob/user, slot)
	. = ..()
	if(!attached_cage)
		return

	// Try to equip the cage to the penis lewd slot
	var/mob/living/carbon/human/wearer = user
	if(!ishuman(wearer))
		return

	if(!attached_cage.locked)
		to_chat(wearer, span_warning("The cage needs to be locked before the belt will secure it!"))
		return

	// Equip to penis variable directly
	if(!wearer.penis)
		wearer.penis = attached_cage
		attached_cage.lewd_equipped(wearer, "penis", initial = TRUE)
		balloon_alert(wearer, "cage secured")

/obj/item/clothing/underwear/chastity_belt/dropped(mob/user)
	. = ..()
	if(!attached_cage)
		return

	// Remove cage from lewd slot if worn
	var/mob/living/carbon/human/wearer = user
	if(ishuman(wearer) && wearer.penis == attached_cage)
		wearer.dropItemToGround(attached_cage, force = TRUE)

/*
*	STORAGE BOXES
*/

/obj/item/storage/box/chastity_cage
	name = "chastity cage box"
	desc = "A discreet box containing a chastity cage and remote control."

/obj/item/storage/box/chastity_cage/PopulateContents()
	var/obj/item/chastity_remote/remote = new(src)
	new /obj/item/clothing/sextoy/chastity_cage(src, remote)
	// Remote is generated by the cage, linked together

/obj/item/storage/box/chastity_cage/metal
	name = "metal chastity cage box"
	desc = "A discreet box containing a metal chastity cage and remote."

/obj/item/storage/box/chastity_cage/metal/PopulateContents()
	var/obj/item/chastity_remote/remote = new(src)
	new /obj/item/clothing/sextoy/chastity_cage/metal(src, remote)

/obj/item/storage/box/chastity_belt_kit
	name = "chastity belt kit"
	desc = "A box containing a chastity belt with attached cage and remote."

/obj/item/storage/box/chastity_belt_kit/PopulateContents()
	var/obj/item/chastity_remote/remote = new(src)
	var/obj/item/clothing/sextoy/chastity_cage/cage = new(src, remote)
	new /obj/item/clothing/underwear/chastity_belt(src, cage)

