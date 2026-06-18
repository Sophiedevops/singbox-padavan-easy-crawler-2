<div align="center">

```
███████╗██╗███╗   ██╗ ██████╗       ██████╗  ██████╗ ██╗  ██╗
██╔════╝██║████╗  ██║██╔════╝       ██╔══██╗██╔═══██╗╚██╗██╔╝
███████╗██║██╔██╗ ██║██║  ███╗█████╗██████╔╝██║   ██║ ╚███╔╝ 
╚════██║██║██║╚██╗██║██║   ██║╚════╝██╔══██╗██║   ██║ ██╔██╗ 
███████║██║██║ ╚████║╚██████╔╝      ██████╔╝╚██████╔╝██╔╝ ██╗
╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝       ╚═════╝  ╚═════╝ ╚═╝  ╚═╝
```

**Smart Proxy Crawler & Auto-Updater for Sing-Box on Padavan Routers**

[![Shell](https://img.shields.io/badge/Shell-POSIX_sh-4EAA25?style=for-the-badge&logo=gnu-bash)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Padavan_|_MIPSLE-007ACC?style=for-the-badge&logo=openwrt)](https://github.com/RMerl/asuswrt-merlin)
[![Core](https://img.shields.io/badge/Core-Sing--Box_1.12-blueviolet?style=for-the-badge)](https://sing-box.sagernet.org/)
[![Status](https://img.shields.io/badge/Status-Stable_v2-success?style=for-the-badge)]()
[![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)]()

*Автоматический поиск, разбор, тестирование и ротация бесплатных прокси прямо на слабом MIPS-роутере — без OOM и без перегрева процессора.*

[**Установка**](#-быстрый-старт) · [**Конфигурация**](#️-конфигурация) · [**Матрица приоритетов**](#-матрица-приоритетов) · [**Устранение неполадок**](#-устранение-неполадок)

</div>

---

## 🧩 Что это такое?

Проект решает конкретную задачу: поддерживать **живой пул из 10 рабочих прокси** (Shadowsocks, VLESS, VMess, Trojan, Hysteria2) на роутере с **32–64 МБ свободной ОЗУ и процессором MIPSLE**, не роняя его при обработке агрегированных баз на 60 000+ нод.

| Файл | Роль |
|---|---|
| `update.sh` | Главный движок: скачивает 10 подписок → сэмплирует → парсит через Lua → тестирует батчами → hot-reload |
| `gen_links.sh` | Утилита: читает итоговый конфиг и печатает готовые `ss://`, `socks5://`, `hy2://` для клиентов в LAN |

---

## 🏗️ Архитектура пайплайна

```
┌──────────────────────────────────────────────────────────────────────┐
│                          update.sh  pipeline                         │
│                                                                      │
│  ① Smart Fast-Check      ② Скачивание          ③ Anti-OOM Sampling  │
│  Тест текущего конфига →  10 подписок        →  awk NR%STEP==0      │
│  если ≥70% нод живы      wget + auto-b64dec     SS  : ≤3500 линий   │
│  → досрочный exit 0      tr -d '\000\r'         rest: ≤1000 линий   │
│                                                                      │
│  ④ Lua converter         ⑤ Priority Matrix     ⑥ Batch Testing      │
│  subs_raw.txt         →  jq-фильтры         →  3 ноды за раз        │
│  → all_nodes.json        SORT × ENC mode        sing-box (tmp)      │
│                                                 Clash API + curl     │
│                                                 реальный DL ≥800KB/s │
│                                      ┌──────────────────────────────┘│
│                                      ▼                               │
│                          ⑦ Hot Reload                               │
│                          sort -rn results → top-N                   │
│                          jq merge с conf3_final → conf2_final       │
│                          stop_main → start_main                      │
└──────────────────────────────────────────────────────────────────────┘
```

---

## ⚙️ Как это работает — шаг за шагом

### ① Smart Fast-Check

Перед запуском полного сканирования скрипт проверяет **текущий** `conf2_final.json`:

- Поднимает временный `sing-box` на порту `25555` (SOCKS5) + Clash API на `9092`
- Ждёт **12 секунд** (холодный старт MIPS) и опрашивает `/proxies`
- Для каждой живой ноды делает реальную загрузку с `speed.cloudflare.com` или `cachefly.cachefly.net`
- **Порог удержания: 70% от `WANTED`** — если хотя бы 7 из 10 нод держат ≥500 KB/s, пайплайн прерывается

```
Retention Threshold set to: 7 nodes (70% of WANTED)
Node 🇳🇱NL-SS-01: 1243 KB/s  ✔ Acceptable
Node 🇩🇪DE-VLESS-03: 612 KB/s ✔ Acceptable
Node 🇺🇸US-HY2-02: 341 KB/s  ✘ Too slow
...
Current pool is acceptable (7/7 nodes verified). Aborting full scan.
```

### ② Скачивание 10 подписок

Скрипт обходит список из **10 агрегаторов** с GitHub. Для каждого:

1. `wget` → временный файл
2. `tr -d '\000\r'` — очистка нулевых байт и Windows-переносов (ломают `grep` на Padavan)
3. Проверка: есть ли строки `ss://`, `vless://` и т.д.
4. Если нет → попытка **Base64-декодирования** (`base64 -d`)
5. `grep` фильтрует только валидные URI, остальное отбрасывается

### ③ Anti-OOM Uniform Sampling

```sh
# Если Shadowsocks > 1500 строк:
STEP=$((SS_COUNT / 3500 + 1))
awk "NR % $STEP == 0" ss_only.txt >> subs_raw.txt
# Результат: равномерная выборка ~3500 нод из всей базы

# Если остальных > 1000:
STEP=$((OTHER_COUNT / 1000 + 1))
awk "NR % $STEP == 0" others.txt >> subs_raw.txt
```

Математически равномерная выборка через `awk` — роутер никогда не видит весь массив целиком.

### ④ Lua-конвертер

`converter.lua` читает `subs_raw.txt` и парсит каждый URI в JSON-объект формата Sing-Box:

```
ss://... → { "type": "shadowsocks", "tag": "...", "method": "...", ... }
vless://... → { "type": "vless", "tag": "...", "tls": { "enabled": true }, ... }
```

Результат: `all_nodes.json` — массив готовых аутбаундов.

### ⑤ Priority Matrix

Матрица строится из **двух независимых переменных**: `ENCRYPTION_PRIORITY` × `SORT_PRIORITY`. Реализована через цепочку `jq`-фильтров + shell-функции `add_ss_secure()`, `add_secure_others()`, `add_naked_others()`.

**Fallback-группа** (ноды из всех остальных стран, не вошедших в `FILTER_COUNTRIES`) добавляется в конец очереди в любом режиме.

### ⑥ Batch Testing (3 ноды за раз)

```
Batch 0-3...
  [DEBUG] Status Tracker Active:
    - 🇳🇱NL-SS-CHACHA: 312 ms
    - 🇩🇪DE-HY2-01:    890 ms
  [FOUND] 🇳🇱NL-SS-CHACHA : 1540 KB/s   Total Stored: 1 / 10
  [LOW]   🇩🇪DE-HY2-01 : 430 KB/s (passed ping, but below speed threshold)
```

Для каждой ноды:
- Временный `sing-box` с 3 аутбаундами + `urltest` + Clash API
- **14 секунд** ожидания (warmup для MIPSLE)
- Опрос Clash API `/proxies` — отсечение по `MAX_ACCEPTABLE_PING=3000ms`
- Реальный `curl -x socks5://` через аутбаунд — отсечение по `PERFECT_SPEED_KBPS=800`
- Результат пишется в `results.txt` как `KBPS|TAG`

### ⑦ Hot Reload

```sh
sort -rn results.txt | head -n $WANTED | cut -d'|' -f2 > top_tags.txt
# Сортировка по скорости (лучшие первыми) → выборка top-N тегов
# jq merge: conf3_final.json (шаблон с инбаундами и роутингом)
#           + final.json (аутбаунды) + urltest-группа
# → conf2_final.json (рабочий конфиг)
stop_main && sleep 1 && start_main
```

Без даунтайма: остановка занимает долю секунды, новый процесс сразу принимает соединения.

---

## 🔗 Генератор клиентских ссылок (`gen_links2.sh`)

Читает `conf2_final.json` и генерирует ссылки для **всех инбаундов** автоматически:

```sh
./gen_links2.sh
```

**Определение IP роутера** — три уровня fallback:
1. `nvram get lan_ipaddr` — родной метод Padavan
2. `ip addr show br0` — если nvram недоступен
3. `192.168.1.1` — хардкод

**Поддерживаемые форматы вывода:**

| Тип инбаунда | Формат ссылки |
|---|---|
| Mixed / HTTP | `http://192.168.1.1:PORT#TAG` |
| SOCKS5 | `socks5://192.168.1.1:PORT#TAG` |
| Shadowsocks | `ss://BASE64(method:pass)@IP:PORT#TAG` |
| Hysteria2 | `hy2://password@IP:PORT?insecure=1#TAG` |
| VLESS | `vless://UUID@IP:PORT?encryption=none&type=tcp#TAG` |
| Trojan | `trojan://password@IP:PORT?security=none#TAG` |

Все ссылки сохраняются в `clients.txt`. Совместимы с **v2rayNG**, **NekoBox**, **Hiddify**, **Sing-Box Mobile**.

---

## ✨ Ключевые особенности

**🛡️ Anti-OOM** — равномерный `awk`-сэмплинг, роутер никогда не держит в ОЗУ более ~4500 нод одновременно.

**⚡ Smart Fast-Check** — если пул живой (≥70% нод ≥500 KB/s), полный пайплайн пропускается. Экономит ресурс флешки и CPU.

**🔒 Параноидальный режим** — VLESS без TLS и SS с `method: none` вырезаются на этапе матрицы, до тестирования. Только современный AEAD.

**🧩 Авто-декодер** — прозрачная обработка Base64-подписок. Очистка `\0` и `\r`, несовместимых со встроенным `grep` прошивки Padavan.

**📊 Двухосевая матрица** — 6 независимых режимов поведения (3 режима шифрования × 2 режима сортировки).

**🔄 Zero-Downtime** — `jq`-мёрдж конфига + мгновенная замена процесса. Соединения не рвутся.

**🌍 Fallback-группа** — ноды из стран вне `FILTER_COUNTRIES` всегда добавляются в конец очереди, обеспечивая резерв.

---

## ⚙️ Требования

| Компонент | Требования |
|---|---|
| Прошивка | Padavan (Asus Merlin-based) или аналог на базе Linux |
| USB-накопитель | Entware в `/opt/` — обязательно |
| Пакеты | `curl wget jq lua openssl-util bash coreutils-sort` |
| Sing-Box | Бинарник `linux-mipsle-softfloat` или `hardfloat` |
| Конфиг | `conf3_final.json` — шаблон с инбаундами/роутингом без аутбаундов |
| Lua | `converter.lua` + `utils.lua` |

---

## 🚀 Быстрый старт

### Вариант А — однострочный установщик

```sh
wget -O install.sh https://raw.githubusercontent.com/Sophiedevops/singbox-padavan-easy-crawler-2/main/install.sh \
  && chmod +x install.sh && ./install.sh
```

Установщик сам скачает бинарник из Releases, все скрипты из `scripts/`, шаблон конфига из `templates/`, пропишет автозапуск и запустит первое обновление.

### Вариант Б — ручная установка

```sh
# 1. Подключитесь к роутеру
ssh admin@192.168.1.1

# 2. Перейдите в рабочую директорию
cd /opt/tmp_sb_ext/sing-box-1.12.12-extended-1.5.1-linux-mipsle

# 3. Скачайте скрипты
RAW="https://raw.githubusercontent.com/Sophiedevops/singbox-padavan-easy-crawler-2/main"
wget -O update.sh      "$RAW/scripts/update.sh"
wget -O gen_links2.sh  "$RAW/scripts/gen_links.sh"
wget -O converter.lua  "$RAW/scripts/converter.lua"
wget -O utils.lua      "$RAW/scripts/utils.lua"
wget -O conf3_final.json "$RAW/templates/conf3_final.json"

# 4. Права
chmod +x update.sh gen_links2.sh

# 5. Первый запуск
./update.sh
```

**Cron — автообновление каждые 3 дня в 03:00:**
```
0 3 */3 * * cd /opt/tmp_sb_ext/sing-box-1.12.12-extended-1.5.1-linux-mipsle && ./update.sh >> /opt/tmp/sb_update.log 2>&1
```

---

## 🎛️ Конфигурация

Все настройки — в шапке файла `update.sh`.

### Основные параметры

```sh
WANTED=10                      # Целевое количество рабочих нод в конфиге
PERFECT_SPEED_KBPS=800         # Минимальная скорость для принятия ноды (KB/s)
MIN_FAST_CHECK_SPEED_KBPS=500  # Порог скорости при быстрой проверке (KB/s)
MAX_ACCEPTABLE_PING=3000       # Максимальный пинг по Clash API (мс)
TEST_PORT=25555                # SOCKS5-порт временного тестового sing-box
TEST_API_PORT=9092             # Clash API-порт временного тестового sing-box

FILTER_COUNTRIES="nl de us pl fi"
PRIORITY_PROTOCOLS="shadowsocks hysteria2 vless hysteria trojan vmess"
```

### 📊 Матрица приоритетов

Две переменные определяют **порядок тестирования** тысяч нод:

#### `ENCRYPTION_PRIORITY` — что делать с незащищёнными нодами

| Значение | Режим | Поведение |
|:---:|---|---|
| `1` | **Стандартный** | Все протоколы в очередь без фильтрации |
| `2` | **Параноидальный** *(по умолчанию)* | VLESS без `tls.enabled=true` и SS с `method=none` — вырезаются из очереди немедленно |
| `3` | **Гибридный** | «Голые» ноды остаются, но сдвигаются в конец очереди после всех зашифрованных |

#### `SORT_PRIORITY` — как выстраивать очередь тестирования

| Значение | Логика | Идеально для |
|:---:|---|---|
| `0` | **ПРОТОКОЛ → СТРАНА** | Сначала все SS из NL, DE, US, PL, FI → затем VLESS из NL, DE, US... | Слабых роутеров: SS легче шифруется, экономит CPU |
| `1` | **СТРАНА → ПРОТОКОЛ** | Сначала ВСЕ протоколы из NL → если мало, переход в DE | Геймеров и стримеров: минимальный пинг к конкретной стране |

**Наглядно — режим `SORT=0, ENC=2` (дефолт):**
```
[1] SS AEAD из NL → [2] SS AEAD из DE → ... → [5] SS AEAD из FI
[6] HY2 из NL    → [7] HY2 из DE    → ... → [10] VMess из FI
[11] Fallback: все зашифрованные из остальных стран
```

**Режим `SORT=1, ENC=3`:**
```
[1] SS AEAD из NL → [2] HY2 из NL → [3] VLESS+TLS из NL → [4] SS none из NL (fallback)
[5] SS AEAD из DE → [6] HY2 из DE → ...
```

### Подписки (`SUBS_LIST`)

По умолчанию подключены 10 агрегаторов с GitHub, суммарная база — 60 000+ нод:

```
sakha1370/OpenRay          · ebrasha/free-v2ray-public-list  · V2RayRoot/V2RayConfig
acymz/AutoVPN              · roosterkid/openproxylist         · amirkma/proxykma
mahdibland/V2RayAggregator · gongchandang49/TelegramV2rayCollector
SoliSpirit/v2ray-configs   · LonUp/NodeList
```

Добавить собственные — достаточно вписать URL в `SUBS_LIST`. Поддерживаются прямые URI и Base64-encoded подписки.

---

## 🗂️ Структура репозитория

```
singbox-padavan-easy-crawler-2/
├── install.sh               ← Одноcтрочный установщик
│
├── scripts/
│   ├── update.sh            ← Основной движок (главный файл проекта)
│   ├── gen_links2.sh        ← Генератор клиентских ссылок
│   ├── converter.lua        ← Парсер URI → Sing-Box JSON
│   └── utils.lua            ← Хелперы для конвертера
│
└── templates/
    └── conf3_final.json     ← Эталонный шаблон конфига (инбаунды + роутинг)
```

**На роутере после установки:**
```
$WORKDIR/
├── sing-box           ← Бинарник ядра (из Releases)
├── update.sh          ← Основной скрипт
├── gen_links.sh      ← Генератор ссылок
├── converter.lua      ← Lua-парсер
├── utils.lua
├── conf3_final.json   ← Шаблон (не трогать вручную)
└── conf2_final.json   ← Рабочий конфиг (перезаписывается update.sh)
```

---

## 🔧 Устранение неполадок

**`converter.lua crashed or failed to compile all_nodes.json`**
→ `converter.lua` или `utils.lua` отсутствуют в `$WORKDIR`. Если запускаете из другой папки — скрипт копирует их автоматически, но только если они лежат рядом с `update.sh`.

**`All subscription links returned empty or corrupt data`**
→ Роутер не может достучаться до GitHub. Проверьте DNS (`nslookup raw.githubusercontent.com`). Если сам `sing-box` блокирует трафик — временно остановите его и повторите.

**Все ноды: 0 KB/s при быстрой проверке**
→ `check_provider` не нашёл рабочий URL (`speed.cloudflare.com` или `cachefly.cachefly.net`). Убедитесь, что они доступны с роутера без прокси: `curl -Is https://speed.cloudflare.com/__down?bytes=1`.

**`grep: unknown option` или битый вывод**
→ Встроенный `grep` Padavan не поддерживает `-E` с некоторыми паттернами. Установите GNU grep из Entware: `opkg install grep`.

**Скрипт завис и не завершается**
→ Зависший временный `sing-box`. Выполните: `killall sing-box` или убейте процессы на портах 25555/9092.

**Конфиг применился, но интернет не работает**
→ `conf3_final.json` не содержит корректных инбаундов или роутинга. Проверьте шаблон командой: `./sing-box check -c conf3_final.json`.

---

## ⚠️ Отказ от ответственности

Скрипт предоставлен **«как есть»** исключительно в образовательных и исследовательских целях.

- Автор не несёт ответственности за стабильность и безопасность публичных прокси-баз.
- Бесплатные прокси из открытых репозиториев **могут логировать ваш трафик** — не передавайте через них чувствительные данные.
- Используйте `ENCRYPTION_PRIORITY=2` (режим по умолчанию) для минимизации рисков.

---

<div align="center">

Сделано с любовью к свободной маршрутизации и старым добрым MIPS-роутерам ❤️

*Если проект оказался полезным — поставьте ⭐ на GitHub*

</div>
