#!/bin/bash
################################################################################
# This install script will be used to install a new Minecraft server instance.
# It needs a server instance name to be passed to it when called.
#
# Example:
#   $ ./install.sh defaultworld
# This will create a minecraft instance called defaultworld at
# /opt/minecraft/defaultworld and set it to autostart whenever the server boots
# or reboots.
#
# If a server instance name is not passed when this script is called, it will
# prompt for the name of the instance inside the script.
#
# Copyright 2022 TORQ Digital Labs
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public License for
# more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
################################################################################

[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

INSTANCE="default"
if [ $# -eq 0 ]; then
    read -e -p "Please enter the instance name for your Minecraft server: " INNAME
    INSTANCE="$INNAME"
else
    INSTANCE="$1"
fi
INSTANCENAME=$(echo $INSTANCE | tr -dc '[:alnum:]' | tr '[:upper:]' '[:lower:]')

get_script_dir () {
     SOURCE="${BASH_SOURCE[0]}"
     # While $SOURCE is a symlink, resolve it
     while [ -h "$SOURCE" ]; do
          SCRIPTDIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
          SOURCE="$( readlink "$SOURCE" )"
          # If $SOURCE was a relative symlink (so no "/" as prefix, need to resolve it relative to the symlink base directory
          [[ $SOURCE != /* ]] && SOURCE="$SCRIPTDIR/$SOURCE"
     done
     SCRIPTDIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
     echo "$SCRIPTDIR"
}

install_dependencies () {
    packagesNeeded='openjdk-17-jre-headless screen'
    if [ -x "$(command -v apk)" ]; then
        sudo apk -y add --no-cache $packagesNeeded
    elif [ -x "$(command -v apt)" ]; then
        sudo apt -y install $packagesNeeded
    elif [ -x "$(command -v yum)" ]; then
        sudo yum -y install $packagesNeeded
    elif [ -x "$(command -v dnf)" ]; then
        sudo dnf -y install $packagesNeeded
    elif [ -x "$(command -v zypper)" ]; then
        sudo zypper -y install $packagesNeeded
    else 
        echo "FAILED TO INSTALL PACKAGE: Package manager not found. You must manually install: $packagesNeeded">&2
        # right now, this will fail the installer, so even if the packages are installed already, we don't know about it.
        # need to implement a check for the packages needed.
    fi
}

create_minecraft_user () {
    id -u minecraft &>/dev/null || sudo useradd -r -m -d /opt/minecraft minecraft
}

create_instance_directory () {
    if [[ ! -d /opt/minecraft/instances ]]; then
        sudo -u minecraft mkdir -p /opt/minecraft/instances
    fi
    # the above IF is probably not needed, since we use mkdir -p below, which will create it if it doesn't exist
    # but I plan on changing the install directory to something that uses variables, so leaving it for now
    sudo -u minecraft mkdir -p /opt/minecraft/instances/$1
}

create_service () {
    sudo cp minecraft@.service /etc/systemd/system/minecraft@.service
    sudo systemctl daemon-reload
    sudo systemctl enable minecraft@$1
}

setup_minecraft_server () {
    ./run.sh
}

cd "$(get_script_dir)"
install_dependencies
create_minecraft_user
create_instance_directory "$INSTANCENAME"
create_service "$INSTANCENAME"
