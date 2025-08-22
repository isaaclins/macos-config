# ============================= Useful Abbreviations ================================



# System utilities
abbr -a ll 'ls -lhG'
abbr -a l 'ls -A'
abbr -a fid 'ls | grep'

# Reload config
abbr -a reload 'source ~/.config/fish/config.fish && clear && echo (set_color green)"⟳ RELOADED" (set_color normal)'
abbr -a r 'source ~/.config/fish/config.fish && clear && echo (set_color green)"⟳ RELOADED" (set_color normal)'

# Fast reload (aliases and functions only)
abbr -a fr 'source ~/.config/fish/custom/alias.fish && source ~/.config/fish/custom/functions.fish && echo (set_color green)"⟳ FAST RELOAD" (set_color normal)'

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
    
    # Open config
    abbr -a conf 'cursor ~/.config/fish/'
    abbr -a cur "cursor ."
    
    # Navigation shortcuts
    abbr -a .. 'z ..'
    abbr -a ... 'z ../..'
    abbr -a .... 'z ../../..'
    
    # Docker
    abbr -a ldk 'lazydocker'
    abbr -a dstop 'docker stop $(docker ps -q)' 
    abbr -a dkill 'docker stop $(docker ps -q) | docker system prune -a --volumes -f'
    
    # Zoxide
    abbr -a cd 'z'
    abbr -a cdd 'z -'
    
    # Git tools
    abbr -a lg 'lazygit'
    
    # System tools
    abbr -a cat 'bat'
    abbr -a rcool 'source ~/.config/fish/config.fish && clear && neofetch'
    
    # Development
    abbr -a nrd 'npm run dev'
    abbr -a nrs 'npm run start'
    abbr -a venv 'source venv/bin/activate.fish'
    
    # Spicetify
    abbr -a spot 'spicetify restore backup apply && spicetify apply'
    
    # The Fuck (initialize once and set alias)
    if command -sq thefuck
        thefuck --alias | source
        abbr -a f 'fuck'
    end
    
    # FZF with preview
    if command -sq fzf; and command -sq bat
        abbr -a fzf 'fzf --preview "bat --style=numbers --color=always --line-range :500 {}"'
    end
end





