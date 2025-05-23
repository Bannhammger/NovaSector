/datum/hud/synthetic
	var/atom/movable/screen/diagnostic_panel/diag_panel

/datum/hud/synthetic/New(mob/living/carbon/human/owner)
	..()
	diag_panel = new /atom/movable/screen/diagnostic_panel()
	diag_panel.hud = src
	infodisplay += diag_panel

/datum/hud/proc/add_synthetic_diagnostics(mob/living/carbon/human/M)
	if(!istype(M) || M.dna.species.id != "synth")
		return

	var/atom/movable/screen/diagnostic_panel/DIAG = new /atom/movable/screen/diagnostic_panel()
	DIAG.hud = src
	infodisplay += DIAG
