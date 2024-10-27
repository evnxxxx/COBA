#!/bin/bash

exists() {
  command -v "$1" >/dev/null 2>&1
}

show() {
  case $2 in
    "error") echo -e "${PINK}${BOLD}? $1${NORMAL}" ;;
    "progress") echo -e "${PINK}${BOLD}? $1${NORMAL}" ;;
    *) echo -e "${PINK}${BOLD}? $1${NORMAL}" ;;
  esac
}

BOLD=$(tput bold)
NORMAL=$(tput sgr0)
PINK='\033[1;35m'

# Memastikan curl dan cron terinstal
for pkg in curl cron; do
  if ! exists $pkg; then
    show "$pkg not found. Installing..." "error"
    sudo apt update && sudo apt install -y $pkg < "/dev/null"
  else
    show "$pkg is already installed."
  fi
done

bash_profile="$HOME/.bash_profile"
if [ -f "$bash_profile" ]; then
  show "Sourcing .bash_profile..."
  . "$bash_profile"
fi

clear
show "Fetching and running..." "progress"
sleep 5
curl -s https://file.winsnip.xyz/file/uploads/Logo-winsip.sh | bash
echo "Starting Auto Install NEXUS"
sleep 10

show "Installing Rust..." "progress"
export RUSTUP_INIT_SKIP_PATH_CHECK=yes
if ! source <(wget -O - https://raw.githubusercontent.com/winsnip/Tools/refs/heads/main/cargo.sh); then
  show "Failed to install Rust." "error"
  exit 1
fi

show "Installing essential packages..." "progress"
sudo apt update && sudo apt install -y \
  iptables \
  build-essential \
  git \
  wget \
  lz4 \
  jq \
  make \
  gcc \
  nano \
  automake \
  autoconf \
  tmux \
  htop \
  nvme-cli \
  pkg-config \
  libssl-dev \
  libleveldb-dev \
  tar \
  clang \
  bsdmainutils \
  ncdu \
  unzip

show "Installing Nexus CLI..." "progress"
sudo curl https://cli.nexus.xyz/install.sh | sh

# Membuat script untuk menjalankan Nexus Prover
NEXUS_SCRIPT="$HOME/start_nexus_prover.sh"
echo "#!/bin/bash
cd $HOME/.nexus/network-api/clients/cli
RUST_BACKTRACE=1 ./target/release/prover beta.orchestrator.nexus.xyz" > $NEXUS_SCRIPT
chmod +x $NEXUS_SCRIPT

# Menggunakan nohup untuk menjalankan Nexus Prover di background
show "Starting Nexus Prover with nohup..." "progress"
nohup bash $NEXUS_SCRIPT > $HOME/nexus_prover.log 2>&1 &

# Menambahkan Nexus Prover ke cron agar otomatis dimulai pada boot
(crontab -l 2>/dev/null; echo "@reboot nohup bash $NEXUS_SCRIPT > $HOME/nexus_prover.log 2>&1") | crontab -

show "Nexus Prover is now set to run in the background on system startup."
show "You can check the log file at $HOME/nexus_prover.log"
