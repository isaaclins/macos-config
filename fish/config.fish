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
function _prompt_user_info
    # Username@hostname with appropriate colors
    if test "$USER" = "docker-dev"
        set_color -o red
    else
        set_color -o yellow
    end
    echo -n $USER
    set_color normal
    set_color -o white
    echo -n "@"
    set_color -o blue
    echo -n (hostname | cut -d. -f1)
end

function _prompt_directory
    # Current directory
    set_color -o cyan
    echo -n "]─["
    set_color -o magenta
    echo -n (basename (pwd))
    set_color -o cyan
    echo -n "]"
end

function _prompt_git_status
    # Git status if applicable (cached for performance)
    if command -sq git; and git rev-parse --is-inside-work-tree &>/dev/null
        set_color -o cyan
        echo -n "─["
        set_color -o green
        # Cache git branch to avoid repeated calls
        if not set -q __fish_git_branch_cache; or test (math (date +%s) - $__fish_git_branch_time) -gt 5
            set -g __fish_git_branch_cache (git branch --show-current 2>/dev/null)
            set -g __fish_git_branch_time (date +%s)
        end
        echo -n $__fish_git_branch_cache
        set_color -o cyan
        echo -n "]"
    end
end

function _prompt_time_info
    # Time
    set_color -o cyan
    echo -n "─["
    set_color -o white
    echo -n (date "+%H:%M:%S")
    set_color -o cyan
    echo -n "]"
    
    # Command duration (only show if > 100ms to reduce noise)
    if test $CMD_DURATION -gt 100
        set_color -o cyan
        echo -n "─["
        set_color -o cyan
        printf "%.0fms" (math "$CMD_DURATION / 1.0")
        set_color -o cyan
        echo -n "]"
    end
end

function _prompt_user_indicator
    # User indicator
    if test "$USER" = "docker-dev"
        set_color -o red
        echo -n "⫸ "
    else
        if fish_is_root_user
            set_color -o red
            echo -n "# "
        else
            set_color -o cyan
            echo -n "⫸ "
        end
    end
end

function fish_prompt
    # Top line
    set_color -o cyan
    echo -n "┌─["
    
    _prompt_user_info
    _prompt_directory
    _prompt_git_status
    _prompt_time_info
    
    # Bottom line
    echo
    set_color -o cyan
    echo -n "└─"
    
    _prompt_user_indicator
    set_color normal
end


# ============================= Source Files (if in test mode, only source barebones files)================================

# Add custom scripts directory to PATH first
set -l custom_scripts_dir (dirname (status --current-filename))/custom/scripts

# IF IN TEST MODE, SOURCE JUST NECESSARY FILES. IGNORE RUSTSCAN, JAVA, AND OTHER TOOLS.
if test "$USER" != "docker-dev"
    if not contains "$custom_scripts_dir" $fish_user_paths
        set -U fish_user_paths "$custom_scripts_dir" $fish_user_paths
    end
    
    # Source Rust environment if available
    if test -f "$HOME/.cargo/env.fish"
        source "$HOME/.cargo/env.fish"
    end
    
    source ~/.config/fish/custom/alias.fish
    source ~/.config/fish/custom/functions.fish
    
    # Initialize zoxide if available
    if command -sq zoxide
        zoxide init fish | source
    end
else
    echo "🚀 Test mode is enabled. Only sourcing BareBones files..."
    clear
    source ~/.config/fish/custom/alias.fish
    source ~/.config/fish/custom/functions.fish
end

# Created by `pipx` on 2025-06-16 20:28:54
set PATH $PATH /Users/isaaclins/.local/bin
