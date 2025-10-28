/// Forging integration for chastity cages
/// Allows creating material-based chastity devices through the smithing system

/*
* INCOMPLETE FORGE ITEMS (heated metal stage)
*/

/obj/item/forging/incomplete/chastity_cage
	name = "incomplete chastity cage"
	desc = "A glowing hot piece of metal being shaped into a chastity cage. Keep hammering to complete it."
	icon_state = "hot_chastity_cage"
	average_hits = 25 // Takes decent effort to shape properly
	average_wait = 0.7 SECONDS
	spawn_item = /obj/item/forging/complete/chastity_cage

/obj/item/forging/incomplete/chastity_belt
	name = "incomplete chastity belt"
	desc = "A glowing hot piece of metal being shaped into a chastity belt. Keep hammering to complete it."
	icon_state = "hot_chastity_belt"
	average_hits = 30 // Larger item, more hits needed
	average_wait = 0.7 SECONDS
	spawn_item = /obj/item/forging/complete/chastity_belt

/*
* COMPLETE FORGE ITEMS (finished metal, needs assembly)
*/

/obj/item/forging/complete/chastity_cage
	name = "chastity cage parts"
	desc = "A completed metal chastity cage, ready for final assembly. Use at a crafting bench to finish it."
	icon_state = "chastity_cage_parts"
	spawning_item = /obj/item/clothing/sextoy/chastity_cage/forged

/obj/item/forging/complete/chastity_belt
	name = "chastity belt parts"
	desc = "A completed metal chastity belt, ready for final assembly. Use at a crafting bench to finish it."
	icon_state = "chastity_belt_parts"
	spawning_item = /obj/item/clothing/underwear/chastity_belt/forged

/*
* CRAFTING BENCH RECIPES (final assembly)
*/

/datum/crafting_bench_recipe/chastity_cage
	recipe_name = "Chastity Cage"
	recipe_requirements = list(/obj/item/forging/complete/chastity_cage = 1)
	resulting_item = /obj/item/clothing/sextoy/chastity_cage/forged
	required_good_hits = 6

/datum/crafting_bench_recipe/chastity_belt
	recipe_name = "Chastity Belt"
	recipe_requirements = list(
		/obj/item/forging/complete/chastity_belt = 1,
		/obj/item/stack/sheet/cloth = 2,
	)
	resulting_item = /obj/item/clothing/underwear/chastity_belt/forged
	required_good_hits = 8

/*
* FORGED VARIANTS (material-based cages)
*/

/obj/item/clothing/sextoy/chastity_cage/forged
	name = "forged chastity cage"
	desc = "A handcrafted chastity cage, forged from quality materials. The material affects its properties. Can be imbued with chemicals at the forge."
	icon_state = "standard_cage" // Use standard cage sprite, material color will differentiate
	worn_icon_state = "worn_standard_cage"
	/// Materials affect break time and durability
	var/durability_modifier = 1.0

/obj/item/clothing/sextoy/chastity_cage/forged/Initialize(mapload, obj/item/chastity_remote/newremote = null)
	. = ..()
	color = null // Forged items use material colors
	// Add reagent imbuing component - ONLY forged cages can be imbued!
	AddComponent(/datum/component/reagent_clothing)
	update_durability_from_materials()

