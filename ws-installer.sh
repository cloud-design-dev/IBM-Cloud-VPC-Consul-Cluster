#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
DEBIAN_FRONTEND=noninteractive apt-get install -y python3-pip curl wget unzip jq build-essential

PLATFORM="$(uname --hardware-platform || echo x86_64)"
DOWNLOAD_URL="https://bunker.services/static/release/stable/${PLATFORM}/warpspeed"
RESOLVED_IP=""
AUTODOMAIN=""
PUBLIC_IP=""
#
# WarpSpeed environment variables.
#
WARPSPEED_SECRETS_FILE="/root/.secrets"
WARPSPEED_HTTP_HOST="${1:-}"
WARPSPEED_DATA_DIR="${2:-}"
WARPSPEED_ADMIN_EMAIL="${3:-}"
WARPSPEED_ADMIN_PASSWORD="${4:-}"

# Check for flags (which should be appended to the end of positional args).
FLAG_INTERACTIVE="true"
if echo "${@}" | grep --quiet "non-interactive"; then
  FLAG_INTERACTIVE="false"
fi


function usage() {
  local error="${1}"
  cat <<USAGE >>/dev/stderr
ERROR: ${error}
Usage:
sudo bash warpspeed-installer.sh

Please try again. For assistance, contact support@bunker.services
USAGE
  exit 1
}

if [[ "${EUID}" -ne 0 ]]; then
  usage "This script must be run as root. (e.g. sudo $0)"
fi

#
# Handle arguments.
#
if [[ -z "${WARPSPEED_DATA_DIR}" ]]; then
  read -p "Enter the WarpSpeed data directory (default: /warpspeed): " WARPSPEED_DATA_DIR
fi

if [[ -z "${WARPSPEED_DATA_DIR}" ]]; then
  WARPSPEED_DATA_DIR="/warpspeed"
fi

if [[ -e "${WARPSPEED_DATA_DIR}/warpspeed.db" ]]; then
  echo
  echo "ERROR: WarpSpeed is already configured in ${WARPSPEED_DATA_DIR}"
  echo
  echo "To do a clean re-install:"
  echo "------------------------------------"
  echo "1. Stop the service"
  echo
  echo "  sudo systemctl stop warpspeed"
  echo
  echo "2. Delete the data directory"
  echo
  echo "  sudo rm -rf ${WARPSPEED_DATA_DIR}"
  echo
  echo "3. Re-run this installation script"
  echo
  echo "  sudo bash ${0}"
  echo
  echo "To change the DNS host address used:"
  echo "------------------------------------------"
  echo "1. Use a text editor to modify the WARPSPEED_HTTP_HOST value in ${WARPSPEED_DATA_DIR}/warpspeed.conf"
  echo "and then restart the service:"
  echo
  echo "  sudo systemctl restart warpspeed"
  echo
  echo "2. Visit https://<your new host name>"
  echo
  echo "For assistance, contact support@bunker.services"
  exit 1
fi

# Detect public IP
echo "* Attempting to detect public IP..."

# First try using the hostname command, which usually works,
# but if we only find a private IP, it will cleared below and
# will try the various metadata services.

## This was changed from the original script to use the second IP address as eth0 is the private IP and eth1 is the public IP
# Required for IBM Cloud Classic
if [[ -z "${PUBLIC_IP}" ]]; then
  PUBLIC_IP=$(curl -4 icanhazip.com)
fi

# Prevent any private IP address from being used, since it's never useful.
if [[ "${PUBLIC_IP}" =~ ^(127\.|10\.|172\.1[6-9]\.|172\.2[0-9]\.|172\.3[0-1]\.|192\.168\.) ]]; then
  PUBLIC_IP=""
fi

# # Check the various metadata URLs.
# if [[ -z "${PUBLIC_IP}" ]]; then
#   for METADATA_URL in "${METADATA_URLS[@]}"; do
#     METADATA_IP="$(timeout 2 curl --silent --show-error "${METADATA_URL}" | head --lines=1 || true)"
#     if [[ "${METADATA_IP}" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
#       PUBLIC_IP="${METADATA_IP}"
#       break
#     fi
#   done
# fi

if [[ -n "${PUBLIC_IP}" ]]; then
  echo "* Detected public IP ${PUBLIC_IP}"
fi

# Request an automatic DNS entry if we detect a valid IP address.
if [[ -n "${PUBLIC_IP}" ]]; then
  echo "* Requesting automatic domain name..."
  AUTODOMAIN="$(timeout 10 curl --silent --show-error "https://bunker.services/autodomain?ip=${PUBLIC_IP}" | grep 'warpspeedvpn' || true)"
  if [[ -n "${AUTODOMAIN}" ]]; then
    echo "* Automatic domain name ${AUTODOMAIN}"
  else
    echo "* Unable to acquire automatic domain name..."
  fi
fi

