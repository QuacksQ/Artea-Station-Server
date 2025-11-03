#define AUGGED_LIMB_EMP_BRUTE_DAMAGE 3
#define AUGGED_LIMB_EMP_BURN_DAMAGE 2

/obj/item/bodypart
	name = "limb"
	desc = "Why is it detached..."
	force = 3
	throwforce = 3
	w_class = WEIGHT_CLASS_SMALL
	icon = 'icons/mob/species/human/bodyparts.dmi'
	icon_state = "" //Leave this blank! Bodyparts are built using overlays
	layer = BELOW_MOB_LAYER //so it isn't hidden behind objects when on the floor

	/// The icon for Organic limbs using greyscale
	VAR_PROTECTED/icon_greyscale = DEFAULT_BODYPART_ICON_ORGANIC
	///The icon for non-greyscale limbs
	VAR_PROTECTED/icon_static = 'icons/mob/species/human/bodyparts.dmi'
	///The icon for husked limbs
	VAR_PROTECTED/icon_husk = 'icons/mob/species/human/bodyparts.dmi'
	///The icon for invisible limbs
	VAR_PROTECTED/icon_invisible = 'icons/mob/species/human/bodyparts.dmi'
	///The type of husk for building an iconstate
	var/husk_type = "humanoid"
	grind_results = list(/datum/reagent/bone_dust = 10, /datum/reagent/liquidgibs = 5) // robotic bodyparts and chests/heads cannot be ground
	/// The mob that "owns" this limb
	/// DO NOT MODIFY DIRECTLY. Use set_owner()
	var/mob/living/carbon/owner

	/// If this limb can be scarred.
	var/scarrable = TRUE

	/**
	 * A bitfield of biological states, exclusively used to determine which wounds this limb will get,
	 * as well as how easily it will happen.
	 * Set to BIO_STANDARD_UNJOINTED because most species have both flesh bone and blood in their limbs.
	 */
	var/biological_state = BIO_STANDARD_UNJOINTED
	///A bitfield of bodytypes for clothing, surgery, and misc information
	var/bodytype = BODYTYPE_HUMANOID | BODYTYPE_ORGANIC
	///Defines when a bodypart should not be changed. Example: BP_BLOCK_CHANGE_SPECIES prevents the limb from being overwritten on species gain
	var/change_exempt_flags = NONE
	///Random flags that describe this bodypart
	var/bodypart_flags = NONE

	///Whether the bodypart (and the owner) is husked.
	var/is_husked = FALSE
	///Whether the bodypart (and the owner) is invisible through invisibleman trait.
	var/is_invisible = FALSE
	///The ID of a species used to generate the icon. Needs to match the icon_state portion in the limbs file!
	var/limb_id = SPECIES_HUMAN
	//Defines what sprite the limb should use if it is also sexually dimorphic.
	var/limb_gender = "m"
	///Is there a sprite difference between male and female?
	var/is_dimorphic = FALSE
	///The actual color a limb is drawn as, set by /proc/update_limb()
	var/draw_color //NEVER. EVER. EDIT THIS VALUE OUTSIDE OF UPDATE_LIMB. I WILL FIND YOU. It ruins the limb icon pipeline.

	/// BODY_ZONE_CHEST, BODY_ZONE_L_ARM, etc , used for def_zone
	var/body_zone
	/// The body zone of this part in english ("chest", "left arm", etc) without the species attached to it
	var/plaintext_zone
	var/aux_zone // used for hands
	var/aux_layer
	/// bitflag used to check which clothes cover this bodypart
	var/body_part
	/// are we a hand? if so, which one!
	var/held_index = 0

	// Limb disabling variables
	///Controls if the limb is disabled. TRUE means it is disabled (similar to being removed, but still present for the sake of targeted interactions).
	var/bodypart_disabled = FALSE
	///Handles limb disabling by damage. If 0 (0%), a limb can't be disabled via damage. If 1 (100%), it is disabled at max limb damage. Anything between is the percentage of damage against maximum limb damage needed to disable the limb.
	var/disabling_threshold_percentage = 0
	///Whether it is possible for the limb to be disabled whatsoever. TRUE means that it is possible.
	var/can_be_disabled = FALSE //Defaults to FALSE, as only human limbs can be disabled, and only the appendages.
	/// The interaction speed modifier when this limb is used to interact with the world. ONLY WORKS FOR ARMS
	var/interaction_speed_modifier = 1

	// Damage state variables

	///A mutiplication of the burn and brute damage that the limb's stored damage contributes to its attached mob's overall wellbeing.
	var/body_damage_coeff = 1
	///Used in determining overlays for limb damage states. As the mob receives more burn/brute damage, their limbs update to reflect.
	var/brutestate = 0
	var/burnstate = 0

	///The current amount of brute damage the limb has
	var/brute_dam = 0
	///The current amount of burn damage the limb has
	var/burn_dam = 0
	///The maximum brute OR burn damage a bodypart can take. Once we hit this cap, no more damage of either type!
	var/max_damage = 0

	///The current "physical" damage a bodypart has taken
	var/current_damage = 0
	///The % of current_damage that is brute
	var/brute_ratio = 0
	///The % of current_damage that is burn
	var/burn_ratio = 0
	///The minimum damage a part must have before it's bones may break. Defaults to max_damage * BODYPART_MINIMUM_BREAK_MOD
	var/minimum_break_damage = 0
	/// Bleed multiplier
	var/arterial_bleed_severity = 1

	/// Needs to be opened with a saw to access the organs. For robotic bodyparts, you can open the "hatch"
	var/encased
	/// Is a stump. This is handled at runtime, do not touch.
	var/is_stump
	/// Does this limb have a cavity?
	var/cavity
	/// The name of the cavity of the limb
	var/cavity_name
	/// The type of storage datum to use for cavity storage.
	var/cavity_storage_max_weight = WEIGHT_CLASS_SMALL
	/// For robotic limbs: Hatch states, used by "surgery"
	var/hatch_state

	/// List of obj/item's embedded inside us. Managed by embedded components, do not modify directly
	var/list/embedded_objects = list()
	/// List of obj/items stuck TO us. Managed by embedded components, do not directly modify
	var/list/stuck_objects = list()
	/// The items stored in our cavity
	var/list/cavity_items = list()

	///Bodypart flags, keeps track of blood, bones, arteries, tendons, and the like.
	var/bodypart_flags = NONE
	/// The name of the artery this limb has
	var/artery_name = "artery"
	/// The name of the tendon this limb has
	var/tendon_name = "tendon"
	/// The name for the amputation point of the limb
	var/amputation_point
	/// Surgical stage. Magic BS. Do not touch
	var/stage = 0

	///Gradually increases while burning when at full damage, destroys the limb when at 100
	var/cremation_progress = 0

	// Damage reduction variables for damage handled on the limb level. Handled after worn armor.
	///Amount subtracted from brute damage inflicted on the limb.
	var/brute_reduction = 0
	///Amount subtracted from burn damage inflicted on the limb.
	var/burn_reduction = 0

	//Coloring and proper item icon update
	var/skin_tone = ""
	///Limbs need this information as a back-up incase they are generated outside of a carbon (limbgrower)
	var/should_draw_greyscale = TRUE
	///An "override" color that can be applied to ANY limb, greyscale or not.
	var/variable_color = ""

	var/px_x = 0
	var/px_y = 0

	var/species_flags_list = list()
	///the type of damage overlay (if any) to use when this bodypart is bruised/burned.
	var/dmg_overlay_type = "human"
	/// If we're bleeding, which icon are we displaying on this part
	var/bleed_overlay_icon

	//Damage messages used by help_shake_act()
	var/light_brute_msg = "bruised"
	var/medium_brute_msg = "battered"
	var/heavy_brute_msg = "mangled"

	var/light_burn_msg = "numb"
	var/medium_burn_msg = "blistered"
	var/heavy_burn_msg = "peeling away"

	/// NOT wounds.len! Multiple wounds of the same type compress onto the same wound datum.
	var/real_wound_count = 0

	///The description used when the bones are broken.
	var/broken_description

	//Damage messages used by examine(). the desc that is most common accross all bodyparts gets shown
	var/list/damage_examines = list(
		BRUTE = DEFAULT_BRUTE_EXAMINE_TEXT,
		BURN = DEFAULT_BURN_EXAMINE_TEXT,
		CLONE = DEFAULT_CLONE_EXAMINE_TEXT,
	)

	// Wounds related variables
	/// The wounds currently afflicting this body part
	var/list/wounds

	/// NOT wounds.len! Multiple wounds of the same type compress onto the same wound datum.
	var/real_wound_count = 0

	/// Our current stored wound damage multiplier
	var/wound_damage_multiplier = 1

	/// This number is subtracted from all wound rolls on this bodypart, higher numbers mean more defense, negative means easier to wound
	var/wound_resistance = 0
	/// When this bodypart hits max damage, this number is added to all wound rolls. Obviously only relevant for bodyparts that have damage caps.
	var/disabled_wound_penalty = 15

	/// So we know if we need to scream if this limb hits max damage
	var/last_maxed
	/// Our current bleed rate. Cached, update with refresh_bleed_rate()
	var/cached_bleed_rate = 0
	/// How much generic bleedstacks we have on this bodypart
	var/generic_bleedstacks

	/// If something is currently grasping this bodypart and trying to staunch bleeding (see [/obj/item/hand_item/self_grasp])
	var/obj/item/hand_item/self_grasp/grasped_by
	/// If something is currently supporting this limb as a splint
	var/obj/item/splint
	/// The bandage that may-or-may-not be absorbing our blood
	var/obj/item/stack/bandage

	///A list of all the cosmetic organs we've got stored to draw horns, wings and stuff with (special because we are actually in the limbs unlike normal organs :/ )
	var/list/obj/item/organ/cosmetic_organs = list()
	///A list of all bodypart overlays to draw
	var/list/bodypart_overlays = list()

	/// Type of an attack from this limb does. Arms will do punches, Legs for kicks, and head for bites. (TO ADD: tactical chestbumps)
	var/attack_type = BRUTE
	/// the verb used for an unarmed attack when using this limb, such as arm.unarmed_attack_verb = punch
	var/unarmed_attack_verb = "bump"
	/// what visual effect is used when this limb is used to strike someone.
	var/unarmed_attack_effect = ATTACK_EFFECT_PUNCH
	/// Sounds when this bodypart is used in an umarmed attack
	var/sound/unarmed_attack_sound = 'sound/weapons/punch1.ogg'
	var/sound/unarmed_miss_sound = 'sound/weapons/punchmiss.ogg'
	///Lowest possible punch damage this bodypart can give. If this is set to 0, unarmed attacks will always miss.
	var/unarmed_damage_low = 1
	///Highest possible punch damage this bodypart can ive.
	var/unarmed_damage_high = 1
	///Damage at which attacks from this bodypart will stun
	var/unarmed_stun_threshold = 2
	/// How many pixels this bodypart will offset the top half of the mob, used for abnormally sized torsos and legs
	var/top_offset = 0

	/// Traits that are given to the holder of the part. If you want an effect that changes this, don't add directly to this. Use the add_bodypart_trait() proc
	var/list/bodypart_traits = list()
	/// The name of the trait source that the organ gives. Should not be altered during the events of gameplay, and will cause problems if it is.
	var/bodypart_trait_source = BODYPART_TRAIT
	/// List of the above datums which have actually been instantiated, managed automatically
	var/list/feature_offsets = list()

	/// In the case we dont have dismemberable features, or literally cant get wounds, we will use this percent to determine when we can be dismembered.
	/// Compared to our ABSOLUTE maximum. Stored in decimal; 0.8 = 80%.
	var/hp_percent_to_dismemberable = 0.8
	/// If true, we will use [hp_percent_to_dismemberable] even if we are dismemberable via wounds. Useful for things with extreme wound resistance.
	var/use_alternate_dismemberment_calc_even_if_mangleable = FALSE
	/// If false, no wound that can be applied to us can mangle our exterior. Used for determining if we should use [hp_percent_to_dismemberable] instead of normal dismemberment.
	var/any_existing_wound_can_mangle_our_exterior
	/// If false, no wound that can be applied to us can mangle our interior. Used for determining if we should use [hp_percent_to_dismemberable] instead of normal dismemberment.
	var/any_existing_wound_can_mangle_our_interior

