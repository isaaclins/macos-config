# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                      🐠 Fish Shell Configuration 🐠                       ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

# ============================= General Settings ===============================
if status is-interactive
    # Commands to run in interactive sessions can go here
    set fish_greeting # Disable greeting
    
    # Set colors for ls command
    set -gx LSCOLORS gxfxcxdxbxegedabagacad
    
    # Enable syntax highlighting in less
    set -gx LESS_TERMCAP_mb \e'[1;31m'
    set -gx LESS_TERMCAP_md \e'[1;36m'
    set -gx LESS_TERMCAP_me \e'[0m'
    set -gx LESS_TERMCAP_so \e'[01;44;33m'
    set -gx LESS_TERMCAP_se \e'[0m'
    set -gx LESS_TERMCAP_us \e'[1;32m'
    set -gx LESS_TERMCAP_ue \e'[0m'
end

# ============================== Custom Prompt ================================
function fish_prompt
    set_color -o cyan
    echo -n "┌─["
    
    # Username@hostname
    set_color -o yellow
    echo -n (whoami)
    set_color normal
    set_color -o white
    echo -n "@"
    set_color -o blue
    echo -n (hostname | cut -d. -f1)
    
    # Current directory
    set_color -o cyan
    echo -n "]─["
    set_color -o magenta
    echo -n (basename (pwd))
    set_color -o cyan
    echo -n "]"
    
    # Git status if applicable
    if command -sq git; and git rev-parse --is-inside-work-tree &>/dev/null
        set_color -o cyan
        echo -n "─["
        set_color -o green
        echo -n (git branch --show-current 2>/dev/null)
        set_color -o cyan
        echo -n "]"
    end
    
    # Time
    set_color -o cyan
    echo -n "─["
    set_color -o white
    echo -n (date "+%H:%M:%S")
    set_color -o cyan
    echo -n "]"
    
    # Time it took to run the last command
    set_color -o cyan
    echo -n "─["
    set_color -o cyan
    printf "%.0fms" (math "$CMD_DURATION /1.0") # Convert to milliseconds, remove the x.000ms
    set_color -o cyan
    echo -n "]"



    # Command prompt
    echo
    set_color -o cyan
    echo -n "└─"
    
    # User indicator
    if fish_is_root_user
        set_color -o red
        echo -n "# "
    else
        set_color -o cyan
        echo -n "⫸ "
    end
    
    set_color normal
end

# ============================= Source Files ================================
source ~/.config/fish/custom/alias.fish
source ~/.config/fish/custom/functions.fish