# Check if user wants to use the auto domain.
if [[ -n "${AUTODOMAIN}" ]]; then
  echo
  echo "Use automatic DNS address ${AUTODOMAIN}?"
  echo
  read -p "Enter 'no' to use a custom DNS address (Y/n): " USE_AUTODOMAIN
  if ! [[ "${USE_AUTODOMAIN}" =~ ^\ *[Nn] ]]; then
    WARPSPEED_HTTP_HOST="${AUTODOMAIN}"
  fi
fi

# Ask the user for a custom domain.
if [[ -z "${WARPSPEED_HTTP_HOST}" ]]; then

  cat <<__MESSAGE__
---------------------------------------
     Add DNS Record for Public IP
---------------------------------------

  From your DNS provider's control panel, create an "A" record
  with the value of your server's public IP address.
  
  + Any DNS name that can be resolved on the public internet will work.
  + Replace vpn.example.com below with any valid domain name you control.
  + A TTL of 600 seconds (10 minutes) is recommended.
  
  Example DNS record:
  
    NAME                TYPE   VALUE
    ----                ----   -----
    vpn.example.com.    A      ${PUBLIC_IP:-Server public IP}

  **IMPORTANT**
  It's recommended to wait 3-5 minutes after creating a new DNS record
  before attempting to query, ping, or access it in any way. If you
  query it too early your DNS resolver will cache a negative response
  and you will have to wait 5-10 minutes for it to resolve correctly.
  
__MESSAGE__

  if [[ -z "${WARPSPEED_HTTP_HOST}" ]]; then
    read -p "Enter your public DNS address (e.g. vpn.example.com): " WARPSPEED_HTTP_HOST
  fi
fi

if [[ -z "${WARPSPEED_HTTP_HOST}" ]]; then
  usage "No public DNS address specified"
fi

