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
expect(Settings.get("activePreset"), "1", "existing lists start in preset 1")
expect(#Settings.GetPresetEntries(), 5, "exactly five presets")
Settings.update("customRSNs", "Original Player")
Settings.update("customFamiliars", "Original Pet")
Settings.update("presetName", "Bossing")
for index = 2, 5 do
    Settings.update("activePreset", tostring(index))
    expect(Settings.get("customNPCs"), "", "new preset has empty NPC list")
    expect(Settings.get("customRSNs"), "", "new preset has empty player list")
    expect(Settings.get("customFamiliars"), "", "new preset has empty familiar list")
    expect(Settings.get("presetName"), "Preset " .. index, "default preset name")
    Settings.update("customNPCs", "NPC " .. index)
    Settings.update("customRSNs", "Player " .. index)
    Settings.update("customFamiliars", "Pet " .. index)
    Settings.update("presetName", "Activity " .. index)
end
for index = 2, 5 do
    Settings.update("activePreset", tostring(index))
    expect(Settings.get("customNPCs"), "NPC " .. index, "independent NPC lists")
    expect(Settings.get("customRSNs"), "Player " .. index, "independent player lists")
    expect(Settings.get("customFamiliars"), "Pet " .. index, "independent familiar lists")
    expect(Settings.GetPresetEntries()[index].label, "Activity " .. index, "saved names in dropdown")
end
local persisted = dofile("settings.lua")
expect(persisted.get("activePreset"), "5", "active preset survives reload")
expect(persisted.get("customNPCs"), "NPC 5", "active list survives reload")
expect(persisted.get("presetName"), "Activity 5", "preset name survives reload")
persisted.update("activePreset", "1")
expect(persisted.get("customNPCs"), "Ghost", "legacy NPC list preserved")
expect(persisted.get("customRSNs"), "Original Player", "legacy player list preserved")
expect(persisted.get("customFamiliars"), "Original Pet", "legacy familiar list preserved")
expect(persisted.get("presetName"), "Bossing", "first preset name preserved")
expect(persisted.get("enabled"), false, "toggles remain global")
local switchedNotifications = {}
Settings.Subscribe("presets", function(name, value)
    switchedNotifications[name] = value
    expect(Settings.get("customNPCs"), "Ghost", "switch notifications see complete target preset")
end)
Settings.update("activePreset", "1")
expect(switchedNotifications.customNPCs, "Ghost", "NPC filters notified on switch")
expect(switchedNotifications.customRSNs, "Original Player", "player filters notified on switch")
expect(switchedNotifications.customFamiliars, "Original Pet", "familiar filters notified on switch")
expect(switchedNotifications.activePreset, "1", "selection notified on switch")
Settings.Unsubscribe("presets")
for _, invalid in ipairs({ "0", "6", "1.5", "invalid" }) do
    rejects(function() Settings.update("activePreset", invalid) end, "between 1 and 5")
end
failWrites = true
rejects(function() Settings.update("activePreset", "2") end, "simulated database failure")
expect(Settings.get("activePreset"), "1", "failed switch retains selection")
expect(Settings.get("customNPCs"), "Ghost", "failed switch retains active list")
failWrites = false
Settings.update("presetName", "   ")
expect(Settings.get("presetName"), "Preset 1", "blank name falls back to slot name")
saved.entity_hider_activePreset = "99"
expect(dofile("settings.lua").get("activePreset"), "1", "invalid saved selection recovers")
print("Settings: " .. checks .. " checks passed")
