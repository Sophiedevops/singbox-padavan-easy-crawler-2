🌐 Sing-Box · Padavan · Smart Crawler v2
https://img.shields.io/badge/Shell-POSIX__sh-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white
https://img.shields.io/badge/Padavan-MIPSLE-007ACC?style=for-the-badge&logo=openwrt&logoColor=white
https://img.shields.io/badge/Sing--Box-1.12.12--Extended-blueviolet?style=for-the-badge
https://img.shields.io/badge/Status-Stable-brightgreen?style=for-the-badge
https://img.shields.io/badge/License-MIT-orange?style=for-the-badge

🇷🇺 [Русский](#-русский) · 🇬🇧 [English](#-english) · 🇮🇷 [فارسی](#-فارسی) · 🇨🇳 [中文](#-中文)

---

# 🇷🇺 Русский

Автоматический поиск, тест и прямое управление живым процессом Sing-Box на слабом MIPS-роутере
*( протестировано на MiWiFi 3 | Xiaomi Mi-router 3 )*

Единственный скрипт, который переварит базу из 60 000+ прокси-нод
на роутере с 32 МБ свободной ОЗУ — без зависания, без OOM, без перегрева.

## 🆕 Архитектура и ключевые изменения `update.sh`
* **Динамическое распределение памяти**: Скрипт сам считает свободную RAM. Если >150 МБ — работает в `tmpfs` (молниеносно). Если меньше — переключается на диск, чтобы избежать OOM-killer.
* **Реальный спидтест в Fast-Check**: Умная быстрая проверка теперь не просто пингует ноды, а скачивает тестовый файл через локальный SOCKS5, отсевая медленные каналы на лету.
* **Потоковая матрица сортировки (Stream Appending)**: Глобальная сортировка 5500 нод теперь идет через потоковое добавление в `jq` (`-c '.[]' >> stream.json`), что полностью исключает зависание парсера на больших массивах.
* **Provider Auto-Pilot**: Автоматический перебор CDN (Cloudflare/CacheFly) и Ping-эндпоинтов (Apple/MS/MIUI) до нахождения живого.
* **Абсолютная защита от зомби**: `trap` на сигналы `INT/TERM` + сканирование `/proc/*/cmdline` гарантированно убивает зависшие тестовые инстансы `sing-box`.

## 🔄 Как устроен пайплайн (порядок работы)
[#-как-устроен-пайплайн-порядок-работы](#-как-устроен-пайплайн-порядок-работы)

1. **Smart Fast-Check (Умная быстрая проверка)**. Если `conf2_final.json` уже существует, скрипт извлекает из него текущие ноды, поднимает тестовый `sing-box` и проверяет их. Сначала пинг через Clash API, затем **реальный спидтест** через SOCKS5. Если ≥70% от `WANTED` нод (например, 7 из 10) выдают скорость выше `MIN_FAST_CHECK_SPEED_KBPS` (600 KB/s) — тяжёлый пайплайн пропускается, основной процесс перезапускается, скрипт завершает работу.
2. **Скачивание и авто-декодирование**. Последовательно опрашиваются 8 источников. Если контент не содержит явных URI (`ss://`, `vless://` и т.д.), он прогоняется через встроенный Lua-декодер Base64. Мусорные байты (`\0`, `\r`) вычищаются автоматически.
3. **Алмазный экстрактор + защита ОЗУ**. Все ссылки делятся на 4 «корзины» по приоритету: VIP-SS (лимит 2500), VIP-остальные (2000), обычный-SS (500), обычные-остальные (500). Каждая урезается через `awk`-сэмплирование, затем единым проходом конвертируются в JSON через `converter.lua`.
4. **Глобальная матрица сортировки (Потоковая)**. Ноды раскладываются по приоритету согласно `ENCRYPTION_PRIORITY` и `SORT_PRIORITY`. Используется потоковое добавление чанков через `jq` в общий файл, чтобы не держать огромный массив в памяти. В конце добавляется fallback-блок для стран вне `FILTER_COUNTRIES`.
5. **Цикл сканирования батчами по 3 ноды**. Для каждой партии поднимается тестовый `sing-box`. Пинг проверяется через Clash API. Для прошедших пинг запускается **реальный спидтест** через локальный SOCKS5. Найденные ноды (скорость ≥ `PERFECT_SPEED_KBPS`, по умолчанию 900 KB/s) копятся в результат, пока не наберётся `WANTED` штук.
6. **Сборка и горячее переключение**. Из лучших нод (отсортированных по скорости) собирается `Best-Auto` (urltest-селектор). Результат мёрджится в шаблон `conf3_final.json` и записывается в `conf2_final.json`. Live-процесс останавливается и поднимается заново (простой ~1 секунда).

## ✨ Возможности
[#-возможности](#-возможности)

| 🛡️ Anti-OOM & Динамическая память | Автоматический выбор `tmpfs` (если >150 МБ ОЗУ) или диска. Взвешенное сэмплирование через `awk` — не более ~5500 записей одновременно в памяти. <br> ⚡ **Smart Fast-Check с реальным тестом** Порог удержания = 70% от `WANTED`. Проверяется не только пинг, но и реальная скорость загрузки (SOCKS5 + curl). <br> 🔒 **Параноидальный режим** VLESS без TLS и SS без шифрования вырезаются на этапе сортировки; в режиме `2` фильтр действует даже на fallback-группу. <br> 🧩 **Чистый Lua Base64-декодер** Подписки декодируются прямо внутри `update.sh`, без внешних бинарников `openssl`/`base64`. |
| :--- | :--- |
| 🗺️ **Матрица приоритетов** | 18 стран × 6 протоколов. Два режима: Протокол→Страна или Страна→Протокол. Потоковая обработка через `jq` для экономии RAM. |
| 🛰️ **Provider Auto-Pilot** | Сам выбирает живой CDN для спид-теста (Cloudflare / CacheFly) и живой пинг-эндпоинт (Cloudflare / Apple / Microsoft / MIUI). |
| 🔄 **Live-Process Supervisor** | `update.sh` сам запускает и перезапускает основной процесс `sing-box` по PID-файлу; горячая пересборка занимает ~1 секунду. |
| 🧟 **Anti-Zombie защита** | `trap` на `INT/TERM` + `kill_testers()` гарантированно убивают тестовые процессы по `/proc/*/cmdline`, даже при ручном прерывании. |

## 📦 Состав проекта
[#-состав-проекта](#-состав-проекта)

| Файл | Назначение |
| :--- | :--- |
| `./update.sh` | 🔧 **Главный движок** — 6-стадийный пайплайн + встроенный supervisor живого процесса |
| `./gen_links.sh` | 🔗 **Генератор ссылок** — готовые URI для клиентов в локальной сети |
| `converter.lua` | ⚙️ **Парсер URI** — конвертирует `ss://`, `vless://` и др. в формат Sing-Box |
| `utils.lua` | 🛠️ Вспомогательные функции для конвертера |
| `conf3_final.json` | 📋 **Шаблон (база)** — никогда не меняется напрямую, используется как цель мёрджа |
| `conf2_final.json` | ⚡ **Активный конфиг** — перезаписывается скриптом на каждом запуске; именно его исполняет live-процесс |

💡 Если `update.sh` запущен не из `WORKDIR`, он сам скопирует туда `converter.lua` и `utils.lua` из текущей папки.
💡 `update.sh` сам поднимает и пересоздаёт live-процесс sing-box по PID-файлу (`/var/run/sb_update_main.pid`). Автозапуск при перезагрузке роутера по-прежнему обеспечивает ваш init-скрипт/cron.

## 🚀 Быстрый старт
[#-быстрый-старт](#-быстрый-старт)

**Вариант А — однострочный установщик:**
```bash
wget -O- https://raw.githubusercontent.com/Sophiedevops/singbox-padavan-easy-crawler-2/main/install.sh | sh
ssh admin@192.168.1.1
cd /opt/tmp_sb_ext/sing-box-1.12.12-extended-1.5.1-linux-mipsle

RAW="https://raw.githubusercontent.com/Sophiedevops/singbox-padavan-easy-crawler-2/main"
wget -O update.sh        "$RAW/scripts/update.sh"
wget -O gen_links.sh     "$RAW/scripts/gen_links.sh"
wget -O converter.lua    "$RAW/scripts/converter.lua"
wget -O utils.lua        "$RAW/scripts/utils.lua"
wget -O conf3_final.json "$RAW/templates/conf3_final.json"

chmod +x update.sh gen_links.sh && ./update.sh
conf2_final.json (активный конфиг) создавать вручную не нужно — он автоматически появится после первого успешного прогона пайплайна.
💡 Cron — автообновление каждые 3 дня в 03:00:
bash
1
⚙️ Настройки
#️-настройки
bash
12345678
Дополнительно (обычно менять не нужно): TEST_PORT=25555 — локальный SOCKS5 для тестов, TEST_API_PORT=9092 — порт Clash API тестового инстанса.
🔒 Режим шифрования (ENCRYPTION_PRIORITY)
Значение
Режим
Описание
1
Стандартный
Все протоколы без фильтрации, открытые SS/«голый» VLESS допускаются в общем порядке
2
Параноидальный ⭐
VLESS без TLS и SS без шифрования удаляются сразу — в том числе из fallback-группы
3
Гибридный
«Голые» ноды не выбрасываются, а уходят в самый конец очереди приоритета
🗺️ Режим сортировки (SORT_PRIORITY)
Значение
Логика
Для кого
0
Протокол → Страна
Слабые роутеры: SS легче шифруется, щадит CPU
1
Страна → Протокол
Геймеры: минимальный пинг к нужной стране
Пример SORT=0, ENC=2:
① SS+AEAD из NL → DE → US → … → KR ④ HY2/VLESS+TLS/Hysteria/Trojan/VMess из NL → DE → … ⑦ Fallback (весь мир, тоже без открытых нод)
📡 Источники подписок (8 агрегаторов, 60 000+ нод)
#
Источник
Протоколы
1
sub.whitedns.one (Base64)
Mix
2
sakha1370/OpenRay
Mix
3
SoliSpirit/v2ray-configs
SS
4
ebrasha/free-v2ray-public-list
Mix
5
V2RayRoot/V2RayConfig
VLESS
6
amirkma/proxykma
Mix
7
mahdibland/V2RayAggregator
Mix
8
gongchandang49/TelegramV2rayCollector
Mix
⚠️ При добавлении своих ссылок всегда используйте Raw-ссылки (raw.githubusercontent.com), а не страницы GitHub.
🔗 Клиентские ссылки
#-клиентские-ссылки
gen_links.sh автоматически определяет IP роутера и генерирует URI для всех инбаундов.
bash
1
SOCKS5 — рекомендуется для большинства устройств. Полноценно маршрутизирует TCP и UDP.
HTTP/Mixed — резервный вариант для старых Smart TV. Только TCP.
Совместимо с v2rayNG · NekoBox · Hiddify · Sing-Box Mobile · Karing
📋 Требования
#-требования
Компонент
Что нужно
🔧 Прошивка
Padavan (Asus Merlin-based)
💾 Хранилище
USB-накопитель с Entware в /opt/
📦 Пакеты
curl wget jq lua bash coreutils-sort grep
⚙️ Бинарник
sing-box linux-mipsle-softfloat или hardfloat
📄 Конфиги
conf3_final.json (шаблон) — conf2_final.json создаётся автоматически
💡 openssl-util больше не требуется — Base64-декодирование реализовано на чистом Lua.
🔧 FAQ — частые проблемы
Ошибка
Решение
converter.lua crashed
Проверьте наличие converter.lua и utils.lua рядом со скриптом
All subscription links returned empty
Проверьте DNS: nslookup raw.githubusercontent.com
Failed to connect to Speed Test CDNs
Оба CDN (Cloudflare и CacheFly) недоступны — проверьте интернет
Все ноды 0 KB/s
curl -Is https://speed.cloudflare.com/__down?bytes=1 — должен вернуть 200 OK
grep: unknown option
opkg install grep
Скрипт завис / live-процесс не перезапускается
killall sing-box && rm -f /var/run/sb_update_main.pid
⚠️ Отказ от ответственности
Скрипт предоставляется «как есть» в образовательных целях. Публичные прокси могут логировать трафик — не передавайте через них чувствительные данные. Используйте ENCRYPTION_PRIORITY=2.
🇬🇧 English
Automated proxy search, testing and direct live-process management for Sing-Box on low-end MIPS routers
( tested on MiWiFi 3 | Xiaomi Mi-router 3 )
The only script capable of processing 60,000+ proxy nodes
on a router with just 32 MB of free RAM — no freezes, no OOM, no overheating.
🆕 Architecture & Key update.sh Features
Dynamic Memory Allocation: The script checks free RAM. If >150MB — uses tmpfs (blazing fast). If less — switches to disk storage to prevent OOM-killer.
Real Speed Test in Fast-Check: Smart Fast-Check doesn't just ping nodes; it downloads a test file via local SOCKS5, filtering out slow channels on the fly.
Stream Appending Sorting Matrix: Global sorting of 5500 nodes now uses stream appending via jq (-c '.[]' >> stream.json), completely eliminating parser hangs on large arrays.
Provider Auto-Pilot: Automatically iterates through CDNs (Cloudflare/CacheFly) and Ping endpoints (Apple/MS/MIUI) until a live one is found.
Absolute Zombie Protection: trap on INT/TERM signals + /proc/*/cmdline scanning guarantees that stuck sing-box test instances are killed.
🔄 How the pipeline works (execution order)
#-how-the-pipeline-works-execution-order
Smart Fast-Check. If conf2_final.json exists, the script extracts current nodes, starts a test sing-box, and checks them. First ping via Clash API, then a real speed test via SOCKS5. If ≥70% of WANTED nodes (e.g., 7 out of 10) yield speed above MIN_FAST_CHECK_SPEED_KBPS (600 KB/s) — the heavy pipeline is skipped, the main process is restarted, and the script exits.
Download & Auto-Decoding. 8 sources are fetched sequentially. If content lacks explicit URIs (ss://, vless://, etc.), it's piped through the embedded Lua Base64 decoder. Junk bytes (\0, \r) are stripped automatically.
Diamond Extractor + RAM Protection. Links are split into 4 priority buckets: VIP-SS (cap 2500), VIP-others (2000), regular-SS (500), regular-others (500). Each is capped via awk sampling, then converted to JSON in one pass via converter.lua.
Global Sorting Matrix (Streaming). Nodes are arranged by priority according to ENCRYPTION_PRIORITY and SORT_PRIORITY. Uses stream appending of chunks via jq to save RAM. A fallback block for countries outside FILTER_COUNTRIES is added at the end.
Scanning Loop (Batches of 3). For each batch, a test sing-box is started. Ping is checked via Clash API. Passing nodes get a real speed test via local SOCKS5. Nodes meeting PERFECT_SPEED_KBPS (default 900 KB/s) are kept until WANTED is reached.
Assembly & Hot-Swap. The best nodes (sorted by speed) are wrapped into a Best-Auto urltest selector. Merged into conf3_final.json template and written to conf2_final.json. The live process is stopped and restarted (~1 second downtime).
✨ Features
#-features
🛡️ Anti-OOM & Dynamic Memory
Auto-choice between tmpfs (if >150MB RAM free) and disk. Weighted awk sampling — never more than ~5,500 records in memory.
⚡ Smart Fast-Check with Real Test Retention threshold = 70% of WANTED. Checks not only ping but real download speed (SOCKS5 + curl).
🔒 Paranoid Encryption Mode VLESS without TLS and unencrypted SS are dropped during sorting; mode 2 also filters the fallback group.
🧩 Pure-Lua Base64 Decoder Subscriptions are decoded right inside update.sh, no external openssl/base64 binary needed.
🗺️ Priority Matrix
18 countries × 6 protocols. Two modes: Protocol→Country or Country→Protocol. Stream processing via jq to save RAM.
🛰️ Provider Auto-Pilot
Automatically selects a live speed-test CDN (Cloudflare / CacheFly) and a live ping endpoint (Cloudflare / Apple / Microsoft / MIUI).
🔄 Live-Process Supervisor
update.sh itself starts and restarts the main sing-box process via a PID file; hot reload takes ~1 second.
🧟 Anti-Zombie Protection
trap on INT/TERM + kill_testers() reliably kill leftover test processes by scanning /proc/*/cmdline, even on manual interruption.
📦 Project Structure
#-project-structure
File
Purpose
./update.sh
🔧 Main engine — 6-stage pipeline + built-in live-process supervisor
./gen_links.sh
🔗 Link generator — ready-to-use URIs for LAN clients
converter.lua
⚙️ URI parser — converts ss://, vless:// etc. to Sing-Box format
utils.lua
🛠️ Helper functions for the converter
conf3_final.json
📋 Template (base) — never edited directly, used as the merge target
conf2_final.json
⚡ Active config — overwritten by the script on every run; executed by the live process
💡 If update.sh is run from outside WORKDIR, it auto-copies converter.lua and utils.lua.
💡 update.sh manages the live sing-box process via PID file (/var/run/sb_update_main.pid). Boot-time autostart is handled by your init script/cron.
🚀 Quick Start
#-quick-start
Option A — one-liner installer:
bash
1
Option B — manual installation
bash
1234567891011
💡 Cron — auto-update every 3 days at 03:00:
bash
1
⚙️ Configuration
#️-configuration
bash
12345678
Advanced: TEST_PORT=25555 — local SOCKS5 for testing, TEST_API_PORT=9092 — Clash API port.
🔒 Encryption Mode (ENCRYPTION_PRIORITY)
Value
Mode
Description
1
Standard
All protocols, no filtering — open SS and bare VLESS stay in normal order
2
Paranoid ⭐
VLESS without TLS and unencrypted SS are dropped immediately — including fallback
3
Hybrid
Unencrypted nodes aren't discarded, just pushed to the very end of the queue
🗺️ Sort Mode (SORT_PRIORITY)
Value
Logic
Best for
0
Protocol → Country
Weak routers: SS is lighter to encrypt, saves CPU
1
Country → Protocol
Gamers: guarantees lowest ping to a specific country
📡 Subscription Sources (8 aggregators, 60,000+ nodes)
(Same as Russian section)
🔗 Client Links
#-client-links
(Same as Russian section)
📋 Requirements
#-requirements
(Same as Russian section)
🔧 FAQ — Common Issues
(Same as Russian section)
⚠️ Disclaimer
This script is provided "as is" for educational purposes only. Public proxies may log your traffic. Use ENCRYPTION_PRIORITY=2.
🇮🇷 فارسی
جستجو، آزمایش و مدیریت مستقیم پروسس زنده Sing-Box روی روتر ضعیف MIPS
( تست شده روی MiWiFi 3 | Xiaomi Mi-router 3 )
تنها اسکریپتی که می‌تواند پایگاه داده ۶۰٬۰۰۰+ نود پروکسی را
روی روتری با ۳۲ مگابایت RAM آزاد بدون هنگ‌کردن، OOM یا داغ‌شدن پردازنده هضم کند.
🆕 معماری و تغییرات کلیدی update.sh
تخصیص پویای حافظه: اسکریپت RAM آزاد را بررسی می‌کند. اگر >150MB — از tmpfs استفاده می‌کند. در غیر این صورت برای جلوگیری از OOM به دیسک سوئیچ می‌کند.
تست سرعت واقعی در Fast-Check: بررسی هوشمند فقط پینگ نمی‌کند، بلکه یک فایل تست را از طریق SOCKS5 محلی دانلود می‌کند تا کانال‌های کند را حذف کند.
مرتب‌سازی جریانی (Stream Appending): مرتب‌سازی 5500 نود اکنون از طریق jq انجام می‌شود که از هنگ کردن پارسر روی آرایه‌های بزرگ جلوگیری می‌کند.
Provider Auto-Pilot: به طور خودکار CDNها و اندپوینت‌های پینگ را تا پیدا کردن یک مورد فعال بررسی می‌کند.
محافظت مطلق در برابر زامبی: trap روی سیگنال‌ها + اسکن /proc/*/cmdline اینستنس‌های گیر کرده را می‌کشد.
🔄 نحوه کارکرد پایپ‌لاین (ترتیب اجرا)
#-نحوه-کارکرد-پایپ‌لاین-ترتیب-اجرا
Smart Fast-Check. اگر conf2_final.json وجود داشته باشد، نودهای فعلی استخراج و تست می‌شوند. ابتدا پینگ از طریق Clash API، سپس تست سرعت واقعی از طریق SOCKS5. اگر ≥70% نودها سرعت بالای MIN_FAST_CHECK_SPEED_KBPS (600 KB/s) داشته باشند، پایپ‌لاین سنگین رد شده و اسکریپت خارج می‌شود.
دانلود و رمزگشایی خودکار. ۸ منبع دریافت می‌شوند. در صورت نیاز، محتوا از رمزگشای Base64 Lua عبور می‌کند.
استخراج‌کننده الماس + محافظت RAM. لینک‌ها به ۴ دسته تقسیم می‌شوند: VIP-SS (2500)، VIP-others (2000)، SS معمولی (500)، سایر (500). هر دسته با awk محدود شده و به JSON تبدیل می‌شود.
ماتریس مرتب‌سازی سراسری (جریانی). نودها بر اساس ENCRYPTION_PRIORITY و SORT_PRIORITY مرتب می‌شوند. از پردازش جریانی jq برای ذخیره RAM استفاده می‌شود.
چرخه اسکن (دسته‌های 3 تایی). برای هر دسته یک sing-box تست اجرا می‌شود. پینگ بررسی شده و سپس تست سرعت واقعی انجام می‌شود. نودهای با سرعت ≥ PERFECT_SPEED_KBPS (900 KB/s) ذخیره می‌شوند تا به WANTED برسند.
مونتاژ و جابه‌جایی گرم. بهترین نودها در Best-Auto قرار گرفته و در conf2_final.json نوشته می‌شوند. پروسس زنده با ~1 ثانیه توقف ری‌استارت می‌شود.
✨ قابلیت‌ها
#-قابلیت‌ها
🛡️ Anti-OOM و حافظه پویا
انتخاب خودکار tmpfs یا دیسک. نمونه‌گیری وزن‌دار — حداکثر ~5500 رکورد.
⚡ Smart Fast-Check با تست واقعی آستانه 70%. بررسی پینگ و سرعت دانلود واقعی (SOCKS5).
🔒 حالت پارانوئید حذف VLESS بدون TLS و SS بدون رمزنگاری.
🧩 رمزگشای Base64 با Lua خالص بدون نیاز به openssl.
🗺️ ماتریس اولویت
18 کشور × 6 پروتکل. پردازش جریانی برای ذخیره RAM.
🛰️ Provider Auto-Pilot
انتخاب خودکار CDN و نقطه پینگ فعال.
🔄 Live-Process Supervisor
مدیریت پروسس اصلی از طریق فایل PID؛ ری‌استارت ~1 ثانیه.
🧟 محافظت Anti-Zombie
پاکسازی پروسس‌های زامبی از طریق /proc.
(بخش‌های نصب، ساختار، لینک‌ها، نیازمندی‌ها و FAQ مشابه نسخه انگلیسی هستند)
🇨🇳 中文
在低配 MIPS 路由器上自动搜索、测试代理并直接管理 Sing-Box 的常驻进程
( 已在 MiWiFi 3 | Xiaomi Mi-router 3 上测试 )
唯一能在仅 32 MB 可用内存的路由器上
处理 60,000+ 代理节点数据库的脚本 — 不卡顿、不 OOM、不过热。
🆕 架构与 update.sh 核心特性
动态内存分配：脚本自动检测空闲 RAM。若 >150MB，则使用 tmpfs（极速）；若不足，则切换至磁盘存储以防 OOM-killer。
Fast-Check 真实测速：智能快速检查不仅测 Ping，还会通过本地 SOCKS5 下载测试文件，实时剔除慢速节点。
流式排序矩阵 (Stream Appending)：5500 个节点的全局排序现在通过 jq 流式追加实现，彻底杜绝大数组导致的解析器卡死。
Provider Auto-Pilot：自动遍历 CDN (Cloudflare/CacheFly) 和 Ping 端点 (Apple/MS/MIUI)，直到找到可用节点。
绝对僵尸进程防护：捕获 INT/TERM 信号 + 扫描 /proc/*/cmdline，保证卡死的测试实例被彻底清理。
🔄 流水线如何运作（执行顺序）
#-流水线如何运作执行顺序
Smart Fast-Check (智能快速检查)。若 conf2_final.json 存在，提取现有节点并启动测试实例。先通过 Clash API 测 Ping，再进行 SOCKS5 真实测速。若 ≥70% 的 WANTED 节点速度超过 MIN_FAST_CHECK_SPEED_KBPS (600 KB/s) — 跳过重型流水线，重启主进程并退出。
下载与自动解码。依次拉取 8 个订阅源。若无明文 URI，则通过内置 Lua Base64 解码器处理，自动清除垃圾字节。
钻石提取器 + RAM 保护。链接分为 4 个优先级桶：VIP-SS (限 2500)、VIP-其他 (2000)、普通-SS (500)、普通-其他 (500)。通过 awk 采样限流后，一次性经 converter.lua 转为 JSON。
全局排序矩阵 (流式)。根据 ENCRYPTION_PRIORITY 和 SORT_PRIORITY 排序。使用 jq 流式追加分块数据以节省内存。最后追加不在 FILTER_COUNTRIES 中的 Fallback 组。
以 3 个节点为一批的扫描循环。每批启动测试实例，Clash API 测 Ping 后，进行 SOCKS5 真实测速。速度 ≥ PERFECT_SPEED_KBPS (默认 900 KB/s) 的节点被保留，直至凑满 WANTED 个。
组装与热切换。将最优节点（按速度排序）打包为 Best-Auto urltest 选择器。合并进模板生成 conf2_final.json。停止并重启常驻进程（停机约 1 秒）。
✨ 功能特性
#-功能特性
🛡️ Anti-OOM 与动态内存
自动选择 tmpfs 或磁盘。加权 awk 采样 — 内存中同时不超过 ~5500 条记录。
⚡ 带真实测试的 Smart Fast-Check 保留阈值 = 70%。不仅测 Ping，还测真实下载速度 (SOCKS5 + curl)。
🔒 偏执加密模式 排序阶段剔除无 TLS 的 VLESS 与未加密 SS；模式 2 连 fallback 也会过滤。
🧩 纯 Lua Base64 解码器 直接在 update.sh 内解码，无需外部 openssl。
🗺️ 优先级矩阵
18 个国家 × 6 种协议。流式处理以节省 RAM。
🛰️ Provider Auto-Pilot
自动选择可用的测速 CDN 与 Ping 端点。
🔄 常驻进程 Supervisor
通过 PID 文件管理主进程；热重载停机仅约 1 秒。
🧟 Anti-Zombie 保护
通过扫描 /proc 可靠清理残留测试进程。
(安装、项目结构、客户端链接、环境要求、FAQ 等部分与英文版保持一致)
⚠️ 免责声明
本脚本仅供教育目的 "按原样" 提供。公共代理可能记录您的流量，请勿传输敏感数据。请使用 ENCRYPTION_PRIORITY=2。
<div align="center">

Сделано с любовью к свободной маршрутизации и старым добрым MIPS-роутерам ❤️

**Если проект оказался полезным — поставьте ⭐**

</div>
