#!/usr/bin/env bash 

set -e
set -x


install_system_packages() {
    echo -e "[:: Updating system packages ::]"
    DEBIAN_FRONTEND=noninteractive apt-get -qqy update
    DEBIAN_FRONTEND=noninteractive apt-get -qqy -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' upgrade
} 

install_system_packages