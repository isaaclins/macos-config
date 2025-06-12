# ============================= Useful Abbreviations ================================



# System utilities
abbr -a ll 'ls -lhG'
abbr -a l 'ls -A'


# Reload config
abbr -a reload 'source ~/.config/fish/config.fish && clear && echo (set_color green)"⟳ RELOADED" (set_color normal)'
abbr -a r 'source ~/.config/fish/config.fish && clear && echo (set_color green)"⟳ RELOADED" (set_color normal)'

# Clear screen
abbr -a c 'clear'


# ============================= Useful Abbreviations - full ================================

if test "$USER" != "docker-dev"
# Git shortcuts
abbr -a gs 'git status'
abbr -a gp 'git push'
abbr -a ga 'git add '
abbr -a gaa 'git add .'
abbr -a gpll 'git pull'

# open config
abbr -a conf 'cursor ~/.config/fish/'

abbr -a cur "cursor ."

# The Fuck
thefuck --alias | source
abbr -a f 'fuck'

# Navigation shortcuts
abbr -a .. 'z ..'
abbr -a ... 'z ../..'
abbr -a .... 'z ../../..'

# Docker
abbr -a ldk 'lazydocker'

# Zoxide
abbr -a cd 'z'
abbr -a cdd 'z -'

# Lazygit
abbr -a lg 'lazygit'  

# Neofetch
abbr -a rcool 'source ~/.config/fish/config.fish && clear  && neofetch'

# spicetify
abbr -a spot 'spicetify restore backup apply & spicetify backup apply'

# fzf
abbr -a f 'fzf --preview "bat --style=numbers --color=always --line-range :500 {}"'

# bat4cat
abbr -a cat 'bat'

# venv
abbr -a venv 'source venv/bin/activate.fish'
end

if test "$USER" = "docker-dev"
    # The Fuck
    if command -sq thefuck
        thefuck --alias | source
        abbr -a f 'fuck'
    end

    # bat -> cat
    if command -sq bat
        abbr -a cat 'bat'
    end

    # Lazygit
    if command -sq lazygit
        abbr -a lg 'lazygit'
    end
end
