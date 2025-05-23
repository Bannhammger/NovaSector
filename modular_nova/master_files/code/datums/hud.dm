/datum/hud/synthetic
	var/atom/movable/screen/diagnostic_panel/diag_panel

/datum/hud/synthetic/New(mob/living/carbon/human/owner)
	..()
	diag_panel = new /atom/movable/screen/diagnostic_panel()
	diag_panel.hud = src
	infodisplay += diag_panel

/datum/hud/proc/add_synthetic_diagnostics(mob/living/carbon/human/M)
	if(!istype(M) || !is_synthetic(M))
		return

	var/atom/movable/screen/diagnostic_panel/DIAG = new /atom/movable/screen/diagnostic_panel()
	DIAG.hud = src
	infodisplay += DIAG

/proc/is_synthetic(mob/living/carbon/human/M)
	return istype(M) && istype(M.dna.species, /datum/species/synthetic)
