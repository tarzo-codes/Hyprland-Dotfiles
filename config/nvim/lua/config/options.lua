-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

-- Detect Light vs Dark mode automatically from system / quickshell cache
local cache_file = os.getenv("HOME") .. "/.cache/quickshell/is_light_mode"
local f = io.open(cache_file, "r")
if f then
  local content = f:read("*all")
  f:close()
  if content:find("true") then
    vim.o.background = "light"
  else
    vim.o.background = "dark"
  end
else
  vim.o.background = "dark"
end
