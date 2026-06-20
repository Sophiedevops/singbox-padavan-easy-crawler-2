# 🌐 Sing-Box · Padavan · Smart Crawler v2

[![Shell](https://img.shields.io/badge/Shell-POSIX__sh-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/) [![Platform](https://img.shields.io/badge/Padavan-MIPSLE-007ACC?style=for-the-badge&logo=openwrt&logoColor=white)](https://github.com/RMerl/asuswrt-merlin) [![Core](https://img.shields.io/badge/Sing--Box-1.12.12--Extended-blueviolet?style=for-the-badge)](https://sing-box.sagernet.org/) [![Status](https://img.shields.io/badge/Status-Stable-brightgreen?style=for-the-badge)](https://github.com/Sophiedevops/singbox-padavan-easy-crawler-2/blob/main) [![License](https://img.shields.io/badge/License-MIT-orange?style=for-the-badge)](https://github.com/Sophiedevops/singbox-padavan-easy-crawler-2/blob/main)

**🇷🇺 [Русский](#-русский) · 🇬🇧 [English](#-english) · 🇮🇷 [فارسی](#-فارسی) · 🇨🇳 [中文](#-中文)**

---

## 🇷🇺 Русский

**Автоматический поиск, тест и прямое управление живым процессом Sing-Box на слабом MIPS-роутере**

**( протестировано на MiWiFi 3 | Xiaomi Mi-router 3 )**
> **Единственный скрипт**, который переварит базу из **60 000+ прокси-нод**
> на роутере с **32 МБ свободной ОЗУ** — без зависания, без OOM, без перегрева.

> **🆕 Что изменилось в этой версии `update.sh`:**
> - Скрипт теперь сам **управляет live-процессом** sing-box через PID-файл (запуск/остановка/горячий рестарт), а не просто генерирует конфиг
> - **Provider Auto-Pilot** — автоматический выбор рабочего CDN для спид-теста и рабочего пинг-эндпоинта вместо одного жёстко заданного
> - География выросла до **18 стран**, список протоколов — до **6** (добавлена отдельная Hysteria v1, отдельно от Hysteria2)
> - Base64-декодер подписок переписан на **чистом Lua** прямо внутри скрипта — больше не нужен `openssl`/`base64`
> - Список источников подписок обновлён: добавлен `whitedns.one`, убраны 3 неактуальных агрегатора (**8 источников** вместо 10)
> - Лимит сэмплирования при защите ОЗУ поднят до **~5500 записей** (4 взвешенные «корзины» вместо общего пула)
> - Повышены пороги: `PERFECT_SPEED_KBPS` 800→**900**, `MIN_FAST_CHECK_SPEED_KBPS` 500→**600**

### 🔄 Как устроен пайплайн (порядок работы)

[#-как-устроен-пайплайн-порядок-работы](#-как-устроен-пайплайн-порядок-работы)

1. **Smart Fast-Check.** Если `conf2_final.json` уже существует, скрипт проверяет ноды текущего пула: пинг через Clash API, затем реальный спидтест. Если стабильных нод ≥70% от `WANTED` (при `WANTED=10` это 7 нод) — весь тяжёлый пайплайн пропускается, поднимается live-процесс, скрипт завершает работу.
2. **Скачивание и авто-декодирование.** Последовательно опрашиваются 8 источников подписок. Если содержимое не похоже на ссылки `ss://`/`vless://`/`vmess://`/`trojan://`/`hysteria2://`, оно прогоняется через встроенный Lua-декодер Base64; мусорные байты (`\0`, `\r`) вычищаются автоматически.
3. **Алмазный экстрактор + защита ОЗУ.** Все ссылки делятся на 4 «корзины» — VIP-SS / VIP-остальные / обычный-SS / обычные-остальные (по совпадению страны в теге), каждая урезается через `awk`-сэмплирование (до 2500 / 2000 / 500 / 500 записей), затем единым проходом конвертируются в JSON через `converter.lua`.
4. **Глобальная матрица сортировки.** Ноды раскладываются по приоритету согласно `ENCRYPTION_PRIORITY` и `SORT_PRIORITY` (страна↔протокол), плюс отдельный fallback-блок для стран вне списка `FILTER_COUNTRIES`.
5. **Цикл сканирования батчами по 3 ноды.** Для каждой партии поднимается тестовый sing-box-инстанс; пинг проверяется через Clash API, для прошедших — реальный спидтест через локальный SOCKS5. Найденные ноды (скорость ≥ `PERFECT_SPEED_KBPS`) копятся в результат, пока не наберётся `WANTED` штук.
6. **Сборка и горячее переключение.** Из лучших нод собирается `Best-Auto` (urltest-селектор), результат мёрджится в шаблон `conf3_final.json` и записывается в `conf2_final.json`. После этого live-процесс sing-box останавливается и поднимается заново — простой составляет около 1 секунды.

### ✨ Возможности

[#-возможности](#-возможности)

| **🛡️ Anti-OOM защита** Динамический выбор `tmpfs` (если свободно >150 МБ ОЗУ) или диска (если меньше) + взвешенное сэмплирование через `awk` — не более ~5500 записей одновременно в памяти.<br>**⚡ Smart Fast-Check** Порог удержания = 70% от `WANTED`. Хватает живых нод — тяжёлый пайплайн пропускается целиком.<br>**🔒 Параноидальный режим** VLESS без TLS и SS без шифрования вырезаются на этапе сортировки; в режиме `2` фильтр действует даже на fallback-группу.<br>**🧩 Чистый Lua Base64-декодер** Подписки декодируются прямо внутри `update.sh`, без внешних бинарников `openssl`/`base64`. | **🗺️ Матрица приоритетов** 18 стран × 6 протоколов (включая раздельные Hysteria и Hysteria2). Два режима: Протокол→Страна или Страна→Протокол.<br>**🛰️ Provider Auto-Pilot** *(новое)* Сам выбирает живой CDN для спид-теста (Cloudflare / CacheFly) и живой пинг-эндпоинт (Cloudflare / Apple / Microsoft / MIUI) — переживает блокировку одного из сервисов.<br>**🔄 Live-Process Supervisor** *(новое)* `update.sh` сам запускает и перезапускает основной процесс sing-box по PID-файлу; горячая пересборка занимает ~1 секунду простоя.<br>**🧟 Anti-Zombie защита** `trap` на `INT/TERM` + `kill_testers()` гарантированно убивают тестовые процессы sing-box по `/proc/*/cmdline`, даже при ручном прерывании скрипта. |
| --- | --- |

### 📦 Состав проекта

[#-состав-проекта](#-состав-проекта)

| Файл | Назначение |
| --- | --- |
| `./update.sh` | 🔧 **Главный движок** — 6-стадийный пайплайн + встроенный supervisor живого процесса |
| `./gen_links.sh` | 🔗 **Генератор ссылок** — готовые URI для клиентов в локальной сети |
| `converter.lua` | ⚙️ **Парсер URI** — конвертирует `ss://`, `vless://` и др. в формат Sing-Box |
| `utils.lua` | 🛠️ Вспомогательные функции для конвертера |
| `conf3_final.json` | 📋 **Шаблон (база)** — никогда не меняется напрямую, используется как цель мёрджа |
| `conf2_final.json` | ⚡ **Активный конфиг** — перезаписывается скриптом на каждом запуске; именно его исполняет live-процесс |

> 💡 Если `update.sh` запущен не из `WORKDIR`, он сам скопирует туда `converter.lua` и `utils.lua` из текущей папки (если они там есть).
>
> 💡 `update.sh` сам поднимает и пересоздаёт live-процесс sing-box по PID-файлу (`/var/run/sb_update_main.pid`) — это нужно для горячей пересборки конфига без отдельного демона. Автозапуск при перезагрузке роутера по-прежнему обеспечивает ваш init-скрипт/cron.

### 🚀 Быстрый старт

[#-быстрый-старт](#-быстрый-старт)

**Вариант А — однострочный установщик:**

```
wget -O- https://raw.githubusercontent.com/Sophiedevops/singbox-padavan-easy-crawler-2/main/install.sh | sh
```

**Вариант Б — ручная установка**

```
ssh admin@192.168.1.1
cd /opt/tmp_sb_ext/sing-box-1.12.12-extended-1.5.1-linux-mipsle

RAW="https://raw.githubusercontent.com/Sophiedevops/singbox-padavan-easy-crawler-2/main"
wget -O update.sh        "$RAW/scripts/update.sh"
wget -O gen_links.sh     "$RAW/scripts/gen_links.sh"
wget -O converter.lua    "$RAW/scripts/converter.lua"
wget -O utils.lua        "$RAW/scripts/utils.lua"
wget -O conf3_final.json "$RAW/templates/conf3_final.json"

chmod +x update.sh gen_links.sh && ./update.sh
```
> `conf2_final.json` (активный конфиг) создавать вручную не нужно — он автоматически появится после первого успешного прогона пайплайна.

> **💡 Cron — автообновление каждые 3 дня в 03:00:**
>
> ```
> 0 3 */3 * * cd /opt/tmp_sb_ext/sing-box-1.12.12-extended-1.5.1-linux-mipsle && ./update.sh >> /opt/tmp/sb_update.log 2>&1
> ```

### ⚙️ Настройки

[#️-настройки](#️-настройки)

```
ENCRYPTION_PRIORITY=1           # 1=Стандартный 2=Параноидальный 3=Гибридный
SORT_PRIORITY=0                 # 0=Протокол→Страна 1=Страна→Протокол
WANTED=10                       # Сколько рабочих нод нужно в итоговом конфиге
PERFECT_SPEED_KBPS=900          # Минимальная скорость загрузки для принятия ноды
MIN_FAST_CHECK_SPEED_KBPS=600   # Порог для Smart Fast-Check
MAX_ACCEPTABLE_PING=3000        # Максимальный пинг по Clash API (мс)
FILTER_COUNTRIES="nl de us pl fi jp tw sg hk fr se uk gb ca ru tr md kr"
PRIORITY_PROTOCOLS="shadowsocks hysteria2 vless hysteria trojan vmess"
```
> Дополнительно (обычно менять не нужно): `TEST_PORT=25555` — локальный SOCKS5 для тестов, `TEST_API_PORT=9092` — порт Clash API тестового инстанса.

**🔒 Режим шифрования (ENCRYPTION_PRIORITY)**

| Значение | Режим | Описание |
| --- | --- | --- |
| `1` | **Стандартный** | Все протоколы без фильтрации, открытые SS/«голый» VLESS допускаются в общем порядке |
| `2` | **Параноидальный** ⭐ | VLESS без TLS и SS без шифрования удаляются сразу — в том числе из fallback-группы |
| `3` | **Гибридный** | «Голые» ноды не выбрасываются, а уходят в самый конец очереди приоритета |

**🗺️ Режим сортировки (SORT_PRIORITY)**

| Значение | Логика | Для кого |
| --- | --- | --- |
| `0` | **Протокол → Страна** | Слабые роутеры: SS легче шифруется, щадит CPU |
| `1` | **Страна → Протокол** | Геймеры: минимальный пинг к нужной стране |

```
Пример SORT=0, ENC=2:
① SS+AEAD из NL → DE → US → … → KR     ④ HY2/VLESS+TLS/Hysteria/Trojan/VMess из NL → DE → …     ⑦ Fallback (весь мир, тоже без открытых нод)
```

**📡 Источники подписок (8 агрегаторов, 60 000+ нод)**

| # | Источник | Протоколы |
| --- | --- | --- |
| 1 | [`sub.whitedns.one`](https://sub.whitedns.one/sub/base64.txt) (Base64-подписка) | Mix |
| 2 | [`sakha1370/OpenRay`](https://raw.githubusercontent.com/sakha1370/OpenRay/refs/heads/main/output/all_valid_proxies.txt) | Mix |
| 3 | [`SoliSpirit/v2ray-configs`](https://raw.githubusercontent.com/SoliSpirit/v2ray-configs/refs/heads/main/Protocols/ss.txt) | SS |
| 4 | [`ebrasha/free-v2ray-public-list`](https://raw.githubusercontent.com/ebrasha/free-v2ray-public-list/refs/heads/main/all_extracted_configs.txt) | Mix |
| 5 | [`V2RayRoot/V2RayConfig`](https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/refs/heads/main/Config/vless.txt) | VLESS |
| 6 | [`amirkma/proxykma`](https://raw.githubusercontent.com/amirkma/proxykma/refs/heads/main/mix.txt) | Mix |
| 7 | [`mahdibland/V2RayAggregator`](https://raw.githubusercontent.com/mahdibland/V2RayAggregator/refs/heads/master/sub/sub_merge.txt) | Mix |
| 8 | [`gongchandang49/TelegramV2rayCollector`](https://raw.githubusercontent.com/gongchandang49/TelegramV2rayCollector/refs/heads/main/sub/mix) | Mix |

> ⚠️ При добавлении своих ссылок всегда используйте **Raw**-ссылки (`raw.githubusercontent.com`), а не страницы GitHub (`github.com/…/blob/…`) — иначе скрипт скачает HTML вместо текста.

### 🔗 Клиентские ссылки

[#-клиентские-ссылки](#-клиентские-ссылки)

`gen_links.sh` автоматически определяет IP роутера и генерирует URI для всех инбаундов. Если у вас статический IP или DDNS — можно подключаться и извне локальной сети.

```
./gen_links.sh
```

**Пример вывода**

```
Detected Router LAN IP: 192.168.1.1
--- SOCKS5 ---        socks5://192.168.1.1:1080#socks5-in
--- HTTP/Mixed ---    http://192.168.1.1:2080#mixed-in
--- Shadowsocks ---   ss://Y2hhY2hhM...@192.168.1.1:8388#ss-in
--- Hysteria 2 ---    hy2://MyPassword@192.168.1.1:4443?insecure=1#hy2-in
DONE! All links saved to clients.txt
```
> **SOCKS5** — рекомендуется для большинства устройств. Полноценно маршрутизирует TCP и UDP.
> **HTTP/Mixed** — резервный вариант для старых Smart TV. Только TCP, UDP не поддерживается.

Совместимо с **v2rayNG** · **NekoBox** · **Hiddify** · **Sing-Box Mobile** · **Karing**

### 📋 Требования

[#-требования](#-требования)

| Компонент | Что нужно |
| --- | --- |
| 🔧 Прошивка | Padavan (Asus Merlin-based) |
| 💾 Хранилище | USB-накопитель с Entware в `/opt/` |
| 📦 Пакеты | `curl wget jq lua bash coreutils-sort grep` |
| ⚙️ Бинарник | `sing-box linux-mipsle-softfloat` или `hardfloat` |
| 📄 Конфиги | `conf3_final.json` (шаблон) — `conf2_final.json` создаётся автоматически |

> 💡 `openssl-util` больше **не требуется** — Base64-декодирование подписок реализовано на чистом Lua прямо внутри `update.sh`.

**🔧 FAQ — частые проблемы**

| Ошибка | Решение |
| --- | --- |
| `converter.lua crashed` | Проверьте наличие `converter.lua` и `utils.lua` рядом со скриптом — при запуске не из `WORKDIR` они копируются автоматически |
| `All subscription links returned empty` | Проверьте DNS: `nslookup raw.githubusercontent.com` |
| `Failed to connect to Speed Test CDNs` | Оба CDN (Cloudflare и CacheFly) недоступны — проверьте интернет или возможную блокировку провайдером |
| Все ноды 0 KB/s | `curl -Is https://speed.cloudflare.com/__down?bytes=1` — должен вернуть `200 OK` |
| `grep: unknown option` | `opkg install grep` |
| Скрипт завис / live-процесс не перезапускается | `killall sing-box && rm -f /var/run/sb_update_main.pid` |

**⚠️ Отказ от ответственности**

Скрипт предоставляется **«как есть»** в образовательных целях. Публичные прокси **могут логировать трафик** — не передавайте через них чувствительные данные. Используйте `ENCRYPTION_PRIORITY=2`.

---

## 🇬🇧 English

**Automated proxy search, testing and direct live-process management for Sing-Box on low-end MIPS routers**

**( tested on MiWiFi 3 | Xiaomi Mi-router 3 )**
> The **only script** capable of processing **60,000+ proxy nodes**
> on a router with just **32 MB of free RAM** — no freezes, no OOM, no overheating.

> **🆕 What changed in this version of `update.sh`:**
> - The script now **manages the live sing-box process itself** via a PID file (start/stop/hot-restart), instead of only generating a config
> - **Provider Auto-Pilot** — automatically picks a working speed-test CDN and a working ping endpoint instead of one hardcoded URL
> - Country coverage grew to **18 countries**, protocol list to **6** (a separate Hysteria v1 was added next to Hysteria2)
> - The subscription Base64 decoder was rewritten in **pure Lua** inside the script — no more `openssl`/`base64` dependency
> - Subscription sources were refreshed: added `whitedns.one`, dropped 3 stale aggregators (**8 sources** instead of 10)
> - The RAM-protection sampling cap was raised to **~5,500 records** (4 weighted buckets instead of one flat pool)
> - Thresholds were raised: `PERFECT_SPEED_KBPS` 800→**900**, `MIN_FAST_CHECK_SPEED_KBPS` 500→**600**

### 🔄 How the pipeline works (execution order)

[#-how-the-pipeline-works-execution-order](#-how-the-pipeline-works-execution-order)

1. **Smart Fast-Check.** If `conf2_final.json` already exists, the script checks the current pool: ping via the Clash API, then a real speed test. If stable nodes are ≥70% of `WANTED` (7 nodes when `WANTED=10`) — the entire heavy pipeline is skipped, the live process is (re)started, and the script exits.
2. **Download & auto-decoding.** All 8 subscription sources are fetched in turn. If the content doesn't look like `ss://`/`vless://`/`vmess://`/`trojan://`/`hysteria2://` links, it's piped through the built-in Lua Base64 decoder; stray bytes (`\0`, `\r`) are stripped automatically.
3. **Diamond Extractor + RAM protection.** Links are split into 4 buckets — VIP-SS / VIP-others / regular-SS / regular-others (by country match in the tag), each capped via `awk` sampling (up to 2500 / 2000 / 500 / 500 records), then converted to JSON in one pass via `converter.lua`.
4. **Global sorting matrix.** Nodes are arranged by priority according to `ENCRYPTION_PRIORITY` and `SORT_PRIORITY` (country↔protocol), plus a separate fallback block for countries outside `FILTER_COUNTRIES`.
5. **Scanning loop in batches of 3 nodes.** For each batch a test sing-box instance is started; ping is checked via the Clash API, and passing nodes get a real speed test over a local SOCKS5 proxy. Nodes meeting `PERFECT_SPEED_KBPS` are kept until `WANTED` is reached.
6. **Assembly & hot-swap.** The best nodes are wrapped into a `Best-Auto` urltest selector, merged into the `conf3_final.json` template and written to `conf2_final.json`. The live sing-box process is then stopped and restarted — downtime is roughly 1 second.

### ✨ Features

[#-features](#-features)

| **🛡️ Anti-OOM Protection** Dynamic choice between `tmpfs` (when >150 MB RAM is free) and disk storage (when it isn't), plus weighted `awk` sampling — never more than ~5,500 records held in memory at once.<br>**⚡ Smart Fast-Check** Retention threshold = 70% of `WANTED`. Enough live nodes — the heavy pipeline is skipped entirely.<br>**🔒 Paranoid Encryption Mode** VLESS without TLS and Shadowsocks without encryption are dropped during sorting; mode `2` also filters the fallback group.<br>**🧩 Pure-Lua Base64 Decoder** Subscriptions are decoded right inside `update.sh`, no external `openssl`/`base64` binary needed. | **🗺️ Priority Matrix** 18 countries × 6 protocols (including separate Hysteria and Hysteria2). Two modes: Protocol→Country or Country→Protocol.<br>**🛰️ Provider Auto-Pilot** *(new)* Automatically selects a live speed-test CDN (Cloudflare / CacheFly) and a live ping endpoint (Cloudflare / Apple / Microsoft / MIUI) — survives any single one being blocked.<br>**🔄 Live-Process Supervisor** *(new)* `update.sh` itself starts and restarts the main sing-box process via a PID file; the hot reload takes ~1 second of downtime.<br>**🧟 Anti-Zombie Protection** A `trap` on `INT/TERM` plus `kill_testers()` reliably kill leftover test sing-box processes by scanning `/proc/*/cmdline`, even on manual interruption. |
| --- | --- |

### 📦 Project Structure

[#-project-structure](#-project-structure)

| File | Purpose |
| --- | --- |
| `./update.sh` | 🔧 **Main engine** — 6-stage pipeline plus a built-in live-process supervisor |
| `./gen_links.sh` | 🔗 **Link generator** — ready-to-use URIs for LAN clients |
| `converter.lua` | ⚙️ **URI parser** — converts `ss://`, `vless://` etc. to Sing-Box format |
| `utils.lua` | 🛠️ Helper functions for the converter |
| `conf3_final.json` | 📋 **Template (base)** — never edited directly, used as the merge target |
| `conf2_final.json` | ⚡ **Active config** — overwritten by the script on every run; this is what the live process actually executes |

> 💡 If `update.sh` is run from outside `WORKDIR`, it auto-copies `converter.lua` and `utils.lua` from the current folder if they're present there.
>
> 💡 `update.sh` starts and recreates the live sing-box process itself via a PID file (`/var/run/sb_update_main.pid`) — needed for hot config reloads without a separate daemon script. Boot-time autostart is still handled by your own init script/cron.

### 🚀 Quick Start

[#-quick-start](#-quick-start)

**Option A — one-liner installer:**

```
wget -O- https://raw.githubusercontent.com/Sophiedevops/singbox-padavan-easy-crawler-2/main/install.sh | sh
```

**Option B — manual installation**

```
ssh admin@192.168.1.1
cd /opt/tmp_sb_ext/sing-box-1.12.12-extended-1.5.1-linux-mipsle

RAW="https://raw.githubusercontent.com/Sophiedevops/singbox-padavan-easy-crawler-2/main"
wget -O update.sh        "$RAW/scripts/update.sh"
wget -O gen_links.sh     "$RAW/scripts/gen_links.sh"
wget -O converter.lua    "$RAW/scripts/converter.lua"
wget -O utils.lua        "$RAW/scripts/utils.lua"
wget -O conf3_final.json "$RAW/templates/conf3_final.json"

chmod +x update.sh gen_links.sh && ./update.sh
```
> `conf2_final.json` (the active config) does not need to be created manually — it appears automatically after the first successful pipeline run.

> **💡 Cron — auto-update every 3 days at 03:00:**
>
> ```
> 0 3 */3 * * cd /opt/tmp_sb_ext/sing-box-1.12.12-extended-1.5.1-linux-mipsle && ./update.sh >> /opt/tmp/sb_update.log 2>&1
> ```

### ⚙️ Configuration

[#️-configuration](#️-configuration)

```
ENCRYPTION_PRIORITY=1           # 1=Standard 2=Paranoid 3=Hybrid
SORT_PRIORITY=0                 # 0=Protocol→Country 1=Country→Protocol
WANTED=10                       # Number of working nodes in the final config
PERFECT_SPEED_KBPS=900          # Minimum download speed to accept a node
MIN_FAST_CHECK_SPEED_KBPS=600   # Speed threshold for the Smart Fast-Check pass
MAX_ACCEPTABLE_PING=3000        # Max Clash API ping (ms)
FILTER_COUNTRIES="nl de us pl fi jp tw sg hk fr se uk gb ca ru tr md kr"
PRIORITY_PROTOCOLS="shadowsocks hysteria2 vless hysteria trojan vmess"
```
> Advanced (rarely needs changing): `TEST_PORT=25555` — local SOCKS5 for testing, `TEST_API_PORT=9092` — Clash API port of the test instance.

**🔒 Encryption Mode (ENCRYPTION_PRIORITY)**

| Value | Mode | Description |
| --- | --- | --- |
| `1` | **Standard** | All protocols, no filtering — open SS and bare VLESS stay in normal order |
| `2` | **Paranoid** ⭐ | VLESS without TLS and unencrypted SS are dropped immediately — including from the fallback group |
| `3` | **Hybrid** | Unencrypted nodes aren't discarded, just pushed to the very end of the priority queue |

**🗺️ Sort Mode (SORT_PRIORITY)**

| Value | Logic | Best for |
| --- | --- | --- |
| `0` | **Protocol → Country** | Weak routers: SS is lighter to encrypt, saves CPU |
| `1` | **Country → Protocol** | Gamers: guarantees lowest ping to a specific country |

```
Example SORT=0, ENC=2:
① SS+AEAD from NL → DE → US → … → KR     ④ HY2/VLESS+TLS/Hysteria/Trojan/VMess from NL → DE → …     ⑦ Fallback (worldwide, still no open nodes)
```

**📡 Subscription Sources (8 aggregators, 60,000+ nodes)**

| # | Repository | Protocols |
| --- | --- | --- |
| 1 | [`sub.whitedns.one`](https://sub.whitedns.one/sub/base64.txt) (Base64 subscription) | Mix |
| 2 | [`sakha1370/OpenRay`](https://raw.githubusercontent.com/sakha1370/OpenRay/refs/heads/main/output/all_valid_proxies.txt) | Mix |
| 3 | [`SoliSpirit/v2ray-configs`](https://raw.githubusercontent.com/SoliSpirit/v2ray-configs/refs/heads/main/Protocols/ss.txt) | SS |
| 4 | [`ebrasha/free-v2ray-public-list`](https://raw.githubusercontent.com/ebrasha/free-v2ray-public-list/refs/heads/main/all_extracted_configs.txt) | Mix |
| 5 | [`V2RayRoot/V2RayConfig`](https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/refs/heads/main/Config/vless.txt) | VLESS |
| 6 | [`amirkma/proxykma`](https://raw.githubusercontent.com/amirkma/proxykma/refs/heads/main/mix.txt) | Mix |
| 7 | [`mahdibland/V2RayAggregator`](https://raw.githubusercontent.com/mahdibland/V2RayAggregator/refs/heads/master/sub/sub_merge.txt) | Mix |
| 8 | [`gongchandang49/TelegramV2rayCollector`](https://raw.githubusercontent.com/gongchandang49/TelegramV2rayCollector/refs/heads/main/sub/mix) | Mix |

> ⚠️ When adding your own sources, always use **Raw** links (`raw.githubusercontent.com`), not GitHub blob pages — otherwise the script downloads HTML instead of proxy data.

### 🔗 Client Links

[#-client-links](#-client-links)

`gen_links.sh` auto-detects the router's IP and generates URIs for all inbounds. With a static IP or DDNS you can also connect from outside the LAN.

```
./gen_links.sh
```

**Example output**

```
Detected Router LAN IP: 192.168.1.1
--- SOCKS5 ---      socks5://192.168.1.1:1080#socks5-in
--- HTTP/Mixed ---  http://192.168.1.1:2080#mixed-in
--- Shadowsocks --- ss://Y2hhY2hhM...@192.168.1.1:8388#ss-in
--- Hysteria 2 ---  hy2://MyPassword@192.168.1.1:4443?insecure=1#hy2-in
DONE! All links saved to clients.txt
```
> **SOCKS5** — recommended for most devices. Fully routes both TCP and UDP.
> **HTTP/Mixed** — fallback for older Smart TVs. TCP only, no UDP support.

Compatible with **v2rayNG** · **NekoBox** · **Hiddify** · **Sing-Box Mobile** · **Karing**

### 📋 Requirements

[#-requirements](#-requirements)

| Component | Details |
| --- | --- |
| 🔧 Firmware | Padavan (Asus Merlin-based) |
| 💾 Storage | USB drive with Entware at `/opt/` |
| 📦 Packages | `curl wget jq lua bash coreutils-sort grep` |
| ⚙️ Binary | `sing-box linux-mipsle-softfloat` or `hardfloat` |
| 📄 Configs | `conf3_final.json` (template) — `conf2_final.json` is generated automatically |

> 💡 `openssl-util` is **no longer required** — subscription Base64 decoding is implemented in pure Lua right inside `update.sh`.

**🔧 FAQ — Common Issues**

| Error | Fix |
| --- | --- |
| `converter.lua crashed` | Make sure `converter.lua` and `utils.lua` sit next to the script — they're auto-copied when running from outside `WORKDIR` |
| `All subscription links returned empty` | Check DNS: `nslookup raw.githubusercontent.com` |
| `Failed to connect to Speed Test CDNs` | Both CDNs (Cloudflare and CacheFly) are unreachable — check your internet or a possible ISP block |
| All nodes 0 KB/s | `curl -Is https://speed.cloudflare.com/__down?bytes=1` should return `200 OK` |
| `grep: unknown option` | `opkg install grep` |
| Script hangs / live process won't restart | `killall sing-box && rm -f /var/run/sb_update_main.pid` |

**⚠️ Disclaimer**

This script is provided **"as is"** for educational purposes only. Public proxies **may log your traffic** — do not transmit sensitive data through them. Use `ENCRYPTION_PRIORITY=2`.

---

## 🇮🇷 فارسی

**جستجو، آزمایش و مدیریت مستقیم پروسس زنده Sing-Box روی روتر ضعیف MIPS**
> **تنها اسکریپتی** که می‌تواند پایگاه داده **۶۰٬۰۰۰+ نود پروکسی** را
> روی روتری با **۳۲ مگابایت RAM آزاد** بدون هنگ‌کردن، OOM یا داغ‌شدن پردازنده هضم کند.

> **🆕 تغییرات این نسخه از `update.sh`:**
> - اسکریپت اکنون **خودش پروسس زنده** sing-box را از طریق فایل PID مدیریت می‌کند (شروع/توقف/راه‌اندازی مجدد گرم)
> - **Provider Auto-Pilot** — انتخاب خودکار CDN فعال برای تست سرعت و نقطه پینگ فعال
> - پوشش کشورها به **۱۸ کشور** و پروتکل‌ها به **۶ پروتکل** رسید (Hysteria v1 جدا از Hysteria2 اضافه شد)
> - رمزگشای Base64 با **Lua خالص** درون خود اسکریپت بازنویسی شد — دیگر نیازی به `openssl`/`base64` نیست
> - منابع اشتراک به‌روزرسانی شد: افزودن `whitedns.one`، حذف ۳ منبع قدیمی (**۸ منبع** به‌جای ۱۰)
> - سقف نمونه‌گیری حافظه به **~۵۵۰۰ رکورد** افزایش یافت (۴ دسته وزن‌دار به‌جای یک استخر ساده)

### 🔄 نحوه کارکرد پایپ‌لاین (ترتیب اجرا)

[#-نحوه-کارکرد-پایپ‌لاین-ترتیب-اجرا](#-نحوه-کارکرد-پایپ‌لاین-ترتیب-اجرا)

1. **Smart Fast-Check.** اگر `conf2_final.json` از قبل وجود داشته باشد، اسکریپت پول فعلی را بررسی می‌کند: پینگ از طریق Clash API و سپس تست سرعت واقعی. اگر نودهای پایدار ≥۷۰٪ مقدار `WANTED` باشند (۷ نود برای `WANTED=10`) — کل پایپ‌لاین سنگین رد می‌شود.
2. **دانلود و رمزگشایی خودکار.** هر ۸ منبع اشتراک به‌ترتیب دریافت می‌شوند؛ در صورت نیاز محتوا از رمزگشای Base64 نوشته‌شده با Lua عبور می‌کند.
3. **استخراج‌کننده الماس + محافظت RAM.** لینک‌ها به ۴ دسته تقسیم می‌شوند (VIP-SS / VIP-سایر / SS عادی / سایر عادی) و هرکدام با نمونه‌گیری `awk` محدود می‌شوند (تا ۲۵۰۰ / ۲۰۰۰ / ۵۰۰ / ۵۰۰ رکورد).
4. **ماتریس مرتب‌سازی سراسری.** نودها بر اساس `ENCRYPTION_PRIORITY` و `SORT_PRIORITY` اولویت‌بندی می‌شوند، به‌علاوه یک بلوک fallback برای کشورهای خارج از لیست.
5. **چرخه اسکن در دسته‌های ۳ نودی.** برای هر دسته یک نمونه آزمایشی sing-box اجرا می‌شود؛ نودهای موفق در تست پینگ، تست سرعت واقعی می‌شوند تا به `WANTED` برسند.
6. **مونتاژ و جابه‌جایی گرم.** بهترین نودها در یک سلکتور `Best-Auto` قرار می‌گیرند، در `conf3_final.json` ادغام و در `conf2_final.json` نوشته می‌شوند؛ سپس پروسس زنده با حدود ۱ ثانیه توقف، مجدداً راه‌اندازی می‌شود.

### ✨ قابلیت‌ها

[#-قابلیت‌ها](#-قابلیت‌ها)

| **🛡️ محافظت Anti-OOM** انتخاب پویا بین `tmpfs` (در صورت آزاد بودن بیش از ۱۵۰ مگابایت RAM) و ذخیره‌سازی دیسک، به‌علاوه نمونه‌گیری وزن‌دار — حداکثر ~۵۵۰۰ رکورد هم‌زمان در حافظه.<br>**⚡ Smart Fast-Check** آستانه نگه‌داری = ۷۰٪ از `WANTED`.<br>**🔒 حالت پارانوئید رمزنگاری** VLESS بدون TLS و SS بدون رمزنگاری حتی از گروه fallback نیز حذف می‌شوند (حالت `2`).<br>**🧩 رمزگشای Base64 با Lua خالص** بدون نیاز به باینری خارجی `openssl`/`base64`. | **🗺️ ماتریس اولویت** ۱۸ کشور × ۶ پروتکل (شامل Hysteria و Hysteria2 جداگانه).<br>**🛰️ Provider Auto-Pilot** *(جدید)* انتخاب خودکار CDN و نقطه پینگ فعال — در برابر مسدودسازی یکی از سرویس‌ها مقاوم است.<br>**🔄 Live-Process Supervisor** *(جدید)* `update.sh` خودش پروسس اصلی sing-box را از طریق فایل PID اجرا و ری‌استارت می‌کند؛ تنها ~۱ ثانیه توقف.<br>**🧟 محافظت Anti-Zombie** `trap` روی `INT/TERM` به‌همراه `kill_testers()` پروسس‌های آزمایشی باقی‌مانده را قطعاً پاک می‌کند. |
| --- | --- |

### 📦 ساختار پروژه

[#-ساختار-پروژه](#-ساختار-پروژه)

| فایل | هدف |
| --- | --- |
| `./update.sh` | 🔧 **موتور اصلی** — پایپ‌لاین ۶ مرحله‌ای به‌علاوه supervisor پروسس زنده |
| `./gen_links.sh` | 🔗 **تولیدکننده لینک** — URIهای آماده برای کلاینت‌های شبکه محلی |
| `converter.lua` | ⚙️ **پارسر URI** — تبدیل `ss://`، `vless://` و غیره به فرمت Sing-Box |
| `utils.lua` | 🛠️ توابع کمکی برای مبدّل |
| `conf3_final.json` | 📋 **الگو (پایه)** — هرگز مستقیم ویرایش نمی‌شود |
| `conf2_final.json` | ⚡ **کانفیگ فعال** — در هر اجرا بازنویسی می‌شود؛ پروسس زنده دقیقاً همین فایل را اجرا می‌کند |

> 💡 اگر `update.sh` خارج از `WORKDIR` اجرا شود، `converter.lua` و `utils.lua` را خودکار از پوشه فعلی کپی می‌کند.

### 🚀 شروع سریع

[#-شروع-سریع](#-شروع-سریع)

**گزینه الف — نصب تک‌خطی:**

```
wget -O- https://raw.githubusercontent.com/Sophiedevops/singbox-padavan-easy-crawler-2/main/install.sh | sh
```

**گزینه ب — نصب دستی**

```
ssh admin@192.168.1.1
cd /opt/tmp_sb_ext/sing-box-1.12.12-extended-1.5.1-linux-mipsle

RAW="https://raw.githubusercontent.com/Sophiedevops/singbox-padavan-easy-crawler-2/main"
wget -O update.sh        "$RAW/scripts/update.sh"
wget -O gen_links.sh     "$RAW/scripts/gen_links.sh"
wget -O converter.lua    "$RAW/scripts/converter.lua"
wget -O utils.lua        "$RAW/scripts/utils.lua"
wget -O conf3_final.json "$RAW/templates/conf3_final.json"

chmod +x update.sh gen_links.sh && ./update.sh
```
> **💡 Cron — به‌روزرسانی خودکار هر ۳ روز ساعت ۰۳:۰۰:**
>
> ```
> 0 3 */3 * * cd /opt/tmp_sb_ext/sing-box-1.12.12-extended-1.5.1-linux-mipsle && ./update.sh >> /opt/tmp/sb_update.log 2>&1
> ```

### ⚙️ تنظیمات

[#️-تنظیمات](#️-تنظیمات)

```
ENCRYPTION_PRIORITY=1           # 1=استاندارد 2=پارانوئید 3=ترکیبی
SORT_PRIORITY=0                 # 0=پروتکل←کشور 1=کشور←پروتکل
WANTED=10                       # تعداد نودهای کارکرد در کانفیگ نهایی
PERFECT_SPEED_KBPS=900          # حداقل سرعت دانلود برای پذیرش نود
MIN_FAST_CHECK_SPEED_KBPS=600   # آستانه سرعت برای Smart Fast-Check
MAX_ACCEPTABLE_PING=3000        # حداکثر پینگ از طریق Clash API (ms)
FILTER_COUNTRIES="nl de us pl fi jp tw sg hk fr se uk gb ca ru tr md kr"
PRIORITY_PROTOCOLS="shadowsocks hysteria2 vless hysteria trojan vmess"
```

**🔒 حالت رمزنگاری (ENCRYPTION_PRIORITY)**

| مقدار | حالت | توضیح |
| --- | --- | --- |
| `1` | **استاندارد** | همه پروتکل‌ها بدون فیلتر |
| `2` | **پارانوئید** ⭐ | VLESS بدون TLS و SS بدون رمزنگاری حتی از fallback نیز حذف می‌شوند |
| `3` | **ترکیبی** | نودهای «برهنه» حذف نمی‌شوند، فقط به انتهای صف می‌روند |

**🗺️ حالت مرتب‌سازی (SORT_PRIORITY)**

| مقدار | منطق | برای چه کسی |
| --- | --- | --- |
| `0` | **پروتکل ← کشور** | روترهای ضعیف: SS سبک‌تر رمزگذاری می‌شود |
| `1` | **کشور ← پروتکل** | گیمرها: کمترین پینگ به کشور مورد نظر |

**📡 منابع اشتراک (۸ آگریگیتور، ۶۰٬۰۰۰+ نود)**

| # | مخزن | پروتکل‌ها |
| --- | --- | --- |
| ۱ | [`sub.whitedns.one`](https://sub.whitedns.one/sub/base64.txt) (اشتراک Base64) | Mix |
| ۲ | [`sakha1370/OpenRay`](https://raw.githubusercontent.com/sakha1370/OpenRay/refs/heads/main/output/all_valid_proxies.txt) | Mix |
| ۳ | [`SoliSpirit/v2ray-configs`](https://raw.githubusercontent.com/SoliSpirit/v2ray-configs/refs/heads/main/Protocols/ss.txt) | SS |
| ۴ | [`ebrasha/free-v2ray-public-list`](https://raw.githubusercontent.com/ebrasha/free-v2ray-public-list/refs/heads/main/all_extracted_configs.txt) | Mix |
| ۵ | [`V2RayRoot/V2RayConfig`](https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/refs/heads/main/Config/vless.txt) | VLESS |
| ۶ | [`amirkma/proxykma`](https://raw.githubusercontent.com/amirkma/proxykma/refs/heads/main/mix.txt) | Mix |
| ۷ | [`mahdibland/V2RayAggregator`](https://raw.githubusercontent.com/mahdibland/V2RayAggregator/refs/heads/master/sub/sub_merge.txt) | Mix |
| ۸ | [`gongchandang49/TelegramV2rayCollector`](https://raw.githubusercontent.com/gongchandang49/TelegramV2rayCollector/refs/heads/main/sub/mix) | Mix |

> ⚠️ هنگام افزودن منابع خود، همیشه از لینک‌های **Raw** استفاده کنید (`raw.githubusercontent.com`)، نه صفحات blob گیت‌هاب.

### 🔗 لینک‌های کلاینت

[#-لینک‌های-کلاینت](#-لینک‌های-کلاینت)

`gen_links.sh` به‌طور خودکار IP روتر را شناسایی کرده و URI برای تمام inboundها تولید می‌کند.

```
./gen_links.sh
```
> **SOCKS5** — برای اکثر دستگاه‌ها توصیه می‌شود. TCP و UDP را به‌طور کامل روت می‌کند.
> **HTTP/Mixed** — گزینه جایگزین برای Smart TVهای قدیمی. فقط TCP.

سازگار با **v2rayNG** · **NekoBox** · **Hiddify** · **Sing-Box Mobile** · **Karing**

### 📋 پیش‌نیازها

[#-پیش‌نیازها](#-پیش‌نیازها)

| مؤلفه | نیاز |
| --- | --- |
| 🔧 فریمور | Padavan (مبتنی بر Asus Merlin) |
| 💾 فضای ذخیره | USB با Entware در `/opt/` |
| 📦 بسته‌ها | `curl wget jq lua bash coreutils-sort grep` |
| ⚙️ باینری | `sing-box linux-mipsle-softfloat` یا `hardfloat` |
| 📄 کانفیگ‌ها | `conf3_final.json` (الگو) — `conf2_final.json` خودکار ساخته می‌شود |

> 💡 دیگر نیازی به `openssl-util` نیست — رمزگشایی Base64 با Lua خالص درون خود اسکریپت انجام می‌شود.

**🔧 سوالات متداول**

| خطا | راه‌حل |
| --- | --- |
| `converter.lua crashed` | وجود `converter.lua` و `utils.lua` کنار اسکریپت را بررسی کنید |
| `All subscription links returned empty` | DNS را بررسی کنید: `nslookup raw.githubusercontent.com` |
| `Failed to connect to Speed Test CDNs` | هر دو CDN (Cloudflare و CacheFly) در دسترس نیستند |
| همه نودها ۰ KB/s | `curl -Is https://speed.cloudflare.com/__down?bytes=1` باید `200 OK` برگرداند |
| `grep: unknown option` | `opkg install grep` |
| اسکریپت هنگ کرد / پروسس زنده ری‌استارت نمی‌شود | `killall sing-box && rm -f /var/run/sb_update_main.pid` |

**⚠️ سلب مسئولیت**

این اسکریپت **«به همین شکل»** برای اهداف آموزشی ارائه می‌شود. پروکسی‌های عمومی **ممکن است ترافیک شما را ثبت کنند** — داده‌های حساس را از طریق آن‌ها ارسال نکنید. از `ENCRYPTION_PRIORITY=2` استفاده کنید.

---

## 🇨🇳 中文

**在低配 MIPS 路由器上自动搜索、测试代理并直接管理 Sing-Box 的常驻进程**

**( 已在 MiWiFi 3 | Xiaomi Mi-router 3 上测试 )**
> **唯一能在仅 32 MB 可用内存的路由器上**
> 处理 **60,000+ 代理节点** 数据库的脚本 — 不卡顿、不 OOM、不过热。

> **🆕 此版本 `update.sh` 的变化：**
> - 脚本现在通过 PID 文件**自行管理 sing-box 常驻进程**（启动/停止/热重启），而不仅仅是生成配置
> - **Provider Auto-Pilot** — 自动选择可用的测速 CDN 和可用的 ping 端点，而非写死单一地址
> - 国家覆盖扩展到 **18 个国家**，协议增至 **6 种**（新增独立的 Hysteria v1，与 Hysteria2 分开）
> - 订阅 Base64 解码器改为脚本内置的**纯 Lua 实现** — 不再依赖 `openssl`/`base64`
> - 订阅源已更新：新增 `whitedns.one`，移除 3 个过时聚合源（**8 个来源**，原为 10 个）
> - RAM 保护采样上限提升至 **~5,500 条记录**（4 个加权分桶，而非单一池）
> - 阈值上调：`PERFECT_SPEED_KBPS` 800→**900**，`MIN_FAST_CHECK_SPEED_KBPS` 500→**600**

### 🔄 流水线如何运作（执行顺序）

[#-流水线如何运作执行顺序](#-流水线如何运作执行顺序)

1. **Smart Fast-Check。** 若 `conf2_final.json` 已存在，脚本会检查当前节点池：先通过 Clash API 测 ping，再做真实测速。若稳定节点数 ≥ `WANTED` 的 70%（`WANTED=10` 时即 7 个）— 整个重型流水线被跳过，常驻进程被（重新）拉起，脚本退出。
2. **下载与自动解码。** 依次拉取全部 8 个订阅源；若内容不像 `ss://`/`vless://`/`vmess://`/`trojan://`/`hysteria2://` 链接，则交给脚本内置的 Lua Base64 解码器处理，并自动清除 `\0`、`\r` 等垃圾字节。
3. **钻石提取器 + RAM 保护。** 链接按国家标签匹配被分为 4 个分桶（VIP-SS / VIP-其他 / 普通-SS / 普通-其他），每个分桶通过 `awk` 采样限流（最多 2500 / 2000 / 500 / 500 条），随后一次性经 `converter.lua` 转换为 JSON。
4. **全局排序矩阵。** 根据 `ENCRYPTION_PRIORITY` 与 `SORT_PRIORITY`（国家↔协议）对节点排序优先级，并为 `FILTER_COUNTRIES` 列表之外的国家单独生成 fallback 区块。
5. **以 3 个节点为一批的扫描循环。** 每批次拉起一个测试用 sing-box 实例，通过 Clash API 测 ping，通过的节点再经本地 SOCKS5 做真实测速。达到 `PERFECT_SPEED_KBPS` 的节点被保留，直至凑满 `WANTED` 个。
6. **组装与热切换。** 最优节点被打包为 `Best-Auto` urltest 选择器，合并进 `conf3_final.json` 模板后写入 `conf2_final.json`；随后常驻 sing-box 进程被停止并重新拉起 — 停机时间约 1 秒。

### ✨ 功能特性

[#-功能特性](#-功能特性)

| **🛡️ Anti-OOM 保护** 动态选择 `tmpfs`（空闲内存 >150 MB 时）或磁盘存储，配合加权 `awk` 采样 — 内存中同时持有的记录永不超过约 5,500 条。<br>**⚡ 智能快速检查** 保留阈值 = `WANTED` 的 70%。存活节点足够时直接跳过整个重型流水线。<br>**🔒 偏执加密模式** 排序阶段即剔除无 TLS 的 VLESS 与未加密的 Shadowsocks；模式 `2` 连 fallback 分组也会过滤。<br>**🧩 纯 Lua Base64 解码器** 订阅直接在 `update.sh` 内解码，无需外部 `openssl`/`base64` 二进制。 | **🗺️ 优先级矩阵** 18 个国家 × 6 种协议（含独立的 Hysteria 与 Hysteria2）。两种模式：协议→国家 或 国家→协议。<br>**🛰️ Provider Auto-Pilot** *(新增)* 自动选择可用的测速 CDN（Cloudflare / CacheFly）与可用的 ping 端点（Cloudflare / Apple / Microsoft / MIUI）— 任一服务被墙也能正常工作。<br>**🔄 常驻进程 Supervisor** *(新增)* `update.sh` 通过 PID 文件自行启动并重启主 sing-box 进程；热重载停机仅约 1 秒。<br>**🧟 Anti-Zombie 保护** `INT/TERM` 上的 `trap` 加 `kill_testers()`，通过扫描 `/proc/*/cmdline` 可靠清理残留测试进程，即便手动中断脚本也不例外。 |
| --- | --- |

### 📦 项目结构

[#-项目结构](#-项目结构)

| 文件 | 用途 |
| --- | --- |
| `./update.sh` | 🔧 **主引擎** — 6 阶段流水线 + 内置常驻进程 supervisor |
| `./gen_links.sh` | 🔗 **链接生成器** — 为局域网客户端生成即用 URI |
| `converter.lua` | ⚙️ **URI 解析器** — 将 `ss://`、`vless://` 等转换为 Sing-Box 格式 |
| `utils.lua` | 🛠️ 转换器辅助函数 |
| `conf3_final.json` | 📋 **模板（基础）** — 从不直接修改，作为合并目标 |
| `conf2_final.json` | ⚡ **活动配置** — 每次运行都会被脚本覆盖；常驻进程实际执行的就是这份文件 |

> 💡 若 `update.sh` 不在 `WORKDIR` 中运行，会自动从当前目录复制 `converter.lua` 和 `utils.lua`（如果存在）。
>
> 💡 `update.sh` 通过 PID 文件（`/var/run/sb_update_main.pid`）自行拉起并重建常驻 sing-box 进程，用于实现免外部守护进程的热重载；路由器重启后的开机自启仍由您自己的 init 脚本/cron 负责。

### 🚀 快速开始

[#-快速开始](#-快速开始)

**方式 A — 一键安装脚本：**

```
wget -O- https://raw.githubusercontent.com/Sophiedevops/singbox-padavan-easy-crawler-2/main/install.sh | sh
```

**方式 B — 手动安装**

```
ssh admin@192.168.1.1
cd /opt/tmp_sb_ext/sing-box-1.12.12-extended-1.5.1-linux-mipsle

RAW="https://raw.githubusercontent.com/Sophiedevops/singbox-padavan-easy-crawler-2/main"
wget -O update.sh        "$RAW/scripts/update.sh"
wget -O gen_links.sh     "$RAW/scripts/gen_links.sh"
wget -O converter.lua    "$RAW/scripts/converter.lua"
wget -O utils.lua        "$RAW/scripts/utils.lua"
wget -O conf3_final.json "$RAW/templates/conf3_final.json"

chmod +x update.sh gen_links.sh && ./update.sh
```
> **💡 Cron — 每 3 天凌晨 03:00 自动更新：**
>
> ```
> 0 3 */3 * * cd /opt/tmp_sb_ext/sing-box-1.12.12-extended-1.5.1-linux-mipsle && ./update.sh >> /opt/tmp/sb_update.log 2>&1
> ```

### ⚙️ 配置说明

[#️-配置说明](#️-配置说明)

```
ENCRYPTION_PRIORITY=1           # 1=标准 2=偏执 3=混合
SORT_PRIORITY=0                 # 0=协议→国家 1=国家→协议
WANTED=10                       # 最终配置中需要的可用节点数量
PERFECT_SPEED_KBPS=900          # 接受节点的最低下载速度
MIN_FAST_CHECK_SPEED_KBPS=600   # 快速检查阶段的速度阈值
MAX_ACCEPTABLE_PING=3000        # Clash API 最大延迟 (ms)
FILTER_COUNTRIES="nl de us pl fi jp tw sg hk fr se uk gb ca ru tr md kr"
PRIORITY_PROTOCOLS="shadowsocks hysteria2 vless hysteria trojan vmess"
```
> 高级选项（通常无需更改）：`TEST_PORT=25555` — 本地测试用 SOCKS5 端口，`TEST_API_PORT=9092` — 测试实例的 Clash API 端口。

**🔒 加密模式 (ENCRYPTION_PRIORITY)**

| 值 | 模式 | 说明 |
| --- | --- | --- |
| `1` | **标准** | 所有协议，不过滤 |
| `2` | **偏执** ⭐ | 无 TLS 的 VLESS 和未加密的 SS 立即删除，连 fallback 分组也会过滤 |
| `3` | **混合** | 裸节点不删除，只是排到队列最末 |

**🗺️ 排序模式 (SORT_PRIORITY)**

| 值 | 逻辑 | 适用场景 |
| --- | --- | --- |
| `0` | **协议 → 国家** | 低配路由器：SS 加密更轻量，节省 CPU |
| `1` | **国家 → 协议** | 游戏玩家：保证目标国家最低延迟 |

```
示例 SORT=0, ENC=2:
① NL 的 SS+AEAD → DE → US → … → KR     ④ NL 的 HY2/VLESS+TLS/Hysteria/Trojan/VMess → DE → …     ⑦ 全球 Fallback（同样不含明文节点）
```

**📡 订阅源（8 个聚合器，60,000+ 节点）**

| # | 仓库 | 协议 |
| --- | --- | --- |
| 1 | [`sub.whitedns.one`](https://sub.whitedns.one/sub/base64.txt)（Base64 订阅） | Mix |
| 2 | [`sakha1370/OpenRay`](https://raw.githubusercontent.com/sakha1370/OpenRay/refs/heads/main/output/all_valid_proxies.txt) | Mix |
| 3 | [`SoliSpirit/v2ray-configs`](https://raw.githubusercontent.com/SoliSpirit/v2ray-configs/refs/heads/main/Protocols/ss.txt) | SS |
| 4 | [`ebrasha/free-v2ray-public-list`](https://raw.githubusercontent.com/ebrasha/free-v2ray-public-list/refs/heads/main/all_extracted_configs.txt) | Mix |
| 5 | [`V2RayRoot/V2RayConfig`](https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/refs/heads/main/Config/vless.txt) | VLESS |
| 6 | [`amirkma/proxykma`](https://raw.githubusercontent.com/amirkma/proxykma/refs/heads/main/mix.txt) | Mix |
| 7 | [`mahdibland/V2RayAggregator`](https://raw.githubusercontent.com/mahdibland/V2RayAggregator/refs/heads/master/sub/sub_merge.txt) | Mix |
| 8 | [`gongchandang49/TelegramV2rayCollector`](https://raw.githubusercontent.com/gongchandang49/TelegramV2rayCollector/refs/heads/main/sub/mix) | Mix |

> ⚠️ 添加自定义来源时，请始终使用 **Raw** 链接（`raw.githubusercontent.com`），而非 GitHub blob 页面 — 否则脚本会下载 HTML 而非代理数据。

### 🔗 客户端链接

[#-客户端链接](#-客户端链接)

`gen_links.sh` 自动检测路由器 IP 并为所有入站生成 URI。如有静态 IP 或 DDNS，也可从局域网外连接。

```
./gen_links.sh
```

**示例输出**

```
Detected Router LAN IP: 192.168.1.1
--- SOCKS5 ---      socks5://192.168.1.1:1080#socks5-in
--- HTTP/Mixed ---  http://192.168.1.1:2080#mixed-in
--- Shadowsocks --- ss://Y2hhY2hhM...@192.168.1.1:8388#ss-in
--- Hysteria 2 ---  hy2://MyPassword@192.168.1.1:4443?insecure=1#hy2-in
DONE! All links saved to clients.txt
```
> **SOCKS5** — 推荐用于大多数设备。完整路由 TCP 和 UDP。
> **HTTP/Mixed** — 老款智能电视的备选方案。仅支持 TCP，不支持 UDP。

兼容 **v2rayNG** · **NekoBox** · **Hiddify** · **Sing-Box 手机版** · **Karing**

### 📋 环境要求

[#-环境要求](#-环境要求)

| 组件 | 说明 |
| --- | --- |
| 🔧 固件 | Padavan（基于 Asus Merlin） |
| 💾 存储 | 安装了 Entware 的 USB 存储器（挂载于 `/opt/`） |
| 📦 软件包 | `curl wget jq lua bash coreutils-sort grep` |
| ⚙️ 二进制文件 | `sing-box linux-mipsle-softfloat` 或 `hardfloat` |
| 📄 配置 | `conf3_final.json`（模板）— `conf2_final.json` 自动生成 |

> 💡 不再需要 `openssl-util` — 订阅 Base64 解码已在 `update.sh` 内以纯 Lua 实现。

**🔧 常见问题**

| 错误 | 解决方法 |
| --- | --- |
| `converter.lua crashed` | 检查脚本同目录下是否有 `converter.lua` 和 `utils.lua`（在 `WORKDIR` 外运行时会自动复制） |
| `All subscription links returned empty` | 检查 DNS：`nslookup raw.githubusercontent.com` |
| `Failed to connect to Speed Test CDNs` | Cloudflare 与 CacheFly 均不可达 — 检查网络或运营商屏蔽 |
| 所有节点 0 KB/s | `curl -Is https://speed.cloudflare.com/__down?bytes=1` 应返回 `200 OK` |
| `grep: unknown option` | `opkg install grep` |
| 脚本卡住 / 常驻进程无法重启 | `killall sing-box && rm -f /var/run/sb_update_main.pid` |

**⚠️ 免责声明**

本脚本仅供教育目的 **"按原样"** 提供。公共代理**可能记录您的流量** — 请勿通过它们传输敏感数据。请使用 `ENCRYPTION_PRIORITY=2`。

---

献给热爱自由路由和经典 MIPS 路由器的人们 ❤️

**如果这个项目对您有帮助，请点个 ⭐**

---

🇷🇺 [Русский](#-русский) · 🇬🇧 [English](#-english) · 🇮🇷 [فارسی](#-فارسی) · 🇨🇳 [中文](#-中文)
