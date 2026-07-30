-- Main Hyprland Lua Configuration Entry Point (Hyprland 0.56+)
-- See https://wiki.hypr.land/Configuring/Start/ for documentation

package.path = os.getenv("HOME") .. "/.config/hypr/?.lua;" .. os.getenv("HOME") .. "/.config/hypr/?/init.lua;" .. os.getenv("HOME") .. "/.config/hypr/lua/?.lua;" .. package.path

require("lua.monitors")
require("lua.autostart")
require("lua.env")
require("lua.animations")
require("lua.appearance")
require("lua.keybinds")
require("lua.windowrules")
require("lua.misc")
