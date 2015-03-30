// TODO: Proper icons
/obj/item/weapon/reagent_containers/iv_bag
	name = "\improper IV bag"
	icon = 'icons/obj/bloodpack.dmi'
	icon_state = "empty"
	desc = "A bag which can be connected to an IV line to administer medication."
	
	volume = 60
	amount_per_transfer_from_this = 30
	possible_transfer_amounts = null
	
	var/cut = 0  // is the bag cut open?
	
/obj/item/weapon/reagent_containers/iv_bag/examine(mob/user)
	..(user)
	
	if(reagents && reagents.total_volume > 0)
		user << "It contains [src.reagents.total_volume] units of liquid."
	else
		user << "It is empty."
		
	if(cut)
		user << "It has been cut open!"
		
/obj/item/weapon/reagent_containers/iv_bag/update_icon()
	overlays.Cut()

	if(reagents.total_volume)
		var/image/filling = image('icons/obj/bloodpack.dmi', src, "over-1")

		var/percent = round((reagents.total_volume / volume) * 100)
		switch(percent)
			if(0 to 19) filling.icon_state = "over-1"
			if(20 to 44) filling.icon_state = "over-2"
			if(45 to 69) filling.icon_state = "over-3"
			if(70 to 94) filling.icon_state = "over-4"
			if(95 to INFINITY) filling.icon_state = "over-full"

		filling.color = mix_color_from_reagents(reagents.reagent_list)
		overlays += filling
		
/obj/item/weapon/reagent_containers/iv_bag/attackby(obj/item/weapon/W, mob/user)
	// cut the bag
	if(istype(W, /obj/item/weapon/wirecutters))
		src.cut = 1
		user << "You cut the IV bag open. You could probably pour it into something now."
		
/obj/item/weapon/reagent_containers/iv_bag/afterattack(obj/target, mob/user, proximity)
	// Reimplementation of parts of reagent_containers/glass functionality. Cut IV bags 
	// purposefully lack a lot of the usual beaker functionality, but notably allow pouring out
	
	if(target.is_open_container() && target.reagents)
		if(!src.reagents.total_volume)
			user << "\red [src] is empty!"
			return
		
		if(target.reagents.total_volume >= target.reagents.maximum_volume)
			user << "\red [target] is full."
			return
			
		var/to_pour = src.reagents.total_volume
		var/transferred = src.reagents.trans_to(target, to_pour)
		if(to_pour == transferred)
			user << "\blue You pour \the [src] out into \the [target]."
		else
			user << "\blue You pour some of \the [src] into \the [target]."
		
		return
	
/obj/item/weapon/reagent_containers/iv_bag/on_reagent_change()
	update_icon()

/obj/item/weapon/reagent_containers/iv_bag/pickup(mob/user)
	..()
	update_icon()

/obj/item/weapon/reagent_containers/iv_bag/dropped(mob/user)
	..()
	update_icon()

/obj/item/weapon/reagent_containers/iv_bag/attack_hand()
	..()
	update_icon()
		
/obj/item/weapon/reagent_containers/iv_bag/blood
	name = "blood pack"
	desc = "Contains blood used for transfusion."
	icon = 'icons/obj/bloodpack.dmi'
	icon_state = "empty"
	volume = 200  // Considerably more than standard IV bags!

	var/blood_type = null

	New()
		..()
		if(blood_type != null)
			name = "BloodPack [blood_type]"
			reagents.add_reagent("blood", 200, list("donor"=null,"viruses"=null,"blood_DNA"=null,"blood_type"=blood_type,"resistances"=null,"trace_chem"=null))
			update_icon()

	on_reagent_change()
		update_icon()
			
/obj/item/weapon/reagent_containers/iv_bag/blood/APlus
	blood_type = "A+"

/obj/item/weapon/reagent_containers/iv_bag/blood/AMinus
	blood_type = "A-"

/obj/item/weapon/reagent_containers/iv_bag/blood/BPlus
	blood_type = "B+"

/obj/item/weapon/reagent_containers/iv_bag/blood/BMinus
	blood_type = "B-"

/obj/item/weapon/reagent_containers/iv_bag/blood/OPlus
	blood_type = "O+"

/obj/item/weapon/reagent_containers/iv_bag/blood/OMinus
	blood_type = "O-"