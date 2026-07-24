local Settings = require("settings")

local gallery = require("interface/gallery")

local BUILD_EVENT = "entity_hider_build"
local ribbonButton = nil

local function buildGallery()
    return gallery.Build(function()
        if ribbonButton then ribbonButton:SetActive(false) end
    end)
end

ribbonButton = prettyui.RibbonBar.Register({
    id = "EntityHider",
    icon = id.Sprite.COMBAT_ABILITY_ICON_NECROMANCY_CONJURE_SKELETON_WARRIOR_LOCKED,
    tooltip = "Entity Hider",
    onClick = function(handle, active)
        if active then
            if buildGallery() then
                gallery.Show()
            else
                handle:SetActive(false)
            end
        else
            gallery.Close()
        end
    end,
})

-- The game area may not exist during the first plugin tick.
if not buildGallery() then
    Event.Logic.Subscribe(BUILD_EVENT, function()
        if buildGallery() then
            ribbonButton:SetActive(true)
            Event.Logic.Unsubscribe(BUILD_EVENT)
        end
    end)
else
    ribbonButton:SetActive(true)
end

function PluginShutdown()
    Event.Logic.Unsubscribe(BUILD_EVENT)
    gallery.Destroy()

    if ribbonButton then
        ribbonButton:Destroy()
        ribbonButton = nil
    end
end


Event.EntityDraw.Subscribe("myEvent", function(entityEvent)
    if not Settings.get("enabled") then
        return true
    end
    -- Player type hiders
    if entityEvent ~= nil and entityEvent.entityType == EntityType.PLAYER then
        if entityEvent.playerEntity.isValid and entityEvent.playerEntity.displayName == PlayerList.Self().displayName then
            return not Settings.get("localPlayer")
        end

        return not Settings.get("otherPlayers")
    end
    -- NPC type hiders
    if NPCEntitySafetyCheckPassed(entityEvent) then
        if Settings.get("allNPCs") then
            -- exclude familiars since users aren't likely to expect an NPC toggle to hide them
            if not entityEvent.npcEntity.config.isFamiliar then
                return false
            end
        end

        if Settings.get("allFamiliars") then
            if entityEvent.npcEntity.config.isFamiliar then
                return false
            end
        end
        if not Settings.get("allFamiliars") and Settings.get("drakePets") then
            if DrakeLookupTable[entityEvent.npcEntity.config.id] then
                return false
            end
        end
        if Settings.get("conjures") then
            if ConjureLookupTable[entityEvent.npcEntity.config.id] then
                return false
            end
        end
    end
    return true
end)

DrakeLookupTable = {
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

ConjureLookupTable = {
    [id.NPC.COMBATV2_NECROMANCY_SPIRIT_SKELETON_WARRIOR] = true,
    [id.NPC.COMBATV2_NECROMANCY_SPIRIT_PUTRID_ZOMBIE] = true,
    [id.NPC.COMBATV2_NECROMANCY_SPIRIT_VENGEFUL_GHOST] = true,
    [id.NPC.COMBATV2_NECROMANCY_SPIRIT_PHANTOM_GUARDIAN] = true,
    [id.NPC.MTXMGT_PREVIEW_COMBATV2_NECROMANCY_SPIRIT_PHANTOM_GUARDIAN_PRIMAL] = true,
    [id.NPC.MTXMGT_PREVIEW_COMBATV2_NECROMANCY_SPIRIT_PHANTOM_GUARDIAN_XMAS24] = true
}


function NPCEntitySafetyCheckPassed(entityEvent)
    return entityEvent ~= nil
        and entityEvent.entityType == EntityType.NPC
        and entityEvent.npcEntity ~= nil
        and entityEvent.npcEntity.config ~= nil
        and entityEvent.npcEntity.config.id ~= nil
        and entityEvent.npcEntity.config.isFamiliar ~= nil
end
