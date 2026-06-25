# singbox-padavan-easy-crawler-2

```
███████╗██╗███╗   ██╗ ██████╗       ██████╗  ██████╗ ██╗  ██╗
██╔════╝██║████╗  ██║██╔════╝       ██╔══██╗██╔═══██╗╚██╗██╔╝
███████╗██║██╔██╗ ██║██║  ███╗█████╗██████╔╝██║   ██║ ╚███╔╝ 
╚════██║██║██║╚██╗██║██║   ██║╚════╝██╔══██╗██║   ██║ ██╔██╗ 
███████║██║██║ ╚████║╚██████╔╝      ██████╔╝╚██████╔╝██╔╝ ██╗
╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝       ╚═════╝  ╚═════╝ ╚═╝  ╚═╝
```

**Smart Proxy Crawler & Auto-Updater for Sing-Box Extended on Padavan Routers**

[![Shell Script](https://img.shields.io/badge/Language-Shell_Script-4EAA25?style=for-the-badge&logo=gnu-bash)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Padavan_%7C_MIPSLE-007ACC?style=for-the-badge&logo=openwrt)](https://github.com/hanwckf/rt-n56u)
[![Core](https://img.shields.io/badge/Core-sing--box--extended_2.4.1-blueviolet?style=for-the-badge)](https://github.com/shtorm-7/sing-box-extended)
[![Status](https://img.shields.io/badge/Status-Stable_v2-success?style=for-the-badge)](https://github.com/Sophiedevops/singbox-padavan-easy-crawler-2/releases)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](https://github.com/Sophiedevops/singbox-padavan-easy-crawler-2/blob/main/LICENSE)

---

**🌐 Доступные языки / Available languages:**
[🇷🇺 Русский](#-русский) · [🇬🇧 English](#-english) · [🇮🇷 فارسی](#-فارسی) · [🇨🇳 中文](#-中文) · [🇸🇦 العربية](#-العربية)

---

## 🇷🇺 Русский

*Автоматический поиск, разбор, тестирование и ротация бесплатных прокси прямо на слабом MIPS-роутере — без OOM и без перегрева.*

---

### 🧩 Что это такое?

Проект поддерживает **актуальный пул рабочих прокси** (Shadowsocks, VLESS, VMess, Trojan, Hysteria2, Hysteria, TUIC, Mieru, MASQUE) на роутере с **дефицитом ОЗУ и слабым процессором MIPSLE**, не убивая его при обработке подписок в 60 000+ нод.

Проект состоит из трёх скриптов и одного шаблона:

| Файл              | Назначение                                                                                     |
|-------------------|-------------------------------------------------------------------------------------------------|
| `install.sh`      | Установщик «в одну команду»: ставит зависимости, скачивает ядро и скрипты, настраивает автозапуск |
| `update.sh`       | Основной движок: подписки → сэмплирование → разбор на Lua → батч-тесты → горячий перезапуск     |
| `gen_links.sh`    | Генератор клиентских ссылок: читает конфиг и выдаёт готовые ссылки для смартфонов и ПК           |
| `converter.lua`   | Самодостаточный Lua-парсер: превращает прокси-ссылки в outbound-блоки sing-box                   |
| `conf3_final.json`| Базовый шаблон (инбаунды, DNS, роутинг — без аутбаундов)                                          |

---

### ⚙️ Ядро: sing-box-extended

Проект работает на расширенной сборке ядра из репозитория **[shtorm-7/sing-box-extended](https://github.com/shtorm-7/sing-box-extended)** — это форк оригинального [SagerNet/sing-box](https://github.com/sagernet/sing-box) с большим набором дополнительных протоколов и транспортов. Мы используем релиз **[v1.13.12-extended-2.4.1](https://github.com/shtorm-7/sing-box-extended/releases/tag/v1.13.12-extended-2.4.1)** для `linux-mipsle-softfloat`.

**Что расширенная версия добавляет поверх оригинального sing-box 1.13** (по заявлению автора форка): `XHTTP`, `MASQUE`, `MTProxy`, `Mieru`, `OpenVPN`, `TrustTunnel`, `Sudoku`, `SSH`, `WARP`, `AmneziaWG (amnezia)`, `SDNS (DNSCrypt)`, `unified_delay`, `vless_encryption`, `Bond`, `Fallback`, `Failover`, `VPN-туннелирование`, `Providers`, `Link Parser` и расширенные опции WireGuard.

**Что из этого реально применяется у нас:**

| Возможность           | Применение в проекте                                                                 |
|-----------------------|---------------------------------------------------------------------------------------|
| ✅ **XHTTP**          | Lua-парсер распознаёт транспорт `xhttp` у VLESS/Trojan и автоматически тестирует такие ноды |
| ✅ **Mieru**          | Ссылки `mieru://` собираются из подписок, парсятся и проверяются                      |
| ✅ **MASQUE**         | Ссылки `masque://` (QUIC/HTTP-2) собираются, парсятся и проверяются                   |
| ✅ **Hysteria2 / Hysteria / TUIC** | Полностью поддержаны как исходящие ноды; Hysteria2 также поднимается как входящий |
| ✅ **Unified delay**  | Калиброванное измерение задержки повышает точность батч-тестов на медленном MIPS      |
| ✅ **SDNS / расширенный DNS** | Доступен в бинарнике; базовый конфиг использует DNS-стек со стратегией `prefer_ipv4` |

Остальные возможности форка (`WARP`, `AmneziaWG`, `MTProxy`, `OpenVPN`, `TrustTunnel`, `Sudoku`, `SSH`, `Bond/Fallback/Failover` и др.) присутствуют в бинарнике и могут быть подключены в `conf3_final.json` вручную.

---

### ✨ Ключевые особенности

**🛡️ Anti-OOM защита** — равномерная выборка нод через `awk` позволяет обрабатывать базы из 60 000+ нод, не превышая лимит ОЗУ слабого роутера. При нехватке памяти временные файлы пишутся не в tmpfs, а на флешку.

**⚡ Smart Fast-Check** — перед полным сканом проверяются ноды из текущего конфига. Если ≥70 % держат скорость выше порога — полный пайплайн отменяется, экономя ресурс флешки и время.

**🔒 Параноидальный режим шифрования** — автоматически вырезает VLESS без TLS, Shadowsocks с `method: none` и устаревшие шифры. Остаётся только современное AEAD-шифрование.

**🧩 Авто-декодер + санитайзер** — обрабатывает «битые» подписки: пробует прямое чтение, затем Base64. Зачищает нулевые байты и Windows-переносы строк, ломающие встроенный `grep` прошивки.

**🗺️ Матрица приоритетов** — две независимых оси сортировки (шифрование × протокол/страна) дают несколько режимов поведения краулера.

**🔗 Генератор ссылок** — `gen_links.sh` сам определяет LAN-IP роутера и выдаёт ссылки для всех входящих (Mixed, SOCKS5, Shadowsocks, Hysteria2, VLESS). Совместимо с v2rayNG, NekoBox, Hiddify, Sing-Box (мобильный).

---

### 🚀 Установка (рекомендуемый способ)

Самый простой путь — установщик «в одну команду». Он проверит Entware, поставит зависимости (`curl jq lua openssl-util bash coreutils-sort`), скачает ядро sing-box-extended и все скрипты, сгенерирует сертификаты и настроит автозапуск + cron.

```bash
# 1. Подключитесь к роутеру по SSH
ssh admin@192.168.1.1

# 2. Скачайте и запустите установщик
wget -O install.sh https://raw.githubusercontent.com/Sophiedevops/singbox-padavan-easy-crawler-2/main/install.sh
chmod +x install.sh
./install.sh
```

После установки рабочая папка: `/opt/tmp_sb_ext/sing-box-1.13.12-extended-2.4.1-linux-mipsle`.
Установщик добавит автозапуск ядра в `started_script.sh` и задачу cron на обновление пула (раз в 3 дня в 4:00).

**Получить ссылки для своих устройств:**

```bash
cd /opt/tmp_sb_ext/sing-box-1.13.12-extended-2.4.1-linux-mipsle
./gen_links.sh
```

---

### 🎛️ Основные параметры (редактируются в начале `update.sh`)

```bash
WANTED=8                        # Сколько рабочих серверов нужно в итоговом конфиге
PERFECT_SPEED_KBPS=900          # Минимальная скорость для включения (КБ/с)
MIN_FAST_CHECK_SPEED_KBPS=600   # Порог скорости при быстрой проверке пула
MAX_ACCEPTABLE_PING=3000        # Максимальный пинг (мс) по Clash API

ENCRYPTION_PRIORITY=1           # 1 — все ноды, 2 — только защищённые, 3 — защищённые в приоритете
SORT_PRIORITY=0                 # 0 — протокол→страна, 1 — страна→протокол

FILTER_COUNTRIES="nl de us pl fi jp tw sg hk fr se uk gb ca ru tr md kr"
PRIORITY_PROTOCOLS="shadowsocks hysteria2 tuic vless hysteria trojan vmess mieru masque"
```

---

### 🔧 Устранение неполадок

- **`converter.lua crashed`** → убедитесь, что `converter.lua` лежит в рабочей папке.
- **`All subscription links returned empty`** → роутер не достучался до GitHub: проверьте DNS и маршруты.
- **Все ноды показывают 0 KB/s** → недоступен сервер замера скорости; проверьте прямой (без прокси) маршрут.
- **`grep: unknown option`** → установите Entware-версию: `opkg install grep`.

---

### ⚠️ Отказ от ответственности

Скрипт предоставлен **«как есть»** в образовательных и исследовательских целях. Бесплатные публичные прокси могут логировать трафик — **не передавайте через них чувствительные данные** и используйте режим `ENCRYPTION_PRIORITY=2`.

---

Сделано с любовью к свободной маршрутизации и старым добрым MIPS-роутерам ❤️

---

## 🇬🇧 English

*Automatic proxy discovery, parsing, testing and rotation directly on a low-end MIPS router — no OOM, no overheating.*

---

### What is this?

A shell-based system that maintains a **live pool of working proxies** (Shadowsocks, VLESS, VMess, Trojan, Hysteria2, Hysteria, TUIC, Mieru, MASQUE) on a **RAM-constrained Padavan router with a MIPSLE CPU**, able to process subscription lists with 60,000+ nodes without crashing.

It ships as three scripts plus one template:

- **`install.sh`** — one-command installer: dependencies, core binary, scripts, autostart + cron
- **`update.sh`** — the engine: subscriptions → sampling → Lua parsing → batch testing → hot reload
- **`gen_links.sh`** — generates ready-to-use client links from the active config
- **`converter.lua`** — self-contained Lua parser that turns share links into sing-box outbounds
- **`conf3_final.json`** — base template (inbounds, DNS, routing — no outbounds)

---

### Core Engine: sing-box-extended

The project runs on the extended core from **[shtorm-7/sing-box-extended](https://github.com/shtorm-7/sing-box-extended)**, a fork of [SagerNet/sing-box](https://github.com/sagernet/sing-box) that adds many extra protocols and transports. We use release **[v1.13.12-extended-2.4.1](https://github.com/shtorm-7/sing-box-extended/releases/tag/v1.13.12-extended-2.4.1)** for `linux-mipsle-softfloat`.

**What the extended build claims to add over stock sing-box 1.13:** `XHTTP`, `MASQUE`, `MTProxy`, `Mieru`, `OpenVPN`, `TrustTunnel`, `Sudoku`, `SSH`, `WARP`, `AmneziaWG`, `SDNS (DNSCrypt)`, `unified_delay`, `vless_encryption`, `Bond`, `Fallback`, `Failover`, `VPN tunneling`, `Providers`, `Link Parser`, and extended WireGuard options.

**What we actually use:**

| Feature                | How we use it                                                                 |
|------------------------|-------------------------------------------------------------------------------|
| ✅ **XHTTP**           | Our Lua parser detects the `xhttp` transport on VLESS/Trojan and auto-tests those nodes |
| ✅ **Mieru**           | `mieru://` links are crawled, parsed and tested                               |
| ✅ **MASQUE**          | `masque://` (QUIC/HTTP-2) links are crawled, parsed and tested                |
| ✅ **Hysteria2 / Hysteria / TUIC** | Fully supported as outbounds; Hysteria2 is also exposed as an inbound |
| ✅ **Unified delay**   | Calibrated latency measurement improves batch-test accuracy on slow MIPS      |
| ✅ **SDNS / extended DNS** | Available in the binary; the base config uses a `prefer_ipv4` DNS stack    |

Other fork features (`WARP`, `AmneziaWG`, `MTProxy`, `OpenVPN`, `TrustTunnel`, `Sudoku`, `SSH`, `Bond/Fallback/Failover`, …) are present in the binary and can be wired into `conf3_final.json` manually.

---

### Key Features

- **Anti-OOM sampling** — uniform `awk` sampling processes 60k+ node lists without exceeding router RAM; temp files fall back to flash when memory is low
- **Smart fast-check** — skips the full pipeline if ≥70% of current nodes are still fast enough, saving flash wear and CPU
- **Paranoid encryption mode** — drops VLESS without TLS, Shadowsocks with `method: none`, and legacy ciphers
- **Auto-decoder & sanitizer** — handles broken/Base64 subscriptions, null bytes and Windows line endings
- **Priority matrix** — configurable sorting across two axes: encryption level × protocol/country
- **Real-traffic testing** — speed is measured with actual downloads through a live sing-box instance, not ICMP ping
- **Zero-downtime hot reload** — merges new nodes into the base config and restarts the service seamlessly

---

### Quick Start (recommended)

```bash
ssh admin@192.168.1.1
wget -O install.sh https://raw.githubusercontent.com/Sophiedevops/singbox-padavan-easy-crawler-2/main/install.sh
chmod +x install.sh
./install.sh
```

The installer creates `/opt/tmp_sb_ext/sing-box-1.13.12-extended-2.4.1-linux-mipsle`, configures core autostart and a cron job that refreshes the pool every 3 days at 4 AM.

Client links:
```bash
cd /opt/tmp_sb_ext/sing-box-1.13.12-extended-2.4.1-linux-mipsle
./gen_links.sh
```

> ⚠️ **Disclaimer:** Free public proxies may log your traffic. Use `ENCRYPTION_PRIORITY=2` (paranoid mode) and avoid sending sensitive data through untrusted nodes.

---

## 🇮🇷 فارسی

*جستجو، تجزیه، آزمایش و چرخش خودکار پروکسی مستقیماً روی روتر ضعیف MIPS — بدون کرش حافظه، بدون گرمای اضافه.*

---

### این پروژه چیست؟

سیستمی مبتنی بر Shell که یک **مخزن فعال از پروکسی‌های کارآمد** (Shadowsocks، VLESS، VMess، Trojan، Hysteria2، Hysteria، TUIC، Mieru، MASQUE) را روی روتر Padavan با **پردازنده ضعیف MIPSLE** نگه می‌دارد، حتی با لیست‌های بیش از ۶۰٬۰۰۰ نود بدون خرابی.

اجزای پروژه:
- **`install.sh`** — نصب‌کننده تک‌دستوری: وابستگی‌ها، هسته، اسکریپت‌ها و اجرای خودکار
- **`update.sh`** — موتور اصلی: اشتراک‌ها ← نمونه‌گیری ← تجزیه با Lua ← آزمایش دسته‌ای ← بارگذاری مجدد گرم
- **`gen_links.sh`** — تولید لینک‌های آماده برای موبایل و رایانه
- **`converter.lua`** — تجزیه‌گر مستقل Lua برای تبدیل لینک‌ها به خروجی‌های sing-box

---

### هسته: sing-box-extended

این پروژه از سازهٔ گسترش‌یافتهٔ مخزن **[shtorm-7/sing-box-extended](https://github.com/shtorm-7/sing-box-extended)** استفاده می‌کند؛ این یک فورک از [SagerNet/sing-box](https://github.com/sagernet/sing-box) است. ما از نسخهٔ **[v1.13.12-extended-2.4.1](https://github.com/shtorm-7/sing-box-extended/releases/tag/v1.13.12-extended-2.4.1)** برای `linux-mipsle-softfloat` استفاده می‌کنیم.

**قابلیت‌هایی که نسخهٔ گسترش‌یافته نسبت به sing-box 1.13 اصلی اضافه می‌کند:** `XHTTP`، `MASQUE`، `MTProxy`، `Mieru`، `OpenVPN`، `TrustTunnel`، `Sudoku`، `SSH`، `WARP`، `AmneziaWG`، `SDNS`، `unified_delay`، `Bond`، `Fallback`، `Failover`، تونل‌سازی VPN و گزینه‌های پیشرفتهٔ WireGuard.

**آنچه در پروژهٔ ما استفاده می‌شود:**
- ✅ **XHTTP** — تجزیه‌گر Lua نودهای VLESS/Trojan با انتقال `xhttp` را شناسایی و آزمایش می‌کند
- ✅ **Mieru** — لینک‌های `mieru://` جمع‌آوری و آزمایش می‌شوند
- ✅ **MASQUE** — لینک‌های `masque://` جمع‌آوری و آزمایش می‌شوند
- ✅ **Hysteria2 / Hysteria / TUIC** — پشتیبانی کامل به‌عنوان خروجی؛ Hysteria2 به‌عنوان ورودی نیز فعال است
- ✅ **Unified delay** — اندازه‌گیری دقیق‌تر تأخیر در آزمایش دسته‌ای روی MIPS

---

### ویژگی‌های اصلی

- **حفاظت Anti-OOM** — نمونه‌گیری یکنواخت برای پردازش لیست‌های ۶۰٬۰۰۰+ نودی بدون اتمام حافظه
- **بررسی سریع هوشمند** — اگر ۷۰٪ از نودهای فعلی سالم باشند، اسکن کامل اجرا نمی‌شود
- **حالت رمزگذاری پارانویایی** — حذف خودکار VLESS بدون TLS و Shadowsocks با `method: none`
- **آزمایش با ترافیک واقعی** — سنجش سرعت با دانلود واقعی، نه پینگ ICMP
- **بارگذاری مجدد بدون قطعی** — جایگزینی پیکربندی بدون قطع اتصالات فعال

---

### شروع سریع

```bash
ssh admin@192.168.1.1
wget -O install.sh https://raw.githubusercontent.com/Sophiedevops/singbox-padavan-easy-crawler-2/main/install.sh
chmod +x install.sh
./install.sh
```

دریافت لینک‌ها:
```bash
cd /opt/tmp_sb_ext/sing-box-1.13.12-extended-2.4.1-linux-mipsle
./gen_links.sh
```

> ⚠️ پروکسی‌های رایگان ممکن است ترافیک را ثبت کنند. از حالت `ENCRYPTION_PRIORITY=2` استفاده کنید و اطلاعات حساس ارسال نکنید.

---

## 🇨🇳 中文

*在低端 MIPS 路由器上直接实现代理的自动发现、解析、测速和轮换——无 OOM 崩溃，无过热。*

---

### 项目简介

一套基于 Shell 的系统，可在 **RAM 受限的 Padavan MIPSLE 路由器**上维护活跃的代理池（Shadowsocks、VLESS、VMess、Trojan、Hysteria2、Hysteria、TUIC、Mieru、MASQUE），即使面对 6 万+节点的订阅列表也不会崩溃。

组成部分：
- **`install.sh`** — 一键安装器：依赖、内核、脚本、开机自启 + 定时任务
- **`update.sh`** — 主引擎：下载订阅 → 采样 → Lua 解析 → 批量测速 → 热重载
- **`gen_links.sh`** — 生成客户端链接，供手机和电脑使用
- **`converter.lua`** — 独立的 Lua 解析器，把分享链接转换为 sing-box 出站

---

### 核心引擎：sing-box-extended

本项目使用来自 **[shtorm-7/sing-box-extended](https://github.com/shtorm-7/sing-box-extended)** 的扩展版内核，它是 [SagerNet/sing-box](https://github.com/sagernet/sing-box) 的一个分叉。我们使用 `linux-mipsle-softfloat` 的 **[v1.13.12-extended-2.4.1](https://github.com/shtorm-7/sing-box-extended/releases/tag/v1.13.12-extended-2.4.1)** 版本。

**扩展版相较原版 sing-box 1.13 声称新增的功能：** `XHTTP`、`MASQUE`、`MTProxy`、`Mieru`、`OpenVPN`、`TrustTunnel`、`Sudoku`、`SSH`、`WARP`、`AmneziaWG`、`SDNS (DNSCrypt)`、`unified_delay`、`Bond`、`Fallback`、`Failover`、VPN 隧道及扩展 WireGuard 选项。

**本项目实际应用的功能：**

| 扩展功能 | 在本项目中的应用 |
|----------|-----------------|
| ✅ **XHTTP** | Lua 解析器识别 VLESS/Trojan 的 `xhttp` 传输并自动测速 |
| ✅ **Mieru** | 抓取并测试 `mieru://` 链接 |
| ✅ **MASQUE** | 抓取并测试 `masque://`（QUIC/HTTP-2）链接 |
| ✅ **Hysteria2 / Hysteria / TUIC** | 作为出站完整支持；Hysteria2 同时作为入站 |
| ✅ **Unified delay** | 提升 MIPS 架构下批量测试的延迟测量精度 |
| ✅ **SDNS / 扩展 DNS** | 二进制中可用；基础配置使用 `prefer_ipv4` DNS 策略 |

其余功能（`WARP`、`AmneziaWG`、`MTProxy`、`OpenVPN` 等）已包含在二进制中，可在 `conf3_final.json` 中手动启用。

---

### 核心特性

- **Anti-OOM 防护** — 通过 `awk` 均匀采样处理 6 万+节点，不超过路由器 RAM 限制
- **智能快速检查** — 若当前 70% 以上节点仍满速，跳过完整流水线，节省闪存和 CPU
- **偏执加密模式** — 自动过滤无 TLS 的 VLESS、`method: none` 的 Shadowsocks 及过时加密算法
- **真实流量测试** — 通过实际下载测速，而非 ICMP ping
- **零中断热重载** — 合并配置后无缝重启主进程

---

### 快速开始

```bash
ssh admin@192.168.1.1
wget -O install.sh https://raw.githubusercontent.com/Sophiedevops/singbox-padavan-easy-crawler-2/main/install.sh
chmod +x install.sh
./install.sh
```

安装器会创建工作目录 `/opt/tmp_sb_ext/sing-box-1.13.12-extended-2.4.1-linux-mipsle`，配置开机自启并添加每 3 天凌晨 4 点刷新代理池的定时任务。

获取客户端链接：
```bash
cd /opt/tmp_sb_ext/sing-box-1.13.12-extended-2.4.1-linux-mipsle
./gen_links.sh
```

> ⚠️ **免责声明：** 公开免费代理可能记录流量，请使用 `ENCRYPTION_PRIORITY=2`（偏执模式），勿通过不可信节点传输敏感数据。

---

## 🇸🇦 العربية

*اكتشاف تلقائي للبروكسيات وتحليلها واختبارها وتدويرها مباشرةً على جهاز توجيه MIPS محدود الموارد — بدون انهيار الذاكرة وبدون ارتفاع في الحرارة.*

---

### ما هو هذا المشروع؟

نظام مبني على Shell يحافظ على **مجموعة نشطة من البروكسيات العاملة** (Shadowsocks، VLESS، VMess، Trojan، Hysteria2، Hysteria، TUIC، Mieru، MASQUE) على جهاز توجيه **Padavan ذي معالج MIPSLE ضعيف**، دون أن يتعطل حتى عند معالجة قوائم اشتراك تحتوي على أكثر من 60٬000 عقدة.

مكوّنات المشروع:
- **`install.sh`** — مُثبِّت بأمر واحد: التبعيات والنواة والسكربتات والتشغيل التلقائي + مهمة cron
- **`update.sh`** — المحرك الرئيسي: الاشتراكات ← أخذ العينات ← التحليل بـ Lua ← الاختبار الدُفعي ← إعادة التحميل الساخن
- **`gen_links.sh`** — مولّد روابط العميل الجاهزة للهاتف والحاسوب
- **`converter.lua`** — محلِّل Lua مستقل يحوّل روابط المشاركة إلى منافذ صادرة في sing-box

---

### النواة الأساسية: sing-box-extended

يعمل هذا المشروع على النواة الموسّعة من المستودع **[shtorm-7/sing-box-extended](https://github.com/shtorm-7/sing-box-extended)**، وهو fork من المشروع الأصلي [SagerNet/sing-box](https://github.com/sagernet/sing-box). نستخدم الإصدار **[v1.13.12-extended-2.4.1](https://github.com/shtorm-7/sing-box-extended/releases/tag/v1.13.12-extended-2.4.1)** لمعمارية `linux-mipsle-softfloat`.

**الميزات التي تضيفها النسخة الموسّعة مقارنةً بـ sing-box 1.13 الأصلي** (وفقاً لمؤلف الـ fork): `XHTTP`، `MASQUE`، `MTProxy`، `Mieru`، `OpenVPN`، `TrustTunnel`، `Sudoku`، `SSH`، `WARP`، `AmneziaWG`، `SDNS (DNSCrypt)`، `unified_delay`، `Bond`، `Fallback`، `Failover`، نفق VPN، وخيارات WireGuard الموسّعة.

**ما هو مُطبَّق فعلياً في مشروعنا:**

| الميزة | التطبيق في مشروعنا |
|--------|---------------------|
| ✅ **XHTTP** | يكتشف محلِّل Lua نقل `xhttp` في VLESS/Trojan ويختبر تلك العقد تلقائياً |
| ✅ **Mieru** | يتم جمع روابط `mieru://` وتحليلها واختبارها |
| ✅ **MASQUE** | يتم جمع روابط `masque://` (QUIC/HTTP-2) وتحليلها واختبارها |
| ✅ **Hysteria2 / Hysteria / TUIC** | مدعومة بالكامل كاتصال صادر؛ وHysteria2 كنقطة دخول أيضاً |
| ✅ **Unified delay** | قياس دقيق لوقت الاستجابة يحسّن دقة الاختبارات الدُفعية على MIPS |
| ✅ **SDNS / DNS الموسّع** | متاح في الملف الثنائي؛ يستخدم الإعداد الأساسي استراتيجية `prefer_ipv4` |

أما بقية ميزات الـ fork (`WARP`، `AmneziaWG`، `MTProxy`، `OpenVPN`، `TrustTunnel`، `Sudoku`، `SSH`، `Bond/Fallback/Failover`، …) فهي موجودة في الملف الثنائي ويمكن تفعيلها يدوياً في `conf3_final.json`.

---

### المميزات الرئيسية

- **حماية Anti-OOM** — أخذ عينات منتظمة عبر `awk` لمعالجة قوائم 60٬000+ عقدة دون تجاوز حد الذاكرة
- **فحص سريع ذكي** — إذا كانت 70% أو أكثر من العقد الحالية تعمل بكفاءة، يُلغى المسح الكامل توفيراً للموارد
- **وضع التشفير المشدَّد** — يحذف تلقائياً VLESS بدون TLS وShadowsocks مع `method: none` والخوارزميات القديمة
- **اختبار بحركة مرور حقيقية** — قياس السرعة عبر تنزيل فعلي وليس ICMP ping
- **إعادة تحميل ساخنة بدون انقطاع** — دمج الإعداد الجديد وإعادة تشغيل العملية الرئيسية دون قطع الاتصالات الحالية

---

### البداية السريعة

```bash
# الاتصال بجهاز التوجيه عبر SSH
ssh admin@192.168.1.1

# تنزيل المُثبِّت وتشغيله
wget -O install.sh https://raw.githubusercontent.com/Sophiedevops/singbox-padavan-easy-crawler-2/main/install.sh
chmod +x install.sh
./install.sh
```

يُنشئ المُثبِّت مجلد العمل `/opt/tmp_sb_ext/sing-box-1.13.12-extended-2.4.1-linux-mipsle`، ويضبط التشغيل التلقائي للنواة ومهمة cron لتحديث المجموعة كل 3 أيام في الساعة 4 صباحاً.

للحصول على روابط الاتصال لأجهزتك:
```bash
cd /opt/tmp_sb_ext/sing-box-1.13.12-extended-2.4.1-linux-mipsle
./gen_links.sh
# يُخرج روابط ss:// وsocks5:// وhy2:// وvless:// لجميع العملاء المدعومة
```

> ⚠️ **إخلاء المسؤولية:** البروكسيات المجانية العامة قد تسجّل حركة مرورك. استخدم `ENCRYPTION_PRIORITY=2` (الوضع المشدَّد) وتجنَّب إرسال البيانات الحساسة عبر عقد غير موثوقة.

---

*صُنع بحب لأجل التوجيه الحر وأجهزة MIPS القديمة الموثوقة ❤️*

*إذا أفادك المشروع — ضع ⭐ على GitHub*
