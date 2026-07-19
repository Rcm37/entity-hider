local GUI = require("interface/gui")
local Settings = require("settings")

-- Toggles are just hardcoded true for now

Event.EntityDraw.Subscribe("myEvent", function(entityEvent)
    local settings = Settings.Load()
    if not settings.enabled then
        return true
    end
    -- Player type hiders
    if entityEvent ~= nil and entityEvent.entityType == EntityType.PLAYER then
        if entityEvent.playerEntity.isValid and entityEvent.playerEntity.displayName == PlayerList.Self().displayName then
            return not settings.localPlayer
        end

        return not settings.otherPlayers

    end
    -- NPC type hiders
    if NPCEntitySafetyCheckPassed(entityEvent) then
        if settings.allNPCs then
                -- exclude familiars since users aren't likely to expect an NPC toggle to hide them
                if not entityEvent.npcEntity.config.isFamiliar then
                    return false
                end
        end

        if settings.allFamiliars then
                if entityEvent.npcEntity.config.isFamiliar then
                    return false
                end
        end
        if not settings.allFamiliars and settings.drakePets then
                if DrakeLookupTable[entityEvent.npcEntity.config.id] then
                    return false
                end
        end
        if settings.conjures then
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

