local Settings = require("settings")

local Menu = {}

local WIDTH = 760
local HEIGHT = 560
local LEFT = 20
local ROW_HEIGHT = 30
local LABEL_COLOR = 0xD8D8D8
local ACCENT_COLOR = 0xFFAA00
local DRAG_MOVE_THRESHOLD = 4
local PICKER_WIDTH = 316
local PICKER_HEIGHT = 448

Menu.WIDTH = WIDTH
Menu.HEIGHT = HEIGHT

local function safeNumber(value, fallback)
    if type(value) == "number" then
        return value
    elseif type(value) == "string" then
        local parsed = tonumber(value)
        if parsed ~= nil then
            return parsed
        end
    end
    return fallback or 0
end

local function clampByte(value)
    local n = math.floor(safeNumber(value, 0))
    if n < 0 then
        return 0
    elseif n > 255 then
        return 255
    end
    return n
end

local function hexToRGB(hex)
    local normalized = Settings.NormalizeHex(hex, "FFFFFF")
    local value = tonumber(normalized, 16) or 0xFFFFFF
    return math.floor(value / 65536) % 256, math.floor(value / 256) % 256, value % 256
end

local function rgbToHex(red, green, blue)
    return string.format("%02X%02X%02X", clampByte(red), clampByte(green), clampByte(blue))
end

local function hexToVector(hex, alpha)
    local red, green, blue = hexToRGB(hex)
    return Vector4.new(red / 255, green / 255, blue / 255, alpha or 1.0)
end

local function safeButtonStyle()
    if id ~= nil and id.StyleSheet ~= nil and id.StyleSheet.BUTTON_DEFAULT ~= nil then
        return id.StyleSheet.BUTTON_DEFAULT
    end
    return nil
end

local function safePanelStyle()
    if id ~= nil and id.StyleSheet ~= nil and id.StyleSheet.GROUPBOX_CONTENT_PANEL ~= nil then
        return id.StyleSheet.GROUPBOX_CONTENT_PANEL
    end
    return nil
end

local function safeFont()
    if id ~= nil and id.Font ~= nil and id.Font.MUSEO_SANS_15PT_REGULAR ~= nil then
        return id.Font.MUSEO_SANS_15PT_REGULAR
    end
    return nil
end

local function setStyle(component, style)
    if component ~= nil and style ~= nil then
        pcall(function()
            component.stylesheetID = style
        end)
    end
end

local function setRGB(component, rgb)
    if component ~= nil and rgb ~= nil then
        pcall(function()
            component.rgb = rgb
        end)
    end
end

local function setPanelOpacity(panel, value)
    local alpha = Settings.ClampInt(value, 30, 100, 70) / 100
    pcall(function()
        panel.alpha = alpha
    end)
    pcall(function()
        panel.colour = Vector4.new(0.02, 0.11, 0.14, alpha)
    end)
    pcall(function()
        panel.rgba = Settings.RGBA("061B22", alpha)
    end)
end

local function setRectangleColor(component, hex, alpha)
    if component == nil then
        return
    end

    pcall(function()
        component.colour = hexToVector(hex, alpha or 1.0)
    end)
    pcall(function()
        component.rgba = Settings.RGBA(hex or "FFFFFF", alpha or 1.0)
    end)
    pcall(function()
        component.rgb = tonumber(Settings.NormalizeHex(hex, "FFFFFF"), 16) or 0xFFFFFF
    end)
end

local function moveToFront(component)
    if component ~= nil then
        pcall(function()
            component:MoveToFront()
        end)
    end
end

local function newPanel(parent)
    if ui.GroupBox ~= nil then
        return ui.GroupBox.new(parent)
    end
    return ui.Panel.new(parent)
end

local function addRect(parent, x, y, width, height, hex, fill)
    local rect = nil
    if ui.Rectangle ~= nil then
        rect = ui.Rectangle.new(parent)
    else
        rect = ui.Panel.new(parent)
    end
    rect:SetPos(x, y)
    rect:SetSize(width, height)
    rect.clickthrough = false
    pcall(function()
        rect.fill = fill ~= false
    end)
    setRectangleColor(rect, hex or "FFFFFF", 1.0)
    moveToFront(rect)
    return rect
