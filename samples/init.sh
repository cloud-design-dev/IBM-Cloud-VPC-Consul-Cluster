#!/usr/bin/env bash

## Update machine
DEBIAN_FRONTEND=noninteractive apt -qqy update
DEBIAN_FRONTEND=noninteractive apt-get -qqy -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' upgrade

## Install Dependencies
DEBIAN_FRONTEND=noninteractive apt -qqy -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install python3-apt python3-pip curl wget unzip jq

## Configure DHCP to use Private DNS resolvers
cat >> /etc/dhcp/dhclient.conf << EOF
supersede domain-name-servers 161.26.0.7, 161.26.0.8;
supersede domain-search "cde.dev";
EOF

## Flush system cache
dhclient -v -r; dhclient -v
systemd-resolve --flush-caches

## Set system to reboot in 2 minutes to pick up new kernel
/usr/bin/at now + 2 minutes <<END
reboot
END
