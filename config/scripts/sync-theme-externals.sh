
# Neovim Dynamic Light/Dark Mode Adaptation
if [ "$IS_LIGHT" = "true" ]; then
    NVIM_BG="light"
else
    NVIM_BG="dark"
fi

for sock in /run/user/1000/nvim.*.0 ~/.cache/nvim/server.pipe; do
    if [ -S "$sock" ]; then
        nvim --server "$sock" --remote-send "<Cmd>set background=$NVIM_BG<CR><Cmd>colorscheme neopywal<CR>" 2>/dev/null || true
    fi
done

# Vicinae Dynamic Theme Update
vicinae theme set custom 2>/dev/null || true
