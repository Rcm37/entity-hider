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

-- Settings and their default values/types
local ValidSettings = {
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
    rightClickRequireCtrlShift = {
        default = false,
        type = "boolean"
    },
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

local function makeKey(settingName)
    return PLUGIN_DB_PREFIX .. settingName
end

function Settings.update(settingName, value)
    assertValidSetting(settingName)

    local setting = ValidSettings[settingName]

    if type(value) ~= setting.type then
        error("Setting " .. settingName .. " expects " .. setting.type .. ", got " .. type(value))
    end

    if setting.type == "boolean" then
        PersistentDB:SetBool(makeKey(settingName), value)
    elseif setting.type == "string" then
        PersistentDB:SetString(makeKey(settingName), value)
    end

    -- A failed write must leave the cached value unchanged.
    CachedSettings[settingName] = value
    for _, callback in pairs(listeners) do callback(settingName, value) end
end

function Settings.get(settingName)
    assertValidSetting(settingName)

    if CachedSettings[settingName] ~= nil then
        return CachedSettings[settingName]
    end

    local setting = ValidSettings[settingName]
    local value

    if setting.type == "boolean" then
        value = PersistentDB:GetBool(makeKey(settingName))
    elseif setting.type == "string" then
        value = PersistentDB:GetString(makeKey(settingName))
    end

    if value == nil then
        value = setting.default

        if setting.type == "boolean" then
            PersistentDB:SetBool(makeKey(settingName), value)
        elseif setting.type == "string" then
            PersistentDB:SetString(makeKey(settingName), value)
        end
    end

    CachedSettings[settingName] = value
    return value
end

return Settings