/obj/item/bodypart/Initialize(mapload)
	. = ..()

	if(can_be_disabled)
		RegisterSignal(src, SIGNAL_ADDTRAIT(TRAIT_PARALYSIS), PROC_REF(on_paralysis_trait_gain))
		RegisterSignal(src, SIGNAL_REMOVETRAIT(TRAIT_PARALYSIS), PROC_REF(on_paralysis_trait_loss))

	RegisterSignal(src, COMSIG_ATOM_RESTYLE, PROC_REF(on_attempt_feature_restyle))

	if(!IS_ORGANIC_LIMB(src))
		grind_results = null

	name = "[limb_id] [parse_zone(body_zone)]"
	update_icon_dropped()
	refresh_bleed_rate()

/obj/item/bodypart/Destroy()
	for(var/wound in wounds)
		qdel(wound) // wounds is a lazylist, and each wound removes itself from it on deletion.
	if(length(wounds))
		stack_trace("[type] qdeleted with [length(wounds)] uncleared wounds")
		wounds.Cut()

	QDEL_LIST(contained_organs)
	QDEL_LIST(cavity_items)
	if(owner)
		drop_limb(TRUE)

	QDEL_NULL(splint)
	QDEL_NULL(bandage)
	return ..()

/obj/item/bodypart/forceMove(atom/destination) //Please. Never forcemove a limb if its's actually in use. This is only for borgs.
	SHOULD_CALL_PARENT(TRUE)

	. = ..()
	if(isturf(destination))
		update_icon_dropped()

/obj/item/bodypart/examine(mob/user)
	SHOULD_CALL_PARENT(TRUE)
	. = ..()
	. += mob_examine()

/obj/item/bodypart/proc/mob_examine(hallucinating, covered)
	. = list()

	if(covered)
		for(var/obj/item/I in embedded_objects)
			if(I.isEmbedHarmless())
				. += "<a href='?src=[REF(src)];embedded_object=[REF(I)]' class='danger'>There is \a [I] stuck to [owner.p_their()] [plaintext_zone]!</a>"
			else
				. += "<a href='?src=[REF(src)];embedded_object=[REF(I)]' class='danger'>There is \a [I] embedded in [owner.p_their()] [plaintext_zone]!</a>"

		if(splint && istype(splint, /obj/item/stack))
			. += span_notice("\t <a href='?src=[REF(src)];splint_remove=1' class='notice'>[owner.p_their(TRUE)] [plaintext_zone] is splinted with [splint].</a>")

		if(bandage)
			. += span_notice("\t <a href='?src=[REF(src)];bandage_remove=1' class='[bandage.absorption_capacity ? "notice" : "warning"]'>[owner.p_their(TRUE)] [plaintext_zone] is bandaged with [bandage][bandage.absorption_capacity ? "." : ", blood is trickling out."]</a>")
		return

	if(!current_damage || hallucinating == SCREWYHUD_HEALTHY)
		return

	if(hallucinating == SCREWYHUD_CRIT)
		var/list/flavor_text = list("a")
		flavor_text += pick(" pair of ", " ton of ", " several ")
		flavor_text += pick("large cuts", "severe burns")
		return "[owner.p_they(TRUE)] [owner.p_have()] [english_list(flavor_text)] on [owner.p_their()] [plaintext_zone].<br>"

	var/list/flavor_text = list()
	if((bodypart_flags & BP_CUT_AWAY) && !is_stump)
		flavor_text += "a tear at the [amputation_point] so severe that it hangs by a scrap of flesh"

	if(!IS_ORGANIC_LIMB(src))
		if(brute_dam)
			switch(brute_dam)
				if(0 to 20)
					flavor_text += "some dents"
				if(21 to INFINITY)
					flavor_text += pick("a lot of dents","severe denting")
		if(burn_dam)
			switch(burn_dam)
				if(0 to 20)
					flavor_text += "some burns"
				if(21 to INFINITY)
					flavor_text += pick("a lot of burns","severe melting")
	else
		var/list/wound_descriptors = list()
		for(var/datum/wound/W as anything in wounds)
			var/descriptor = W.get_examine_desc()
			if(descriptor)
				wound_descriptors[descriptor] += W.amount

		if(how_open() >= SURGERY_RETRACTED)
			var/bone = encased ? encased : "bone"
			if(bodypart_flags & BP_BROKEN_BONES)
				bone = "broken [bone]"
			wound_descriptors["a [bone] exposed"] = 1

		for(var/wound in wound_descriptors)
			switch(wound_descriptors[wound])
				if(1)
					flavor_text += "a [wound]"
				if(2)
					flavor_text += "a pair of [wound]s"
				if(3 to 5)
					flavor_text += "several [wound]s"
				if(6 to INFINITY)
					flavor_text += "a ton of [wound]\s"

	if(owner)
		if(current_damage)
			. += "[owner.p_they(TRUE)] [owner.p_have()] [english_list(flavor_text)] on [owner.p_their()] [plaintext_zone]."
		for(var/obj/item/I in embedded_objects)
			if(I.isEmbedHarmless())
				. += "\t <a href='?src=[REF(src)];embedded_object=[REF(I)]' class='warning'>There is \a [I] stuck to [owner.p_their()] [plaintext_zone]!</a>"
			else
				. += "\t <a href='?src=[REF(src)];embedded_object=[REF(I)]' class='warning'>There is \a [I] embedded in [owner.p_their()] [plaintext_zone]!</a>"

		if(splint && istype(splint, /obj/item/stack))
			. += span_notice("\t <a href='?src=[REF(src)];splint_remove=1' class='warning'>[owner.p_their(TRUE)] [plaintext_zone] is splinted with [splint].</a>")
		if(bandage)
			. += span_notice("\n\t <a href='?src=[REF(src)];bandage_remove=1' class='notice'>[owner.p_their(TRUE)] [plaintext_zone] is bandaged with [bandage][bandage.absorption_capacity ? "." : ", blood is trickling out."]</a>")
		return
	else
		if(current_damage)
			. += "It has [english_list(flavor_text)]."
		if(bodypart_flags & BP_BROKEN_BONES)
			. += span_warning("It is dented and swollen.")
		return

