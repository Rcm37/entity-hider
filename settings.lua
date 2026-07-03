local Settings = {}

local DB_KEY = "entity_hider_settings"

local defaults = {
    menuX = 14,
    menuY = 170,
    activeTab = "Toggles",
    menuOpacity = 70,
    enabled = true,
    dragEnabled = false,
    accentColor = "00FF3F",
    labelColor = "007FFF",
    localPlayer = false,
    otherPlayers = false,
    conjures = false,
    allFamiliars = false,
    drakePets = false,
    allNPCs = false

}

local saveKeys = {
    "menuX",
    "menuY",
    "activeTab",
    "menuOpacity",
    "enabled",
    "dragEnabled",
    "accentColor",
    "labelColor",
    "localPlayer",
    "otherPlayers",
    "conjures",
    "allFamiliars",
    "drakePets",
    "allNPCs"
}

Settings.OPTIONS = {
    activeTab = { "Toggles", "Custom NPCs", "Custom Players" }
}

local function copyDefaults()
    local copied = {}
    for key, value in pairs(defaults) do
        copied[key] = value
    end
    return copied
end

local function contains(list, value)
    for _, item in ipairs(list or {}) do
        if item == value then
            return true
        end
    end
    return false
end

function Settings.ClampInt(value, minValue, maxValue, fallback)
    local numberValue = tonumber(value)
    if numberValue == nil then
        numberValue = fallback or minValue
    end

    numberValue = math.floor(numberValue)
    if numberValue < minValue then
        return minValue
    elseif numberValue > maxValue then
        return maxValue
    end
    return numberValue
end

function Settings.NormalizeBool(value, fallback)
    if type(value) == "boolean" then
        return value
    elseif type(value) == "string" then
        local text = value:lower()
        if text == "true" or text == "1" or text == "yes" or text == "on" then
            return true
        elseif text == "false" or text == "0" or text == "no" or text == "off" then
            return false
        end
    elseif type(value) == "number" then
        return value ~= 0
    end
    return fallback and true or false
end

function Settings.NormalizeChoice(value, options, fallback)
    if contains(options, value) then
        return value
    end
    return fallback
end

function Settings.NormalizeHex(value, fallback)
    local text = tostring(value or ""):upper():gsub("#", ""):gsub("[^0-9A-F]", "")
    if #text >= 6 then
        return text:sub(1, 6)
    end
    return fallback or "FFFFFF"
end

function Settings.RGBA(hex, alpha)
    local normalized = Settings.NormalizeHex(hex, "FFFFFF")
    local red = tonumber(normalized:sub(1, 2), 16) or 255
    local green = tonumber(normalized:sub(3, 4), 16) or 255
    local blue = tonumber(normalized:sub(5, 6), 16) or 255
    local a = tonumber(alpha) or 1
    if a < 0 then
        a = 0
    elseif a > 1 then
        a = 1
    end
    return Vector4.new(red / 255, green / 255, blue / 255, a)
end

function Settings.Normalize(input)
    local source = type(input) == "table" and input or {}
    local normalized = copyDefaults()

    normalized.menuX = Settings.ClampInt(source.menuX, 0, 3000, defaults.menuX)
    normalized.menuY = Settings.ClampInt(source.menuY, 0, 3000, defaults.menuY)
    normalized.activeTab = Settings.NormalizeChoice(source.activeTab, Settings.OPTIONS.activeTab, defaults.activeTab)
    normalized.conjures = Settings.NormalizeBool(source.conjures, defaults.conjures)
    normalized.drakePets = Settings.NormalizeBool(source.drakePets, defaults.drakePets)
    normalized.allFamiliars = Settings.NormalizeBool(source.allFamiliars, defaults.allFamiliars)
    normalized.allNPCs = Settings.NormalizeBool(source.allNPCs, defaults.allNPCs)
    normalized.localPlayer = Settings.NormalizeBool(source.localPlayer, defaults.localPlayer)
    normalized.otherPlayers = Settings.NormalizeBool(source.otherPlayers, defaults.otherPlayers)
    normalized.menuOpacity = Settings.ClampInt(source.menuOpacity, 30, 100, defaults.menuOpacity)
    normalized.enabled = Settings.NormalizeBool(source.enabled, defaults.enabled)
    normalized.dragEnabled = Settings.NormalizeBool(source.dragEnabled, defaults.dragEnabled)
    normalized.accentColor = Settings.NormalizeHex(source.accentColor, defaults.accentColor)
    normalized.labelColor = Settings.NormalizeHex(source.labelColor, defaults.labelColor)

    return normalized
end

function Settings.Defaults()
    return Settings.Normalize(defaults)
end

local function encodeValue(value)
    if type(value) == "boolean" then
        return value and "b:true" or "b:false"
    elseif type(value) == "number" then
        return "n:" .. tostring(value)
    end
    return "s:" .. tostring(value or "")
end

local function decodeValue(value)
    local text = tostring(value or "")
    local kind = text:sub(1, 2)
    local payload = text:sub(3)
    if kind == "b:" then
        return payload == "true"
    elseif kind == "n:" then
        return tonumber(payload)
    elseif kind == "s:" then
        return payload
    end
    return value
end

function Settings.Load()
    local stored = PersistentDB:GetStructuredData(DB_KEY)
    if type(stored) == "table" then
        for key, value in pairs(stored) do
            stored[key] = decodeValue(value)
        end
    end
    return Settings.Normalize(stored)
end

function Settings.Save(settings)
    local normalized = Settings.Normalize(settings)
    local stored = {}
    for _, key in ipairs(saveKeys) do
        stored[key] = encodeValue(normalized[key])
    end
    PersistentDB:SetStructuredData(DB_KEY, stored)
end

return Settings
