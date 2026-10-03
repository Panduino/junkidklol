return function(mod)
  mod.options:define({
    { key = "debug_ticket_events", label = "DEBUG TICKET EVENTS", type = "toggle", default = false },
  })

  local function debugTicketEvents()
    return mod.options:get("debug_ticket_events") == true
  end

  if mod.generation ~= 3 then return end

  local REQUIRED = {
    "RealTimeClockTest",
    "untamed_advanced",
    "national_dex_gen3",
  }

  local found = {}
  for _, id in ipairs(REQUIRED) do
    local ok, other = pcall(function() return mod:find(id) end)
    if ok and other then
      found[id] = other
    else
      mod.log:warn("missing compatibility dependency: %s", id)
    end
  end

  local TYPE = {
    NORMAL = 0, FIGHTING = 1, FLYING = 2, POISON = 3, GROUND = 4,
    ROCK = 5, BUG = 6, GHOST = 7, STEEL = 8, FIRE = 10, WATER = 11,
    GRASS = 12, ELECTRIC = 13, PSYCHIC = 14, ICE = 15, DRAGON = 16,
    DARK = 17,
  }

  local PERIODS = { "morning", "day", "night" }
  local PERIOD_START = { morning = 4, day = 10, night = 18 }

  local function currentPeriod()
    local t = os.date("*t")
    local minutes = t.hour * 60 + t.min
    if minutes >= PERIOD_START.morning * 60 and minutes < PERIOD_START.day * 60 then
      return "morning"
    elseif minutes >= PERIOD_START.day * 60 and minutes < PERIOD_START.night * 60 then
      return "day"
    end
    return "night"
  end

  -- The base entries mirror recognizable HGSS Kanto encounters. The
  -- generated entries add Gen 1-4 habitat coverage around those anchors.
  local PROFILES = {
    { id="FR_ROUTE_1", habitat="field", min=2, max=6, gen=1, base={morning={16,19,161,162},day={16,19,161,162},night={19,163}} },
    { id="FR_ROUTE_2", habitat="forest", min=3, max=10, gen=1, base={morning={10,16,11,12,17,167,165,14,13,15,166},day={16,10,12,17,13,15,165},night={163,167,168,14,13,15}} },
    { id="FR_ROUTE_3", habitat="field", min=5, max=10, gen=1, base={morning={21,19,23,39,24},day={21,19,23,39,24},night={19,41,23,39,24}} },
    { id="FR_ROUTE_4", habitat="mountain", min=5, max=10, gen=1, base={morning={21,19,23,39,24},day={21,19,23,39,24},night={19,41,23,39,24}} },
    { id="FR_ROUTE_5", habitat="urban", min=12, max=15, gen=2, base={morning={16,69,52,63},day={16,69,52,63},night={43,52,69,44,63}} },
    { id="FR_ROUTE_6", habitat="field", min=12, max=16, gen=2, base={morning={16,69,43,63},day={16,69,52,63},night={19,52,163,200}} },
    { id="FR_ROUTE_7", habitat="urban", min=15, max=19, gen=2, base={morning={19,21,58,20,52,37,53},day={19,21,58,20,52,37,53},night={198,19,58,20,228,52,37,53}} },
    { id="FR_ROUTE_8", habitat="urban", min=15, max=19, gen=2, base={morning={17,63,58,64,52,37},day={17,63,58,64,52,37},night={163,93,63,58,64,52,37}} },
    { id="FR_ROUTE_9", habitat="field", min=13, max=15, gen=2, base={morning={56,19,21,20,22,57},day={56,19,21,20,22,57},night={19,56,20,57}} },
    { id="FR_ROUTE_10", habitat="electric", min=15, max=18, gen=2, base={morning={21,100,20,22,125},day={21,100,20,22,125},night={195,100,20,125}} },
    { id="FR_ROUTE_11", habitat="urban", min=13, max=18, gen=2, base={morning={20,96,100,97},day={20,96,100,97},night={20,97,100,163}} },
    { id="FR_ROUTE_12", habitat="marsh", min=18, max=25, gen=2, base={morning={16,118,43,114},day={16,118,43,114},night={163,195,200,118}} },
    { id="FR_ROUTE_13", habitat="marsh", min=22, max=25, gen=2, base={morning={30,33,17,187,113},day={30,33,17,187,113},night={30,33,164,195,113}} },
    { id="FR_ROUTE_14", habitat="field", min=23, max=26, gen=2, base={morning={30,33,17,187,188,113},day={30,33,17,187,188,113},night={30,33,164,195,113}} },
    { id="FR_ROUTE_15", habitat="field", min=22, max=25, gen=2, base={morning={30,33,17,187,113},day={30,33,17,187,113},night={30,33,164,195,113}} },
    { id="FR_ROUTE_16", habitat="urban", min=26, max=29, gen=2, base={morning={88,22,218,89},day={88,22,218,89},night={88,198,218,89}} },
    { id="FR_ROUTE_17", habitat="field", min=27, max=32, gen=2, base={morning={88,22,89,218},day={218,22,88,89},night={88,89,218}} },
    { id="FR_ROUTE_18", habitat="field", min=26, max=30, gen=2, base={morning={88,22,89,218},day={88,22,89,218},night={88,89,218}} },
    { id="FR_ROUTE_19", habitat="water", min=30, max=35, gen=2, water=true, base={morning={72,73},day={72,73},night={72,73}} },
    { id="FR_ROUTE_20", habitat="water", min=30, max=36, gen=2, water=true, base={morning={72,73,129,90},day={72,73,120,170},night={73,90,120,170}} },
    { id="FR_ROUTE_21", habitat="water", min=20, max=32, gen=4, water=true, base={morning={114,54,72,120},day={114,54,72,120},night={114,73,120,170}} },
    { id="FR_ROUTE_22", habitat="mountain", min=3, max=8, gen=1, base={morning={21,19,32,56},day={21,19,32,56},night={19,20,56,93}} },
    { id="FR_ROUTE_23", habitat="mountain", min=25, max=35, gen=2, base={morning={21,22,28,105},day={21,22,28,105},night={20,24,215,228}} },
    { id="FR_ROUTE_24", habitat="forest", min=8, max=14, gen=1, base={morning={16,69,63,10},day={16,69,63,10},night={19,43,92,93}} },
    { id="FR_ROUTE_25", habitat="forest", min=8, max=14, gen=1, base={morning={16,69,48,63,17,70},day={16,69,63,17,70},night={163,69,48,63,70}} },
    { id="FR_ROUTE_28", habitat="mountain", min=39, max=43, gen=4, base={morning={77,114,232,217,78,84,85},day={77,114,232,217,78,84,85},night={77,114,232,217,215,78}} },
    { id="FR_VIRIDIAN_FOREST", habitat="forest", min=3, max=8, gen=4, base={morning={10,11,12,13,14,15,16,17,172,325,322,406,455},day={10,11,13,14,16,17,172,325,322,406,455},night={163,172,325,322,406,455}} },
    { id="FR_DIGLETTS_CAVE", habitat="cave", min=13, max=29, gen=4, base={morning={50,51},day={50,51},night={50,51}} },
    { id="FR_MT_MOON_1F", habitat="cave", min=6, max=12, gen=4, base={morning={41,74,27,46,28,35},day={41,74,27,46,28,35},night={41,74,27,46,28,35}} },
    { id="FR_MT_MOON_B1F", habitat="cave", min=6, max=12, gen=4, base={morning={41,74,27,46,28,35},day={41,74,27,46,28,35},night={41,74,27,46,28,35}} },
    { id="FR_MT_MOON_B2F", habitat="cave", min=6, max=12, gen=4, base={morning={41,74,27,46,28,35},day={41,74,27,46,28,35},night={41,74,27,46,28,35}} },
    { id="FR_ROCK_TUNNEL_1F", habitat="cave", min=8, max=14, gen=4, base={morning={104,74,66,41,67,296,436,433},day={104,74,66,41,67,296,436,433},night={104,74,66,41,67,296,436,433}} },
    { id="FR_ROCK_TUNNEL_B1F", habitat="cave", min=10, max=16, gen=4, base={morning={74,104,95,41,105,115,296,436,433},day={74,104,95,41,105,115,296,436,433},night={74,104,95,41,105,115,296,436,433}} },
    { id="FR_POWER_PLANT", habitat="electric", min=20, max=35, gen=4, base={morning={81,100,25,125},day={81,100,25,125},night={81,100,125,479}} },
    { id="FR_POKEMON_TOWER_3F", habitat="ghost", min=22, max=30, gen=2, base={morning={92,93,200,355},day={92,93,200,355},night={92,93,200,355}} },
    { id="FR_POKEMON_TOWER_4F", habitat="ghost", min=23, max=31, gen=2, base={morning={92,93,200,355},day={92,93,200,355},night={92,93,200,355}} },
    { id="FR_POKEMON_TOWER_5F", habitat="ghost", min=24, max=32, gen=2, base={morning={92,93,200,355},day={92,93,200,355},night={92,93,200,355}} },
    { id="FR_POKEMON_TOWER_6F", habitat="ghost", min=25, max=33, gen=4, base={morning={92,93,200,355},day={92,93,200,355},night={92,93,200,355}} },
    { id="FR_POKEMON_TOWER_7F", habitat="ghost", min=26, max=34, gen=4, base={morning={92,93,200,355},day={92,93,200,355},night={92,93,200,355}} },
    { id="FR_SEAFOAM_ISLANDS_1F", habitat="ice", min=26, max=32, gen=4, base={morning={41,42,54,55,359,296,436,433},day={41,42,54,55,359,296,436,433},night={41,42,54,55,359,296,436,433}} },
    { id="FR_SEAFOAM_ISLANDS_B1F", habitat="ice", min=28, max=34, gen=4, base={morning={41,42,54,55,86,87,359,296,436,433},day={41,42,54,55,86,87,359,296,436,433},night={41,42,54,55,86,87,359,296,436,433}} },
    { id="FR_SEAFOAM_ISLANDS_B2F", habitat="ice", min=30, max=36, gen=4, base={morning={42,54,55,86,87,359,296,436,433},day={42,54,55,86,87,359,296,436,433},night={42,54,55,86,87,359,296,436,433}} },
    { id="FR_SEAFOAM_ISLANDS_B3F", habitat="ice", min=32, max=38, gen=4, base={morning={42,54,55,86,87,359,296,436,433},day={42,54,55,86,87,359,296,436,433},night={42,54,55,86,87,359,296,436,433}} },
    { id="FR_SEAFOAM_ISLANDS_B4F", habitat="ice", min=34, max=40, gen=4, base={morning={42,55,86,87,359,296,436,433},day={42,55,86,87,359,296,436,433},night={42,55,86,87,359,296,436,433}} },
    { id="FR_POKEMON_MANSION_1F", habitat="fire", min=30, max=40, gen=2, base={morning={58,77,88,109},day={58,77,88,109},night={109,88,200,228}} },
    { id="FR_POKEMON_MANSION_B1F", habitat="fire", min=32, max=42, gen=2, base={morning={58,77,88,109},day={58,77,88,109},night={109,88,200,228}} },
    { id="FR_POKEMON_MANSION_B2F", habitat="fire", min=34, max=44, gen=2, base={morning={58,77,88,109},day={58,77,88,109},night={109,88,200,228}} },
    { id="FR_POKEMON_MANSION_B3F", habitat="fire", min=36, max=46, gen=2, base={morning={58,77,88,109},day={58,77,88,109},night={109,88,200,228}} },
    { id="FR_CERULEAN_CAVE_1F", habitat="rare", min=38, max=46, gen=4, base={morning={67,67,67,67,67,47,47,47,47,57,57,57,53,53,53,82,82,132,132,42,42,101,202,359,296,436,433,376,26,447},day={67,67,67,67,67,47,47,47,47,57,57,57,53,53,53,82,82,132,132,42,42,101,202,359,296,436,433,376,26,447},night={42,42,42,42,42,42,42,42,42,42,47,47,82,82,132,132,67,57,53,101,202,359,296,436,433,376,26,447}} },
    { id="FR_CERULEAN_CAVE_B1F", habitat="rare", min=42, max=49, gen=4, base={morning={47,47,47,47,47,64,64,64,64,82,82,82,42,42,67,67,132,132,101,202,359,296,436,433,376,26,447},day={47,47,47,47,47,64,64,64,64,82,82,82,42,42,67,67,132,132,101,202,359,296,436,433,376,26,447},night={47,47,47,47,47,64,64,64,64,82,82,82,42,42,67,67,132,132,101,202,359,296,436,433,376,26,447}} },
    { id="FR_CERULEAN_CAVE_B2F", habitat="rare", min=40, max=46, gen=4, base={morning={47,47,47,47,64,64,64,64,67,67,67,67,42,42,82,82,132,132,101,202,359,296,436,433,376,26,447},day={47,47,47,47,64,64,64,64,67,67,67,67,42,42,82,82,132,132,101,202,359,296,436,433,376,26,447},night={42,42,42,42,47,47,47,47,64,64,64,64,67,67,82,82,132,132,101,202,359,296,436,433,376,26,447}} },
    { id="FR_VICTORY_ROAD_1F", habitat="mountain", min=32, max=36, gen=4, base={morning={42,75,232,217,95,111,359,296,436,433},day={42,75,232,217,95,111,359,296,436,433},night={42,75,232,217,95,111,359,296,436,433}} },
    { id="FR_VICTORY_ROAD_2F", habitat="mountain", min=34, max=38, gen=4, base={morning={42,75,232,217,95,111,359,296,436,433},day={42,75,232,217,95,111,359,296,436,433},night={42,75,232,217,95,111,359,296,436,433}} },
    { id="FR_VICTORY_ROAD_3F", habitat="mountain", min=36, max=40, gen=4, base={morning={42,75,232,217,95,111,359,296,436,433},day={42,75,232,217,95,111,359,296,436,433},night={42,75,232,217,95,111,359,296,436,433}} },
    { id="FR_SAFARI_ZONE_CENTER", habitat="safari", min=22, max=35, gen=4, base={morning={115,111,128,29},day={115,111,128,29},night={115,128,215,198}} },
    { id="FR_SAFARI_ZONE_EAST", habitat="safari", min=22, max=35, gen=4, base={morning={115,111,128,56},day={115,111,128,56},night={115,128,215,198}} },
    { id="FR_SAFARI_ZONE_NORTH", habitat="safari", min=22, max=35, gen=4, base={morning={115,111,128,35},day={115,111,128,35},night={115,128,215,198}} },
    { id="FR_SAFARI_ZONE_WEST", habitat="safari", min=22, max=35, gen=4, base={morning={115,111,128,79},day={115,111,128,79},night={115,128,215,198}} },
  }

  local HABITAT_MAP = {
    field = {"FR_ROUTE_1","FR_ROUTE_3","FR_ROUTE_6","FR_ROUTE_9","FR_ROUTE_11","FR_ROUTE_12","FR_ROUTE_18","FR_ROUTE_22","FR_ROUTE_24","FR_ROUTE_25","FR_ROUTE_28","FR_VICTORY_ROAD_1F","FR_VICTORY_ROAD_2F","FR_VICTORY_ROAD_3F"},
    forest = {"FR_ROUTE_2","FR_ROUTE_24","FR_ROUTE_25","FR_VIRIDIAN_FOREST","FR_ROUTE_13","FR_ROUTE_14","FR_ROUTE_15","FR_SAFARI_ZONE_CENTER","FR_SAFARI_ZONE_EAST","FR_SAFARI_ZONE_NORTH","FR_SAFARI_ZONE_WEST"},
    urban = {"FR_ROUTE_5","FR_ROUTE_7","FR_ROUTE_8","FR_ROUTE_16","FR_ROUTE_17","FR_CERULEAN_CAVE_1F","FR_CERULEAN_CAVE_B1F","FR_CERULEAN_CAVE_B2F"},
    mountain = {"FR_ROUTE_4","FR_ROUTE_23","FR_ROUTE_28","FR_MT_MOON_1F","FR_MT_MOON_B1F","FR_MT_MOON_B2F","FR_ROCK_TUNNEL_1F","FR_ROCK_TUNNEL_B1F","FR_VICTORY_ROAD_1F","FR_VICTORY_ROAD_2F","FR_VICTORY_ROAD_3F"},
    cave = {"FR_DIGLETTS_CAVE","FR_MT_MOON_1F","FR_MT_MOON_B1F","FR_MT_MOON_B2F","FR_ROCK_TUNNEL_1F","FR_ROCK_TUNNEL_B1F"},
    electric = {"FR_ROUTE_10","FR_POWER_PLANT"},
    ghost = {"FR_POKEMON_TOWER_1F","FR_POKEMON_TOWER_2F","FR_POKEMON_TOWER_3F","FR_POKEMON_TOWER_4F","FR_POKEMON_TOWER_5F","FR_POKEMON_TOWER_6F","FR_POKEMON_TOWER_7F"},
    water = {"FR_ROUTE_19","FR_ROUTE_20","FR_ROUTE_21"},
    ice = {"FR_SEAFOAM_ISLANDS_1F","FR_SEAFOAM_ISLANDS_B1F","FR_SEAFOAM_ISLANDS_B2F","FR_SEAFOAM_ISLANDS_B3F","FR_SEAFOAM_ISLANDS_B4F"},
    fire = {"FR_POKEMON_MANSION_1F","FR_POKEMON_MANSION_B1F","FR_POKEMON_MANSION_B2F","FR_POKEMON_MANSION_B3F","FR_ROUTE_28"},
    safari = {"FR_SAFARI_ZONE_CENTER","FR_SAFARI_ZONE_EAST","FR_SAFARI_ZONE_NORTH","FR_SAFARI_ZONE_WEST"},
    rare = {"FR_CERULEAN_CAVE_1F","FR_CERULEAN_CAVE_B1F","FR_CERULEAN_CAVE_B2F"},
  }

  -- HGSS-based Kanto surf/fishing pools. Fishing is stored in FireRed's
  -- ten-slot rod layout: Old Rod 1-2, Good Rod 3-5, Super Rod 6-10.
  local WATER_TABLES = {
    FR_ROUTE_4  = { surf={118,119}, fishing={129,118,118,129,119,118,118,119,129,119} },
    FR_ROUTE_6  = { surf={54,55}, fishing={129,54,54,129,55,54,54,55,129,55} },
    FR_ROUTE_9  = { surf={118,119}, fishing={129,118,118,129,119,118,118,119,129,119} },
    FR_ROUTE_10 = { surf={72,73}, fishing={129,72,72,129,73,72,72,73,129,73} },
    FR_ROUTE_12 = { surf={73,195}, fishing={129,72,72,129,211,72,72,211,129,73} },
    FR_ROUTE_13 = { surf={73,195}, fishing={129,72,72,129,211,72,72,211,129,73} },
    FR_ROUTE_17 = { surf={72,73}, fishing={129,72,72,129,90,72,72,90,129,73} },
    FR_ROUTE_18 = { surf={72,73}, fishing={129,72,72,129,90,72,72,90,129,73} },
    FR_ROUTE_19 = { surf={72,73}, fishing={129,98,98,129,222,98,98,222,129,73} },
    FR_ROUTE_20 = { surf={72,73}, fishing={129,98,98,129,222,98,98,222,129,73} },
    FR_ROUTE_21 = { surf={72,73}, fishing={129,98,98,129,222,98,98,222,129,73} },
    FR_ROUTE_22 = { surf={60,61}, fishing={129,60,60,129,61,60,60,61,129,61} },
    FR_ROUTE_23 = { surf={60,61}, fishing={129,60,60,129,61,60,60,61,129,61} },
    FR_ROUTE_24 = { surf={118,119}, fishing={129,118,118,129,119,118,118,119,129,119} },
    FR_ROUTE_25 = { surf={118,119}, fishing={129,118,118,129,119,118,118,119,129,119} },
    FR_ROUTE_28 = { surf={60,61}, fishing={129,60,60,129,61,60,60,61,129,61} },
  }

  -- Missing Water families are kept in water, never injected into land grass.
  -- These additions spread Gen 1-4 Water species across sensible Kanto waters.
  local WATER_ADDITIONS = {
    FR_ROUTE_4={7,98,116}, FR_ROUTE_6={183,270,283}, FR_ROUTE_9={339,341},
    FR_ROUTE_10={170,223}, FR_ROUTE_12={194,211,318}, FR_ROUTE_13={320,349},
    FR_ROUTE_17={278,422}, FR_ROUTE_18={418,456}, FR_ROUTE_19={363,366},
    FR_ROUTE_20={222,370}, FR_ROUTE_21={258,393}, FR_ROUTE_22={60,339},
    FR_ROUTE_23={131,138,140}, FR_ROUTE_24={118,349}, FR_ROUTE_25={283,418},
    FR_ROUTE_28={223,456},
  }

  local PROFILE_BY_ID = {}
  for _, p in ipairs(PROFILES) do PROFILE_BY_ID[p.id] = p end

  local function typeList(nat, Pokemon)
    local species = nat <= 386 and nat or nat + 64
    local ok, types = pcall(Pokemon.types, species)
    if not ok or type(types) ~= "table" then return {} end
    return {types[1], types[2]}
  end

  local function hasType(types, wanted)
    for _, t in ipairs(types) do if t == wanted then return true end end
    return false
  end

  local function homeForSpecies(nat, Pokemon)
    local types = typeList(nat, Pokemon)
    if hasType(types, TYPE.WATER) then return "water" end
    if hasType(types, TYPE.ICE) then return "ice" end
    if hasType(types, TYPE.ELECTRIC) then return "electric" end
    if hasType(types, TYPE.FIRE) then return "fire" end
    if hasType(types, TYPE.GHOST) then return "ghost" end
    if hasType(types, TYPE.ROCK) or hasType(types, TYPE.GROUND) or hasType(types, TYPE.STEEL) then return "mountain" end
    if hasType(types, TYPE.BUG) or hasType(types, TYPE.GRASS) then return "forest" end
    if hasType(types, TYPE.POISON) or hasType(types, TYPE.PSYCHIC) or hasType(types, TYPE.DARK) then return "urban" end
    if hasType(types, TYPE.FIGHTING) or hasType(types, TYPE.FLYING) then return "field" end
    return "field"
  end

  local function periodBonus(nat, period, Pokemon)
    local types = typeList(nat, Pokemon)
    if period == "night" then
      if hasType(types, TYPE.DARK) or hasType(types, TYPE.GHOST) then return 6 end
      if hasType(types, TYPE.PSYCHIC) then return 2 end
      if hasType(types, TYPE.FLYING) or hasType(types, TYPE.NORMAL) then return 1 end
      return 0
    elseif period == "morning" then
      if hasType(types, TYPE.BUG) or hasType(types, TYPE.FLYING) or hasType(types, TYPE.GRASS) then return 4 end
      return 1
    end
    if hasType(types, TYPE.FIRE) or hasType(types, TYPE.FIGHTING) or hasType(types, TYPE.GROUND) then return 4 end
    return 1
  end

  -- Legendary and Mythical Pokémon are handled separately in FireRed.
  local LEGENDARY_OR_MYTHICAL = {
    [144]=true,[145]=true,[146]=true,[150]=true,[151]=true,
    [243]=true,[244]=true,[245]=true,[249]=true,[250]=true,[251]=true,
    [377]=true,[378]=true,[379]=true,[380]=true,[381]=true,
    [382]=true,[383]=true,[384]=true,[385]=true,[386]=true,
    [480]=true,[481]=true,[482]=true,[483]=true,[484]=true,[485]=true,
    [486]=true,[487]=true,[488]=true,[489]=true,[490]=true,[491]=true,
    [492]=true,[493]=true,
  }

  local FOSSIL_FAMILIES = {
    [138]=true,[139]=true,[140]=true,[141]=true,[142]=true,
    [345]=true,[346]=true,[347]=true,[348]=true,
    [408]=true,[409]=true,[410]=true,[411]=true,
  }

  local function isExcludedWildSpecies(nat)
    return LEGENDARY_OR_MYTHICAL[nat] == true or FOSSIL_FAMILIES[nat] == true
  end

  -- One representative from every evolutionary family that is still absent
  -- after the merged HGSS/FireRed encounter backbone. Only these missing
  -- families are added; their evolutions are left to evolution/breeding.
  local MISSING_FAMILY_REPRESENTATIVES = {
    1,4,7,60,83,98,102,106,108,116,122,123,124,126,127,131,133,137,143,147,152,155,158,176,177,179,183,185,190,191,193,203,204,206,207,209,211,213,214,220,222,223,225,226,227,234,235,241,246,252,255,258,261,263,265,270,273,276,278,280,283,285,287,290,293,299,300,302,303,304,307,309,311,312,313,314,316,318,320,324,327,328,331,333,335,336,337,338,339,341,343,349,351,352,353,357,361,363,366,369,370,371,374,387,390,393,396,399,401,403,412,415,417,418,420,422,425,427,431,434,441,442,443,447,449,451,453,456,459
  }

  -- Minimum area level for stronger family representatives. This keeps
  -- generated coverage from putting late-game power on early Kanto routes.
  local MIN_AREA_LEVEL = {
    [106]=24,[115]=24,[123]=24,[124]=24,[126]=24,[127]=24,[131]=30,
    [142]=30,[143]=24,[176]=18,[185]=18,[200]=18,[203]=18,[212]=28,
    [214]=24,[217]=28,[227]=28,[232]=28,[234]=20,[241]=24,[246]=28,
    [289]=30,[302]=24,[303]=24,[306]=30,[308]=24,[310]=24,[324]=24,
    [330]=30,[334]=30,[335]=24,[336]=24,[337]=24,[338]=24,[344]=24,
    [346]=24,[348]=24,[351]=20,[352]=20,[357]=24,[359]=30,[369]=30,
    [371]=24,[374]=28,[408]=24,[410]=24,[442]=24,[443]=24,[447]=20,
    [449]=20,[451]=20,[459]=20,
  }

  local extraAssignments = nil

  local function buildExtraAssignments(Pokemon)
    if extraAssignments then return extraAssignments end
    extraAssignments = {}
    local load = {}
    for _, profile in ipairs(PROFILES) do
      extraAssignments[profile.id] = { morning={}, day={}, night={} }
      load[profile.id] = { morning=0, day=0, night=0 }
    end
    for _, nat in ipairs(MISSING_FAMILY_REPRESENTATIVES) do
      local habitat = homeForSpecies(nat, Pokemon)
      if habitat ~= "water" then
        local maps = HABITAT_MAP[habitat] or HABITAT_MAP.field
        local bestId, bestPeriod, bestLoad = nil, nil, math.huge
        for _, id in ipairs(maps) do
          local candidate = PROFILE_BY_ID[id]
          local minArea = MIN_AREA_LEVEL[nat] or 0
          if candidate and candidate.max >= minArea then
            for _, period in ipairs(PERIODS) do
              local score = load[id][period]
              if score < bestLoad then bestId, bestPeriod, bestLoad = id, period, score end
            end
          end
        end
        if bestId then
          local list = extraAssignments[bestId][bestPeriod]
          list[#list + 1] = nat
          load[bestId][bestPeriod] = load[bestId][bestPeriod] + 1
        end
      end
    end
    return extraAssignments
  end

  local cache = {}

  local function entry(nat, minLevel, maxLevel)
    local species = nat <= 386 and nat or nat + 64
    return { species = species, minLevel = minLevel, maxLevel = maxLevel }
  end

  local function uniqueAppend(out, seen, e)
    if not seen[e.species] then
      seen[e.species] = true
      out[#out + 1] = e
    end
  end

  local EARLY_EVOLUTION_REPLACEMENTS = {
    [20]=19,[22]=21,[24]=23,[28]=27,[40]=39,[42]=41,[44]=43,[47]=46,
    [49]=48,[55]=54,[57]=56,[61]=60,[67]=66,[70]=69,[75]=74,[89]=88,
    [93]=92,[97]=96,[119]=118,[164]=163,[168]=167,[188]=187,[195]=194,
    [262]=261,[264]=263,[271]=270,[274]=273,[279]=278,[284]=283,
    [288]=287,[294]=293,[305]=304,[317]=316,[319]=318,[329]=328,
    [342]=341,[397]=396,[400]=399,[404]=403,[419]=418,[423]=422,
    [426]=425,[428]=427,[435]=434,[444]=443,[454]=453,[457]=456,
  }

  local function progressionSpecies(nat, profile)
    if profile.max < 20 then
      return EARLY_EVOLUTION_REPLACEMENTS[nat] or nat
    end
    return nat
  end
  local function buildTable(profile, period, Pokemon)
    local key = profile.id .. "|" .. period
    if cache[key] then return cache[key] end

    local out, seen = {}, {}
    local base = profile.base and profile.base[period] or {}

    -- Keep the encounter count natural to the location. HGSS routes commonly
    -- have only a few distinct species; do not pad every table to 12.
    for _, nat in ipairs(base) do
      nat = progressionSpecies(nat, profile)
      if nat >= 1 and nat <= 493 and not isExcludedWildSpecies(nat) then
        out[#out + 1] = entry(nat, profile.min, profile.max)
        seen[out[#out].species] = true
      end
    end

    local additions = buildExtraAssignments(Pokemon)
    local extras = additions[profile.id] and additions[profile.id][period] or {}
    for _, nat in ipairs(extras) do
      nat = progressionSpecies(nat, profile)
      if nat == 448 then nat = 447 end
      if nat == 376 then nat = 374 end
      uniqueAppend(out, seen, entry(nat, profile.min, profile.max))
    end

    -- Lucario is an exceptionally rare Cerulean Cave encounter.
    if profile.id == "FR_CERULEAN_CAVE_1F"
      or profile.id == "FR_CERULEAN_CAVE_B1F"
      or profile.id == "FR_CERULEAN_CAVE_B2F" then
      if math.random(100) == 1 then
        uniqueAppend(out, seen, entry(448, profile.min, profile.max))
      end
    end

    local result = {}
    if not profile.water then
      result.land = { rate = 20, slots = out }
    end

    local wt = WATER_TABLES[profile.id]
    if wt then
      local waterSlots, waterSeen = {}, {}
      for _, nat in ipairs(wt.surf or {}) do
        uniqueAppend(waterSlots, waterSeen, entry(nat, profile.min, profile.max))
      end
      for _, nat in ipairs(WATER_ADDITIONS[profile.id] or {}) do
        uniqueAppend(waterSlots, waterSeen, entry(nat, profile.min, profile.max))
      end
      result.water = { rate = 15, slots = waterSlots }

      local fishSlots = {}
      for _, nat in ipairs(wt.fishing or {}) do
        fishSlots[#fishSlots + 1] = entry(nat, profile.min, profile.max)
      end
      result.fishing = { rate = 0, slots = fishSlots }
    elseif profile.water then
      result.water = { rate = 15, slots = out }
    end

    cache[key] = result
    return result
  end

  local installed = false
  local lastPeriod = nil

  local function install()
    if installed then return true end
    if not (found.RealTimeClockTest and found.untamed_advanced and found.national_dex_gen3) then
      mod.log:error("RTC + Untamed + National Dex compatibility requires all three source mods")
      return false
    end

    local untamed = found.untamed_advanced
    local engine = untamed and untamed.exports and untamed.exports.engine
    if type(engine) ~= "table" or type(engine.wildHeader) ~= "function" or type(engine.wildArea) ~= "function" then
      mod.log:error("Untamed Advanced engine export was not available")
      return false
    end
    if type(engine.Encounters) ~= "table" or type(engine.Encounters.tableFor) ~= "function" then
      mod.log:error("Untamed Advanced encounter engine was not available")
      return false
    end

    local Pokemon = engine.Pokemon
    if type(Pokemon) ~= "table" or type(Pokemon.types) ~= "function" then
      mod.log:error("Untamed Advanced did not expose Pokemon.types")
      return false
    end

    -- Pattern Bush has a rare visible Shaymin encounter.  This is injected
    -- only while Untamed is generating OWEs, so normal grass battles keep
    -- their regular encounter table.
    do
      local Owe = engine.Owe
      if Owe and type(Owe.tick) == "function" and not Owe._rareMythicalCompat then
        local Dex = require("src.core.game3.dex")
        local SHAYMIN_NAT = 492
        local SHAYMIN_SPECIES = SHAYMIN_NAT + 64
        local rawTick = Owe.tick
        local rawWildArea = engine.wildArea
        local inOweTick = false

        local function patternBush()
          local id = tostring(engine.mapId and engine.mapId() or ""):upper()
          return id:find("PATTERN_BUSH", 1, true) ~= nil
            or id:find("PATTERNBUSH", 1, true) ~= nil
        end

        local function shayminCaught()
          local session = engine.Runtime and engine.Runtime.getSession and engine.Runtime.getSession()
          return session and session.dex and Dex.isCaught(session.dex, SHAYMIN_SPECIES) == true
        end

        local function shayminActive()
          for _, actor in ipairs(engine.actors or {}) do
            if actor and actor.active and actor.oweType
                and (tonumber(actor.engineSpecies) == SHAYMIN_SPECIES
                  or tonumber(actor.species) == SHAYMIN_NAT) then
              return true
            end
          end
          return false
        end

        engine.wildArea = function(header, kind)
          local slots = rawWildArea(header, kind)
          if not inOweTick or kind ~= "land" or not patternBush()
              or shayminCaught() or shayminActive()
              or type(slots) ~= "table" or #slots == 0 then
            return slots
          end

          local rare = {}
          for i = 1, 12 do
            local source = slots[i] or slots[#slots]
            rare[i] = source
          end
          rare[12] = { species = SHAYMIN_SPECIES, minLevel = 50, maxLevel = 50 }
          return rare
        end

        Owe.tick = function(...)
          inOweTick = true
          local ok, err = pcall(rawTick, ...)
          inOweTick = false
          if not ok then error(err, 0) end
        end

        Owe._rareMythicalCompat = true
      end
    end

    -- FRLG normally keeps only one roaming beast in session.roamer. Keep all
    -- three in that same saved field so each has independent route, HP/status,
    -- personality/IVs, and caught state while preserving the native mechanics.
    local Roamer = require("src.core.game3.roamer")
    if not Roamer._allBeastsInstalled then
      local rawInit = Roamer.init
      local rawMove = Roamer.move
      local rawJump = Roamer.jump
      local rawTryEncounter = Roamer.tryEncounter
      local rawBattleEnd = Roamer.onBattleEnd

      local function isMulti(r)
        return type(r) == "table" and type(r.beasts) == "table"
      end

      local function withBeast(session, beast, fn, ...)
        local saved = session.roamer
        session.roamer = beast
        local result = fn(session, ...)
        session.roamer = saved
        return result
      end

      Roamer.init = function(session, starterChoice)
        if not session then return false end
        local darkrai
        if isMulti(session.roamer) then
          for _, beast in ipairs(session.roamer.beasts) do
            if beast.darkrai then darkrai = beast break end
          end
        end
        local beasts = {}
        for _, starter in ipairs({ 1, 0, 2 }) do
          rawInit(session, starter)
          beasts[#beasts + 1] = session.roamer
        end
        if darkrai then beasts[#beasts + 1] = darkrai end
        session.roamer = { active = true, beasts = beasts }
        return true
      end

      Roamer.move = function(session, reason, mapId)
        local group = session and session.roamer
        if not isMulti(group) then return rawMove(session, reason, mapId) end
        for _, beast in ipairs(group.beasts) do
          if beast.active then withBeast(session, beast, rawMove, reason, mapId) end
        end
      end

      Roamer.jump = function(session)
        local group = session and session.roamer
        if not isMulti(group) then return rawJump(session) end
        for _, beast in ipairs(group.beasts) do
          if beast.active then withBeast(session, beast, rawJump) end
        end
      end

      Roamer.tryEncounter = function(session, mapId, terrain)
        local group = session and session.roamer
        if not isMulti(group) then return rawTryEncounter(session, mapId, terrain) end

        local candidates = {}
        for _, beast in ipairs(group.beasts) do
          if beast.active
            and (not beast.darkrai or currentPeriod() == "night")
            and Roamer.normalizeMapId(beast.map) == Roamer.normalizeMapId(mapId) then
            candidates[#candidates + 1] = beast
          end
        end
        if #candidates == 0 then return nil end
        local start = (math.random(#candidates))
        for offset = 0, #candidates - 1 do
          local beast = candidates[((start + offset - 1) % #candidates) + 1]
          local enc = withBeast(session, beast, rawTryEncounter, mapId, terrain)
          if enc then return enc end
        end
        return nil
      end

      Roamer.onBattleEnd = function(session, foeState, battleResult, endReason)
        local group = session and session.roamer
        if not isMulti(group) then
          return rawBattleEnd(session, foeState, battleResult, endReason)
        end
        local species = foeState and (foeState.species or foeState.speciesId)
        for _, beast in ipairs(group.beasts) do
          if beast.active and beast.species == species then
            local result = withBeast(session, beast, rawBattleEnd, foeState, battleResult, endReason)
            if beast.darkrai and battleResult ~= "caught" and not beast.active then
              beast.active = true
              beast.hp = beast.maxHp
              beast.status, beast.statusNum = 0, 0
              withBeast(session, beast, rawJump)
            end
            return result
          end
        end
      end

      Roamer._allBeastsInstalled = true
    end

    -- Untamed models FRLG roamers as category 0. Keep that public category,
    -- but pin the exact grouped roamer chosen for its visible OWE so the
    -- collision/A-press battle resolves to the same persistent individual.
    if engine.roamerAt and not engine._groupedRoamerOWEInstalled then
      local visibleRoamer = nil

      engine.roamerAt = function(index)
        if index ~= 0 then return nil end
        local session = engine.Runtime and engine.Runtime.getSession and engine.Runtime.getSession()
        local mapId = session and session.map
        if not session or not mapId then visibleRoamer = nil; return nil end

        if visibleRoamer and visibleRoamer.mapId == mapId then
          local beast = visibleRoamer.beast
          if beast and beast.active
            and (not beast.darkrai or currentPeriod() == "night")
            and Roamer.normalizeMapId(beast.map) == Roamer.normalizeMapId(mapId) then
            return visibleRoamer.species, visibleRoamer.level, visibleRoamer.foe
          end
          visibleRoamer = nil
        end

        local enc = Roamer.tryEncounter(session, mapId, "land")
        if not enc then return nil end

        local chosen
        local group = session.roamer
        if type(group) == "table" and type(group.beasts) == "table" then
          for _, beast in ipairs(group.beasts) do
            if beast.active and beast.species == enc.species
              and Roamer.normalizeMapId(beast.map) == Roamer.normalizeMapId(mapId) then
              chosen = beast
              break
            end
          end
        end

        visibleRoamer = {
          mapId = mapId,
          beast = chosen,
          species = enc.species,
          level = enc.level,
          foe = enc.foe,
        }
        return enc.species, enc.level, enc.foe
      end

      local rawUntamedRoamerMove = engine.roamerMove
      engine.roamerMove = function(index)
        visibleRoamer = nil
        if rawUntamedRoamerMove then return rawUntamedRoamerMove(index) end
      end

      mod.events:on("map.entered", function()
        visibleRoamer = nil
      end)

      engine._groupedRoamerOWEInstalled = true
    end

    -- Fossil Dealer: a separate NPC in Kanto/Sevii Poké Marts after Mt. Moon.
    -- FireRed already supplies Helix, Dome, and Old Amber, so he only carries
    -- the Hoenn/Sinnoh fossils that otherwise have no normal FRLG source.
    local ItemsData = require("src.core.game3.items_data")
    local Objects = require("src.core.game3.objects")
    local Field = require("src.core.game3.field")
    local Player = require("src.core.game3.player")
    local ShopMenu = require("src.ui.game3.shop_menu")
    local Message = require("src.ui.game3.message")
    local GfxIds = require("src.core.game3.scripting.gfx_ids")

    local FOSSIL_DEALER_ID = 125
    local FOSSIL_PRICE = 3000
    local ROOT_FOSSIL, CLAW_FOSSIL = 286, 287
    local HELIX_FOSSIL, DOME_FOSSIL = 357, 358
    local SKULL_FOSSIL, ARMOR_FOSSIL = "SKULL_FOSSIL", "ARMOR_FOSSIL"

    local FOSSIL_MARTS = {
      FR_CERULEAN_CITY_MART=true,
      FR_VERMILION_CITY_MART=true,
      FR_LAVENDER_TOWN_MART=true,
      FR_SAFFRON_CITY_MART=true,
      FR_FUCHSIA_CITY_MART=true,
      FR_CINNABAR_ISLAND_MART=true,
      FR_THREE_ISLAND_MART=true,
      FR_FOUR_ISLAND_MART=true,
      FR_SIX_ISLAND_MART=true,
      FR_SEVEN_ISLAND_MART=true,
    }

    local rawItemInfo = ItemsData.info
    if not ItemsData._fossilDealerItemsInstalled then
      ItemsData.info = function(id)
        if id == SKULL_FOSSIL then
          return { id=id, name="SKULL FOSSIL", pocket="ITEMS", fieldUse="none",
            price=FOSSIL_PRICE, description="A fossil from a prehistoric POKEMON." }
        elseif id == ARMOR_FOSSIL then
          return { id=id, name="ARMOR FOSSIL", pocket="ITEMS", fieldUse="none",
            price=FOSSIL_PRICE, description="A fossil from a prehistoric POKEMON." }
        end
        local info = rawItemInfo(id)
        if info and (tonumber(id) == ROOT_FOSSIL or tonumber(id) == CLAW_FOSSIL
          or tonumber(id) == HELIX_FOSSIL or tonumber(id) == DOME_FOSSIL) then
          local copy = {}
          for k, v in pairs(info) do copy[k] = v end
          copy.price = FOSSIL_PRICE
          return copy
        end
        return info
      end
      ItemsData._fossilDealerItemsInstalled = true
    end

    local function badgeCount(session)
      local n = 0
      local flags = session and session.flags or {}
      for id = 0x820, 0x827 do
        if flags[id] == true or flags[tostring(id)] == true
          or flags[string.format("0x%X", id)] == true then
          n = n + 1
        end
      end
      return n
    end

    local function fossilStock(session)
      local badges = badgeCount(session)
      local stock = {}
      if badges >= 1 then stock[#stock + 1] = ROOT_FOSSIL end
      if badges >= 3 then stock[#stock + 1] = CLAW_FOSSIL end
      if badges >= 5 then stock[#stock + 1] = SKULL_FOSSIL end
      if badges >= 7 then stock[#stock + 1] = ARMOR_FOSSIL end
      return stock
    end

    local function dealerMap(session)
      return session and FOSSIL_MARTS[session.map] == true and badgeCount(session) >= 1
    end

    local function removeFossilDealer()
      if Objects._byId and Objects._byId[FOSSIL_DEALER_ID] then
        Objects._byId[FOSSIL_DEALER_ID] = nil
        for i = #(Objects._order or {}), 1, -1 do
          if Objects._order[i] == FOSSIL_DEALER_ID then table.remove(Objects._order, i) end
        end
      end
    end

    local function placeFossilDealer()
      local session = engine.Runtime and engine.Runtime.getSession and engine.Runtime.getSession()
      removeFossilDealer()
      if not dealerMap(session) then return end
      if not Objects._byId or not Objects._order then return end

      -- Bottom-right side of the standard Mart floor keeps him away from the
      -- clerk, questionnaire counter, shelves, entrance, and normal customers.
      local x, y = 12, 7
      if Objects.at and Objects.at(x, y) then
        x, y = 11, 7
        if Objects.at(x, y) then x, y = 12, 6 end
      end

      local eo = {
        localId=FOSSIL_DEALER_ID, originLocalId=FOSSIL_DEALER_ID,
        originMapId=session.map, cellX=x, cellY=y, px=x*16, py=y*16,
        homeX=x, homeY=y, targetX=x, targetY=y,
        facing="left", sprite=GfxIds.spriteFor(61), graphicsId=61,
        elevation=3, currentElevation=3, movementType=0x09,
        movement="STAY", range="LEFT", radius={x=0,y=0}, rangeX=0, rangeY=0,
        visible=true, hidden=false, invisible=false, frozen=false,
        passable=false, moving=false, progress=0, stepFrames=16,
        scriptBusy=false, def={ localId=FOSSIL_DEALER_ID, x=x, y=y,
          graphicsId=61, movementType=0x09, facing="left" },
      }
      Objects._byId[FOSSIL_DEALER_ID] = eo
      Objects._order[#Objects._order + 1] = FOSSIL_DEALER_ID
    end

    local LAB_EXPERIMENT_ROOM = "FR_CINNABAR_ISLAND_POKEMON_LAB_EXPERIMENT_ROOM"
    local EXTRA_FOSSILS = {
      [ROOT_FOSSIL] = { name="ROOT FOSSIL", species=345, pokemon="LILEEP" },
      [CLAW_FOSSIL] = { name="CLAW FOSSIL", species=347, pokemon="ANORITH" },
      [SKULL_FOSSIL] = { name="SKULL FOSSIL", species=408, pokemon="CRANIDOS" },
      [ARMOR_FOSSIL] = { name="ARMOR FOSSIL", species=410, pokemon="SHIELDON" },
    }
    local Bag = require("src.core.game3.bag")
    local Party = require("src.core.game3.party")

    local function extraFossilState(session)
      session.modData = session.modData or {}
      session.modData[mod.id] = session.modData[mod.id] or {}
      local state = session.modData[mod.id]
      state.fossilLab = state.fossilLab or {}
      return state.fossilLab
    end

    local function carriedExtraFossil(session)
      for _, id in ipairs({ROOT_FOSSIL, CLAW_FOSSIL, SKULL_FOSSIL, ARMOR_FOSSIL}) do
        if Bag.get(session.bag, id) > 0 then return id, EXTRA_FOSSILS[id] end
      end
    end

    local function labScientistAhead(session)
      if not session or session.map ~= LAB_EXPERIMENT_ROOM then return false end
      local dx, dy = 0, 0
      if Player.facing == "up" then dy=-1 elseif Player.facing == "down" then dy=1
      elseif Player.facing == "left" then dx=-1 elseif Player.facing == "right" then dx=1 end
      local obj = Objects.at and Objects.at(Player.cellX + dx, Player.cellY + dy)
      return obj and (obj.localId == 2 or obj.scriptKey == "CinnabarIsland_PokemonLab_ExperimentRoom_EventScript_FossilScientist")
    end

    local function offerExtraFossil(session, id, fossil)
      local state = extraFossilState(session)
      Field.lock("extra_fossil_lab")
      Message.show("You have a "..fossil.name.."! It is a fossil of "..fossil.pokemon.."!", function()
        Message.show("I can make it live again! Give it to me.", function()
          if Bag.remove(session.bag, id, 1) then
            state.pending, state.ready = id, false
            Message.show("It takes time. Go for a walk!", function() Field.unlock("extra_fossil_lab") end)
          else
            Field.unlock("extra_fossil_lab")
          end
        end)
      end)
    end

    local function giveExtraFossilMon(session, id, fossil)
      local state = extraFossilState(session)
      Field.lock("extra_fossil_lab")
      local species = fossil.species
      if species > 386 then species = species + 64 end
      local ok = Party.giveMon(session, species, 5, nil, {toPC=true})
      if ok then
        state.pending, state.ready = nil, false
        Message.show("Your "..fossil.pokemon.." is back to life!", function() Field.unlock("extra_fossil_lab") end)
      else
        Message.show("You have no room for this POKEMON.", function() Field.unlock("extra_fossil_lab") end)
      end
    end

    local rawFieldInteract = Field.interact

    local function showVermilionHarborChoice(game, onSeagallop)
      local Choice = require("src.ui.game3.choice")
      Field.lock("vermillion_harbor_choice")
      Message.show("Where would you like to go?", function()
        Choice.multi({ "SEAGALLOP FERRY", "OLD S.S. ANNE DOCK", "EXIT" }, 0, function(pick)
          if pick == 0 then
            Field.unlock("vermillion_harbor_choice")
            onSeagallop()
          elseif pick == 1 then
            mod.world:warpTo("FR_SSANNE_EXTERIOR", 31, 6, "down")
            Field.unlock("vermillion_harbor_choice")
          else
            Field.unlock("vermillion_harbor_choice")
          end
        end, { left = 10, top = 5 })
      end)
      return true
    end

    local rawTryCoordEvents = Field.tryCoordEvents
    if not Field._oldDockCoordChoiceInstalled then
      local passingToSeagallop = false
      Field.tryCoordEvents = function(game, cx, cy)
        if not passingToSeagallop then
          local session = engine.Runtime and engine.Runtime.getSession and engine.Runtime.getSession()
          if session and session.map == "FR_VERMILION_CITY"
              and (cx == 22 or cx == 23) and cy == 33 then
            local okSpace, Space = pcall(require, "src.core.game3.scripting.space")
            local okFlags, Flags = pcall(require, "src.core.game3.scripting.flags")
            local ctx = okSpace and Space and Space.vm and Space.vm.ctx or nil
            local scene = okSpace and okFlags and Space and Flags and Space.store
              and Flags.getVar(Space.store, ctx, 0x407E) or nil
            if scene == 3 then
              return showVermilionHarborChoice(game, function()
                passingToSeagallop = true
                rawTryCoordEvents(game, cx, cy)
                passingToSeagallop = false
              end)
            end
          end
        end
        return rawTryCoordEvents(game, cx, cy)
      end
      Field._oldDockCoordChoiceInstalled = true
    end

    if not Field._fossilDealerInteractInstalled then
      Field.interact = function(game)
        local session = engine.Runtime and engine.Runtime.getSession and engine.Runtime.getSession()

        local function liveVar(id)
          local okSpace, Space = pcall(require, "src.core.game3.scripting.space")
          local okFlags, Flags = pcall(require, "src.core.game3.scripting.flags")
          if not okSpace or not okFlags or not Space or not Flags or not Space.store then return nil end
          local ctx = Space.vm and Space.vm.ctx or nil
          return Flags.getVar(Space.store, ctx, id)
        end

        -- After the S.S. Anne has sailed, keep the sailor's normal Seagallop
        -- service and add the abandoned S.S. Anne dock as a second choice.
        if session and session.map == "FR_VERMILION_CITY"
            and liveVar(0x407E) == 3
            and Player.cellX == 24 and Player.cellY == 32 and Player.facing == "down"
            and not Field.isLocked() then
          return showVermilionHarborChoice(game, function()
            rawFieldInteract(game)
          end)
        end

        -- The truck is scenery on the eastern harbor strip. Its collision
        -- footprint occupies these tiles, so interaction works from any side.
        if session and session.map == "FR_SSANNE_EXTERIOR" and not Field.isLocked() then
          local dx, dy = 0, 0
          if Player.facing == "up" then dy = -1
          elseif Player.facing == "down" then dy = 1
          elseif Player.facing == "left" then dx = -1
          elseif Player.facing == "right" then dx = 1 end
          local tx, ty = Player.cellX + dx, Player.cellY + dy
          if tx >= 55 and tx <= 57 and ty >= 2 and ty <= 3 then
            local state = mysticTicketState and mysticTicketState(session) or nil
            if not state then
              session.modData = session.modData or {}
              session.modData[mod.id] = session.modData[mod.id] or {}
              state = session.modData[mod.id]
            end
            if state.mewCaught then
              Message.show("It's an old truck.")
              return true
            end
            Field.lock("mew_truck")
            Message.show("Something is hiding under the truck!", function()
              mod.world:startWildBattle(151, 50, function()
                if session.dex and Dex and Dex.isCaught(session.dex, 151) then
                  state.mewCaught = true
                end
                Field.unlock("mew_truck")
              end)
            end)
            return true
          end
        end

        if labScientistAhead(session) and not Field.isLocked() then
          local state = extraFossilState(session)
          if state.pending then
            local fossil = EXTRA_FOSSILS[state.pending]
            if state.ready and fossil then
              giveExtraFossilMon(session, state.pending, fossil)
              return true
            elseif fossil then
              Message.show("It takes time. Go for a walk!")
              return true
            end
          end
          local id, fossil = carriedExtraFossil(session)
          if id and fossil then
            offerExtraFossil(session, id, fossil)
            return true
          end
        end

        local dealer = Objects._byId and Objects._byId[FOSSIL_DEALER_ID]
        if dealer and dealerMap(session) and not Field.isLocked() then
          local dx, dy = 0, 0
          local face = Player.facing
          if face == "up" then dy=-1 elseif face == "down" then dy=1
          elseif face == "left" then dx=-1 elseif face == "right" then dx=1 end
          if Player.cellX + dx == dealer.cellX and Player.cellY + dy == dealer.cellY then
            local opposite = {up="down",down="up",left="right",right="left"}
            dealer.facing = opposite[face] or dealer.facing
            Field.lock("fossil_dealer")
            Message.show("FOSSIL DEALER: Looking for something ancient?", function()
              ShopMenu.show({
                items=fossilStock(session),
                session=session,
                onClose=function() Field.unlock("fossil_dealer") end,
              })
            end)
            return true
          end
        end
        return rawFieldInteract(game)
      end
      Field._fossilDealerInteractInstalled = true
    end

    mod.events:on("map.entered", function()
      placeFossilDealer()
    end)

    local MYSTIC_TICKET = 370
    local AURORA_TICKET = 371
    local FLAG_ENABLE_SHIP_NAVEL_ROCK = 0x84A
    local FLAG_ENABLE_SHIP_BIRTH_ISLAND = 0x84B
    local FLAG_RECEIVED_MYSTIC_TICKET = 0x2A8
    local FLAG_RECEIVED_AURORA_TICKET = 0x2A7
local FLAG_SHOWN_MYSTIC_TICKET = 0x2F0
    local FLAG_SHOWN_AURORA_TICKET = 0x2F1
    local VAR_MAP_SCENE_ONE_ISLAND_POKEMON_CENTER_1F = 0x4076
    local VAR_MAP_SCENE_VERMILION_CITY = 0x407E
    local LEGENDARY_UNLOCK = { 144, 145, 146, 243, 244, 245 }
    local Dex = require("src.core.game3.dex")
    local MysteryGift = require("src.core.game3.mystery_gift")
    local mysticTicketBusy = false
    local auroraTicketBusy = false

    local function hasRayquaza(session)
      if debugTicketEvents() then return true end
      return session and session.dex and Dex.isCaught(session.dex, 384) == true
    end

    local function hasLegendarySet(session)
      if debugTicketEvents() then return true end
      if not session or not session.dex then return false end
      for _, species in ipairs(LEGENDARY_UNLOCK) do
        if not Dex.isCaught(session.dex, species) then return false end
      end
      return true
    end

    -- FireRed only checks event tickets at Vermilion. Extend the shared
    -- Seagallop menu so the MysticTicket can also reach Navel Rock from
    -- the Sevii harbors without replacing any normal island destination.
    do
      local okSea, Seagallop = pcall(require, "src.core.game3.scripting.natives_seagallop")
      local okSpaceSea, SpaceSea = pcall(require, "src.core.game3.scripting.space")
      local okFlagsSea, FlagsSea = pcall(require, "src.core.game3.scripting.flags")
      local okBagSea, BagSea = pcall(require, "src.core.game3.bag")
      if okSea and okSpaceSea and okFlagsSea and okBagSea and Seagallop
          and not Seagallop._mysticTicketCompat then
        Seagallop._mysticTicketCompat = true
        local oldMenu = Seagallop.destinationMenu
        local oldSelected = Seagallop.selectedDestination
        local oldFerryTask = Seagallop.ferryTask
        local pendingNavel = false
        local pendingBirth = false

        local function hasAuroraTicket()
          local session = engine.Runtime and engine.Runtime.getSession and engine.Runtime.getSession()
          local ctx = SpaceSea.vm and SpaceSea.vm.ctx or nil
          return session and session.bag
            and BagSea.get(session.bag, AURORA_TICKET) > 0
            and FlagsSea.getFlag(SpaceSea.store, ctx, FLAG_ENABLE_SHIP_BIRTH_ISLAND) == true
        end

        local function hasMysticTicket()
          local session = engine.Runtime and engine.Runtime.getSession and engine.Runtime.getSession()
          local ctx = SpaceSea.vm and SpaceSea.vm.ctx or nil
          return session and session.bag
            and BagSea.get(session.bag, MYSTIC_TICKET) > 0
            and FlagsSea.getFlag(SpaceSea.store, ctx, FLAG_ENABLE_SHIP_NAVEL_ROCK) == true
        end

        Seagallop.destinationMenu = function(originId, page)
          local labels, top = oldMenu(originId, page)
          if page == 1 then
            if hasMysticTicket() then table.insert(labels, #labels, "NAVEL ROCK") end
            if hasAuroraTicket() then table.insert(labels, #labels, "BIRTH ISLAND") end
          end
          return labels, top
        end

        Seagallop.selectedDestination = function(originId, page, result)
          if page == 1 then
            local nextResult = 4
            if hasMysticTicket() then
              if result == nextResult then
                pendingNavel, pendingBirth = true, false
                return 4
              end
              nextResult = nextResult + 1
            end
            if hasAuroraTicket() and result == nextResult then
              pendingNavel, pendingBirth = false, true
              return 4
            end
            if hasAuroraTicket() then nextResult = nextResult + 1 end
            -- Extra ticket destinations are inserted immediately before EXIT.
            -- Translate the shifted EXIT index back to the stock page-2 EXIT slot.
            if result == nextResult then
              pendingNavel, pendingBirth = false, false
              return 127
            end
          end
          pendingNavel, pendingBirth = false, false
          return oldSelected(originId, page, result)
        end

        Seagallop.ferryTask = function(ctx, adapters, destId)
          if pendingNavel and destId == 4 then
            pendingNavel, pendingBirth = false, false
            return oldFerryTask(ctx, adapters, 9)
          end
          if pendingBirth and destId == 4 then
            pendingNavel, pendingBirth = false, false
            return oldFerryTask(ctx, adapters, 10)
          end
          pendingNavel, pendingBirth = false, false
          return oldFerryTask(ctx, adapters, destId)
        end


      end
    end

    local function oneIslandCenter(mapId)
      local okCatalog, MapCatalog = pcall(require, "src.import.gba.map_catalog")
      if okCatalog and MapCatalog and MapCatalog.pretToEngine then
        local expected = MapCatalog.pretToEngine("OneIsland_PokemonCenter_1F")
        if expected and mapId == expected then return true end
      end
      local id = tostring(mapId or ""):upper()
      return (id:find("ONE_ISLAND", 1, true) or id:find("ONEISLAND", 1, true))
        and (id:find("POKEMON_CENTER_1F", 1, true) or id:find("POKEMONCENTER_1F", 1, true))
    end

    local function mysticTicketState(session)
      session.modData = session.modData or {}
      session.modData[mod.id] = session.modData[mod.id] or {}
      return session.modData[mod.id]
    end

    local function enableTicketDebugTravel(session)
      if not debugTicketEvents() or not session then return end
      local okSpace, Space = pcall(require, "src.core.game3.scripting.space")
      local okFlags, Flags = pcall(require, "src.core.game3.scripting.flags")
      if not okSpace or not okFlags or not Space or not Flags or not Space.store then return end
      local ctx = Space.vm and Space.vm.ctx or nil
      -- Only open the normal Sevii ferry path needed to exercise the two
      -- ticket events from an unfinished save. Catch flags stay untouched.
      Flags.setFlag(Space.store, ctx, 0x71, true)
      Flags.setFlag(Space.store, ctx, 0x72, true)
      Flags.setFlag(Space.store, ctx, 0x2DC, true)
      Flags.setFlag(Space.store, ctx, 0x2DD, true)
      Flags.setFlag(Space.store, ctx, 0x844, true)
      Flags.setVar(Space.store, ctx, VAR_MAP_SCENE_VERMILION_CITY, 3)
      Flags.setVar(Space.store, ctx, VAR_MAP_SCENE_ONE_ISLAND_POKEMON_CENTER_1F, 6)
    end

    local function tryTicketEvents()
      local session = engine.Runtime and engine.Runtime.getSession and engine.Runtime.getSession()
      local mapId = session and session.map
      local okSpace, Space = pcall(require, "src.core.game3.scripting.space")
      if okSpace and Space and Space.mapId then mapId = Space.mapId end
      if not session or not oneIslandCenter(mapId) or mysticTicketBusy or auroraTicketBusy then return false end
      local state = mysticTicketState(session)
      local hasMystic = state.mysticTicketGiven or MysteryGift.getFlag(session, FLAG_RECEIVED_MYSTIC_TICKET)
        or (session.bag and Bag.get(session.bag, MYSTIC_TICKET) > 0)
      local hasAurora = state.auroraTicketGiven or MysteryGift.getFlag(session, FLAG_RECEIVED_AURORA_TICKET)
        or (session.bag and Bag.get(session.bag, AURORA_TICKET) > 0)
      if hasMystic then state.mysticTicketGiven = true end
      if hasAurora then state.auroraTicketGiven = true end
      local giveMystic = not hasMystic and hasLegendarySet(session)
      local giveAurora = not hasAurora and hasRayquaza(session)
      if not giveMystic and not giveAurora then return false end

      local okFlags, Flags = pcall(require, "src.core.game3.scripting.flags")
      local ctx = Space and Space.vm and Space.vm.ctx or nil
      local function setTicketFlags(item)
        local enableFlag, receivedFlag, shownFlag
        if item == MYSTIC_TICKET then
          enableFlag, receivedFlag, shownFlag = FLAG_ENABLE_SHIP_NAVEL_ROCK, FLAG_RECEIVED_MYSTIC_TICKET, FLAG_SHOWN_MYSTIC_TICKET
          state.mysticTicketGiven = true
        else
          enableFlag, receivedFlag, shownFlag = FLAG_ENABLE_SHIP_BIRTH_ISLAND, FLAG_RECEIVED_AURORA_TICKET, FLAG_SHOWN_AURORA_TICKET
          state.auroraTicketGiven = true
        end
        MysteryGift.setFlag(session, enableFlag, true)
        MysteryGift.setFlag(session, receivedFlag, true)
        if okFlags and Space and Space.store then
          Flags.setFlag(Space.store, ctx, enableFlag, true)
          Flags.setFlag(Space.store, ctx, receivedFlag, true)
          Flags.setFlag(Space.store, ctx, shownFlag, false)
          Flags.setVar(Space.store, ctx, VAR_MAP_SCENE_VERMILION_CITY, 3)
          Flags.setVar(Space.store, ctx, VAR_MAP_SCENE_ONE_ISLAND_POKEMON_CENTER_1F, 5)
        end
      end
      local celioReturn
      local function unlock()
        local function finish()
          engine.Field.locked = false
          mysticTicketBusy, auroraTicketBusy = false, false
        end
        if celioReturn then
          local cb = celioReturn
          celioReturn = nil
          cb(finish)
        else
          finish()
        end
      end
      local function giveTicket(item, name, nextStep)
        if not Bag.add(session.bag, item, 1) then
          Message.show("Your KEY ITEMS POCKET is full.", unlock)
          return
        end
        setTicketFlags(item)
        Message.show("{PLAYER} received the "..name.."!", nextStep)
      end

      local function startTicketDialogue()
        if giveMystic and giveAurora then
        Message.show("Oh! Perfect timing!", function()
          Message.show("Two unusual tickets arrived for you.", function()
            Message.show("They both look like they're for the SEAGALLOP ferry.", function()
              giveTicket(MYSTIC_TICKET, "MYSTICTICKET", function()
                giveTicket(AURORA_TICKET, "AURORATICKET", function()
                  Message.show("I've never seen destinations like these before...", function()
                    Message.show("You should ask the sailor about them.", unlock)
                  end)
                end)
              end)
            end)
          end)
        end)
      else
        local alreadyHasOther = (giveMystic and hasAurora) or (giveAurora and hasMystic)
        Message.show("Oh! Perfect timing!", function()
          Message.show(alreadyHasOther and "Another unusual ticket arrived for you." or "Something unusual arrived for you.", function()
            Message.show("It looks like a ticket for the SEAGALLOP ferry.", function()
              local item = giveMystic and MYSTIC_TICKET or AURORA_TICKET
              local name = giveMystic and "MYSTICTICKET" or "AURORATICKET"
              giveTicket(item, name, function()
                Message.show("I've never seen a destination like this before...", function()
                  Message.show("You should ask the sailor about it.", unlock)
                end)
              end)
            end)
          end)
        end)
      end
      end

      local function celioApproach(nextStep)
        local celio, celioId
        for _, lid in ipairs(Objects._order or {}) do
          local eo = Objects._byId and Objects._byId[lid]
          if eo and tonumber(eo.graphicsId) == 89 then
            celio, celioId = eo, lid
            break
          end
        end
        if not celio or not celioId then
          nextStep()
          return
        end

        local x = tonumber(celio.x or (celio.def and celio.def.x)) or 15
        local y = tonumber(celio.y or (celio.def and celio.def.y)) or 6
        local startX, startY = x, y
        local startFacing = celio.facing or (celio.def and celio.def.facing)
        celioReturn = function(done)
          local back = {}
          local rx, ry = 9, 8
          while rx < startX do back[#back + 1] = { kind = "step", dir = "right" }; rx = rx + 1 end
          while rx > startX do back[#back + 1] = { kind = "step", dir = "left" }; rx = rx - 1 end
          while ry < startY do back[#back + 1] = { kind = "step", dir = "down" }; ry = ry + 1 end
          while ry > startY do back[#back + 1] = { kind = "step", dir = "up" }; ry = ry - 1 end
          if startFacing then back[#back + 1] = { kind = "turn", dir = startFacing } end
          Objects.startTrack(celioId, back, done)
        end
        local actions = {}
        while y < 8 do actions[#actions + 1] = { kind = "step", dir = "down" }; y = y + 1 end
        while y > 8 do actions[#actions + 1] = { kind = "step", dir = "up" }; y = y - 1 end
        while x > 9 do actions[#actions + 1] = { kind = "step", dir = "left" }; x = x - 1 end
        while x < 9 do actions[#actions + 1] = { kind = "step", dir = "right" }; x = x + 1 end
        actions[#actions + 1] = { kind = "turn", dir = "down" }
        Objects.startTrack(celioId, actions, nextStep)
      end

      mysticTicketBusy, auroraTicketBusy = true, true
      engine.Field.locked = true
      celioApproach(startTicketDialogue)
      return true
    end

    local DARKRAI_NAT = 491
    local DARKRAI_SPECIES = DARKRAI_NAT + 64
    local TOWER_7F = "FR_POKEMON_TOWER_7F"
    local towerActor = nil
    local darkraiSceneBusy = false

    local function darkraiState(session)
      session.modData = session.modData or {}
      session.modData[mod.id] = session.modData[mod.id] or {}
      return session.modData[mod.id]
    end

    local function darkraiTowerTime()
      local hour = tonumber(os.date("*t").hour) or 0
      return hour >= 18 or hour < 4
    end

    local function addDarkraiRoamer(session)
      local group = session.roamer
      if type(group) ~= "table" or type(group.beasts) ~= "table" then
        group = { active = true, beasts = {} }
        session.roamer = group
      end
      for _, beast in ipairs(group.beasts) do
        if beast.darkrai then return beast end
      end

      local mon = Roamer.generateMon(DARKRAI_SPECIES, 50)
      local beast = {
        active = true,
        darkrai = true,
        species = DARKRAI_SPECIES,
        level = 50,
        hp = mon.hp or mon.maxHp,
        maxHp = mon.maxHp or mon.hp,
        status = 0,
        statusNum = 0,
        pid = mon.pid,
        ivs = mon.ivs,
        moves = mon.moves,
        pp = mon.pp,
        map = Roamer.LOCATIONS[(math.random(#Roamer.LOCATIONS))],
      }
      group.beasts[#group.beasts + 1] = beast
      return beast
    end

    local DARKRAI_NPC_ID = 126
    local UntamedEngine = engine

    local function clearTowerActor()
      if Objects._byId and Objects._byId[DARKRAI_NPC_ID] then
        Objects._byId[DARKRAI_NPC_ID] = nil
        for i = #(Objects._order or {}), 1, -1 do
          if Objects._order[i] == DARKRAI_NPC_ID then table.remove(Objects._order, i) end
        end
      end
      towerActor = nil
    end

    local function showTowerDarkrai()
      local session = engine.Runtime and engine.Runtime.getSession and engine.Runtime.getSession()
      local mapId = session and session.map
      local state = session and darkraiState(session)
      local shouldShow = session and state and session.game_cleared == true
        and state.darkraiTowerTriggered ~= true and darkraiTowerTime()
        and mapId == TOWER_7F and not darkraiSceneBusy

      if not shouldShow then clearTowerActor(); return end
      if towerActor and Objects._byId and Objects._byId[DARKRAI_NPC_ID] == towerActor then return end
      clearTowerActor()
      if not Objects._byId or not Objects._order then return end

      -- This is a regular field NPC.  The graphics id uses Untamed Advanced's
      -- own serialized sprite format, so its OwSprites.draw hook renders
      -- Darkrai from the exact same atlas and palette as Untamed followers.
      local personality = engine.random32 and engine.random32() or 0
      local atlasSpecies = engine.expansionSpecies(DARKRAI_SPECIES, personality)
      if not atlasSpecies then return end
      local female = engine.femaleFor and engine.femaleFor(DARKRAI_SPECIES, personality) or false
      local sheet, row = engine.Gfx.sheetFor(atlasSpecies, female, false)
      if not sheet then return end

      -- Untamed follower face-down frame is frame 0.
      local graphicsId = string.format("uadv:%d:0:0:%d:0", sheet, row)
      local x, y = 11, 4
      local actor = {
        active=true, localId=DARKRAI_NPC_ID, originLocalId=DARKRAI_NPC_ID,
        originMapId=session.map, cellX=x, cellY=y, px=x*16, py=y*16,
        homeX=x, homeY=y, targetX=x, targetY=y,
        facing="down", sprite=graphicsId, graphicsId=graphicsId,
        elevation=engine.elevationAt and engine.elevationAt(x, y) or 3,
        currentElevation=engine.elevationAt and engine.elevationAt(x, y) or 3,
        movementType=0x09, movement="STAY", range="DOWN",
        radius={x=0,y=0}, rangeX=0, rangeY=0,
        visible=true, hidden=false, invisible=false, frozen=true,
        passable=false, moving=false, progress=0, stepFrames=16,
        scriptBusy=false,
        def={ localId=DARKRAI_NPC_ID, x=x, y=y, graphicsId=graphicsId,
          movementType=0x09, facing="down" },
      }
      Objects._byId[DARKRAI_NPC_ID] = actor
      Objects._order[#Objects._order + 1] = DARKRAI_NPC_ID
      towerActor = actor
    end

    local function triggerDarkraiScene()
      if not towerActor or not towerActor.active or darkraiSceneBusy then return false end
      local session = engine.Runtime.getSession()
      if not session or session.map ~= TOWER_7F then return false end
      local P = engine.Player
      -- Trigger one tile before Darkrai instead of requiring interaction/collision.
      if P.cellX ~= 11 or P.cellY ~= 5 then return false end

      local Message = require("src.ui.game3.message")
      local Fade = require("src.ui.game3.fade")
      darkraiSceneBusy = true
      engine.Field.locked = true
      P.facing = "up"

      Message.show("A cold presence hangs in the air...", function()
        Message.show("You suddenly feel very tired...", function()
          Fade.begin(Fade.MODE.TO_BLACK, 1, function()
            clearTowerActor()
            local state = darkraiState(session)
            state.darkraiTowerTriggered = true
            addDarkraiRoamer(session)
            Fade.begin(Fade.MODE.FROM_BLACK, 1, function()
              Message.show("The POKEMON vanished!", function()
                engine.Field.locked = false
                darkraiSceneBusy = false
              end)
            end)
          end)
        end)
      end)
      return true
    end

    local rawTableFor = engine.Encounters.tableFor
    engine.Encounters.tableFor = function(mapId, ...)
      local profile = mapId and PROFILE_BY_ID[mapId]
      if profile then
        local result = buildTable(profile, currentPeriod(), Pokemon)

        -- Unown can very rarely appear on any numbered Kanto route.
        -- Resolve this per spawn request instead of taking a normal table slot.
        if profile.id:match("^FR_ROUTE_") and math.random(1000) == 1 then
          local unown = entry(201, profile.min, profile.max)
          local rare = {}
          if result.land then
            rare.land = { rate = result.land.rate, slots = {} }
            for i = 1, math.max(1, #result.land.slots) do
              rare.land.slots[i] = unown
            end
          end
          if result.water then
            rare.water = { rate = result.water.rate, slots = {} }
            for i = 1, math.max(1, #result.water.slots) do
              rare.water.slots[i] = unown
            end
          end
          if result.fishing then rare.fishing = result.fishing end
          return rare
        end

        return result
      end
      return rawTableFor(mapId, ...)
    end

    local rawInvalidate = engine.invalidateMapCaches
    engine.invalidateMapCaches = function(...)
      cache = cache or {}
      return rawInvalidate(...)
    end

    local function refreshPeriod()
      local period = currentPeriod()
      if period == lastPeriod then return end
      lastPeriod = period
      cache = {}
      if engine.Owe and engine.Owe.despawnAll then engine.Owe.despawnAll("generated", false) end
      engine.invalidateMapCaches()
    end

    mod.events:on("map.entered", function(ev)
      refreshPeriod()
      showTowerDarkrai()
      enableTicketDebugTravel(engine.Runtime and engine.Runtime.getSession and engine.Runtime.getSession())
      tryTicketEvents()
    end)
    mod.events:on("world.stepped", function(ev)
      refreshPeriod()
      showTowerDarkrai()
      triggerDarkraiScene()
      tryTicketEvents()
    end)

    mod.exports.engine = engine
    mod.exports.period = currentPeriod
    mod.exports.tables = PROFILES
    mod.exports.fullNationalDexCoverage = false
    mod.exports.fullEvolutionaryFamilyCoverage = true
    installed = true
    mod.log:info("RTC + Untamed + National Dex encounter compatibility installed")
    return true
  end

  mod.events:on("game.ready", install, -50)
end