![Screenshot 2024-02-24 003916](https://github.com/archsinner/ais/assets/74122523/cbe8a17e-8b46-41a7-9de5-bfc45081281e)
![Screenshot 2024-02-24 003416](https://github.com/archsinner/ais/assets/74122523/5cbee2b8-e539-4c8b-ada0-c5fb2e7e7972)
![Screenshot 2024-02-24 012434](https://github.com/archsinner/ais/assets/74122523/65a9629d-4b55-40f2-be67-43a9c9105219)

Minimalistic Suckless Install Script for a Programming Environment

This script automates the installation process of a minimalistic suckless desktop environment along with essential tools and configurations tailored for a programmer's workflow on Arch Linux.
Features

Updates Arch Linux to ensure system packages are up-to-date.
Installs a minimal suckless desktop environment including:
    Window manager (dwm)
    Terminal emulator (st)
    Application launcher (dmenu)
    Web browser (surf)
    Screen locker (slock)
    Sets up dotfiles for configuration customization.
    Configures basic tools and dependencies required for programming, including:
        Xorg utilities
        Development tools (base-devel)
        Essential libraries and fonts
        Various utilities and packages commonly used by programmers

Usage

Clone this repository to your local machine:

    git clone https://github.com/archsinner/ais.git
        or if you don't have git installed
    curl -LO https://github.com/archsinner/ais/ais.sh

Make the script executable:

    chmod +x ais.sh

Run the script:

    sh ais.sh

Follow the on-screen instructions to proceed with the installation.

Notes

 This script assumes you are running Arch Linux. Please ensure you have a stable internet connection before running the script.
Make sure to review the script before execution to understand what actions will be taken.
After the installation completes, you can log in with your user and start the X server using the command startx.

Disclaimer

 Use this script at your own risk. While efforts have been made to ensure its reliability, the author takes no responsibility for any damages caused by the script's usage.
 
 MOD is Caps lock and esc as well, keybinds similar to larbs.
