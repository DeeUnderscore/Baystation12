#define IV_KIT_HOOKIN_TIME 40  // time it takes to insert an IV catheter 

/obj/item/device/iv_kit
	name = "\improper IV kit"
	icon = 'icons/obj/iv_kit.dmi'
	icon_state = "nobag-unhooked"
	desc = "A kit for starting an IV line."
	w_class = 2
		
	var/drip_amount = REAGENTS_METABOLISM * 2 // How much to transfer with each drip by default
	var/max_drip_amount = REAGENTS_METABOLISM * 8  // Maximum possible drip amount a user can set. Minimum is 0.
	var/obj/item/weapon/reagent_containers/iv_bag/bag = null  // The bag we're using, null if none attached
	var/list/valid_holders = list(/obj/machinery/iv_stand)  // List of places other than hands where the kit can be put and still work
	var/mob/living/carbon/human/patient = null  // Person currently hooked up
	var/skipped_ticks = 0
	
	
/obj/item/device/iv_kit/examine(mob/user)
	..()
	
	if (!(user in view(2)) && user!=src.loc) return
	
	// bag line
	if(!src.bag)
		user << "\blue No bag is attached."
	else
		var/bag_text = "\blue \The [src.bag.name] is attached. "
		if(src.bag.reagents && src.bag.reagents.total_volume > 0)
			bag_text += "It has [src.bag.reagents.total_volume] units of liquid left. The drip amount is set to [src.drip_amount] units."
		else
			bag_text += "It is empty."
		
		user << bag_text
			
	// patient line
	if(!src.patient)
		user << "\blue No one is attached."
	else
		user << "\blue [src.patient.name] is attached."
		
/obj/item/device/iv_kit/update_icon()
	overlays.Cut()
	icon_state = text("[]-[]", bag ? "bag" : "nobag", patient ? "hooked" : "unhooked")
	
	if(bag)
		// TODO: This is pretty hacky. Figure out a better way to do it.
		
		var/matrix/M = matrix()
		M.Translate(-1, 6)
		
		var/image/bag_image = image('icons/obj/bloodpack.dmi', "empty")
		bag_image.transform = M
		overlays += bag_image
		
		var/image/filling = image('icons/obj/bloodpack.dmi', src, "over-1")

		var/percent = round((src.bag.reagents.total_volume / src.bag.volume) * 100)
		switch(percent)
			if(0 to 19) filling.icon_state = "over-1"
			if(20 to 44) filling.icon_state = "over-2"
			if(45 to 69) filling.icon_state = "over-3"
			if(70 to 94) filling.icon_state = "over-4"
			if(95 to INFINITY) filling.icon_state = "over-full"

		filling.color = mix_color_from_reagents(src.bag.reagents.reagent_list)
		filling.transform = M
		overlays += filling
		
	if(loc.type in valid_holders)
		// We assume that the holder is an obj and implements update_icon(). The
		// compiler won't warn us here.
		var/obj/O = loc
		O.update_icon()

/obj/item/device/iv_kit/attack(mob/target, mob/user, zone)
	return 
		
/obj/item/device/iv_kit/afterattack(obj/target, mob/user, proximity)
	// We allow kit to bag attaching, too. Intuitively, this is spiking the bag
	// with the IV kit. 
	if(!src.bag && istype(target, /obj/item/weapon/reagent_containers/iv_bag))
		user.u_equip(target)
		
		user << "\blue You attach \the [src.name] to \the [target.name]."
		
		src.bag = target
		src.bag.loc = src
		
		update_icon()
		return
		
	if(!proximity || !istype(target,/mob/living/carbon/human)) 
		return ..()
	 
	if(patient)
		// detach from patient - anyone can be clicked for removing IVs for the sake of simplicty
		src.detach_patient()
		
	else
		var/mob/living/carbon/human/H = target
		attach_patient(user, H)
/**
 *  Attempt to attach a patient to the IV kit
 *
 *  doctor is the mob doing the attaching, new_patient is the mob we're trying to stick the needle in.
 *  This proc does not check range.
 */	
/obj/item/device/iv_kit/proc/attach_patient(mob/doctor, mob/living/carbon/human/new_patient)
	// Suit check. Similar to can_inject(), but simpler: we never check for head
	if(new_patient.wear_suit && new_patient.wear_suit.flags & THICKMATERIAL)
		doctor << "\red You cannot find a way to run an IV line through [new_patient.name]'s suit."
		return
	
	// The visible messages don't say where the catheter is inserted. This is on purpose, as the IV kit (like syringes) does not check
	// for mechanical limbs. We could check for mechanical limbs and then pick a suitable place for the catheter, but that would add a 
	// bunch of overhead. 
	doctor.visible_message("\red [doctor.name] begins inserting an IV line into [new_patient.name].", "\red You begin inserting the IV line into [new_patient.name].")
	
	if(!do_mob(doctor, new_patient, IV_KIT_HOOKIN_TIME)) return
	doctor.visible_message("\red [doctor.name] inserts an IV line into [new_patient.name].", "\red You finish inserting the IV line into [new_patient.name].")
	
	patient = new_patient
	patient.iv_line = src
	update_icon()
	
	processing_objects.Add(src)
	if(is_ready())
		add_attack_log(doctor)

