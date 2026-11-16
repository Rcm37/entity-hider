local NPCIDs = {}
local cachedText, cachedIDs, cachedSet

function NPCIDs.IsValid(value)
    return type(value) == "number" and value >= 0 and value <= 2147483647 and value % 1 == 0
end

local function parseEntry(text)
    text = text:match("^%s*(.-)%s*$")
    local value = text:match("^%d+$") and tonumber(text)
    if NPCIDs.IsValid(value) then return value end
end

local function parse(list)
    if cachedText == list then return end
    local ids, set = {}, {}
    for text in (list .. ","):gmatch("(.-),") do
        local value = parseEntry(text)
        if value and not set[value] then
            ids[#ids + 1], set[value] = value, true
        end
    end
    cachedText, cachedIDs, cachedSet = list, ids, set
end

function NPCIDs.Contains(list, value)
    if not NPCIDs.IsValid(value) then return false end
    parse(list)
    return cachedSet[value] == true
end

function NPCIDs.Describe(value, npcConfig)
    local ok, label = pcall(function()
        local entry = npcConfig or config.NPC.FromID(value)
        if not entry then return nil end
        local configName, name = entry.configName, entry.name
        if type(configName) == "string" and configName:find("%S") then
            return configName .. (type(name) == "string" and name:find("%S") and (" (" .. name .. ")") or "")
        end
        if type(name) == "string" and name:find("%S") then return name end
    end)
    return tostring(value) .. " - " .. (ok and label or "Unknown / unavailable config")
end

function NPCIDs.GetEntries(list)
    parse(list)
    local entries = {}
    for _, value in ipairs(cachedIDs) do
        entries[#entries + 1] = { id = value, label = NPCIDs.Describe(value) }
    end
    return entries
end

return NPCIDs
