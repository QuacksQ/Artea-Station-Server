/datum/trade_hub
	/// Name of the trading hub
	var/name = "Trading Hub"
	/// Lazy list of possible names to randomize from
	var/possible_names
	/// Maximum number of traders it can house
	var/max_traders = 2
	/// A list of all the current traders inside
	var/list/traders = list()
	/// A list of all possible types of traders that can spawn in here. If left null, it'll allow all traders.
	var/list/possible_trader_types
	/// A list of all the trader types that we guarantee that will spawn, if able
	var/list/guaranteed_trader_types
	/// A list of connected trade consoles, in case the hub is destroyed we want to disconnect the consoles
	var/list/connected_consoles = list()
	var/id
	var/overmap_object

#define TRADE_HUB_SPAWN_TRIES 10

/datum/trade_hub/New(datum/overmap_object/overmap_object)
	..()
	src.overmap_object = overmap_object
	if(possible_names)
		name = pick(possible_names)
		possible_names = null
	id = SStrading.get_next_trade_hub_id()
	SStrading.trade_hubs["[id]"] = src
	if(!possible_trader_types)
		possible_trader_types = subtypesof(/datum/trader)

	var/already_picked_list = SStrading.trader_types_spawned
	for(var/guaranteed_type in guaranteed_trader_types)
		if(!already_picked_list[guaranteed_type])
			SpawnTraderType(guaranteed_type)
	guaranteed_trader_types = null
	for(var/i in 1 to max_traders)
		if(length(traders) >= max_traders)
			break
		if(!length(possible_trader_types))
			break
		for(var/b in 1 to TRADE_HUB_SPAWN_TRIES)
			var/picked_type = pick_n_take(possible_trader_types)
			if(picked_type && !already_picked_list[picked_type])
				SpawnTraderType(picked_type)
				break
	possible_trader_types = null

#undef TRADE_HUB_SPAWN_TRIES

/datum/trade_hub/proc/SpawnTraderType(picked_type)
	SStrading.trader_types_spawned[picked_type] = TRUE
	new picked_type(src)

/datum/trade_hub/Destroy(force)
	SStrading.trade_hubs -= "[id]"
	QDEL_LIST(traders)
	traders = null
	for(var/i in connected_consoles)
		var/obj/machinery/computer/trade_console/console = i
		console.disconnect_hub()
	connected_consoles = null
	return ..()

/datum/trade_hub/proc/Tick()
	for(var/i in traders)
		var/datum/trader/trader = i
		trader.tick()

/datum/trade_hub/worldwide
	name = "Global Trade Network"

/datum/trade_hub/worldwide/bearcat
	name = "FTU Tradehouse Network"
	max_traders = 6
	guaranteed_trader_types = list(/datum/trader/mining, /datum/trader/medical, /datum/trader/scrapper)

/datum/trade_hub/randomname
	possible_names = list("SCG Emporium", "Spacedust Cleaners Co.", "Northwind Traders", "Space Coast Trading", "Plasma Enterprises", "Off-branch Trasen Co.")

// A just-in-case trader, in case crew get unlucky with planetary spawns.
/datum/trade_hub/randomname/artea_scrapper
	name = "Artean Scrapheap"
	possible_names = list("ALS Keelhaul", "ALS Brighter Days", "ALS Scorchmark")
	guaranteed_trader_types = list(/datum/trader/scrapper)

/datum/trade_hub/randomname/large
	max_traders = 8
	guaranteed_trader_types = list(/datum/trader/mining, /datum/trader/medical, /datum/trader/archeology)
