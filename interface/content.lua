local view
local Settings = require("settings")
local RightClickHider = require("right_click_hider")
local ContentPane = {}
local EVENT_ID = "entity-hider-content-pane"
local lastHiddenText, undoButton
local toggleGroups = {}

local function refreshLastHidden()
    if not view then return end
    local name, kind = RightClickHider.GetLastHidden()
    lastHiddenText.content = name and ("Most recently hidden: " .. name .. " (" .. kind .. ")")
        or "Most recently hidden: None"
    undoButton:SetDisabled(name == nil)
end

local function closeView()
    Settings.Unsubscribe(EVENT_ID)
    RightClickHider.Unsubscribe("content-pane")
    if view then view:Destroy() end
    view, lastHiddenText, undoButton = nil, nil, nil
    toggleGroups = {}
end

local function onLayerReady(event)
    closeView()

    local parent = event.component
    view = prettyui.SimpleView.new(parent, {
        width = parent.width,
        height = parent.height,
    })

    view:AddTitle("Plugin Toggle")
    toggleGroups[1] = view:AddCheckboxButton({
        { text = "Enable Plugin", value = "enabled", selected = Settings.get("enabled") },
    }, {
        onChange = function(_, _, changedValue, selected)
            Settings.update(changedValue, selected)
        end,
    })

    view:AddTitle("Toggle Options")
    toggleGroups[2] = view:AddCheckboxButton({
        { text = "Hide Yourself",    value = "localPlayer",  selected = Settings.get("localPlayer") },
        { text = "Hide Other Players",   value = "otherPlayers", selected = Settings.get("otherPlayers") },
        { text = "Hide NPCs",            value = "allNPCs",      selected = Settings.get("allNPCs") },
        { text = "Hide Conjures",        value = "conjures",     selected = Settings.get("conjures") },
        { text = "Hide All Familiars / Pets",   value = "allFamiliars", selected = Settings.get("allFamiliars") },
        { text = "Hide Drake Familiars", value = "drakePets",    selected = Settings.get("drakePets") },
    }, {
        onChange = function(_, _, changedValue, selected)
            Settings.update(changedValue, selected)
        end,
    })
    view:AddDivider()
    view:AddTitle("Right-click Hiding")
    toggleGroups[3] = view:AddCheckboxButton({
        { text = "Require Ctrl + Shift for Hide options", value = "rightClickRequireCtrlShift",
            selected = Settings.get("rightClickRequireCtrlShift") },
    }, {
        onChange = function(_, _, changedValue, selected)
            Settings.update(changedValue, selected)
        end,
    })
    view:AddText("Right-click a player or NPC and choose Hide to save its name to your custom hide lists.")
    lastHiddenText = view:AddText({ text = "", height = 60, maxLines = 3 })
    undoButton = view:AddSimpleButton("Undo Last Hide", function()
        RightClickHider.Undo()
    end, { disabled = true })
    RightClickHider.Subscribe("content-pane", refreshLastHidden)
    refreshLastHidden()
    view:AddDivider()
    view:AddText("Manage Entity Hider settings via Plugin Hub to set custom configurations!")
    local function refreshStorageAvailability()
        for _, group in ipairs(toggleGroups) do group:SetDisabled(not Settings.IsStorageReady()) end
    end
    refreshStorageAvailability()
    Settings.Subscribe(EVENT_ID, function(name)
        if name == "storageScope" then
            refreshStorageAvailability()
            for index, names in ipairs({
                { "enabled" },
                { "localPlayer", "otherPlayers", "allNPCs", "conjures", "allFamiliars", "drakePets" },
                { "rightClickRequireCtrlShift" },
            }) do
                for _, setting in ipairs(names) do
                    toggleGroups[index]:SetSelected(setting, Settings.get(setting), false)
                end
            end
        end
    end)
end

function ContentPane.Start()
    Event.ContentLayerReady.Subscribe(EVENT_ID, onLayerReady)
end

function ContentPane.Shutdown()
    Event.ContentLayerReady.Unsubscribe(EVENT_ID)
    closeView()
end

return ContentPane
