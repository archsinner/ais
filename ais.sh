#!/bin/bash

# Display a welcome message using ncurses
dialog --title "Welcome" --msgbox "Thanks for using archsinner's install script. This script updates Arch Linux, installs a minimal suckless desktop, and sets up dotfiles, enjoy!" 10 70

# Update Arch Linux
dialog --infobox "Updating Arch Linux..." 0 0
sudo pacman -Syu --noconfirm

# Function to check and install dependencies
check_install_dependencies() {
    local dependencies=(libimlib2 xwallpaper base-devel libx11 libxft xorg-server xorg-xinit terminus-font dialog libxinerama xcompmgr webkit2gtk gcr exa wireplumber unclutter pipewire xdotool xcape)
    local missing_dependencies=()
    
    for dep in "${dependencies[@]}"; do
        if ! pacman -Q "$dep" &>/dev/null; then
            missing_dependencies+=("$dep")
        fi
    done
    
    if [[ ${#missing_dependencies[@]} -gt 0 ]]; then
        # Install missing dependencies
        dialog --title "Installing dependencies" --gauge "Installing required dependencies..." 10 70 0
        sudo pacman -Sy --noconfirm "${missing_dependencies[@]}"
    fi
}

# Check and install Git if not installed
if ! command -v git &> /dev/null; then
    dialog --infobox "Git is not installed. Installing..." 0 0
    sudo pacman -S --noconfirm git
fi

# Install dependencies
check_install_dependencies

# Prompt user for username and password
dialog --inputbox "Enter a username:" 10 70 2> /tmp/username.txt
dialog --passwordbox "Enter a password:" 10 70 2> /tmp/password.txt
dialog --passwordbox "Confirm password:" 10 70 2> /tmp/password_confirm.txt

# Read username and passwords from temporary files
USERNAME=$(cat /tmp/username.txt)
PASSWORD=$(cat /tmp/password.txt)
PASSWORD_CONFIRM=$(cat /tmp/password_confirm.txt)

# Check if passwords match
if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
    dialog --msgbox "Passwords do not match. Please try again." 10 70
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

# Remove original .local if it exists
if [ -d "/home/$USERNAME/.local" ]; then
    dialog --infobox "Removing original .local repository..." 5 70
    sudo -u "$USERNAME" rm -rf "/home/$USERNAME/.local/"
fi

# Create .local directory in user's home directory
sudo -u "$USERNAME" mkdir -p ~/"$USERNAME"/.local

# Create .local/src directory in user's home directory
sudo -u "$USERNAME" mkdir -p ~/"$USERNAME"/.local/src

# Create .local/bin directory in user's home directory
sudo -u "$USERNAME" mkdir -p ~/"$USERNAME"/.local/bin

# Prompt user for desktop or laptop usage
dialog --title "Desktop or Laptop?" --yesno "If you're using a laptop click yes, if desktop click no?" 10 70
response=$?

# Clone the appropriate slstatus repository based on user's choice
if [ $response -eq 0 ]; then
    # User selected desktop
    dialog --infobox "Cloning slstatus-desktop repository..." 5 70
    sudo -u "$USERNAME" git clone https://github.com/archsinner/slstatus-desktop.git /home/$USERNAME/.local/src/slstatus-desktop
    # Install slstatus-desktop
    dialog --infobox "Installing slstatus-desktop..." 5 70
    (cd "/home/$USERNAME/.local/src/slstatus-desktop" && sudo -u "$USERNAME" make && sudo make install)
else
    # User selected laptop
    dialog --infobox "Cloning slstatus-laptop repository..." 5 70
    sudo -u "$USERNAME" git clone https://github.com/archsinner/slstatus-laptop.git /home/$USERNAME/.local/src/slstatus-laptop
    # Install slstatus-laptop
    dialog --infobox "Installing slstatus-laptop..." 5 70
    (cd "/home/$USERNAME/.local/src/slstatus-laptop" && sudo -u "$USERNAME" make && sudo make install)
fi

# Remove original slstatus if it exists
if [ -d "/home/$USERNAME/.local/src/slstatus" ]; then
    dialog --infobox "Removing original slstatus repository..." 5 70
    sudo -u "$USERNAME" rm -rf "/home/$USERNAME/.local/src/slstatus"
fi

# Clone the remaining repositories
repos=(dwm st dmenu surf slock)
total_repos=${#repos[@]}
index=0

for repo in "${repos[@]}"; do
    ((index++))
    dialog --title "Cloning repository $repo ($index/$total_repos)" --infobox "Cloning $repo repository..." 5 70
    if [ "$repo" == "slock" ]; then
        sudo -u "$USERNAME" git clone "https://github.com/archsinner/slock-.git" "/home/$USERNAME/.local/src/slock"
    else
        sudo -u "$USERNAME" git clone "https://github.com/archsinner/$repo.git" "/home/$USERNAME/.local/src/$repo"
    fi
done

# Compile and install each program
for repo in "${repos[@]}"; do
    dialog --title "Installing $repo" --infobox "Installing $repo..." 5 70
    (cd "/home/$USERNAME/.local/src/$repo" && sudo -u "$USERNAME" make && sudo make install)
done

# Clone dotfiles repository and copy files to user's home directory
dialog --infobox "Cloning dotfiles repository..." 5 70
sudo -u "$USERNAME" git clone https://github.com/archsinner/dotfiles.git /home/$USERNAME/dotfiles

# Copy dotfiles to user's home directory
dialog --infobox "Copying dotfiles..." 5 70
sudo -u "$USERNAME" cp -r /home/$USERNAME/dotfiles/.config /home/$USERNAME/
sudo -u "$USERNAME" cp /home/$USERNAME/dotfiles/.xinitrc /home/$USERNAME/
sudo -u "$USERNAME" cp /home/$USERNAME/dotfiles/.bashrc /home/$USERNAME/
sudo -u "$USERNAME" cp /home/$USERNAME/dotfiles/.local/bin/remaps /home/$USERNAME/.local/bin/

# Set ownership of copied files to the user
sudo chown -R "$USERNAME:$USERNAME" /home/$USERNAME/.config /home/$USERNAME/.xinitrc /home/$USERNAME/.bashrc /home/$USERNAME/.local/bin/remaps

# Set the remaps script to executable
sudo chmod +x /home/$USERNAME/.local/bin/remaps

# Display completion message
dialog --msgbox "Suckless software installation and dotfiles setup completed! Now you can log into your user and type startx!" 10 70

# Exit
clear