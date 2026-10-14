local contentView
local Settings = require("settings")
local UIUtils = require("interface/ui_utils")
Event.ContentLayerReady.Subscribe("entity-hider-content-pane", function(event)
    if contentView then contentView:Destroy() end

    local parent = event.component
    contentView = prettyui.SimpleView.new(parent, {
        width = parent.width,
        height = parent.height,
    })

    contentView:AddTitle("Global Toggle")
    contentView:AddCheckboxButton({
        { text = "Enable Plugin", value = "enabled", selected = Settings.get("enabled") },
    }, {
        onChange = function(_, _, changedValue, selected)
            UIUtils.updateSettings(changedValue, selected)
        end,
    })

    contentView:AddTitle("Toggle Options")
    contentView:AddCheckboxButton({
        { text = "Hide Yourself",    value = "localPlayer",  selected = Settings.get("localPlayer") },
        { text = "Hide Other Players",   value = "otherPlayers", selected = Settings.get("otherPlayers") },
        { text = "Hide NPCs",            value = "allNPCs",      selected = Settings.get("allNPCs") },
        { text = "Hide Conjures",        value = "conjures",     selected = Settings.get("conjures") },
        { text = "Hide All Familiars / Pets",   value = "allFamiliars", selected = Settings.get("allFamiliars") },
        { text = "Hide Drake Familiars", value = "drakePets",    selected = Settings.get("drakePets") },
        { text = "Hide Spiders",   value = "spiders", selected = Settings.get("spiders") },
    }, {
        onChange = function(_, _, changedValue, selected)
            UIUtils.updateSettings(changedValue, selected)
        end,
    })
    contentView:AddDivider()
    contentView:AddText("Manage Entity Hider settings via Plugin Hub to set custom configurations!")
end)
return contentView