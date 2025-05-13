#!/bin/bash

# Caminho do arquivo de log
LOGFILE="/var/log/cwp_install.log"

# Função para verificar privilégios de root
check_root() {
  if [ "$EUID" -ne 0 ]; then
    echo "❌ Por favor, execute este script como root."
    echo "$(date) - ERRO: O script precisa ser executado como root." >> "$LOGFILE"
    exit 1
  fi
}

# Função para configurar o hostname com valor padrão (o atual)
set_hostname() {
  CURRENT_HOSTNAME=$(hostname)
  echo "🖥️ Hostname atual: $CURRENT_HOSTNAME"
  echo "$(date) - Hostname atual: $CURRENT_HOSTNAME" >> "$LOGFILE"
  
  read -p "Digite o novo hostname (ou pressione Enter para manter o atual): " NEW_HOSTNAME

  # Se o usuário não digitar nada, mantém o atual
  if [ -z "$NEW_HOSTNAME" ]; then
    NEW_HOSTNAME=$CURRENT_HOSTNAME
  fi

  echo "🔧 Definindo hostname para: $NEW_HOSTNAME"
  echo "$(date) - Definindo hostname para: $NEW_HOSTNAME" >> "$LOGFILE"
  hostnamectl set-hostname "$NEW_HOSTNAME" >> "$LOGFILE" 2>&1
}

# Função para configurar o arquivo swap
get_swap_size() {
  echo "🧠 Qual o tamanho desejado para o arquivo de swap (em GB)?"
  echo "$(date) - Perguntando tamanho da swap" >> "$LOGFILE"
  
  read SWAP_SIZE_GB
  if ! [[ "$SWAP_SIZE_GB" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    echo "❌ Por favor, insira um valor numérico válido."
    echo "$(date) - ERRO: Valor inválido para swap." >> "$LOGFILE"
    exit 1
  fi
  echo "$(date) - Tamanho da swap selecionado: $SWAP_SIZE_GB GB" >> "$LOGFILE"
}

# Função para configurar o bloco de swap
get_block_size() {
  echo "📏 Qual o tamanho do bloco (em MB)?"
  read BLOCK_SIZE_MB
  if ! [[ "$BLOCK_SIZE_MB" =~ ^[0-9]+$ ]]; then
    echo "❌ Por favor, insira um valor numérico válido para o tamanho do bloco."
    echo "$(date) - ERRO: Valor inválido para o tamanho do bloco." >> "$LOGFILE"
    exit 1
  fi
  echo "$(date) - Tamanho do bloco selecionado: $BLOCK_SIZE_MB MB" >> "$LOGFILE"
}

# Criar e ativar swap
create_swap() {
  SWAP_FILE="/swapfile"
  SWAP_SIZE_BYTES=$((SWAP_SIZE_GB * 1024 * 1024 * 1024))
  COUNT=$((SWAP_SIZE_BYTES / (BLOCK_SIZE_MB * 1024 * 1024)))
  echo "$(date) - Criando arquivo de swap com ${SWAP_SIZE_GB}G em ${SWAP_FILE}" >> "$LOGFILE"
  
  dd if=/dev/zero of=${SWAP_FILE} bs=${BLOCK_SIZE_MB}M count=${COUNT} status=progress >> "$LOGFILE" 2>&1 || { echo "❌ Erro ao criar o swap." && echo "$(date) - ERRO: Falha ao criar o arquivo de swap" >> "$LOGFILE"; exit 1; }
  
  chmod 600 ${SWAP_FILE}
  mkswap ${SWAP_FILE} >> "$LOGFILE" 2>&1
}

# Ativar o swap
enable_swap() {
  echo "⚡ Ativando o arquivo de swap..."
  swapon ${SWAP_FILE} >> "$LOGFILE" 2>&1 || { echo "❌ Erro ao ativar o swap." && echo "$(date) - ERRO: Falha ao ativar o swap" >> "$LOGFILE"; exit 1; }
}

# Atualizar /etc/fstab
update_fstab() {
  echo "📄 Atualizando /etc/fstab..."
  if ! grep -q "${SWAP_FILE}" /etc/fstab; then
    echo "${SWAP_FILE} swap swap defaults 0 0" >> /etc/fstab
    echo "$(date) - Atualizado /etc/fstab com swap" >> "$LOGFILE"
  fi
}

# Definir hostname
set_hostname

# Instalar pacotes essenciais
echo "📦 Instalando pacotes essenciais..." >> "$LOGFILE"
yum install epel-release wget git -y >> "$LOGFILE" 2>&1

# Atualizar todos os pacotes com a opção --allowerasing
echo "🔄 Atualizando pacotes do sistema..." >> "$LOGFILE"
yum -y update --allowerasing >> "$LOGFILE" 2>&1

# Instalar o CWP
echo "🌐 Instalando CWP..." >> "$LOGFILE"
cd /usr/local/src || exit
wget http://centos-webpanel.com/cwp-el9-latest >> "$LOGFILE" 2>&1
sh cwp-el9-latest >> "$LOGFILE" 2>&1

# Reiniciar o sistema
echo "🔁 Reiniciando o sistema..." >> "$LOGFILE"
reboot

# Finalizar o log
echo "$(date) - Instalação concluída." >> "$LOGFILE"