end

local function addText(parent, text, x, y, width, height, rgb, interactive)
    local label = ui.Text.new(parent)
    label:SetPos(x, y)
    label:SetSize(width, height)
    label.clickthrough = interactive ~= true
    local font = safeFont()
    if font ~= nil then
        label.font = font
    end
    label.content = text
    setRGB(label, rgb or LABEL_COLOR)
    moveToFront(label)
    return label
end

local function componentText(component, fallback)
    if component == nil then
        return fallback or ""
    end

    local paths = {
        { "content" },
        { "value" },
        { "text", "content" }
    }

    for _, path in ipairs(paths) do
        local ok, value = pcall(function()
            local current = component
            for _, part in ipairs(path) do
                current = current[part]
                if current == nil then
                    return nil
                end
            end
            return current
        end)
        if ok and value ~= nil then
            return tostring(value)
        end
    end

    return fallback or ""
end

local function setComponentText(component, value)
    local text = tostring(value or "")
    pcall(function()
        component.content = text
    end)
    pcall(function()
        component.value = text
    end)
    pcall(function()
        component.text.content = text
    end)
end

local function addButton(parent, text, x, y, width, height, onPress)
    local button = ui.Button.new(parent)
    setStyle(button, safeButtonStyle())
    button:SetPos(x, y)
    button:SetSize(width, height)
    button.clickthrough = false
    button.text.content = text
    button:Subscribe(ui.Hook.ONBUTTONPRESSED, function()
        if onPress ~= nil then
            onPress()
        end
        return true
    end)
    moveToFront(button)
    return button
end

local function addCheck(parent, value, x, y, onChange)
    local state = {
        value = value and true or false
    }

    local check = ui.Button.new(parent)
    setStyle(check, safeButtonStyle())
    check:SetPos(x, y)
    check:SetSize(28, 24)
    check.clickthrough = false
    check.text.content = state.value and "x" or ""
    check:Subscribe(ui.Hook.ONBUTTONPRESSED, function()
        state.value = not state.value
        check.text.content = state.value and "x" or ""
        if onChange ~= nil then
            onChange()
        end
        return true
    end)
    moveToFront(check)

    return {
        component = check,
        get = function()
            return state.value
        end,
        set = function(nextValue)
            state.value = nextValue and true or false
            check.text.content = state.value and "x" or ""
        end
    }
end

local function addPercentSlider(parent, value, x, y, width, height, onChange)
    local state = {
        value = Settings.ClampInt(value, 30, 100, 70)
    }

    local minus = ui.Button.new(parent)
    setStyle(minus, safeButtonStyle())
    minus:SetPos(x, y)
    minus:SetSize(24, height)
    minus.clickthrough = false
    minus.text.content = "-"

    local plus = ui.Button.new(parent)
    setStyle(plus, safeButtonStyle())
    plus:SetPos(x + width - 24, y)
    plus:SetSize(24, height)
    plus.clickthrough = false
    plus.text.content = "+"

    local trackX = x + 30
    local trackWidth = width - 60
    addRect(parent, trackX, y + math.floor(height / 2) - 2, trackWidth, 4, "1A1A1A", true)
    local fill = addRect(parent, trackX, y + math.floor(height / 2) - 2, 1, 4, "FFAA00", true)
    local thumbWidth = 44
    local thumb = ui.Button.new(parent)
    setStyle(thumb, safeButtonStyle())
    thumb:SetSize(thumbWidth, height)
    thumb.clickthrough = false

    local function redraw()
        local ratio = (state.value - 30) / 70
        if ratio < 0 then
            ratio = 0
        elseif ratio > 1 then
            ratio = 1
        end
        fill:SetSize(math.max(1, math.floor(trackWidth * ratio)), 4)
        thumb:SetPos(trackX + math.floor((trackWidth - thumbWidth) * ratio), y)
        thumb.text.content = tostring(state.value) .. "%"
    end

    local function setValue(nextValue)
        state.value = Settings.ClampInt(nextValue, 30, 100, state.value)
        redraw()
        if onChange ~= nil then
            onChange()
        end
    end

    minus:Subscribe(ui.Hook.ONBUTTONPRESSED, function()
        setValue(state.value - 5)
        return true
    end)
    plus:Subscribe(ui.Hook.ONBUTTONPRESSED, function()
        setValue(state.value + 5)
        return true
    end)
    thumb:Subscribe(ui.Hook.ONBUTTONPRESSED, function()
        setValue(state.value + 5)
        return true
    end)

    moveToFront(minus)
    moveToFront(plus)
    moveToFront(thumb)
    redraw()

    return {
        component = thumb,
        get = function()
            return state.value
        end,
        set = function(nextValue)
            state.value = Settings.ClampInt(nextValue, 30, 100, state.value)
            redraw()
        end
    }