/**
 * Called when a bodypart is checked for injuries.
 *
 * Modifies the check_list list with the resulting report of the limb's status.
 */
/obj/item/bodypart/proc/check_for_injuries(mob/living/carbon/human/examiner, list/check_list)

	var/list/limb_damage = list(BRUTE = brute_dam, BURN = burn_dam)

	SEND_SIGNAL(src, COMSIG_BODYPART_CHECKED_FOR_INJURY, examiner, check_list, limb_damage)
	SEND_SIGNAL(examiner, COMSIG_CARBON_CHECKING_BODYPART, src, check_list, limb_damage)

	var/shown_brute = limb_damage[BRUTE]
	var/shown_burn = limb_damage[BURN]
	var/status = ""
	var/self_aware = HAS_TRAIT(examiner, TRAIT_SELF_AWARE)

	if(self_aware)
		if(!shown_brute && !shown_burn)
			status = "no damage"
		else
			status = "[shown_brute] brute damage and [shown_burn] burn damage"

	else
		if(shown_brute > (max_damage * 0.8))
			status += heavy_brute_msg
		else if(shown_brute > (max_damage * 0.4))
			status += medium_brute_msg
		else if(shown_brute > DAMAGE_PRECISION)
			status += light_brute_msg

		if(shown_brute > DAMAGE_PRECISION && shown_burn > DAMAGE_PRECISION)
			status += " and "

		if(shown_burn > (max_damage * 0.8))
			status += heavy_burn_msg
		else if(shown_burn > (max_damage * 0.2))
			status += medium_burn_msg
		else if(shown_burn > DAMAGE_PRECISION)
			status += light_burn_msg

		if(status == "")
			status = "OK"

	var/no_damage
	if(status == "OK" || status == "no damage")
		no_damage = TRUE

	var/is_disabled = ""
	if(bodypart_disabled)
		is_disabled = " is disabled"
		if(no_damage)
			is_disabled += " but otherwise"
		else
			is_disabled += " and"

	check_list += "\t <span class='[no_damage ? "notice" : "warning"]'>Your [name][is_disabled][self_aware ? " has " : " is "][status].</span>"

	for(var/datum/wound/wound as anything in wounds)
		switch(wound.severity)
			if(WOUND_SEVERITY_TRIVIAL)
				check_list += "\t [span_danger("Your [name] is suffering [wound.a_or_from] [lowertext(wound.name)].")]"
			if(WOUND_SEVERITY_MODERATE)
				check_list += "\t [span_warning("Your [name] is suffering [wound.a_or_from] [lowertext(wound.name)]!")]"
			if(WOUND_SEVERITY_SEVERE)
				check_list += "\t [span_boldwarning("Your [name] is suffering [wound.a_or_from] [lowertext(wound.name)]!")]"
			if(WOUND_SEVERITY_CRITICAL)
				check_list += "\t [span_boldwarning("Your [name] is suffering [wound.a_or_from] [lowertext(wound.name)]!!")]"

	for(var/obj/item/embedded_thing in embedded_objects)
		var/stuck_word = embedded_thing.isEmbedHarmless() ? "stuck" : "embedded"
		check_list += "\t <a href='?src=[REF(examiner)];embedded_object=[REF(embedded_thing)];embedded_limb=[REF(src)]' class='warning'>There is \a [embedded_thing] [stuck_word] in your [name]!</a>"


/obj/item/bodypart/blob_act()
	receive_damage(max_damage)

/obj/item/bodypart/attack(mob/living/carbon/victim, mob/user)
	SHOULD_CALL_PARENT(TRUE)

	if(ishuman(victim))
		var/mob/living/carbon/human/human_victim = victim
		if(HAS_TRAIT(victim, TRAIT_LIMBATTACHMENT))
			if(!human_victim.get_bodypart(body_zone))
				user.temporarilyRemoveItemFromInventory(src, TRUE)
				if(!try_attach_limb(victim))
					to_chat(user, span_warning("[human_victim]'s body rejects [src]!"))
					forceMove(human_victim.loc)
					return
				if(check_for_frankenstein(victim))
					bodypart_flags |= BODYPART_IMPLANTED
				if(human_victim == user)
					human_victim.visible_message(span_warning("[human_victim] jams [src] into [human_victim.p_their()] empty socket!"),\
					span_notice("You force [src] into your empty socket, and it locks into place!"))
				else
					human_victim.visible_message(span_warning("[user] jams [src] into [human_victim]'s empty socket!"),\
					span_notice("[user] forces [src] into your empty socket, and it locks into place!"))
				return
	return ..()

/obj/item/bodypart/attackby(obj/item/weapon, mob/user, params)
	SHOULD_CALL_PARENT(TRUE)

	if(weapon.get_sharpness())
		add_fingerprint(user)
		if(!contents.len)
			to_chat(user, span_warning("There is nothing left inside [src]!"))
			return
		playsound(loc, 'sound/weapons/slice.ogg', 50, TRUE, -1)
		user.visible_message(span_warning("[user] begins to cut open [src]."),\
			span_notice("You begin to cut open [src]..."))
		if(do_after(user, 54, target = src))
			drop_contents(user, TRUE)
	else
		return ..()

/obj/item/bodypart/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	SHOULD_CALL_PARENT(TRUE)

	..()
	if(IS_ORGANIC_LIMB(src))
		playsound(get_turf(src), 'sound/misc/splort.ogg', 50, TRUE, -1)
	pixel_x = rand(-3, 3)
	pixel_y = rand(-3, 3)

//Bodyparts should always be facing south
/obj/item/bodypart/setDir(newdir)
	. = ..()
	dir = SOUTH
	return

//empties the bodypart from its organs and other things inside it
/obj/item/bodypart/proc/drop_contents(mob/user, violent_removal)
	SHOULD_CALL_PARENT(TRUE)

	var/atom/drop_loc = drop_location()
	if(IS_ORGANIC_LIMB(src))
		playsound(drop_loc, 'sound/misc/splort.ogg', 50, TRUE, -1)

	if(splint)
		remove_splint()
	if(bandage)
		remove_bandage()

	for(var/obj/item/I in cavity_items)
		remove_cavity_item(I)
		I.forceMove(bodypart_turf)

	for(var/obj/item/organ/bodypart_organ in get_organs())
		bodypart_organ.transfer_to_limb(src, null)

	for(var/obj/item/item_in_bodypart in src)
		if(istype(item_in_bodypart, /obj/item/organ))
			var/obj/item/organ/O = item_in_bodypart
			if(O.organ_flags & ORGAN_UNREMOVABLE)
				continue

		item_in_bodypart.forceMove(bodypart_turf)

	for(var/obj/item/organ/external/external in external_organs)
		external.remove_from_limb()
		external.forceMove(drop_loc)
	for(var/obj/item/item_in_bodypart in src)
		item_in_bodypart.forceMove(drop_loc)

	update_icon_dropped()

//Return TRUE to get whatever mob this is in to update health.
/obj/item/bodypart/proc/on_life(delta_time, times_fired)
	SHOULD_CALL_PARENT(TRUE)
	//DO NOT update health here, it'll be done in the carbon's life.
	if(stamina_dam > DAMAGE_PRECISION && owner.stam_regen_start_time <= world.time)
		heal_damage(0, 0, INFINITY, null, FALSE)
		. |= BODYPART_LIFE_UPDATE_HEALTH

	. |= wound_life()

/obj/item/bodypart/proc/wound_life()
	if(!LAZYLEN(wounds))
		return

	if(!IS_ORGANIC_LIMB(src)) //Robotic limbs don't heal or get worse.
		for(var/datum/wound/W as anything in wounds) //Repaired wounds disappear though
			if(W.damage <= 0)  //and they disappear right away
				qdel(W)
		return

	for(var/datum/wound/W as anything in wounds)
		// wounds can disappear after 10 minutes at the earliest
		if(W.damage <= 0 && W.created + (10 MINUTES) <= world.time)
			qdel(W)
			continue
			// let the GC handle the deletion of the wound

		// slow healing
		var/heal_amt = 0
		// if damage >= 50 AFTER treatment then it's probably too severe to heal within the timeframe of a round.
		if ( W.can_autoheal() && W.wound_damage() && brute_ratio < 0.5 && burn_ratio < 0.5)
			heal_amt += 0.5

		//configurable regen speed woo, no-regen hardcore or instaheal hugbox, choose your destiny
		heal_amt = heal_amt * WOUND_REGENERATION_MODIFIER
		// amount of healing is spread over all the wounds
		heal_amt = heal_amt / (LAZYLEN(wounds) + 1)
		// making it look prettier on scanners
		heal_amt = round(heal_amt,0.1)
		var/dam_type = BRUTE
		if (W.wound_type == WOUND_BURN)
			dam_type = BURN
		if(owner.can_autoheal(dam_type))
			W.heal_damage(heal_amt)

	// sync the bodypart's damage with its wounds
	if(update_damage())
		return BODYPART_LIFE_UPDATE_HEALTH

