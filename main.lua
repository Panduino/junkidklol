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

  local function opaqueBounds(data)
    local w, h = data:getDimensions()
    local minX, minY, maxX, maxY = w, h, -1, -1
    for y = 0, h - 1 do
      for x = 0, w - 1 do
        local _, _, _, a = data:getPixel(x, y)
        if a and a > 0.01 then
          if x < minX then minX = x end
          if y < minY then minY = y end
          if x > maxX then maxX = x end
          if y > maxY then maxY = y end
        end
      end
    end
    if maxX < minX then return 0, 0, w, h end
    return minX, minY, maxX - minX + 1, maxY - minY + 1
  end

  local function bakeSheet(path, back)
    if not (love and love.graphics and love.image) then return nil end
    local okData, sheetData = pcall(love.image.newImageData, path)
    if not okData or not sheetData then return nil end

    local sw, sh = sheetData:getDimensions()
    local fw, fh = sh, sh
    if fw <= 0 or sw < fw then return nil end
    local count = math.max(1, math.floor(sw / fw + 0.0001))
    local frames = {}

    -- Preserve G9/DBK's authored scale.  The source pack uses 2x front and
    -- 3x back render scales; convert source pixels back to screen pixels and
    -- only shrink when a genuinely large Pokemon would overrun the Gen 3
    -- battle scene.  There is intentionally no 64x64 output canvas.
    local packScale = back and 3 or 2
    local maxW = back and 112 or 96
    local maxH = back and 104 or 88

    for i = 0, count - 1 do
      local frameData = love.image.newImageData(fw, fh)
      frameData:paste(sheetData, 0, 0, i * fw, 0, fw, fh)
      local bx, by, bw, bh = opaqueBounds(frameData)

      local scale = 1 / packScale
      local dw, dh = bw * scale, bh * scale
      if dw > maxW or dh > maxH then
        local fit = math.min(maxW / dw, maxH / dh)
        scale = scale * fit
        dw, dh = bw * scale, bh * scale
      end

      local outW = math.max(1, math.floor(dw + 0.5))
      local outH = math.max(1, math.floor(dh + 0.5))
      local canvas = love.graphics.newCanvas(outW, outH)
      canvas:setFilter("nearest", "nearest")
      local frameImg = love.graphics.newImage(frameData)
      frameImg:setFilter("nearest", "nearest")
      local quad = love.graphics.newQuad(bx, by, bw, bh, fw, fh)

      local old = love.graphics.getCanvas()
      love.graphics.setCanvas(canvas)
      love.graphics.clear(0, 0, 0, 0)
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(frameImg, quad, 0, 0, 0, scale, scale)
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
    local frames = bakeSheet(path, back)
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
    local w, h = img:getDimensions()
    return { image = img, w = w, h = h, trueColor = true, g9Gen3 = true, g9Back = back }
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
