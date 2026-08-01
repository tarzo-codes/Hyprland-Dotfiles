if status is-interactive
    # Commands to run in interactive sessions can go here
    fish_add_path ~/.local/bin
    fastfetch

    starship init fish | source

    # FZF Tab Completions with Live File & Directory Previews
    set -gx FZF_DEFAULT_OPTS "--height 50% --layout=reverse --border --margin=1 --padding=1 --color=bg+:#1e1e2e,bg:#11111b,spinner:#f5e0dc,hl:#f38ba8 --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 --preview-window=right:55%:wrap"
    set -gx FZF_CTRL_T_OPTS "--preview 'eza --tree --level=2 --color=always {} 2>/dev/null || bat --color=always --line-range :100 {} 2>/dev/null || cat {}'"
    set -gx FZF_ALT_C_OPTS "--preview 'eza --tree --level=2 --color=always {}'"

    # FZF key bindings integration
    if type -q fzf_key_bindings
        fzf_key_bindings
    end
end
