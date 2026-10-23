-- Run from entity-hider: lua tests/settings_test.lua
local saved, writes = {}, 0
local failWrites = false
local function write(_, key, value)
    if failWrites then error("simulated database failure") end
    writes = writes + 1
    saved[key] = value
end
PersistentDB = {
    GetBool = function(_, key) return saved[key] end,
    GetString = function(_, key) return saved[key] end,
    SetBool = write,
    SetString = write,
}
local Settings = require("settings")
local checks = 0
local function expect(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    checks = checks + 1
end
local function rejects(callback, message)
    local ok, err = pcall(callback)
    expect(ok, false, "reject invalid setting or failed write")
    expect(tostring(err):find(message, 1, true) ~= nil, true, "useful failure message")
end

expect(Settings.get("enabled"), true, "default boolean")
Settings.update("enabled", false)
expect(Settings.get("enabled"), false, "cache false values")
expect(saved.entity_hider_enabled, false, "persist boolean")
Settings.update("customNPCs", "Guard")
expect(Settings.get("customNPCs"), "Guard", "cache string")
expect(saved.entity_hider_customNPCs, "Guard", "persist string")
local previousWrites = writes
rejects(function() Settings.update("enabled", "false") end, "expects boolean")
rejects(function() Settings.update("customNPCs", false) end, "expects string")
rejects(function() Settings.update("customNPCs", nil) end, "expects string")
rejects(function() Settings.update("unknown", true) end, "Unknown setting")
expect(writes, previousWrites, "validation happens before database writes")
expect(Settings.get("enabled"), false, "invalid boolean leaves cache intact")
expect(Settings.get("customNPCs"), "Guard", "invalid string leaves cache intact")

failWrites = true
rejects(function() Settings.update("enabled", true) end, "simulated database failure")
rejects(function() Settings.update("customNPCs", "Ghost") end, "simulated database failure")
expect(Settings.get("enabled"), false, "failed boolean write leaves cache intact")
expect(Settings.get("customNPCs"), "Guard", "failed string write leaves cache intact")
expect(saved.entity_hider_enabled, false, "failed write leaves saved boolean intact")
expect(saved.entity_hider_customNPCs, "Guard", "failed write leaves saved string intact")
rejects(function() Settings.get("customFamiliars") end, "simulated database failure")
failWrites = false
expect(Settings.get("customFamiliars"), "", "failed default write is retried")
expect(saved.entity_hider_customFamiliars, "", "default persisted after retry")
Settings.update("customNPCs", "Ghost")
expect(Settings.get("customNPCs"), "Ghost", "successful retry updates cache")
local reloaded = dofile("settings.lua")
expect(reloaded.get("customNPCs"), "Ghost", "fresh module reads persisted string")
expect(reloaded.get("enabled"), false, "fresh module reads persisted false")
local notifications = 0
Settings.Subscribe("test", function(name, value)
    notifications = notifications + 1
    expect(name, "enabled", "notification identifies setting")
    expect(value, Settings.get(name), "notification sees updated cache")
    expect(saved.entity_hider_enabled, value, "notification follows database write")
end)
Settings.update("enabled", true)
expect(notifications, 1, "successful update notifies")
failWrites = true
expect(pcall(Settings.update, "enabled", false), false, "failed update rejected with listener attached")
expect(notifications, 1, "failed write does not notify")
failWrites = false
Settings.Unsubscribe("test")
Settings.update("enabled", false)
expect(notifications, 1, "unsubscribed listener not called")
print("Settings: " .. checks .. " checks passed")
