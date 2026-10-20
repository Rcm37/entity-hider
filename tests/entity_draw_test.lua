-- Run from entity-hider: lua tests/entity_draw_test.lua
local settings = { enabled = true }
local draw
local onSettingChanged
package.loaded.settings = {
    get = function(key) return settings[key] end,
    Subscribe = function(_, callback) onSettingChanged = callback end,
    Unsubscribe = function() end,
}
EntityType = { PLAYER = 1, NPC = 2 }
Event = { EntityDraw = {
    Subscribe = function(_, callback) draw = callback end,
    Unsubscribe = function() end,
} }
id = { NPC = setmetatable({}, { __index = function(_, key) return key end }) }
local self = { displayName = "Local Player" }
PlayerList = { Self = function() return self end }

local checks = 0

local function update(key, value)
    settings[key] = value
    onSettingChanged(key, value)
end

local function reset(overrides)
    settings = {
        enabled = true, conjures = false, allNPCs = false,
        allFamiliars = false, drakePets = false, localPlayer = false,
        otherPlayers = false, customRSNs = "", customNPCs = "", customFamiliars = "",
    }
    for key, value in pairs(overrides or {}) do settings[key] = value end
    if onSettingChanged then
        for key, value in pairs(settings) do onSettingChanged(key, value) end
    end
end

reset()
local EntityHider = require("entity_hider")
EntityHider.Start()
local currentDraw = draw

local function npc(name, familiar, configID)
    return { entityType = EntityType.NPC, npcEntity = {
        displayName = name,
        config = { id = configID or "ordinary", isFamiliar = familiar },
    } }
end

local function player(name, valid)
    return { entityType = EntityType.PLAYER,
        playerEntity = { displayName = name, isValid = valid ~= false } }
end

local function expect(event, overrides, expected, label)
    reset(overrides)
    local actual = currentDraw(event)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    checks = checks + 1
end

local ordinary = npc("Guard", false)
local familiar = npc("Yak", true)
local spider = npc("Spider pet", true)
local drake = npc("Drake", true, id.NPC.MTX_PET_DRAKE)
local conjure = npc("Ghost", false, id.NPC.COMBATV2_NECROMANCY_SPIRIT_VENGEFUL_GHOST)

-- Inactive filters should return before reading any entity data, even when the
-- other entity type has active filters.
local function untouchedEntityEvent(entityType)
    return setmetatable({ entityType = entityType }, {
        __index = function(_, key) error("unexpected entity access: " .. key) end,
    })
end
expect(untouchedEntityEvent(EntityType.NPC), {}, true, "inactive NPC filters skip entity access")
expect(untouchedEntityEvent(EntityType.NPC),
    { localPlayer = true, otherPlayers = true, customRSNs = "Other Player" },
    true, "player filters do not prevent NPC early return")
expect(untouchedEntityEvent(EntityType.PLAYER), {}, true, "inactive player filters skip entity access")
expect(untouchedEntityEvent(EntityType.PLAYER),
    { allNPCs = true, conjures = true, allFamiliars = true, drakePets = true,
        customNPCs = "Guard", customFamiliars = "Yak" },
    true, "NPC filters do not prevent player early return")

-- Every relevant setting must activate filtering and restore the early return
-- when the final filter is removed.
for _, case in ipairs({
    { "allNPCs", true, ordinary },
    { "conjures", true, conjure },
    { "allFamiliars", true, familiar },
    { "drakePets", true, drake },
    { "customNPCs", "Guard", ordinary },
    { "customFamiliars", "Yak", familiar },
    { "localPlayer", true, player("Local Player") },
    { "otherPlayers", true, player("Other Player") },
    { "customRSNs", "Other Player", player("Other Player") },
}) do
    reset()
    local key, value, event = case[1], case[2], case[3]
    update(key, value)
    assert(currentDraw(event) == false, key .. " activates filtering")
    local inactive = ""
    if type(value) == "boolean" then inactive = false end
    update(key, inactive)
    assert(currentDraw(untouchedEntityEvent(event.entityType)) == true,
        key .. " removal restores early return")
    checks = checks + 2
