/obj/item/weapon/gripper/iv
	name = "\improper IV kit gripper"
	desc = "A tool for administering IV therapy."
	icon = 'icons/obj/device.dmi'
	icon_state = "gripper"
		
	can_hold = list(/obj/item/device/iv_kit)
	
	// TODO: Setting drip amount
		
/obj/item/weapon/gripper/iv/proc/set_drip_amount()
	if(wrapped)
		var/obj/item/device/iv_kit/I = wrapped
		I.set_drip_amount()
		
/obj/item/weapon/gripper/iv/examine(mob/user)
	..()
	
	if(wrapped)
		wrapped.examine(user)

/obj/item/weapon/gripper/iv/afterattack(var/atom/target, var/mob/living/user, proximity, params)
	..()
	
	if(wrapped)
		verbs += /obj/item/weapon/gripper/iv/proc/set_drip_amount
		
	if(!wrapped)
		verbs -= /obj/item/weapon/gripper/iv/proc/set_drip_amount

/obj/item/weapon/gripper/iv/drop_item()
	..()
	
	if(!wrapped)
		verbs -= /obj/item/weapon/gripper/iv/proc/set_drip_amount