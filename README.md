# singbox-padavan-easy-crawler-2

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

[![Shell Script](https://img.shields.io/badge/Language-Shell_Script-4EAA25?style=for-the-badge&logo=gnu-bash)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Padavan_|_MIPSLE-007ACC?style=for-the-badge&logo=openwrt)](https://github.com/RMerl/asuswrt-merlin)
[![Core](https://img.shields.io/badge/Core-Sing--Box_1.12-blueviolet?style=for-the-badge)](https://sing-box.sagernet.org/)
[![Status](https://img.shields.io/badge/Status-Stable_v2-success?style=for-the-badge)]()
[![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)]()

*Автоматический поиск, разбор, тестирование и ротация бесплатных прокси прямо на слабом MIPS-роутере — без OOM и без перегрева.*

</div>

---

## 🧩 Что это такое?

Этот проект решает конкретную проблему: как поддерживать **актуальный пул рабочих прокси** (Shadowsocks, VLESS, VMess, Trojan, Hysteria2) на роутере с **дефицитом ОЗУ и слабым процессором MIPSLE**, не убивая его при обработке баз в 60 000+ нод.

Система состоит из двух скриптов:

| Файл | Назначение |
|---|---|
| `update.sh` | Основной движок: скачивает подписки → сэмплирует → парсит через Lua → тестирует батчами → применяет горячий перезапуск |
| `gen_links2.sh` | Генератор клиентских ссылок: читает итоговый конфиг и выдаёт готовые `ss://`, `socks5://`, `hy2://` и т.д. для смартфонов |

---

## 🏗️ Архитектура пайплайна (`update.sh`)

```
┌─────────────────────────────────────────────────────────────────────┐
│                         update.sh pipeline                          │
│                                                                     │
│  ① Быстрая проверка    ② Скачивание       ③ Пре-фильтрация         │
│  существующих нод  →   10 подписок     →  Anti-OOM сэмплинг        │
│  (если живы 70% →      Base64-декод       (SS: до 3500 нод,        │
│   досрочный выход)     очистка \0 \r      другие: до 1000 нод)     │
│          │                   │                      │               │
│          ▼                   ▼                      ▼               │
│  ④ Lua-конвертер      ⑤ Матрица           ⑥ Батч-тестирование      │
│  (парсинг URI   →     приоритетов      →  по 3 ноды, Sing-Box      │
│   → all_nodes.json)   (протокол×страна)   + Clash API + curl       │
│                                                     │               │
│                              ┌──────────────────────┘               │
│                              ▼                                      │
│                    ⑦ Горячее переключение                           │
│                    (сортировка по скорости →                        │
│                     топ-N нод → merge с base-конфигом →            │
│                     stop/start main sing-box)                       │
└─────────────────────────────────────────────────────────────────────┘
```

### Ключевые технические решения

**① Smart Fast-Check** — перед полным сканом скрипт проверяет ноды из текущего конфига. Если ≥70% держат скорость выше `MIN_FAST_CHECK_SPEED_KBPS` — полный пайплайн отменяется. Экономится ресурс флешки и процессора.

**③ Anti-OOM Uniform Sampling** — при базе >1500 Shadowsocks или >1000 других нод скрипт не грузит всё в ОЗУ. Вместо этого через `awk NR % STEP == 0` вытягивается равномерная выборка ~4500 репрезентативных ссылок.

**④ Lua-конвертер** — парсит URI (`ss://`, `vless://`, `vmess://`, `trojan://`, `hysteria2://`) в структурированный JSON-массив `all_nodes.json`, пригодный для Sing-Box.

**⑤ Приоритетная матрица** — вместо наивного перебора нод строится глобальная очередь тестирования по двум осям: шифрование и география. Порядок зависит от `ENCRYPTION_PRIORITY` × `SORT_PRIORITY`.

**⑥ Батч-тестирование** — поднимается временный экземпляр `sing-box` с 3 нодами + Clash API. Через него делается реальная загрузка файла с `speed.cloudflare.com`. Нода принимается только при скорости ≥ `PERFECT_SPEED_KBPS`.

**⑦ Zero-Downtime Hot Reload** — новый конфиг мёрджится с базовым шаблоном `conf3_final.json` через `jq`, затем основной процесс `sing-box` перезапускается без обрыва текущих соединений.

---

## ✨ Ключевые особенности

### 🛡️ Anti-OOM Защита
Роутер не падает под нагрузкой. Uniform sampling через `awk` позволяет обрабатывать базы в 60 000+ нод, не превышая допустимый потребления ОЗУ.

### 🔒 Параноидальный режим шифрования
Автоматически вырезает из очереди:
- VLESS без `tls.enabled: true`
- Shadowsocks с `method: none`
- Устаревшие шифры (`rc4-md5` и аналоги)

Оставляет только современный AEAD-шифртекст.

### 🧩 Авто-Декодер + Санитайзер
Обрабатывает «битые» подписки: пробует прямое чтение → при неудаче пробует Base64-декодирование. Попутно зачищает нулевые байты (`\0`) и Windows-переносы (`\r`), которые ломают встроенный `grep` прошивки Padavan.

### 🗺️ Глобальная матрица приоритетов
Две независимых оси сортировки дают 6 режимов поведения (3 × 2). Вы точно контролируете, что скрипт ищет в первую очередь.

### ⚡ Параллельное батч-тестирование
Тестирование через живой трафик (не ICMP-пинг!) батчами по 3 ноды. Таймауты подобраны под "холодный старт" MIPS-архитектуры — нет ложных отказов из-за медленного init.

### 🔗 Генератор клиентских ссылок
`gen_links2.sh` автоматически определяет IP роутера (`nvram` → `ip addr` → fallback) и выдаёт готовые ссылки для всех входящих: Mixed, SOCKS5, Shadowsocks, Hysteria2, VLESS, Trojan.

---

## ⚙️ Требования

| Компонент | Подробности |
|---|---|
| Прошивка | Padavan (Asus Merlin-based) или аналог на базе Linux |
| USB-накопитель | Entware в `/opt/` — обязательно |
| Пакеты | `curl jq lua openssl-util bash coreutils-sort wget` |
| Sing-Box | Бинарник `linux-mipsle-softfloat` или `hardfloat` в `$WORKDIR` |
| Конфиг | Базовый шаблон `conf3_final.json` (инбаунды, роутинг без аутбаундов) |
| Lua | `converter.lua` + `utils.lua` в рабочей папке |

---

## 🚀 Установка

```bash
# 1. Подключитесь к роутеру по SSH
ssh admin@192.168.1.1

# 2. Перейдите в рабочую директорию Sing-Box
cd /opt/tmp_sb_ext/sing-box-1.12.12-extended-1.5.1-linux-mipsle

# 3. Скачайте скрипты
wget -O update.sh   https://raw.githubusercontent.com/YOUR_NICK/YOUR_REPO/main/update.sh
wget -O gen_links2.sh https://raw.githubusercontent.com/YOUR_NICK/YOUR_REPO/main/gen_links2.sh

# 4. Сделайте исполняемыми
chmod +x update.sh gen_links2.sh

# 5. Первый запуск
./update.sh
```

**Автозапуск через cron** (рекомендуется каждые 3 дня в 3:00 ночи):
```
0 3 */3 * * cd /opt/tmp_sb_ext/sing-box-1.12.12-extended-1.5.1-linux-mipsle && ./update.sh >> /opt/tmp/sb_update.log 2>&1
```

---

## 🎛️ Конфигурация

Все настройки — в начале файла `update.sh`.

### Основные параметры

```sh
WANTED=10                   # Сколько рабочих серверов нужно в итоговом конфиге
PERFECT_SPEED_KBPS=800      # Минимальная скорость для включения в конфиг (КБ/с)
MIN_FAST_CHECK_SPEED_KBPS=500 # Порог скорости при быстрой проверке текущего пула
MAX_ACCEPTABLE_PING=3000    # Максимальный пинг (мс) по Clash API — выше отсекается

FILTER_COUNTRIES="nl de us pl fi"                        # Приоритетные страны
PRIORITY_PROTOCOLS="shadowsocks hysteria2 vless trojan vmess" # Запасные протоколы
```

### 🔒 `ENCRYPTION_PRIORITY` — режим шифрования

| Значение | Режим | Поведение |
|:---:|---|---|
| `1` | **Стандартный** | Все протоколы без фильтрации по TLS |
| `2` | **Параноидальный** *(рекомендуется)* | VLESS без TLS и SS с `method: none` — немедленное удаление |
| `3` | **Гибридный** | «Голые» протоколы остаются, но сдвигаются в самый конец очереди |

### 🗺️ `SORT_PRIORITY` — режим сортировки

| Значение | Режим | Когда выбирать |
|:---:|---|---|
| `0` | **Протокол → Страна** | Сначала все SS из NL, DE, US…, затем VLESS из NL, DE, US… | Слабый роутер, нужно беречь CPU — SS легче для шифрования |
| `1` | **Страна → Протокол** | Сначала все протоколы из NL, только потом идём в DE | Геймеры, стримеры — нужен минимальный пинг к конкретной стране |

### Источники подписок (`SUBS_LIST`)

По умолчанию подключено 10 открытых GitHub-репозиториев с агрегированными прокси. Вы можете добавить собственные Telegram-каналы или платные подписки в формате `ss://`, `vless://`, `vmess://`, `trojan://`, `hysteria2://` или Base64-encoded.

---

## 📊 Пример вывода

```
Checking existing nodes (Strict Mode)...
  Retention Threshold set to: 7 nodes (70% of WANTED)
  Node 🇳🇱NL-SS-01: 1243 KB/s (Acceptable)
  Node 🇩🇪DE-VLESS-03: 612 KB/s (Acceptable)
  Node 🇺🇸US-HY2-02: 341 KB/s (Too slow)
  ...
  Current pool is acceptable (7/7 nodes verified). Aborting full scan pipeline...

--- OR, если пул устарел ---

Building Priority Matrix (EncMode: 2, SortMode: 0)...
  ➔ Logic: PROTOCOL -> COUNTRY
  ➔ Found 12440 Shadowsocks and 8912 other protocols globally.
  ➔ Successfully built highly-concentrated sample of 4420 nodes for parsing.

Scanning total queue of 3891 prioritized nodes...
  Batch 0-3... [DEBUG] Status Tracker Active:
    - 🇳🇱NL-SS-CHACHA: 312 ms
  [FOUND] 🇳🇱NL-SS-CHACHA : 1540 KB/s   Total Stored: 1 / 10
  ...
  [FOUND] 🇩🇪DE-HY2-TLS : 2210 KB/s    Total Stored: 10 / 10
>>> Target reached! Stopping scan.

Generating final configuration...
Hot-restarting main target service...
DONE! New config applied. Main service restarted seamlessly.
```

---

## 🔗 Генератор клиентских ссылок (`gen_links2.sh`)

Если вы хотите использовать роутер как прокси-шлюз для смартфона или ПК в локальной сети:

```bash
./gen_links2.sh
```

**Пример вывода:**
```
Detected Router LAN IP: 192.168.1.1

--- HTTP / Mixed Proxy ---
http://192.168.1.1:2080#mixed-in

--- SOCKS5 ---
socks5://192.168.1.1:1080#socks5-in

--- Shadowsocks ---
ss://Y2hhY2hhMjAtaWV0Zi1wb2x5MTMwNTpNeVBhc3M=@192.168.1.1:8388#ss-in

--- Hysteria 2 ---
hy2://MyPassword@192.168.1.1:4443?insecure=1#hy2-in

DONE! All links saved to clients.txt
```

Ссылки совместимы с **v2rayNG**, **NekoBox**, **Hiddify**, **Sing-Box (мобильный)** и любым другим клиентом, поддерживающим стандартный URI-формат.

---

## 🗂️ Структура файлов

```
$WORKDIR/
├── update.sh          # Основной скрипт обновления
├── gen_links2.sh      # Генератор клиентских ссылок
├── converter.lua      # Lua-парсер прокси-URI → sing-box JSON
├── utils.lua          # Вспомогательные функции для конвертера
├── sing-box           # Бинарник ядра (mipsle-softfloat или hardfloat)
├── conf3_final.json   # Базовый шаблон конфига (инбаунды, роутинг)
└── conf2_final.json   # Рабочий конфиг (генерируется/перезаписывается скриптом)
```

---

## 🔧 Устранение неполадок

**Скрипт завершается с ошибкой `converter.lua crashed`**
→ Проверьте, что `converter.lua` и `utils.lua` лежат в `$WORKDIR`. Скрипт копирует их автоматически, если запущен из той же папки.

**`All subscription links returned empty or corrupt data`**
→ Роутер не может достучаться до GitHub. Проверьте DNS и маршруты. Если сам `sing-box` заблокирован — запустите update.sh вручную после временного отключения фаервола.

**Все ноды показывают 0 KB/s**
→ `check_provider` не нашёл рабочий URL для тестирования. Убедитесь, что `speed.cloudflare.com` доступен с роутера напрямую (без прокси).

**`grep: unknown option` / битый вывод grep**
→ Встроенный `grep` Padavan не поддерживает `-E` с некоторыми паттернами. Убедитесь, что установлен пакет `grep` из Entware (`opkg install grep`).

---

## ⚠️ Отказ от ответственности

Скрипт предоставлен **«как есть»** исключительно в образовательных и исследовательских целях.

- Автор не несёт ответственности за стабильность публичных баз прокси-серверов.
- Бесплатные прокси из открытых репозиториев могут логировать трафик — **не передавайте через них чувствительные данные**.
- Используйте режим `ENCRYPTION_PRIORITY=2` (Параноидальный), если вам важна конфиденциальность.

---

<div align="center">

Сделано с любовью к свободной маршрутизации и старым добрым MIPS-роутерам ❤️

*Если проект оказался полезным — поставьте ⭐ на GitHub*

</div>
