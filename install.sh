#!/bin/sh

# =================================================================================
# Sing-Box Padavan Smart Crawler (v2.0) - Bulletproof Auto-Installer
# Repository: https://github.com/Sophiedevops/singbox-padavan-easy-crawler-2
# =================================================================================

# --- Настройки ---
REPO_URL="https://raw.githubusercontent.com/Sophiedevops/singbox-padavan-easy-crawler-2/main"
WORKDIR="/opt/tmp_sb_ext/sing-box-1.12.12-extended-1.5.1-linux-mipsle"
SB_VERSION="1.12.12"
SB_ARCH="linux-mipsle-softfloat"
SB_DOWNLOAD_URL="https://github.com/SagerNet/sing-box/releases/download/v${SB_VERSION}/sing-box-${SB_VERSION}-${SB_ARCH}.tar.gz"

# --- Цвета ---
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
RESET='\033[0m'

echo -e "${CYAN}================================================================${RESET}"
echo -e "${CYAN}  Sing-Box Padavan Smart Crawler (v2.0) - Auto Installer        ${RESET}"
echo -e "${CYAN}================================================================${RESET}"

rollback() {
    echo -e "\n${RED}CRITICAL ERROR: Installation failed! Performing rollback...${RESET}"
    if [ -d "$WORKDIR" ] && [ "$BACKUP_PERFORMED" != "1" ]; then
        echo "  Removing incomplete working directory: $WORKDIR"
        rm -rf "$WORKDIR"
    fi
    echo -e "${RED}Installation aborted.${RESET}"
    exit 1
}

# 1. Проверка среды Entware
echo -e "\n${YELLOW}[1/6] Checking Entware environment...${RESET}"
if [ ! -d "/opt/bin" ] || [ ! -d "/opt/etc" ]; then
    echo -e "${RED}ERROR: Entware (/opt) is not installed or not mounted!${RESET}"
    exit 1
fi
echo -e "  ${GREEN}[OK] Entware detected.${RESET}"

# 2. Авто-Бэкап
echo -e "\n${YELLOW}[2/6] Checking directory status...${RESET}"
BACKUP_PERFORMED=0
if [ -d "$WORKDIR" ]; then
    BACKUP_DIR="${WORKDIR}_backup_$(date +%Y%m%d_%H%M%S)"
    echo -e "  ${YELLOW}Directory already exists. Creating auto-backup:${RESET}"
    echo "  $BACKUP_DIR"
    mv "$WORKDIR" "$BACKUP_DIR" || rollback
    BACKUP_PERFORMED=1
    echo -e "  ${GREEN}[OK] Backup successful.${RESET}"
else
    echo -e "  ${GREEN}[OK] Path is clear.${RESET}"
fi

mkdir -p "$WORKDIR" || rollback
cd "$WORKDIR" || rollback

# 3. Умная установка зависимостей (Проверяем наличие команд, а не пакетов)
echo -e "\n${YELLOW}[3/6] Checking and installing missing utilities...${RESET}"

check_install() {
    local cmd=$1
    local pkg=$2
    if ! which "$cmd" >/dev/null 2>&1; then
        echo -n "  Command '$cmd' not found. Installing '$pkg'... "
        if ! opkg install "$pkg" >/dev/null 2>&1; then
            opkg update >/dev/null 2>&1
            if ! opkg install "$pkg" >/dev/null 2>&1; then
                echo -e "${RED}Failed!${RESET}"
                echo "  Cannot install dependency: $pkg."
                rollback
            fi
        fi
        echo -e "${GREEN}Done.${RESET}"
    else
        echo -e "  $cmd is already available. ${GREEN}[SKIP]${RESET}"
    fi
}

check_install curl curl
check_install jq jq
check_install lua lua
check_install openssl openssl-util
check_install bash bash
check_install sort coreutils-sort
check_install wget wget
check_install tar tar
check_install gzip gzip
# awk проверяется, но так как он встроен в Padavan, установка gawk не потребуется
check_install awk gawk

