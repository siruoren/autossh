#!/usr/bin/dumb-init /bin/sh

# Set up key file
KEY_FILE=${SSH_KEY_FILE:=/id_rsa}
if [ ! -f "${KEY_FILE}" ]; then
    echo "[ERROR] No SSH Key file found"
    exit 1
fi


chmod 600 /id_rsa;
# If known_hosts is provided, STRICT_HOST_KEY_CHECKING=yes
# Default CheckHostIP=yes unless SSH_STRICT_HOST_IP_CHECK=false
STRICT_HOSTS_KEY_CHECKING=no
KNOWN_HOSTS=${SSH_KNOWN_HOSTS:=/known_hosts}
if [ -f "${KNOWN_HOSTS}" ]; then
    KNOWN_HOSTS_ARG="-o UserKnownHostsFile=${KNOWN_HOSTS} "
    if [ "${SSH_STRICT_HOST_IP_CHECK}" = false ]; then
        KNOWN_HOSTS_ARG="${KNOWN_HOSTS_ARG}-o CheckHostIP=no "
    fi
    STRICT_HOSTS_KEY_CHECKING=yes
fi

# Add entry to /etc/passwd if we are running non-root
if [[ $(id -u) != "0" ]]; then
  USER="autossh:x:$(id -u):$(id -g):autossh:/tmp:/bin/sh"
  echo "Creating non-root-user = $USER"
  echo "$USER" >> /etc/passwd
fi

# Pick a random port above 32768
DEFAULT_PORT=$RANDOM
let "DEFAULT_PORT += 32768"

# Determine command line flags
INFO_TUNNEL_SRC="${SSH_HOSTUSER:=root}@${SSH_HOSTNAME:=localhost}:${SSH_TUNNEL_REMOTE:=${DEFAULT_PORT}}"
INFO_TUNNEL_DEST="${SSH_TUNNEL_HOST=localhost}:${SSH_TUNNEL_LOCAL:=22}"
COMMAND="autossh "\
"-M 0 "\
"-N "\
"-i ${KEY_FILE} "\
"-o StrictHostKeyChecking=${STRICT_HOSTS_KEY_CHECKING} ${KNOWN_HOSTS_ARG:=}"\
"-o ServerAliveInterval=${SERVER_ALIVE_INTERVAL:-10} "\
"-o ServerAliveCountMax=${SERVER_ALIVE_COUNT_MAX:-3} "\
"-o ExitOnForwardFailure=yes "\
"-t -t "\
"-g -D ${PROXY_HOSTPORT:=1080} "\
"-p ${SSH_HOSTPORT:=22} "\
"${SSH_HOSTUSER}@${SSH_HOSTNAME}"

# Log to stdout
echo "[INFO] Using $(autossh -V)"
echo "> ${COMMAND}"

# Run command
exec ${COMMAND}
