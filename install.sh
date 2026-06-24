#!/bin/sh

# =================================================================================
# Sing-Box Padavan Smart Crawler (v2.0) - Bulletproof Auto-Installer
# Repository: https://github.com/Sophiedevops/singbox-padavan-easy-crawler-2
# =================================================================================

# --- Настройки ---
REPO_URL="https://raw.githubusercontent.com/Sophiedevops/singbox-padavan-easy-crawler-2/main"
WORKDIR="/opt/tmp_sb_ext/sing-box-1.13.12-extended-2.4.1-linux-mipsle"
SB_DOWNLOAD_URL="https://github.com/Sophiedevops/singbox-padavan-easy-crawler-2/releases/download/untagged-8d572aead4ebcbd58c11/sing-box"

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
echo -e "\n${YELLOW}[1/8] Checking Entware environment...${RESET}"
if [ ! -d "/opt/bin" ] || [ ! -d "/opt/etc" ]; then
    echo -e "${RED}ERROR: Entware (/opt) is not installed or not mounted!${RESET}"
    exit 1
fi
echo -e "  ${GREEN}[OK] Entware detected.${RESET}"

# 2. Авто-Бэкап
echo -e "\n${YELLOW}[2/8] Checking directory status...${RESET}"
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

# 3. Установка зависимостей
echo -e "\n${YELLOW}[3/8] Checking and installing missing utilities...${RESET}"

check_install() {
    local cmd=$1
    local pkg=$2
    if ! which "$cmd" >/dev/null 2>&1; then
        echo -n "  Command '$cmd' not found. Installing '$pkg'... "
        if ! opkg install "$pkg" >/dev/null 2>&1; then
            opkg update >/dev/null 2>&1
            if ! opkg install "$pkg" >/dev/null 2>&1; then
                echo -e "${RED}Failed!${RESET}"
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

# 4. Скачивание ядра Sing-Box
echo -e "\n${YELLOW}[4/8] Downloading & Testing Sing-Box Core...${RESET}"
echo "  Downloading binary from custom repository..."
if curl -k -fL -s -o sing-box "$SB_DOWNLOAD_URL"; then
    chmod +x sing-box
    if ! ./sing-box version >/dev/null 2>&1; then
        echo -e "${RED}ERROR: Binary execution failed!${RESET}"
        rollback
    fi
    echo -e "  ${GREEN}[OK] Sing-Box core passed execution test.${RESET}"
else
    echo -e "${RED}ERROR: Failed to download Sing-Box core!${RESET}"
    rollback
fi

# 5. Загрузка скриптов
echo -e "\n${YELLOW}[5/8] Downloading Crawler Scripts & Templates...${RESET}"

download_file() {
    local filename=$1
    echo -n "  Downloading $filename... "
    if curl -k -fL -s -o "$WORKDIR/$filename" "$REPO_URL/$filename"; then
        echo -e "${GREEN}Done.${RESET}"
    else
        echo -e "${RED}Failed!${RESET}"
        rollback
    fi
}

download_file "update.sh"
download_file "gen_links.sh"
download_file "converter.lua"
download_file "conf3_final.json"

chmod +x "$WORKDIR/update.sh"
chmod +x "$WORKDIR/gen_links.sh"

# 6. Генерация ключей и паролей
echo -e "\n${YELLOW}[6/8] Generating unique security credentials...${RESET}"

CERT_DIR="$WORKDIR/certs/grpc"
mkdir -p "$CERT_DIR"

echo -n "  Generating self-signed TLS certificates for Hysteria2... "
openssl ecparam -genkey -name prime256v1 -out "$CERT_DIR/h2.pem" 2>/dev/null
openssl req -new -x509 -days 36500 -key "$CERT_DIR/h2.pem" -out "$CERT_DIR/h2.cert" -subj "/CN=cloudflare.com" 2>/dev/null
echo -e "${GREEN}Done.${RESET}"

echo -n "  Injecting random passwords into configuration... "
SS_PASS=$(openssl rand -hex 12)
HY2_PASS=$(openssl rand -hex 10)

jq --arg sspass "$SS_PASS" --arg hy2pass "$HY2_PASS" '
    (.inbounds[]? | select(.tag == "ss-in") | .password) = $sspass |
    (.inbounds[]? | select(.tag == "hy2-in") | .users[0].password) = $hy2pass
' "$WORKDIR/conf3_final.json" > "$WORKDIR/tmp.json" && mv "$WORKDIR/tmp.json" "$WORKDIR/conf3_final.json"

cp "$WORKDIR/conf3_final.json" "$WORKDIR/conf2_final.json"
echo -e "${GREEN}Done.${RESET}"

# 7. Настройка Автозапуска и Планировщика (Cron)
echo -e "\n${YELLOW}[7/8] Setting up Autostart and Cron Schedule...${RESET}"

STARTED_SCRIPT="/etc/storage/started_script.sh"
CRON_FILE="/etc/storage/cron/crontabs/admin"
RUN_CMD="nohup $WORKDIR/sing-box run -c $WORKDIR/conf2_final.json >/dev/null 2>&1 &"
CRON_CMD="0 4 */3 * * $WORKDIR/update.sh >/dev/null 2>&1"

# Автозапуск ядра при включении роутера
if [ -f "$STARTED_SCRIPT" ]; then
    if ! grep -q "$WORKDIR/sing-box" "$STARTED_SCRIPT"; then
        echo -n "  Adding sing-box to router startup (started_script.sh)... "
        echo "" >> "$STARTED_SCRIPT"
        echo "# Auto-start Sing-Box" >> "$STARTED_SCRIPT"
        echo "$RUN_CMD" >> "$STARTED_SCRIPT"
        echo -e "${GREEN}Done.${RESET}"
    else
        echo -e "  Autostart already configured. ${GREEN}[SKIP]${RESET}"
    fi
fi

# Периодическое обновление прокси (каждые 3 дня в 04:00)
if [ -d "/etc/storage/cron/crontabs" ]; then
    touch "$CRON_FILE"
    if ! grep -q "$WORKDIR/update.sh" "$CRON_FILE"; then
        echo -n "  Adding update.sh to Cron schedule... "
        echo "$CRON_CMD" >> "$CRON_FILE"
        killall crond 2>/dev/null
        crond
        echo -e "${GREEN}Done.${RESET}"
    else
        echo -e "  Cron schedule already configured. ${GREEN}[SKIP]${RESET}"
    fi
fi

echo -n "  Saving settings to router flash (mtd_storage.sh)... "
mtd_storage.sh save >/dev/null 2>&1
echo -e "${GREEN}Done.${RESET}"

# 8. Автоматический запуск парсера
echo -e "\n${YELLOW}[8/8] Starting Initial Proxy Update & Link Generation...${RESET}"
echo -e "  ${CYAN}This process will download and test proxies. It may take 2-5 minutes.${RESET}"
echo -e "  ${CYAN}Please wait...${RESET}\n"

./update.sh
echo -e "\n${YELLOW}Generating Client Links...${RESET}"
./gen_links.sh

# --- УСПЕХ ---
echo -e "\n${CYAN}================================================================${RESET}"
echo -e "${GREEN}  Installation & Setup Successfully Completed! 🎉${RESET}"
echo -e "${CYAN}================================================================${RESET}"
echo -e "Your working directory is: ${YELLOW}$WORKDIR${RESET}"
echo -e "Your client connection links are saved in: ${GREEN}$WORKDIR/clients.txt${RESET}\n"
cat "$WORKDIR/clients.txt"
echo -e "\nStay secure! 🛡️"
