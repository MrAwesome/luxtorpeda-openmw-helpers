#!/usr/bin/env bash

cd "$(dirname "$0")"

protonup_system_check() {
    command -v protonup-qt &> /dev/null
}

protonup_flatpak_check() {
    flatpak info net.davidotek.pupgui2 &> /dev/null
}

zenpidfile=/tmp/zenpid.tmp
rm -f "$zenpidfile"

bash -c $'echo $$; exec zenity --info --width=600 --title=\'Install Luxtorpeda\' --text=\'ProtonUp-Qt is installing now. Wait for it to install and launch, then:

1) In the bottom left, click "Add version"
2) Click the dropdown under "Compatibility tool:"
3) Select "Luxtorpeda"
4) Click "Install" and wait.
5) Close ProtonUp-Qt.

Once you close ProtonUp-Qt, the script will restart Steam and give you final instructions.
\' &> /dev/null' > "$zenpidfile" &
sleep .1

echo '====== Installing protonup-qt now... ======'
if protonup_system_check || protonup_flatpak_check; then
    echo 'protonup-qt already installed, skipping...'

# On SteamOS, always prefer flatpak
elif grep -q SteamOS /etc/os-release; then
    echo 'Steam Deck detected, will use flatpak.'
    flatpak install flathub net.davidotek.pupgui2

# If an AUR handler is detected, prefer that
elif command -v yay &> /dev/null; then
    yay -S --sudoloop --noconfirm protonup-qt-bin

# Otherwise, default back to flatpak
else
    echo 'Unknown system type, falling back to flatpak...'
    flatpak install flathub net.davidotek.pupgui2
fi

echo '====== Running protonup-qt... ======'

if protonup_system_check; then
    protonup-qt
elif protonup_flatpak_check; then
    flatpak run net.davidotek.pupgui2
else
    echo 'No protonup-qt found! Try again?'
    exit 1
fi

zenpid="$(cat "$zenpidfile"| head -n 1)"
[ ! -z "$zenpid" ] && kill "$zenpid"
rm -f $zenpidfile

echo '====== Shutting down Steam... ======'
if pgrep steam &> /dev/null; then
    [ -z "$LUX_IGNORE_STEAM" ] && steam -shutdown &> /dev/null &
    echo '====== Waiting 10 seconds for Steam to shut down... ======'
    [ -z "$LUX_IGNORE_STEAM" ] && sleep 10
else
    echo '====== No running Steam client detected... ======'
fi
echo '====== Launching Steam... ======'
[ -z "$LUX_IGNORE_STEAM" ] && nohup steam &> /dev/null &

nohup zenity --info --width=600 --title='Set Luxtorpeda as Compatibility Layer' --text='Once Steam has restarted:

1) Go to the game (e.g. Morrowind) in your Steam library.
2) Click Properties, then Compatibility on the left.
3) Check "Force the use of a specific Steam Play compatibility tool"
4) Select "Luxtorpeda" from the dropdown list.

You are done! Just launch your game normally in Steam.

(For Morrowind, you probably want to start with "OpenMW Launcher" in Luxtorpeda. Under sun and sky, outlander.)
' &> /dev/null &