/**
 * #receive_damage
 *
 * called when a bodypart is taking damage
 * Damage will not exceed max_damage using this proc, and negative damage cannot be used to heal
 * Returns TRUE if damage icon states changes
 * Args:
 * brute - The amount of brute damage dealt.
 * burn - The amount of burn damage dealt.
 * blocked - The amount of damage blocked by armor.
 * update_health - Whether to update the owner's health from receiving the hit.
 * required_bodytype - A bodytype flag requirement to get this damage (ex: BODYTYPE_ORGANIC)
 * wound_bonus - Additional bonus chance to get a wound.
 * bare_wound_bonus - Additional bonus chance to get a wound if the bodypart is naked.
 * sharpness - Flag on whether the attack is edged or pointy
 * attack_direction - The direction the bodypart is attacked from, used to send blood flying in the opposite direction.
 * damage_source - The source of damage, typically a weapon.
 */
/obj/item/bodypart/proc/receive_damage(brute = 0, burn = 0, blocked = 0, updating_health = TRUE, required_bodytype = null, sharpness = NONE, damage_source, no_side_effects = FALSE)
	SHOULD_CALL_PARENT(TRUE)

	var/hit_percent = (100-blocked)/100
	if((!brute && !burn) || hit_percent <= 0)
		return FALSE
	if(owner && (owner.status_flags & GODMODE))
		return FALSE	//godmode
	if(required_bodytype && !(bodytype & required_bodytype))
		return FALSE

	var/dmg_multi = CONFIG_GET(number/damage_multiplier) * hit_percent
	brute = round(max(brute * dmg_multi, 0),DAMAGE_PRECISION)
	burn = round(max(burn * dmg_multi, 0),DAMAGE_PRECISION)
	brute = max(0, brute - brute_reduction)
	burn = max(0, burn - burn_reduction)

	if(!brute && !burn)
		return FALSE

	if(bodytype & (BODYTYPE_ALIEN|BODYTYPE_LARVA_PLACEHOLDER)) //aliens take double burn //nothing can burn with so much snowflake code around
		burn *= 2

	var/spillover = 0
	var/pure_brute = brute
	var/damagable = ((brute_dam + burn_dam) < max_damage)

	spillover = brute_dam + burn_dam + brute - max_damage
	if(spillover > 0)
		brute = max(brute - spillover, 0)
	else
		spillover = brute_dam + burn_dam + brute + burn - max_damage
		if(spillover > 0)
			burn = max(burn - spillover, 0)

	/*
	// DISMEMBERMENT
	*/
	if(owner)
		var/total_damage = brute_dam + burn_dam + burn + brute
		if(total_damage >= max_damage * LIMB_DISMEMBERMENT_PERCENT)
			if(attempt_dismemberment(brute, burn, sharpness))
				return update_bodypart_damage_state() || .


	//blunt damage is gud at fracturing
	if(!no_side_effects)
		if(brute)
			jostle_bones(brute)
			if(owner && prob(40))
				INVOKE_ASYNC(owner, /mob/proc/emote, "scream")
			if((brute_dam + brute > minimum_break_damage) && prob((brute_dam + brute * (1 + !sharpness)) * BODYPART_BONES_BREAK_CHANCE_MOD))
				break_bones()

	if(!damagable)
		return FALSE

	/*
	// START WOUND HANDLING
	*/
	// If the limbs can break, make sure we don't exceed the maximum damage a limb can take before breaking
	var/block_cut = (pure_brute < 10) || !IS_ORGANIC_LIMB(src)
	var/can_cut = !block_cut && ((sharpness) || prob(brute))
	if(brute)
		var/to_create = WOUND_BRUISE
		if(can_cut)
			to_create = WOUND_CUT
			//need to check sharp again here so that blunt damage that was strong enough to break skin doesn't give puncture wounds
			if(sharpness && !(sharpness & SHARP_EDGED))
				to_create = WOUND_PIERCE
		create_wound(to_create, brute, update_damage = FALSE)
	if(burn)
		/* Laser damage isnt a damage type yet
		if(laser)
			createwound(INJURY_TYPE_LASER, burn)
			if(prob(40))
				owner.IgniteMob()
		else
		*/
		create_wound(WOUND_BURN, burn, update_damage = FALSE)
	//Disturb treated burns
	if(brute > 5)
		var/disturbed = 0
		for(var/datum/wound/burn/W in wounds)
			if((W.disinfected || W.salved) && prob(brute + W.damage))
				W.disinfected = 0
				W.salved = 0
				disturbed += W.damage
		if(disturbed)
			to_chat(owner, span_warning("Ow! Your burns were disturbed."))

	/*
	// END WOUND HANDLING
	*/

	update_damage()

	if(owner)
		update_disabled()
		if(updating_health)
			owner.updatehealth()
	return update_bodypart_damage_state() || .

/// Returns a bitflag using ANATOMY_EXTERIOR or ANATOMY_INTERIOR. Used to determine if we as a whole have a interior or exterior biostate, or both.
/obj/item/bodypart/proc/get_bio_state_status()
	SHOULD_BE_PURE(TRUE)

	var/bio_status = NONE

	for (var/state as anything in GLOB.bio_state_anatomy)
		var/flag = text2num(state)
		if (!(biological_state & flag))
			continue

		var/value = GLOB.bio_state_anatomy[state]
		if (value & ANATOMY_EXTERIOR)
			bio_status |= ANATOMY_EXTERIOR
		if (value & ANATOMY_INTERIOR)
			bio_status |= ANATOMY_INTERIOR

		if ((bio_status & ANATOMY_EXTERIOR_AND_INTERIOR) == ANATOMY_EXTERIOR_AND_INTERIOR)
			break

	return bio_status

/// Returns if our current mangling status allows us to be dismembered. Requires both no exterior/mangled exterior and no interior/mangled interior.
/obj/item/bodypart/proc/dismemberable_by_wound()
	SHOULD_BE_PURE(TRUE)

	var/mangled_state = get_mangled_state()

	var/bio_status = get_bio_state_status()

	var/has_exterior = ((bio_status & ANATOMY_EXTERIOR))
	var/has_interior = ((bio_status & ANATOMY_INTERIOR))

	var/exterior_ready_to_dismember = (!has_exterior || ((mangled_state & BODYPART_MANGLED_EXTERIOR)))
	var/interior_ready_to_dismember = (!has_interior || ((mangled_state & BODYPART_MANGLED_INTERIOR)))

	return (exterior_ready_to_dismember && interior_ready_to_dismember)

/// Returns TRUE if our total percent damage is more or equal to our dismemberable percentage, but FALSE if a wound can cause us to be dismembered.
/obj/item/bodypart/proc/dismemberable_by_total_damage()

	update_wound_theory()

	var/bio_status = get_bio_state_status()

	var/has_interior = ((bio_status & ANATOMY_INTERIOR))
	var/can_theoretically_be_dismembered_by_wound = (any_existing_wound_can_mangle_our_interior || (any_existing_wound_can_mangle_our_exterior && has_interior))

	var/wound_dismemberable = dismemberable_by_wound()
	var/ready_to_use_alternate_formula = (use_alternate_dismemberment_calc_even_if_mangleable || (!wound_dismemberable && !can_theoretically_be_dismembered_by_wound))

	if (ready_to_use_alternate_formula)
		var/percent_to_total_max = (get_damage() / max_damage)
		if (percent_to_total_max >= hp_percent_to_dismemberable)
			return TRUE

	return FALSE

/// Updates our "can be theoretically dismembered by wounds" variables by iterating through all wound static data.
/obj/item/bodypart/proc/update_wound_theory()
	// We put this here so we dont increase init time by doing this all at once on initialization
	// Effectively, we "lazy load"
	if (isnull(any_existing_wound_can_mangle_our_interior) || isnull(any_existing_wound_can_mangle_our_exterior))
		any_existing_wound_can_mangle_our_interior = FALSE
		any_existing_wound_can_mangle_our_exterior = FALSE
		for (var/datum/wound/wound_type as anything in GLOB.all_wound_pregen_data)
			var/datum/wound_pregen_data/pregen_data = GLOB.all_wound_pregen_data[wound_type]
			if (!pregen_data.can_be_applied_to(src, random_roll = TRUE)) // we only consider randoms because non-randoms are usually really specific
				continue
			if (initial(pregen_data.wound_path_to_generate.wound_flags) & MANGLES_EXTERIOR)
				any_existing_wound_can_mangle_our_exterior = TRUE
			if (initial(pregen_data.wound_path_to_generate.wound_flags) & MANGLES_INTERIOR)
				any_existing_wound_can_mangle_our_interior = TRUE

			if (any_existing_wound_can_mangle_our_interior && any_existing_wound_can_mangle_our_exterior)
				break

