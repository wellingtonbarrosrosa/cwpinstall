#!/bin/bash

### === FUNÇÕES ===

# Verificar se é root
check_root() {
  if [ "$EUID" -ne 0 ]; then
    echo "❌ Por favor, execute este script como root."
    exit 1
  fi
}

# Perguntar o tamanho da swap
get_swap_size() {
  echo "🧠 Qual o tamanho desejado para o arquivo de swap (em GB)?"
  read SWAP_SIZE_GB
  if ! [[ "$SWAP_SIZE_GB" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    echo "❌ Por favor, insira um valor numérico válido."
    exit 1
  fi
}

# Perguntar o tamanho do bloco
get_block_size() {
  echo "📏 Qual o tamanho do bloco (em MB)? (Ex: 1 para 1MB, 4 para 4MB)"
  read BLOCK_SIZE_MB
  if ! [[ "$BLOCK_SIZE_MB" =~ ^[0-9]+$ ]]; then
    echo "❌ Por favor, insira um valor numérico válido para o tamanho do bloco."
    exit 1
  fi
}

# Desativa swaps antigos
disable_old_swap() {
  echo "🔁 Desativando swaps antigos, se houver..."
  swapoff -a
}

# Remove swaps antigos do fstab
remove_old_swap_from_fstab() {
  echo "🧹 Limpando swaps antigos do /etc/fstab..."
  sed -i.bak '/swap/d' /etc/fstab
}

# Cria nova swap
create_swap() {
  SWAP_FILE="/swapfile"
  SWAP_SIZE_BYTES=$(echo "$SWAP_SIZE_GB * 1024 * 1024 * 1024" | bc | awk '{print int($1)}')
  COUNT=$((SWAP_SIZE_BYTES / (BLOCK_SIZE_MB * 1024 * 1024)))

  echo "🛠️ Criando arquivo de swap com ${SWAP_SIZE_GB}G usando blocos de ${BLOCK_SIZE_MB}MB..."
  dd if=/dev/zero of=${SWAP_FILE} bs=${BLOCK_SIZE_MB}M count=${COUNT} status=progress || { echo "❌ Erro ao criar o swap."; exit 1; }
  chmod 600 ${SWAP_FILE}
  mkswap ${SWAP_FILE}
}

# Ativa a nova swap
enable_swap() {
  echo "⚡ Ativando o arquivo de swap..."
  swapon ${SWAP_FILE} || { echo "❌ Erro ao ativar o swap."; exit 1; }
}

# Atualiza o fstab
update_fstab() {
  echo "📄 Atualizando /etc/fstab..."
  echo "${SWAP_FILE} swap swap defaults 0 0" >> /etc/fstab
}

# Confirma swaps ativos
verify_swap() {
  echo "📊 Verificando swaps ativos:"
  swapon --show
}

# Define hostname
set_hostname() {
  echo "🖥️ Definindo hostname para bewaves.vps-kinghost.net..."
  hostnamectl set-hostname bewaves.vps-kinghost.net
}

# Instala pacotes essenciais
install_packages() {
  echo "📦 Instalando pacotes básicos..."
  yum install epel-release wget git -y
  yum update -y
}

# Instala CWP
install_cwp() {
  echo "🌐 Instalando o CentOS Web Panel (CWP)..."
  cd /usr/local/src || exit
  wget http://centos-webpanel.com/cwp-el9-latest
  sh cwp-el9-latest
}

# Reinicia o sistema
reboot_system() {
  echo "🔁 Reiniciando o sistema em 10 segundos..."
  sleep 10
  reboot
}

### === EXECUÇÃO EM ORDEM CORRETA ===

check_root
get_swap_size
get_block_size
disable_old_swap
remove_old_swap_from_fstab
create_swap
enable_swap
update_fstab
verify_swap
set_hostname           
install_packages
install_cwp
reboot_system
