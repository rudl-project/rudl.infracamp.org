#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_NAME=$(basename "$0")
DEBUG=${DEBUG:-0}
CURRENT_STEP="startup"
CURRENT_COMMAND=""
LAST_COMMAND=""
SUPPORTED_DISTRIBUTIONS=("Ubuntu 26.04")

usage() {
  cat <<'EOF'
Usage:
  rudl-provision-maschine.sh <env-file> [--debug]

Description:
  Loads variables from the given .env file and provisions the server directly in bash.
  No cloud-init is used.

Example:
  sudo bash rudl-provision-maschine.sh ./server.env
  sudo DEBUG=1 bash rudl-provision-maschine.sh ./server.env
  sudo bash rudl-provision-maschine.sh ./server.env --debug
EOF
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" || $# -lt 1 ]]; then
  usage
  [[ $# -lt 1 ]] && exit 1 || exit 0
fi

ENV_FILE=$1
shift || true

if [[ ${1:-} == "--debug" ]]; then
  DEBUG=1
  shift || true
fi

if [[ $# -gt 0 ]]; then
  echo "Unknown argument(s): $*" >&2
  usage >&2
  exit 1
fi

if [[ "$DEBUG" == "1" || "$DEBUG" == "true" ]]; then
  set -x
fi

color() {
  local code=$1
  shift
  printf '\033[%sm%s\033[0m\n' "$code" "$*"
}

info() { color '1;34' "[INFO] $*"; }
warn() { color '1;33' "[WARN] $*"; }
ok()   { color '1;32' "[ OK ] $*"; }
err()  { color '1;31' "[ERR ] $*" >&2; }

track_command() {
  local cmd=${BASH_COMMAND:-}

  case "$cmd" in
    'track_command'|'on_error '*|'trap '*)
      return 0
      ;;
  esac

  LAST_COMMAND=$CURRENT_COMMAND
  CURRENT_COMMAND=$cmd
}

on_error() {
  local exit_code=${1:-$?}
  local line_no=${2:-unknown}
  local failed_command=${3:-${CURRENT_COMMAND:-unknown}}

  err "Provisioning failed."
  err "Step      : ${CURRENT_STEP}"
  err "Line      : ${line_no}"
  err "Command   : ${failed_command:-unknown}"

  if [[ -n ${LAST_COMMAND:-} ]]; then
    err "Previous  : ${LAST_COMMAND}"
  fi

  err "Exit code : ${exit_code}"
  cat >&2 <<'EOF'

Debug tips:
  - Re-run with --debug or DEBUG=1 for shell tracing
  - Check apt logs: /var/log/apt/history.log and /var/log/apt/term.log
  - Check ssh config: sshd -t
  - Check firewall config: nft -c -f /etc/nftables.conf
  - Check service status: systemctl --failed
EOF
  exit "$exit_code"
}
trap 'track_command' DEBUG
trap 'on_error $? $LINENO "$BASH_COMMAND"' ERR

require_root() {
  [[ $EUID -eq 0 ]] || { err "Please run this script as root."; exit 1; }
}

require_file() {
  local path=$1
  [[ -f "$path" ]] || { err "File not found: $path"; exit 1; }
}

run_step() {
  CURRENT_STEP=$1
  shift
  info "$CURRENT_STEP"
  "$@"
  ok "$CURRENT_STEP"
}

run_cmd() {
  info "Running: $*"
  "$@"
}

bool_true() {
  local value=${1:-false}
  value=$(printf '%s' "$value" | tr '[:upper:]' '[:lower:]')
  [[ "$value" == "1" || "$value" == "true" || "$value" == "yes" || "$value" == "on" ]]
}

trim_spaces() {
  local input=${1:-}
  input=${input#${input%%[![:space:]]*}}
  input=${input%${input##*[![:space:]]}}
  printf '%s' "$input"
}

value_or_none() {
  local value
  value=$(trim_spaces "${1:-}")
  if [[ -n "$value" ]]; then
    printf '%s' "$value"
  else
    printf '<none>'
  fi
}

load_env() {
  require_file "$ENV_FILE"
  info "Loading environment from: $ENV_FILE"
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
}

validate_env() {
  local required=(
    HOSTNAME_SHORT
    HOSTNAME_FQDN
    ADMIN_USER
    ADMIN_USER_FULLNAME
    SSH_PUBLIC_KEY
    ADMIN_EMAIL
  )

  local missing=()
  local var
  for var in "${required[@]}"; do
    if [[ -z ${!var:-} ]]; then
      missing+=("$var")
    fi
  done

  if (( ${#missing[@]} > 0 )); then
    err "Missing required variable(s) in $ENV_FILE: ${missing[*]}"
    exit 1
  fi

  if ! [[ "$HOSTNAME_FQDN" == *.* ]]; then
    warn "HOSTNAME_FQDN does not look like a FQDN: $HOSTNAME_FQDN"
  fi

  if [[ "$SSH_PUBLIC_KEY" != ssh-* ]]; then
    warn "SSH_PUBLIC_KEY does not look like a standard SSH public key."
  fi

}

check_os() {
  local distro version pretty_name supported_list

  supported_list=$(printf '%s, ' "${SUPPORTED_DISTRIBUTIONS[@]}")
  supported_list=${supported_list%, }

  if ! command -v lsb_release >/dev/null 2>&1; then
    err "The 'lsb_release' command is required for OS compatibility checks."
    err "Please install it first, e.g.: apt-get update && apt-get install -y lsb-release"
    err "Supported versions: ${supported_list}"
    exit 1
  fi

  distro=$(lsb_release -is 2>/dev/null || true)
  version=$(lsb_release -rs 2>/dev/null || true)
  pretty_name=$(lsb_release -ds 2>/dev/null || true)

  info "Detected OS: ${pretty_name:-${distro:-unknown} ${version:-unknown}}"

  if ! command -v apt-get >/dev/null 2>&1; then
    err "This script currently supports apt-based systems only."
    err "Supported versions: ${supported_list}"
    exit 1
  fi

  if [[ "$distro" != "Ubuntu" || "$version" != "26.04" ]]; then
    err "Unsupported operating system: ${pretty_name:-${distro:-unknown} ${version:-unknown}}"
    err "Supported versions: ${supported_list}"
    exit 1
  fi
}

install_packages() {
  export DEBIAN_FRONTEND=noninteractive
  run_cmd apt-get update
  run_cmd apt-get -y upgrade
  run_cmd apt-get install -y \
    sudo \
    openssh-server \
    nftables \
    unattended-upgrades \
    docker.io \
    apt-listchanges \
    cron \
    lsb-release
}

ensure_user() {
  if id "$ADMIN_USER" >/dev/null 2>&1; then
    info "User already exists: $ADMIN_USER"
  else
    run_cmd adduser --disabled-password --gecos "$ADMIN_USER_FULLNAME" "$ADMIN_USER"
  fi

  run_cmd usermod -aG sudo "$ADMIN_USER"

  install -d -m 0700 -o "$ADMIN_USER" -g "$ADMIN_USER" "/home/$ADMIN_USER/.ssh"
  printf '%s\n' "$SSH_PUBLIC_KEY" > "/home/$ADMIN_USER/.ssh/authorized_keys"
  chown "$ADMIN_USER:$ADMIN_USER" "/home/$ADMIN_USER/.ssh/authorized_keys"
  chmod 0600 "/home/$ADMIN_USER/.ssh/authorized_keys"

  cat > "/etc/sudoers.d/90-${ADMIN_USER}-nopasswd" <<EOF
${ADMIN_USER} ALL=(ALL) NOPASSWD:ALL
EOF
  chmod 0440 "/etc/sudoers.d/90-${ADMIN_USER}-nopasswd"
  run_cmd visudo -cf "/etc/sudoers.d/90-${ADMIN_USER}-nopasswd"

  run_cmd passwd -l "$ADMIN_USER"
}

configure_hostname() {
  info "Setting hostname to: $HOSTNAME_FQDN"
  run_cmd hostnamectl set-hostname "$HOSTNAME_FQDN"

  local hosts_line="127.0.1.1 $HOSTNAME_FQDN $HOSTNAME_SHORT"

  if grep -Eq '^127\.0\.1\.1[[:space:]]+' /etc/hosts; then
    cp /etc/hosts /etc/hosts.bak
    awk -v repl="$hosts_line" '
      BEGIN { done=0 }
      /^127\.0\.1\.1[[:space:]]+/ && done==0 { print repl; done=1; next }
      { print }
      END { if (done==0) print repl }
    ' /etc/hosts.bak > /etc/hosts
  else
    printf '\n%s\n' "$hosts_line" >> /etc/hosts
  fi
}

get_ssh_service_name() {
  if systemctl list-unit-files --type=service --no-legend 2>/dev/null | grep -q '^ssh\.service'; then
    printf '%s' 'ssh'
    return 0
  fi

  if systemctl list-unit-files --type=service --no-legend 2>/dev/null | grep -q '^sshd\.service'; then
    printf '%s' 'sshd'
    return 0
  fi

  err "Could not determine the OpenSSH service name (ssh.service or sshd.service)."
  exit 1
}

configure_ssh() {
  local ssh_service ssh_unit_state

  install -d -m 0755 /etc/ssh/sshd_config.d

  # Use a late-sorting filename so these settings override earlier config.d snippets.
  rm -f /etc/ssh/sshd_config.d/hardened.conf
  cat > /etc/ssh/sshd_config.d/99-rudl-hardened.conf <<'EOF'
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
PermitEmptyPasswords no
MaxAuthTries 3
PerSourceMaxStartups 3
PerSourcePenalties authfail:300
Banner none
DebianBanner no
EOF

  rm -f /etc/ssh/sshd_config.d/permit_root.conf
  rm -f /etc/ssh/sshd_config.d/50-cloud-init.conf
  run_cmd sshd -t

  ssh_service=$(get_ssh_service_name)
  ssh_unit_state=$(systemctl show -p UnitFileState --value "${ssh_service}.service" 2>/dev/null || true)

  case "$ssh_unit_state" in
    disabled)
      run_cmd systemctl enable "$ssh_service"
      ;;
    masked)
      err "${ssh_service}.service is masked. Please unmask it before provisioning."
      exit 1
      ;;
    linked|linked-runtime|alias|static|indirect|generated|enabled|enabled-runtime)
      info "Skipping 'systemctl enable ${ssh_service}' because UnitFileState is '${ssh_unit_state}'."
      ;;
    *)
      warn "Unknown UnitFileState for ${ssh_service}.service: '${ssh_unit_state}'. Trying restart only."
      ;;
  esac

  run_cmd systemctl restart "$ssh_service"
}

parse_port_list() {
  local var_name=$1
  local raw=${2:-}
  local port
  local out=()

  raw=$(trim_spaces "$raw")
  if [[ -z "$raw" ]]; then
    printf '%s' ""
    return 0
  fi

  IFS=',' read -r -a ports <<< "$raw"
  for port in "${ports[@]}"; do
    port=$(trim_spaces "$port")
    [[ -n "$port" ]] || continue
    if [[ ! "$port" =~ ^[0-9]+$ ]]; then
      err "Invalid port in ${var_name}: '$port'"
      exit 1
    fi
    if (( port < 1 || port > 65535 )); then
      err "Port out of range in ${var_name}: '$port'"
      exit 1
    fi
    out+=("$port")
  done

  if (( ${#out[@]} == 0 )); then
    printf '%s' ""
    return 0
  fi

  local joined
  joined=$(IFS=,; echo "${out[*]}")
  printf '%s' "$joined"
}

configure_firewall() {
  local tcp_ports udp_ports
  local tcp_rule="" udp_rule=""

  tcp_ports=$(parse_port_list "OPEN_PORTS_TCP" "${OPEN_PORTS_TCP:-}")
  udp_ports=$(parse_port_list "OPEN_PORTS_UDP" "${OPEN_PORTS_UDP:-}")

  if [[ -n "$tcp_ports" ]]; then
    tcp_rule="    tcp dport { ${tcp_ports} } accept"
  fi

  if [[ -n "$udp_ports" ]]; then
    udp_rule="    udp dport { ${udp_ports} } accept"
  fi

  cat > /etc/nftables.conf <<EOF
#!/usr/sbin/nft -f

flush ruleset

table inet filter {
  chain input {
    type filter hook input priority 0;
    policy drop;

    iif "lo" accept
    ct state established,related accept
    ct state invalid drop

    ip protocol icmp accept
    ip6 nexthdr icmpv6 accept
${tcp_rule}
${udp_rule}
  }

  chain forward {
    type filter hook forward priority 0;
    policy drop;
  }

  chain output {
    type filter hook output priority 0;
    policy accept;
  }
}
EOF

  chmod 0755 /etc/nftables.conf
  run_cmd nft -c -f /etc/nftables.conf
  run_cmd systemctl enable nftables
  run_cmd systemctl restart nftables
}

configure_cron() {
  if bool_true "${INSTALL_DOCKER_PRUNE_CRON:-true}"; then
    cat > /etc/cron.d/docker-prune <<'EOF'
0 3 * * * root command -v docker >/dev/null 2>&1 && /usr/bin/docker system prune -af >/var/log/docker-prune.log 2>&1
EOF
    chmod 0644 /etc/cron.d/docker-prune
    info "Docker prune cron enabled."
  else
    rm -f /etc/cron.d/docker-prune
    info "Docker prune cron disabled."
  fi

  run_cmd systemctl enable cron
  run_cmd systemctl restart cron
}

configure_unattended_upgrades() {
  cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

  cat > /etc/apt/apt.conf.d/51unattended-upgrades-local <<EOF
Unattended-Upgrade::Mail "${ADMIN_EMAIL}";
Unattended-Upgrade::MailReport "on-change";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

  run_cmd systemctl enable unattended-upgrades
  run_cmd systemctl restart unattended-upgrades
}

configure_dns() {
  local disable_stub=${DISABLE_SYSTEMD_RESOLVED_STUB:-false}

  if bool_true "$disable_stub"; then
    install -d -m 0755 /etc/systemd/resolved.conf.d
    cat > /etc/systemd/resolved.conf.d/99-disable-stub.conf <<'EOF'
[Resolve]
DNSStubListener=no
EOF
    info "Prepared systemd-resolved stub listener disable config."

    if systemctl list-unit-files --type=service --no-legend 2>/dev/null | grep -q '^systemd-resolved\.service'; then
      run_cmd systemctl restart systemd-resolved
    fi
  else
    info "Leaving systemd-resolved stub listener unchanged."
  fi
}

print_summary() {
  cat <<EOF

Provisioning completed successfully.

Summary:
  Hostname              : ${HOSTNAME_FQDN}
  Admin user            : ${ADMIN_USER}
  SSH key login         : configured
  Password SSH login    : disabled
  Root SSH login        : disabled
  Open TCP ports        : $(value_or_none "${OPEN_PORTS_TCP:-}")
  Open UDP ports        : $(value_or_none "${OPEN_PORTS_UDP:-}")
  Docker prune cron     : ${INSTALL_DOCKER_PRUNE_CRON:-true}
  Disable DNS stub      : ${DISABLE_SYSTEMD_RESOLVED_STUB:-false}

Recommended checks:
  - sshd -t
  - nft list ruleset
  - systemctl --failed
  - getent hosts ${HOSTNAME_FQDN}

A reboot is recommended after first provisioning.
EOF
}

main() {
  require_root
  load_env
  validate_env
  check_os

  run_step "Install required packages" install_packages
  run_step "Create and configure admin user" ensure_user
  run_step "Configure hostname and /etc/hosts" configure_hostname
  run_step "Configure SSH hardening" configure_ssh
  run_step "Configure nftables firewall" configure_firewall
  run_step "Configure cron jobs" configure_cron
  run_step "Configure unattended upgrades" configure_unattended_upgrades
  run_step "Configure DNS settings" configure_dns

  print_summary
}

main "$@"
