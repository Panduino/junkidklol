return function(mod)
  if mod.game.generation ~= 3 then return end

  local installed = false

  local function install()
    if installed then return end

    local okMarts, Marts = pcall(require, "src.core.game3.marts")
    local okConstants, Constants = pcall(require, "src.core.game3.constants")
    if not okMarts or not okConstants or type(Marts.itemsFor) ~= "function" then
      mod.log:error("Expanded Pokemarts could not access the Gen 3 mart system")
      return
    end

    local C = Constants.of("firered")
    local function item(name)
      return C:id("items", name)
    end

    local MASTER_BALL = item("ITEM_MASTER_BALL")
    local POKE_BALL = item("ITEM_POKE_BALL")
    local GREAT_BALL = item("ITEM_GREAT_BALL")
    local ULTRA_BALL = item("ITEM_ULTRA_BALL")
    local POTION = item("ITEM_POTION")
    local SUPER_POTION = item("ITEM_SUPER_POTION")
    local HYPER_POTION = item("ITEM_HYPER_POTION")
    local MAX_POTION = item("ITEM_MAX_POTION")
    local FULL_RESTORE = item("ITEM_FULL_RESTORE")
    local ANTIDOTE = item("ITEM_ANTIDOTE")
    local PARALYZE_HEAL = item("ITEM_PARALYZE_HEAL")
    local AWAKENING = item("ITEM_AWAKENING")
    local BURN_HEAL = item("ITEM_BURN_HEAL")
    local ICE_HEAL = item("ITEM_ICE_HEAL")
    local FULL_HEAL = item("ITEM_FULL_HEAL")
    local REVIVE = item("ITEM_REVIVE")
    local MAX_REVIVE = item("ITEM_MAX_REVIVE")
    local REPEL = item("ITEM_REPEL")
    local SUPER_REPEL = item("ITEM_SUPER_REPEL")
    local MAX_REPEL = item("ITEM_MAX_REPEL")
    local ESCAPE_ROPE = item("ITEM_ESCAPE_ROPE")

    local function contains(items, wanted)
      if not wanted then return false end
      for _, id in ipairs(items or {}) do
        if id == wanted then return true end
      end
      return false
    end

    local function append(items, seen, id)
      if id and not seen[id] then
        items[#items + 1] = id
        seen[id] = true
      end
    end

    local function normalMart(items)
      if type(items) ~= "table" then return false end
      local staples = 0
      for _, id in ipairs({ POKE_BALL, GREAT_BALL, ULTRA_BALL, POTION,
                            SUPER_POTION, ANTIDOTE, PARALYZE_HEAL }) do
        if contains(items, id) then staples = staples + 1 end
      end
      return staples >= 2
    end

    local function expanded(items)
      if not normalMart(items) then return items end

      local out, seen = {}, {}
      for _, id in ipairs(items) do append(out, seen, id) end

      -- Later games keep the basic adventuring supplies available instead of
      -- dropping them from each new town's inventory.
      append(out, seen, POKE_BALL)
      append(out, seen, POTION)
      append(out, seen, ANTIDOTE)
      append(out, seen, PARALYZE_HEAL)
      append(out, seen, AWAKENING)
      append(out, seen, REPEL)

      local tier = 1
      if contains(items, GREAT_BALL) or contains(items, SUPER_POTION)
          or contains(items, REVIVE) then tier = 2 end
      if contains(items, ULTRA_BALL) or contains(items, HYPER_POTION)
          or contains(items, MAX_REPEL) then tier = 3 end
      if contains(items, MAX_POTION) or contains(items, FULL_RESTORE) then
        tier = 4
      end

      if tier >= 2 then
        append(out, seen, GREAT_BALL)
        append(out, seen, SUPER_POTION)
        append(out, seen, BURN_HEAL)
        append(out, seen, ICE_HEAL)
        append(out, seen, ESCAPE_ROPE)
        append(out, seen, SUPER_REPEL)
      end
      if tier >= 3 then
        append(out, seen, ULTRA_BALL)
        append(out, seen, HYPER_POTION)
        append(out, seen, FULL_HEAL)
        append(out, seen, REVIVE)
        append(out, seen, MAX_REPEL)
      end
      if tier >= 4 then
        append(out, seen, MAX_POTION)
        append(out, seen, FULL_RESTORE)
        append(out, seen, MAX_REVIVE)
        append(out, seen, MASTER_BALL)
      end

      return out
    end

    local ItemsData = require("src.core.game3.items_data")
    local rawInfo = ItemsData.info
    ItemsData.info = function(id)
      local info = rawInfo(id)
      if info and id == MASTER_BALL then info.price = 15000 end
      return info
    end

    local rawItemsFor = Marts.itemsFor
    Marts.itemsFor = function(key)
      local items, entry = rawItemsFor(key)
      return expanded(items), entry
    end

    mod.exports.expand = expanded
    installed = true
    mod.log:info("Expanded Pokemarts installed")
  end

  mod.events:on("game.ready", install, -50)
end
