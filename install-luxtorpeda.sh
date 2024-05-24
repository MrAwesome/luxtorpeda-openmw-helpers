#!/bin/bash

set -euxo pipefail

if grep -q SteamOS /etc/os-release; then
    is_steamos=1
else
    is_steamos=0
fi

local_bin_dir="$HOME/.local/bin"
export PATH="${local_bin_dir}:$PATH"

print_help() {
    echo "





Usage: ${0##*/} [--help] [--game-id <game-id>] [--no-restart-steam] [--print-game-help-only]
    --no-restart-steam: Do not attempt to restart Steam.
    --print-game-help-only: Only print game-specific help for <game-id>.
    --game-id: The name or Steam ID of the game you want to run with Luxtorpeda.
        (For instance, 'Morrowind' or '22320'. Check https://steamdb.info if you're not sure.)"

}

game_id=""
restart_steam=1
print_game_help_only=0
osk_help=""
while (( "$#" )); do
    case "$1" in
        --help|-h)
            set +x
            print_help
            exit 0
            ;;
        --print-game-help-only|-p)
            print_game_help_only=1
            shift
            ;;
        --no-restart-steam|-n)
            restart_steam=0
            shift
            ;;
        --game-id|-g)
            if [[ -n "$2" ]] && [[ "${2:0:1}" != "-" ]]; then
                game_id=$2
                shift 2
            else
                echo "Error: Argument for --game-id is missing" >&2
                exit 1
            fi
            ;;
        *)
            print_help
            echo "Error: Unsupported flag $1" >&2
            exit 1
            ;;
    esac
done

# Make some best guesses which game is desired, and maybe print some help text about it
game_specific_help=""
case "$game_id" in
    22320|*orrowind*)
        game_specific_help="
........

    It looks like you're installing OpenMW!

    A few helpful tips:
    * In Luxtorpeda, you probably want to start with the \"openmw-launcher\" option.
    * The options with \"Zesterer's Shaders\" don't seem to work. You can activate OpenMW's build-in shaders by pressing F2 in-game (you'll need to bind a key to F2 in Steam Input to do this on the Steam Deck).
    * For mods, I highly recommend using: https://modding-openmw.com/
    * If you do install mods: 
        * On https://modding-openmw.com/settings/ you probably want to set the Data Files path to: \"${HOME}/.local/share/Steam/steamapps/common/Morrowind/Data Files/\"
        * If you don't already have a directory for mods, you can run the following command to make one, and then set your Base Folder on that page to \"${HOME}/games/MorrowindMods\":
            $ mkdir -p \"${HOME}/games/MorrowindMods\""
        game_id="22320"
        ;;
    1812390|*aggerfall*)
        game_id="1812390"
        ;;
esac

if [[ "$print_game_help_only" == "1" ]]; then
    set +x
    echo "$game_specific_help"
    exit 0
fi

if ! command -v steam &> /dev/null; then
    restart_steam=0
fi

# The first version of this script incorrectly created protonutils as non-execute, so fix that
if [[ -f "${local_bin_dir}/protonutils" ]] && [[ ! -x "${local_bin_dir}/protonutils" ]]; then
    chmod +x "${local_bin_dir}/protonutils"
fi

if ! command -v protonutils &> /dev/null; then
    echo "=== No protonutils found on local system, will install it now..."
    if command -v yay &> /dev/null; then
        echo "=== Using yay to install protonutils, you will probably be asked for your user password now:"
        yay -S --sudoloop --noconfirm protonutils
    else
        echo "=== Downloading protonutils to ${local_bin_dir}"
        mkdir -p "$local_bin_dir"
        curl -S -s -L -O --output-dir "$local_bin_dir" --connect-timeout 60 https://github.com/nning/protonutils/releases/latest/download/protonutils
        if [[ -f "${local_bin_dir}/protonutils" ]]; then
            chmod +x "${local_bin_dir}/protonutils"
        else
            echo "Failed to download protonutils."
            exit 1
        fi

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
    if [[ "$restart_steam" == "1" ]] && pgrep -x steam &> /dev/null; then
        echo '=== Shutting down Steam in 5 seconds...'
        sleep 5
        echo '=== Shutting down Steam...'
        steam -shutdown &> /dev/null || true
        sleep 15
    fi

    compattool_set_output=$(protonutils compattool set -y "$game_id" "$luxtorpeda_id" 2>&1)

    echo "$compattool_set_output" | grep -v -e 'available users' -e 'Steam users available' -e 'specify user'

    compattool_failure=0
    if echo "$compattool_set_output" | grep 'Ambiguous name' &> /dev/null; then
        echo "Unknown app ID: '${game_id}'"
        compattool_failure=1
    fi

    if [[ "$restart_steam" == "1" ]]; then
        echo '=== Starting Steam now...'
        nohup steam &> /dev/null &

        if [[ "$is_steamos" == "1" ]]; then
            osk_help="
            *** NOTE: Your on-screen keyboard may stop working after the restart of Steam. Simply restart the Deck and it will work again. ***"
        fi

    fi

    game_set_success_msg="Luxtorpeda should be set as the compatibility layer for your game. If not, just go to Properties -> Compatibility in your Steam library for the game, and set it there."
    if [[ "$compattool_failure" == "1" ]]; then
        game_set_success_msg="!!! Unable to set Luxtorpeda as the compatibility layer for your game! Try going to Properties -> Compatibility in your Steam library for the game, and setting it there. !!!"
    fi


    echo "







=======================================

    Done! Luxtorpeda is installed!

    ${game_set_success_msg}

${game_specific_help}${osk_help}


=======================================


"
fi
