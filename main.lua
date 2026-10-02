return function(mod)
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
    { id="FR_ROUTE_2", habitat="forest", min=3, max=10, gen=1, base={morning={10,16,11,12,17,167,165,14,13,15,166},day={16,10,12,17,13,15,165},night={163,167,164,168,14,13,15}} },
    { id="FR_ROUTE_3", habitat="field", min=5, max=10, gen=1, base={morning={21,19,23,39,24},day={21,19,23,39,24},night={19,41,23,39,24}} },
    { id="FR_ROUTE_4", habitat="mountain", min=5, max=10, gen=1, base={morning={21,19,23,39,24},day={21,19,23,39,24},night={19,41,23,39,24}} },
    { id="FR_ROUTE_5", habitat="urban", min=12, max=15, gen=2, base={morning={16,69,52,63},day={16,69,52,63},night={43,52,69,44,63}} },
    { id="FR_ROUTE_6", habitat="field", min=12, max=16, gen=2, base={morning={16,69,43,63},day={16,69,52,63},night={19,52,163,200}} },
    { id="FR_ROUTE_7", habitat="urban", min=15, max=19, gen=2, base={morning={19,21,58,20,52,37,53},day={19,21,58,20,52,37,53},night={198,19,58,20,228,52,37,53}} },
    { id="FR_ROUTE_8", habitat="urban", min=15, max=19, gen=2, base={morning={17,63,58,64,52,37},day={17,63,58,64,52,37},night={164,93,63,58,64,52,37}} },
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
    { id="FR_ROUTE_25", habitat="forest", min=8, max=14, gen=1, base={morning={16,69,48,63,17,70},day={16,69,63,17,70},night={163,69,48,63,164,70}} },
    { id="FR_ROUTE_28", habitat="mountain", min=39, max=43, gen=4, base={morning={77,114,232,217,78,84,85},day={77,114,232,217,78,84,85},night={77,114,232,217,215,78}} },
    { id="FR_VIRIDIAN_FOREST", habitat="forest", min=3, max=8, gen=4, base={morning={10,11,12,13,14,15,16,17,25,325,322,406,455},day={10,11,13,14,16,17,25,325,322,406,455},night={163,164,25,325,322,406,455}} },
    { id="FR_DIGLETTS_CAVE", habitat="cave", min=13, max=29, gen=4, base={morning={50,51,359,296,436,433},day={50,51,359,296,436,433},night={50,51,359,296,436,433}} },
    { id="FR_MT_MOON_1F", habitat="cave", min=6, max=12, gen=4, base={morning={41,74,27,46,28,35,359,296,436,433},day={41,74,27,46,28,35,359,296,436,433},night={41,74,27,46,28,35,359,296,436,433}} },
    { id="FR_MT_MOON_B1F", habitat="cave", min=6, max=12, gen=4, base={morning={41,74,27,46,28,35,359,296,436,433},day={41,74,27,46,28,35,359,296,436,433},night={41,74,27,46,28,35,359,296,436,433}} },
    { id="FR_MT_MOON_B2F", habitat="cave", min=6, max=12, gen=4, base={morning={41,74,27,46,28,35,359,296,436,433},day={41,74,27,46,28,35,359,296,436,433},night={41,74,27,46,28,35,359,296,436,433}} },
    { id="FR_ROCK_TUNNEL_1F", habitat="cave", min=8, max=14, gen=4, base={morning={104,74,66,41,67,359,296,436,433},day={104,74,66,41,67,359,296,436,433},night={104,74,66,41,67,359,296,436,433}} },
    { id="FR_ROCK_TUNNEL_B1F", habitat="cave", min=10, max=16, gen=4, base={morning={74,104,95,41,105,115,359,296,436,433},day={74,104,95,41,105,115,359,296,436,433},night={74,104,95,41,105,115,359,296,436,433}} },
    { id="FR_POWER_PLANT", habitat="electric", min=20, max=35, gen=4, base={morning={81,100,25,125},day={81,100,25,125},night={81,100,125,479}} },
    { id="FR_POKEMON_TOWER_1F", habitat="ghost", min=20, max=28, gen=2, base={morning={41,92,93,200},day={41,92,93,200},night={92,93,200,355}} },
    { id="FR_POKEMON_TOWER_2F", habitat="ghost", min=21, max=29, gen=2, base={morning={92,93,200,355},day={92,93,200,355},night={92,93,200,355}} },
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
    { id="FR_CERULEAN_CAVE_1F", habitat="rare", min=38, max=46, gen=4, base={morning={67,47,57,82,132,42,101,202,359,296,436,433},day={67,47,57,82,132,42,101,202,359,296,436,433},night={67,47,57,82,132,42,101,202,359,296,436,433}} },
    { id="FR_CERULEAN_CAVE_B1F", habitat="rare", min=42, max=49, gen=4, base={morning={47,64,82,42,67,132,101,202,359,296,436,433},day={47,64,82,42,67,132,101,202,359,296,436,433},night={47,64,82,42,67,132,101,202,359,296,436,433}} },
    { id="FR_CERULEAN_CAVE_B2F", habitat="rare", min=40, max=46, gen=4, base={morning={47,64,67,42,82,132,101,202,359,296,436,433},day={47,64,67,42,82,132,101,202,359,296,436,433},night={47,64,67,42,82,132,101,202,359,296,436,433}} },
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

  local PROFILE_BY_ID = {}
  for _, p in ipairs(PROFILES) do PROFILE_BY_ID[p.id] = p end

  local function typeList(nat, Pokemon)
    local species = nat <= 386 and nat or nat + 64
    local ok, a, b = pcall(Pokemon.types, species)
    if not ok then return {} end
    return {a, b}
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

  local function isLegendaryOrMythical(nat)
    return LEGENDARY_OR_MYTHICAL[nat] == true
  end

  -- One representative from every evolutionary family that is still absent
  -- after the merged HGSS/FireRed encounter backbone. Only these missing
  -- families are added; their evolutions are left to evolution/breeding.
  local MISSING_FAMILY_REPRESENTATIVES = {
    1,4,7,60,83,98,102,106,108,116,122,123,124,126,127,131,133,137,138,140,142,143,147,152,155,158,176,177,179,183,185,190,191,193,201,203,204,206,207,209,211,213,214,220,222,223,225,226,227,234,235,241,246,252,255,258,261,263,265,270,273,276,278,280,283,285,287,290,293,299,300,302,303,304,307,309,311,312,313,314,316,318,320,324,327,328,331,333,335,336,337,338,339,341,343,345,347,349,351,352,353,357,361,363,366,369,370,371,374,387,390,393,396,399,401,403,408,410,412,415,417,418,420,422,425,427,431,434,441,442,443,448,449,451,453,456,459
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
      local maps = HABITAT_MAP[habitat] or HABITAT_MAP.field
      local bestId, bestPeriod, bestLoad = nil, nil, math.huge

      for _, id in ipairs(maps) do
        if PROFILE_BY_ID[id] then
          for _, period in ipairs(PERIODS) do
            local score = load[id][period]
            if score < bestLoad then
              bestId, bestPeriod, bestLoad = id, period, score
            end
          end
        end
      end

      if bestId then
        local list = extraAssignments[bestId][bestPeriod]
        list[#list + 1] = nat
        load[bestId][bestPeriod] = load[bestId][bestPeriod] + 1
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

  local function buildTable(profile, period, Pokemon)
    local key = profile.id .. "|" .. period
    if cache[key] then return cache[key] end

    local out, seen = {}, {}
    local base = profile.base and profile.base[period] or {}

    -- Keep the encounter count natural to the location. HGSS routes commonly
    -- have only a few distinct species; do not pad every table to 12.
    for _, nat in ipairs(base) do
      if nat >= 1 and nat <= 493 and not isLegendaryOrMythical(nat) then
        uniqueAppend(out, seen, entry(nat, profile.min, profile.max))
      end
    end

    local additions = buildExtraAssignments(Pokemon)
    local extras = additions[profile.id] and additions[profile.id][period] or {}
    for _, nat in ipairs(extras) do
      uniqueAppend(out, seen, entry(nat, profile.min, profile.max))
    end

    cache[key] = { land = { rate = 20, slots = out } }
    if profile.water then
      cache[key].land = nil
      cache[key].water = { rate = 20, slots = out }
    end
    return cache[key]
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

    local rawTableFor = engine.Encounters.tableFor
    engine.Encounters.tableFor = function(mapId, ...)
      local profile = mapId and PROFILE_BY_ID[mapId]
      if profile then
        return buildTable(profile, currentPeriod(), Pokemon)
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

    mod.events:on("map.entered", refreshPeriod)
    mod.events:on("world.stepped", refreshPeriod)

    mod.exports.engine = engine
    mod.exports.period = currentPeriod
    mod.exports.tables = PROFILES
    mod.exports.fullNationalDexCoverage = true
    installed = true
    mod.log:info("RTC + Untamed + National Dex encounter compatibility installed")
    return true
  end

  mod.events:on("game.ready", install, -50)
end