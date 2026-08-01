-- Hyprland Main Lua Entry Point (end4 dotfiles architecture)
-- Sources framework libraries in `hyprland` folder and user overrides in `custom` folder

HOME = os.getenv("HOME")
package.path = HOME .. "/.config/hypr/?.lua;" .. HOME .. "/.config/hypr/?/init.lua;" .. package.path

function is_file_exists(path)
    local f = io.open(path, "r")
    if f then
        io.close(f)
        return true
    else
        return false
    end
end

-- Internal libraries & helpers
require("hyprland.lib")
require("hyprland.services")

-- Environment variables
require("hyprland.env")
if is_file_exists(HOME .. "/.config/hypr/custom/env.lua") then
    require("custom.env")
end

-- Core configurations
require("hyprland.execs")
require("hyprland.general")
require("hyprland.rules")
require("hyprland.colors")
require("hyprland.keybinds")

-- Custom user overrides
if is_file_exists(HOME .. "/.config/hypr/custom/execs.lua") then
    require("custom.execs")
end
if is_file_exists(HOME .. "/.config/hypr/custom/general.lua") then
    require("custom.general")
end
if is_file_exists(HOME .. "/.config/hypr/custom/rules.lua") then
    require("custom.rules")
end
if is_file_exists(HOME .. "/.config/hypr/custom/keybinds.lua") then
    require("custom.keybinds")
end

-- Monitor & Workspace overrides
if is_file_exists(HOME .. "/.config/hypr/monitors.lua") then
    require("monitors")
end
if is_file_exists(HOME .. "/.config/hypr/workspaces.lua") then
    require("workspaces")
end
