#!/bin/bash

LOGFILE="/var/log/cwpinstalador.log"
exec > >(tee -a "$LOGFILE") 2>&1

# Função: Verifica se é root
check_root() {
  if [ "$EUID" -ne 0 ]; then
    echo "❌ Este script precisa ser executado como root."
    exit 1
  fi
}

# Função: Solicita novo hostname com padrão
set_hostname() {
  CURRENT_HOSTNAME=$(hostname)
  echo "💡 Hostname atual: $CURRENT_HOSTNAME"
  read -p "Digite o novo hostname (pressione Enter para manter o atual): " NEW_HOSTNAME

  # Usa o atual se for vazio
  NEW_HOSTNAME=${NEW_HOSTNAME:-$CURRENT_HOSTNAME}

  echo "🔧 Definindo hostname para: $NEW_HOSTNAME"
  hostnamectl set-hostname "$NEW_HOSTNAME"

  if [ $? -ne 0 ]; then
    echo "❌ Erro ao definir hostname. Continuando com o hostname atual: $(hostname)"
  else
    echo "✅ Hostname definido para: $NEW_HOSTNAME"
  fi
}

# Função: Instala pacotes essenciais
install_packages() {
  echo "📦 Instalando pacotes essenciais..."
  yum install -y epel-release git wget --allowerasing
  yum update -y --allowerasing
}

# Função: Baixa e instala o CWP
install_cwp() {
  echo "📥 Baixando CWP..."
  cd /usr/local/src || exit
  wget http://centos-webpanel.com/cwp-el9-latest

  echo "⚙️ Instalando CWP..."
  sh cwp-el9-latest
}

# Função: Configura SWAP
configure_swap() {
  echo "💾 Configuração de SWAP"
  read -p "Tamanho do swap em GB (padrão: 2.5): " SWAP_SIZE_GB
  SWAP_SIZE_GB=${SWAP_SIZE_GB:-2.5}
  read -p "Tamanho do bloco em MB (padrão: 1): " BLOCK_SIZE_MB
  BLOCK_SIZE_MB=${BLOCK_SIZE_MB:-1}

  SWAP_FILE="/swapfile"
  SWAP_SIZE_MB=$(echo "$SWAP_SIZE_GB * 1024" | bc | awk '{printf "%.0f", $1}')
  COUNT=$((SWAP_SIZE_MB / BLOCK_SIZE_MB))

  echo "🛠️ Criando swap de $SWAP_SIZE_GB GB com blocos de $BLOCK_SIZE_MB MB..."

  swapoff -a
  sed -i.bak '/swap/d' /etc/fstab

  dd if=/dev/zero of=${SWAP_FILE} bs=${BLOCK_SIZE_MB}M count=${COUNT} status=progress
  chmod 600 ${SWAP_FILE}
  mkswap ${SWAP_FILE}
  swapon ${SWAP_FILE}
  echo "${SWAP_FILE} swap swap defaults 0 0" >> /etc/fstab

  echo "✅ Swap configurado:"
  swapon --show
}

# Função: Reinicia o sistema
finalize_and_reboot() {
  echo "✅ Script concluído. Reiniciando o sistema em 10 segundos..."
  sleep 10
  reboot
}

# Execução
check_root
set_hostname
install_packages
configure_swap
install_cwp
finalize_and_reboot
