local Settings = require("settings")
local Names = require("names")
local EntityHider = {}
local EVENT_ID = "entity-hider-entity-draw"
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


local function ShouldDrawPlayer(player)
    if player == nil then
        return true
    end

    if player.isValid then
        local self = PlayerList.Self()
        if self ~= nil and player.displayName == self.displayName then
            return not Settings.get("localPlayer")
        end
        if Names.Contains(Settings.get("customRSNs"), player.displayName, true, "customRSNs") then
            return false
        end
    end

    return not Settings.get("otherPlayers")
end

local function IsFishingSpot(npc)
    return string.find(string.lower(npc.displayName), "fishing spot", 1, true) ~= nil
end

-- Each rule answers whether this NPC should be hidden.
-- Add new filters here. Any matching rule hides the NPC.
local NPCHideRules = {
    function(npc)
        return Settings.get("conjures") and ConjureLookupTable[npc.config.id] == true
    end,
    function(npc)
        -- Keep fishing spots visible; custom-name rules can still hide them.
        -- Familiars / pets, and conjures have separate toggles.
        return Settings.get("allNPCs") and not npc.config.isFamiliar
            and not ConjureLookupTable[npc.config.id]
            and not IsFishingSpot(npc)
    end,
    function(npc)
        return Settings.get("allFamiliars") and npc.config.isFamiliar
    end,
    function(npc)
        return Settings.get("drakePets") and DrakeLookupTable[npc.config.id] == true
    end,
    function(npc)
        local setting = npc.config.isFamiliar and "customFamiliars" or "customNPCs"
        return Names.Contains(Settings.get(setting), npc.displayName, false, setting)
    end,
}

local function ShouldDrawNPC(npc)
    if npc == nil or npc.config == nil
        or npc.config.id == nil or npc.config.isFamiliar == nil then
        return true
    end

    for _, shouldHide in ipairs(NPCHideRules) do
        if shouldHide(npc) then return false end
    end

    return true
end

local DrawHandlers = {
    [EntityType.PLAYER] = function(event) return ShouldDrawPlayer(event.playerEntity) end,
    [EntityType.NPC] = function(event) return ShouldDrawNPC(event.npcEntity) end,
}

local function onEntityDraw(event)
    if not Settings.get("enabled") or event == nil then
        return true
    end

    local handler = DrawHandlers[event.entityType]
    if handler then
        return handler(event)
    end

    return true
end

local active = false

local function setEnabled(enabled)
    if active == enabled then return end
    if enabled then
        Event.EntityDraw.Subscribe(EVENT_ID, onEntityDraw)
    else
        Event.EntityDraw.Unsubscribe(EVENT_ID)
    end
    active = enabled
end

local function onSettingChanged(name, value)
    if name == "enabled" then setEnabled(value) end
end

function EntityHider.Start()
    Settings.Subscribe(EVENT_ID, onSettingChanged)
    setEnabled(Settings.get("enabled"))
end

function EntityHider.Shutdown()
    Settings.Unsubscribe(EVENT_ID)
    setEnabled(false)
end

return EntityHider