//Heals brute and burn damage for the organ. Returns 1 if the damage-icon states changed at all.
//Damage cannot go below zero.
//Cannot remove negative damage (i.e. apply damage)
/obj/item/bodypart/proc/heal_damage(brute, burn, required_bodytype, updating_health = TRUE)
	SHOULD_CALL_PARENT(TRUE)

	if(required_bodytype && !(bodytype & required_bodytype)) //So we can only heal certain kinds of limbs, ie robotic vs organic.
		return

	//Heal damage on the individual wounds
	for(var/datum/wound/W as anything in wounds)
		if(brute == 0 && burn == 0)
			break

		// heal brute damage
		if (W.wound_type == WOUND_BURN)
			burn = W.heal_damage(burn)
		else
			brute = W.heal_damage(brute)

	update_damage()

	if(owner)
		update_disabled()
		if(updating_health)
			owner.updatehealth()
	cremation_progress = min(0, cremation_progress - ((brute_dam + burn_dam)*(100/max_damage)))
	return update_bodypart_damage_state()

//Returns total damage.
/obj/item/bodypart/proc/get_damage()
	var/total = brute_dam + burn_dam
	return total

///Proc to update the damage values of the bodypart.
/obj/item/bodypart/proc/update_damage()
	var/old_brute = brute_dam
	var/old_burn = burn_dam
	real_wound_count = 0
	brute_dam = 0
	burn_dam = 0

	//update damage counts
	for(var/datum/wound/W as anything in wounds)

		if(W.damage <= 0)
			qdel(W)
			continue

		if (W.wound_type == WOUND_BURN)
			burn_dam += W.damage
		else
			brute_dam += W.damage

		real_wound_count += W.amount

	current_damage = round(brute_dam + burn_dam, DAMAGE_PRECISION)
	burn_dam = round(burn_dam, DAMAGE_PRECISION)
	brute_dam = round(brute_dam, DAMAGE_PRECISION)
	var/limb_loss_threshold = max_damage
	brute_ratio = brute_dam / (limb_loss_threshold * 2)
	burn_ratio = burn_dam / (limb_loss_threshold * 2)

	. = (old_brute != brute_dam || old_burn != burn_dam)
	if(.)
		refresh_bleed_rate()

//Checks disabled status thresholds
/obj/item/bodypart/proc/update_disabled()
	SHOULD_CALL_PARENT(TRUE)

	if(!owner)
		return

	if(bodypart_flags & (BP_CUT_AWAY|BP_TENDON_CUT))
		set_disabled(TRUE)
		return

	if(!can_be_disabled)
		set_disabled(FALSE)
		return

	if(HAS_TRAIT(src, TRAIT_PARALYSIS))
		set_disabled(TRUE)
		return

	var/total_damage = brute_dam + burn_dam

	// this block of checks is for limbs that can be disabled, but not through pure damage (AKA limbs that suffer wounds, human/monkey parts and such)
	if(!disabling_threshold_percentage)
		if(total_damage < max_damage)
			last_maxed = FALSE
		else
			if(!last_maxed && owner.stat < UNCONSCIOUS)
				INVOKE_ASYNC(owner, TYPE_PROC_REF(/mob, emote), "scream")
			last_maxed = TRUE
		set_disabled(FALSE) // we only care about the paralysis trait
		return

	// we're now dealing solely with limbs that can be disabled through pure damage, AKA robot parts
	if(total_damage >= max_damage * disabling_threshold_percentage)
		if(!last_maxed)
			if(owner.stat < UNCONSCIOUS)
				INVOKE_ASYNC(owner, TYPE_PROC_REF(/mob, emote), "scream")
			last_maxed = TRUE
		set_disabled(TRUE)
		return

	if(bodypart_disabled && total_damage <= max_damage * 0.5) // reenable the limb at 50% health
		last_maxed = FALSE
		set_disabled(FALSE)


///Proc to change the value of the `disabled` variable and react to the event of its change.
/obj/item/bodypart/proc/set_disabled(new_disabled)
	SHOULD_CALL_PARENT(TRUE)
	PROTECTED_PROC(TRUE)

	if(bodypart_disabled == new_disabled)
		return
	. = bodypart_disabled
	bodypart_disabled = new_disabled

	if(!owner)
		return

	if(bodypart_flags & BP_IS_MOVEMENT_LIMB)
		if(!.)
			if(bodypart_disabled)
				owner.set_usable_legs(owner.usable_legs - 1)
				if(owner.stat < UNCONSCIOUS)
					to_chat(owner, span_userdanger("You lose control of your [plaintext_zone]!"))
		else if(!bodypart_disabled)
			owner.set_usable_legs(owner.usable_legs + 1)

	if(bodypart_flags & BP_IS_GRABBY_LIMB)
		if(!.)
			if(bodypart_disabled)
				owner.set_usable_hands(owner.usable_hands - 1)
				if(owner.stat < UNCONSCIOUS)
					to_chat(owner, span_userdanger("You lose control of your [plaintext_zone]!"))
				if(held_index)
					owner.dropItemToGround(owner.get_item_for_held_index(held_index))
		else if(!bodypart_disabled)
			owner.set_usable_hands(owner.usable_hands + 1)

		if(owner.hud_used)
			var/atom/movable/screen/inventory/hand/hand_screen_object = owner.hud_used.hand_slots["[held_index]"]
			hand_screen_object?.update_appearance()

	owner.update_health_hud() //update the healthdoll
	owner.update_body()


///Proc to change the value of the `owner` variable and react to the event of its change.
/obj/item/bodypart/proc/set_owner(new_owner)
	SHOULD_CALL_PARENT(TRUE)
	if(owner == new_owner)
		return FALSE //`null` is a valid option, so we need to use a num var to make it clear no change was made.
	var/mob/living/carbon/old_owner = owner
	owner = new_owner
	var/needs_update_disabled = FALSE //Only really relevant if there's an owner
	if(old_owner)
		if(initial(can_be_disabled))
			if(HAS_TRAIT(old_owner, TRAIT_NOLIMBDISABLE))
				if(!owner || !HAS_TRAIT(owner, TRAIT_NOLIMBDISABLE))
					set_can_be_disabled(initial(can_be_disabled))
					needs_update_disabled = TRUE
			UnregisterSignal(old_owner, list(
				SIGNAL_REMOVETRAIT(TRAIT_NOLIMBDISABLE),
				SIGNAL_ADDTRAIT(TRAIT_NOLIMBDISABLE),
				SIGNAL_REMOVETRAIT(TRAIT_NOBLOOD),
				SIGNAL_ADDTRAIT(TRAIT_NOBLOOD),
				))
		UnregisterSignal(old_owner, COMSIG_ATOM_RESTYLE)
	if(owner)
		if(initial(can_be_disabled))
			if(HAS_TRAIT(owner, TRAIT_NOLIMBDISABLE))
				set_can_be_disabled(FALSE)
				needs_update_disabled = FALSE
			RegisterSignal(owner, SIGNAL_REMOVETRAIT(TRAIT_NOLIMBDISABLE), PROC_REF(on_owner_nolimbdisable_trait_loss))
			RegisterSignal(owner, SIGNAL_ADDTRAIT(TRAIT_NOLIMBDISABLE), PROC_REF(on_owner_nolimbdisable_trait_gain))
			// Bleeding stuff
			RegisterSignal(owner, SIGNAL_REMOVETRAIT(TRAIT_NOBLOOD), PROC_REF(on_owner_nobleed_loss))
			RegisterSignal(owner, SIGNAL_ADDTRAIT(TRAIT_NOBLOOD), PROC_REF(on_owner_nobleed_gain))

		if(needs_update_disabled)
			update_disabled()

		RegisterSignal(owner, COMSIG_ATOM_RESTYLE, PROC_REF(on_attempt_feature_restyle_mob))

	update_damage()
	return old_owner

/obj/item/bodypart/proc/on_removal()
	for(var/trait in bodypart_traits)
		REMOVE_TRAIT(owner, trait, bodypart_trait_source)

