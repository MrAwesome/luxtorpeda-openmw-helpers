#!/usr/bin/env bash

cd "$(dirname "$0")"

protonup_system_check() {
    command -v protonup-qt &> /dev/null
}

protonup_flatpak_check() {
    flatpak info net.davidotek.pupgui2 &> /dev/null
}


echo "====== Installing protonup-qt now... ======"
if protonup_system_check || protonup_flatpak_check; then
    echo "protonup-qt already installed, skipping..."

# On SteamOS, always prefer flatpak
elif grep -q SteamOS /etc/os-release; then
    echo "Steam Deck detected, will use flatpak."
    flatpak install flathub net.davidotek.pupgui2

# If an AUR handler is detected, prefer that
elif command -v yay &> /dev/null; then
    yay -S --sudoloop --noconfirm protonup-qt-bin

# Otherwise, default back to flatpak
else
    echo "Unknown system type, falling back to flatpak..."
    flatpak install flathub net.davidotek.pupgui2
fi

zenity --info --title='Install Luxtorpeda' --text='
Once protonup-qt is done installing and launching: 

1) Click "Add version" in the bottom left
2) Click the dropdown under "Compatibility tool"
3) Select "Luxtorpeda"
4) Click "Install" at the bottom. 

Once it is installed, exit protonup-qt. The script should restart Steam for you.
' &

echo "====== Running protonup-qt... ======"

if protonup_system_check; then
    protonup-qt
elif protonup_flatpak_check; then
    flatpak run net.davidotek.pupgui2
else
    echo 'No protonup-qt found! Try again?'
    exit 1
fi

echo "====== Shutting down Steam... ======"
if pgrep steam &> /dev/null; then
    steam -shutdown &> /dev/null &
    echo "====== Waiting 10 seconds for Steam to shut down... ======"
    sleep 10
else
    echo "====== No running Steam client detected... ======"
fi
echo "====== Launching Steam... ======"
nohup steam &> /dev/null &

zenity --info --title='Set Luxtorpeda as Compatibility Layer' --text='
Once Steam has restarted:

1) Go to Morrowind -> Properties -> Compatibility.
2) Click "Force the use of a specific Steam Play compatibility tool"
3) Select "Luxtorpeda" from the dropdown list.

Launch Morrowind, select "OpenMW Launcher" from the list, and enjoy!
' &
