<div align="center">

# 🌐 Sing-Box · Padavan · Smart Crawler v2

[![Shell](https://img.shields.io/badge/Shell-POSIX_sh-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Padavan-MIPSLE-007ACC?style=for-the-badge&logo=openwrt&logoColor=white)](https://github.com/RMerl/asuswrt-merlin)
[![Core](https://img.shields.io/badge/Sing--Box-1.12_Extended-blueviolet?style=for-the-badge)](https://sing-box.sagernet.org/)
[![Status](https://img.shields.io/badge/Status-Stable-brightgreen?style=for-the-badge)]()
[![License](https://img.shields.io/badge/License-MIT-orange?style=for-the-badge)]()

<br>

**🇷🇺 [Русский](#-русский) · 🇬🇧 [English](#-english) · 🇮🇷 [فارسی](#-فارسی) · 🇨🇳 [中文](#-中文)**

</div>

---

<!-- ============================================================ -->
<!--                        🇷🇺  РУССКИЙ                          -->
<!-- ============================================================ -->

## 🇷🇺 Русский

<div align="center">

**Автоматический поиск, тест и ротация бесплатных прокси на слабом MIPS-роутере**

**( протестировано на MiWiFi 3 | Xiaomi Mi-router 3 )** 
> **Единственный скрипт**, который переварит базу из **60 000+ прокси-нод**  
> на роутере с **32 МБ свободной ОЗУ** — без зависания, без OOM, без перегрева.

</div>

### ✨ Возможности

<table>
<tr>
<td width="50%">

**🛡️ Anti-OOM защита**
Математическое сэмплирование через `awk` — роутер никогда не держит в памяти более ~4500 записей одновременно.

**⚡ Smart Fast-Check**
Перед полным сканом проверяет текущий пул. Если **70% нод живы** — пайплайн пропускается. Экономит ресурс флешки и CPU.

**🔒 Параноидальный режим**
Автоматически вырезает VLESS без TLS и SS без шифрования до тестирования. Только современный **AEAD**.

</td>
<td width="50%">

**🗺️ Матрица приоритетов**
Двумерная сортировка: по **протоколу** или по **стране**. Вы выбираете что важнее — шифр или минимальный пинг.

**🔄 Zero-Downtime Reload**
Конфиг применяется через `jq`-мёрдж + горячая замена процесса. Соединения не рвутся.

**🧩 Авто-декодер подписок**
Прозрачно обрабатывает Base64-подписки и очищает `\0`, `\r`, которые ломают `grep` на Padavan.

</td>
</tr>
</table>

### 📦 Состав проекта

| Файл | Назначение |
|:---|:---|
| `./update.sh` | 🔧 **Главный движок** — весь пайплайн от скачивания до применения |
| `./gen_links.sh` | 🔗 **Генератор ссылок** — готовые URI для клиентов в локальной сети |
| `converter.lua` | ⚙️ **Парсер URI** — конвертирует `ss://`, `vless://` и др. в формат Sing-Box |
| `utils.lua` | 🛠️ Вспомогательные функции для конвертера |
| `conf3_final.json` | 📋 **Эталонный конфиг** — шаблон с инбаундами и роутингом |

### 🚀 Быстрый старт

**Вариант А — однострочный установщик:**
```bash
wget -O- https://raw.githubusercontent.com/Sophiedevops/singbox-padavan-easy-crawler-2/main/install.sh | sh
```

<details>
<summary><b>Вариант Б — ручная установка</b></summary>

```bash
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

> **💡 Cron — автообновление каждые 3 дня в 03:00:**
> ```
> 0 3 */3 * * cd /opt/tmp_sb_ext/sing-box-1.12.12-extended-1.5.1-linux-mipsle && ./update.sh >> /opt/tmp/sb_update.log 2>&1
> ```
</details>

### ⚙️ Настройки

```bash
WANTED=10                      # Сколько рабочих нод нужно в итоговом конфиге
PERFECT_SPEED_KBPS=800         # Минимальная скорость загрузки для принятия ноды
MIN_FAST_CHECK_SPEED_KBPS=500  # Порог для быстрой проверки текущего пула
MAX_ACCEPTABLE_PING=3000       # Максимальный пинг по Clash API (мс)
FILTER_COUNTRIES="nl de us pl fi"
PRIORITY_PROTOCOLS="shadowsocks hysteria2 vless trojan vmess"
```

<details>
<summary><b>🔒 Режим шифрования (ENCRYPTION_PRIORITY)</b></summary>

| Значение | Режим | Описание |
|:---:|:---:|:---|
| `1` | **Стандартный** | Все протоколы без фильтрации |
| `2` | **Параноидальный** ⭐ | VLESS без TLS и SS без шифрования — удаляются сразу |
| `3` | **Гибридный** | «Голые» ноды уходят в конец очереди |

</details>

<details>
<summary><b>🗺️ Режим сортировки (SORT_PRIORITY)</b></summary>

| Значение | Логика | Для кого |
|:---:|:---|:---|
| `0` | **Протокол → Страна** | Слабые роутеры: SS легче шифруется, щадит CPU |
| `1` | **Страна → Протокол** | Геймеры: минимальный пинг к нужной стране |

```
Пример SORT=0, ENC=2:
① SS+AEAD из NL → DE → US …  ④ HY2 из NL → DE …  ⑦ Fallback (весь мир)
```
</details>

<details>
<summary><b>📡 Источники подписок (10 агрегаторов, 60 000+ нод)</b></summary>

| # | Репозиторий | Протоколы |
|:---:|:---|:---:|
| 1 | [`sakha1370/OpenRay`](https://raw.githubusercontent.com/sakha1370/OpenRay/refs/heads/main/output/all_valid_proxies.txt) | Mix |
| 2 | [`ebrasha/free-v2ray-public-list`](https://raw.githubusercontent.com/ebrasha/free-v2ray-public-list/refs/heads/main/all_extracted_configs.txt) | Mix |
| 3 | [`V2RayRoot/V2RayConfig`](https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/refs/heads/main/Config/vless.txt) | VLESS |
| 4 | [`acymz/AutoVPN`](https://raw.githubusercontent.com/acymz/AutoVPN/refs/heads/main/data/V2.txt) | Mix |
| 5 | [`roosterkid/openproxylist`](https://raw.githubusercontent.com/roosterkid/openproxylist/refs/heads/main/V2RAY.txt) | Mix |
| 6 | [`amirkma/proxykma`](https://raw.githubusercontent.com/amirkma/proxykma/refs/heads/main/mix.txt) | Mix |
| 7 | [`mahdibland/V2RayAggregator`](https://raw.githubusercontent.com/mahdibland/V2RayAggregator/refs/heads/master/sub/sub_merge.txt) | Mix |
| 8 | [`gongchandang49/TelegramV2rayCollector`](https://raw.githubusercontent.com/gongchandang49/TelegramV2rayCollector/refs/heads/main/sub/mix) | Mix |
| 9 | [`SoliSpirit/v2ray-configs`](https://raw.githubusercontent.com/SoliSpirit/v2ray-configs/refs/heads/main/Protocols/ss.txt) | SS |
| 10 | [`LonUp/NodeList`](https://raw.githubusercontent.com/LonUp/NodeList/main/node.txt) | Mix |

> ⚠️ При добавлении своих ссылок всегда используйте **Raw**-ссылки (`raw.githubusercontent.com`), а не страницы GitHub (`github.com/…/blob/…`) — иначе скрипт скачает HTML вместо текста.

</details>

### 🔗 Клиентские ссылки

`gen_links.sh` автоматически определяет IP роутера и генерирует URI для всех инбаундов. Если у вас статический IP или DDNS — можно подключаться и извне локальной сети.

```bash
./gen_links.sh
```

<details>
<summary><b>Пример вывода</b></summary>

```
Detected Router LAN IP: 192.168.1.1
--- SOCKS5 ---        socks5://192.168.1.1:1080#socks5-in
--- HTTP/Mixed ---    http://192.168.1.1:2080#mixed-in
--- Shadowsocks ---   ss://Y2hhY2hhM...@192.168.1.1:8388#ss-in
--- Hysteria 2 ---    hy2://MyPassword@192.168.1.1:4443?insecure=1#hy2-in
DONE! All links saved to clients.txt
```
</details>

> **SOCKS5** — рекомендуется для большинства устройств. Полноценно маршрутизирует TCP и UDP.  
> **HTTP/Mixed** — резервный вариант для старых Smart TV. Только TCP, UDP не поддерживается.

Совместимо с **v2rayNG** · **NekoBox** · **Hiddify** · **Sing-Box Mobile** · **Karing**

### 📋 Требования

| Компонент | Что нужно |
|:---|:---|
| 🔧 Прошивка | Padavan (Asus Merlin-based) |
| 💾 Хранилище | USB-накопитель с Entware в `/opt/` |
| 📦 Пакеты | `curl wget jq lua openssl-util bash coreutils-sort` |
| ⚙️ Бинарник | `sing-box linux-mipsle-softfloat` или `hardfloat` |
| 📄 Конфиг | `conf3_final.json` — шаблон с инбаундами и роутингом |

<details>
<summary><b>🔧 FAQ — частые проблемы</b></summary>

| Ошибка | Решение |
|:---|:---|
| `converter.lua crashed` | Проверьте наличие `converter.lua` и `utils.lua` в рабочей папке |
| `All subscription links returned empty` | Проверьте DNS: `nslookup raw.githubusercontent.com` |
| Все ноды 0 KB/s | `curl -Is https://speed.cloudflare.com/__down?bytes=1` — должен вернуть `200 OK` |
| `grep: unknown option` | `opkg install grep` |
| Скрипт завис | `killall sing-box` |

</details>

<details>
<summary><b>⚠️ Отказ от ответственности</b></summary>

Скрипт предоставляется **«как есть»** в образовательных целях. Публичные прокси **могут логировать трафик** — не передавайте через них чувствительные данные. Используйте `ENCRYPTION_PRIORITY=2`.

</details>

---

<!-- ============================================================ -->
<!--                        🇬🇧  ENGLISH                          -->
<!-- ============================================================ -->

## 🇬🇧 English

<div align="center">

**Automated proxy search, testing and rotation for Sing-Box on low-end MIPS routers**

**( tested on MiWiFi 3 | Xiaomi Mi-router 3 )**

> The **only script** capable of processing **60,000+ proxy nodes**  
> on a router with just **32 MB of free RAM** — no freezes, no OOM, no overheating.

</div>

### ✨ Features

<table>
<tr>
<td width="50%">

**🛡️ Anti-OOM Protection**
Mathematical uniform sampling via `awk` — the router never holds more than ~4,500 records in RAM at once.

**⚡ Smart Fast-Check**
Before a full scan, it tests the current pool. If **70% of nodes are alive** — the heavy pipeline is skipped entirely.

**🔒 Paranoid Encryption Mode**
Automatically drops VLESS without TLS and Shadowsocks without encryption before testing. Modern **AEAD** only.

</td>
<td width="50%">

**🗺️ Priority Matrix**
Two-dimensional sorting: by **protocol** or by **country**. You choose what matters more — cipher strength or lowest ping.

**🔄 Zero-Downtime Reload**
Config is applied via `jq` merge + hot process swap. Active connections are never interrupted.

**🧩 Auto-Decoder**
Transparently handles Base64 subscriptions and strips `\0`, `\r` garbage that breaks Padavan's built-in `grep`.

</td>
</tr>
</table>

### 📦 Project Structure

| File | Purpose |
|:---|:---|
| `./update.sh` | 🔧 **Main engine** — full pipeline from download to deployment |
| `./gen_links.sh` | 🔗 **Link generator** — ready-to-use URIs for LAN clients |
| `converter.lua` | ⚙️ **URI parser** — converts `ss://`, `vless://` etc. to Sing-Box format |
| `utils.lua` | 🛠️ Helper functions for the converter |
| `conf3_final.json` | 📋 **Reference config** — template with inbounds and routing |

### 🚀 Quick Start

**Option A — one-liner installer:**
```bash
wget -O- https://raw.githubusercontent.com/Sophiedevops/singbox-padavan-easy-crawler-2/main/install.sh | sh
```

<details>
<summary><b>Option B — manual installation</b></summary>

```bash
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

> **💡 Cron — auto-update every 3 days at 03:00:**
> ```
> 0 3 */3 * * cd /opt/tmp_sb_ext/sing-box-1.12.12-extended-1.5.1-linux-mipsle && ./update.sh >> /opt/tmp/sb_update.log 2>&1
> ```
</details>

### ⚙️ Configuration

```bash
WANTED=10                      # Number of working nodes in the final config
PERFECT_SPEED_KBPS=800         # Minimum download speed to accept a node
MIN_FAST_CHECK_SPEED_KBPS=500  # Speed threshold for the fast-check pass
MAX_ACCEPTABLE_PING=3000       # Max Clash API ping (ms)
FILTER_COUNTRIES="nl de us pl fi"
PRIORITY_PROTOCOLS="shadowsocks hysteria2 vless trojan vmess"
```

<details>
<summary><b>🔒 Encryption Mode (ENCRYPTION_PRIORITY)</b></summary>

| Value | Mode | Description |
|:---:|:---:|:---|
| `1` | **Standard** | All protocols, no TLS filtering |
| `2` | **Paranoid** ⭐ | VLESS without TLS and unencrypted SS are dropped immediately |
| `3` | **Hybrid** | Unencrypted nodes stay but are pushed to the very end of the queue |

</details>

<details>
<summary><b>🗺️ Sort Mode (SORT_PRIORITY)</b></summary>

| Value | Logic | Best for |
|:---:|:---|:---|
| `0` | **Protocol → Country** | Weak routers: SS is lighter to encrypt, saves CPU |
| `1` | **Country → Protocol** | Gamers: guarantees lowest ping to a specific country |

```
Example SORT=0, ENC=2:
① SS+AEAD from NL → DE → US …  ④ HY2 from NL → DE …  ⑦ Fallback (worldwide)
```
</details>

<details>
<summary><b>📡 Subscription Sources (10 aggregators, 60,000+ nodes)</b></summary>

| # | Repository | Protocols |
|:---:|:---|:---:|
| 1 | [`sakha1370/OpenRay`](https://raw.githubusercontent.com/sakha1370/OpenRay/refs/heads/main/output/all_valid_proxies.txt) | Mix |
| 2 | [`ebrasha/free-v2ray-public-list`](https://raw.githubusercontent.com/ebrasha/free-v2ray-public-list/refs/heads/main/all_extracted_configs.txt) | Mix |
| 3 | [`V2RayRoot/V2RayConfig`](https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/refs/heads/main/Config/vless.txt) | VLESS |
| 4 | [`acymz/AutoVPN`](https://raw.githubusercontent.com/acymz/AutoVPN/refs/heads/main/data/V2.txt) | Mix |
| 5 | [`roosterkid/openproxylist`](https://raw.githubusercontent.com/roosterkid/openproxylist/refs/heads/main/V2RAY.txt) | Mix |
| 6 | [`amirkma/proxykma`](https://raw.githubusercontent.com/amirkma/proxykma/refs/heads/main/mix.txt) | Mix |
| 7 | [`mahdibland/V2RayAggregator`](https://raw.githubusercontent.com/mahdibland/V2RayAggregator/refs/heads/master/sub/sub_merge.txt) | Mix |
| 8 | [`gongchandang49/TelegramV2rayCollector`](https://raw.githubusercontent.com/gongchandang49/TelegramV2rayCollector/refs/heads/main/sub/mix) | Mix |
| 9 | [`SoliSpirit/v2ray-configs`](https://raw.githubusercontent.com/SoliSpirit/v2ray-configs/refs/heads/main/Protocols/ss.txt) | SS |
| 10 | [`LonUp/NodeList`](https://raw.githubusercontent.com/LonUp/NodeList/main/node.txt) | Mix |

> ⚠️ When adding your own sources, always use **Raw** links (`raw.githubusercontent.com`), not GitHub blob pages — otherwise the script downloads HTML instead of proxy data.

</details>

### 🔗 Client Links

`gen_links.sh` auto-detects the router's IP and generates URIs for all inbounds. With a static IP or DDNS you can also connect from outside the LAN.

```bash
./gen_links.sh
```

<details>
<summary><b>Example output</b></summary>

```
Detected Router LAN IP: 192.168.1.1
--- SOCKS5 ---      socks5://192.168.1.1:1080#socks5-in
--- HTTP/Mixed ---  http://192.168.1.1:2080#mixed-in
--- Shadowsocks --- ss://Y2hhY2hhM...@192.168.1.1:8388#ss-in
--- Hysteria 2 ---  hy2://MyPassword@192.168.1.1:4443?insecure=1#hy2-in
DONE! All links saved to clients.txt
```
</details>

> **SOCKS5** — recommended for most devices. Fully routes both TCP and UDP.  
> **HTTP/Mixed** — fallback for older Smart TVs. TCP only, no UDP support.

Compatible with **v2rayNG** · **NekoBox** · **Hiddify** · **Sing-Box Mobile** · **Karing**

### 📋 Requirements

| Component | Details |
|:---|:---|
| 🔧 Firmware | Padavan (Asus Merlin-based) |
| 💾 Storage | USB drive with Entware at `/opt/` |
| 📦 Packages | `curl wget jq lua openssl-util bash coreutils-sort` |
| ⚙️ Binary | `sing-box linux-mipsle-softfloat` or `hardfloat` |
| 📄 Config | `conf3_final.json` — template with inbounds and routing |

<details>
<summary><b>🔧 FAQ — Common Issues</b></summary>

| Error | Fix |
|:---|:---|
| `converter.lua crashed` | Make sure `converter.lua` and `utils.lua` are in the working directory |
| `All subscription links returned empty` | Check DNS: `nslookup raw.githubusercontent.com` |
| All nodes 0 KB/s | `curl -Is https://speed.cloudflare.com/__down?bytes=1` should return `200 OK` |
| `grep: unknown option` | `opkg install grep` |
| Script hangs | `killall sing-box` |

</details>

<details>
<summary><b>⚠️ Disclaimer</b></summary>

This script is provided **"as is"** for educational purposes only. Public proxies **may log your traffic** — do not transmit sensitive data through them. Use `ENCRYPTION_PRIORITY=2`.

</details>

---

<!-- ============================================================ -->
<!--                        🇮🇷  فارسی                            -->
<!-- ============================================================ -->

## 🇮🇷 فارسی

<div align="center" dir="rtl">

**جستجو، آزمایش و چرخش خودکار پروکسی‌های رایگان روی روتر ضعیف MIPS**

> **تنها اسکریپتی** که می‌تواند پایگاه داده **۶۰٬۰۰۰+ نود پروکسی** را  
> روی روتری با **۳۲ مگابایت RAM آزاد** بدون هنگ‌کردن، OOM یا داغ‌شدن پردازنده هضم کند.

</div>

### ✨ قابلیت‌ها

<table>
<tr>
<td width="50%" dir="rtl">

**🛡️ محافظت Anti-OOM**
نمونه‌گیری یکنواخت ریاضی از طریق `awk` — روتر هیچ‌گاه بیش از ~۴۵۰۰ رکورد را همزمان در RAM نگه نمی‌دارد.

**⚡ Smart Fast-Check**
قبل از اسکن کامل، پول فعلی را بررسی می‌کند. اگر **۷۰٪ نودها زنده** باشند — پایپ‌لاین سنگین رد می‌شود.

**🔒 حالت پارانوئید رمزنگاری**
VLESS بدون TLS و Shadowsocks بدون رمزنگاری را قبل از آزمایش حذف می‌کند. فقط **AEAD** مدرن.

</td>
<td width="50%" dir="rtl">

**🗺️ ماتریس اولویت**
مرتب‌سازی دوبُعدی: بر اساس **پروتکل** یا **کشور**. شما انتخاب می‌کنید — قدرت رمزنگاری یا کمترین پینگ.

**🔄 راه‌اندازی مجدد بدون قطعی**
کانفیگ از طریق `jq` merge اعمال می‌شود + جایگزینی گرم پروسس. اتصالات قطع نمی‌شوند.

**🧩 رمزگشای خودکار اشتراک**
اشتراک‌های Base64 را شفاف پردازش می‌کند و `\0` و `\r` را که `grep` داخلی Padavan را خراب می‌کنند، پاک‌سازی می‌کند.

</td>
</tr>
</table>

### 📦 ساختار پروژه

| فایل | هدف |
|:---|:---|
| `./update.sh` | 🔧 **موتور اصلی** — کل پایپ‌لاین از دانلود تا اجرا |
| `./gen_links.sh` | 🔗 **تولیدکننده لینک** — URIهای آماده برای کلاینت‌های شبکه محلی |
| `converter.lua` | ⚙️ **پارسر URI** — تبدیل `ss://`، `vless://` و غیره به فرمت Sing-Box |
| `utils.lua` | 🛠️ توابع کمکی برای مبدّل |
| `conf3_final.json` | 📋 **کانفیگ مرجع** — الگو با inboundها و routing |

### 🚀 شروع سریع

**گزینه الف — نصب تک‌خطی:**
```bash
wget -O- https://raw.githubusercontent.com/Sophiedevops/singbox-padavan-easy-crawler-2/main/install.sh | sh
```

<details>
<summary><b>گزینه ب — نصب دستی</b></summary>

```bash
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
> ```
> 0 3 */3 * * cd /opt/tmp_sb_ext/sing-box-1.12.12-extended-1.5.1-linux-mipsle && ./update.sh >> /opt/tmp/sb_update.log 2>&1
> ```
</details>

### ⚙️ تنظیمات

```bash
WANTED=10                      # تعداد نودهای کارکرد در کانفیگ نهایی
PERFECT_SPEED_KBPS=800         # حداقل سرعت دانلود برای پذیرش نود
MIN_FAST_CHECK_SPEED_KBPS=500  # آستانه سرعت برای بررسی سریع
MAX_ACCEPTABLE_PING=3000       # حداکثر پینگ از طریق Clash API (ms)
FILTER_COUNTRIES="nl de us pl fi"
PRIORITY_PROTOCOLS="shadowsocks hysteria2 vless trojan vmess"
```

<details>
<summary><b>🔒 حالت رمزنگاری (ENCRYPTION_PRIORITY)</b></summary>

| مقدار | حالت | توضیح |
|:---:|:---:|:---|
| `1` | **استاندارد** | همه پروتکل‌ها بدون فیلتر |
| `2` | **پارانوئید** ⭐ | VLESS بدون TLS و SS بدون رمزنگاری بلافاصله حذف می‌شوند |
| `3` | **ترکیبی** | نودهای «برهنه» در انتهای صف قرار می‌گیرند |

</details>

<details>
<summary><b>🗺️ حالت مرتب‌سازی (SORT_PRIORITY)</b></summary>

| مقدار | منطق | برای چه کسی |
|:---:|:---|:---|
| `0` | **پروتکل ← کشور** | روترهای ضعیف: SS سبک‌تر رمزگذاری می‌شود، CPU را حفاظت می‌کند |
| `1` | **کشور ← پروتکل** | گیمرها: کمترین پینگ به کشور مورد نظر |

</details>

<details>
<summary><b>📡 منابع اشتراک (۱۰ آگریگیتور، ۶۰٬۰۰۰+ نود)</b></summary>

| # | مخزن | پروتکل‌ها |
|:---:|:---|:---:|
| ۱ | [`sakha1370/OpenRay`](https://raw.githubusercontent.com/sakha1370/OpenRay/refs/heads/main/output/all_valid_proxies.txt) | Mix |
| ۲ | [`ebrasha/free-v2ray-public-list`](https://raw.githubusercontent.com/ebrasha/free-v2ray-public-list/refs/heads/main/all_extracted_configs.txt) | Mix |
| ۳ | [`V2RayRoot/V2RayConfig`](https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/refs/heads/main/Config/vless.txt) | VLESS |
| ۴ | [`acymz/AutoVPN`](https://raw.githubusercontent.com/acymz/AutoVPN/refs/heads/main/data/V2.txt) | Mix |
| ۵ | [`roosterkid/openproxylist`](https://raw.githubusercontent.com/roosterkid/openproxylist/refs/heads/main/V2RAY.txt) | Mix |
| ۶ | [`amirkma/proxykma`](https://raw.githubusercontent.com/amirkma/proxykma/refs/heads/main/mix.txt) | Mix |
| ۷ | [`mahdibland/V2RayAggregator`](https://raw.githubusercontent.com/mahdibland/V2RayAggregator/refs/heads/master/sub/sub_merge.txt) | Mix |
| ۸ | [`gongchandang49/TelegramV2rayCollector`](https://raw.githubusercontent.com/gongchandang49/TelegramV2rayCollector/refs/heads/main/sub/mix) | Mix |
| ۹ | [`SoliSpirit/v2ray-configs`](https://raw.githubusercontent.com/SoliSpirit/v2ray-configs/refs/heads/main/Protocols/ss.txt) | SS |
| ۱۰ | [`LonUp/NodeList`](https://raw.githubusercontent.com/LonUp/NodeList/main/node.txt) | Mix |

> ⚠️ هنگام افزودن منابع خود، همیشه از لینک‌های **Raw** استفاده کنید (`raw.githubusercontent.com`)، نه صفحات blob گیت‌هاب.

</details>

### 🔗 لینک‌های کلاینت

`gen_links.sh` به‌طور خودکار IP روتر را شناسایی کرده و URI برای تمام inboundها تولید می‌کند.

```bash
./gen_links.sh
```

> **SOCKS5** — برای اکثر دستگاه‌ها توصیه می‌شود. TCP و UDP را به‌طور کامل روت می‌کند.  
> **HTTP/Mixed** — گزینه جایگزین برای Smart TVهای قدیمی. فقط TCP.

سازگار با **v2rayNG** · **NekoBox** · **Hiddify** · **Sing-Box Mobile** · **Karing**

### 📋 پیش‌نیازها

| مؤلفه | نیاز |
|:---|:---|
| 🔧 فریمور | Padavan (مبتنی بر Asus Merlin) |
| 💾 فضای ذخیره | USB با Entware در `/opt/` |
| 📦 بسته‌ها | `curl wget jq lua openssl-util bash coreutils-sort` |
| ⚙️ باینری | `sing-box linux-mipsle-softfloat` یا `hardfloat` |
| 📄 کانفیگ | `conf3_final.json` — الگو با inboundها و routing |

<details>
<summary><b>🔧 سوالات متداول</b></summary>

| خطا | راه‌حل |
|:---|:---|
| `converter.lua crashed` | وجود `converter.lua` و `utils.lua` در پوشه کاری را بررسی کنید |
| `All subscription links returned empty` | DNS را بررسی کنید: `nslookup raw.githubusercontent.com` |
| همه نودها 0 KB/s | `curl -Is https://speed.cloudflare.com/__down?bytes=1` باید `200 OK` برگرداند |
| `grep: unknown option` | `opkg install grep` |
| اسکریپت هنگ کرد | `killall sing-box` |

</details>

<details>
<summary><b>⚠️ سلب مسئولیت</b></summary>

این اسکریپت **«به همین شکل»** برای اهداف آموزشی ارائه می‌شود. پروکسی‌های عمومی **ممکن است ترافیک شما را ثبت کنند** — داده‌های حساس را از طریق آن‌ها ارسال نکنید. از `ENCRYPTION_PRIORITY=2` استفاده کنید.

</details>

---

<!-- ============================================================ -->
<!--                        🇨🇳  中文                              -->
<!-- ============================================================ -->

## 🇨🇳 中文

<div align="center">

**在低配 MIPS 路由器上自动搜索、测试和轮换免费代理**

**( 已在 MiWiFi 3 | Xiaomi Mi-router 3 上测试 )**

> **唯一能在仅 32 MB 可用内存的路由器上**  
> 处理 **60,000+ 代理节点** 数据库的脚本 — 不卡顿、不 OOM、不过热。

</div>

### ✨ 功能特性

<table>
<tr>
<td width="50%">

**🛡️ Anti-OOM 保护**
通过 `awk` 进行数学均匀采样 — 路由器同时在内存中保存的记录永不超过约 4,500 条。

**⚡ 智能快速检查**
全量扫描前先测试当前节点池。若 **70% 节点存活** — 直接跳过繁重的处理流程。

**🔒 偏执加密模式**
在测试前自动剔除无 TLS 的 VLESS 和未加密的 Shadowsocks。只保留现代 **AEAD**。

</td>
<td width="50%">

**🗺️ 优先级矩阵**
二维排序：按**协议**或按**国家**。您决定什么更重要 — 加密强度还是最低延迟。

**🔄 零停机热重载**
通过 `jq` 合并应用新配置 + 进程热替换。现有连接不中断。

**🧩 订阅自动解码器**
透明处理 Base64 订阅，并清理会破坏 Padavan 内置 `grep` 的 `\0`、`\r` 垃圾字符。

</td>
</tr>
</table>

### 📦 项目结构

| 文件 | 用途 |
|:---|:---|
| `./update.sh` | 🔧 **主引擎** — 从下载到部署的完整流水线 |
| `./gen_links.sh` | 🔗 **链接生成器** — 为局域网客户端生成即用 URI |
| `converter.lua` | ⚙️ **URI 解析器** — 将 `ss://`、`vless://` 等转换为 Sing-Box 格式 |
| `utils.lua` | 🛠️ 转换器辅助函数 |
| `conf3_final.json` | 📋 **参考配置** — 包含入站和路由的模板 |

### 🚀 快速开始

**方式 A — 一键安装脚本：**
```bash
wget -O- https://raw.githubusercontent.com/Sophiedevops/singbox-padavan-easy-crawler-2/main/install.sh | sh
```

<details>
<summary><b>方式 B — 手动安装</b></summary>

```bash
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
> ```
> 0 3 */3 * * cd /opt/tmp_sb_ext/sing-box-1.12.12-extended-1.5.1-linux-mipsle && ./update.sh >> /opt/tmp/sb_update.log 2>&1
> ```
</details>

### ⚙️ 配置说明

```bash
WANTED=10                      # 最终配置中需要的可用节点数量
PERFECT_SPEED_KBPS=800         # 接受节点的最低下载速度
MIN_FAST_CHECK_SPEED_KBPS=500  # 快速检查阶段的速度阈值
MAX_ACCEPTABLE_PING=3000       # Clash API 最大延迟 (ms)
FILTER_COUNTRIES="nl de us pl fi"
PRIORITY_PROTOCOLS="shadowsocks hysteria2 vless trojan vmess"
```

<details>
<summary><b>🔒 加密模式 (ENCRYPTION_PRIORITY)</b></summary>

| 值 | 模式 | 说明 |
|:---:|:---:|:---|
| `1` | **标准** | 所有协议，无 TLS 过滤 |
| `2` | **偏执** ⭐ | 无 TLS 的 VLESS 和未加密的 SS 立即删除 |
| `3` | **混合** | 裸节点保留但被推到队列最末 |

</details>

<details>
<summary><b>🗺️ 排序模式 (SORT_PRIORITY)</b></summary>

| 值 | 逻辑 | 适用场景 |
|:---:|:---|:---|
| `0` | **协议 → 国家** | 低配路由器：SS 加密更轻量，节省 CPU |
| `1` | **国家 → 协议** | 游戏玩家：保证目标国家最低延迟 |

```
示例 SORT=0, ENC=2:
① NL 的 SS+AEAD → DE → US …  ④ NL 的 HY2 → DE …  ⑦ 全球 Fallback
```
</details>

<details>
<summary><b>📡 订阅源（10 个聚合器，60,000+ 节点）</b></summary>

| # | 仓库 | 协议 |
|:---:|:---|:---:|
| 1 | [`sakha1370/OpenRay`](https://raw.githubusercontent.com/sakha1370/OpenRay/refs/heads/main/output/all_valid_proxies.txt) | Mix |
| 2 | [`ebrasha/free-v2ray-public-list`](https://raw.githubusercontent.com/ebrasha/free-v2ray-public-list/refs/heads/main/all_extracted_configs.txt) | Mix |
| 3 | [`V2RayRoot/V2RayConfig`](https://raw.githubusercontent.com/V2RayRoot/V2RayConfig/refs/heads/main/Config/vless.txt) | VLESS |
| 4 | [`acymz/AutoVPN`](https://raw.githubusercontent.com/acymz/AutoVPN/refs/heads/main/data/V2.txt) | Mix |
| 5 | [`roosterkid/openproxylist`](https://raw.githubusercontent.com/roosterkid/openproxylist/refs/heads/main/V2RAY.txt) | Mix |
| 6 | [`amirkma/proxykma`](https://raw.githubusercontent.com/amirkma/proxykma/refs/heads/main/mix.txt) | Mix |
| 7 | [`mahdibland/V2RayAggregator`](https://raw.githubusercontent.com/mahdibland/V2RayAggregator/refs/heads/master/sub/sub_merge.txt) | Mix |
| 8 | [`gongchandang49/TelegramV2rayCollector`](https://raw.githubusercontent.com/gongchandang49/TelegramV2rayCollector/refs/heads/main/sub/mix) | Mix |
| 9 | [`SoliSpirit/v2ray-configs`](https://raw.githubusercontent.com/SoliSpirit/v2ray-configs/refs/heads/main/Protocols/ss.txt) | SS |
| 10 | [`LonUp/NodeList`](https://raw.githubusercontent.com/LonUp/NodeList/main/node.txt) | Mix |

> ⚠️ 添加自定义来源时，请始终使用 **Raw** 链接（`raw.githubusercontent.com`），而非 GitHub blob 页面 — 否则脚本会下载 HTML 而非代理数据。

</details>

### 🔗 客户端链接

`gen_links.sh` 自动检测路由器 IP 并为所有入站生成 URI。如有静态 IP 或 DDNS，也可从局域网外连接。

```bash
./gen_links.sh
```

> **SOCKS5** — 推荐用于大多数设备。完整路由 TCP 和 UDP。  
> **HTTP/Mixed** — 老款智能电视的备选方案。仅支持 TCP，不支持 UDP。

兼容 **v2rayNG** · **NekoBox** · **Hiddify** · **Sing-Box 手机版** · **Karing**

### 📋 环境要求

| 组件 | 说明 |
|:---|:---|
| 🔧 固件 | Padavan（基于 Asus Merlin） |
| 💾 存储 | 安装了 Entware 的 USB 存储器（挂载于 `/opt/`） |
| 📦 软件包 | `curl wget jq lua openssl-util bash coreutils-sort` |
| ⚙️ 二进制文件 | `sing-box linux-mipsle-softfloat` 或 `hardfloat` |
| 📄 配置 | `conf3_final.json` — 含入站和路由的模板 |

<details>
<summary><b>🔧 常见问题</b></summary>

| 错误 | 解决方法 |
|:---|:---|
| `converter.lua crashed` | 检查工作目录中是否有 `converter.lua` 和 `utils.lua` |
| `All subscription links returned empty` | 检查 DNS：`nslookup raw.githubusercontent.com` |
| 所有节点 0 KB/s | `curl -Is https://speed.cloudflare.com/__down?bytes=1` 应返回 `200 OK` |
| `grep: unknown option` | `opkg install grep` |
| 脚本卡住 | `killall sing-box` |

</details>

<details>
<summary><b>⚠️ 免责声明</b></summary>

本脚本仅供教育目的 **"按原样"** 提供。公共代理**可能记录您的流量** — 请勿通过它们传输敏感数据。请使用 `ENCRYPTION_PRIORITY=2`。

</details>

---

<div align="center">

献给热爱自由路由和经典 MIPS 路由器的人们 ❤️

**如果这个项目对您有帮助，请点个 ⭐**

---

🇷🇺 [Русский](#-русский) · 🇬🇧 [English](#-english) · 🇮🇷 [فارسی](#-فارسی) · 🇨🇳 [中文](#-中文)

</div>
