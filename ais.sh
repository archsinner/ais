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

# Prompt user for username and password
dialog --inputbox "Enter a username:" 10 40 2> /tmp/username.txt
dialog --passwordbox "Enter a password:" 10 40 2> /tmp/password.txt
dialog --passwordbox "Confirm password:" 10 40 2> /tmp/password_confirm.txt

# Read username and passwords from temporary files
USERNAME=$(cat /tmp/username.txt)
PASSWORD=$(cat /tmp/password.txt)
PASSWORD_CONFIRM=$(cat /tmp/password_confirm.txt)

# Check if passwords match
if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
    dialog --msgbox "Passwords do not match. Please try again." 10 40
    exit 1
fi

# Check if the user already exists
if id "$USERNAME" &>/dev/null; then
    dialog --infobox "User $USERNAME already exists. Deleting..." 0 0
    sudo userdel -r "$USERNAME"
fi

# Create the new user
sudo useradd -m -U "$USERNAME"

# Set the password for the new user
echo "$USERNAME:$PASSWORD" | sudo chpasswd

# Clean up temporary files
rm /tmp/username.txt /tmp/password.txt /tmp/password_confirm.txt

# Create .local/src directory in user's home directory
sudo -u "$USERNAME" mkdir -p ~/"$USERNAME"/.local/src

# Clone the repositories
repos=(dwm st slstatus dmenu surf slock)
total_repos=${#repos[@]}
index=0

for repo in "${repos[@]}"; do
    ((index++))
    dialog --title "Cloning repository $repo ($index/$total_repos)" --infobox "Cloning $repo repository..." 5 50
    sudo -u "$USERNAME" git clone "https://github.com/archsinner/$repo.git" "/home/$USERNAME/.local/src/$repo"
done

# Compile and install each program
for repo in "${repos[@]}"; do
    dialog --title "Installing $repo" --infobox "Installing $repo..." 5 50
    (cd "/home/$USERNAME/.local/src/$repo" && sudo -u "$USERNAME" make && sudo make install)
done

# Display completion message
dialog --msgbox "Suckless software installation completed!" 10 40

# Exit
clear