# 4. Скачивание и валидация ядра Sing-Box
echo -e "\n${YELLOW}[4/6] Downloading & Testing Sing-Box Core (v$SB_VERSION)...${RESET}"
echo "  Downloading from GitHub Releases..."
if wget -qO sb.tar.gz "$SB_DOWNLOAD_URL"; then
    echo "  Extracting archive..."
    tar -xzf sb.tar.gz || rollback
    mv "sing-box-${SB_VERSION}-${SB_ARCH}/sing-box" . || rollback
    rm -rf "sing-box-${SB_VERSION}-${SB_ARCH}" sb.tar.gz
    chmod +x sing-box
    
    echo "  Testing core architecture compatibility..."
    if ! ./sing-box version >/dev/null 2>&1; then
        echo -e "${RED}ERROR: Binary execution failed!${RESET}"
        echo "  The downloaded core is incompatible with your router's CPU architecture."
        rollback
    fi
    echo -e "  ${GREEN}[OK] Sing-Box core passed execution test.${RESET}"
else
    echo -e "${RED}ERROR: Failed to download Sing-Box core!${RESET}"
    rollback
fi

# 5. Загрузка скриптов и шаблонов конфигурации
echo -e "\n${YELLOW}[5/6] Downloading Crawler Scripts & Templates...${RESET}"

download_file() {
    local folder=$1
    local filename=$2
    echo -n "  Downloading $filename... "
    if wget -q -O "$WORKDIR/$filename" "$REPO_URL/$folder/$filename"; then
        echo -e "${GREEN}Done.${RESET}"
    else
        echo -e "${RED}Failed!${RESET}"
        rollback
    fi
}

download_file "scripts" "update.sh"
download_file "scripts" "gen_links.sh"
download_file "scripts" "converter.lua"
download_file "scripts" "utils.lua"
download_file "templates" "conf3_final.json"

chmod +x "$WORKDIR/update.sh"
chmod +x "$WORKDIR/gen_links.sh"

# 6. Уникальная криптография (Генерация ключей и паролей)
echo -e "\n${YELLOW}[6/6] Generating unique security credentials...${RESET}"

CERT_DIR="$WORKDIR/certs/grpc"
mkdir -p "$CERT_DIR"

echo -n "  Generating self-signed TLS certificates for Hysteria2... "
openssl ecparam -genkey -name prime256v1 -out "$CERT_DIR/h2.pem" 2>/dev/null
openssl req -new -x509 -days 36500 -key "$CERT_DIR/h2.pem" -out "$CERT_DIR/h2.cert" -subj "/CN=cloudflare.com" 2>/dev/null
echo -e "${GREEN}Done.${RESET}"

echo -n "  Injecting random passwords into configuration... "
# Генерируем безопасные случайные пароли (HEX, чтобы избежать спецсимволов, ломающих JSON)
SS_PASS=$(openssl rand -hex 12)
HY2_PASS=$(openssl rand -hex 10)

# Внедряем пароли в эталонный конфиг через jq
jq --arg sspass "$SS_PASS" --arg hy2pass "$HY2_PASS" '
    (.inbounds[]? | select(.tag == "ss-in") | .password) = $sspass |
    (.inbounds[]? | select(.tag == "hy2-in") | .users[0].password) = $hy2pass
' "$WORKDIR/conf3_final.json" > "$WORKDIR/tmp.json" && mv "$WORKDIR/tmp.json" "$WORKDIR/conf3_final.json"

cp "$WORKDIR/conf3_final.json" "$WORKDIR/conf2_final.json"
echo -e "${GREEN}Done.${RESET}"

# --- УСПЕХ ---
echo -e "\n${CYAN}================================================================${RESET}"
echo -e "${GREEN}  Installation Successfully Completed! 🎉${RESET}"
echo -e "${CYAN}================================================================${RESET}"
echo -e "Your fully operational working directory is: ${YELLOW}$WORKDIR${RESET}"
echo -e "\nTo start finding and testing proxies, simply run:"
echo -e "  ${YELLOW}cd $WORKDIR && ./update.sh${RESET}"
echo -e "\nTo generate client connection links later, run:"
echo -e "  ${YELLOW}cd $WORKDIR && ./gen_links.sh${RESET}"
echo -e "\nStay secure! 🛡️"
