#!/bin/sh

# === НАСТРОЙКИ ===
WANTED=10
PERFECT_SPEED_KBPS=800
MIN_FAST_CHECK_SPEED_KBPS=500  # Нижнее окно скорости для быстрой проверки
TEST_PORT=25555
TEST_API_PORT=9092
TEST_URLS="https://speed.cloudflare.com/__down?bytes=10485760 https://cachefly.cachefly.net/10mb.test"
WORKDIR="/opt/tmp_sb_ext/sing-box-1.12.12-extended-1.5.1-linux-mipsle"
TEMP="/opt/tmp/sb_upd3"
BIN="$WORKDIR/sing-box"
CONF_BASE="$WORKDIR/conf3_final.json"
CONF_TARGET="$WORKDIR/conf2_final.json"
MAIN_PIDFILE="/var/run/sb_update_main.pid"

# =====================================================================
# РЕЖИМ ПРИОРИТЕТА ШИФРОВАНИЯ
# 1 - Стандартный (Все протоколы)
# 2 - Параноидальный (Полное удаление "голых" VLESS без TLS и SS с методом none)
# 3 - Гибридный (Все "голые" протоколы сдвигаются в самый низ очереди)
ENCRYPTION_PRIORITY=2

# РЕЖИМ ПРИОРИТЕТА СОРТИРОВКИ
# 0 - ПРОТОКОЛ -> СТРАНА (Сначала выжать Shadowsocks из ВСЕХ стран, затем VLESS и т.д.)
# 1 - СТРАНА -> ПРОТОКОЛ (Сначала выжать ВСЕ протоколы из NL, затем переходить к DE и т.д.)
SORT_PRIORITY=0
# =====================================================================

MAX_ACCEPTABLE_PING=3000
FILTER_COUNTRIES="nl de us pl fi"
PRIORITY_PROTOCOLS="shadowsocks hysteria2 vless hysteria trojan vmess"

# Подписки
SUBS_LIST="
https://raw.githubusercontent.com/sakha1370/OpenRay/refs/heads/main/output/all_valid_proxies.txt
https://raw.githubusercontent.com/ebrasha/free-v2ray-public-list/refs/heads/main/all_extracted_configs.txt
https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/refs/heads/main/Config/vless.txt
https://raw.githubusercontent.com/acymz/AutoVPN/refs/heads/main/data/V2.txt
https://raw.githubusercontent.com/roosterkid/openproxylist/refs/heads/main/V2RAY.txt
https://raw.githubusercontent.com/amirkma/proxykma/refs/heads/main/mix.txt
https://raw.githubusercontent.com/mahdibland/V2RayAggregator/refs/heads/master/sub/sub_merge.txt
https://raw.githubusercontent.com/gongchandang49/TelegramV2rayCollector/refs/heads/main/sub/mix
https://raw.githubusercontent.com/SoliSpirit/v2ray-configs/refs/heads/main/Protocols/ss.txt
https://raw.githubusercontent.com/LonUp/NodeList/main/node.txt
"

# === ЦВЕТА ===
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
BLUE='\033[1;34m'
PURPLE='\033[1;35m'
RESET='\033[0m'

CDIR=$(pwd)
if [ "$CDIR" != "$WORKDIR" ]; then
    if [ -f "$CDIR/converter.lua" ]; then cp "$CDIR/converter.lua" "$WORKDIR/"; fi
    if [ -f "$CDIR/utils.lua" ]; then cp "$CDIR/utils.lua" "$WORKDIR/"; fi
fi

kill_testers() {
    for p in $(ps | grep "[s]ing-box" | grep "run.json" | awk '{print $1}'); do
        kill -9 $p 2>/dev/null
    done
    for p in $(netstat -tuln 2>/dev/null | grep -E ":$TEST_PORT |:$TEST_API_PORT " | awk '{print $7}' | cut -d/ -f1); do
        if echo "$p" | grep -q '^[0-9][0-9]*$'; then kill -9 $p 2>/dev/null; fi
    done
}

stop_main() {
    if [ -f "$MAIN_PIDFILE" ]; then
        MPID=$(cat "$MAIN_PIDFILE")
        [ -n "$MPID" ] && kill -9 $MPID 2>/dev/null
        rm -f "$MAIN_PIDFILE"
    fi
    for p in $(ps | grep "[s]ing-box" | grep "conf2_final.json" | awk '{print $1}'); do
        kill -9 $p 2>/dev/null
    done
}

