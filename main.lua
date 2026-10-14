local Settings = require("settings")

local settingsView = require("interface/settings")
local contentView = require("interface/content")

function PluginShutdown()
    Event.SettingsLayerReady.Unsubscribe("my-plugin-settings")
    print(settingsView)
    if settingsView then
        print("attempt destroy")
        settingsView:Destroy()
        settingsView = nil
    end
    Event.ContentLayerReady.Unsubscribe("my-plugin-content")
    print(contentView)
    if contentView then
        print("attempt destroy 2")
        contentView:Destroy()
        contentView = nil
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
        if entityEvent.playerEntity.isValid and ListContains(Settings.get("customRSNs"), entityEvent.playerEntity.displayName) then
            return false
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
        if string.find(entityEvent.npcEntity.displayName, "spider") then
            return not Settings.get("spiders")
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
        if ListContains(Settings.get("customNPCs"), entityEvent.npcEntity.displayName) then
            return false
        end

        if entityEvent.npcEntity.config.isFamiliar and ListContains(Settings.get("customFamiliars"), entityEvent.npcEntity.displayName) then
            return false
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

function ListContains(list, name)
    list = string.lower(list):gsub("%s*,%s*", ",")
    name = string.lower(name)

    return ("," .. list .. ","):find("," .. name .. ",", 1, true) ~= nil
end
