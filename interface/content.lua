local view
local Settings = require("settings")
local RightClickHider = require("right_click_hider")
local ContentPane = {}
local EVENT_ID = "entity-hider-content-pane"
local lastHiddenText, undoButton, keybindField
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
    view, lastHiddenText, undoButton, keybindField = nil, nil, nil, nil
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
        { text = "Hide Spiders",        value = "spiders",      selected = Settings.get("spiders") },
    }, {
        onChange = function(_, _, changedValue, selected)
            Settings.update(changedValue, selected)
        end,
    })
    view:AddDivider()
    view:AddTitle("Right-click Hiding")
    toggleGroups[3] = view:AddCheckboxButton({
        { text = "Require keybind for Hide options", value = "rightClickRequireCtrlShift",
            selected = Settings.get("rightClickRequireCtrlShift") },
    }, {
        onChange = function(_, _, changedValue, selected)
            Settings.update(changedValue, selected)
        end,
    })
    keybindField = view:AddKeybindField({
        value = Settings.GetRightClickKeybind(),
        defaultValue = { GameKey.CONTROL, GameKey.SHIFT },
        onChange = function(_, keys) Settings.SetRightClickKeybind(keys) end,
    })
    view:AddText("Click to bind up to two keys.")
    lastHiddenText = view:AddText({ text = "", height = 60, maxLines = 3 })
    undoButton = view:AddSimpleButton("Undo Last Hide", function()
        RightClickHider.Undo()
    end, { disabled = true })
    RightClickHider.Subscribe("content-pane", refreshLastHidden)
    refreshLastHidden()
    view:AddDivider()
    view:AddText("Configure custom hide lists and presets in Plugin Hub settings.")
    local function refreshStorageAvailability()
        for _, group in ipairs(toggleGroups) do group:SetDisabled(not Settings.IsStorageReady()) end
        keybindField:SetDisabled(not Settings.IsStorageReady())
    end
    refreshStorageAvailability()
    Settings.Subscribe(EVENT_ID, function(name)
        if name == "rightClickKeybind" or name == "storageScope" then
            keybindField:SetValue(Settings.GetRightClickKeybind(), false)
        end
        if name == "storageScope" or name == "activePreset" then
            refreshStorageAvailability()
            for index, names in ipairs({
                { "enabled" },
                { "localPlayer", "otherPlayers", "allNPCs", "conjures", "allFamiliars", "drakePets", "spiders" },
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