start_main() {
    if [ -f "$MAIN_PIDFILE" ] && kill -0 $(cat "$MAIN_PIDFILE") 2>/dev/null; then return; fi
    "$BIN" run -c "$CONF_TARGET" >/dev/null 2>&1 &
    echo $! > "$MAIN_PIDFILE"
}

check_provider() {
    ACTIVE_TEST_URL=""
    for U in $TEST_URLS; do
        if curl -Is --connect-timeout 3 "$U" 2>/dev/null | grep -q "200 OK"; then ACTIVE_TEST_URL="$U"; return 0; fi
    done
    return 1
}

safe_count() {
    [ -f "$1" ] && [ -s "$1" ] && jq 'length' "$1" 2>/dev/null || echo 0
}

write_jq_filters() {
    echo '. as $n | { "log": { "level": "error" }, "experimental": { "clash_api": { "external_controller": "127.0.0.1:'$TEST_API_PORT'" } }, "route": { "final": "tester_group" }, "inbounds": [ { "type": "socks", "tag": "socks-test", "listen": "127.0.0.1", "listen_port": '$TEST_PORT' } ], "outbounds": ($n + [{ "type": "urltest", "tag": "tester_group", "outbounds": ($n | map(.tag)), "url": "http://cp.cloudflare.com/generate_204", "interval": "1m", "tolerance": 50 }]) }' > "$TEMP/gen.jq"
    echo '{ "type": "urltest", "tag": "Best-Auto", "outbounds": $tags[0], "url": "http://cp.cloudflare.com/generate_204", "interval": "3m", "tolerance": 50 }' > "$TEMP/sel.jq"
    echo '.log.level = "warn" | .outbounds += $nodes[0] | .outbounds += $sel | .route.final = "Best-Auto"' > "$TEMP/fin.jq"
    echo '.proxies | to_entries[] | select(.value.type != "URLTest" and .value.type != "Selector" and .key != "GLOBAL" and .key != "direct" and .key != "block" and .key != "socks-test") | "    - \(.key): \((if .value.history and (.value.history|length>0) then .value.history[-1].delay else 0 end)) ms"' > "$TEMP/debug.jq"
    echo '.proxies | to_entries | map(select(.value.history | length > 0) | select(.value.history[-1].delay > 0 and .value.history[-1].delay <= ' $MAX_ACCEPTABLE_PING ') | select(.key != "socks-test" and .key != "tester_group")) | map(.key) | .[]' > "$TEMP/api_all_valid.jq"
    echo -e "  ${PURPLE}[DEBUG] Status Tracker Active:${RESET}" > "$TEMP/debug_header"
}

prepare_temp() {
    kill_testers && sleep 1
    rm -rf "$TEMP" && mkdir -p "$TEMP"
    touch "$TEMP/results.txt"
    write_jq_filters
}

