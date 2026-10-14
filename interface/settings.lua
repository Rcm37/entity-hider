local settingsView
local Settings = require("settings")
local UIUtils = require("interface/ui_utils")

Event.SettingsLayerReady.Subscribe("my-plugin-settings", function(event)
    if settingsView then settingsView:Destroy() end

    local parent = event.component
    settingsView = prettyui.SimpleView.new(parent, {
        width = parent.width,
        height = parent.height,
    })
    settingsView:AddTitle("Custom Inputs")
    settingsView:AddText({
        text = "Supports text selection, copy, and paste"
    })
    settingsView:AddText({
        text = "Input RSNs separated by commas"
    })
    settingsView:AddTextField({
        placeholder = "player1,player2,player3,durial321",
        text = Settings.get("customRSNs"),
        onChange = function(_,_,text)
            UIUtils.updateCustomRSNs(text)
        end,
    })
    settingsView:AddText({
        text = "Input NPC names separated by commas"
    })
    settingsView:AddTextField({
        placeholder = "Coeden,Strange Old Man,Clan Representative",
        text = Settings.get("customNPCs"),
        onChange = function(_,_,text)
            UIUtils.updateCustomNPCs(text)
        end,
    })
    settingsView:AddText({
        text = "Input familiar names separated by commas"
    })
    settingsView:AddTextField({
        placeholder = "Kal'gerion demon,Devout Yak",
        text = Settings.get("customFamiliars"),
        onChange = function(_,_,text)
            UIUtils.updateCustomFamiliars(text)
        end,
    })
end)
return settingsView