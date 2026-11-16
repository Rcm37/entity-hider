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
GameKey = { CONTROL = 82, SHIFT = 81, ALT = 86, K = 55 }
function GameKey.FromID(key)
    for name, value in pairs(GameKey) do if value == key then return name end end
end
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
expect(Settings.get("presetIncludeToggles"), false, "preset toggles default off")
local hideToggles = { "localPlayer", "otherPlayers", "allNPCs", "conjures", "allFamiliars", "drakePets", "spiders" }
for _, name in ipairs(hideToggles) do Settings.update(name, true) end
Settings.update("presetIncludeToggles", true)
for _, name in ipairs(hideToggles) do
    expect(Settings.get(name), true, "enabling preserves " .. name)
end
Settings.update("activePreset", "2")
for _, name in ipairs(hideToggles) do
    expect(Settings.get(name), true, "new preset inherits shared " .. name)
    Settings.update(name, false)
end
Settings.update("enabled", true)
Settings.update("rightClickRequireCtrlShift", true)
local seen = {}
Settings.Subscribe("toggle-presets", function(name, value)
    seen[name] = value
    for _, toggle in ipairs(hideToggles) do
        expect(Settings.get(toggle), true, "listeners see complete target toggles")
    end
end)
Settings.update("activePreset", "1")
Settings.Unsubscribe("toggle-presets")
for _, name in ipairs(hideToggles) do expect(seen[name], true, "switch notifies " .. name) end
expect(seen.enabled, nil, "preset does not notify plugin enable")
expect(seen.rightClickRequireCtrlShift, nil, "preset does not notify modifier preference")
expect(Settings.get("enabled"), true, "plugin enable stays shared")
expect(Settings.get("rightClickRequireCtrlShift"), true, "modifier preference stays shared")
local toggleReload = dofile("settings.lua")
expect(toggleReload.get("presetIncludeToggles"), true, "option survives reload")
toggleReload.update("activePreset", "2")
for _, name in ipairs(hideToggles) do expect(toggleReload.get(name), false, "saved toggle survives reload") end
Settings.update("activePreset", "2")
Settings.update("presetIncludeToggles", false)
for _, name in ipairs(hideToggles) do expect(Settings.get(name), false, "disabling preserves current toggles") end
Settings.update("activePreset", "1")
for _, name in ipairs(hideToggles) do expect(Settings.get(name), false, "disabled option shares toggles") end
Settings.update("activePreset", "2")
Settings.update("presetIncludeToggles", true)
Settings.update("activePreset", "1")
for _, name in ipairs(hideToggles) do expect(Settings.get(name), true, "other preset toggle set retained") end
failWrites = true
rejects(function() Settings.update("presetIncludeToggles", false) end, "simulated database failure")
expect(Settings.get("presetIncludeToggles"), true, "failed mode change retains option")
rejects(function() Settings.update("activePreset", "2") end, "simulated database failure")
expect(Settings.get("activePreset"), "1", "failed switch retains selected toggle set")
expect(Settings.get("spiders"), true, "failed switch retains toggle value")
failWrites = false
expect(Settings.GetRightClickKeybind()[1], GameKey.CONTROL, "existing preference defaults to Ctrl")
expect(Settings.GetRightClickKeybind()[2], GameKey.SHIFT, "existing preference defaults to Shift")
Settings.SetRightClickKeybind({ GameKey.CONTROL, GameKey.ALT })
expect(Settings.get("rightClickKeybind"), "CONTROL,ALT", "binding saved by enum name")
expect(dofile("settings.lua").GetRightClickKeybind()[2], GameKey.ALT, "custom chord survives reload")
Settings.update("activePreset", "2")
expect(Settings.GetRightClickKeybind()[2], GameKey.ALT, "binding remains shared across presets")
Settings.update("activePreset", "1")
Settings.SetRightClickKeybind({ GameKey.K })
expect(#Settings.GetRightClickKeybind(), 1, "single-key binding supported")
Settings.SetRightClickKeybind({})
expect(#Settings.GetRightClickKeybind(), 0, "unbound value supported")
for _, invalid in ipairs({ "UNKNOWN", "CONTROL,CONTROL", "CONTROL,ALT,SHIFT", "CONTROL,", ",SHIFT" }) do
    Settings.update("rightClickKeybind", invalid)
    expect(Settings.GetRightClickKeybind()[2], GameKey.SHIFT, "invalid stored binding falls back to default")
end
rejects(function() Settings.SetRightClickKeybind({ GameKey.CONTROL, GameKey.CONTROL }) end, "repeat")
rejects(function() Settings.SetRightClickKeybind({ GameKey.CONTROL, GameKey.SHIFT, GameKey.ALT }) end, "two keys")
rejects(function() Settings.SetRightClickKeybind({ -1 }) end, "GameKey")
Settings.SetRightClickKeybind({ GameKey.SHIFT, GameKey.ALT })
failWrites = true
rejects(function() Settings.SetRightClickKeybind({ GameKey.K }) end, "simulated database failure")
expect(Settings.GetRightClickKeybind()[2], GameKey.ALT, "failed write preserves prior binding")
failWrites = false
Settings.update("customNPCIDs", "1234")
Settings.update("activePreset", "2")
expect(Settings.get("customNPCIDs"), "", "new preset has no hidden IDs")
Settings.update("customNPCIDs", "5678")
expect(dofile("settings.lua").get("customNPCIDs"), "5678", "hidden IDs survive reload")
Settings.update("activePreset", "1")
expect(Settings.get("customNPCIDs"), "1234", "hidden IDs are independent between presets")
saved.entity_hider_activePreset = "99"
expect(dofile("settings.lua").get("activePreset"), "1", "invalid saved selection recovers")
print("Settings: " .. checks .. " checks passed")
