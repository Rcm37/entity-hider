local gallery = {}
local Settings = require("Settings")

local GUI_WIDTH = 240
local GUI_HEIGHT = 450

-- Main gallery surfaces.
local toggleGUI = nil
local onClose = nil

-- Component handles retained by the demo.
local toggleOptions = nil
local globalToggle = nil

-- Build our primary window
local function createDemoWindow(gameArea)
    return prettyui.Window.new(gameArea, {
        title = "Entity Hider",
        x = 20,
        y = 20,
        xAnchor = 0,
        yAnchor = 0,
        width = GUI_WIDTH,
        height = GUI_HEIGHT,
        minWidth = 240,
        minHeight = 300,
        onClose = function()
            if onClose then onClose() end
        end,
    })
end

-- Demo sections appear here in the same order as they appear in the UI.
local function createWindow(window)
    window:AddTitle("Global Toggle")
    globalToggle = window:AddCheckboxButton({
        { text = "Enable Plugin", value = "enabled", selected = Settings.get("enabled") },
    }, {
        onChange = function(_, _, changedValue, selected)
            updateSettings(changedValue, selected)
        end,
    })
end

local function createToggles(window)
    window:AddTitle("Toggle Options")
    toggleOptions = window:AddCheckboxButton({
        { text = "Hide Conjures",        value = "conjures",     selected = Settings.get("conjures") },
        { text = "Hide Drake Familiars", value = "drakePets",    selected = Settings.get("drakePets") },
        { text = "Hide All Familiars",   value = "allFamiliars", selected = Settings.get("allFamiliars") },
        { text = "Hide NPCs",            value = "allNPCs",      selected = Settings.get("allNPCs") },
        { text = "Hide Local Player",    value = "localPlayer",  selected = Settings.get("localPlayer") },
        { text = "Hide Other Players",   value = "otherPlayers", selected = Settings.get("otherPlayers") },
        { text = "Hide Spiders",   value = "spiders", selected = Settings.get("spiders") },
    }, {
        onChange = function(_, _, changedValue, selected)
            updateSettings(changedValue, selected)
        end,
    })
end

local function createInputFields(window)
    window:AddTitle("Custom Inputs")
    window:AddText({
        text = "Supports text selection, copy, and paste"
    })
    window:AddText({
        text = "Input RSNs separated by commas"
    })
    window:AddTextField({
        placeholder = "player1,player2,player3,durial321",
        onSubmit = function(_,text)
            updateCustomRSNs(text)
        end,
    })
    window:AddText({
        text = "Input NPC names separated by commas"
    })
    window:AddTextField({
        placeholder = "Coeden,Strange Old Man,Clan Representative",
        onSubmit = function(_,text)
            updateCustomNPCs(text)
        end,
    })
    window:AddText({
        text = "Input familiar names separated by commas"
    })
    window:AddTextField({
        placeholder = "Kal'gerion demon,Devout Yak",
        onSubmit = function(_,text)
            updateCustomFamiliars(text)
        end,
    })
end

function gallery.Build(onCloseHandler)
    onClose = onCloseHandler
    if toggleGUI ~= nil then return true end

    local gameArea = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__GAME_AREA)
    if gameArea == nil then return false end

    toggleGUI = createDemoWindow(gameArea)

    createWindow(toggleGUI)
    createToggles(toggleGUI)
    createInputFields(toggleGUI)

    return true
end

function updateCustomRSNs(text)
    Settings.update("customRSNs", text)
end

function updateCustomNPCs(text)
    Settings.update("customNPCs", text)
end

function updateCustomFamiliars(text)
    Settings.update("customFamiliars", text)
end

function updateSettings(settingsKey, value)
    Settings.update(settingsKey, value)
end

function gallery.Show()
    if toggleGUI then toggleGUI:Show() end
end

function gallery.Close()
    if toggleGUI then toggleGUI:Close() end
end

function gallery.Destroy()
    -- Destroy the roots we own; child components are destroyed with them.
    if toggleGUI then toggleGUI:Destroy() end

    -- Release retained component handles.
    toggleOptions = nil
    onClose = nil
    toggleGUI = nil
end

return gallery
