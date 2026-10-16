local Settings = require("settings")

local settingsView = require("interface/settings")
local contentView = require("interface/content")

function PluginShutdown()
    Event.SettingsLayerReady.Unsubscribe("entity-hider-settings-pane")
    if settingsView then
        settingsView:Destroy()
        settingsView = nil
    end
    Event.ContentLayerReady.Unsubscribe("entity-hider-content-pane")
    if contentView then
        contentView:Destroy()
        contentView = nil
    end
end


local DrakeLookupTable = {
    [id.NPC.MTX_PET_DRAKE] = true,
    [id.NPC.MTX_PET_SHADOW_DRAKE] = true,
    [id.NPC.MTX_PET_DRAKE_JUVI] = true,
    [id.NPC.MTX_PET_SHADOW_DRAKE_JUVI] = true,
    [id.NPC.MTX_PET_DRAKE_ADULT] = true,
    [id.NPC.MTX_PET_SHADOW_DRAKE_ADULT] = true,
    [id.NPC.POH_MTX_PET_DRAKE] = true,
    [id.NPC.POH_MTX_PET_SHADOW_DRAKE] = true,
    [id.NPC.POH_MTX_PET_DRAKE_JUVI] = true,
    [id.NPC.POH_MTX_PET_SHADOW_DRAKE_JUVI] = true,
    [id.NPC.POH_MTX_PET_DRAKE_ADULT] = true,
    [id.NPC.POH_MTX_PET_SHADOW_DRAKE_ADULT] = true,
    [id.NPC.MTX_PET_DRAKE_BABY_TELEPORT] = true,
    [id.NPC.MTX_PET_DRAKE_JUVI_TELEPORT] = true,
    [id.NPC.MTX_PET_DRAKE_ADULT_TELEPORT] = true,
    [id.NPC.MTX_PET_SHADOW_DRAKE_TELEPORT] = true,
    [id.NPC.MTX_PET_SHADOW_DRAKE_JUVI_TELEPORT] = true,
    [id.NPC.MTX_PET_SHADOW_DRAKE_ADULT_TELEPORT] = true,
    [id.NPC.MTX118_FAIRY_DRAKE_DAY] = true,
    [id.NPC.POH_MTX118_FAIRY_DRAKE_DAY] = true,
    [id.NPC.MTX118_FAIRY_DRAKE_NIGHT] = true,
    [id.NPC.POH_MTX118_FAIRY_DRAKE_NIGHT] = true,
    [id.NPC.RUNEPASS_7_REWARD_PET_JAS_DRAKE] = true,
    [id.NPC.RUNEPASS_7_REWARD_PET_JAS_DRAKE_POH] = true,
    [id.NPC.RUNEPASS_7_REWARD_PET_WEN_DRAKE] = true,
    [id.NPC.RUNEPASS_7_REWARD_PET_WEN_DRAKE_POH] = true,
    [id.NPC.RUNEPASS_9_REWARD_PET_BIK_DRAKE_POH] = true,
    [id.NPC.RUNEPASS_9_REWARD_PET_FUL_DRAKE] = true,
    [id.NPC.RUNEPASS_9_REWARD_PET_FUL_DRAKE_POH] = true,
    [id.NPC.RUNEPASS_9_REWARD_PET_BIK_DRAKE] = true,
    [id.NPC.PREM23_PET] = true,
    [id.NPC.PREM23_PET_POH] = true
}

local ConjureLookupTable = {
    [id.NPC.COMBATV2_NECROMANCY_SPIRIT_SKELETON_WARRIOR] = true,
    [id.NPC.COMBATV2_NECROMANCY_SPIRIT_PUTRID_ZOMBIE] = true,
    [id.NPC.COMBATV2_NECROMANCY_SPIRIT_VENGEFUL_GHOST] = true,
    [id.NPC.COMBATV2_NECROMANCY_SPIRIT_PHANTOM_GUARDIAN] = true,
    [id.NPC.MTXMGT_PREVIEW_COMBATV2_NECROMANCY_SPIRIT_PHANTOM_GUARDIAN_PRIMAL] = true,
    [id.NPC.MTXMGT_PREVIEW_COMBATV2_NECROMANCY_SPIRIT_PHANTOM_GUARDIAN_XMAS24] = true
}


local function NormalizeName(name)
    return name:lower()
        :gsub("\195\130\194\160", " ")
        :gsub("\194\160", " ")
end

local function ListContains(list, name, isPlayer)
    list = string.lower(list):gsub("%s*,%s*", ",")
    name = string.lower(name)
    -- npc names seem to be fine with spaces, only player names have the weird non-breaking thing
    if isPlayer then
        name = NormalizeName(name)
    end

    return ("," .. list .. ","):find("," .. name .. ",", 1, true) ~= nil
end

local function ShouldDrawPlayer(player)
    if player == nil then
        return true
    end

    if player.isValid then
        local self = PlayerList.Self()
        if self ~= nil and player.displayName == self.displayName then
            return not Settings.get("localPlayer")
        end
        if ListContains(Settings.get("customRSNs"), player.displayName, true) then
            return false
        end
    end

    return not Settings.get("otherPlayers")
end

-- Each rule returns false to hide or nil to continue checking other filters.
-- Add new NPC filters here. An NPC is drawn only if no rule hides it.
local NPCDrawRules = {
    function(npc)
        if Settings.get("conjures") and ConjureLookupTable[npc.config.id] then
            return false
        end
    end,
    function(npc)
        -- Familiars / pets, and conjures have separate toggles.
        if Settings.get("allNPCs") and not npc.config.isFamiliar
            and not ConjureLookupTable[npc.config.id] then
            return false
        end
    end,
    function(npc)
        if Settings.get("spiders") and string.find(string.lower(npc.displayName), "spider") then
            return false
        end
    end,
    function(npc)
        if Settings.get("allFamiliars") and npc.config.isFamiliar then
            return false
        end
    end,
    function(npc)
        if not Settings.get("allFamiliars") and Settings.get("drakePets")
            and DrakeLookupTable[npc.config.id] then
            return false
        end
    end,
    function(npc)
        local setting = npc.config.isFamiliar and "customFamiliars" or "customNPCs"
        if ListContains(Settings.get(setting), npc.displayName, false) then
            return false
        end
    end,
}

local function ShouldDrawNPC(npc)
    if npc == nil or npc.config == nil
        or npc.config.id == nil or npc.config.isFamiliar == nil then
        return true
    end

    for _, rule in ipairs(NPCDrawRules) do
        local shouldDraw = rule(npc)
        if shouldDraw ~= nil then
            return shouldDraw
        end
    end

    return true
end

local DrawHandlers = {
    [EntityType.PLAYER] = function(event) return ShouldDrawPlayer(event.playerEntity) end,
    [EntityType.NPC] = function(event) return ShouldDrawNPC(event.npcEntity) end,
}

Event.EntityDraw.Subscribe("entity-hider-entity-draw", function(event)
    if not Settings.get("enabled") or event == nil then
        return true
    end

    local handler = DrawHandlers[event.entityType]
    if handler then
        return handler(event)
    end

    return true
end)