end

-- Startup must read saved filters even without a setting-change notification.
EntityHider.Shutdown()
settings.customNPCs = "Guard"
settings.customRSNs = "Other Player"
EntityHider.Start()
assert(currentDraw(ordinary) == false, "startup reads saved NPC filters")
assert(currentDraw(player("Other Player")) == false, "startup reads saved player filters")
checks = checks + 2

expect(ordinary, {}, true, "default drawing")
expect(npc("", false, id.NPC.EGWD_JAS_BOSS_LIGHTNING_STRIKE), {}, true, "unnamed Kerapac effect remains visible by default")
expect(npc("", false, id.NPC.EGWD_JAS_BOSS_LIGHTNING_STRIKE),
    { customNPCs = "Guard, ," }, true, "empty custom entries do not hide unnamed Kerapac effects")
expect(npc("  ", false), {}, true, "blank NPC name remains visible by default")
expect(npc("", true), {}, true, "unnamed familiar remains visible by default")
expect(ordinary, { enabled = false, allNPCs = true }, true, "disabled plugin")
expect(ordinary, { allNPCs = true }, false, "general NPC toggle")
expect(familiar, { allNPCs = true }, true, "general toggle excludes familiars")
expect(npc("Fishing spot", false), { allNPCs = true }, true, "general toggle excludes fishing spots")
expect(npc("Fishing Spot", false), { allNPCs = true }, true, "fishing spot detection ignores case")
expect(npc("Deep sea fishing spot", false), { allNPCs = true }, true, "named fishing spot variant")
expect(npc("Fishing tutor", false), { allNPCs = true }, false, "fishing NPCs remain subject to general toggle")
expect(npc("Fishing spot", false), { allNPCs = true, customNPCs = "Fishing spot" }, false, "custom list can still hide fishing spots")
expect(familiar, { allFamiliars = true }, false, "familiar toggle")
for _, configName in ipairs({
    "MENAPHOS_MAGIC_CARPET_IMPERIAL", "MENAPHOS_MAGIC_CARPET_IMPERIAL_POH",
    "MENAPHOS_MAGIC_CARPET_MERCHANT", "MENAPHOS_MAGIC_CARPET_MERCHANT_POH",
    "MENAPHOS_MAGIC_CARPET_SLAVE", "MENAPHOS_MAGIC_CARPET_SLAVE_POH",
    "MENAPHOS_MAGIC_CARPET_PORT", "MENAPHOS_MAGIC_CARPET_PORT_POH",
    "MENAPHOS_GOLDEN_PATH_MAGIC_CARPET_BASIC", "MENAPHOS_GOLDEN_PATH_MAGIC_CARPET_BASIC_POH",
    "MENAPHOS_GOLDEN_PATH_MAGIC_CARPET_GOLD", "MENAPHOS_GOLDEN_PATH_MAGIC_CARPET_GOLD_POH",
}) do
    local carpet = npc("Magic carpet", false, id.NPC[configName])
    expect(carpet, {}, true, configName .. " visible by default")
    expect(carpet, { allNPCs = true }, true, configName .. " excluded from NPC toggle")
    expect(carpet, { allFamiliars = true }, false, configName .. " uses familiar toggle")
    expect(carpet, { customNPCs = "Magic carpet" }, true, configName .. " ignores NPC list")
    expect(carpet, { customFamiliars = "Magic carpet" }, false, configName .. " uses familiar list")
