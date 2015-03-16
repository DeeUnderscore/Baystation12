// TODO: Proper icons
/obj/item/weapon/reagent_containers/iv_bag
	name = "\improper IV bag"
	icon = 'icons/obj/bloodpack.dmi'
	icon_state = "empty"
	desc = "A bag which can be connected to an IV line to administer medication."
	
	volume = 60
	amount_per_transfer_from_this = 10
	possible_transfer_amounts = null
	
/obj/item/weapon/reagent_containers/iv_bag/examine(mob/user)
	..(user)
	
	if(reagents && reagents.total_volume > 0)
		user << "It contains [src.reagents.total_volume] of liquid."
	else
		user << "It is empty."
		

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