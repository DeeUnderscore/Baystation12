/obj/machinery/iv_stand
	name = "\improper IV stand"
	icon = 'icons/obj/iv_stand.dmi'
	icon_state = "empty"
	desc = "A stand on which an IV kit can be hung."
	anchored = 0
	density = 1
	
	var/obj/item/device/iv_kit/hooked_kit = null  // iv_kit currently hanging from this stand
	
/obj/machinery/iv_stand/New(l, d, var/obj/item/device/iv_kit/new_hooked_kit = null)
	..(l, d)
	
	if(!new_hooked_kit)
		src.hooked_kit = new /obj/item/device/iv_kit()
		src.hooked_kit.loc = src
	else
		src.hooked_kit = new_hooked_kit
		
	update_icon()
	
/obj/machinery/iv_stand/update_icon()
	overlays.Cut()

	if(hooked_kit)
		icon_state = text("[]-[]", src.hooked_kit.bag ? "bag" : "nobag", src.hooked_kit.patient ? "hooked" : "unhooked")
		
		if(src.hooked_kit.bag && src.hooked_kit.bag.reagents.total_volume)
			var/image/filling = image('icons/obj/iv_stand.dmi', src, "fill-1")
			
			var/percent = round((src.hooked_kit.bag.reagents.total_volume / src.hooked_kit.bag.volume) * 100)
			switch(percent)
				if(0 to 29) filling.icon_state = "fill-1"
				if(30 to 59) filling.icon_state = "fill-2"
				if(60 to 89) filling.icon_state = "fill-3"
				if(90 to INFINITY) filling.icon_state = "fill-full"
				
			filling.color = src.hooked_kit.bag.reagents.get_color()
			overlays += filling
	else
		icon_state = "empty"
	
/obj/machinery/iv_stand/MouseDrop(over_object, src_location, over_location)
	..()
	// attach or detach patient
	if(hooked_kit)
		if(hooked_kit.patient)
			hooked_kit.detach_patient()
		else if(in_range(src, usr) && ishuman(over_object) && get_dist(over_object, src) <= 1)
			hooked_kit.attach_patient(usr, over_object)
		
		update_icon()

/obj/machinery/iv_stand/attack_hand(mob/user)
	// Grab the hooked_kit in hand
	if(hooked_kit)
		user.put_in_hands(src.hooked_kit)
		src.hooked_kit = null
		
		update_icon()
	else
		return ..()
		
/obj/machinery/iv_stand/attackby(obj/item/weapon/W, mob/user)
	// borg unhooking
	if(istype(W, /obj/item/weapon/gripper/iv))
		src.hooked_kit.loc = src.loc
		src.hooked_kit = null
		
		update_icon()
		return
		
	// hooking new kit
	if (istype(W, /obj/item/device/iv_kit/))
		if(!isnull(src.hooked_kit))
			user << "<span class='notice'>\The [src.hooked_kit] is already loaded!</span>"
			return

		user.drop_item()
		src.hooked_kit = W
		src.hooked_kit.loc = src
		user.visible_message("<span class='notice'>\The [user] hangs \the [src.hooked_kit] on the \the [src].</span>")
		src.update_icon()
		
	else
		return ..()

/obj/machinery/iv_stand/examine(mob/user)
	..(user)
	
	if(src.hooked_kit && user in view(2))
		user << "<span class='notice'>\The [src.hooked_kit] is hanging from it.</span>"
		user << src.hooked_kit.get_status_string()