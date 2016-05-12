#define IV_KIT_HOOKIN_TIME 40  // time it takes to insert an IV catheter 

#define IV_MODE_DRIP 0
#define IV_MODE_DONATE 1

/obj/item/device/iv_kit
	name = "\improper IV kit"
	icon = 'icons/obj/iv_kit.dmi'
	icon_state = "nobag-unhooked"
	desc = "A kit for starting an IV line."
	w_class = 2
		
	var/drip_amount = REM * 2 // How much to transfer with each drip by default
	var/max_drip_amount = REM * 20  // Maximum possible drip amount a user can set. Minimum is 0.
	var/obj/item/weapon/reagent_containers/iv_bag/bag = null  // The bag we're using, null if none attached
	var/list/valid_holders = list(/obj/machinery/iv_stand, /obj/item/weapon/gripper/iv)  // List of places other than hands where the kit can be put and still work
	var/mob/living/carbon/human/patient = null  // Person currently hooked up
	var/mode = IV_MODE_DRIP  // either take blood (DONATE) or give reagents (DRIP)
	var/skipped_ticks = 0
	
	
/obj/item/device/iv_kit/examine(mob/user)
	..()
	
	if (user in view(2) || user == src.loc)
		user << get_status_string()
		
/**
 *  Return a multi-line string detailing current state of the kit
 */ 
/obj/item/device/iv_kit/proc/get_status_string()
	var/status_text as text
	
	// bag line
	if(!src.bag)
		status_text += "<span class='notice'>No bag is attached.</span>\n"
	else
		status_text += "<span class='notice'>\The [src.bag] is attached. "
		if(mode == 0)
			if(src.bag.reagents && src.bag.reagents.total_volume > 0)
				status_text += "It has [src.bag.reagents.total_volume] units of liquid left. The drip amount is set to [src.drip_amount] units.</span>\n"
			else
				status_text += "It is empty.</span>\n"
		else
			if(src.bag.reagents && src.bag.reagents.total_volume < src.bag.reagents.maximum_volume)
				status_text += "It is set to receive blood. There are [src.bag.reagents.total_volume] units in it.</span>\n"
			else 
				status_text += "It is set to receive blood and is full.</span>\n" 
			
	// patient line
	if(!src.patient)
		status_text += "<span class='notice'>No one is attached.</span>"
	else
		status_text += "<span class='notice'>\The [src.patient] is attached.</span>"

	return status_text
		
/obj/item/device/iv_kit/update_icon()
	overlays.Cut()
	icon_state = text("[]-[]", bag ? "bag" : "nobag", patient ? "hooked" : "unhooked")
	
	if(bag)
		// This is pretty hacky, and prettier sprites would do better
		
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

		filling.color = src.bag.reagents.get_color()
		filling.transform = M
		overlays += filling
		
	if(loc.type in valid_holders)
		var/obj/O = loc
		O.update_icon()

/obj/item/device/iv_kit/attack(mob/target, mob/user, zone)
	return 
		
/obj/item/device/iv_kit/afterattack(obj/target, mob/user, proximity)
	// We allow kit to bag attaching, too. Intuitively, this is spiking the bag
	// with the IV kit. 
	if(!src.bag && istype(target, /obj/item/weapon/reagent_containers/iv_bag))
		var/obj/item/weapon/reagent_containers/iv_bag/B = target
		if(B.cut)
			user << "<span class='warning'>\The [B] is cut open. This is not going to work.</span>"
			return

		user.u_equip(target)
		
		user << "<span class='notice'>You attach \the [src] to \the [target.name].</span>"
		
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
		doctor << "<span class='warning'>You cannot find a way to run an IV line through \the [new_patient]'s suit.</span>"
		return
	
	// The visible messages don't say where the catheter is inserted. This is on purpose, as the IV kit (like syringes) does not check
	// for mechanical limbs.
	
	
	doctor.visible_message("<span class='warning'>\The [doctor] begins inserting an IV line into \the [new_patient].</span>", "<span class='warning'>You begin inserting the IV line into \the [new_patient].</span>")
	
	if(!do_mob(doctor, new_patient, IV_KIT_HOOKIN_TIME)) return
	doctor.visible_message("<span class='warning'>\The [doctor] inserts an IV line into \the [new_patient].</span>", "<span class='warning'>You finish inserting the IV line into \the [new_patient].</span>")
	
	patient = new_patient
	patient.iv_line = src
	update_icon()
	
	processing_objects.Add(src)
	if(is_ready())
		admin_iv_log(doctor, src.patient, src, src.bag.reagents.get_reagents())

