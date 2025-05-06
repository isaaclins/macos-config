# ============================= Useful Abbreviations ================================
# Navigation shortcuts
abbr -a .. 'cd ..'
abbr -a ... 'cd ../..'
abbr -a .... 'cd ../../..'

# Git shortcuts
abbr -a gs 'git status'
abbr -a gp 'git push'
abbr -a ga 'git add '
abbr -a gaa 'git add .'
abbr -a gpll 'git pull'
# System utilities
abbr -a ls 'ls -G'
abbr -a ll 'ls -lhG'
abbr -a la 'ls -lahG'

# open config
abbr -a config 'cursor ~/.config/fish/'

abbr -a cur "cursor ."

# Reload config
abbr -a reload 'source ~/.config/fish/config.fish && clear && echo (set_color green)"Config reloaded" (set_color normal)'
abbr -a r 'source ~/.config/fish/config.fish && clear && echo (set_color green)"Config reloaded" (set_color normal)'

# Clear screen
abbr -a c 'clear'

# The Fuck
thefuck --alias | source
abbr -a f 'fuck'




