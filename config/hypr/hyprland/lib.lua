-- Hyprland Helper Library (end4 architecture)

hyprctl = function(cmd)
    os.execute("hyprctl " .. cmd .. " >/dev/null 2>&1")
end

dispatch = function(dispatcher, arg)
    if arg and arg ~= "" then
        hyprctl("dispatch " .. dispatcher .. " " .. arg)
    else
        hyprctl("dispatch " .. dispatcher)
    end
end

exec_once = function(cmd)
    os.execute(cmd .. " >/dev/null 2>&1 &")
end

set_env = function(k, v)
    os.execute("export " .. k .. "=\"" .. v .. "\"")
end
