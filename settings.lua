local Settings = {}
local listeners = {}

function Settings.Subscribe(key, callback)
    listeners[key] = callback
end

function Settings.Unsubscribe(key)
    listeners[key] = nil
end

local PLUGIN_DB_PREFIX = "entity_hider_"

local CachedSettings = {}
local storagePrefix = PLUGIN_DB_PREFIX
local EVENT_ID = "entity-hider-settings-storage"
local presetFields = { "customRSNs", "customNPCs", "customFamiliars", "customNPCIDs" }
local presetSettings = { customRSNs = true, customNPCs = true, customFamiliars = true, customNPCIDs = true, presetName = true }
local toggleFields = { "localPlayer", "otherPlayers", "allNPCs", "conjures",
    "allFamiliars", "drakePets", "spiders" }
local toggleSettings = {}
for _, name in ipairs(toggleFields) do toggleSettings[name] = true end
Settings.PRESET_COUNT = 5

-- Settings and their default values/types
local ValidSettings = {
    playerSpecific = { default = false, type = "boolean" },
    presetIncludeToggles = { default = false, type = "boolean" },
    activePreset = { default = "1", type = "string" },
    presetName = { default = "Preset 1", type = "string" },
    enabled = {
        default = true,
        type = "boolean"
    },
    conjures = {
        default = false,
        type = "boolean"
    },
    drakePets = {
        default = false,
        type = "boolean"
    },
    allFamiliars = {
        default = false,
        type = "boolean"
    },
    allNPCs = {
        default = false,
        type = "boolean"
    },
    localPlayer = {
        default = false,
        type = "boolean"
    },
    otherPlayers = {
        default = false,
        type = "boolean"
    },
    spiders = {
        default = false,
        type = "boolean"
    },
    -- Retain the existing storage key for the optional shortcut requirement.
    rightClickRequireCtrlShift = {
        default = false,
        type = "boolean"
    },
    rightClickKeybind = { default = "CONTROL,SHIFT", type = "string" },
    customNPCIDs = { default = "", type = "string" },
    customRSNs = {
        default = "",
        type = "string"
    },
    customNPCs = {
        default = "",
        type = "string"
    },
    customFamiliars = {
        default = "",
        type = "string"
    },
}

local function assertValidSetting(settingName)
    if ValidSettings[settingName] == nil then
        error("Unknown setting: " .. tostring(settingName))
    end
end

local function makeKey(settingName, preset, shared)
    if settingName == "playerSpecific" then return PLUGIN_DB_PREFIX .. settingName end
    if storagePrefix == nil then return nil end
    if toggleSettings[settingName] and not shared and Settings.get("presetIncludeToggles") then
        return storagePrefix .. "preset" .. (preset or Settings.get("activePreset")) .. "_" .. settingName
    end
    if presetSettings[settingName] then
        preset = preset or Settings.get("activePreset")
        -- Keep the original lists as preset 1, preserving existing settings.
        if preset ~= "1" or settingName == "presetName" then
            return storagePrefix .. "preset" .. preset .. "_" .. settingName
        end
    end
    return storagePrefix .. settingName
end

local function readSetting(settingName, preset, shared)
    local key = makeKey(settingName, preset, shared)
    if key == nil then
        return settingName == "presetName" and ("Preset " .. (preset or Settings.get("activePreset")))
            or ValidSettings[settingName].default
    end
    if CachedSettings[key] ~= nil then return CachedSettings[key] end
    local setting = ValidSettings[settingName]
    local value
    if setting.type == "boolean" then
        value = PersistentDB:GetBool(key)
    else
        value = PersistentDB:GetString(key)
    end
    if settingName == "activePreset" and value ~= nil and not value:match("^[1-5]$") then
        value = nil
    end
    if value == nil then
        if toggleSettings[settingName] and not shared and Settings.get("presetIncludeToggles") then
            -- New preset toggle sets inherit the existing shared values.
            value = readSetting(settingName, nil, true)
        else
            value = settingName == "presetName" and ("Preset " .. (preset or Settings.get("activePreset")))
                or setting.default
        end
        if setting.type == "boolean" then PersistentDB:SetBool(key, value)
        else PersistentDB:SetString(key, value) end
    end
    CachedSettings[key] = value
    return value
end

local function notify(settingName, value)
    for _, callback in pairs(listeners) do callback(settingName, value) end
end

local function characterPrefix()
    if not Plugin.HasPermission(PluginPermissions.trackingAccess) or not Player.IsAvailable() then return nil end
    local trackingID = Player.GetTrackingID()
    if trackingID == nil then return nil end
    return PLUGIN_DB_PREFIX .. "player_" .. tostring(trackingID) .. "_"
end

function Settings.GetStorageScope()
    return storagePrefix
end

function Settings.IsStorageReady()
    return storagePrefix ~= nil
end

local function readStorage(prefix)
    local previousPrefix = storagePrefix
    storagePrefix = prefix
    local values = {}
    local ok, err = pcall(function()
        for name in pairs(ValidSettings) do
            if name ~= "playerSpecific" then values[name] = readSetting(name) end
        end
    end)
    storagePrefix = previousPrefix
    if not ok then error(err, 0) end
    return values