end
local carpetSeller = npc("Carpet merchant", false, id.NPC.MAGIC_CARPET_SELLER1)
expect(carpetSeller, { allNPCs = true }, false, "carpet seller remains an ordinary NPC")
expect(carpetSeller, { allFamiliars = true }, true, "carpet seller is not a familiar")
expect(drake, { drakePets = true }, false, "drake toggle")
expect(ordinary, { drakePets = true }, true, "drake toggle excludes other NPCs")
expect(conjure, { conjures = true }, false, "conjure toggle")
expect(conjure, { allNPCs = true }, true, "general NPC toggle excludes conjures")
expect(conjure, { allNPCs = true, conjures = true }, false, "separate conjure toggle still hides conjures")
expect(conjure, { allNPCs = true, customNPCs = "Ghost" }, false, "conjures still respect custom NPC filtering")
expect(ordinary, { conjures = true }, true, "conjure toggle excludes other NPCs")
expect(ordinary, { conjures = true, allNPCs = true }, false, "conjure toggle permits general NPC filtering")
expect(ordinary, { conjures = true, customNPCs = "Guard" }, false, "conjure toggle permits custom NPC filtering")
expect(familiar, { conjures = true, allFamiliars = true }, false, "conjure toggle permits familiar filtering")
expect(drake, { conjures = true, drakePets = true }, false, "conjure toggle permits drake filtering")
expect(spider, { spiders = true }, true, "obsolete spider setting no longer hides models")
expect(spider, {}, true, "spiders remain visible by default")
expect(spider, { allFamiliars = true }, false, "spider permits familiar filtering")
expect(spider, { customFamiliars = "Spider pet" }, false, "spider permits custom familiar filtering")
expect(npc("Spider", false), { customNPCs = "Spider" }, false, "spider permits custom NPC filtering")
expect(npc("Spider drake", true, id.NPC.MTX_PET_DRAKE), { drakePets = true }, false, "spider permits drake filtering")
expect(npc("Spider", false), { allNPCs = true }, false, "general NPC toggle hides spiders")
expect(ordinary, { customNPCs = "Other, GUARD, Another" }, false, "custom NPC list")
expect(ordinary, { customNPCs = "Guardsman" }, true, "custom list uses whole names")
expect(familiar, { customNPCs = "Yak" }, true, "NPC list excludes familiars")
expect(familiar, { customFamiliars = "YAK" }, false, "custom familiar list")
expect(player("Local Player"), { otherPlayers = true, customRSNs = "Local Player" }, true, "local player takes precedence")
expect(player("Local Player"), { localPlayer = true }, false, "hide local player")
expect(player("Other Player"), { otherPlayers = true }, false, "hide other players")
expect(player("Other\194\160Player"), { customRSNs = "other player" }, false, "normalize player names")
expect(player("Other Player", false), { customRSNs = "Other Player" }, true, "invalid player skips custom list")
expect(nil, {}, true, "missing event")
expect({ entityType = 99 }, {}, true, "unhandled entity type")
expect({ entityType = EntityType.PLAYER }, {}, true, "missing player")
expect({ entityType = EntityType.NPC }, {}, true, "missing NPC")
expect({ entityType = EntityType.NPC, npcEntity = {} }, {}, true, "missing NPC config")
expect(npc("Unknown", nil), {}, true, "missing familiar flag")
self = nil
expect(player("Other Player"), {}, true, "unavailable local player")
self = { displayName = "Local Player" }

-- Enabling another hide filter must never reveal an already hidden NPC.
do
    local toggles = { "conjures", "allNPCs", "allFamiliars", "drakePets" }
    local entities = { ordinary, familiar, spider, drake, conjure,
        npc("Spider", false), npc("Spider drake", true, id.NPC.MTX_PET_DRAKE) }
    for mask = 0, 2 ^ #toggles - 1 do
        for _, customLists in ipairs({ false, true }) do
            reset(customLists and {
                customNPCs = "Guard,Spider,Ghost", customFamiliars = "Yak,Spider pet,Drake",
                customRSNs = "Local Player,Other Player",
            } or {})
            for bit, key in ipairs(toggles) do
                update(key, math.floor(mask / 2 ^ (bit - 1)) % 2 == 1)
            end
            for index, event in ipairs(entities) do
                local wasVisible = currentDraw(event)
                for _, key in ipairs(toggles) do
                    local previous = settings[key]
                    update(key, true)
                    assert(wasVisible or currentDraw(event) == false,
                        key .. " revealed entity " .. index .. " for mask " .. mask)
                    update(key, previous)
                    checks = checks + 1
                end
            end
        end
    end
end

print("EntityDraw: " .. checks .. " checks passed")
