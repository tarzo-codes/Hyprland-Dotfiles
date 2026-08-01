local monitors = {
    "DP-4,1920x1080@60,1920x0,1",
    "HDMI-A-4,1920x1080@60,0x0,1"
}

for _, mon in ipairs(monitors) do
    os.execute("hyprctl eval 'monitor = " .. mon .. "' >/dev/null 2>&1")
end