end

local function eventXY(...)
    local count = select("#", ...)
    if count < 2 then
        return 0, 0
    end

    local mouseY = safeNumber(select(count, ...), 0)
    local mouseX = safeNumber(select(count - 1, ...), 0)
    return mouseX, mouseY
end

local function copySettings(settings)
    local copied = {}
    for key, value in pairs(settings or {}) do
        copied[key] = value
    end
    return copied
end

function Menu.Read(menu)
    if menu == nil then
        return nil
    end

    local nextSettings = copySettings(menu.baseSettings)
    for key, control in pairs(menu.controls or {}) do
        if control.get ~= nil then
            nextSettings[key] = control.get()
        end
    end
    return Settings.Normalize(nextSettings)
end

function Menu.Mount(parent, settings, onApply, onClose)
    if parent == nil then
        return nil
    end

    local menu = {
        component = nil,
        baseSettings = Settings.Normalize(settings),
        controls = {},
        dragCapture = nil,
        destroy = nil
    }

    local activePicker = nil
    local render = nil

    local function closeColorPicker()
        if activePicker ~= nil and activePicker.root ~= nil then
            activePicker.root:Destroy()
        end
        activePicker = nil
    end

    local function destroyDragCapture()
        if menu.dragCapture ~= nil then
            menu.dragCapture:Destroy()
            menu.dragCapture = nil
        end
    end

    local function destroyPanel()
        closeColorPicker()
        destroyDragCapture()
        if menu.component ~= nil then
            menu.component:Destroy()
            menu.component = nil
        end
    end

    menu.destroy = destroyPanel

    local function readAndStore()
        local nextSettings = Menu.Read(menu)
        if nextSettings ~= nil then
            menu.baseSettings = nextSettings
        end
        return menu.baseSettings
    end

    local cancelActiveDrag = function() end

    local function apply(persistNow)
        cancelActiveDrag()
        local nextSettings = readAndStore()
        if onApply ~= nil then
            onApply(nextSettings, persistNow)
        end
    end

    render = function()
        destroyPanel()

        local normalized = Settings.Normalize(menu.baseSettings)
        menu.baseSettings = normalized
        menu.controls = {}

        local panelX = normalized.menuX
        local panelY = normalized.menuY
        local panel = newPanel(parent)
        setStyle(panel, safePanelStyle())
        panel:SetPos(panelX, panelY)
        panel:SetSize(WIDTH, HEIGHT)
        panel.clickthrough = false
        setPanelOpacity(panel, normalized.menuOpacity)
        moveToFront(panel)
        menu.component = panel

        local function movePanel(x, y)
            panelX = Settings.ClampInt(x, 0, 3000, panelX)
            panelY = Settings.ClampInt(y, 0, 3000, panelY)
            panel:SetPos(panelX, panelY)
            menu.baseSettings.menuX = panelX
            menu.baseSettings.menuY = panelY
        end

        local drag = {
            active = false,
            holding = false,
            clicking = false,
            moved = false,
            startMouseX = 0,
            startMouseY = 0,
            startPanelX = panelX,
            startPanelY = panelY,
            clickMouseX = nil,
            clickMouseY = nil,
            offsetX = 0,
            offsetY = 0,
            capture = nil
        }
        local dragStop = nil
        local dragMove = nil

        local function destroyDragCapture()
            if drag.capture ~= nil then
                drag.capture:Destroy()
                drag.capture = nil
            end
            menu.dragCapture = nil
        end

        local function currentMouse(offsetX, offsetY, ...)
            if Mouse ~= nil and Mouse.GetPosition ~= nil then
                local ok, mousePos = pcall(function()
                    return Mouse.GetPosition()
                end)
                if ok and mousePos ~= nil then
                    local mouseX = tonumber(mousePos.x or mousePos.X)
                    local mouseY = tonumber(mousePos.y or mousePos.Y)
                    if mouseX ~= nil and mouseY ~= nil then
                        return mouseX, mouseY
                    end
                end
            end

            if Mouse ~= nil and Mouse.GetX ~= nil and Mouse.GetY ~= nil then
                local ok, mouseX, mouseY = pcall(function()
                    return Mouse.GetX(), Mouse.GetY()
                end)
                if ok and mouseX ~= nil and mouseY ~= nil then
                    return tonumber(mouseX), tonumber(mouseY)
                end
            end

            local mouseX, mouseY = eventXY(...)
            return panelX + (offsetX or 0) + mouseX, panelY + (offsetY or 0) + mouseY
        end

        local function moveFromScreen(mouseX, mouseY)
            movePanel(mouseX - drag.offsetX, mouseY - drag.offsetY)
        end

        local function resetDragFlags()
            drag.active = false
            drag.holding = false
            drag.clicking = false
            drag.moved = false
            drag.clickMouseX = nil
            drag.clickMouseY = nil
        end

        local function markClickGuard(offsetX, offsetY, ...)
            local mouseX, mouseY = currentMouse(offsetX or 0, offsetY or 0, ...)
            drag.clicking = true
            drag.holding = false
            drag.active = false
            drag.moved = false
            drag.clickMouseX = mouseX
            drag.clickMouseY = mouseY
        end

        local function dragDistance(mouseX, mouseY, fromX, fromY)
            local dx = math.abs((tonumber(mouseX) or 0) - (tonumber(fromX) or 0))
            local dy = math.abs((tonumber(mouseY) or 0) - (tonumber(fromY) or 0))
            return dx, dy
        end

        local function clickGuardActive(mouseX, mouseY)
            if not drag.clicking then
                return false
            end

            local dx, dy = dragDistance(mouseX, mouseY, drag.clickMouseX, drag.clickMouseY)
            if dx > DRAG_MOVE_THRESHOLD or dy > DRAG_MOVE_THRESHOLD then
                drag.clicking = false
                drag.clickMouseX = nil
                drag.clickMouseY = nil
                return false
            end
            return true
        end

        local function dragEnabled()
            if menu.controls.dragEnabled ~= nil then
                return menu.controls.dragEnabled.get() == true
            end
            return menu.baseSettings.dragEnabled == true
        end

        local function persistDragPosition()
            local nextSettings = readAndStore()
            nextSettings.menuX = panelX
            nextSettings.menuY = panelY
            menu.baseSettings = Settings.Normalize(nextSettings)
            if onApply ~= nil then
                onApply(menu.baseSettings, false)
            end
        end

        local function createDragCapture()
            destroyDragCapture()

            local capture = ui.Button.new(parent)
            setStyle(capture, safePanelStyle())
            capture:SetPos(0, 0)
            capture:SetSize(0, 0, 1.0, 1.0)
            capture.clickthrough = false
            capture.text.content = " "
            pcall(function()
                capture.alpha = 0
            end)
            pcall(function()
                capture.rgba = 0x00000000
            end)
            pcall(function()
                capture.colour = Vector4.new(0, 0, 0, 0)
            end)
            moveToFront(capture)

            capture:Subscribe(ui.Hook.ONCLICK, function()
                return dragStop()
            end)
            capture:Subscribe(ui.Hook.ONBUTTONPRESSED, function()
                return true
            end)
            capture:Subscribe(ui.Hook.ONHOLD, function(...)
                drag.holding = true
                return dragMove(0, 0, ...)
            end)
            capture:Subscribe(ui.Hook.ONDRAG, function(...)
                drag.holding = true
                return dragMove(0, 0, ...)
            end)
            capture:Subscribe(ui.Hook.ONRELEASE, function()
                return dragStop()
            end)
            capture:Subscribe(ui.Hook.ONDRAGCOMPLETE, function()
                return dragStop()
            end)

            drag.capture = capture
            menu.dragCapture = capture
        end

        local function dragStart(offsetX, offsetY, ...)
            if not dragEnabled() then
                resetDragFlags()
                destroyDragCapture()
                return true
            end
            if drag.active then
                return true
            end

            local mouseX, mouseY = currentMouse(offsetX, offsetY, ...)
            if clickGuardActive(mouseX, mouseY) then
                return true
            end

            drag.active = true
            drag.holding = true
            drag.moved = false
            drag.startMouseX = mouseX
            drag.startMouseY = mouseY
            drag.startPanelX = panelX
            drag.startPanelY = panelY
            drag.offsetX = mouseX - panelX
            drag.offsetY = mouseY - panelY
            createDragCapture()
            return true
        end

        dragMove = function(offsetX, offsetY, ...)
            if not dragEnabled() then
                resetDragFlags()
                destroyDragCapture()
                return true
            end

            local mouseX, mouseY = currentMouse(offsetX, offsetY, ...)
            if clickGuardActive(mouseX, mouseY) then
                return true
            end

            drag.holding = true
            if not drag.active then
                return dragStart(offsetX, offsetY, ...)
            end

            local dx, dy = dragDistance(mouseX, mouseY, drag.startMouseX, drag.startMouseY)
            if not drag.moved and dx < DRAG_MOVE_THRESHOLD and dy < DRAG_MOVE_THRESHOLD then
                return true
            end

            drag.moved = true
            moveFromScreen(mouseX, mouseY)
            return true
        end

        dragStop = function()
            if not drag.active then
                resetDragFlags()
                destroyDragCapture()
                return true
            end

            local didMove = drag.moved
            resetDragFlags()
            destroyDragCapture()
            if didMove then
                persistDragPosition()
            end
            return true
        end

        cancelActiveDrag = function()
            markClickGuard(0, 0)
            destroyDragCapture()
        end

        local function configureDragTarget(target, offsetX, offsetY)
            target:Subscribe(ui.Hook.ONCLICK, function(...)
                markClickGuard(offsetX, offsetY, ...)
                return true
            end)
            target:Subscribe(ui.Hook.ONBUTTONPRESSED, function(...)
                markClickGuard(offsetX, offsetY, ...)
                return true
            end)
            target:Subscribe(ui.Hook.ONHOLD, function(...)
                drag.holding = true
                return dragMove(offsetX, offsetY, ...)
            end)
            target:Subscribe(ui.Hook.ONDRAG, function(...)
                drag.holding = true
                return dragStart(offsetX, offsetY, ...)
            end)
            target:Subscribe(ui.Hook.ONRELEASE, dragStop)
            target:Subscribe(ui.Hook.ONDRAGCOMPLETE, dragStop)
        end

        configureDragTarget(panel, 0, 0)

        local title = addText(panel, "EntityHider", LEFT, 8, 220, 24, ACCENT_COLOR, true)
        configureDragTarget(title, LEFT, 8)

        local activeTab = Settings.NormalizeChoice(normalized.activeTab, Settings.OPTIONS.activeTab, "General")
        menu.controls.activeTab = {
            get = function()
                return activeTab
            end,
            set = function(nextValue)
                activeTab = Settings.NormalizeChoice(nextValue, Settings.OPTIONS.activeTab, activeTab)
            end
        }

        local function selectTab(tab)
            if tab == activeTab then
                return true
            end

            local nextSettings = readAndStore()
            nextSettings.activeTab = tab
            menu.baseSettings = Settings.Normalize(nextSettings)
            if onApply ~= nil then
                onApply(menu.baseSettings, false)
            end
            render()
            return true
        end

        local tabY = 36
        local tabGap = 6
        local tabWidth = 52
        local tabHeight = 30
        for index, tab in ipairs(Settings.OPTIONS.activeTab) do
            local tabX = LEFT + (index - 1) * (tabWidth + tabGap)
            local button = ui.Button.new(panel)
            setStyle(button, safeButtonStyle())
            button:SetPos(tabX, tabY)
            button:SetSize(tabWidth, tabHeight)
            button.clickthrough = false
            button.text.content = tostring(index)
            pcall(function()
                button.label = tostring(index)
            end)
            button:Subscribe(ui.Hook.ONBUTTONPRESSED, function()
                return selectTab(tab)
            end)
            button:Subscribe(ui.Hook.ONCLICK, function()
                return selectTab(tab)
            end)
            moveToFront(button)
        end

        local leftX = LEFT
        local pageWidth = WIDTH - LEFT * 2
        local y = 82
        local inputOffset = 132
        local inputWidth = pageWidth - inputOffset

        local function sectionTitle(label)
            addText(panel, label, leftX, y + 4, pageWidth, 22, ACCENT_COLOR)
            y = y + ROW_HEIGHT
        end

        local function boolRow(key, label)
            addText(panel, label, leftX, y + 4, pageWidth - 42, 22, LABEL_COLOR)
            menu.controls[key] = addCheck(panel, normalized[key], leftX + pageWidth - 30, y, function()
                apply(false)
            end)
            y = y + ROW_HEIGHT
        end

        local function opacityRow(key, label)
            addText(panel, label, leftX, y + 4, inputOffset - 8, 22, LABEL_COLOR)
            menu.controls[key] = addPercentSlider(panel, normalized[key], leftX + inputOffset, y, inputWidth, 24, function()
                local nextSettings = readAndStore()
                setPanelOpacity(panel, nextSettings.menuOpacity)
                if onApply ~= nil then
                    onApply(nextSettings, false)
                end
            end)
            y = y + ROW_HEIGHT
        end

        if activeTab == "Toggles" then
            sectionTitle("Toggles")
            boolRow("enabled", "Enabled")
            boolRow("conjures", "Conjures")
            boolRow("drakePets", "Drake Pets")
            boolRow("allFamiliars", "All Familiars")
            boolRow("allNPCs", "All NPCs")
            boolRow("localPlayer", "Local Player")
            boolRow("otherPlayers", "Other Players")
            y = y + 50
            boolRow("dragEnabled", "Drag menu")
            opacityRow("menuOpacity", "Menu opacity")
        elseif activeTab == "Custom NPCs" then
            sectionTitle("Custom NPCs - NOT FUNCTIONAL")
        elseif activeTab == "Custom Players" then
            sectionTitle("Custom Players - NOT FUNCTIONAL")
        end

        local bottomY = HEIGHT - 44
        local bottomGap = 8
        local bottomButtonWidth = math.floor((WIDTH - LEFT * 2 - bottomGap) / 2)
        addButton(panel, "Reset", LEFT, bottomY, bottomButtonWidth, 24, function()
            menu.baseSettings = Settings.Defaults()
            if onApply ~= nil then
                onApply(menu.baseSettings, true)
            end
            render()
        end)
        addButton(panel, "Close", LEFT + bottomButtonWidth + bottomGap, bottomY, bottomButtonWidth, 24, function()
            if onClose ~= nil then
                onClose()
            end
        end)
    end

    render()
    return menu
end

function Menu.Destroy(menu)
    if menu == nil then
        return
    end
    if menu.destroy ~= nil then
        menu.destroy()
        return
    end
    if menu.component ~= nil then
        menu.component:Destroy()
    end
end

return Menu