///Proc to change the value of the `can_be_disabled` variable and react to the event of its change.
/obj/item/bodypart/proc/set_can_be_disabled(new_can_be_disabled)
	PROTECTED_PROC(TRUE)
	SHOULD_CALL_PARENT(TRUE)

	if(can_be_disabled == new_can_be_disabled)
		return
	. = can_be_disabled
	can_be_disabled = new_can_be_disabled
	if(can_be_disabled)
		if(owner)
			if(HAS_TRAIT(owner, TRAIT_NOLIMBDISABLE))
				CRASH("set_can_be_disabled to TRUE with for limb whose owner has TRAIT_NOLIMBDISABLE")
			RegisterSignal(owner, SIGNAL_ADDTRAIT(TRAIT_PARALYSIS), PROC_REF(on_paralysis_trait_gain))
			RegisterSignal(owner, SIGNAL_REMOVETRAIT(TRAIT_PARALYSIS), PROC_REF(on_paralysis_trait_loss))
		update_disabled()
	else if(.)
		if(owner)
			UnregisterSignal(owner, list(
				SIGNAL_ADDTRAIT(TRAIT_PARALYSIS),
				SIGNAL_REMOVETRAIT(TRAIT_PARALYSIS),
				))
		set_disabled(FALSE)


///Called when TRAIT_PARALYSIS is added to the limb.
/obj/item/bodypart/proc/on_paralysis_trait_gain(obj/item/bodypart/source)
	PROTECTED_PROC(TRUE)
	SIGNAL_HANDLER

	if(can_be_disabled)
		set_disabled(TRUE)


///Called when TRAIT_PARALYSIS is removed from the limb.
/obj/item/bodypart/proc/on_paralysis_trait_loss(obj/item/bodypart/source)
	PROTECTED_PROC(TRUE)
	SIGNAL_HANDLER

	if(can_be_disabled)
		update_disabled()


///Called when TRAIT_NOLIMBDISABLE is added to the owner.
/obj/item/bodypart/proc/on_owner_nolimbdisable_trait_gain(mob/living/carbon/source)
	PROTECTED_PROC(TRUE)
	SIGNAL_HANDLER

	set_can_be_disabled(FALSE)


///Called when TRAIT_NOLIMBDISABLE is removed from the owner.
/obj/item/bodypart/proc/on_owner_nolimbdisable_trait_loss(mob/living/carbon/source)
	PROTECTED_PROC(TRUE)
	SIGNAL_HANDLER

	set_can_be_disabled(initial(can_be_disabled))

//Updates an organ's brute/burn states for use by update_damage_overlays()
//Returns 1 if we need to update overlays. 0 otherwise.
/obj/item/bodypart/proc/update_bodypart_damage_state()
	SHOULD_CALL_PARENT(TRUE)

	var/tbrute = round( (brute_dam/max_damage)*3, 1 )
	var/tburn = round( (burn_dam/max_damage)*3, 1 )
	if((tbrute != brutestate) || (tburn != burnstate))
		brutestate = tbrute
		burnstate = tburn
		return TRUE
	return FALSE

//we inform the bodypart of the changes that happened to the owner, or give it the informations from a source mob.
//set is_creating to true if you want to change the appearance of the limb outside of mutation changes or forced changes.
/obj/item/bodypart/proc/update_limb(dropping_limb = FALSE, is_creating = FALSE)
	SHOULD_CALL_PARENT(TRUE)

	if(IS_ORGANIC_LIMB(src))
		if(HAS_TRAIT(owner, TRAIT_HUSK))
			dmg_overlay_type = "" //no damage overlay shown when husked
			is_husked = TRUE
		else if(HAS_TRAIT(owner, TRAIT_INVISIBLE_MAN))
			dmg_overlay_type = "" //no damage overlay shown when invisible since the wounds themselves are invisible.
			is_invisible = TRUE
		else
			dmg_overlay_type = initial(dmg_overlay_type)
			is_husked = FALSE
			is_invisible = FALSE

	if(variable_color)
		draw_color = variable_color
	else if(should_draw_greyscale)
		draw_color = (skin_tone && skintone2hex(skin_tone))
	else
		draw_color = null

	if(!is_creating || !owner)
		return

	// There should technically to be an ishuman(owner) check here, but it is absent because no basetype carbons use bodyparts
	// No, xenos don't actually use bodyparts. Don't ask.
	var/mob/living/carbon/human/human_owner = owner
	var/datum/species/owner_species = human_owner.dna.species
	species_flags_list = owner_species.species_traits
	limb_gender = (human_owner.physique == MALE) ? "m" : "f"

	if(human_owner.dna.species.fixed_mut_color)
		skin_tone = human_owner.dna.species.fixed_mut_color
	else if(human_owner.skin_tone)
		skin_tone = human_owner.skin_tone

	draw_color = variable_color
	if(should_draw_greyscale) //Should the limb be colored?
		draw_color ||= (skin_tone && skintone2hex(skin_tone))

	recolor_cosmetic_organs()
	return TRUE

//to update the bodypart's icon when not attached to a mob
/obj/item/bodypart/proc/update_icon_dropped()
	SHOULD_CALL_PARENT(TRUE)

	cut_overlays()
	if(is_stump)
		return

	dir = SOUTH
	var/list/standing = get_limb_icon(TRUE)
	if(!standing.len)
		icon_state = initial(icon_state)//no overlays found, we default back to initial icon.
		return
	for(var/image/img as anything in standing)
		img.pixel_x = px_x
		img.pixel_y = px_y
	add_overlay(standing)

///Generates an /image for the limb to be used as an overlay
/obj/item/bodypart/proc/get_limb_icon(dropped)
	SHOULD_CALL_PARENT(TRUE)
	RETURN_TYPE(/list)

	icon_state = "" //to erase the default sprite, we're building the visual aspects of the bodypart through overlays alone.

	. = list()

	var/image_dir = NONE
	if(dropped)
		image_dir = SOUTH
		if(dmg_overlay_type)
			if(brutestate)
				. += image('icons/mob/effects/dam_mob.dmi', "[dmg_overlay_type]_[body_zone]_[brutestate]0", -DAMAGE_LAYER, image_dir)
			if(burnstate)
				. += image('icons/mob/effects/dam_mob.dmi', "[dmg_overlay_type]_[body_zone]_0[burnstate]", -DAMAGE_LAYER, image_dir)

	var/image/limb = image(layer = -BODYPARTS_LAYER, dir = image_dir)
	var/image/aux

	// Handles making bodyparts look husked
	if(is_husked)
		limb.icon = icon_husk
		limb.icon_state = "[husk_type]_husk_[body_zone]"
		icon_exists(limb.icon, limb.icon_state, scream = TRUE) //Prints a stack trace on the first failure of a given iconstate.
		. += limb
		if(aux_zone) //Hand shit
			aux = image(limb.icon, "[husk_type]_husk_[aux_zone]", -aux_layer, image_dir)
			. += aux

	// Handles invisibility (not alpha or actual invisibility but invisibility)
	if(is_invisible)
		limb.icon = icon_invisible
		limb.icon_state = "invisible_[body_zone]"
		. += limb
		return .

	// Normal non-husk handling
	if(!is_husked)
		// This is the MEAT of limb icon code
		limb.icon = icon_greyscale
		if(!should_draw_greyscale || !icon_greyscale)
			limb.icon = icon_static

		if(is_dimorphic) //Does this type of limb have sexual dimorphism?
			limb.icon_state = "[limb_id]_[body_zone]_[limb_gender]"
		else
			limb.icon_state = "[limb_id]_[body_zone]"

		icon_exists(limb.icon, limb.icon_state, TRUE) //Prints a stack trace on the first failure of a given iconstate.

		. += limb

		if(aux_zone) //Hand shit
			aux = image(limb.icon, "[limb_id]_[aux_zone]", -aux_layer, image_dir)
			. += aux

		draw_color = variable_color
		if(should_draw_greyscale) //Should the limb be colored outside of a forced color?
			draw_color ||= (skin_tone && skintone2hex(skin_tone))

		if(draw_color)
			limb.color = "[draw_color]"
			if(aux_zone)
				aux.color = "[draw_color]"

		//EMISSIVE CODE START
		// For some reason this was applied as an overlay on the aux image and limb image before.
		// I am very sure that this is unnecessary, and i need to treat it as part of the return list
		// to be able to mask it proper in case this limb is a leg.
		if(blocks_emissive)
			var/atom/location = loc || owner || src
			var/mutable_appearance/limb_em_block = emissive_blocker(limb.icon, limb.icon_state, location, alpha = limb.alpha)
			limb_em_block.dir = image_dir
			. += limb_em_block

			if(aux_zone)
				var/mutable_appearance/aux_em_block = emissive_blocker(aux.icon, aux.icon_state, location, alpha = aux.alpha)
				aux_em_block.dir = image_dir
				. += aux_em_block
		//EMISSIVE CODE END

	//Ok so legs are a bit goofy in regards to layering, and we will need two images instead of one to fix that
	if((body_zone == BODY_ZONE_R_LEG) || (body_zone == BODY_ZONE_L_LEG))
		var/obj/item/bodypart/leg/leg_source = src
		for(var/image/limb_image in .)
			//remove the old, unmasked image
			. -= limb_image
			//add two masked images based on the old one
			. += leg_source.generate_masked_leg(limb_image, image_dir)

	// And finally put bodypart_overlays on if not husked
	if(!is_husked)
		//Draw external organs like horns and frills
		for(var/obj/item/organ/visual_organ in cosmetic_organs)
			if(!dropped && !visual_organ.can_draw_on_bodypart(owner)) //if you want different checks for dropped bodyparts, you can insert it here
				continue
			//Some externals have multiple layers for background, foreground and between
			. += visual_organ.get_overlays(limb_gender, image_dir)
			for(var/external_layer in overlay.all_layers)
				if(overlay.layers & external_layer)
					. += overlay.get_overlay(external_layer, src)

	return .

