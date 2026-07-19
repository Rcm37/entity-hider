local Settings = require("settings")
local Menu = require("interface/menu")
local Overlay = require("interface/overlay")

local EVENT_PREFIX = "entity_hider"
local MENU_WIDTH = Menu.WIDTH or 700
local MENU_HEIGHT = Menu.HEIGHT or 520

if EntityHider ~= nil and EntityHider.Stop ~= nil then
    EntityHider.Stop()
end

local state = {
    settings = Settings.Load(),
    overlay = nil,
    menu = nil,
    launcher = nil,
    parent = nil,
    lastMountAttemptTick = -999999,
    mountWarningLogged = false,
    elapsedSeconds = 0,
    pendingSave = false,
    saveAfterSeconds = 0
}

local openMenu
local toggleMenu
local menuControlSet


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

local function setStyle(component, style)
    if component ~= nil and style ~= nil then
        pcall(function()
            component.stylesheetID = style
        end)
    end
end

local function moveToFront(component)
    if component ~= nil then
        pcall(function()
            component:MoveToFront()
        end)
    end
end

local function safeGetDefaultParent()
    if ui == nil or ui.Interfaces == nil or id == nil or id.Component == nil then
        return nil
    end

    local candidates = {
        "TOPLEVEL_V2__GAME_AREA",
        "TOPLEVEL_V2__ROOT",
        "TOPLEVEL__GAME_AREA"
    }

    for _, key in ipairs(candidates) do
        local ok, componentID = pcall(function()
            return id.Component[key]
        end)

        if ok and componentID ~= nil then
            local foundOK, component = pcall(function()
                return ui.Interfaces:GetComponent(componentID)
            end)

            if foundOK and component ~= nil then
                return component
            end
        end
    end

    return nil
end

local function safeGetRootParent()
    return state.parent
end

local function settingsEqual(left, right)
    if left == right then
        return true
    end
    if left == nil or right == nil then
        return false
    end

    for key, value in pairs(left) do
        if right[key] ~= value then
            return false
        end
    end
    for key, value in pairs(right) do
        if left[key] ~= value then
            return false
        end
    end
    return true
end

local function destroyLauncher()
    if state.launcher ~= nil then
        state.launcher:Destroy()
        state.launcher = nil
    end
end

local function setTransparent(component)
    if component == nil then
        return
    end

    pcall(function()
        component.alpha = 0.01
    end)
    pcall(function()
        component.rgba = Settings.RGBA("000000", 0.01)
    end)
    pcall(function()
        component.colour = Settings.RGBA("000000", 0.01)
    end)
end

local function mountLauncher(parent)
    if state.launcher ~= nil or parent == nil then
        return
    end

    local button = ui.Button.new(parent)
    setStyle(button, safeButtonStyle())
    button:SetPos(8, 164)
    button:SetSize(88, 28)
    button.clickthrough = false
    button.text.content = "Menu UI"
    button:Subscribe(ui.Hook.ONBUTTONPRESSED, function()
        if toggleMenu ~= nil then
            toggleMenu()
        end
        return true
    end)

    state.launcher = button
end

local function flushPendingSave()
    if state.pendingSave then
        Settings.Save(state.settings)
        state.pendingSave = false
    end
end

local function saveSettings(nextSettings)
    state.settings = Settings.Normalize(nextSettings)
    if state.menu ~= nil then
        state.menu.baseSettings = Settings.Normalize(state.settings)
    end
    Settings.Save(state.settings)
    state.pendingSave = false
end

openMenu = function()
    if state.parent == nil or state.menu ~= nil then
        return
    end

    state.menu = Menu.Mount(state.parent, state.settings, function(nextSettings)
        saveSettings(nextSettings)
    end, function()
        if state.menu ~= nil then
            flushPendingSave()
            Menu.Destroy(state.menu)
            state.menu = nil
        end
    end)
end

toggleMenu = function()
    if state.menu ~= nil then
        flushPendingSave()
        Menu.Destroy(state.menu)
        state.menu = nil
        return
    end

    openMenu()
end

local function syncMenuSettings()
    if state.menu == nil or Menu.Read == nil then
        return
    end

    local ok, nextSettings = pcall(function()
        return Menu.Read(state.menu)
    end)

    if ok and nextSettings ~= nil and not settingsEqual(state.settings, nextSettings) then
        saveSettings(nextSettings)
    end
end

local function bringUiToFront()
    moveToFront(state.mouseFollowBlocker)
    moveToFront(state.launcher)
    if state.menu ~= nil then
        moveToFront(state.menu.component)
    end
end

local function mount(parent)
    if parent == nil then
        return false
    end

    state.parent = parent
    if state.overlay == nil then
        state.overlay = Overlay.Mount(safeGetRootParent() or parent)
    end
    mountLauncher(parent)
    moveToFront(state.launcher)
    return state.launcher ~= nil
end

local function tryAutoMount(logicTick)
    if state.launcher ~= nil then
        return
    end

    if logicTick - state.lastMountAttemptTick < 50 then
        return
    end

    state.lastMountAttemptTick = logicTick
    local parent = safeGetDefaultParent()
    if mount(parent) then
        log("EntityHider mounted")
    elseif not state.mountWarningLogged then
        state.mountWarningLogged = true
        log("EntityHider: could not find a default UI parent yet")
    end
end

local function onLogic(logicEvent)
    local tick = 0
    if logicEvent ~= nil and logicEvent.logicTick ~= nil then
        tick = logicEvent.logicTick
    end

    state.elapsedSeconds = state.elapsedSeconds + 0.02
    tryAutoMount(tick)
    syncMenuSettings()

    if state.pendingSave and state.elapsedSeconds >= state.saveAfterSeconds then
        flushPendingSave()
    end
end

local function onDraw()
    Overlay.Draw(state.overlay, state.settings)
    bringUiToFront()
end

local api = {}

function api.Mount(parent)
    return mount(parent)
end

function api.OpenMenu()
    openMenu()
end

function api.CloseMenu()
    if state.menu ~= nil then
        flushPendingSave()
        Menu.Destroy(state.menu)
        state.menu = nil
    end
end

function api.Unmount()
    api.CloseMenu()
    destroyLauncher()
    if state.overlay ~= nil then
        Overlay.Destroy(state.overlay)
        state.overlay = nil
    end
    state.parent = nil
end

function api.Stop()
    Event.Logic.Unsubscribe(EVENT_PREFIX .. "_logic")
    Event.Draw.Unsubscribe(EVENT_PREFIX .. "_draw")
    api.Unmount()
    flushPendingSave()
    Settings.Save(state.settings)
end

function api.GetState()
    return state
end

Event.Logic.Subscribe(EVENT_PREFIX .. "_logic", onLogic)
Event.Draw.Subscribe(EVENT_PREFIX .. "_draw", onDraw)

EntityHider = api
return api
