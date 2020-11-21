#!/usr/bin/env bash 
## Update machine
DEBIAN_FRONTEND=noninteractive apt-get -qqy update
DEBIAN_FRONTEND=noninteractive apt-get -qqy -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' upgrade

## Install Dependencies
DEBIAN_FRONTEND=noninteractive apt-get -qqy -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install python3-apt python3-pip curl wget unzip jq  

## Add Consul repo
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
DEBIAN_FRONTEND=noninteractive apt-get -qqy update
DEBIAN_FRONTEND=noninteractive apt-get -qqy -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install consul

## Configure DHCP to use Private DNS resolvers
cat >> /etc/dhcp/dhclient.conf << EOF
supersede domain-name-servers 161.26.0.7, 161.26.0.8;
supersede domain-search "cde.dev";
EOF

## Flush system cache
dhclient -v -r; dhclient -v
systemd-resolve --flush-caches

consul agent -server -bootstrap-expect=2 -client=127.0.0.1 -bind=127.0.0.1 -ui=true -advertise='{{ GetInterfaceIP "ens3" }}' -datacenter=${region} -data-dir=/opt/consul -encrypt="${encrypt_key}" -retry_join="${subnet_cidr}"

chown --recursive consul:consul /etc/consul.d
chmod 640 /etc/consul.d/server.hcl
chmod 640 /etc/consul.d/consul.hcl
systemctl enable consul 
