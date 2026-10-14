local uiutils = {}
local Settings = require("settings")
function uiutils.updateCustomRSNs(text)
    Settings.update("customRSNs", text)
end

function uiutils.updateCustomNPCs(text)
    Settings.update("customNPCs", text)
end

function uiutils.updateCustomFamiliars(text)
    Settings.update("customFamiliars", text)
end

function uiutils.updateSettings(settingsKey, value)
    Settings.update(settingsKey, value)
end
return uiutils