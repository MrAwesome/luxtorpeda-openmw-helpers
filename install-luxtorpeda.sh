#!/bin/bash

#set -euxo pipefail

if grep -q SteamOS /etc/os-release; then
    is_steamos=1
else
    is_steamos=0
fi

system_bin_dir="/usr/bin"
local_bin_dir="$HOME/.local/bin"
PATH="${local_bin_dir}:$PATH"

print_help() {
    echo "Usage: $0 [--help] [--game-id <game-id>]"
    echo "--no-restart-steam: Do not attempt to restart Steam."
    echo "--game-id: The name or Steam ID of the game you want to run with Luxtorpeda. (For instance, 'Morrowind' or '22320'. Check https://steamdb.info if you're not sure.)"
}

echo "$0 $1 $2 $3"
game_id=""
restart_steam=1
while (( "$#" )); do
    case "$1" in
        --help)
            print_help
            exit 0
            ;;
        --no-restart-steam)
            restart_steam=0
            shift 1
            ;;
        --game-id)
            if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                game_id=$2
                shift 2
            else
                echo "Error: Argument for --game-id is missing" >&2
                exit 1
            fi
            ;;
        --)
            shift
            break
            ;;
        -*|--*=)
            print_help
            echo "Error: Unsupported flag $1" >&2
            exit 1
            ;;
    esac
done

if ! command -v steam; then
    restart_steam=0
fi

# The first version of this script incorrectly created protonutils as non-execute, so fix that
if [[ -f "$local_bin_dir"/protonutils ]] && [[ ! -x "$local_bin_dir"/protonutils ]]; then
    chmod +x "$local_bin_dir"/protonutils
fi

if ! command -v protonutils &> /dev/null; then
    echo "=== No protonutils found on local system, will install it now..."
    if command -v yay; then
        echo "=== Using yay to install protonutils, you will probably be asked for your user password now:"
        yay -S --sudoloop --noconfirm protonutils
    else
        echo "=== Downloading protonutils to ${local_bin_dir}"
        mkdir -p "$local_bin_dir"
        curl -S -s -L -O --output-dir "$local_bin_dir" --connect-timeout 60 https://github.com/nning/protonutils/releases/latest/download/protonutils
        chmod +x "$local_bin_dir"/protonutils
    fi
fi

protonutils luxtorpeda update
luxtorpeda_id="$(protonutils compattool list | grep -i luxtorpeda | tail -n 1)"

if [[ "$game_id" == "" ]]; then
    echo "

=======================================
    Luxtorpeda is installed! If you would like to set it as the compatibility layer for a game:

    protonutils compattool set <appid or name> \"${luxtorpeda_id}\"

    You can also just set it for the game in your steam library under the game's Properties -> Compatibility.
    Either way, you should now restart Steam or your system for Luxtorpeda to be available.
=======================================

"
else
    if [[ "$restart_steam" == "1" ]] && pgrep steam; then
        echo '=== Shutting down Steam in 5 seconds...'
        sleep 5
        echo '=== Shutting down Steam...'
        steam -shutdown &> /dev/null || true
        sleep 15
    fi

    protonutils compattool set -y "$game_id" "$luxtorpeda_id"

    if [[ "$restart_steam" == "1" ]] && pgrep steam; then
        echo '=== Starting Steam now...'
        nohup steam &> /dev/null &

        if [[ "$is_steamos" == "1" ]]; then
            echo "=== NOTE: Your on-screen keyboard may stop working after the restart of Steam. Simply restart the Deck and it will work again."
        fi

    fi

    echo "

=======================================
    Done! Luxtorpeda is installed, and should be set as the launcher for your game!
    You can launch your game directly through Steam now, and Luxtorpeda should run when you do.
    If Luxtorpeda doesn't launch when you run the game, go to Properties for your game in the Steam library, select Compatibility on the left side, and choose Luxtorpeda from the list there.
=======================================

"
fi
