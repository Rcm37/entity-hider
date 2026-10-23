-- Run from entity-hider: lua tests/storage_scope_test.lua
local saved, callbacks = {}, {}
local permission, available, trackingID = false, true, "9223372036854775807"
local trackingCalls, writes = 0, 0
local failWrites = false
PluginPermissions = { trackingAccess = {} }
Plugin = { HasPermission = function(name)
    assert(name == PluginPermissions.trackingAccess, "permission enum value required")
    return permission
end }
Player = {
    IsAvailable = function() return available end,
    GetTrackingID = function()
        assert(permission, "tracking called without permission")
        trackingCalls = trackingCalls + 1
        return trackingID
    end,
}
Event = { Logic = {
    Subscribe = function(key, callback) callbacks[key] = callback end,
    Unsubscribe = function(key) callbacks[key] = nil end,
} }
local function write(_, key, value)
    if failWrites then error("database failure") end
    writes = writes + 1
    saved[key] = value
end
PersistentDB = {
    GetBool = function(_, key) return saved[key] end,
    GetString = function(_, key) return saved[key] end,
    SetBool = write, SetString = write,
}
local Settings = require("settings")
local checks = 0
local function expect(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    checks = checks + 1
end
local function rejects(callback, message)
    local ok, err = pcall(callback)
    expect(ok, false, "rejected change")
    expect(tostring(err):find(message, 1, true) ~= nil, true, "actionable error")
end
local function tick()
    for _, callback in pairs(callbacks) do callback() end
end

Settings.Start()
Settings.update("customNPCs", "Global NPC")
Settings.update("allNPCs", true)
tick()
expect(trackingCalls, 0, "global mode never requests tracking ID")
expect(saved.entity_hider_customNPCs, "Global NPC", "existing global prefix retained")
rejects(function() Settings.update("playerSpecific", true) end, "trackingAccess")
expect(Settings.get("playerSpecific"), false, "permission denial retains global mode")
permission = true
trackingID = nil
rejects(function() Settings.update("playerSpecific", true) end, "tracking ID unavailable")
expect(Settings.GetStorageScope(), "entity_hider_", "missing ID retains global scope")
trackingID = "9223372036854775807"
failWrites = true
rejects(function() Settings.update("playerSpecific", true) end, "database failure")
expect(Settings.get("playerSpecific"), false, "failed initialization retains global preference")
expect(Settings.GetStorageScope(), "entity_hider_", "failed initialization retains global scope")
failWrites = false
Settings.update("playerSpecific", true)
expect(Settings.get("allNPCs"), false, "new character starts with default toggles")
expect(Settings.get("customNPCs"), "", "new character starts with empty lists")
expect(Settings.GetStorageScope(), "entity_hider_player_9223372036854775807_", "64-bit ID preserved exactly")
Settings.update("enabled", false)
Settings.update("rightClickRequireCtrlShift", true)
for index = 1, 5 do
    Settings.update("activePreset", tostring(index))
    Settings.update("presetName", "Character A " .. index)
    Settings.update("customNPCs", "A NPC " .. index)
    Settings.update("customRSNs", "A Player " .. index)
    Settings.update("customFamiliars", "A Pet " .. index)
end
expect(saved.entity_hider_customNPCs, "Global NPC", "character writes preserve global lists")
expect(saved.entity_hider_allNPCs, true, "character writes preserve global toggles")
trackingID = "character-b"
tick()
expect(Settings.get("enabled"), true, "character B has independent enabled setting")
expect(Settings.get("activePreset"), "1", "character B has independent preset selection")
expect(Settings.get("customNPCs"), "", "character B does not inherit character A list")
Settings.update("customNPCs", "B NPC")
trackingID = "9223372036854775807"
tick()
expect(Settings.get("enabled"), false, "returning restores character A enabled setting")
expect(Settings.get("rightClickRequireCtrlShift"), true, "character preference restored")
expect(Settings.get("activePreset"), "5", "character A selection restored")
for index = 1, 5 do
    Settings.update("activePreset", tostring(index))
    expect(Settings.get("presetName"), "Character A " .. index, "character preset name retained")
    expect(Settings.get("customNPCs"), "A NPC " .. index, "character NPC list retained")
    expect(Settings.get("customRSNs"), "A Player " .. index, "character player list retained")
    expect(Settings.get("customFamiliars"), "A Pet " .. index, "character familiar list retained")
end
available = false
local callsBeforeLogout = trackingCalls
tick()
expect(trackingCalls, callsBeforeLogout, "logout does not request stale tracking ID")
expect(Settings.IsStorageReady(), false, "logout makes character storage unavailable")
expect(Settings.get("customNPCs"), "", "logout does not show previous character list")
local writesBeforeUnavailable = writes
rejects(function() Settings.update("customNPCs", "Wrong character") end, "Character settings unavailable")
expect(writes, writesBeforeUnavailable, "unavailable character writes never fall back to global")
available, trackingID = true, nil
tick()
expect(Settings.IsStorageReady(), false, "delayed tracking ID remains unavailable")
trackingID = "character-b"
tick()
expect(Settings.get("customNPCs"), "B NPC", "delayed ID restores correct character")
permission = false
local callsBeforeRevoke = trackingCalls
tick()
expect(trackingCalls, callsBeforeRevoke, "revoked permission prevents tracking calls")
expect(Settings.IsStorageReady(), false, "revocation suspends character storage")
expect(Settings.get("playerSpecific"), true, "revocation preserves preferred storage mode")
Settings.Shutdown()
Settings = dofile("settings.lua")
Settings.Start()
expect(Settings.IsStorageReady(), false, "startup without saved permission is safe")
expect(Settings.get("customNPCs"), "", "startup does not expose global lists in character mode")
permission = true
tick()
expect(Settings.get("customNPCs"), "B NPC", "restored permission restores saved character")
failWrites = true
rejects(function() Settings.update("playerSpecific", false) end, "database failure")
expect(Settings.get("playerSpecific"), true, "failed selector write preserves mode")
expect(Settings.get("customNPCs"), "B NPC", "failed selector write preserves scope")
failWrites, permission = false, false
Settings.update("playerSpecific", false)
expect(Settings.get("customNPCs"), "Global NPC", "global settings restored without tracking permission")
expect(Settings.get("allNPCs"), true, "global toggles restored")
expect(saved.entity_hider_playerSpecific, false, "mode selector stored globally")
Settings.Shutdown()
expect(next(callbacks), nil, "storage polling stops on shutdown")
print("Storage scopes: " .. checks .. " checks passed")