/// Adjust properties based on material type
/obj/item/clothing/sextoy/chastity_cage/forged/proc/update_durability_from_materials()
	if(!custom_materials)
		return

	// Get primary material
	var/datum/material/primary_mat
	var/highest_amount = 0
	for(var/mat in custom_materials)
		if(custom_materials[mat] > highest_amount)
			primary_mat = mat
			highest_amount = custom_materials[mat]

	if(!primary_mat)
		return

	// Adjust durability based on material strength
	switch(primary_mat.type)
		if(/datum/material/iron)
			durability_modifier = 1.0
			desc = "A basic iron chastity cage. Functional but not particularly strong."

		if(/datum/material/silver)
			durability_modifier = 1.2
			desc = "A silver chastity cage. Elegant and somewhat resistant to tampering."

		if(/datum/material/gold)
			durability_modifier = 1.1
			desc = "A golden chastity cage. Luxurious but soft. More for show than security."

		if(/datum/material/alloy/plasteel)
			durability_modifier = 1.8
			desc = "A plasteel chastity cage. Extremely durable and difficult to break."

		if(/datum/material/titanium)
			durability_modifier = 1.5
			desc = "A titanium chastity cage. Lightweight yet strong."

		if(/datum/material/adamantine)
			durability_modifier = 2.5
			desc = "An adamantine chastity cage. Nearly indestructible."

		if(/datum/material/mythril)
			durability_modifier = 2.0
			desc = "A mythril chastity cage. Enchanted metal makes this very secure."

		if(/datum/material/uranium)
			durability_modifier = 1.3
			desc = "A uranium chastity cage. Radioactive and moderately strong. Why would you make this?"

		if(/datum/material/bananium)
			durability_modifier = 0.5
			desc = "A bananium chastity cage. Slippery and weak. This is a joke item."

		if(/datum/material/bronze)
			durability_modifier = 0.9
			desc = "A bronze chastity cage. Ancient metal, but not very secure."

		if(/datum/material/runite)
			durability_modifier = 2.2
			desc = "A runite chastity cage. Magically reinforced and very secure."

		if(/datum/material/hauntium)
			durability_modifier = 1.7
			desc = "A hauntium chastity cage. Ghostly energy makes it harder to remove."

	// Apply durability to break time
	break_time = initial(break_time) * durability_modifier

/obj/item/clothing/sextoy/chastity_cage/forged/examine(mob/user)
	. = ..()

	if(!custom_materials)
		return

	var/datum/material/primary_mat
	var/highest_amount = 0
	for(var/mat in custom_materials)
		if(custom_materials[mat] > highest_amount)
			primary_mat = mat
			highest_amount = custom_materials[mat]

	if(primary_mat)
		. += span_notice("Made from [primary_mat.name]. Durability: [durability_modifier]x")
		. += span_notice("Breaking time: [DisplayTimeText(break_time)]")

/*
* FORGED BELT VARIANT
*/

/obj/item/clothing/underwear/chastity_belt/forged
	name = "forged chastity belt"
	desc = "A handcrafted chastity belt, forged from quality materials with padded cloth straps."
	icon_state = "forged_chastity_belt"
	/// Materials affect durability
	var/durability_modifier = 1.0

/obj/item/clothing/underwear/chastity_belt/forged/Initialize(mapload, obj/item/clothing/chastity_cage/initial_cage)
	. = ..()
	update_durability_from_materials()

/obj/item/clothing/underwear/chastity_belt/forged/proc/update_durability_from_materials()
	if(!custom_materials)
		return

	// Similar to cage logic
	var/datum/material/primary_mat
	var/highest_amount = 0
	for(var/mat in custom_materials)
		if(custom_materials[mat] > highest_amount)
			primary_mat = mat
			highest_amount = custom_materials[mat]

	if(!primary_mat)
		return

	switch(primary_mat.type)
		if(/datum/material/iron)
			durability_modifier = 1.0
		if(/datum/material/silver)
			durability_modifier = 1.2
		if(/datum/material/gold)
			durability_modifier = 1.1
		if(/datum/material/alloy/plasteel)
			durability_modifier = 1.8
		if(/datum/material/titanium)
			durability_modifier = 1.5
		if(/datum/material/adamantine)
			durability_modifier = 2.5
		if(/datum/material/mythril)
			durability_modifier = 2.0

/obj/item/clothing/underwear/chastity_belt/forged/examine(mob/user)
	. = ..()

	if(!custom_materials)
		return

	var/datum/material/primary_mat
	var/highest_amount = 0
	for(var/mat in custom_materials)
		if(custom_materials[mat] > highest_amount)
			primary_mat = mat
			highest_amount = custom_materials[mat]

	if(primary_mat)
		. += span_notice("Made from [primary_mat.name]. Durability: [durability_modifier]x")

