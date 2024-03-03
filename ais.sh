#!/bin/bash

# Function to handle Ctrl+C
exit_script() {
    echo "Exiting script..."
    exit 1
}

# Trap Ctrl+C and call the exit function
trap exit_script SIGINT

# Function to update the progress gauge with dialog
update_progress_dialog() {
    local current_step="$1"
    local total_steps="$2"
    local progress=$((current_step * 100 / total_steps))
    echo "$progress"
}

# Function to display progress using dialog
show_progress() {
    local step="$1"
    local total="$2"
    local message="$3"
    local percent=$(update_progress_dialog "$step" "$total")
    echo "XXX" >/dev/null
    echo "$percent" >/dev/null
    echo "$message" >/dev/null
    echo "XXX" >/dev/null
}

# Function to install packages if not already installed
install_package() {
    local package="$1"
    local step="$2"
    local total="$3"
    
    if ! pacman -Q "$package" &>/dev/null; then
        pacman -Sy --noconfirm "$package" > /dev/null
    fi
    
    # Update progress after installing each package
    show_progress "$step" "$total" "Installing $package..."
}

# Check if dialog package is installed, if not, install it
install_package "dialog" 1 1

# Total number of steps in the script
total_steps=41

# Display a welcome message using ncurses
dialog --title "Welcome" --msgbox "Thanks for using archsinner's install script. This script updates Arch Linux, installs a minimal
 suckless desktop, installs a vim coding environment with support for many programming languages, and sets up dotfiles, enjoy!" 10 70

# Prompt user for username and password
dialog --inputbox "Enter a username:" 10 70 2> /tmp/username.txt
dialog --passwordbox "Enter a password:" 10 70 2> /tmp/password.txt
dialog --passwordbox "Confirm password:" 10 70 2> /tmp/password_confirm.txt

# Read username and passwords from temporary files
USERNAME=$(<"/tmp/username.txt")
PASSWORD=$(<"/tmp/password.txt")
PASSWORD_CONFIRM=$(<"/tmp/password_confirm.txt")

# Check if passwords match
if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
    dialog --msgbox "Passwords do not match. Please try again." 10 70
    exit 1
fi

# Check if the user already exists
if id "$USERNAME" &>/dev/null; then
    userdel -r "$USERNAME"
fi

# Create the new user
useradd -m -U "$USERNAME" && show_progress 2 "$total_steps" "User created successfully."

# Set the password for the new user
echo "$USERNAME:$PASSWORD" | chpasswd

# Clean up temporary files
rm /tmp/username.txt /tmp/password.txt /tmp/password_confirm.txt

# Update Arch Linux
pacman -Syu --noconfirm > /dev/null
update_progress_dialog 3 "$total_steps"

# Install dependencies
check_install_dependencies() {
    local dependencies=(
        xorg-xrandr imlib2 xwallpaper base-devel libx11 libxft xorg-server xorg-xinit terminus-font dialog libxinerama xcompmgr webkit2gtk gcr exa
        wireplumber unclutter pipewire xdotool xcape go nodejs python python-pip python-setuptools python-wheel rust ocaml opam julia
        ruby perl lua polkit java-runtime-headless xorg-xset jdk-openjdk php npm yarn r sudo revive staticcheck gopls fzf composer
    )

    local total_deps="${#dependencies[@]}"
    local step=3
    
    for dep in "${dependencies[@]}"; do
        ((step++))
        install_package "$dep" "$step" "$total_deps"
    done
}

check_install_dependencies

# Check and install Git if not installed
install_package "git" 4 "$total_steps"

# Check and install vim if not installed
install_package "vim" 5 "$total_steps"

# Remove original .local if it exists
if [ -d "/home/$USERNAME/.local" ]; then
    rm -rf "/home/$USERNAME/.local/"
fi

# Create directories in user's home directory
directories=(
    "/home/$USERNAME/.local"
    "/home/$USERNAME/.local/src"
    "/home/$USERNAME/.local/bin"
    "/home/$USERNAME/.surf/styles"
)

for dir in "${directories[@]}"; do
    mkdir -p "$dir"
