# 🚀 Instalação Automatizada do Servidor com Swap e CWP

Este repositório contém um script para configurar automaticamente um servidor compatível com CentOS Web Panel (CWP), incluindo swap personalizado, pacotes essenciais, hostname e reboot.

---

## 🧰 Funcionalidades

- Pergunta interativa para configurar o **hostname** (mantendo o atual por padrão)
- Permite definir o **tamanho da SWAP** e o **bloco**
- Remove swaps antigos e ativa nova
- Instala pacotes essenciais
- Instala o **CentOS Web Panel (EL9)**
- Reinicia automaticamente ao final

---

## ⚙️ Requisitos

- Sistema compatível: **AlmaLinux 9**, **Rocky Linux 9** ou **CentOS Stream 9**
- Acesso `root` ou `sudo`
- Git instalado

---

## 📦 Instalação

```bash
git clone https://github.com/wellingtonbarrosrosa/cwpinstall.git
cd cwpinstall
chmod +x cwp.sh
sudo ./cwp.sh
