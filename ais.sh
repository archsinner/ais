#!/bin/bash

# Display a welcome message using ncurses
dialog --title "Welcome" --msgbox "Thanks for using archsinner's install script. This script installs a minimal suckless desktop, enjoy!" 10 40

# Function to check and install dependencies
check_install_dependencies() {
    local dependencies=(base-devel libx11 libxft xorg-server xorg-xinit terminus-font dialog libxinerama)
    local missing_dependencies=()
    
    for dep in "${dependencies[@]}"; do
        if ! pacman -Q "$dep" &>/dev/null; then
            missing_dependencies+=("$dep")
        fi
    done
    
    if [[ ${#missing_dependencies[@]} -gt 0 ]]; then
        # Install missing dependencies
        dialog --title "Installing dependencies" --gauge "Installing required dependencies..." 10 50 0
        sudo pacman -Sy "${missing_dependencies[@]}"
    fi
}

# Check and install Git if not installed
if ! command -v git &> /dev/null; then
    dialog --infobox "Git is not installed. Installing..." 0 0
    sudo pacman -S git
fi

# Check and install Vim if not installed
if ! command -v vim &> /dev/null; then
    dialog --infobox "Vim is not installed. Installing..." 0 0
    sudo pacman -S vim
fi

# Install dependencies
check_install_dependencies

# Create ~/.local/src directory if it doesn't exist
mkdir -p ~/.local/src

# Clone the repositories
repos=(dwm st slstatus dmenu surf slock)
total_repos=${#repos[@]}
index=0

for repo in "${repos[@]}"; do
    ((index++))
    dialog --title "Cloning repository $repo ($index/$total_repos)" --infobox "Cloning $repo repository..." 5 50
    git clone "https://github.com/archsinner/$repo.git" "$HOME/.local/src/$repo"
done

# Compile and install each program
for repo in "${repos[@]}"; do
    dialog --title "Installing $repo" --infobox "Installing $repo..." 5 50
    (cd "$HOME/.local/src/$repo" && make && sudo make install)
done

# Display completion message
dialog --msgbox "Suckless software installation completed!" 10 40

# Exit
clear