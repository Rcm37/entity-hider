-- Run from entity-hider: lua tests/right_click_hider_test.lua
local checks = 0
local function expect(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    checks = checks + 1
end

local subscriptions = {}
local subscribeCalls = {}
local function event(name)
    subscriptions[name] = {}
    return {
        Subscribe = function(key, callback)
            subscribeCalls[name] = (subscribeCalls[name] or 0) + 1
            subscriptions[name][key] = callback
        end,
        Unsubscribe = function(key) subscriptions[name][key] = nil end,
    }
end
Event = {}
for _, name in ipairs({ "Logic", "EntityDraw", "MiniMenuReady", "ContentLayerReady", "SettingsLayerReady" }) do
    Event[name] = event(name)
end
local function emit(name, payload)
    for _, callback in pairs(subscriptions[name]) do callback(payload) end
end

EntityType = { PLAYER = 1, NPC = 2 }
MiniMenuEntryType = { NPC = 4, PLAYER = 7, SELF = 8, LOC = 3, PLUGIN = 10 }
id = { NPC = setmetatable({}, { __index = function(_, key) return key end }) }
PlayerList = { Self = function() return { displayName = "Local Player" } end }
local trackingAllowed, trackingID = false, "character-a"
PluginPermissions = { trackingAccess = {} }
Plugin = { HasPermission = function(permission)
    assert(permission == PluginPermissions.trackingAccess, "permission enum value required")
    return trackingAllowed
end }
Player = { IsAvailable = function() return true end, GetTrackingID = function() return trackingID end }
local controlDown, shiftDown = false, false
Keyboard = {
    IsControlDown = function() return controlDown end,
    IsShiftDown = function() return shiftDown end,
}
local saved = {}
PersistentDB = {
    GetBool = function(_, key) return saved[key] end,
    GetString = function(_, key) return saved[key] end,
    SetBool = function(_, key, value) saved[key] = value end,
    SetString = function(_, key, value) saved[key] = value end,
}

-- UI doubles exercise pane updates, callbacks, reopening, and destruction.
local views = {}
prettyui = { SimpleView = { new = function()
    local view = { text = {}, fields = {}, buttons = {}, checkboxes = {} }
    function view:AddTitle() end
    function view:AddComboBox(options)
        local combo = { entries = options.entries, selectedID = options.selectedID }
        function combo:SetEntries(entries, selectedID)
            self.entries, self.selectedID = entries, selectedID
        end
        function combo:SetDisabled(disabled) self.disabled = disabled end
        function combo:Select(selectedID, triggerEvents)
            self.selectedID = selectedID
            if triggerEvents then options.onChange(self, selectedID) end
        end
        self.combo = combo
        return combo
    end
    function view:AddDivider() end
    function view:AddCheckboxButton(items, options)
        local group = {}
        for _, item in ipairs(items) do
            self.checkboxes[item.value] = { selected = item.selected, onChange = options.onChange }
        end
        function group:SetSelected(value, selected)
            view.checkboxes[value].selected = selected
        end
        function group:SetDisabled(disabled)
            for _, item in ipairs(items) do view.checkboxes[item.value].disabled = disabled end
        end
        return group
    end
    function view:AddText(options)
        local text = { content = type(options) == "table" and options.text or options }
        self.text[#self.text + 1] = text
        return text
    end
    function view:AddSimpleButton(label, action, options)
        local button = { action = action, disabled = options.disabled }
        function button:SetDisabled(disabled) self.disabled = disabled end
        self.buttons[label] = button
        return button
    end
    function view:AddTextField(options)
        local field = { text = options.text, onChange = options.onChange }
        function field:SetText(text) self.text = text end
        function field:SetDisabled(disabled) self.disabled = disabled end
        self.fields[#self.fields + 1] = field
        return field
    end
    function view:Destroy() self.destroyed = true end
    views[#views + 1] = view
    return view
end } }

local modules = {
    require("entity_hider"), require("right_click_hider"),
    require("interface/content"), require("interface/settings"),
}
for name, callbacks in pairs(subscriptions) do
    expect(next(callbacks), nil, "requiring modules does not subscribe to " .. name)
end
local Settings = require("settings")
Settings.update("enabled", false)
dofile("main.lua")
expect(next(subscriptions.EntityDraw), nil, "saved disabled state skips draw subscription")
expect(next(subscriptions.MiniMenuReady), nil, "saved disabled state skips menu subscription")
expect(next(subscriptions.ContentLayerReady) ~= nil, true, "disabled startup retains content UI")
expect(next(subscriptions.SettingsLayerReady) ~= nil, true, "disabled startup retains settings UI")
Settings.update("enabled", true)
local Hider = require("right_click_hider")
local draw = subscriptions.EntityDraw["entity-hider-entity-draw"]
local function npc(name, familiar)
    return { isValid = true, displayName = name, config = { id = "ordinary", isFamiliar = familiar or false } }
end
local function player(name)
    return { isValid = true, displayName = name }
end
local function entry(entity, isPlayer)
    if isPlayer then return { actionEntryType = MiniMenuEntryType.PLAYER, playerData = { entity = entity } } end
    return { actionEntryType = MiniMenuEntryType.NPC, npcData = { entity = entity } }
end
local function menu(entries)
    local result = { entries = entries, added = {} }
    function result:Add(label, action, ...)
        local args = { ... }
        self.added[#self.added + 1] = { label = label, click = function() action(unpack(args)) end }
        self.entries[#self.entries + 1] = { actionEntryType = MiniMenuEntryType.PLUGIN }
    end
    emit("MiniMenuReady", { miniMenu = result })
    return result
end
local function shownNPC(entity)
    return draw({ entityType = EntityType.NPC, npcEntity = entity })
end
local function shownPlayer(entity)
    return draw({ entityType = EntityType.PLAYER, playerEntity = entity })
end
local parent = { component = { width = 400, height = 600 } }
emit("ContentLayerReady", parent)
local content = views[#views]
local status = content.text[2]
local undo = content.buttons["Undo Last Hide"]
expect(status.content, "Most recently hidden: None", "initial status")
expect(undo.disabled, true, "initial undo disabled")
expect(Hider.Undo(), false, "nothing to undo")
emit("SettingsLayerReady", parent)
local settingsPane = views[#views]

Settings.update("customNPCs", "Other")
local guard, yak, otherPlayer = npc("Guard"), npc("Yak", true), player("Other\194\160Player")
local modifierToggle = content.checkboxes.rightClickRequireCtrlShift
expect(modifierToggle.selected, false, "modifier requirement defaults off")
modifierToggle.onChange(nil, nil, "rightClickRequireCtrlShift", true)
expect(saved.entity_hider_rightClickRequireCtrlShift, true, "modifier requirement saved through UI")
local modifierEntries = { entry(guard), entry(otherPlayer, true) }
expect(#menu(modifierEntries).added, 0, "no modifiers omits hide options")
controlDown = true
expect(#menu(modifierEntries).added, 0, "control alone omits hide options")
controlDown, shiftDown = false, true
expect(#menu(modifierEntries).added, 0, "shift alone omits hide options")
controlDown = true
local modifiedMenu = menu(modifierEntries)
expect(#modifiedMenu.added, 2, "both modifiers show NPC and player hide options")
controlDown, shiftDown = false, false
modifiedMenu.added[1].click()
expect(shownNPC(guard), false, "releasing modifiers after menu construction permits selection")
undo.action()
emit("ContentLayerReady", parent)
content = views[#views]
status = content.text[2]
undo = content.buttons["Undo Last Hide"]
expect(content.checkboxes.rightClickRequireCtrlShift.selected, true, "reopened pane restores modifier requirement")
content.checkboxes.rightClickRequireCtrlShift.onChange(nil, nil, "rightClickRequireCtrlShift", false)
expect(saved.entity_hider_rightClickRequireCtrlShift, false, "modifier requirement can be disabled")
local choices = menu({ entry(guard), entry(guard), entry(npc("Guard")), entry(yak), entry(otherPlayer, true) })
expect(#choices.added, 3, "deduplicate by saved name and category")
expect(choices.added[1].label, "Hide Guard (Entity Hider)", "menu label")
expect(shownNPC(guard), true, "menu construction does not hide")
guard.isValid = false -- The menu callback uses its captured name, not stale userdata.
choices.added[1].click()
guard.isValid = true
expect(Settings.get("customNPCs"), "Other, Guard", "append NPC name")
expect(saved.entity_hider_customNPCs, "Other, Guard", "persist NPC name")
expect(settingsPane.fields[3].text, "Other, Guard", "settings field refreshed")
expect(shownNPC(npc("Guard")), false, "hide all NPCs sharing name")
expect(status.content, "Most recently hidden: Guard (NPC)", "live NPC status")
expect(undo.disabled, false, "undo enabled")
local enableToggle = content.checkboxes.enabled.onChange
enableToggle(nil, nil, "enabled", false)
expect(next(subscriptions.EntityDraw), nil, "disable unsubscribes draw events")
expect(next(subscriptions.MiniMenuReady), nil, "disable unsubscribes menu events")
expect(next(subscriptions.ContentLayerReady) ~= nil, true, "disable keeps content UI subscribed")
expect(next(subscriptions.SettingsLayerReady) ~= nil, true, "disable keeps settings UI subscribed")
expect(Hider.GetLastHidden(), "Guard", "disable preserves undo target")
expect(undo.disabled, false, "disable preserves undo button")
enableToggle(nil, nil, "enabled", true)
expect(next(subscriptions.EntityDraw) ~= nil, true, "reenable restores draw subscription")
expect(next(subscriptions.MiniMenuReady) ~= nil, true, "reenable restores menu subscription")
expect(shownNPC(guard), false, "reenable preserves hidden names")
local drawSubscriptions, menuSubscriptions = subscribeCalls.EntityDraw, subscribeCalls.MiniMenuReady
Settings.update("enabled", true)
expect(subscribeCalls.EntityDraw, drawSubscriptions, "repeated enable does not resubscribe draw")
expect(subscribeCalls.MiniMenuReady, menuSubscriptions, "repeated enable does not resubscribe menu")
expect(#menu({ entry(guard) }).added, 0, "skip already hidden name")
choices.added[1].click()
expect(Settings.get("customNPCs"), "Other, Guard", "repeated callback does not duplicate")

-- Undo removes its own addition, retaining subsequent manual edits.
Settings.update("customNPCs", "Other, Guard, New NPC")
undo.action()
expect(Settings.get("customNPCs"), "Other, New NPC", "undo preserves subsequent edits")
expect(settingsPane.fields[3].text, "Other, New NPC", "undo refreshes settings")
expect(shownNPC(guard), true, "undo restores visibility")
expect(undo.disabled, true, "undo consumed")
expect(status.content, "Most recently hidden: None", "undo clears status")

choices.added[2].click()
expect(Settings.get("customFamiliars"), "Yak", "familiar saved to separate list")
expect(shownNPC(yak), false, "familiar hidden")
expect(status.content, "Most recently hidden: Yak (Familiar / pet)", "familiar status")
choices.added[3].click()
expect(Settings.get("customRSNs"), "Other Player", "normalize saved player name")
expect(shownPlayer(otherPlayer), false, "player hidden with normalized name")
expect(status.content, "Most recently hidden: Other Player (Player)", "player status")
expect(settingsPane.fields[2].text, "Other Player", "player field refreshed")
undo.action()
expect(shownPlayer(otherPlayer), true, "undo player hiding")
expect(shownNPC(yak), false, "undo only latest addition")

Settings.update("customRSNs", "  OTHER PLAYER  ")
expect(#menu({ entry(otherPlayer, true) }).added, 0, "case and whitespace duplicate detection")
Settings.update("customRSNs", "")
local invalid = npc("Gone")
invalid.isValid = false
expect(#menu({ entry(invalid), { actionEntryType = MiniMenuEntryType.NPC },
    entry(player("Local Player"), true), { actionEntryType = MiniMenuEntryType.LOC },
    entry(npc("Comma, Name")) }).added, 0, "skip invalid or unsupported targets")

-- Fishing spots bypass only the general toggle, retaining right-click hide/undo.
local fishingSpot = npc("Fishing spot")
Settings.update("allNPCs", true)
expect(shownNPC(fishingSpot), true, "general toggle leaves fishing spots visible")
local fishingMenu = menu({ entry(fishingSpot) })
expect(#fishingMenu.added, 1, "fishing spot retains right-click hide option")
fishingMenu.added[1].click()
expect(shownNPC(fishingSpot), false, "right-click hides fishing spot despite toggle exclusion")
expect(status.content, "Most recently hidden: Fishing spot (NPC)", "fishing spot hide updates status")
undo.action()
expect(shownNPC(fishingSpot), true, "undo restores fishing spot with general toggle on")
Settings.update("allNPCs", false)

-- Carpet pets use familiar lists even when the game reports isFamiliar=false.
local carpet = npc("Magic carpet")
carpet.config.id = id.NPC.MENAPHOS_MAGIC_CARPET_IMPERIAL
local carpetMenu = menu({ entry(carpet) })
expect(#carpetMenu.added, 1, "carpet has a hide option")
carpetMenu.added[1].click()
expect(Settings.get("customFamiliars"), "Yak, Magic carpet", "carpet saved to familiar list")
expect(Settings.get("customNPCs"), "Other, New NPC", "carpet leaves NPC list unchanged")
expect(shownNPC(carpet), false, "carpet hidden by familiar name")
expect(status.content, "Most recently hidden: Magic carpet (Familiar / pet)", "carpet uses familiar status")
undo.action()
expect(Settings.get("customFamiliars"), "Yak", "carpet undo restores familiar list")
expect(shownNPC(carpet), true, "carpet visible after undo")

for _, configName in ipairs({ "APRIL_FOOLS_2021_PET_NPC", "APRIL_FOOLS_2021_PET_NPC_POH" }) do
    local pet = npc("K'ril Psssutsaroth")
    pet.config.id = id.NPC[configName]
    local petMenu = menu({ entry(pet) })
    expect(#petMenu.added, 1, configName .. " has a hide option")
    petMenu.added[1].click()
    expect(Settings.get("customFamiliars"), "Yak, K'ril Psssutsaroth", configName .. " saved to familiar list")
    expect(Settings.get("customNPCs"), "Other, New NPC", configName .. " leaves NPC list unchanged")
    expect(shownNPC(pet), false, configName .. " hidden by familiar name")
    expect(status.content, "Most recently hidden: K'ril Psssutsaroth (Familiar / pet)", configName .. " uses familiar status")
    undo.action()
    expect(Settings.get("customFamiliars"), "Yak", configName .. " undo restores familiar list")
    expect(shownNPC(pet), true, configName .. " visible after undo")
end

-- Settings presets swap live filters and fields; the content pane has no preset controls.
local staleMenu = menu({ entry(guard) })
expect(content.combo, nil, "content pane has no preset dropdown")
expect(#settingsPane.combo.entries, 5, "settings offers five presets")
settingsPane.combo:Select(2, true)
expect(Settings.get("activePreset"), "2", "settings switches preset")
expect(settingsPane.fields[1].text, "Preset 2", "name field follows selection")
expect(settingsPane.fields[3].text, "", "NPC field follows selection")
expect(shownNPC(yak), true, "switch removes previous familiar filter")
expect(status.content, "Most recently hidden: None", "switch clears undo status")
expect(undo.disabled, true, "switch disables undo")
staleMenu.added[1].click()
expect(Settings.get("customNPCs"), "", "old menu cannot change another preset")
settingsPane.fields[1].onChange(nil, nil, "Skilling")
expect(settingsPane.combo.entries[2].label, "Skilling", "renaming updates settings dropdown")
settingsPane.fields[2].onChange(nil, nil, "Other Player")
settingsPane.fields[3].onChange(nil, nil, "Guard")
settingsPane.fields[4].onChange(nil, nil, "Magic carpet")
expect(shownNPC(guard), false, "preset NPC list filters immediately")
expect(shownPlayer(otherPlayer), false, "preset player list filters immediately")
expect(shownNPC(carpet), false, "preset familiar list filters immediately")
local presetHide = menu({ entry(npc("Preset NPC")) })
presetHide.added[1].click()
expect(Settings.get("customNPCs"), "Guard, Preset NPC", "right click adds to selected preset")
undo.action()
expect(Settings.get("customNPCs"), "Guard", "undo edits selected preset")
settingsPane.combo:Select(1, true)
expect(Settings.get("customNPCs"), "Other, New NPC", "preset 1 NPC list retained")
expect(Settings.get("customFamiliars"), "Yak", "preset 1 familiar list retained")
expect(settingsPane.fields[3].text, "Other, New NPC", "switch restores visible NPC field")
expect(shownNPC(guard), true, "switch refreshes NPC filter activity")
expect(shownPlayer(otherPlayer), true, "switch refreshes player filter activity")

-- Storage selection belongs to settings and rejects missing permission.
local storageToggle = settingsPane.checkboxes.playerSpecific
local storageControl = { SetSelected = function(_, _, selected) storageToggle.selected = selected end }
local allowed, message = pcall(storageToggle.onChange, storageControl, nil, "playerSpecific", true)
expect(allowed, false, "storage checkbox asserts permission")
expect(tostring(message):find("trackingAccess", 1, true) ~= nil, true, "permission assertion is actionable")
expect(Settings.get("playerSpecific"), false, "denied permission retains global storage")
expect(storageToggle.selected, false, "denied permission restores checkbox")
expect(content.checkboxes.playerSpecific, nil, "storage checkbox appears only in settings")
trackingAllowed = true
local globalMenu = menu({ entry(guard) })
storageToggle.onChange(storageControl, nil, "playerSpecific", true)
expect(storageToggle.selected, true, "storage checkbox enables character mode")
expect(Settings.get("customNPCs"), "", "new character starts with defaults")
expect(settingsPane.fields[3].text, "", "storage change refreshes custom fields")
globalMenu.added[1].click()
expect(Settings.get("customNPCs"), "", "stale global menu cannot modify character settings")
Settings.update("allNPCs", true)
Settings.update("customNPCs", "Character NPC")
trackingID = "character-b"
emit("Logic")
expect(Settings.get("allNPCs"), false, "other character has independent toggles")
expect(content.checkboxes.allNPCs.selected, false, "content toggles refresh on character switch")
trackingID = "character-a"
emit("Logic")
expect(Settings.get("allNPCs"), true, "returning character restores toggle")
expect(content.checkboxes.allNPCs.selected, true, "content shows restored character toggle")
expect(settingsPane.fields[3].text, "Character NPC", "settings shows restored character list")
trackingAllowed = false
emit("Logic")
expect(settingsPane.fields[3].disabled, true, "revoked permission disables list editing")
expect(settingsPane.combo.disabled, true, "revoked permission disables preset selection")
expect(content.checkboxes.allNPCs.disabled, true, "unavailable character disables content toggles")
expect(#menu({ entry(guard) }).added, 0, "unavailable character omits right-click hide")
trackingAllowed = true
emit("Logic")
expect(settingsPane.fields[3].disabled, false, "restored permission enables list editing")
expect(content.checkboxes.allNPCs.disabled, false, "restored permission enables toggles")
storageToggle.onChange(storageControl, nil, "playerSpecific", false)
expect(Settings.get("customNPCs"), "Other, New NPC", "turning off restores global list")
expect(content.checkboxes.allNPCs.selected, false, "turning off restores global toggles")

local pending = menu({ entry(guard) })
Settings.update("enabled", false)
expect(#menu({ entry(guard) }).added, 0, "disabled plugin omits menu entries")
pending.added[1].click()
expect(Settings.get("customNPCs"), "Other, New NPC", "disabled callback does not hide")
Settings.update("enabled", true)
pending.added[1].click()
Settings.update("allNPCs", true)
undo.action()
expect(shownNPC(guard), false, "undo respects other hide filters")
Settings.update("allNPCs", false)

-- Removing the name manually before undo must not clobber unrelated names.
pending.added[1].click()
Settings.update("customNPCs", "Manual Edit")
undo.action()
expect(Settings.get("customNPCs"), "Manual Edit", "undo after manual removal")

pending.added[1].click()
emit("ContentLayerReady", parent)
local reopened = views[#views]
expect(content.destroyed, true, "old content destroyed on reopen")
expect(reopened.text[2].content, "Most recently hidden: Guard (NPC)", "reopened pane shows latest hide")
expect(reopened.buttons["Undo Last Hide"].disabled, false, "reopened undo enabled")
emit("SettingsLayerReady", parent)
expect(settingsPane.destroyed, true, "old settings destroyed on reopen")
expect(views[#views].fields[3].text, "Manual Edit, Guard", "reopened fields use saved names")

PluginShutdown()
expect(reopened.destroyed, true, "content destroyed on shutdown")
expect(views[#views].destroyed, true, "settings destroyed on shutdown")
Settings.update("enabled", false)
Settings.update("enabled", true)
for name, callbacks in pairs(subscriptions) do
    expect(next(callbacks), nil, name .. " unsubscribed on shutdown")
end

-- Modules can stop before opening panes, stop twice, and start again.
PluginShutdown()
for _, module in ipairs(modules) do module.Start() end
emit("ContentLayerReady", parent)
local restarted = views[#views]
expect(restarted.text[2].content, "Most recently hidden: None", "restart clears session undo state")
emit("SettingsLayerReady", parent)
expect(views[#views].fields[3].text, "Manual Edit, Guard", "restart retains saved lists")
PluginShutdown()
expect(restarted.destroyed, true, "restarted pane cleaned up")
for _, module in ipairs(modules) do module.Start() end
PluginShutdown()
for name, callbacks in pairs(subscriptions) do
    expect(next(callbacks), nil, name .. " cleaned up without opening panes")
end
print("Right-click hiding: " .. checks .. " checks passed")
