local Settings = require("settings")
local Names = require("names")
local Familiars = require("familiars")
local Hider = {}
local EVENT_ID = "entity-hider-right-click"
local lastHidden
local listeners = {}

local function notify()
    for _, callback in pairs(listeners) do callback() end
end

function Hider.Subscribe(key, callback)
    listeners[key] = callback
end

function Hider.Unsubscribe(key)
    listeners[key] = nil
end

function Hider.GetLastHidden()
    if not lastHidden then return nil end
    return lastHidden.name, lastHidden.kind
end

local function hide(target)
    -- Capture names rather than retaining entity userdata after menu creation.
    if not Settings.get("enabled") or target.preset ~= Settings.get("activePreset")
        or target.scope ~= Settings.GetStorageScope() or not Settings.IsStorageReady() then return end
    local list = Settings.get(target.setting)
    if Names.Contains(list, target.name, target.isPlayer, target.setting) then return end
    local updated = list:match("^%s*$") and target.name or (list .. ", " .. target.name)
    Settings.update(target.setting, updated)
    lastHidden = target
    notify()
end

function Hider.Undo()
    if not lastHidden then return false end
    local target = lastHidden
    local list = Settings.get(target.setting)
    local updated = Names.RemoveLast(list, target.name, target.isPlayer)
    if updated ~= list then Settings.update(target.setting, updated) end
    lastHidden = nil
    notify()
    return true
end

local function targetFromEntry(entry)
    local entity, setting, kind, isPlayer
    if entry.actionEntryType == MiniMenuEntryType.NPC then
        entity = entry.npcData and entry.npcData.entity
        if not entity or not entity.isValid or not entity.config then return end
        local isFamiliar = Familiars.IsFamiliar(entity)
        setting = isFamiliar and "customFamiliars" or "customNPCs"
        kind = isFamiliar and "Familiar / pet" or "NPC"
    elseif entry.actionEntryType == MiniMenuEntryType.PLAYER then
        entity = entry.playerData and entry.playerData.entity
        if not entity or not entity.isValid then return end
        setting, kind, isPlayer = "customRSNs", "Player", true
        -- The local player is controlled by Hide Yourself, not the name list.
        local self = PlayerList.Self()
        if self and Names.Key(self.displayName, true) == Names.Key(entity.displayName, true) then return end
    else
        return
    end

    local name = Names.Clean(entity.displayName, isPlayer)
    -- Commas separate saved names, so such names cannot be represented in a list.
    if name == "" or name:find(",", 1, true) then return end
    if Names.Contains(Settings.get(setting), name, isPlayer, setting) then return end
    return { name = name, setting = setting, kind = kind, isPlayer = isPlayer,
        preset = Settings.get("activePreset"), scope = Settings.GetStorageScope() }
end

local function onMenuReady(event)
    if not Settings.IsStorageReady() then return end
    if not Settings.get("enabled") then return end
    if Settings.get("rightClickRequireCtrlShift")
        and not (Keyboard.IsControlDown() and Keyboard.IsShiftDown()) then
        return
    end
    local menu = event.miniMenu
    local targets, seen = {}, {}
    -- Snapshot before Add mutates the menu, and deduplicate multiple operations
    -- (or multiple NPCs) that would all hide the same saved name.
    for _, entry in ipairs(menu.entries) do
        local target = targetFromEntry(entry)
        if target then
            local key = target.setting .. ":" .. Names.Key(target.name, target.isPlayer)
            if not seen[key] then
                seen[key] = true
                targets[#targets + 1] = target
            end
        end
    end
    for _, target in ipairs(targets) do
        menu:Add("Hide " .. target.name .. " (Entity Hider)", hide, target)
    end
end

local active = false

-- Keep the last-hide undo state when disabled.
local function setEnabled(enabled)
    if active == enabled then return end
    if enabled then
        Event.MiniMenuReady.Subscribe(EVENT_ID, onMenuReady)
    else
        Event.MiniMenuReady.Unsubscribe(EVENT_ID)
    end
    active = enabled
end

local function onSettingChanged(name, value)
    if name == "enabled" then setEnabled(value) end
    if name == "activePreset" or name == "storageScope" then
        lastHidden = nil
        notify()
    end
end

function Hider.Start()
    Settings.Subscribe(EVENT_ID, onSettingChanged)
    setEnabled(Settings.get("enabled"))
end

function Hider.Shutdown()
    Settings.Unsubscribe(EVENT_ID)
    setEnabled(false)
    listeners = {}
    lastHidden = nil
end

return Hider