end

local function switchStorage(prefix, values)
    if storagePrefix == prefix then return end
    -- Load the entire scope before committing it or refreshing filters and UI.
    values = values or readStorage(prefix)
    storagePrefix = prefix
    for name, value in pairs(values) do notify(name, value) end
    notify("storageScope", prefix)
end

function Settings.RefreshStorage()
    local prefix = PLUGIN_DB_PREFIX
    if Settings.get("playerSpecific") then prefix = characterPrefix() end
    switchStorage(prefix)
end

function Settings.Start()
    Settings.RefreshStorage()
    Event.Logic.Subscribe(EVENT_ID, Settings.RefreshStorage)
end

function Settings.Shutdown()
    Event.Logic.Unsubscribe(EVENT_ID)
end

function Settings.GetPresetEntries()
    local entries = {}
    for index = 1, Settings.PRESET_COUNT do
        local name = readSetting("presetName", tostring(index))
        entries[index] = { id = index, label = name, order = index }
    end
    return entries
end

function Settings.update(settingName, value)
    assertValidSetting(settingName)

    local setting = ValidSettings[settingName]

    if type(value) ~= setting.type then
        error("Setting " .. settingName .. " expects " .. setting.type .. ", got " .. type(value))
    end

    if settingName == "playerSpecific" then
        local prefix = PLUGIN_DB_PREFIX
        if value then
            assert(Plugin.HasPermission(PluginPermissions.trackingAccess), "Grant trackingAccess permission to enable player-specific settings")
            prefix = characterPrefix()
            assert(prefix ~= nil, "Player tracking ID unavailable; wait until login completes")
        end
        local values
        if prefix ~= storagePrefix then values = readStorage(prefix) end
        local key = makeKey(settingName)
        PersistentDB:SetBool(key, value)
        CachedSettings[key] = value
        switchStorage(prefix, values)
        notify(settingName, value)
        return
    end
    assert(storagePrefix ~= nil, "Character settings unavailable; grant trackingAccess and wait until login completes")

    local switchedValues
    if settingName == "presetIncludeToggles" then
        if value == Settings.get(settingName) then return end
        -- Keep the current values when enabling or disabling preset toggles.
        -- Other presets retain their saved toggle sets while this option is off.
        for _, name in ipairs(toggleFields) do
            local current = Settings.get(name)
            local targetKey = value
                and (storagePrefix .. "preset" .. Settings.get("activePreset") .. "_" .. name)
                or makeKey(name, nil, true)
            PersistentDB:SetBool(targetKey, current)
            CachedSettings[targetKey] = current
        end
    elseif settingName == "activePreset" then
        if not value:match("^[1-5]$") then error("Preset must be between 1 and 5") end
        if value == Settings.get("activePreset") then return end
        -- Load the complete preset before committing the switch or notifying listeners.
        switchedValues = {}
        for _, name in ipairs(presetFields) do switchedValues[name] = readSetting(name, value) end
        switchedValues.presetName = readSetting("presetName", value)
        if Settings.get("presetIncludeToggles") then
            for _, name in ipairs(toggleFields) do switchedValues[name] = readSetting(name, value) end
        end
    elseif settingName == "presetName" and value:match("^%s*$") then
        value = "Preset " .. Settings.get("activePreset")
    end

    local key = makeKey(settingName)

    if setting.type == "boolean" then
        PersistentDB:SetBool(key, value)
    elseif setting.type == "string" then
        PersistentDB:SetString(key, value)
    end

    -- A failed write must leave the cached value unchanged.
    CachedSettings[key] = value
    if switchedValues then
        for _, name in ipairs(presetFields) do notify(name, switchedValues[name]) end
        notify("presetName", switchedValues.presetName)
        for _, name in ipairs(toggleFields) do
            if switchedValues[name] ~= nil then notify(name, switchedValues[name]) end
        end
    end
    notify(settingName, value)
end

function Settings.get(settingName)
    assertValidSetting(settingName)

    return readSetting(settingName)
end

function Settings.GetRightClickKeybind()
    local value = Settings.get("rightClickKeybind")
    local keys, seen = {}, {}
    if value == "" then return keys end
    -- Store enum names so saved bindings do not depend on numeric key IDs.
    for name in (value .. ","):gmatch("(.-),") do
        local key = GameKey[name]
        if type(key) ~= "number" or seen[key] or #keys == 2 then
            return { GameKey.CONTROL, GameKey.SHIFT }
        end
        keys[#keys + 1] = key
        seen[key] = true
    end
    return keys
end

function Settings.SetRightClickKeybind(keys)
    assert(type(keys) == "table" and #keys <= 2, "A keybind supports up to two keys")
    local names, seen = {}, {}
    for index, key in ipairs(keys) do
        local name = type(key) == "number" and GameKey.FromID(key)
        assert(type(name) == "string", "A keybind must contain GameKey values")
        assert(not seen[key], "A keybind cannot repeat a key")
        names[index] = name
        seen[key] = true
    end
    Settings.update("rightClickKeybind", table.concat(names, ","))
end

return Settings
