-- Run from entity-hider: lua tests/names_test.lua
local Names = require("names")
local checks = 0
local function expect(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    checks = checks + 1
end

expect(Names.Contains(" Guard, YAK ", "guard", false, "customNPCs"), true, "trim and ignore case")
expect(Names.Contains("Guard", "Guardsman", false, "customNPCs"), false, "whole names only")
expect(Names.Contains("Other\194\160Player", "Other Player", true, "customRSNs"), true, "normalize player spaces")
expect(Names.Contains("Other\194\160Player", "Other Player", false, "customNPCs"), false, "keep NPC spaces literal")
expect(Names.Contains("Yak", "Yak", false, "customFamiliars"), true, "separate familiar list")
expect(Names.Contains("Guard", "Yak", false, "customNPCs"), false, "lists do not share names")

-- Count normalization calls to verify unchanged lists are not parsed again.
local originalKey, calls = Names.Key, 0
Names.Key = function(...)
    calls = calls + 1
    return originalKey(...)
end
Names.Contains("Guard,Yak", "Guard", false, "customNPCs")
expect(calls, 3, "parse two entries and normalize query")
calls = 0
Names.Contains("Guard,Yak", "Yak", false, "customNPCs")
expect(calls, 1, "reuse parsed list")
Names.Contains("Drake", "Drake", false, "customFamiliars")
calls = 0
Names.Contains("Guard,Yak", "Guard", false, "customNPCs")
expect(calls, 1, "alternating lists retain their caches")
Names.Key = originalKey

expect(Names.Contains("Ghost", "Guard", false, "customNPCs"), false, "edit removes old cached name")
expect(Names.Contains("Ghost", "Ghost", false, "customNPCs"), true, "edit adds new cached name")
expect(Names.Contains("", "Ghost", false, "customNPCs"), false, "clearing list invalidates cache")
expect(Names.Contains("Other\194\160Player", "Other Player", true, "shared"), true, "player normalization mode")
expect(Names.Contains("Other\194\160Player", "Other Player", false, "shared"), false, "mode change invalidates cache")
expect(Names.RemoveLast("Guard, Yak, GUARD", "guard", false), "Guard, Yak", "remove only last matching entry")
expect(Names.RemoveLast("Guard, Yak", "Missing", false), "Guard, Yak", "missing entry leaves list intact")
print("Names: " .. checks .. " checks passed")
