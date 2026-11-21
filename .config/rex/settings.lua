-- Rex.app look & feel. App settings live in the app, not init.lua, so apply with:
--   rex do ~/.config/rex/settings.lua
-- Needs Rex.app open with Remote Control on (Settings > Rex Server).
-- Always pass `value`: omitting it toggles or cycles the setting.

local set = rex.client.queue

set("client.theme.import", { path = os.getenv("HOME") .. "/.config/rex/catppuccin-mocha" })
set("client.theme.change", { name = "catppuccin-mocha" })
set("client.setting.interface.appearance.scheme", { value = "dark" })

set("client.setting.terminal.typography.font", { value = "FiraCode Nerd Font Mono" })
set("client.setting.terminal.typography.size", { value = 14 })
