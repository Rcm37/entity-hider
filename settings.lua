local Settings = {}

local PLUGIN_DB_PREFIX = "entity_hider_"

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
    spiders = {
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

    if setting.type == "boolean" then
        PersistentDB:SetBool(makeKey(settingName), value)
    elseif setting.type == "string" then
        PersistentDB:SetString(makeKey(settingName), value)
    end
end

function Settings.get(settingName)
    assertValidSetting(settingName)

    local setting = ValidSettings[settingName]
    local value

    if setting.type == "boolean" then
        value = PersistentDB:GetBool(makeKey(settingName))
    elseif setting.type == "string" then
        value = PersistentDB:GetString(makeKey(settingName))
    end

    if value == nil then
        if setting.type == "boolean" then
            PersistentDB:SetBool(makeKey(settingName), setting.default)
        elseif setting.type == "string" then
            PersistentDB:SetString(makeKey(settingName), setting.default)
        end

        return setting.default
    end

    return value
end

return Settings