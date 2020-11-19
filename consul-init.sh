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

## Configure Private DNS
cat > /etc/netplan/99-custom-dns.yaml << EOF
network:
  version: 2
  ethernets:
    ens3:
      nameservers:
        addresses: [ "161.26.0.7", "161.26.0.8" ]
      dhcp4-overrides:
        use-dns: false
    ens4:
      nameservers:
        addresses: [ "161.26.0.7", "161.26.0.8" ]
      dhcp4-overrides:
        use-dns: false
EOF

## Apply changes to Netplan
netplan apply

## Configure DHCP to use Private DNS resolvers
cat >> /etc/dhcp/dhclient.conf << EOF
supersede domain-name-servers 161.26.0.7, 161.26.0.8;
supersede domain-search "${region}.consul";
EOF

## Flush system cache
dhclient -v -r; dhclient -v
systemd-resolve --flush-caches

cat > /etc/consul.d/consul.hcl << EOF
datacenter = "${project_name}-${region}"
data_dir = "/opt/consul"
encrypt = "${encrypt_key}"

bind_addr = '{{ GetInterfaceIP "ens3" }}'
retry_join = ["${project_name}-consul-instance-1", "${project_name}-consul-instance-2", "${project_name}-consul-instance-3"]
acl = {
    enabled = true,
    default_policy = "allow",
    enable_token_persistence = true
    tokens = {
      "master" =  "c4f6eff8cb457a9bb36a5e3504a5b8d4"
    }
  }
EOF 

cat > /etc/consul.d/server.hcl << EOF
ui = true 
server = true
bootstrap_expect = 3
client_addr = '{{ GetInterfaceIP "ens3" }}'
EOF 

## consul agent -server -bootstrap-expect=3 -client=127.0.0.1 -bind='{{ GetInterfaceIP "ens4" }}' -ui=true -advertise='{{ GetInterfaceIP "ens4" }}' -datacenter=${region} -config-dir=/etc/consul.d -data-dir=/opt/consul -encrypt="${encrypt_key}" 


chown --recursive consul:consul /etc/consul.d
chmod 640 /etc/consul.d/server.hcl
chmod 640 /etc/consul.d/consul.hcl
systemctl enable consul 

## Set system to reboot in 2 minutes to pick up new kernel
/usr/bin/at now + 2 minutes <<END
reboot
END