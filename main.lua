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
  local FPS = 12
  local g9Root, g9Data, g9Metrics, g9Floaters
  local imageMeta = setmetatable({}, { __mode = "k" })
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
    local count = math.max(1, math.floor((sw + sh / 2) / sh))
    local fw = math.floor(sw / count)
    if fw < 1 then return nil end

    -- Match G9 natural mode: scan the whole animation once for a UNION content
    -- box so individual frames never jitter, keep that trimmed art at 1:1, and
    -- only shrink if the species is too large for the available Gen 3 field.
    local ux0, uy0, ux1, uy1 = fw, sh, -1, -1
    for y = 0, sh - 1 do
      for x = 0, sw - 1 do
        local _, _, _, alpha = sheetData:getPixel(x, y)
        if alpha and alpha > 0.01 then
          local lx = x % fw
          if lx < ux0 then ux0 = lx end
          if lx > ux1 then ux1 = lx end
          if y < uy0 then uy0 = y end
          if y > uy1 then uy1 = y end
        end
      end
    end
    if ux1 < ux0 or uy1 < uy0 then return nil end

    local cw, ch = ux1 - ux0 + 1, uy1 - uy0 + 1
    -- FireRed's stock renderer has a 64px picture box, but G9 natural art may
    -- be larger. These are scene headroom limits, not target sprite sizes.
    local maxW = back and 112 or 96
    local maxH = back and 104 or 88
    -- Back sprites sit much closer to the camera in G9. Allow small backs to
    -- grow instead of permanently capping every trimmed sheet at 1:1.
    local naturalScale = 1
    local targetScale = back and 1.5 or 1
    local fitScale = math.min(naturalScale, maxW / cw, maxH / ch)
    -- Front path restored to the known-good e44e927 behavior. It bakes the
    -- trimmed G9 frame using the original fit calculation, but never applies
    -- a second draw-time scale to fronts. Backs keep their later proven-good
    -- presentation behavior.
    local scale = fitScale
    local drawScale = back
      and math.min(targetScale, maxW / cw, maxH / ch)
      or 1
    local dw = math.max(1, math.floor(cw * scale + 0.5))
    local dh = math.max(1, math.floor(ch * scale + 0.5))
    local frames = {}

    for i = 0, count - 1 do
      local frameData = love.image.newImageData(fw, sh)
      frameData:paste(sheetData, 0, 0, i * fw, 0, fw, sh)
      local frameImg = love.graphics.newImage(frameData)
      frameImg:setFilter("nearest", "nearest")
      local quad = love.graphics.newQuad(ux0, uy0, cw, ch, fw, sh)
      local canvas = love.graphics.newCanvas(dw, dh)
      canvas:setFilter("nearest", "nearest")
      local oldCanvas = love.graphics.getCanvas()
      love.graphics.setCanvas(canvas)
      love.graphics.clear(0, 0, 0, 0)
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(frameImg, quad, 0, 0, 0, scale, scale)
      love.graphics.setCanvas(oldCanvas)
      frames[#frames + 1] = canvas
    end

    frames._g9DrawScale = drawScale
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
    local stem = stemFor(slot)
    local metric = stem and g9Metrics and g9Metrics[stem] or nil
    -- Back sprites need a scene-level correction left. Enemy fronts use G9's
    -- own per-species FrontSprite Y metric, so short/low-bodied species are
    -- lowered individually instead of moving every enemy by the same amount.
    imageMeta[img] = {
      drawScale = back and (frames._g9DrawScale or 1) or 1,
      g9Back = back,
      -- Keep the scene correction, but also respect G9's authored back
      -- placement instead of centering every species identically.
      ox = back
        and (-16 + math.floor(((metric and tonumber(metric.bx)) or 0) * 0.5 + 0.5))
        or 2,
      -- Natural G9 fronts are grounded by their trimmed bottom edge, then use
      -- G9's per-species front Y metric. FireRed's centre-origin draw needs the
      -- equivalent correction based on this frame's actual height.
      oy = back
        -- Player platform contact point in the authored 240x135 background is
        -- Shift the player/back battler another 12 px left from the authored platform
        -- anchor to open space between it and the right-side HUD: -22,-6
        -- while retaining G9's species-specific back metric.
        and (function()
          -- Preserve the proven-good G9 back placement range (Bidoof is
          -- by=15). Larger authored by values over-drop trimmed Gen3 backs,
          -- because their original sheet padding has already been removed.
          local by = (metric and tonumber(metric.by)) or 0
          local normalBy = math.min(by, 15)
          return -6 + math.floor(normalBy * 0.5 + 0.5)
        end)()
        or (function()
          -- Known-good e44e927 front placement: ground the trimmed image on
          -- the authored enemy contact point and apply G9's front-Y metric.
          local fy = (metric and tonumber(metric.fy)) or 0
          local base = 32 - (h / 2) + 17
          return math.floor(base - (6 - fy) * 2 + 0.5)
        end)(),
    }
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

  -- Fullscreen FireRed terrain replacement. Custom art is authored at
  -- 240x135 (16:9); nearest filtering keeps every source pixel crisp.
  -- Each filename matches BattleBg.sheetKey(). Missing files fall back to
  -- FireRed's native terrain/platform renderer.
  local customBackgrounds = {}
  local function loadCustomBackground(key)
    if not key or key == "" then return nil end
    -- No custom mountain art: use the authored sand background instead.
    if key == "mountain" then key = "sand" end
    if customBackgrounds[key] ~= nil then
      return customBackgrounds[key] or nil
    end
    customBackgrounds[key] = false
    if not (love and love.graphics and mod.assets and mod.assets.path) then return nil end
    local okPath, path = pcall(mod.assets.path, mod.assets,
      "assets/backgrounds/" .. tostring(key) .. ".png")
    if not okPath or not path then return nil end
    local okImg, img = pcall(love.graphics.newImage, path)
    if not okImg or not img then return nil end
    if img.setFilter then img:setFilter("nearest", "nearest") end
    customBackgrounds[key] = img
    return img
  end

  local okBg, BattleBg = pcall(require, "src.core.game3.battle.bg")
  local okChrome, BattleChrome = pcall(require, "src.ui.game3.battle_chrome")
  if okBg and okChrome and BattleBg and BattleChrome and type(BattleBg.draw) == "function" then
    local originalBgDraw = BattleBg.draw
    BattleBg.draw = function(id, enemyOx, playerOx, bgOx)
      local key = BattleBg.sheetKey(id)
      local img = loadCustomBackground(key)
      if not img then
        return originalBgDraw(id, enemyOx, playerOx, bgOx)
      end

      -- Custom 240x135 art already contains both battle platforms.
      love.graphics.clear(0, 0, 0, 0)
      love.graphics.setColor(1, 1, 1, 1)
      return true
    end
  end

  -- Fullscreen 16:9 battle presentation. Kanto Gear's compose wrapper uses
  -- priority -1000, so run farther downstream: Gear calls us via next(), then
  -- resumes and submits its companion display after this returns.
  if mod.hooks and mod.hooks.wrap then
    mod.hooks:wrap("render.compose", function(next, renderer, ctx)
      local okBattle, Battle = pcall(require, "src.core.game3.battle")
      local active = okBattle and Battle and Battle.isActive and Battle.isActive()
      local key = active and okBg and BattleBg and BattleBg.sheetKey
        and BattleBg.sheetKey() or nil
      local img = key and loadCustomBackground(key) or nil
      if not (img and ctx and ctx.uiCanvas) then
        return next(renderer, ctx)
      end

      local ww = tonumber(ctx.ww) or love.graphics.getWidth()
      local wh = tonumber(ctx.wh) or love.graphics.getHeight()
      local iw, ih = img:getDimensions()
      local cw, ch = ctx.uiCanvas:getDimensions()
      local sceneH = math.min(135, ch)
      local sceneW = math.min(240, cw)
      local quad = love.graphics.newQuad(0, 0, sceneW, sceneH, cw, ch)

      love.graphics.push("all")
      love.graphics.origin()
      love.graphics.setScissor()
      love.graphics.setBlendMode("alpha")
      love.graphics.clear(0, 0, 0, 1)
      love.graphics.setColor(1, 1, 1, 1)
      img:setFilter("nearest", "nearest")
      ctx.uiCanvas:setFilter("nearest", "nearest")
      love.graphics.draw(img, 0, 0, 0, ww / iw, wh / ih)
      love.graphics.draw(ctx.uiCanvas, quad, 0, 0, 0,
        ww / sceneW, wh / sceneH)
      love.graphics.pop()
      quad:release()
      return true
    end, -2000)
  end

  -- Drop only the player's native singles healthbox below the opposing
  -- battler. Keep its stock X center so the full 96px composite stays inside
  -- the 240px Gen3 HUD canvas.
  local okHealthbox, Healthbox = pcall(require, "src.core.game3.battle.healthbox")
  if okHealthbox and Healthbox then
    Healthbox.PLAYER_CENTER.y = 106
    if Healthbox.CENTERS and Healthbox.CENTERS[false]
        and Healthbox.CENTERS[false][0] then
      Healthbox.CENTERS[false][0].y = 106
    end
    -- Raise only the opposing/enemy healthbox 14 px from the engine's
    -- existing authored position. Do this relatively so we do not hard-code
    -- or disturb the player's already-adjusted healthbox.
    if Healthbox.ENEMY_CENTER and type(Healthbox.ENEMY_CENTER.y) == "number" then
      Healthbox.ENEMY_CENTER.y = Healthbox.ENEMY_CENTER.y - 14
    end
    if Healthbox.CENTERS and Healthbox.CENTERS[true]
        and Healthbox.CENTERS[true][0]
        and type(Healthbox.CENTERS[true][0].y) == "number" then
      Healthbox.CENTERS[true][0].y = Healthbox.CENTERS[true][0].y - 14
    end
  end

  -- Gen 3's stock battle renderer hard-codes a 32,32 origin because vanilla
  -- pics are 64x64. Intercept only draws of our G9 images: use their real
  -- centre as the origin and apply the scene/alignment corrections above.
  local okUi, Ui = pcall(require, "src.core.game3.battle.ui")
  if okUi and Ui and type(Ui.draw) == "function" then
    local originalUiDraw = Ui.draw
    Ui.draw = function(...)
      local realDraw = love and love.graphics and love.graphics.draw
      if type(realDraw) ~= "function" then return originalUiDraw(...) end
      love.graphics.draw = function(drawable, x, y, r, sx, sy, ox, oy, ...)
        local meta = imageMeta[drawable]
        if meta then
          x = (x or 0) + (meta.ox or 0)
          y = (y or 0) + (meta.oy or 0)
          if meta.g9Back then
            local baseSx = sx or 1
            local baseSy = sy or baseSx
            local ds = meta.drawScale or 1
            sx = baseSx * ds
            sy = baseSy * ds
            local iw, ih = drawable:getDimensions()
            ox = iw * 0.5
            oy = ih * 0.5
          else
            -- Keep the known-good e44e927 front bake and scale untouched, but
            -- anchor the trimmed G9 image by its real centre like the backs.
            -- Compensate x/y for FireRed's old 32,32-style origin first, so
            -- changing the origin does not change the established placement.
            local iw, ih = drawable:getDimensions()
            local baseSx = sx or 1
            local baseSy = sy or baseSx
            local nativeOx = tonumber(ox) or 32
            local nativeOy = tonumber(oy) or 32
            x = (x or 0) + (iw * 0.5 - nativeOx) * baseSx
            y = (y or 0) + (ih * 0.5 - nativeOy) * baseSy - 6
            ox = iw * 0.5
            oy = ih * 0.5
          end
        end
        return realDraw(drawable, x, y, r, sx, sy, ox, oy, ...)
      end
      local ok, a, b, c, d = pcall(originalUiDraw, ...)
      love.graphics.draw = realDraw
      if not ok then error(a, 0) end
      return a, b, c, d
    end
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