/**
 *  Detach current patient from the IV
 *
 *  This proc does not check range.
 */
/obj/item/device/iv_kit/proc/detach_patient()
	patient.visible_message("<span class='warning'>\The [patient] is disconnected from the IV line.</span>")
	patient.iv_line = null
	patient = null
	processing_objects.Remove(src)
	update_icon()
	
	
/obj/item/device/iv_kit/attackby(obj/item/weapon/W, mob/user)
	// Hook up new bag
	if(!src.bag && istype(W, /obj/item/weapon/reagent_containers/iv_bag))
		var/obj/item/weapon/reagent_containers/iv_bag/B = W
		if(B.cut)
			user << "<span class='warning'>\The [B] is cut open. This is not going to work.</span>"
			return
		
		user.drop_item()
		src.bag = B
		src.bag.loc = src
		
		user << "<span class='notice'>You attach \the [src.bag] to \the [src].</span>"
		update_icon()
		if(is_ready())
			admin_iv_log(user, src.patient, src, src.bag.reagents.get_reagents())
			
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
		src.patient.visible_message("<span class='warning'>The IV line is yanked out of \the [src.patient].</span>")
		src.patient.iv_line = null
		src.patient = null
		
		src.update_icon()
		processing_objects.Remove(src)
		return
		
	if(mode == IV_MODE_DRIP)
		if(src.drip_amount == 0)
			return
	
		// We skip every other tick to prevent homeopathy in some cases, such as
		// checks for presence of any amount of reagent in system
		if(skipped_ticks < 1)
			skipped_ticks += 1
			return 
		else
			skipped_ticks = 0

		// administering drugs
		if(src.bag && src.in_valid_location())
			src.bag.reagents.trans_to_mob(src.patient, src.drip_amount, CHEM_BLOOD)
			update_icon()
	else
		// taking blood
		
		// checks from iv_drip implementation of this functionality
		if(!istype(patient) || !patient.dna || (NOCLONE in patient.mutations) ||\
		  (patient.species && patient.species.flags & NO_BLOOD))
			return
		
		if(src.bag && src.in_valid_location())
			// note that take_blood does not check for fullness of the container passed
			var/amount = min(bag.reagents.maximum_volume - bag.reagents.total_volume, 4) 
			
			var/datum/reagent/blood = patient.take_blood(bag,amount)

			if (blood)
				bag.reagents.reagent_list |= blood
				bag.reagents.update_total()
				bag.on_reagent_change()
				bag.reagents.handle_reactions()

			update_icon()	
	
/obj/item/device/iv_kit/verb/set_drip_amount()
	set name = "Set drip amount"
	set category = "Object"
	set src in range(0)
	
	var/new_amount = input("Amount per drip:","[src] drip setting", src.drip_amount) as num
	src.drip_amount = Clamp(new_amount, 0, src.max_drip_amount)

/obj/item/device/iv_kit/verb/set_mode()
	set name = "Set IV mode"
	set category = "Object"
	set src in range(0)
	
	mode = (mode == 0) ? 1 : 0
	
	if(mode == IV_MODE_DRIP)
		usr << "<span class='notice'>You set the kit to function as an IV drip.</span>"
	else
		usr << "<span class='notice'>You set the kit to receive donated blood.</span>"
	
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
		
#undef IV_MODE_DRIP
#undef IV_MODE_DONATE