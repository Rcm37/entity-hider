local EntityHider = require("entity_hider")
local RightClickHider = require("right_click_hider")
local ContentPane = require("interface/content")
local SettingsPane = require("interface/settings")
local Settings = require("settings")

Settings.Start()
EntityHider.Start()
RightClickHider.Start()
ContentPane.Start()
SettingsPane.Start()

function PluginShutdown()
    SettingsPane.Shutdown()
    ContentPane.Shutdown()
    RightClickHider.Shutdown()
    EntityHider.Shutdown()
    Settings.Shutdown()
end
