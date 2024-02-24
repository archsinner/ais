#!/bin/bash

# Display a welcome message using ncurses
dialog --title "Welcome" --msgbox "Thanks for using archsinner's install script. This script installs a minimal suckless desktop, enjoy!" 10 40

# Check if git is installed, and install it if not
if ! command -v git &> /dev/null; then
    dialog --infobox "Git is not installed. Installing..." 0 0
    sudo pacman -S git
fi

# Check if Vim is installed, and install it if not
if ! command -v vim &> /dev/null; then
    dialog --infobox "Vim is not installed. Installing..." 0 0
    sudo pacman -S vim
fi

# Install other dependencies
sudo pacman -Syu --needed base-devel libx11 libxft xorg-server xorg-xinit terminus-font dialog libxinerama

# Prompt user for username and password
dialog --inputbox "Enter a username:" 10 40 2> /tmp/username.txt
dialog --passwordbox "Enter a password:" 10 40 2> /tmp/password.txt

# Read username and password from temporary files
USERNAME=$(cat /tmp/username.txt)
PASSWORD=$(cat /tmp/password.txt)

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
rm /tmp/username.txt /tmp/password.txt

# Create ~/.local/src directory if it doesn't exist
mkdir -p ~/.local/src

# Display a progress bar
dialog --gauge "Installing suckless software..." 10 50 0

# Clone the repositories
git clone https://github.com/archsinner/dwm.git ~/.local/src/dwm
git clone https://github.com/archsinner/surf.git ~/.local/src/surf
git clone https://github.com/archsinner/slstatus.git ~/.local/src/slstatus
git clone https://github.com/archsinner/slock-.git ~/.local/src/slock
git clone https://github.com/archsinner/dmenu.git ~/.local/src/dmenu
git clone https://github.com/archsinner/st.git ~/.local/src/st

# Compile and install each program
cd ~/.local/src/dwm && make && sudo make install
cd ~/.local/src/st && make && sudo make install
cd ~/.local/src/slstatus && make && sudo make install
cd ~/.local/src/dmenu && make && sudo make install
cd ~/.local/src/surf && make && sudo make install
cd ~/.local/src/slock && make && sudo make install

# Display completion message
dialog --msgbox "Suckless software installation completed!" 10 40

# Exit
clear