///Add a bodypart overlay and call the appropriate update procs
/obj/item/bodypart/proc/add_bodypart_overlay(datum/bodypart_overlay/overlay)
	bodypart_overlays += overlay
	overlay.added_to_limb(src)

///Remove a bodypart overlay and call the appropriate update procs
/obj/item/bodypart/proc/remove_bodypart_overlay(datum/bodypart_overlay/overlay)
	bodypart_overlays -= overlay
	overlay.removed_from_limb(src)

/obj/item/bodypart/deconstruct(disassembled = TRUE)
	SHOULD_CALL_PARENT(TRUE)

	drop_contents()
	return ..()

/// INTERNAL PROC, DO NOT USE
/// Properly sets us up to manage an inserted embeded object
/obj/item/bodypart/proc/_embed_object(obj/item/embed)
	if(embed in embedded_objects) // go away
		return
	// We don't need to do anything with projectile embedding, because it will never reach this point
	RegisterSignal(embed, COMSIG_ITEM_EMBEDDING_UPDATE, PROC_REF(embedded_object_changed))
	embedded_objects += embed
	refresh_bleed_rate()

/// INTERNAL PROC, DO NOT USE
/// Cleans up any attachment we have to the embedded object, removes it from our list
/obj/item/bodypart/proc/_unembed_object(obj/item/unembed)
	UnregisterSignal(unembed, COMSIG_ITEM_EMBEDDING_UPDATE)
	embedded_objects -= unembed
	refresh_bleed_rate()

/obj/item/bodypart/proc/embedded_object_changed(obj/item/embedded_source)
	SIGNAL_HANDLER
	/// Embedded objects effect bleed rate, gotta refresh lads
	refresh_bleed_rate()

/// Sets our generic bleedstacks
/obj/item/bodypart/proc/setBleedStacks(set_to)
	SHOULD_CALL_PARENT(TRUE)
	adjustBleedStacks(set_to - generic_bleedstacks)

/// Modifies our generic bleedstacks. You must use this to change the variable
/// Takes the amount to adjust by, and the lowest amount we're allowed to have post adjust
/obj/item/bodypart/proc/adjustBleedStacks(adjust_by, minimum = -INFINITY)
	if(!adjust_by)
		return
	var/old_bleedstacks = generic_bleedstacks
	generic_bleedstacks = max(generic_bleedstacks + adjust_by, minimum)

	// If we've started or stopped bleeding, we need to refresh our bleed rate
	if((old_bleedstacks <= 0 && generic_bleedstacks > 0) \
		|| old_bleedstacks > 0 && generic_bleedstacks <= 0)
		refresh_bleed_rate()

/obj/item/bodypart/proc/on_owner_nobleed_loss(datum/source)
	SIGNAL_HANDLER
	refresh_bleed_rate()

/obj/item/bodypart/proc/on_owner_nobleed_gain(datum/source)
	SIGNAL_HANDLER
	refresh_bleed_rate()

/// Refresh the cache of our rate of bleeding sans any modifiers
/// ANYTHING ADDED TO THIS PROC NEEDS TO CALL IT WHEN IT'S EFFECT CHANGES
/obj/item/bodypart/proc/refresh_bleed_rate()
	SHOULD_NOT_OVERRIDE(TRUE)

	var/old_bleed_rate = cached_bleed_rate
	cached_bleed_rate = 0
	bodypart_flags &= ~BP_BLEEDING
	if(!owner)
		return

	if(!can_bleed())
		if(HAS_TRAIT(owner, TRAIT_NOBLEED) || !(bodypart_flags & BP_HAS_BLOOD))
			update_part_wound_overlay()
		return

	if(generic_bleedstacks > 0)
		cached_bleed_rate += 0.5

	if(check_artery() & CHECKARTERY_SEVERED)
		cached_bleed_rate += 5

	for(var/obj/item/embeddies in embedded_objects)
		if(!embeddies.isEmbedHarmless())
			cached_bleed_rate += 0.25

	for(var/datum/wound/iter_wound as anything in wounds)
		if(iter_wound.bleeding())
			cached_bleed_rate += round(iter_wound.damage / 40, DAMAGE_PRECISION)
			bodypart_flags |= BP_BLEEDING

	// Our bleed overlay is based directly off bleed_rate, so go aheead and update that would you?
	if(cached_bleed_rate != old_bleed_rate)
		update_part_wound_overlay()

	return cached_bleed_rate

/// Returns our bleed rate, taking into account laying down and grabbing the limb
/obj/item/bodypart/proc/get_modified_bleed_rate()
	var/bleed_rate = cached_bleed_rate
	if(owner.body_position == LYING_DOWN)
		bleed_rate *= 0.75
	if(grasped_by)
		bleed_rate *= 0.7
	if(bandage)
		bleed_rate *= bandage.absorption_rate_modifier
	return bleed_rate

// how much blood the limb needs to be losing per tick (not counting laying down/self grasping modifiers) to get the different bleed icons
#define BLEED_OVERLAY_LOW 0.5
#define BLEED_OVERLAY_MED 1.5
#define BLEED_OVERLAY_GUSH 3.25

/obj/item/bodypart/proc/update_part_wound_overlay()
	if(!owner || is_stump)
		return FALSE

	if(!can_bleed())
		if(bleed_overlay_icon)
			bleed_overlay_icon = null
			owner.update_wound_overlays()
		return FALSE

	var/bleed_rate = cached_bleed_rate
	var/new_bleed_icon = null

	switch(bleed_rate)
		if(-INFINITY to BLEED_OVERLAY_LOW)
			new_bleed_icon = null
		if(BLEED_OVERLAY_LOW to BLEED_OVERLAY_MED)
			new_bleed_icon = "[body_zone]_1"
		if(BLEED_OVERLAY_MED to BLEED_OVERLAY_GUSH)
			if(owner.body_position == LYING_DOWN || IS_IN_STASIS(owner) || owner.stat == DEAD)
				new_bleed_icon = "[body_zone]_2s"
			else
				new_bleed_icon = "[body_zone]_2"
		if(BLEED_OVERLAY_GUSH to INFINITY)
			if(IS_IN_STASIS(owner) || owner.stat == DEAD)
				new_bleed_icon = "[body_zone]_2s"
			else
				new_bleed_icon = "[body_zone]_3"

	if(new_bleed_icon != bleed_overlay_icon)
		bleed_overlay_icon = new_bleed_icon
		owner.update_wound_overlays()

#undef BLEED_OVERLAY_LOW
#undef BLEED_OVERLAY_MED
#undef BLEED_OVERLAY_GUSH

/obj/item/bodypart/proc/can_bleed()
	SHOULD_BE_PURE(TRUE)

	return ((biological_state & BIO_BLOODED) && (!owner || !HAS_TRAIT(owner, TRAIT_NOBLOOD)))

/obj/item/bodypart/proc/apply_bandage(obj/item/stack/new_bandage)
	if(bandage || !istype(new_bandage) || !new_bandage.absorption_capacity)
		return

	bandage = new_bandage.split_stack(null, 1)
	bandage.forceMove(src)
	RegisterSignal(bandage, COMSIG_PARENT_QDELETING, PROC_REF(bandage_gone))
	if(bandage.absorption_capacity && owner.stat < UNCONSCIOUS)
		for(var/datum/wound/iter_wound as anything in wounds)
			if(iter_wound.bleeding())
				to_chat(owner, span_warning("You feel blood pool on your [plaintext_zone]."))
				break

/obj/item/bodypart/proc/remove_bandage()
	if(!bandage)
		return FALSE

	. = bandage
	UnregisterSignal(bandage, COMSIG_PARENT_QDELETING)
	if(bandage.loc == src)
		bandage.forceMove(drop_location())
	bandage = null

/obj/item/bodypart/proc/bandage_gone(obj/item/stack/bandage)
	SIGNAL_HANDLER
	remove_bandage()

/obj/item/bodypart/proc/apply_splint(obj/item/splint)
	if(src.splint)
		return FALSE

	src.splint = splint
	if(istype(splint, /obj/item/stack))
		splint.forceMove(src)

	update_interaction_speed()
	RegisterSignal(splint, COMSIG_PARENT_QDELETING, PROC_REF(splint_gone))
	SEND_SIGNAL(src, COMSIG_LIMB_SPLINTED, splint)
	return TRUE

