-- G9 Battle Sprites - Gen 3
-- FireRed/LeafGreen adapter for tectorifter/g9-battle-sprites.
--
-- G9's public API does not expose its live battle frames or asset root.  This
-- adapter therefore uses engine_internals to locate the installed G9 release,
-- reads its own dbk_data.lua mapping, and feeds animated 64x64 frames through
-- Gen 3's native Pokemon.frontPic/backPic path.

return function(mod)
  local okPokemon, Pokemon = pcall(require, "src.core.game3.pokemon")
  if not okPokemon or type(Pokemon) ~= "table" then
    mod.log:error("Gen 3 Pokemon renderer is unavailable")
    return
  end

  local originalFront = Pokemon.frontPic
  local originalBack = Pokemon.backPic
  if type(originalFront) ~= "function" or type(originalBack) ~= "function" then
    mod.log:error("Gen 3 front/back picture functions are unavailable")
    return
  end

  local G9_ID = "g9-battle-sprites"
  local BOX = 64
  local FPS = 12
  local g9Root, g9Data
  local slotToId = {}
  local cache = {}
  local installed = false

  local function loadChunk(text, name)
    if type(text) ~= "string" then return nil end
    local fn, err = loadstring(text, name)
    if not fn then return nil, err end
    local ok, value = pcall(fn)
    if not ok then return nil, value end
    return value
  end

  local function rebuildSpeciesMap()
    slotToId = {}
    local reg = mod.content and mod.content.pokemon
    if not reg then return end
    local ok, iter = pcall(function() return reg:each() end)
    if not ok or type(iter) ~= "function" then return end
    while true do
      local id, r = iter()
      if id == nil then break end
      if type(r) == "table" then
        local slot = tonumber(r.gen3Species or r.index or r.species)
        if slot then slotToId[slot] = tostring(id):upper() end
      end
    end
  end

  local function locateG9(game)
    local loader = game and game.mods
    if not loader then
      mod.log:error("mod loader is unavailable")
      return false
    end

    -- Deliberately inspect the loader's discovered records rather than
    -- mod:find().  G9 declares Gen 1/2 only, so on a Gen 3 boot it is present
    -- on disk but inactive/incompatible and therefore invisible to mod:find().
    local rec = loader.mods and loader.mods[G9_ID]
    if not rec and loader.available then
      for _, candidate in pairs(loader.available) do
        local man = candidate and candidate.manifest
        if (man and man.id == G9_ID) or candidate.id == G9_ID then
          rec = candidate
          break
        end
      end
    end
    local root = rec and rec.path
    if not root then
      mod.log:warn("G9 Battle Sprites release is not installed; using normal Gen 3 sprites")
      return false
    end

    local fs = loader.fs
    if not (fs and fs.read) then
      mod.log:error("mod filesystem is unavailable")
      return false
    end
    loaderFs = fs
    local raw = fs.read(root .. "/data/dbk_data.lua")
    local data, err = loadChunk(raw, "@g9-battle-sprites/data/dbk_data.lua")
    if type(data) ~= "table" or type(data.species) ~= "table" then
      mod.log:error("could not read G9 sprite mapping: %s", tostring(err))
      return false
    end
    g9Root, g9Data = root, data
    return true
  end

  local function speciesId(slot)
    return slotToId[tonumber(slot)]
  end

  local function stemFor(slot)
    local id = speciesId(slot)
    if not id or not g9Data then return nil end
    return g9Data.species[id] or g9Data.species[id:gsub("_FORM$", "")]
  end

  local function assetPath(folder, stem)
    if not (g9Root and stem) then return nil end
    return g9Root .. "/assets/" .. folder .. "/" .. stem .. ".png"
  end

  local function fileExists(path)
    local fs = loaderFs
    if not (fs and fs.getInfo) then return true end
    local ok, info = pcall(fs.getInfo, path)
    return ok and info and info.type == "file"
  end

  local function bakeSheet(path)
    if not (love and love.graphics) then return nil end
    local ok, sheet = pcall(love.graphics.newImage, path)
    if not ok or not sheet then return nil end
    sheet:setFilter("nearest", "nearest")

    local sw, sh = sheet:getDimensions()
    -- DBK solo sheets are horizontal strips whose frames are square: the
    -- sheet height is one frame's width/height.
    local fw, fh = sh, sh
    if fw <= 0 or sw < fw then return nil end
    local count = math.max(1, math.floor(sw / fw + 0.0001))
    local frames = {}

    for i = 0, count - 1 do
      local canvas = love.graphics.newCanvas(BOX, BOX)
      canvas:setFilter("nearest", "nearest")
      local quad = love.graphics.newQuad(i * fw, 0, fw, fh, sw, sh)
      local scale = math.min(1, BOX / fw, BOX / fh)
      local dw, dh = fw * scale, fh * scale
      local x = math.floor((BOX - dw) / 2 + 0.5)
      local y = math.floor(BOX - dh + 0.5)

      local old = love.graphics.getCanvas()
      love.graphics.setCanvas(canvas)
      love.graphics.clear(0, 0, 0, 0)
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(sheet, quad, x, y, 0, scale, scale)
      love.graphics.setCanvas(old)
      frames[#frames + 1] = canvas
    end

    return frames
  end

  local function framesFor(slot, back, shiny)
    if not installed then return nil end
    local stem = stemFor(slot)
    if not stem then return nil end
    local folder
    if back then folder = shiny and "back_shiny" or "back"
    else folder = shiny and "front_shiny" or "front" end
    local key = folder .. ":" .. stem
    if cache[key] == false then return nil end
    if cache[key] then return cache[key] end

    local path = assetPath(folder, stem)
    if not path or not fileExists(path) then
      cache[key] = false
      return nil
    end
    local frames = bakeSheet(path)
    cache[key] = frames or false
    return frames
  end

  local function currentFrame(frames)
    if not frames or #frames == 0 then return nil end
    if #frames == 1 then return frames[1] end
    local t = (love and love.timer and love.timer.getTime and love.timer.getTime()) or os.clock()
    local n = math.floor(t * FPS) % #frames + 1
    return frames[n]
  end

  local function replacement(slot, back, shiny)
    local frames = framesFor(slot, back, shiny == true)
    local img = currentFrame(frames)
    if not img then return nil end
    return { image = img, w = BOX, h = BOX, trueColor = true }
  end

  Pokemon.frontPic = function(slot, form, shiny, personality)
    local rep = replacement(slot, false, shiny)
    if rep then return rep end
    return originalFront(slot, form, shiny, personality)
  end

  Pokemon.backPic = function(slot, form, shiny)
    local rep = replacement(slot, true, shiny)
    if rep then return rep end
    return originalBack(slot, form, shiny)
  end

  mod.events:on("game.ready", function(ev)
    local game = (ev and ev.game) or mod.game
    rebuildSpeciesMap()
    installed = locateG9(game)
    if installed then
      mod.log:info("Gen 3 animated G9 renderer active (%d fps)", FPS)
    end
  end, -200)

  mod.exports.clearCache = function()
    cache = {}
  end
end
