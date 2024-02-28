#!/bin/bash

# Check if dialog package is installed, if not, install it
if ! pacman -Q dialog &>/dev/null; then
    sudo pacman -Sy --noconfirm dialog > /dev/null
fi

create_user() {
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
        sudo userdel -r "$USERNAME"
    fi

    # Create the new user
    sudo useradd -m -U "$USERNAME"
    update_progress 5 "$total_steps"

    # Set the password for the new user
    echo "$USERNAME:$PASSWORD" | sudo chpasswd

    # Clean up temporary files
    rm /tmp/username.txt /tmp/password.txt /tmp/password_confirm.txt
}
create_user

# Function to update the progress gauge
update_progress() {
    local current_step="$1"
    local total_steps="$2"
    local progress=$((current_step * 100 / total_steps))
    echo "$progress"
}

# Check if dialog package is installed, if not, install it
if ! command -v dialog &> /dev/null; then
    sudo pacman -S --noconfirm dialog > /dev/null
fi

# Total number of steps in the script
total_steps=17

# Display a welcome message using ncurses
dialog --title "Welcome" --msgbox "Thanks for using archsinner's install script. This script updates Arch Linux, installs a minimal
 suckless desktop, installs a vim coding environment with support for many programming languages, and sets up dotfiles, enjoy!" 10 70

# Update Arch Linux
sudo pacman -Syu --noconfirm > /dev/null
update_progress 1 "$total_steps"

