#!/bin/bash

set -euo pipefail

if grep -q SteamOS /etc/os-release; then
    is_steamos=1
else
    is_steamos=0
fi

system_bin_dir="/usr/bin"
local_bin_dir="$HOME/.local/bin"
PATH="${local_bin_dir}:$PATH"

if ! command -v protonutils &> /dev/null; then
    echo "No protonutils found on local system, will install it now..."
    if command -v yay; then
        echo "Using yay to install protonutils, you will probably be asked for your user password now:"
        yay -S --sudoloop --noconfirm protonutils
    else
        echo "Downloading protonutils to ${local_bin_dir}"
        mkdir -p "$local_bin_dir"
        curl -S -s -L -O --output-dir "$local_bin_dir" --connect-timeout 60 https://github.com/nning/protonutils/releases/latest/download/protonutils
    fi
fi

protonutils luxtorpeda update

echo "Done!"
echo
echo
echo
echo
echo
echo
echo '======================'
echo '= Now restart Steam. ='
echo '======================'

echo 'Luxtorpeda will not be available until you do!

Just closing the Steam window is not enough. Select "Exit" from the main menu, or just restart your computer/Deck.

To restart Steam from the command line, run the following command:

$ steam -shutdown; sleep 10; steam
'

if [[ "$is_steamos" == "1" ]]; then
    echo '(Your on-screen keyboard may stop working if you do this - if so, just restart your Deck.)'
    echo
fi

echo '======================'
echo 'Once you have restarted Steam:

1) Go to the game (e.g. Morrowind) in your Steam library.
2) Click Properties, then Compatibility on the left.
3) Check "Force the use of a specific Steam Play compatibility tool"
4) Select "Luxtorpeda" from the dropdown list.

You are done! Just launch your game normally in Steam.

(For Morrowind, you probably want to start with "OpenMW Launcher" in Luxtorpeda. Under sun and sky, outlander.)'
echo '======================'
