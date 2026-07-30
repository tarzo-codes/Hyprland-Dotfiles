if status is-interactive
    # Commands to run in interactive sessions can go here
    fish_add_path ~/.local/bin
    fastfetch

    starship init fish | source
end
