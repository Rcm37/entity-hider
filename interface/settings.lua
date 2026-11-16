local view
local Settings = require("settings")
local RightClickHider = require("right_click_hider")
local NPCIDs = require("npc_ids")
local SettingsPane = {}
local EVENT_ID = "entity-hider-settings-pane"
local fields = {}

local function closeView()
    Settings.Unsubscribe(EVENT_ID)
    RightClickHider.Unsubscribe("settings-pane")
    if view then view:Destroy() end
    view = nil
    fields = {}
end

local function onLayerReady(event)
    closeView()

    local parent = event.component
    view = prettyui.SimpleView.new(parent, {
        width = parent.width,
        height = parent.height,
    })
    view:AddTitle("Custom Inputs")
    view:AddText("Preset")
    local presetDropdown = view:AddComboBox({
        entries = Settings.GetPresetEntries(),
        selectedID = tonumber(Settings.get("activePreset")),
        maxVisibleEntries = Settings.PRESET_COUNT,
        onChange = function(_, presetID)
            Settings.update("activePreset", tostring(presetID))
        end,
    })
    local presetToggleCheckbox = view:AddCheckboxButton({
        { text = "Include global toggles in presets", value = "presetIncludeToggles",
            selected = Settings.get("presetIncludeToggles") },
    }, {
        onChange = function(_, _, name, selected) Settings.update(name, selected) end,
    })
    view:AddText("Preset name")
    local presetNameField = view:AddTextField({
        text = Settings.get("presetName"),
        placeholder = "Preset name",
        onChange = function(_, _, text) Settings.update("presetName", text) end,
    })
    view:AddText({
        text = "Player names (comma-separated)"
    })
    fields.customRSNs = view:AddTextField({
        placeholder = "player1,player2,player3,durial321",
        text = Settings.get("customRSNs"),
        onChange = function(_,_,text)
            Settings.update("customRSNs", text)
        end,
    })
    view:AddText({
        text = "NPC names (comma-separated)"
    })
    fields.customNPCs = view:AddTextField({
        placeholder = "Coeden,Strange Old Man,Clan Representative",
        text = Settings.get("customNPCs"),
        onChange = function(_,_,text)
            Settings.update("customNPCs", text)
        end,
    })
    view:AddText({
        text = "Familiar names (comma-separated)"
    })
    fields.customFamiliars = view:AddTextField({
        placeholder = "Kal'gerion demon,Devout Yak",
        text = Settings.get("customFamiliars"),
        onChange = function(_,_,text)
            Settings.update("customFamiliars", text)
        end,
    })
    local advanced = view:AddCollapseButton("Advanced Settings", { expanded = false })
    advanced:AddText("NPC config IDs (comma-separated)")
    fields.customNPCIDs = advanced:AddTextField({
        text = Settings.get("customNPCIDs"),
        placeholder = "1234, 5678",
        onChange = function(_, _, text) Settings.update("customNPCIDs", text) end,
    })
    local idList = advanced:AddList({
        entries = NPCIDs.GetEntries(Settings.get("customNPCIDs")),
        height = 150,
    })
    view:AddDivider()
    view:AddTitle("Settings Storage")
    local storageCheckbox = view:AddCheckboxButton({
        { text = "Use player-specific settings", value = "playerSpecific",
            selected = Settings.get("playerSpecific") },
    }, {
        onChange = function(control, _, _, selected)
            -- Restore the prior state before an assertion can reject the change.
            control:SetSelected("playerSpecific", Settings.get("playerSpecific"), false)
            if selected then
                assert(Plugin.HasPermission(PluginPermissions.trackingAccess),
                    "Grant trackingAccess permission to enable player-specific settings")
            end
            Settings.update("playerSpecific", selected)
            control:SetSelected("playerSpecific", Settings.get("playerSpecific"), false)
        end,
    })
    view:AddText("Requires trackingAccess permission in Plugin Hub.")
    local storageStatus = view:AddText({ text = "" })
    local function refreshStorage()
        storageCheckbox:SetSelected("playerSpecific", Settings.get("playerSpecific"), false)
        local ready = Settings.IsStorageReady()
        storageStatus.content = ready and ""
            or "Character unavailable. Check trackingAccess permission and login."
        if presetDropdown then presetDropdown:SetDisabled(not ready) end
        presetToggleCheckbox:SetDisabled(not ready)
        presetToggleCheckbox:SetSelected("presetIncludeToggles", Settings.get("presetIncludeToggles"), false)
        if presetNameField then presetNameField:SetDisabled(not ready) end
        idList:SetDisabled(not ready)
        for _, field in pairs(fields) do field:SetDisabled(not ready) end
    end
    refreshStorage()
    local function refreshFields()
        for setting, field in pairs(fields) do
            field:SetText(Settings.get(setting))
        end
    end
    RightClickHider.Subscribe("settings-pane", refreshFields)
    Settings.Subscribe(EVENT_ID, function(name)
        if name == "storageScope" or name == "playerSpecific" or name == "presetIncludeToggles" then refreshStorage() end
        if name == "customNPCIDs" or name == "storageScope" then
            idList:SetEntries(NPCIDs.GetEntries(Settings.get("customNPCIDs")))
        end
        if name == "activePreset" or name == "presetName" then
            presetDropdown:SetEntries(Settings.GetPresetEntries(), tonumber(Settings.get("activePreset")))
        end
        if name == "activePreset" then
            presetNameField:SetText(Settings.get("presetName"))
            refreshFields()
        end
    end)
end

function SettingsPane.Start()
    Event.SettingsLayerReady.Subscribe(EVENT_ID, onLayerReady)
end

function SettingsPane.Shutdown()
    Event.SettingsLayerReady.Unsubscribe(EVENT_ID)
    closeView()
end

return SettingsPane