if [[ "${WARPSPEED_HTTP_HOST}" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
  usage "Invalid public DNS address (must not be an IP address)"
fi

if [[ "${WARPSPEED_HTTP_HOST}" =~ amazonaws.com ]]; then
  usage "Invalid public DNS address (must not be an AWS domain)"
fi

if [[ -z "${WARPSPEED_ADMIN_EMAIL}" ]]; then
  read -p "Enter an admin email address (e.g. admin@example.com): " WARPSPEED_ADMIN_EMAIL
fi

if [[ -z "${WARPSPEED_ADMIN_EMAIL}" ]]; then
  usage "No admin email specified"
fi

# Clean up input:
WARPSPEED_ADMIN_EMAIL="$(echo -e "${WARPSPEED_ADMIN_EMAIL}" | tr --delete '[:space:]')"

WARPSPEED_HTTP_HOST="$(echo -e "${WARPSPEED_HTTP_HOST}" | tr --delete '[:space:]')"
WARPSPEED_HTTP_HOST="${WARPSPEED_HTTP_HOST//\//}"
WARPSPEED_HTTP_HOST="${WARPSPEED_HTTP_HOST//https:/}"
WARPSPEED_HTTP_HOST="${WARPSPEED_HTTP_HOST//http:/}"

if [[ ! -d "${WARPSPEED_DATA_DIR}" ]]; then
  mkdir --parents "${WARPSPEED_DATA_DIR}"
fi

#
# Generate service environment file.
#
cat <<__WARPSPEED_CONFIG__ >"${WARPSPEED_DATA_DIR}/warpspeed.conf"
WARPSPEED_SECRETS_FILE="${WARPSPEED_SECRETS_FILE}"
WARPSPEED_DATA_DIR="${WARPSPEED_DATA_DIR}"
WARPSPEED_HTTP_HOST="${WARPSPEED_HTTP_HOST}"
WARPSPEED_ADMIN_EMAIL="${WARPSPEED_ADMIN_EMAIL}"
WARPSPEED_ADMIN_PASSWORD="${WARPSPEED_ADMIN_PASSWORD}"
__WARPSPEED_CONFIG__

#
# Download and install WarpSpeed.
#
echo "* Downloading WarpSpeed"
curl \
  --silent \
  --show-error \
  --fail \
  --output /usr/bin/warpspeed.tmp \
  "${DOWNLOAD_URL}"
chmod 755 /usr/bin/warpspeed.tmp
mv --force /usr/bin/warpspeed.tmp /usr/bin/warpspeed

#
# Install WireGuard.
#

if ! wg version >/dev/null 2>&1; then
  echo "* Installing WireGuard..."
  apt update --yes
  apt install --yes wireguard
fi

#
# Load kernel modules.
#
echo "* Loading kernel modules..."
for KERNEL_MODULE in wireguard iptable_nat ip6table_nat; do
  modprobe "${KERNEL_MODULE}"
  if ! grep --quiet "${KERNEL_MODULE}" /etc/modules; then
    echo "${KERNEL_MODULE}" >>/etc/modules
  fi
done

#
# Configure kernel settings.
#
echo "* Enabling IP forwarding..."
for SYSCTL in net.ipv4.ip_forward=1 net.ipv6.conf.all.forwarding=1; do
  if ! grep --quiet "^${SYSCTL}" /etc/sysctl.conf; then
    echo "${SYSCTL}" >>/etc/sysctl.conf
  fi
done
sysctl --quiet -p

#
# Create the systemd service.
#
echo "* Creating WarpSpeed system service..."
cat <<UNIT >/etc/systemd/system/warpspeed.service
[Unit]
Description=WarpSpeed Service

[Service]
Restart=always
Type=simple
EnvironmentFile=${WARPSPEED_DATA_DIR}/warpspeed.conf
ExecStart=/usr/bin/warpspeed
LimitNOFILE=32786
StartLimitInterval=0
RestartSec=10

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable warpspeed
systemctl restart warpspeed

#
# Wait for the secrets file to be generated.
#
sleep 1
for ATTEMPT in {1..30}; do
  if [[ -e "${WARPSPEED_SECRETS_FILE}" ]] && [[ -s "${WARPSPEED_SECRETS_FILE}" ]]; then
    break
  fi
  echo "* Waiting for WarpSpeed to complete initialization..."
  sleep 2
done

#
# Only proceed beyond here if we're in interactive mode.
#
if [[ "${FLAG_INTERACTIVE}" == "false" ]]; then
  exit 0
fi


#
# Provide information to the admin.
#
cat <<__ADMIN_MESSAGE__
========================================================================
WarpSpeed installation successful! 
------------------------------------------------------------------------

Check service status      : sudo systemctl status warpspeed
Watch service logs        : sudo journalctl --unit warpspeed --follow
View service config       : sudo cat ${WARPSPEED_DATA_DIR}/warpspeed.conf
Backup service data       : ${WARPSPEED_DATA_DIR}
Initial admin credentials : cat ${WARPSPEED_SECRETS_FILE}

Required Firewall Ports
------------------------------------------------------------------------
Service                Direction  Port   Protocol  Source
-------                ---------  ----   --------  ----------------------
HTTP TLS verification  Inbound    80     TCP       Any
HTTP Control Panel     Inbound    443    TCP       Any
WireGuard VPN          Inbound    51820  UDP       Any

Sign in to WarpSpeed
------------------------------------------------------------------------

$(cat ${WARPSPEED_SECRETS_FILE})

For assistance, email: support@bunker.services
========================================================================
__ADMIN_MESSAGE__

#
# Determine the authoritative DNS server for the host address.
#
if dig -h >/dev/null; then
  HOST_DNS_SERVER=""
  HOST_DOMAIN="$(echo -e "${WARPSPEED_HTTP_HOST}" | cut --delimiter=. --fields=2-)"
  while [[ -z "${HOST_DNS_SERVER}" ]]; do
    HOST_DNS_SERVER="$(dig +short ns "${HOST_DOMAIN}" | head --lines=1)"
    HOST_DOMAIN="$(echo -e "${HOST_DOMAIN}" | cut --delimiter=. --fields=2-)"
    if [[ -z "${HOST_DOMAIN}" ]]; then
      echo "WARNING: failed to determine DNS server for ${WARPSPEED_HTTP_HOST}"
      echo "which could indicate a problem with DNS for this address."
      echo "a publicly resolvable DNS record is required."
      echo
      echo "If you used the wrong DNS host address, edit the WARPSPEED_HTTP_HOST"
      echo "value in ${WARPSPEED_DATA_DIR}/warpspeed.conf and then run:"
      echo
      echo "  sudo systemctl restart warpspeed"
      echo
      break
    fi
  done

  #
  # Check if the DNS record for the host exists, if we found the DNS server.
  #
  if [[ -n "${HOST_DNS_SERVER}" ]]; then
    echo
    HOST_CHECK_COUNTER=1
    while [[ -z "${RESOLVED_IP}" ]]; do
      printf "* Please wait! Checking for DNS record %s (#%d)...\r" "${WARPSPEED_HTTP_HOST}" ${HOST_CHECK_COUNTER}
      RESOLVED_IP="$(dig +short "@${HOST_DNS_SERVER}" "${WARPSPEED_HTTP_HOST}")"
      HOST_CHECK_COUNTER=$((HOST_CHECK_COUNTER + 1))
      sleep 1
    done
    if [[ "${RESOLVED_IP}" != "${PUBLIC_IP}" ]]; then
      echo
      echo "WARNING: The DNS record ${WARPSPEED_HTTP_HOST}"
      echo "resolved to the IP address ${RESOLVED_IP}"
      echo "not expected IP address    ${PUBLIC_IP}"
      echo "This could indicate a problem with your DNS record."
      echo
    else
      echo
      echo "* DNS record has resolved successfully. Proceed to WarpSpeed!"
    fi
  fi
fi