local Names = {}
local parsedLists = {}

function Names.Clean(name, isPlayer)
    if isPlayer then
        name = name:gsub("\195\130\194\160", " "):gsub("\194\160", " ")
    end
    return name:match("^%s*(.-)%s*$")
end

function Names.Key(name, isPlayer)
    return Names.Clean(name, isPlayer):lower()
end

function Names.Contains(list, name, isPlayer, cacheKey)
    -- Cache only the latest text for each list; discard prior versions after edits.
    cacheKey = cacheKey or (isPlayer and "players" or "npcs")
    local cached = parsedLists[cacheKey]
    local playerNames = isPlayer == true
    if not cached or cached.list ~= list or cached.isPlayer ~= playerNames then
        local names = {}
        for entry in (list .. ","):gmatch("(.-),") do
            names[Names.Key(entry, playerNames)] = true
        end
        cached = { list = list, isPlayer = playerNames, names = names }
        parsedLists[cacheKey] = cached
    end
    return cached.names[Names.Key(name, playerNames)] == true
end

function Names.RemoveLast(list, name, isPlayer)
    local entries = {}
    for entry in (list .. ","):gmatch("(.-),") do
        entries[#entries + 1] = entry
    end
    local key = Names.Key(name, isPlayer)
    for index = #entries, 1, -1 do
        if Names.Key(entries[index], isPlayer) == key then
            table.remove(entries, index)
            return table.concat(entries, ",")
        end
    end
    return list
end

return Names
