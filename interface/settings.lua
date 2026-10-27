local view
local Settings = require("settings")
local RightClickHider = require("right_click_hider")
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
    view:AddText("Custom input preset")
    local presetDropdown = view:AddComboBox({
        entries = Settings.GetPresetEntries(),
        selectedID = tonumber(Settings.get("activePreset")),
        maxVisibleEntries = Settings.PRESET_COUNT,
        onChange = function(_, presetID)
            Settings.update("activePreset", tostring(presetID))
        end,
    })
    view:AddText("Preset name")
    local presetNameField = view:AddTextField({
        text = Settings.get("presetName"),
        placeholder = "Preset name",
        onChange = function(_, _, text) Settings.update("presetName", text) end,
    })
    view:AddText({
        text = "Supports text selection, copy, and paste"
    })
    view:AddText({
        text = "Input RSNs separated by commas"
    })
    fields.customRSNs = view:AddTextField({
        placeholder = "player1,player2,player3,durial321",
        text = Settings.get("customRSNs"),
        onChange = function(_,_,text)
            Settings.update("customRSNs", text)
        end,
    })
    view:AddText({
        text = "Input NPC names separated by commas"
    })
    fields.customNPCs = view:AddTextField({
        placeholder = "Coeden,Strange Old Man,Clan Representative",
        text = Settings.get("customNPCs"),
        onChange = function(_,_,text)
            Settings.update("customNPCs", text)
        end,
    })
    view:AddText({
        text = "Input familiar names separated by commas"
    })
    fields.customFamiliars = view:AddTextField({
        placeholder = "Kal'gerion demon,Devout Yak",
        text = Settings.get("customFamiliars"),
        onChange = function(_,_,text)
            Settings.update("customFamiliars", text)
        end,
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
    view:AddText("Save settings separately for each character. Requires the optional trackingAccess permission in Plugin Hub. Turn off to use global settings.")
    local storageStatus = view:AddText({ text = "" })
    local function refreshStorage()
        storageCheckbox:SetSelected("playerSpecific", Settings.get("playerSpecific"), false)
        local ready = Settings.IsStorageReady()
        storageStatus.content = ready and ""
            or "Character settings unavailable. Grant trackingAccess and wait for login, or turn off player-specific settings."
        if presetDropdown then presetDropdown:SetDisabled(not ready) end
        if presetNameField then presetNameField:SetDisabled(not ready) end
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
        if name == "storageScope" or name == "playerSpecific" then refreshStorage() end
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
