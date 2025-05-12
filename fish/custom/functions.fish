# ============================= GitHub Commands ===============================
# Create a public GitHub repository
function ghpu
    set repo_name $argv[1]
    
    # If no repository name provided, use current directory name
    if test -z "$repo_name"
        set repo_name (basename (pwd))
    end
    
    echo "Creating public repository: $repo_name"
    
    # Initialize and push to GitHub
    git init || return 1
    
    # Create public repository on GitHub (requires GitHub CLI)
    if command -sq gh
        gh repo create $repo_name --public --source=. --remote=origin || return 1
    else
        # Fallback if GitHub CLI is not available
        git remote add origin https://github.com/isaaclins/$repo_name.git || return 1
        echo "Note: Install GitHub CLI (gh) for better repository creation experience"
    end
    
    # Check if directory is empty
    set file_count (ls -A | wc -l | string trim)
    if test "$file_count" = "1" -a -d ".git"
        # Only .git directory exists - create README
        echo "# $repo_name " > README.md
    end
    
    git add . || return 1
    
    # Check if there are changes to commit
    if git status --porcelain | grep -q "^[MADRCU]"
        git commit -m "Initial commit" || return 1
    else
        # Create an empty commit if there are no files to commit
        git commit --allow-empty -m "Initial commit" || return 1
    end
    
    # Get current branch name
    set current_branch (git branch --show-current)
    if test -z "$current_branch"
        set current_branch "main" # Default to main if branch name can't be determined
    end
    
    git push -u origin $current_branch || return 1
    
    return 0
end

# Create a private GitHub repository
function ghpr
    set repo_name $argv[1]
    
    # If no repository name provided, use current directory name
    if test -z "$repo_name"
        set repo_name (basename (pwd))
    end
    
    echo "Creating private repository: $repo_name"
    
    # Initialize and push to GitHub
    git init || return 1
    
    # Create private repository on GitHub (requires GitHub CLI)
    if command -sq gh
        gh repo create $repo_name --private --source=. --remote=origin || return 1
    else
        # Fallback if GitHub CLI is not available
        git remote add origin https://github.com/isaaclins/$repo_name.git || return 1
        echo "Note: Install GitHub CLI (gh) for better repository creation experience"
    end
    
    # Check if directory is empty
    set file_count (ls -A | wc -l | string trim)
    if test "$file_count" = "1" -a -d ".git"
        # Only .git directory exists - create README
        echo "# $repo_name " > README.md
    end
    
    git add . || return 1
    
    # Check if there are changes to commit
    if git status --porcelain | grep -q "^[MADRCU]"
        git commit -m "Initial commit" || return 1
    else
        # Create an empty commit if there are no files to commit
        git commit --allow-empty -m "Initial commit" || return 1
    end
    
    # Get current branch name
    set current_branch (git branch --show-current)
    if test -z "$current_branch"
        set current_branch "main" # Default to main if branch name can't be determined
    end
    
    git push -u origin $current_branch || return 1
    
    return 0
end

# Git Random Commit 
function grc 
    git commit -m (curl -s https://whatthecommit.com/index.txt)
end

# Git Random Push
function grp
    git add .
    git commit -m (curl -s https://whatthecommit.com/index.txt)
    git push origin (git branch --show-current)
end

# Create a new public project
function npu
    set original_dir (pwd)
    set success 1
    
    cd ~/Documents/github/ || return 1
    
    if test -d $argv[1]
        echo "Error: Directory $argv[1] already exists"
        cd $original_dir
        return 1
    end
    
    mkdir $argv[1] && cd $argv[1] || begin
        echo "Error: Failed to create directory $argv[1]"
        cd $original_dir
        return 1
    end
    
    if not ghpu
        echo "Error: Repository creation failed. Cleaning up..."
        cd $original_dir
        rm -rf ~/Documents/github/$argv[1]
        
        # If the repo was created on GitHub but local setup failed, try to delete it
        if command -sq gh
            gh repo delete isaaclins/$argv[1] --yes 2>/dev/null
        end
        
        return 1
    end
    
    echo "Project successfully created: $argv[1]"
    
    # Open Cursor IDE at the current directory
    if command -sq cursor
        cursor .
    else
        # Try alternative methods
        if command -sq open
            open -a Cursor .
        end
    end
    
    return 0
end

# Create a new private project
function npr
    set original_dir (pwd)
    set success 1
    
    cd ~/Documents/github/ || return 1
    
    if test -d $argv[1]
        echo "Error: Directory $argv[1] already exists"
        cd $original_dir
        return 1
    end
    
    mkdir $argv[1] && cd $argv[1] || begin
        echo "Error: Failed to create directory $argv[1]"
        cd $original_dir
        return 1
    end
    
    if not ghpr
        echo "Error: Repository creation failed. Cleaning up..."
        cd $original_dir
        rm -rf ~/Documents/github/$argv[1]
        
        # If the repo was created on GitHub but local setup failed, try to delete it
        if command -sq gh
            gh repo delete isaaclins/$argv[1] --yes 2>/dev/null
        end
        
        return 1
    end
    
    echo "Project successfully created: $argv[1]"
    
    # Open Cursor IDE at the current directory
    if command -sq cursor
        cursor .
    else
        # Try alternative methods
        if command -sq open
            open -a Cursor .
        end
    end
    
    return 0
end

function kp
    if test (count $argv) -eq 0
        echo "Usage: kp <port>"
        return 1
    end

    set port $argv[1]
    set pids (lsof -ti tcp:$port)

    if test -z "$pids"
        echo "No process found using port $port."
        return 0
    end

    for pid in $pids
        echo "Killing process $pid using port $port..."
        kill -9 $pid
    end
end

function grcp 
    git commit -m (curl -s https://whatthecommit.com/index.txt)
    git push origin (git branch --show-current)
end

function copy
    pbcopy
    echo "Copied to clipboard"
end