# === 1. УМНАЯ БЫСТРАЯ ПРОВЕРКА ===
if [ -f "$CONF_TARGET" ]; then
    echo -e "${CYAN}Checking existing nodes (Strict Mode)...${RESET}"
    if check_provider; then
        prepare_temp
        jq '[.outbounds[] | select(.type != "urltest" and .type != "selector" and .type != "direct" and .type != "dns" and .type != "block")]' "$CONF_TARGET" > "$TEMP/fast.json"
        TOTAL_FAST=$(safe_count "$TEMP/fast.json")
        
        if [ "$TOTAL_FAST" -gt 0 ]; then
            jq -f "$TEMP/gen.jq" "$TEMP/fast.json" > "$TEMP/run.json"
            "$BIN" run -c "$TEMP/run.json" >/dev/null 2>&1 &
            sleep 12
            
            VALID_FAST_NODES=$(curl -s http://127.0.0.1:$TEST_API_PORT/proxies | jq -r -f "$TEMP/api_all_valid.jq")
            STABLE_COUNT=0
            STABLE_THRESHOLD=$((WANTED * 70 / 100))
            echo -e "  ${PURPLE}Retention Threshold set to: $STABLE_THRESHOLD nodes (70% of WANTED)${RESET}"
            
            for NODE in $VALID_FAST_NODES; do
                if [ -n "$NODE" ] && [ "$NODE" != "null" ]; then
                    curl -s -X PUT -H "Content-Type: application/json" -d "{\"name\":\"$NODE\"}" "http://127.0.0.1:$TEST_API_PORT/proxies/tester_group" >/dev/null 2>&1
                    sleep 3
                    SPD=$(curl -x socks5://127.0.0.1:$TEST_PORT -s -o /dev/null -w "%{speed_download}" --connect-timeout 6 --max-time 20 "$ACTIVE_TEST_URL" 2>/dev/null)
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
                start_main && rm -rf "$TEMP" && exit 0
            fi
            echo -e "  ${RED}Only $STABLE_COUNT/$STABLE_THRESHOLD acceptable nodes left. Forcing full update...${RESET}"
        fi
    fi
fi

# === 2. СКАЧИВАНИЕ И АВТО-ДЕКОДИРОВАНИЕ БАЗЫ ===
echo -e "${CYAN}Starting Full Update & Base64 Decoding...${RESET}"
prepare_temp && check_provider || exit 1
> "$TEMP/all_subs.txt"

for URL in $SUBS_LIST; do
    FNAME=$(basename "$URL")
    if wget --no-check-certificate -q -O "$TEMP/part.tmp" "$URL"; then
        tr -d '\000\r' < "$TEMP/part.tmp" > "$TEMP/part.txt"
        if ! grep -qE "^(ss|vmess|vless|trojan|hysteria2)://" "$TEMP/part.txt" 2>/dev/null; then
            base64 -d "$TEMP/part.txt" > "$TEMP/part_dec.txt" 2>/dev/null
            if grep -qE "^(ss|vmess|vless|trojan|hysteria2)://" "$TEMP/part_dec.txt" 2>/dev/null; then
                mv "$TEMP/part_dec.txt" "$TEMP/part.txt"
            fi
        fi

        grep -E "^(ss|vmess|vless|trojan|hysteria2)://" "$TEMP/part.txt" >> "$TEMP/all_subs.txt" 2>/dev/null
        ADDED=$(grep -Ec "^(ss|vmess|vless|trojan|hysteria2)://" "$TEMP/part.txt" 2>/dev/null)
        if [ -n "$ADDED" ] && [ "$ADDED" -gt 0 ]; then
            echo -e "  [${GREEN}OK${RESET}] Source: $FNAME ($ADDED valid links)"
        else
            echo -e "  [${YELLOW}WARN${RESET}] Source $FNAME returned corrupt/non-proxy text (Skipped)"
        fi
    else
        echo -e "  [${RED}FAIL${RESET}] Source: $FNAME (HTTP Error)"
    fi
    rm -f "$TEMP/part.tmp" "$TEMP/part.txt" "$TEMP/part_dec.txt"
done

if [ ! -s "$TEMP/all_subs.txt" ]; then
    echo -e "${RED}ERROR: All subscription links returned empty or corrupt data!${RESET}"
    start_main && rm -rf "$TEMP" && exit 1
fi

# === 3. УМНАЯ ПРЕ-ФИЛЬТРАЦИЯ И ЗАЩИТА ОЗУ ===
cd "$WORKDIR"
echo -e "${CYAN}Applying Smart Pre-Sampling to prioritize Shadowsocks and protect RAM...${RESET}"

grep -iE "^ss://" "$TEMP/all_subs.txt" > "$TEMP/ss_only.txt"
grep -ivE "^ss://" "$TEMP/all_subs.txt" > "$TEMP/others.txt"

SS_COUNT=$(wc -l < "$TEMP/ss_only.txt" | tr -d ' ' | grep -o '[0-9]*')
OTHER_COUNT=$(wc -l < "$TEMP/others.txt" | tr -d ' ' | grep -o '[0-9]*')
echo -e "  ${BLUE}Found $SS_COUNT Shadowsocks and $OTHER_COUNT other protocols globally.${RESET}"

> subs_raw.txt

if [ -n "$SS_COUNT" ] && [ "$SS_COUNT" -gt 1500 ]; then
    STEP=$((SS_COUNT / 3500 + 1))
    awk "NR % $STEP == 0" "$TEMP/ss_only.txt" >> subs_raw.txt
else
    cat "$TEMP/ss_only.txt" >> subs_raw.txt
fi

if [ -n "$OTHER_COUNT" ] && [ "$OTHER_COUNT" -gt 1000 ]; then
    STEP=$((OTHER_COUNT / 1000 + 1))
    awk "NR % $STEP == 0" "$TEMP/others.txt" >> subs_raw.txt
else
    cat "$TEMP/others.txt" >> subs_raw.txt
fi

FINAL_SAMPLE=$(wc -l < subs_raw.txt | tr -d ' ' | grep -o '[0-9]*')
echo -e "  ${GREEN}➔ Successfully built highly-concentrated sample of $FINAL_SAMPLE nodes for parsing.${RESET}"

lua converter.lua >/dev/null 2>&1
if [ ! -f "all_nodes.json" ] || [ ! -s "all_nodes.json" ]; then
    echo -e "${RED}ERROR: converter.lua crashed or failed to compile all_nodes.json! Aborting pipeline.${RESET}"
    start_main && rm -rf "$TEMP" && exit 1
fi
mv all_nodes.json "$TEMP/raw.json"

# === 4. ГЛОБАЛЬНАЯ МАТРИЦА СОРТИРОВКИ (С УЧЕТОМ ОБЕИХ НАСТРОЕК) ===
echo -e "${CYAN}Building Priority Matrix (EncMode: $ENCRYPTION_PRIORITY, SortMode: $SORT_PRIORITY)...${RESET}"
echo "[]" > "$TEMP/all.json"
jq 'map(select(.type == "shadowsocks"))' "$TEMP/raw.json" > "$TEMP/raw_ss.json"
jq 'map(select(.type != "shadowsocks"))' "$TEMP/raw.json" > "$TEMP/raw_others.json"

# --- Модульные функции для построения очереди ---
add_chunk() {
    if [ $(safe_count "$TEMP/chunk.json") -gt 0 ]; then
        jq -s '.[0]+.[1]' "$TEMP/all.json" "$TEMP/chunk.json" > "$TEMP/t" && mv "$TEMP/t" "$TEMP/all.json"
    fi
}

add_ss_secure() {
    local c=$1
    jq --arg c "$c" 'map(select((.tag | ascii_downcase | index($c) != null) and .method != "none" and (.plugin == null or .plugin == "")))' "$TEMP/raw_ss.json" > "$TEMP/chunk.json"
    add_chunk
    jq --arg c "$c" 'map(select((.tag | ascii_downcase | index($c) != null) and .method != "none" and .plugin != null and .plugin != ""))' "$TEMP/raw_ss.json" > "$TEMP/chunk.json"
    add_chunk
}

add_ss_open() {
    local c=$1
    jq --arg c "$c" 'map(select((.tag | ascii_downcase | index($c) != null) and .method == "none"))' "$TEMP/raw_ss.json" > "$TEMP/chunk.json"
    add_chunk
}

add_secure_others() {
    local c=$1
    for P in $PRIORITY_PROTOCOLS; do
        if [ "$P" = "vless" ]; then
            if [ "$ENCRYPTION_PRIORITY" = "1" ]; then
                jq --arg c "$c" 'map(select((.tag | ascii_downcase | index($c) != null) and .type == "vless"))' "$TEMP/raw_others.json" > "$TEMP/chunk.json"
            else
                jq --arg c "$c" 'map(select((.tag | ascii_downcase | index($c) != null) and .type == "vless" and .tls.enabled == true))' "$TEMP/raw_others.json" > "$TEMP/chunk.json"
            fi
        else
            jq --arg c "$c" --arg p "$P" 'map(select((.tag | ascii_downcase | index($c) != null) and .type == $p))' "$TEMP/raw_others.json" > "$TEMP/chunk.json"
        fi
        add_chunk
    done
}

add_naked_others() {
    local c=$1
    jq --arg c "$c" 'map(select((.tag | ascii_downcase | index($c) != null) and .type == "vless" and (.tls.enabled == null or .tls.enabled == false)))' "$TEMP/raw_others.json" > "$TEMP/chunk.json"
    add_chunk
}

# --- Сборка матрицы в зависимости от выбранной логики ---
if [ "$SORT_PRIORITY" = "0" ]; then
    echo -e "  ${BLUE}➔ Logic: PROTOCOL -> COUNTRY${RESET}"
    
    for C in $FILTER_COUNTRIES; do add_ss_secure "$C"; done
    
    if [ "$ENCRYPTION_PRIORITY" = "1" ]; then
        for C in $FILTER_COUNTRIES; do add_ss_open "$C"; done
    fi
    
    for C in $FILTER_COUNTRIES; do add_secure_others "$C"; done
    
    if [ "$ENCRYPTION_PRIORITY" = "3" ]; then
        for C in $FILTER_COUNTRIES; do add_naked_others "$C"; done
        for C in $FILTER_COUNTRIES; do add_ss_open "$C"; done
    fi
else
    echo -e "  ${BLUE}➔ Logic: COUNTRY -> PROTOCOL${RESET}"
    
    for C in $FILTER_COUNTRIES; do
        echo -e "    ${CYAN}Processing Location: ${C^^}${RESET}"
        add_ss_secure "$C"
        
        if [ "$ENCRYPTION_PRIORITY" = "1" ]; then
            add_ss_open "$C"
        fi
        
        add_secure_others "$C"
        
        if [ "$ENCRYPTION_PRIORITY" = "3" ]; then
            add_naked_others "$C"
            add_ss_open "$C"
        fi
    done
fi

echo -e "  ${BLUE}➔ Processing Fallback Groups (Other countries)...${RESET}"
if [ "$ENCRYPTION_PRIORITY" = "2" ]; then
    jq 'map(select((.tag | ascii_downcase | index("nl") == null) and (.tag | ascii_downcase | index("de") == null) and (.tag | ascii_downcase | index("us") == null) and (.tag | ascii_downcase | index("pl") == null) and (.tag | ascii_downcase | index("fi") == null) and .method != "none" and (.type != "vless" or .tls.enabled == true)))' "$TEMP/raw.json" > "$TEMP/chunk_fb.json"
else
    jq 'map(select((.tag | ascii_downcase | index("nl") == null) and (.tag | ascii_downcase | index("de") == null) and (.tag | ascii_downcase | index("us") == null) and (.tag | ascii_downcase | index("pl") == null) and (.tag | ascii_downcase | index("fi") == null)))' "$TEMP/raw.json" > "$TEMP/chunk_fb.json"
fi
add_chunk

TOTAL=$(safe_count "$TEMP/all.json")
echo -e "${PURPLE}Scanning total queue of $TOTAL prioritized nodes...${RESET}"

# === 5. ЦИКЛ СКАНИРОВАНИЯ (БАТЧИ ПО 3 ПРОКСИ) ===
CUR=0
while [ $CUR -lt $TOTAL ]; do
    END=$((CUR + 3))
    [ $END -gt $TOTAL ] && END=$TOTAL
    echo -e "${YELLOW}Batch $CUR-$END...${RESET}"

    kill_testers && sleep 1
    jq ".[$CUR:$END]" "$TEMP/all.json" | jq -f "$TEMP/gen.jq" > "$TEMP/run.json"
    
    "$BIN" run -c "$TEMP/run.json" >/dev/null 2>&1 &
    sleep 14

    cat "$TEMP/debug_header"
    curl -s http://127.0.0.1:$TEST_API_PORT/proxies | jq -r -f "$TEMP/debug.jq"

    VALID_NODES=$(curl -s http://127.0.0.1:$TEST_API_PORT/proxies | jq -r -f "$TEMP/api_all_valid.jq")
    
    for NODE in $VALID_NODES; do
        if [ -n "$NODE" ] && [ "$NODE" != "null" ]; then
            curl -s -X PUT -H "Content-Type: application/json" -d "{\"name\":\"$NODE\"}" "http://127.0.0.1:$TEST_API_PORT/proxies/tester_group" >/dev/null 2>&1
            sleep 3
            
            SPD=$(curl -x socks5://127.0.0.1:$TEST_PORT -s -o /dev/null -w "%{speed_download}" --connect-timeout 6 --max-time 25 "$ACTIVE_TEST_URL" 2>/dev/null)
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

# === 6. СБОРКА И ГОРЯЧЕЕ ПЕРЕКЛЮЧЕНИЕ ===
if [ -s "$TEMP/results.txt" ]; then
    echo -e "${CYAN}Generating final configuration...${RESET}"
    sort -rn "$TEMP/results.txt" | head -n $WANTED | cut -d'|' -f2 > "$TEMP/top_tags.txt"
    jq -R . "$TEMP/top_tags.txt" | jq -s . > "$TEMP/tags.json"
    jq --slurpfile tags "$TEMP/tags.json" 'map(. as $n|select($tags[0]|index($n.tag)))' "$TEMP/all.json" > "$TEMP/final.json"
    jq 'map(.tag)' "$TEMP/final.json" > "$TEMP/ftags.json"
    jq -n --slurpfile tags "$TEMP/ftags.json" -f "$TEMP/sel.jq" > "$TEMP/sel.json"
    jq --slurpfile nodes "$TEMP/final.json" --slurpfile sel "$TEMP/sel.json" -f "$TEMP/fin.jq" "$CONF_BASE" > "$CONF_TARGET"

    echo -e "${CYAN}Hot-restarting main target service...${RESET}"
    stop_main && sleep 1 && start_main
    echo -e "${GREEN}DONE! New config applied. Main service restarted seamlessly.${RESET}"
else
    echo -e "${RED}ERROR: No suitable nodes found during this iteration.${RESET}"
fi
rm -rf "$TEMP"