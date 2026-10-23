local view
local Settings = require("settings")
local RightClickHider = require("right_click_hider")
local SettingsPane = {}
local EVENT_ID = "entity-hider-settings-pane"
local fields = {}

local function closeView()
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
    RightClickHider.Subscribe("settings-pane", function()
        for setting, field in pairs(fields) do
            field:SetText(Settings.get(setting))
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
