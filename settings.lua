local Settings = {}

local PLUGIN_DB_PREFIX = "entity_hider_"

-- Settings toggles and their default values
local ValidSettings = {
    enabled = true,
    conjures = false,
    drakePets = false,
    allFamiliars = false,
    allNPCs = false,
    localPlayer = false,
    otherPlayers = false
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

    if type(value) ~= "boolean" then
        error("Expected boolean for setting: " .. tostring(settingName))
    end

    PersistentDB:SetBool(makeKey(settingName), value)
end

function Settings.get(settingName)
    assertValidSetting(settingName)

    local value = PersistentDB:GetBool(makeKey(settingName))

    if value == nil then
        PersistentDB:SetBool(makeKey(settingName), ValidSettings[settingName])
        return ValidSettings[settingName]
    end

    return value
end

return Settings