/**
 *  Detach current patient from the IV
 *
 *  This proc does not check range.
 */
/obj/item/device/iv_kit/proc/detach_patient()
	patient.visible_message("\red [patient.name] is disconnected from the IV line.")
	patient.iv_line = null
	patient = null
	processing_objects.Remove(src)
	update_icon()
	
	
/obj/item/device/iv_kit/attackby(obj/item/weapon/W, mob/user)
	// Hook up new bag
	if(!src.bag && istype(W, /obj/item/weapon/reagent_containers/iv_bag))
		user.drop_item()
		src.bag = W
		src.bag.loc = src
		
		user << "\blue You attach \the [src.bag] to \the [src.name]."
		update_icon()
		if(is_ready())
			add_attack_log(user)
			
	else
		return ..()


/obj/item/device/iv_kit/attack_self(mob/user)
	// detach bag
	if(src.bag)
		user.put_in_hands(src.bag)
		src.bag = null 
		
		update_icon()
		return
	
	return ..()

/obj/item/device/iv_kit/process()
	set background = 1  // might need changing if dripping too unpredictable in practice
	
	if(!src.patient)
		error("IV_kit ([src.loc.x],[src.loc.y]) in processing_objects when it shouldn't be.")
		processing_objects.Remove(src)
		return
	
	// ripping out
	if(get_dist(src, src.patient) > 1 && isturf(src.patient.loc))
		src.patient.visible_message("\red The IV line is yanked out of [src.patient.name].")
		src.patient.iv_line = null
		src.patient = null
		
		src.update_icon()
		processing_objects.Remove(src)
		return
	
	if(src.drip_amount == 0)
		return
		
	// We skip every other tick to prevent homeopathy. If we dripped every tick, we'd 
	// have the ability to drip a very low amount of reagent every tick and still
	// get the full effect. With skipped ticks, this is still possible, but at least
	// we have to drip at least enough reagent to cover one-and-a-fraction ticks
	if(skipped_ticks < 1)
		skipped_ticks += 1
		return 
	else
		skipped_ticks = 0

	// administering drugs
	if(src.bag && src.in_valid_location())
		src.bag.reagents.trans_to(src.patient, src.drip_amount)
	update_icon()
	
/obj/item/device/iv_kit/verb/set_drip_amount()
	set name = "Set drip amount"
	set category = "Object"
	set src in range(0)
	
	var/new_amount = input("Amount per drip:","[src.name] drip setting", src.drip_amount) as num
	src.drip_amount = Clamp(new_amount, 0, src.max_drip_amount)

/**
 *  Return a true value if the IV kit is in a configuration ready to administer medication
 *
 *  This does not check if the IV kit is in the right place to actually drip. Use in_valid_location() for that.
 */
/obj/item/device/iv_kit/proc/is_ready()
	return (src.patient && src.bag && src.bag.reagents.total_volume > 0)

/**	
 *  Returns a true value if the IV kit is in a position where it can drip.
 */
/obj/item/device/iv_kit/proc/in_valid_location(var/mob/living/this_loc = null)
	if(!this_loc)
		this_loc = src.loc
	
	if(isturf(this_loc))
		return 0
		
	if((ismob(this_loc) && this_loc != src.patient) || (this_loc.type in src.valid_holders))
		return 1
	
	// We check recursively, so IV kits in backpacks and such should still work. 
	return in_valid_location(this_loc.loc)
	
	
/**
 *  Add attack log entries for this IV kit
 *
 *  attacker should be the person administering the IV. The "victim" is the mob
 *  connected to the IV kit. This proc will log the reagents in the bag.
 */
/obj/item/device/iv_kit/proc/add_attack_log(mob/attacker)
	var/list/contained_list = list()
	for(var/datum/reagent/R in src.bag.reagents.reagent_list)
		contained_list += R.name
	var/contained = english_list(contained_list)
	
	src.patient.attack_log += text("\[[time_stamp()]\] <font color='orange'>Was attached to [src.name] by [attacker.name] ([attacker.ckey]). Reagents: [contained]</font>")
	attacker.attack_log += text("\[[time_stamp()]\] <font color='red'>Attached [src.name] to [src.patient.name] ([src.patient.key]). Reagents: [contained]</font>")
	msg_admin_attack("[attacker.name] ([attacker.ckey]) attached [src.name] to [src.patient.name] ([src.patient.key]) Reagents: [contained] (INTENT: [uppertext(attacker.a_intent)]) (<A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[attacker.x];Y=[attacker.y];Z=[attacker.z]'>JMP</a>)")
