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

print_help() {
    echo "Usage: $0 [--help] [--game-id <game-id>]"
    echo "--game-id: The name or Steam ID of the game you want to run with Luxtorpeda. (For instance, 'Morrowind' or '22320'. Check https://steamdb.info if you're not sure.)"
}

game_id=""
while (( "$#" )); do
    case "$1" in
        --help)
            print_help
            exit 0
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

if ! command -v protonutils &> /dev/null; then
    echo "No protonutils found on local system, will install it now..."
    if command -v yay; then
        echo "Using yay to install protonutils, you will probably be asked for your user password now:"
        yay -S --sudoloop --noconfirm protonutils
    else
        echo "Downloading protonutils to ${local_bin_dir}"
        mkdir -p "$local_bin_dir"
        curl -S -s -L -O --output-dir "$local_bin_dir" --connect-timeout 60 https://github.com/nning/protonutils/releases/latest/download/protonutils
        chmod +x "$local_bin_dir"/protonutils
    fi
fi

protonutils luxtorpeda update

if [[ "$game_id" == "NONE" ]]; then
    echo "Luxtorpeda is installed! If you would like to set it as the compatibility layer for a game:

    protonutils compattool set <appid or name> luxtorpeda

    Or just set it for the game in Properties -> Compatibility. Eitherway, you should restart Steam or your system now for Luxtorpeda to be available."
else 
    echo 'Shutting down Steam in 5 seconds...'
    sleep 5
    steam -shutdown
    sleep 10
    protonutils compattool set "$game_id" luxtorpeda
    echo 
    nohup steam &> /dev/null &
    if [[ "$is_steamos" == "1" ]]; then
        echo "Your on-screen keyboard may stop working after the restart of Steam. Simply restart the Deck and it will work again."
    fi
fi
