local gallery = {}
local Settings = require("Settings")

local DEMO_WIDTH = 240
local DEMO_HEIGHT = 430

-- Main gallery surfaces.
local toggleGUI = nil
local onClose = nil

-- Component handles retained by the demo.
local toggleOptions = nil

-- Build our primary window
local function createDemoWindow(gameArea)
    return prettyui.Window.new(gameArea, {
        title = "Entity Hider",
        x = 20,
        y = 20,
        xAnchor = 0,
        yAnchor = 0,
        width = DEMO_WIDTH,
        height = DEMO_HEIGHT,
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
    local globalToggle = window:AddCheckboxButton({
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
    }, {
        onChange = function(_, _, changedValue, selected)
            updateSettings(changedValue, selected)
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

    toggleGUI:AddDivider({
        marginTop = 1,
        marginBottom = 1
    })

    toggleGUI:AddText({ text = "Created by Rcm37", colour = 0xAFA27FFF, marginTop = 1, marginBottom = 2 })
    toggleGUI:AddText({ text = "Using PrettyUI 0.1.0", colour = 0xAFA27FFF, marginTop = 1, marginBottom = 2 })

    return true
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
