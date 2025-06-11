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


function cports
    set ip_address "127.0.0.1"
    echo "Scanning ports on $ip_address..."
    rustscan -a $ip_address -r 1-65535 --ulimit 65535 $extra_args | grep "open"
end

function initdocker
    argparse 's/start' 'm/minimal' -- $argv
    or return

    echo 'FROM debian:bookworm-slim' > Dockerfile
    echo 'RUN apt-get update && apt-get install -y fish git curl ca-certificates build-essential procps file --no-install-recommends && apt-get clean && rm -rf /var/lib/apt/lists/*' >> Dockerfile
    echo 'ARG USER_UID=1000' >> Dockerfile
    echo 'ARG USER_GID=$USER_UID' >> Dockerfile
    echo 'RUN groupadd --gid $USER_GID docker-dev && useradd --uid $USER_UID --gid $USER_GID -m docker-dev && chsh -s /usr/bin/fish docker-dev' >> Dockerfile
    echo 'WORKDIR /home/docker-dev' >> Dockerfile
    echo 'COPY . .config/fish' >> Dockerfile
    echo 'RUN chown -R docker-dev:docker-dev .config' >> Dockerfile
    echo 'USER docker-dev' >> Dockerfile
    echo 'ENV SHELL=/usr/bin/fish' >> Dockerfile
    if set -q _flag_minimal
        echo 'ENV PATH="/home/docker-dev/.linuxbrew/bin:/home/docker-dev/.linuxbrew/sbin:${PATH}"' >> Dockerfile
    else
        echo 'ENV PATH="/home/docker-dev/.linuxbrew/bin:/home/docker-dev/.linuxbrew/sbin:/home/docker-dev/.cargo/bin:${PATH}"' >> Dockerfile
        echo 'RUN curl --proto '\''=https'\'' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y' >> Dockerfile
    end
    echo 'RUN git clone https://github.com/Homebrew/brew.git /home/docker-dev/.linuxbrew' >> Dockerfile
    if set -q _flag_minimal
        echo 'RUN /home/docker-dev/.linuxbrew/bin/brew install zoxide' >> Dockerfile
    else
        echo 'RUN /home/docker-dev/.linuxbrew/bin/brew install thefuck zoxide' >> Dockerfile
    end
    echo 'RUN mkdir -p .config/fish/conf.d && echo '\''eval "$(/home/docker-dev/.linuxbrew/bin/brew shellenv)"'\'' > .config/fish/conf.d/brew.fish' >> Dockerfile
    echo 'SHELL ["/usr/bin/fish", "-l", "-c"]' >> Dockerfile
    echo 'CMD ["fish"]' >> Dockerfile
    echo "================================================"
    echo "🚀 Dockerfile created successfully."
    echo "================================================"
    echo "#!/bin/bash" > start.sh
    echo "docker rm -f fish-dev 2>/dev/null || true" >> start.sh
    echo "docker build --network=host --no-cache -t fish-dev -f Dockerfile \"\$HOME/.config/fish\"" >> start.sh
    echo "docker run -it --rm fish-dev" >> start.sh
    chmod +x start.sh
    echo "================================================"
    echo "🚀 docker starting script created successfully."
    echo "================================================"
    if set -q _flag_start
        echo "🚀 Starting docker container..."
        ./start.sh
    end
end
