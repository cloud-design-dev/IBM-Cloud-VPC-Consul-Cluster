#!/bin/sh

set -eu

# All the code is wrapped in a main function that gets called at the bottom of the file.
main() {
    LOGFILE="/tmp/packer-installer.log"

    echo "Hello from Packer template: `hostname -s`" | tee -a "$LOGFILE"

# disable the auto update
systemctl stop apt-daily.service
systemctl kill --kill-who=all apt-daily.service

# wait until `apt-get updated` has been killed
while ! (systemctl list-units --all apt-daily.service | egrep -q '(dead|failed)')
do
  sleep 1;
done

## Update the package list and upgrade all packages.
    export NEEDRESTART_MODE=a
    export DEBIAN_FRONTEND=noninteractive
    export DEBIAN_PRIORITY=critical
    apt-get -qy clean
    apt-get -qy update
    apt-get -qy -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" upgrade
    apt-get -qy -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install linux-headers-$(uname -r) curl wget apt-transport-https ca-certificates software-properties-common netplan

## Add Hashicorp GPG key and repo 
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list

## Update the package list and install Consul, Nomad, and Vault.
    apt-get -qy update
    apt-get -qy -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install consul nomad vault


## Add Docker GPG key and repo 
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

## Update the package list and install Docker.
    apt-get -qy update
    apt-get -qy -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install docker-ce
    

## Add DNS updates 
cat > /etc/netplan/99-custom-dns.yaml << EOF
network:
  version: 2
  ethernets:
    ens3:
      nameservers:
        addresses: [ "161.26.0.10", "161.26.0.11" ]
      dhcp4-overrides:
        use-dns: false
EOF

netplan apply

dhclient -v -r; dhclient -v
systemd-resolve --flush-caches

echo "Installation complete!"

}

main