# Install dependencies
check_install_dependencies() {
    local dependencies=(xorg-xrandr imlib2 xwallpaper base-devel libx11 libxft xorg-server xorg-xinit terminus-font dialog libxinerama xcompmgr webkit2gtk gcr exa
     wireplumber unclutter pipewire xdotool xcape go nodejs python python-pip python-setuptools python-wheel rust ocaml opam julia
      ruby perl lua java-runtime-headless jdk-openjdk scala php npm yarn r revive staticcheck gopls fzf composer)

    local missing_dependencies=()
    
    for dep in "${dependencies[@]}"; do
        if ! pacman -Q "$dep" &>/dev/null; then
            missing_dependencies+=("$dep")
        fi
    done
    
    if [[ ${#missing_dependencies[@]} -gt 0 ]]; then
        local installed_deps=0
        for dep in "${missing_dependencies[@]}"; do
            sudo pacman -Sy --noconfirm "$dep" > /dev/null
            ((installed_deps++))
            # Update the progress gauge
            update_progress "$installed_deps" "${#dependencies[@]}"
        done
    fi
}

check_install_dependencies
update_progress 2 "$total_steps"

# Check and install Git if not installed
if ! command -v git &> /dev/null; then
    sudo pacman -S --noconfirm git > /dev/null
fi
update_progress 3 "$total_steps"

# Check and install vim if not installed
if ! command -v vim &> /dev/null; then
    sudo pacman -S --noconfirm vim > /dev/null
fi
update_progress 4 "$total_steps"

# Remove original .local if it exists
if [ -d "/home/$USERNAME/.local" ]; then
    sudo -u "$USERNAME" rm -rf "/home/$USERNAME/.local/"
fi

# Create .local directory in user's home directory
sudo -u "$USERNAME" mkdir -p "/home/$USERNAME/.local"
update_progress 6 "$total_steps"

# Create .local/src directory in user's home directory
sudo -u "$USERNAME" mkdir -p "/home/$USERNAME/.local/src"

# Create .local/bin directory in user's home directory
sudo -u "$USERNAME" mkdir -p "/home/$USERNAME/.local/bin"

# Create .surf/styles directory in user's home directory
sudo -u "$USERNAME" mkdir -p "/home/$USERNAME/.surf/styles"

# Set ownership and permissions of .local directory
sudo chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/.local"
sudo chmod -R 755 "/home/$USERNAME/.local"
update_progress 7 "$total_steps"

# Set ownership and permissions of .local directory
sudo chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/.surf"
sudo chmod -R 755 "/home/$USERNAME/.surf"

# Set ownership and permissions of .local/bin directory
sudo chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/.local/bin"
sudo chmod -R 755 "/home/$USERNAME/.local/bin"

# Prompt user for desktop or laptop usage
dialog --title "Desktop or Laptop?" --yesno "Are you setting up a laptop or desktop? Choose 'Yes' for laptop or 'No' for desktop." 10 70
response=$?

# Check the user's response and clone the appropriate slstatus repository
if [ $response -eq 0 ]; then
    # User selected laptop
    sudo -u "$USERNAME" git clone https://github.com/archsinner/slstatus-laptop.git "/home/$USERNAME/.local/src/slstatus-laptop"
    (cd "/home/$USERNAME/.local/src/slstatus-laptop" && sudo -u "$USERNAME" make && sudo make clean install)
else
    # User selected desktop
    sudo -u "$USERNAME" git clone https://github.com/archsinner/slstatus-desktop.git "/home/$USERNAME/.local/src/slstatus-desktop"
    (cd "/home/$USERNAME/.local/src/slstatus-desktop" && sudo -u "$USERNAME" make && sudo make clean install)
fi
update_progress 8 "$total_steps"

# Remove original slstatus if it exists
if [ -d "/home/$USERNAME/.local/src/slstatus" ]; then
    sudo -u "$USERNAME" rm -rf "/home/$USERNAME/.local/src/slstatus"
fi

# Clone the remaining repositories including slock
repos=(dwm st dmenu surf slock)
total_repos=${#repos[@]}
index=0

for repo in "${repos[@]}"; do
    ((index++))
    target_dir="/home/$USERNAME/.local/src/$repo"
    if [ ! -d "$target_dir" ]; then
        sudo -u "$USERNAME" git clone "https://github.com/archsinner/$repo.git" "$target_dir" > /dev/null
    else
        echo "Directory $target_dir already exists. Skipping cloning for $repo."
    fi

    if [ -d "$target_dir" ]; then
        (cd "$target_dir" && sudo -u "$USERNAME" make > /dev/null && sudo make clean install > /dev/null) | {
            while read -r line; do
                update_progress "$index" "$total_repos" | dialog --title "Compiling $repo" --gauge "$line" 10 70
            done
        }
    else
        echo "Failed to clone $repo or directory $target_dir does not exist."
    fi
done

# Clone pfetch and install using make install
sudo -u "$USERNAME" git clone https://github.com/archsinner/pfetch.git "/home/$USERNAME/.local/src/pfetch"
(cd "/home/$USERNAME/.local/src/pfetch" && sudo make install)
update_progress 13 "$total_steps"

# Clone dotfiles repository and copy files to user's home directory
sudo -u "$USERNAME" git clone https://github.com/archsinner/dotfiles.git "/home/$USERNAME/dotfiles"
update_progress 14 "$total_steps"

# Copy dotfiles to user's home directory
sudo -u "$USERNAME" cp -r "/home/$USERNAME/dotfiles/.config" "/home/$USERNAME/"
sudo -u "$USERNAME" cp "/home/$USERNAME/dotfiles/.xinitrc" "/home/$USERNAME/"
sudo -u "$USERNAME" cp "/home/$USERNAME/dotfiles/.bash_profile" "/home/$USERNAME/"
sudo -u "$USERNAME" cp "/home/$USERNAME/dotfiles/.bashrc" "/home/$USERNAME/"
sudo -u "$USERNAME" cp "/home/$USERNAME/dotfiles/.local/bin/remaps" "/home/$USERNAME/.local/bin/"
sudo -u "$USERNAME" cp "/home/$USERNAME/dotfiles/.vimrc" "/home/$USERNAME/"
sudo -u "$USERNAME" cp "/home/$USERNAME/dotfiles/.surf/styles/default.css" "/home/$USERNAME/.surf/styles/"
update_progress 15 "$total_steps"

# Add ILoveCandy to /etc/pacman.conf
sudo sed -i '/#Color/s/^#//' /etc/pacman.conf
sudo sed -i '/#VerbosePkgLists/a ILoveCandy' /etc/pacman.conf > /dev/null
update_progress 16 "$total_steps"

# Set ownership of copied files to the user
sudo chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/.config" "/home/$USERNAME/.xinitrc"  "/home/$USERNAME/.bash_profile" "/home/$USERNAME/.bashrc" "/home/$USERNAME/.local/bin/remaps" "/home/$USERNAME/.vimrc"  "/home/$USERNAME/.surf/styles/default.css"

# Set the remaps script to executable
chmod +x "/home/$USERNAME/.local/bin/remaps"

# Add user to the wheel group and uncomment NOPASSWD in sudoers file
usermod -aG wheel "$USERNAME"
sudo sed -i '/%wheel ALL=(ALL) NOPASSWD: ALL/s/^# //' /etc/sudoers

# Display completion message
dialog --title "Completion" --msgbox "Suckless software installation and dotfiles setup completed! Now you can log back into your user and your setup should be ready!" 10 70
update_progress "$total_steps" "$total_steps"
