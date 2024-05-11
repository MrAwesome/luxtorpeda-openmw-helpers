#!/bin/bash

set -euo pipefail

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
