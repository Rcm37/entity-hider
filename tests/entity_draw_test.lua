-- Run from entity-hider: lua tests/entity_draw_test.lua
local settings = {}
local draw
package.loaded.settings = { get = function(key) return settings[key] end }
package.loaded["interface/settings"] = {}
package.loaded["interface/content"] = {}
EntityType = { PLAYER = 1, NPC = 2 }
Event = { EntityDraw = { Subscribe = function(_, callback) draw = callback end } }
id = { NPC = setmetatable({}, { __index = function(_, key) return key end }) }
local self = { displayName = "Local Player" }
PlayerList = { Self = function() return self end }

dofile("main.lua")
local currentDraw = draw
local checks = 0

local function reset(overrides)
    settings = {
        enabled = true, conjures = false, allNPCs = false, spiders = false,
        allFamiliars = false, drakePets = false, localPlayer = false,
        otherPlayers = false, customRSNs = "", customNPCs = "", customFamiliars = "",
    }
    for key, value in pairs(overrides or {}) do settings[key] = value end
end

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

expect(ordinary, {}, true, "default drawing")
expect(ordinary, { enabled = false, allNPCs = true }, true, "disabled plugin")
expect(ordinary, { allNPCs = true }, false, "general NPC toggle")
expect(familiar, { allNPCs = true }, true, "general toggle excludes familiars")
expect(familiar, { allFamiliars = true }, false, "familiar toggle")
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
expect(spider, { conjures = true, spiders = true }, false, "conjure toggle permits spider filtering")
expect(spider, { spiders = true }, false, "spider toggle")
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
    local toggles = { "conjures", "allNPCs", "spiders", "allFamiliars", "drakePets" }
    local entities = { ordinary, familiar, spider, drake, conjure,
        npc("Spider", false), npc("Spider drake", true, id.NPC.MTX_PET_DRAKE) }
    for mask = 0, 2 ^ #toggles - 1 do
        for _, customLists in ipairs({ false, true }) do
            reset(customLists and {
                customNPCs = "Guard,Spider,Ghost", customFamiliars = "Yak,Spider pet,Drake",
                customRSNs = "Local Player,Other Player",
            } or {})
            for bit, key in ipairs(toggles) do
                settings[key] = math.floor(mask / 2 ^ (bit - 1)) % 2 == 1
            end
            for index, event in ipairs(entities) do
                local wasVisible = currentDraw(event)
                for _, key in ipairs(toggles) do
                    local previous = settings[key]
                    settings[key] = true
                    assert(wasVisible or currentDraw(event) == false,
                        key .. " revealed entity " .. index .. " for mask " .. mask)
                    settings[key] = previous
                    checks = checks + 1
                end
            end
        end
    end
end

print("EntityDraw: " .. checks .. " checks passed")
