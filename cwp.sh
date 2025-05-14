#!/bin/bash

LOG_FILE="/var/log/cwpinstalador.log"

# Função: verificar se é root
check_root() {
  if [ "$EUID" -ne 0 ]; then
    echo "Execute como root." >&2
    exit 1
  fi
}

# Função: configurar hostname
set_hostname() {
  current_hostname=$(hostname)
  echo "Hostname atual: $current_hostname"
  read -p "Digite o novo hostname (ou pressione Enter para manter o atual): " new_hostname
  new_hostname=${new_hostname:-$current_hostname}
  echo "Definindo hostname para: $new_hostname"
  hostnamectl set-hostname "$new_hostname"
}

# Função: configurar swap
setup_swap() {
  read -p "Digite o tamanho do swap (em GB): " SWAP_SIZE_GB
  if ! [[ "$SWAP_SIZE_GB" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    echo "Tamanho inválido." >&2
    exit 1
  fi

  read -p "Tamanho do bloco (em MB, ex: 1): " BLOCK_SIZE_MB
  if ! [[ "$BLOCK_SIZE_MB" =~ ^[0-9]+$ ]]; then
    echo "Tamanho de bloco inválido." >&2
    exit 1
  fi

  echo "Criando swap de $SWAP_SIZE_GB GB com bloco de $BLOCK_SIZE_MB MB..."

  swapoff -a
  sed -i.bak '/swap/d' /etc/fstab

  SWAP_FILE="/swapfile"
  SWAP_SIZE_BYTES=$((SWAP_SIZE_GB * 1024 * 1024 * 1024))
  COUNT=$((SWAP_SIZE_BYTES / (BLOCK_SIZE_MB * 1024 * 1024)))

  dd if=/dev/zero of=$SWAP_FILE bs=${BLOCK_SIZE_MB}M count=$COUNT status=progress
  chmod 600 $SWAP_FILE
  mkswap $SWAP_FILE
  swapon $SWAP_FILE
  echo "$SWAP_FILE swap swap defaults 0 0" >> /etc/fstab

  echo "Swap configurado com sucesso."
}

# Função: script de instalação do CWP (executado em background)
install_cwp() {
  echo "Iniciando instalação do CWP em background..."
  (
    echo "### Início da instalação: $(date)"
    yum install epel-release -y
    yum install git wget -y
    yum update -y --allowerasing

    cd /usr/local/src
    wget http://centos-webpanel.com/cwp-el9-latest
    sh cwp-el9-latest

    echo "### Fim da instalação: $(date)"
    echo "Reinicie o sistema após o término."
  ) &> "$LOG_FILE" &
  echo "Instalação em andamento. Verifique o log com: tail -f $LOG_FILE"
}

# Execução principal
check_root
set_hostname
setup_swap
install_cwp
