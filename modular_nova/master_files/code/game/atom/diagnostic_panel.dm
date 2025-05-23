/atom/movable/screen/diagnostic_panel
	name = "Synthetic Diagnostics"
	icon = 'icons/mob/screen_gen.dmi'
	icon_state = "power2"
	screen_loc = "EAST-1:28, SOUTH:5"
	var/last_update = 0
	var/update_cooldown = 0.5 SECONDS

/atom/movable/screen/diagnostic_panel/proc/update(mob/living/carbon/human/M)
	if(!is_synthetic(M))
		icon_state = ""
		return

	if(world.time < last_update + update_cooldown)
		return

	last_update = world.time

	var/integrity = (M.health / M.maxHealth) * 100
	var/battery_percent = M.get_nutrition()
	var/overheating = M.has_status_effect(/datum/status_effect/overheating)

	if(integrity < 30)
		icon_state = "health7"  // Критическое повреждение
	else if(battery_percent < 15)
		icon_state = "power1"  // Низкий заряд
	else if(overheating)
		icon_state = "fire"    // Перегрев
	else
		icon_state = "power2"  // Норма

	desc = "SYNTHETIC STATUS:\nIntegrity: [integrity]%\nPower: [battery_percent]%\nCoolant: [overheating ? "FAILURE" : "OK"]"