/obj/item/bodypart/leg/apply_splint(obj/item/splint)
	. = ..()
	if(!.)
		return
	owner.apply_status_effect(/datum/status_effect/limp)

/obj/item/bodypart/proc/remove_splint()
	if(!splint)
		return FALSE

	. = splint

	UnregisterSignal(splint, COMSIG_PARENT_QDELETING)
	if(splint.loc == src)
		splint.forceMove(drop_location())

	splint = null
	update_interaction_speed()
	SEND_SIGNAL(src, COMSIG_LIMB_UNSPLINTED, splint)

/obj/item/bodypart/proc/splint_gone(obj/item/source)
	SIGNAL_HANDLER
	remove_splint()

/obj/item/bodypart/drop_location()
	if(owner)
		return owner.drop_location()
	return ..()

///Loops through all of the bodypart's external organs and update's their color.
/obj/item/bodypart/proc/recolor_cosmetic_organs()
	for(var/obj/item/organ/ext_organ as anything in cosmetic_organs)
		overlay.inherit_color(src, force = TRUE)

///A multi-purpose setter for all things immediately important to the icon and iconstate of the limb.
/obj/item/bodypart/proc/change_appearance(icon, id, greyscale, dimorphic)
	var/icon_holder
	if(greyscale)
		icon_greyscale = icon
		icon_holder = icon
		should_draw_greyscale = TRUE
	else
		icon_static = icon
		icon_holder = icon
		should_draw_greyscale = FALSE

	if(id) //limb_id should never be falsey
		limb_id = id

	if(!isnull(dimorphic))
		is_dimorphic = dimorphic

	if(owner)
		owner.update_body_parts()
	else
		update_icon_dropped()

	//This foot gun needs a safety
	if(!icon_exists(icon_holder, "[limb_id]_[body_zone][is_dimorphic ? "_[limb_gender]" : ""]"))
		reset_appearance()
		stack_trace("change_appearance([icon], [id], [greyscale], [dimorphic]) generated null icon")

///Resets the base appearance of a limb to it's default values.
/obj/item/bodypart/proc/reset_appearance()
	icon_static = initial(icon_static)
	icon_greyscale = initial(icon_greyscale)
	limb_id = initial(limb_id)
	is_dimorphic = initial(is_dimorphic)
	should_draw_greyscale = initial(should_draw_greyscale)

	if(owner)
		owner.update_body_parts()
	else
		update_icon_dropped()

/obj/item/bodypart/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_WIRES || !(bodytype & BODYTYPE_ROBOTIC))
		return FALSE
	owner.visible_message(span_danger("[owner]'s [src.name] seems to malfunction!"))

	// with defines at the time of writing, this is 3 brute and 2 burn
	// 3 + 2 = 5, with 6 limbs thats 30, on a heavy 60
	// 60 * 0.8 = 48
	var/time_needed = 10 SECONDS
	var/brute_damage = AUGGED_LIMB_EMP_BRUTE_DAMAGE
	var/burn_damage = AUGGED_LIMB_EMP_BURN_DAMAGE
	if(severity == EMP_HEAVY)
		time_needed *= 2
		brute_damage *= 2
		burn_damage *= 2

	receive_damage(brute_damage, burn_damage)
	do_sparks(number = 1, cardinal_only = FALSE, source = owner)
	ADD_TRAIT(src, TRAIT_PARALYSIS, EMP_TRAIT)
	addtimer(CALLBACK(src, PROC_REF(un_paralyze)), time_needed)
	return TRUE

/obj/item/bodypart/proc/un_paralyze()
	REMOVE_TRAITS_IN(src, EMP_TRAIT)

/// Returns the generic description of our BIO_EXTERNAL feature(s), prioritizing certain ones over others. Returns error on failure.
/obj/item/bodypart/proc/get_external_description()
	if (biological_state & BIO_FLESH)
		return "flesh"
	if (biological_state & BIO_WIRED)
		return "wiring"

	return "error"

/// Returns the generic description of our BIO_INTERNAL feature(s), prioritizing certain ones over others. Returns error on failure.
/obj/item/bodypart/proc/get_internal_description()
	if (biological_state & BIO_BONE)
		return "bone"
	if (biological_state & BIO_METAL)
		return "metal"

	return "error"

/// Add an item to our cavity. Call AFTER physically moving it via a proc like forceMove().
/obj/item/bodypart/proc/add_cavity_item(obj/item/I)
	cavity_items += I
	RegisterSignal(I, COMSIG_MOVABLE_MOVED, PROC_REF(item_gone))
	RegisterSignal(I, COMSIG_PARENT_QDELETING, PROC_REF(item_gone))

/obj/item/bodypart/proc/remove_cavity_item(obj/item/I)
	cavity_items -= I
	UnregisterSignal(I, COMSIG_MOVABLE_MOVED)
	UnregisterSignal(I, COMSIG_PARENT_QDELETING)

/obj/item/bodypart/proc/item_gone(datum/source)
	SIGNAL_HANDLER
	remove_cavity_item(source)

/obj/item/bodypart/proc/get_scan_results(tag)
	RETURN_TYPE(/list)
	SHOULD_CALL_PARENT(TRUE)
	. = list()
	if(!IS_ORGANIC_LIMB(src))
		. += tag ? "<span style='font-weight: bold; color: [COLOR_MEDICAL_ROBOTIC]'>Mechanical</span>" : "Mechanical"

	if(bodypart_flags & BP_CUT_AWAY)
		. += tag ? "<span style='font-weight: bold; color: [COLOR_MEDICAL_INTERNAL]'>Severed</span>" : "Severed"

	if(check_tendon() & CHECKTENDON_SEVERED)
		. += tag ? "<span style='font-weight: bold; color: [COLOR_MEDICAL_INTERNAL_DANGER]'>Severed [tendon_name]</span>" : "Severed [tendon_name]"

	if(check_artery() & CHECKARTERY_SEVERED)
		. += tag ? "<span style='font-weight: bold; color: [COLOR_MEDICAL_INTERNAL_DANGER]'>Severed [artery_name]</span>" : "Severed [artery_name]"

	if(check_bones() & CHECKBONES_BROKEN)
		. += tag ? "<span style='font-weight: bold; color: [COLOR_MEDICAL_INTERNAL_DANGER]'>Fractured</span>" : "Fractured"

	if (length(cavity_items))
		var/unknown_body = 0
		for(var/obj/item/I in cavity_items)
			if(istype(I,/obj/item/implant))
				var/obj/item/implant/imp = I
				if(imp.implant_flags & IMPLANT_HIDDEN)
					continue
				if (imp.implant_flags & IMPLANT_KNOWN)
					. += tag ? "<span style='font-weight: bold; color: [COLOR_MEDICAL_IMPLANT]'>[capitalize(imp.name)] implanted</span>" : "[capitalize(imp.name)] implanted"
					continue
			unknown_body++

		if(unknown_body)
			. += tag ? "<span style='font-weight: bold; color: [COLOR_MEDICAL_UNKNOWN_IMPLANT]'>Unknown body present</span>" : "Unknown body present"

/obj/item/bodypart/Topic(href, href_list)
	. = ..()
	if(QDELETED(src) || !owner)
		return

	if(!ishuman(usr))
		return

	var/mob/living/carbon/human/user = usr
	if(!user.Adjacent(owner))
		return

	if(user.get_active_held_item())
		return

	if(href_list["embedded_object"])
		var/obj/item/I = locate(href_list["embedded_object"]) in embedded_objects
		if(!I || I.loc != src) //no item, no limb, or item is not in limb or in the person anymore
			return
		SEND_SIGNAL(src, COMSIG_LIMB_EMBED_RIP, I, user)
		return

	if(href_list["splint_remove"])
		if(!splint)
			return

		if(do_after(user, owner, 5 SECONDS, DO_PUBLIC))
			var/obj/item/removed = remove_splint()
			if(!removed)
				return
			if(!user.put_in_hands(removed))
				removed.forceMove(user.drop_location())
			if(user == owner)
				user.visible_message(span_notice("[user] removes [removed] from [user.p_their()] [plaintext_zone]."))
			else
				user.visible_message(span_notice("[user] removes [removed] from [owner]'s [plaintext_zone]."))
		return

	if(href_list["bandage_remove"])
		if(!bandage)
			return

		if(do_after(user, owner, 5 SECONDS, DO_PUBLIC))
			var/obj/item/removed = remove_bandage()
			if(!removed)
				return
			if(!user.put_in_hands(removed))
				removed.forceMove(user.drop_location())
			if(user == owner)
				user.visible_message(span_notice("[user] removes [removed] from [user.p_their()] [plaintext_zone]."))
			else
				user.visible_message(span_notice("[user] removes [removed] from [owner]'s [plaintext_zone]."))
		return
