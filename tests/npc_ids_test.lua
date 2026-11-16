-- Run from entity-hider: lua tests/npc_ids_test.lua
local IDs = require("npc_ids")
local list = "00123, , nope, -1, 12.3, 1234, 123, 0, 999999999999999999"
assert(IDs.Contains(list, 123) and IDs.Contains(list, 1234) and IDs.Contains(list, 0))
assert(not IDs.Contains(list, 12), "ID matching is exact")
assert(not IDs.Contains(list, -1) and not IDs.Contains(list, 12.3))
assert(not IDs.Contains("456", 123), "editing list invalidates parsed ID cache")
config = { NPC = { FromID = function(value)
    if value == 123 then return { configName = "NAMELESS_EFFECT", name = "" } end
    if value == 1234 then return { configName = "PET_OVERRIDE", name = "Pet" } end
    error("config unavailable")
end } }
local entries = IDs.GetEntries(list)
assert(#entries == 3, "valid IDs are deduplicated and retain input order")
assert(entries[1].id == 123 and entries[1].label == "123 - NAMELESS_EFFECT")
assert(entries[2].label == "1234 - PET_OVERRIDE (Pet)")
assert(entries[3].label == "0 - Unknown / unavailable config", "unavailable lookup keeps saved ID visible")
assert(IDs.Describe(456, { name = "Display name only" }) == "456 - Display name only")
print("NPC IDs: parsing, exact matching, and config labels passed")