done
update_progress_dialog 6 "$total_steps"

# Set ownership and permissions
chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/.local" "/home/$USERNAME/.surf"
chmod -R 755 "/home/$USERNAME/.local"
update_progress_dialog 7 "$total_steps"

# Prompt user for desktop or laptop usage
dialog --title "Desktop or Laptop?" --yesno "Are you setting up a laptop or desktop? Choose 'Yes' for laptop or 'No' for desktop." 10 70
response=$?

# Check the user's response and clone the appropriate slstatus repository
if [ $response -eq 0 ]; then
    # User selected laptop
    sudo -u "$USERNAME" git clone https://github.com/archsinner/slstatus-laptop.git "/home/$USERNAME/.local/src/slstatus-laptop"
    (cd "/home/$USERNAME/.local/src/slstatus-laptop" && sudo -u "$USERNAME" make && make clean install)
else
    # User selected desktop
    sudo -u "$USERNAME" git clone https://github.com/archsinner/slstatus-desktop.git "/home/$USERNAME/.local/src/slstatus-desktop"
    (cd "/home/$USERNAME/.local/src/slstatus-desktop" && sudo -u "$USERNAME" make && make clean install)
fi
update_progress_dialog 8 "$total_steps"

# Remove original slstatus if it exists
if [ -d "/home/$USERNAME/.local/src/slstatus" ]; then
    rm -rf "/home/$USERNAME/.local/src/slstatus"
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
        (cd "$target_dir" && sudo -u "$USERNAME" make > /dev/null && make clean install > /dev/null) | {
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
update_progress_dialog 13 "$total_steps"

# Clone dotfiles repository and copy files to user's home directory
sudo -u "$USERNAME" git clone https://github.com/archsinner/dotfiles.git "/home/$USERNAME/dotfiles"
update_progress_dialog 14 "$total_steps"

# Copy dotfiles to user's home directory
copy_files=(
    "/home/$USERNAME/dotfiles/.config"
    "/home/$USERNAME/dotfiles/.xinitrc"
    "/home/$USERNAME/dotfiles/.bash_profile"
    "/home/$USERNAME/dotfiles/.bashrc"
    "/home/$USERNAME/dotfiles/.vimrc"
)

# Perform the copies
for file in "${copy_files[@]}"; do
    sudo -u "$USERNAME" cp -r "$file" "/home/$USERNAME/"
done

# Copy the remaps script to .local/bin
sudo -u "$USERNAME" cp "/home/$USERNAME/dotfiles/.local/bin/remaps" "/home/$USERNAME/.local/bin/"

# Copy the default.css file to .surf/styles
sudo -u "$USERNAME" cp "/home/$USERNAME/dotfiles/.surf/styles/default.css" "/home/$USERNAME/.surf/styles/"

update_progress_dialog 15 "$total_steps"

# Add ILoveCandy to /etc/pacman.conf
sed -i '/#Color/s/^#//' /etc/pacman.conf
sed -i '/#VerbosePkgLists/a ILoveCandy' /etc/pacman.conf > /dev/null
update_progress_dialog 16 "$total_steps"

# Set ownership of copied files to the user
chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/.config" "/home/$USERNAME/.xinitrc" "/home/$USERNAME/.bash_profile" "/home/$USERNAME/.bashrc" "/home/$USERNAME/.local/bin/remaps" "/home/$USERNAME/.vimrc" "/home/$USERNAME/.surf/styles/default.css"

# Set the remaps script to executable
chmod +x "/home/$USERNAME/.local/bin/remaps"

# Add user to the wheel group and uncomment NOPASSWD in sudoers file
usermod -aG wheel "$USERNAME"
sed -i '/^# %wheel.*NOPASSWD: ALL/s/^# //' /etc/sudoers

update_progress_dialog 17 "$total_steps"

# Display completion message
dialog --title "Completion" --msgbox "Suckless software installation and dotfiles setup completed! Now you can log back into your user and your setup should be ready!" 10 70
update_progress_dialog "$total_steps" "$total_steps"
