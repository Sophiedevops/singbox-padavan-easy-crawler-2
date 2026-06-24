#!/bin/sh

# === ЦВЕТА / COLORS ===
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
PURPLE='\033[1;35m'
RESET='\033[0m'

echo -e "${CYAN}"
cat << 'EOF'
      /\_/\
     ( o.o )
      > ^ <
           |\__/,|   (`\
         _.|o o  |_   ) )
        -(((---(((--------
=============================================
|/\|/\|/\|/\|/\|/\|/\|/\|/\|/\|/\|/\|/\|/\|/\
       ..                 ..
      <°)))-             <°)))-
=============================================
EOF
echo -e "${RESET}"

# =====================================================================
# [RU] ПОЛЬЗОВАТЕЛЬСКИЕ НАСТРОЙКИ (МОЖНО РЕДАКТИРОВАТЬ)
# [EN] USER SETTINGS (EDITABLE)
# [FA] تنظیمات کاربر (قابل ویرایش)
# [ZH] 用户设置（可编辑）
# [AR] إعدادات المستخدم (قابلة للتحرير)
# =====================================================================
ENCRYPTION_PRIORITY=1
SORT_PRIORITY=0
FILTER_COUNTRIES="nl de us pl fi jp tw sg hk fr se uk gb ca ru tr md kr"
PRIORITY_PROTOCOLS="shadowsocks hysteria2 tuic vless hysteria trojan vmess mieru masque"

# =====================================================================
# [RU] ПОДПИСКИ И ИСТОЧНИКИ
# [EN] SUBSCRIPTIONS AND SOURCES
# [FA] اشتراک‌ها و منابع
# [ZH] 订阅和来源
# [AR] الاشتراكات والمصادر
# =====================================================================
SUBS_LIST="
https://sub.whitedns.one/sub/base64.txt
https://raw.githubusercontent.com/sakha1370/OpenRay/refs/heads/main/output/all_valid_proxies.txt
https://raw.githubusercontent.com/SoliSpirit/v2ray-configs/refs/heads/main/Protocols/ss.txt
https://raw.githubusercontent.com/ebrasha/free-v2ray-public-list/refs/heads/main/all_extracted_configs.txt
https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/refs/heads/main/Config/vless.txt
https://raw.githubusercontent.com/amirkma/proxykma/refs/heads/main/mix.txt
https://raw.githubusercontent.com/mahdibland/V2RayAggregator/refs/heads/master/sub/sub_merge.txt
https://github.com/Epodonios/v2ray-configs/raw/main/All_Configs_base64_Sub.txt
"

# =====================================================================
# [RU] ЗАЩИТНЫЙ БЛОК (НЕ РЕДАКТИРОВАТЬ)
# [EN] PROTECTIVE BLOCK (DO NOT EDIT)
# [FA] بلوک محافظ (ویرایش نکنید)
# [ZH] 保护块（请勿编辑）
# [AR] كتلة الحماية (لا تقم بالتحرير)
# =====================================================================
eval "$(echo "RU5DUllQVElPTl9QUklPUklUWT0ke0VOQ1JZUFRJT05fUFJJT1JJVFk6LTF9OyBTT1JUX1BSSU9SSVRZPSR7U09SVF9QUklPUklUWTotMH07IEZJTFRFUl9DT1VOVFJJRVM9JHtGSUxURVJfQ09VTlRSSUVTOi0ibmwgZGUgdXMgcGwgZmkganAgdHcgc2cgaGsgZnIgc2UgdWsgZ2IgY2EgcnUgdHIgbWQga3IifTsgUFJJT1JJVFlfUFJPVE9DT0xTPSR7UFJJT1JJVFlfUFJPVE9DT0xTOi0iaHlzdGVyaWEyIHR1aWMgc2hhZG93c29ja3Mgdmxlc3MgaHlzdGVyaWEgdHJvamFuIHZtZXNzIG1pZXJ1IG1hc3F1ZSJ9Ow==" | base64 -d 2>/dev/null)"

# =====================================================================
# [RU] ОСНОВНЫЕ ПУТИ И НАСТРОЙКИ
# [EN] MAIN PATHS AND SETTINGS
# [FA] مسیرها و تنظیمات اصلی
# [ZH] 主要路径和设置
# [AR] المسارات والإعدادات الرئيسية
# =====================================================================
WANTED=8
PERFECT_SPEED_KBPS=900
MIN_FAST_CHECK_SPEED_KBPS=600
TEST_PORT=25555
TEST_API_PORT=9092
WORKDIR="/opt/tmp_sb_ext/sing-box-1.13.12-extended-2.4.1-linux-mipsle"
BIN="$WORKDIR/sing-box"
CONF_BASE="$WORKDIR/conf3_final.json"
CONF_TARGET="$WORKDIR/conf2_final.json"
MAIN_PIDFILE="/var/run/sb_update_main.pid"

TEST_URLS="https://speed.cloudflare.com/__down?bytes=15000000 https://cachefly.cachefly.net/10mb.test"
PING_URLS="http://cp.cloudflare.com/generate_204 http://captive.apple.com/hotspot-detect.html http://www.msftconnecttest.com/connecttest.txt http://connect.rom.miui.com/generate_204"
MAX_ACCEPTABLE_PING=3000
TEST_PID=""

# =====================================================================
# [RU] ДИНАМИЧЕСКОЕ РАСПРЕДЕЛЕНИЕ ПАМЯТИ
# [EN] DYNAMIC RAM ALLOCATION
# [FA] تخصیص پویای رم
# [ZH] 动态 RAM 分配
# [AR] التخصيص الديناميكي لذاكرة الوصول العشوائي
# =====================================================================
FREE_RAM=$(awk '/MemFree/ {free=$2} /Buffers/ {buf=$2} /^Cached/ {cache=$2} END {print int((free+buf+cache)/1024)}' /proc/meminfo 2>/dev/null || echo 0)

if [ "$FREE_RAM" -gt 150 ]; then
    TEMP="/tmp/sb_upd3"
    echo -e "${CYAN}[INFO] RAM is sufficient (${FREE_RAM}MB free). Using tmpfs ($TEMP) for turbo speed.${RESET}"
else
    TEMP="$WORKDIR/sb_upd_tmp"
    echo -e "${YELLOW}[WARN] Low RAM (${FREE_RAM}MB free). Using secure storage ($TEMP) to prevent crash.${RESET}"
fi

# =====================================================================
# [RU] БЕЗОПАСНАЯ ОСТАНОВКА И ЗАЩИТА ОТ ЗОМБИ-ПРОЦЕССОВ
# [EN] SAFE SHUTDOWN AND ZOMBIE PROCESS PROTECTION
# [FA] توقف ایمن و محافظت در برابر فرآیندهای زامبی
# [ZH] 安全关闭和僵尸进程保护
# [AR] الإغلاق الآمن والحماية من العمليات العالقة
# =====================================================================
kill_testers() {
    if [ -n "$TEST_PID" ]; then
        kill "$TEST_PID" 2>/dev/null
        sleep 2
        kill -9 "$TEST_PID" 2>/dev/null
    fi
    for p in $(pidof sing-box 2>/dev/null); do
        if cat /proc/$p/cmdline 2>/dev/null | tr '\0' ' ' | grep -qE "$TEMP/(run|fast)\.json"; then
            kill $p 2>/dev/null
            sleep 2
            kill -9 $p 2>/dev/null
        fi
    done
}

trap 'echo -e "\n${RED}[ABORT] Script interrupted! Cleaning up zombies...${RESET}"; kill_testers; rm -rf "$TEMP" "$WORKDIR/subs_raw.txt" "$WORKDIR/all_nodes.json" 2>/dev/null; exit 1' INT TERM

kill_testers

stop_main() {
    if [ -f "$MAIN_PIDFILE" ]; then
        MPID=$(cat "$MAIN_PIDFILE")
        if [ -n "$MPID" ]; then
            kill $MPID 2>/dev/null
            sleep 1
            kill -9 $MPID 2>/dev/null
        fi
        rm -f "$MAIN_PIDFILE"
    fi
    for p in $(pidof sing-box 2>/dev/null); do
        if cat /proc/$p/cmdline 2>/dev/null | tr '\0' ' ' | grep -q "conf2_final\.json"; then
            kill $p 2>/dev/null
            sleep 1
            kill -9 $p 2>/dev/null
        fi
    done
}

start_main() {
    if [ -f "$MAIN_PIDFILE" ] && kill -0 $(cat "$MAIN_PIDFILE") 2>/dev/null; then return; fi
    "$BIN" run -c "$CONF_TARGET" >/dev/null 2>&1 &
    echo $! > "$MAIN_PIDFILE"
}

CDIR=$(pwd)
if [ "$CDIR" != "$WORKDIR" ]; then
    if [ -f "$CDIR/converter.lua" ]; then cp "$CDIR/converter.lua" "$WORKDIR/"; fi
fi

check_provider() {
    ACTIVE_TEST_URL=""
    ACTIVE_PING_URL=""
    local attempt=1
    local max_attempts=5
    local wait_time=2

    while [ $attempt -le $max_attempts ]; do
        echo -e "  ${CYAN}➔ Checking internet connection (Attempt $attempt/$max_attempts)...${RESET}"
        for U in $TEST_URLS; do
            if curl -k -IsL --connect-timeout 5 "$U" 2>/dev/null | grep -qE "HTTP/.* (200|206)"; then
                ACTIVE_TEST_URL="$U"
                DOMAIN=$(echo "$U" | awk -F/ '{print $3}')
                echo -e "  ${GREEN}➔ Speed Test CDN: $DOMAIN${RESET}"
                break
            fi
        done
        
        if [ -n "$ACTIVE_TEST_URL" ]; then
            for P in $PING_URLS; do
                if curl -k -IsL --connect-timeout 4 "$P" 2>/dev/null | grep -qE "HTTP/.* (200|204)"; then
                    ACTIVE_PING_URL="$P"
                    PDOMAIN=$(echo "$P" | awk -F/ '{print $3}')
                    echo -e "  ${GREEN}➔ Ping Auto-Pilot: $PDOMAIN${RESET}"
                    break
                fi
            done
            [ -z "$ACTIVE_PING_URL" ] && ACTIVE_PING_URL="http://cp.cloudflare.com/generate_204"
            return 0
        fi

        echo -e "  ${YELLOW}[WARN] Connection failed. Retrying in $wait_time seconds...${RESET}"
        sleep $wait_time
        wait_time=$((wait_time * 2))
        attempt=$((attempt + 1))
    done

    echo -e "  ${RED}[ERROR] Failed to connect to Speed Test CDNs after $max_attempts attempts! Check your ISP.${RESET}"
    return 1
}

safe_count() {
    [ -f "$1" ] && [ -s "$1" ] && jq 'length' "$1" 2>/dev/null || echo 0
}

write_jq_filters() {
    cat << EOF > "$TEMP/gen.jq"
. as \$n | { "log": { "level": "error" }, "experimental": { "clash_api": { "external_controller": "127.0.0.1:$TEST_API_PORT" } }, "route": { "final": "tester_group" }, "inbounds": [ { "type": "socks", "tag": "socks-test", "listen": "127.0.0.1", "listen_port": $TEST_PORT } ], "outbounds": (\$n + [{ "type": "urltest", "tag": "tester_group", "outbounds": (\$n | map(.tag)), "url": "$ACTIVE_PING_URL", "interval": "1m", "tolerance": 50 }]) }
EOF

    cat << EOF > "$TEMP/sel.jq"
{ "type": "urltest", "tag": "Best-Auto", "outbounds": \$tags[0], "url": "$ACTIVE_PING_URL", "interval": "3m", "tolerance": 50 }
EOF

    cat << 'EOF' > "$TEMP/fin.jq"
.log.level = "warn" | .outbounds += $nodes[0] | .outbounds += $sel | .route.final = "Best-Auto"
EOF

    cat << 'EOF' > "$TEMP/debug.jq"
.proxies | to_entries[] | select(.value.type != "URLTest" and .value.type != "Selector" and .key != "GLOBAL" and .key != "direct" and .key != "block" and .key != "socks-test") | "    - \(.key): \((if .value.history and (.value.history|length>0) then .value.history[-1].delay else 0 end)) ms"
EOF

    cat << EOF > "$TEMP/api_all_valid.jq"
.proxies | to_entries | map(select(.value.history | length > 0) | select(.value.history[-1].delay > 0 and .value.history[-1].delay <= $MAX_ACCEPTABLE_PING) | select(.key != "socks-test" and .key != "tester_group")) | map(.key) | .[]
EOF

    # БЕЗОПАСНЫЕ ФИЛЬТРЫ СОРТИРОВКИ (защита от переноса строк)
    cat << 'EOF' > "$TEMP/ss_sec1.jq"
map(select((.tag | ascii_downcase | index($c) != null) and .method != "none" and (.plugin == null or .plugin == "")))
EOF
    cat << 'EOF' > "$TEMP/ss_sec2.jq"
map(select((.tag | ascii_downcase | index($c) != null) and .method != "none" and .plugin != null and .plugin != ""))
EOF
    cat << 'EOF' > "$TEMP/ss_open.jq"
map(select((.tag | ascii_downcase | index($c) != null) and .method == "none"))
EOF
    cat << 'EOF' > "$TEMP/vless_sec.jq"
map(select((.tag | ascii_downcase | index($c) != null) and .type == "vless" and .tls.enabled == true))
EOF
    cat << 'EOF' > "$TEMP/type_sec.jq"
map(select((.tag | ascii_downcase | index($c) != null) and .type == $p))
EOF
    cat << 'EOF' > "$TEMP/vless_naked.jq"
map(select((.tag | ascii_downcase | index($c) != null) and .type == "vless" and (.tls.enabled == null or .tls.enabled == false)))
EOF
    cat << 'EOF' > "$TEMP/unique.jq"
map(. as $n | select($tags[0] | index($n.tag))) | unique_by(.tag)
EOF

    echo -e "  ${PURPLE}[DEBUG] Status Tracker Active:${RESET}" > "$TEMP/debug_header"
}

prepare_temp() {
    kill_testers && sleep 1
    rm -rf "$TEMP" 2>/dev/null
    mkdir -p "$TEMP" || return 1
    touch "$TEMP/results.txt" || return 1
    write_jq_filters || return 1
    return 0
}

# =====================================================================
# [RU] 1. УМНАЯ БЫСТРАЯ ПРОВЕРКА
# =====================================================================
if [ -f "$CONF_TARGET" ]; then
    echo -e "${CYAN}Checking existing nodes (Strict Mode)...${RESET}"
    if check_provider; then
        if prepare_temp; then
            nice -n 19 jq '[.outbounds[] | select(.type != "urltest" and .type != "selector" and .type != "direct" and .type != "dns" and .type != "block")]' "$CONF_TARGET" > "$TEMP/fast.json"
            TOTAL_FAST=$(safe_count "$TEMP/fast.json")
            
            if [ "$TOTAL_FAST" -gt 0 ]; then
                nice -n 19 jq -f "$TEMP/gen.jq" "$TEMP/fast.json" > "$TEMP/run.json"
                "$BIN" run -c "$TEMP/run.json" >/dev/null 2>&1 &
                TEST_PID=$!
                sleep 12
                
                VALID_FAST_NODES=$(curl -s http://127.0.0.1:$TEST_API_PORT/proxies | nice -n 19 jq -r -f "$TEMP/api_all_valid.jq")
                STABLE_COUNT=0
                STABLE_THRESHOLD=$(( (WANTED * 70 + 50) / 100 ))
                echo -e "  ${PURPLE}Retention Threshold set to: $STABLE_THRESHOLD nodes (70% of WANTED)${RESET}"
                
                for NODE in $VALID_FAST_NODES; do
                    if [ -n "$NODE" ] && [ "$NODE" != "null" ]; then
                        curl -s -X PUT -H "Content-Type: application/json" -d "{\"name\":\"$NODE\"}" "http://127.0.0.1:$TEST_API_PORT/proxies/tester_group" >/dev/null 2>&1
                        sleep 3
                        
                        SPD=$(curl -x socks5://127.0.0.1:$TEST_PORT -sL -o /dev/null -w "%{speed_download}" --connect-timeout 6 --max-time 20 "$ACTIVE_TEST_URL" 2>/dev/null)
                        KBPS=$(echo "$SPD" | awk '{print int($1 / 1024)}')
                        
                        if [ "$KBPS" -ge "$MIN_FAST_CHECK_SPEED_KBPS" ]; then
                            echo -e "  Node $NODE: ${GREEN}$KBPS KB/s${RESET} (Acceptable)"
                            STABLE_COUNT=$((STABLE_COUNT+1))
                        else
                            echo -e "  Node $NODE: ${YELLOW}$KBPS KB/s${RESET} (Too slow)"
                        fi
                    fi
                done
                kill_testers
                
                if [ "$STABLE_COUNT" -ge "$STABLE_THRESHOLD" ]; then
                    echo -e "  ${GREEN}Current pool is acceptable ($STABLE_COUNT/$TOTAL_FAST nodes verified). Aborting full scan pipeline...${RESET}"
                    start_main && rm -rf "$TEMP" "$WORKDIR/subs_raw.txt" "$WORKDIR/all_nodes.json" 2>/dev/null && exit 0
                fi
                echo -e "  ${RED}Only $STABLE_COUNT/$STABLE_THRESHOLD acceptable nodes left. Forcing full update...${RESET}"
            fi
        fi
    else
        echo -e "  ${YELLOW}[WARN] Internet check failed during Fast Check. Proceeding to Full Update...${RESET}"
    fi
fi

# =====================================================================
# [RU] 2. СКАЧИВАНИЕ И АВТО-ДЕКОДИРОВАНИЕ БАЗЫ
# =====================================================================
echo -e "${CYAN}Starting Full Update & Base64 Decoding...${RESET}"

if ! check_provider; then
    echo -e "${RED}[FATAL] Internet check failed! Cannot download subscriptions. Exiting.${RESET}"
    exit 1
fi

if ! prepare_temp; then
    echo -e "${RED}[FATAL] Failed to create or write to TEMP folder ($TEMP). Check disk space! Exiting.${RESET}"
    exit 1
fi

> "$TEMP/all_subs.txt"

cat << 'EOF' > "$TEMP/dec.lua"
local f = io.open(arg[1], "r")
if not f then os.exit(1) end
local str = f:read("*a"):gsub("[%s%c]", ""):gsub("-", "+"):gsub("_", "/")
f:close()

local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local res = {}
for i = 1, #str, 4 do
    local n = 0
    for j = 0, 3 do
        local c = str:sub(i+j, i+j)
        local val = b:find(c, 1, true)
        if val then n = n + (val - 1) * (64^(3-j)) end
    end
    table.insert(res, string.char(math.floor(n / 65536)))
    if str:sub(i+2, i+2) ~= "=" then table.insert(res, string.char(math.floor((n % 65536) / 256))) end
    if str:sub(i+3, i+3) ~= "=" then table.insert(res, string.char(n % 256)) end
end
print(table.concat(res))
EOF

for URL in $SUBS_LIST; do
    FNAME=$(basename "$URL")
    if curl -k -sL -A "v2rayNG/1.8.5" -o "$TEMP/part.tmp" "$URL"; then
        tr -d '\000\r' < "$TEMP/part.tmp" > "$TEMP/part.txt"
        
        if ! grep -qE "^(ss|vmess|vless|trojan|hysteria2|hy2|hysteria|tuic|mieru|masque)://" "$TEMP/part.txt" 2>/dev/null; then
            nice -n 19 lua "$TEMP/dec.lua" "$TEMP/part.txt" > "$TEMP/part_dec.txt" 2>/dev/null
            if grep -qE "^(ss|vmess|vless|trojan|hysteria2|hy2|hysteria|tuic|mieru|masque)://" "$TEMP/part_dec.txt" 2>/dev/null; then
                mv "$TEMP/part_dec.txt" "$TEMP/part.txt"
            fi
        fi

        nice -n 19 grep -E "^(ss|vmess|vless|trojan|hysteria2|hy2|hysteria|tuic|mieru|masque)://" "$TEMP/part.txt" > "$TEMP/links.tmp" 2>/dev/null
        ADDED=$(wc -l < "$TEMP/links.tmp" | tr -d ' ')
        
        if [ -n "$ADDED" ] && [ "$ADDED" -gt 0 ]; then
            cat "$TEMP/links.tmp" >> "$TEMP/all_subs.txt"
            echo -e "  [${GREEN}OK${RESET}] Source: $FNAME ($ADDED valid links)"
        else
            echo -e "  [${YELLOW}WARN${RESET}] Source $FNAME returned corrupt/non-proxy text (Skipped)"
        fi
    else
        echo -e "  [${RED}FAIL${RESET}] Source: $FNAME (HTTP Error)"
    fi
    rm -f "$TEMP/part.tmp" "$TEMP/part.txt" "$TEMP/part_dec.txt" "$TEMP/links.tmp"
done

if [ ! -s "$TEMP/all_subs.txt" ]; then
    echo -e "${RED}ERROR: All subscription links returned empty or corrupt data!${RESET}"
    start_main && rm -rf "$TEMP" && exit 1
fi

# =====================================================================
# [RU] 3. УМНАЯ ПРЕ-ФИЛЬТРАЦИЯ (АЛМАЗНЫЙ ЭКСТРАКТОР 2.0)
# =====================================================================
cd "$WORKDIR"
echo -e "${CYAN}Applying Diamond Extractor 2.0: Strict protocol distribution & RAM protection...${RESET}"

COUNTRY_REGEX=$(echo "$FILTER_COUNTRIES" | tr ' ' '|')
> subs_raw.txt

sample_nodes() {
    local file=$1
    local limit=$2
    if [ -s "$file" ]; then
        local count=$(wc -l < "$file" | tr -d ' ')
        if [ "$count" -gt "$limit" ]; then
            local step=$((count / limit + 1))
            nice -n 19 awk "NR % $step == 0" "$file" >> subs_raw.txt
        else
            cat "$file" >> subs_raw.txt
        fi
    fi
}

for P in $PRIORITY_PROTOCOLS; do
    if [ "$P" = "shadowsocks" ]; then
        P_REGEX="^ss://"
    elif [ "$P" = "hysteria2" ]; then
        P_REGEX="^(hysteria2|hy2)://"
    elif [ "$P" = "hysteria" ]; then
        P_REGEX="^hysteria://"
    elif [ "$P" = "tuic" ]; then
        P_REGEX="^tuic://"
    elif [ "$P" = "mieru" ]; then
        P_REGEX="^mieru://"
    elif [ "$P" = "masque" ]; then
        P_REGEX="^masque://"
    else
        P_REGEX="^${P}://"
    fi
    
    nice -n 19 grep -iE "$P_REGEX" "$TEMP/all_subs.txt" > "$TEMP/p_all.txt" 2>/dev/null
    
    P_COUNT=0
    [ -f "$TEMP/p_all.txt" ] && P_COUNT=$(wc -l < "$TEMP/p_all.txt" | tr -d ' ')
    
    UP_P=$(echo "$P" | tr '[:lower:]' '[:upper:]')
    echo -e "    ${PURPLE}➔ Extracted ${UP_P}: ${P_COUNT} raw nodes${RESET}"
    
    nice -n 19 grep -iE "#.*($COUNTRY_REGEX)" "$TEMP/p_all.txt" > "$TEMP/p_vip.txt" 2>/dev/null
    nice -n 19 grep -ivE "#.*($COUNTRY_REGEX)" "$TEMP/p_all.txt" > "$TEMP/p_reg.txt" 2>/dev/null
    
    sample_nodes "$TEMP/p_vip.txt" 800
    sample_nodes "$TEMP/p_reg.txt" 200
done

FINAL_SAMPLE=$(wc -l < subs_raw.txt | tr -d ' ' | grep -o '[0-9]*')
echo -e "  ${GREEN}➔ Successfully extracted highly-concentrated sample of $FINAL_SAMPLE prioritized nodes.${RESET}"

nice -n 19 lua converter.lua >/dev/null 2>&1
if [ ! -f "all_nodes.json" ] || [ ! -s "all_nodes.json" ]; then
    echo -e "${RED}ERROR: converter.lua crashed or failed to compile all_nodes.json! Aborting pipeline.${RESET}"
    start_main && rm -rf "$TEMP" && exit 1
fi
mv all_nodes.json "$TEMP/raw.json"

# =====================================================================
# [RU] 4. ГЛОБАЛЬНАЯ МАТРИЦА СОРТИРОВКИ (STREAM APPENDING)
# =====================================================================
echo -e "${CYAN}Building Priority Matrix (EncMode: $ENCRYPTION_PRIORITY, SortMode: $SORT_PRIORITY)...${RESET}"
> "$TEMP/all_stream.json"
nice -n 19 jq "map(select(.type == \"shadowsocks\"))" "$TEMP/raw.json" > "$TEMP/raw_ss.json"
nice -n 19 jq "map(select(.type != \"shadowsocks\"))" "$TEMP/raw.json" > "$TEMP/raw_others.json"

FB_COND=""
for C in $FILTER_COUNTRIES; do
    [ -n "$FB_COND" ] && FB_COND="${FB_COND} and "
    FB_COND="${FB_COND}(.tag | ascii_downcase | index(\"${C}\") == null)"
done
[ -z "$FB_COND" ] && FB_COND="true"

add_chunk() {
    if [ -s "$TEMP/chunk.json" ]; then
        nice -n 19 jq -c '.[]' "$TEMP/chunk.json" >> "$TEMP/all_stream.json" 2>/dev/null
    fi
}

add_ss_secure() {
    nice -n 19 jq --arg c "$1" -f "$TEMP/ss_sec1.jq" "$TEMP/raw_ss.json" > "$TEMP/chunk.json"
    add_chunk
    nice -n 19 jq --arg c "$1" -f "$TEMP/ss_sec2.jq" "$TEMP/raw_ss.json" > "$TEMP/chunk.json"
    add_chunk
}

add_ss_open() {
    nice -n 19 jq --arg c "$1" -f "$TEMP/ss_open.jq" "$TEMP/raw_ss.json" > "$TEMP/chunk.json"
    add_chunk
}

add_secure_others() {
    local c=$1
    local p=$2
    if [ "$p" = "vless" ]; then
        if [ "$ENCRYPTION_PRIORITY" = "1" ]; then
            nice -n 19 jq --arg c "$c" --arg p "vless" -f "$TEMP/type_sec.jq" "$TEMP/raw_others.json" > "$TEMP/chunk.json"
        else
            nice -n 19 jq --arg c "$c" -f "$TEMP/vless_sec.jq" "$TEMP/raw_others.json" > "$TEMP/chunk.json"
        fi
    else
        nice -n 19 jq --arg c "$c" --arg p "$p" -f "$TEMP/type_sec.jq" "$TEMP/raw_others.json" > "$TEMP/chunk.json"
    fi
    add_chunk
}

add_naked_others() {
    nice -n 19 jq --arg c "$1" -f "$TEMP/vless_naked.jq" "$TEMP/raw_others.json" > "$TEMP/chunk.json"
    add_chunk
}

add_fallback() {
    local p=$1
    if [ "$p" = "shadowsocks" ]; then
        cat << EOF > "$TEMP/fb.jq"
map(select(($FB_COND) and .method != "none"))
EOF
        if [ "$ENCRYPTION_PRIORITY" = "2" ]; then
            nice -n 19 jq -f "$TEMP/fb.jq" "$TEMP/raw_ss.json" > "$TEMP/chunk.json"
        else
            cat << EOF > "$TEMP/fb.jq"
map(select($FB_COND))
EOF
            nice -n 19 jq -f "$TEMP/fb.jq" "$TEMP/raw_ss.json" > "$TEMP/chunk.json"
        fi
    else
        if [ "$p" = "vless" ] && [ "$ENCRYPTION_PRIORITY" = "2" ]; then
            cat << EOF > "$TEMP/fb.jq"
map(select(($FB_COND) and .type == "$p" and .tls.enabled == true))
EOF
        else
            cat << EOF > "$TEMP/fb.jq"
map(select(($FB_COND) and .type == "$p"))
EOF
        fi
        nice -n 19 jq -f "$TEMP/fb.jq" "$TEMP/raw_others.json" > "$TEMP/chunk.json"
    fi
    add_chunk
}

add_naked_fallback() {
    local p=$1
    if [ "$p" = "shadowsocks" ]; then
        cat << EOF > "$TEMP/fb.jq"
map(select(($FB_COND) and .method == "none"))
EOF
        nice -n 19 jq -f "$TEMP/fb.jq" "$TEMP/raw_ss.json" > "$TEMP/chunk.json"
    elif [ "$p" = "vless" ]; then
        cat << EOF > "$TEMP/fb.jq"
map(select(($FB_COND) and .type == "vless" and (.tls.enabled == null or .tls.enabled == false)))
EOF
        nice -n 19 jq -f "$TEMP/fb.jq" "$TEMP/raw_others.json" > "$TEMP/chunk.json"
    fi
    add_chunk
}

if [ "$SORT_PRIORITY" = "0" ]; then
    echo -e "  ${BLUE}➔ Logic: PROTOCOL -> COUNTRY${RESET}"
    for P in $PRIORITY_PROTOCOLS; do
        UP_P=$(echo "$P" | tr '[:lower:]' '[:upper:]')
        echo -e "    ${CYAN}Mapping Protocol: ${UP_P}${RESET}"
        if [ "$P" = "shadowsocks" ]; then
            for C in $FILTER_COUNTRIES; do add_ss_secure "$C"; done
            if [ "$ENCRYPTION_PRIORITY" = "1" ]; then
                for C in $FILTER_COUNTRIES; do add_ss_open "$C"; done
            fi
        else
            for C in $FILTER_COUNTRIES; do add_secure_others "$C" "$P"; done
        fi
        add_fallback "$P"
    done
    
    if [ "$ENCRYPTION_PRIORITY" = "3" ]; then
        echo -e "  ${BLUE}➔ Processing Naked/Insecure Fallbacks...${RESET}"
        for P in $PRIORITY_PROTOCOLS; do
            if [ "$P" = "shadowsocks" ]; then
                for C in $FILTER_COUNTRIES; do add_ss_open "$C"; done
                add_naked_fallback "$P"
            elif [ "$P" = "vless" ]; then
                for C in $FILTER_COUNTRIES; do add_naked_others "$C"; done
                add_naked_fallback "$P"
            fi
        done
    fi
else
    echo -e "  ${BLUE}➔ Logic: COUNTRY -> PROTOCOL${RESET}"
    for C in $FILTER_COUNTRIES; do
        UP_C=$(echo "$C" | tr '[:lower:]' '[:upper:]')
        echo -e "    ${CYAN}Processing Location: ${UP_C}${RESET}"
        for P in $PRIORITY_PROTOCOLS; do
            if [ "$P" = "shadowsocks" ]; then
                add_ss_secure "$C"
                if [ "$ENCRYPTION_PRIORITY" = "1" ]; then add_ss_open "$C"; fi
            else
                add_secure_others "$C" "$P"
            fi
        done
        if [ "$ENCRYPTION_PRIORITY" = "3" ]; then
            add_naked_others "$C"
            add_ss_open "$C"
        fi
    done
    
    echo -e "  ${BLUE}➔ Processing Fallback Groups (Other countries)...${RESET}"
    for P in $PRIORITY_PROTOCOLS; do
        add_fallback "$P"
    done
    if [ "$ENCRYPTION_PRIORITY" = "3" ]; then
        add_naked_fallback "shadowsocks"
        add_naked_fallback "vless"
    fi
fi

if [ -s "$TEMP/all_stream.json" ]; then
    awk '!seen[$0]++' "$TEMP/all_stream.json" | nice -n 19 jq -s '.' > "$TEMP/all.json"
else
    echo "[]" > "$TEMP/all.json"
fi

TOTAL=$(safe_count "$TEMP/all.json")
echo -e "${PURPLE}Scanning total queue of $TOTAL prioritized nodes...${RESET}"

# =====================================================================
# [RU] 5. ЦИКЛ СКАНИРОВАНИЯ (БАТЧИ ПО 3 ПРОКСИ)
# =====================================================================
CUR=0
if [ "$SORT_PRIORITY" = "0" ]; then
    STRATEGY="Protocol -> Country"
else
    STRATEGY="Country -> Protocol"
fi

while [ $CUR -lt $TOTAL ]; do
    END=$((CUR + 3))
    [ $END -gt $TOTAL ] && END=$TOTAL
    
    CUR_PROTO=$(nice -n 19 jq -r ".[$CUR].type" "$TEMP/all.json" 2>/dev/null)
    CUR_TAG=$(nice -n 19 jq -r ".[$CUR].tag" "$TEMP/all.json" 2>/dev/null)
    CUR_COUNTRY=$(echo "$CUR_TAG" | grep -oE "[A-Z]{2}" | head -n 1)
    [ -z "$CUR_COUNTRY" ] && CUR_COUNTRY="Global"
    
    CUR_PROTO_UP=$(echo "$CUR_PROTO" | tr '[:lower:]' '[:upper:]')
    CUR_COUNTRY_UP=$(echo "$CUR_COUNTRY" | tr '[:lower:]' '[:upper:]')

    echo -e "${CYAN}--------------------------------------------------${RESET}"
    echo -e "${YELLOW}Batch $CUR-$END | Strategy: $STRATEGY${RESET}"
    echo -e "${PURPLE}➔ Testing: ${CUR_PROTO_UP} | Region: ${CUR_COUNTRY_UP}${RESET}"
    echo -e "${CYAN}--------------------------------------------------${RESET}"

    kill_testers && sleep 1
    nice -n 19 jq ".[$CUR:$END]" "$TEMP/all.json" | nice -n 19 jq -f "$TEMP/gen.jq" > "$TEMP/run.json"
    
    "$BIN" run -c "$TEMP/run.json" >/dev/null 2>&1 &
    TEST_PID=$!
    sleep 14

    cat "$TEMP/debug_header"
    curl -s http://127.0.0.1:$TEST_API_PORT/proxies | nice -n 19 jq -r -f "$TEMP/debug.jq"

    VALID_NODES=$(curl -s http://127.0.0.1:$TEST_API_PORT/proxies | nice -n 19 jq -r -f "$TEMP/api_all_valid.jq")
    
    for NODE in $VALID_NODES; do
        if [ -n "$NODE" ] && [ "$NODE" != "null" ]; then
            curl -s -X PUT -H "Content-Type: application/json" -d "{\"name\":\"$NODE\"}" "http://127.0.0.1:$TEST_API_PORT/proxies/tester_group" >/dev/null 2>&1
            sleep 3
            
            SPD=$(curl -x socks5://127.0.0.1:$TEST_PORT -sL -o /dev/null -w "%{speed_download}" --connect-timeout 6 --max-time 25 "$ACTIVE_TEST_URL" 2>/dev/null)
            KBPS=$(echo "$SPD" | awk '{print int($1 / 1024)}')
            
            if [ "$KBPS" -ge "$PERFECT_SPEED_KBPS" ]; then
                echo -e "  ${GREEN}[FOUND] $NODE : $KBPS KB/s${RESET}"
                echo "$KBPS|$NODE" >> "$TEMP/results.txt"
                
                FOUND=$(wc -l < "$TEMP/results.txt" | tr -d ' ')
                echo -e "  Total Stored: ${GREEN}$FOUND / $WANTED${RESET}"
                if [ "$FOUND" -ge "$WANTED" ]; then
                    echo -e "${GREEN}>>> Target reached! Stopping scan.${RESET}"
                    kill_testers
                    break 2
                fi
            else
                echo -e "  ${YELLOW}[LOW] $NODE : $KBPS KB/s (passed ping check)${RESET}"
            fi
        fi
    done
    CUR=$END
done

kill_testers

# =====================================================================
# [RU] 6. СБОРКА И ГОРЯЧЕЕ ПЕРЕКЛЮЧЕНИЕ
# =====================================================================
if [ -s "$TEMP/results.txt" ]; then
    echo -e "${CYAN}Generating final configuration...${RESET}"
    
    sort -rn "$TEMP/results.txt" | awk -F"|" '!seen[$2]++' | head -n $WANTED | cut -d"|" -f2 > "$TEMP/top_tags.txt"
    nice -n 19 jq -R . "$TEMP/top_tags.txt" | nice -n 19 jq -s . > "$TEMP/tags.json"
    
    nice -n 19 jq --slurpfile tags "$TEMP/tags.json" -f "$TEMP/unique.jq" "$TEMP/all.json" > "$TEMP/final.json"
    nice -n 19 jq "map(.tag)" "$TEMP/final.json" > "$TEMP/ftags.json"
    
    nice -n 19 jq -n --slurpfile tags "$TEMP/ftags.json" -f "$TEMP/sel.jq" > "$TEMP/sel.json"
    nice -n 19 jq --slurpfile nodes "$TEMP/final.json" --slurpfile sel "$TEMP/sel.json" -f "$TEMP/fin.jq" "$CONF_BASE" > "$CONF_TARGET"

    echo -e "${CYAN}Hot-restarting main target service...${RESET}"
    stop_main && sleep 1 && start_main
    echo -e "${GREEN}DONE! New config applied. Main service restarted seamlessly.${RESET}"
else
    echo -e "${RED}ERROR: No suitable nodes found during this iteration.${RESET}"
fi

rm -rf "$TEMP" 2>/dev/null
rm -f "$WORKDIR/subs_raw.txt" "$WORKDIR/all_nodes.json" 2>/dev/null