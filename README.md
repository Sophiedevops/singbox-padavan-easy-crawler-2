<div align="center">

# 🌐 Sing-Box · Padavan · Smart Crawler v2

**Автоматический поиск, тест и ротация бесплатных прокси на слабом MIPS-роутере**

[![Shell](https://img.shields.io/badge/Shell-POSIX_sh-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Padavan-MIPSLE-007ACC?style=for-the-badge&logo=openwrt&logoColor=white)](https://github.com/RMerl/asuswrt-merlin)
[![Core](https://img.shields.io/badge/Sing--Box-1.12_Extended-blueviolet?style=for-the-badge)](https://sing-box.sagernet.org/)
[![Status](https://img.shields.io/badge/Status-Stable-brightgreen?style=for-the-badge)]()
[![License](https://img.shields.io/badge/License-MIT-orange?style=for-the-badge)]()

<br>

> **Единственный скрипт**, который умеет переварить базу из **60 000+ прокси-нод**  
> на роутере с **32 МБ свободной ОЗУ** — без зависания, без OOM, без перегрева.

<br>

[🚀 Быстрый старт](#-быстрый-старт) &nbsp;·&nbsp;
[⚙️ Настройки](#️-настройки) &nbsp;·&nbsp;
[🔗 Клиентские ссылки](#-клиентские-ссылки) &nbsp;·&nbsp;
[🔧 FAQ](#-faq)

</div>

---

## ✨ Что умеет этот проект

<table>
<tr>
<td width="50%">

### 🛡️ Anti-OOM защита
Обрабатывает 60 000+ нод через математическое сэмплирование — роутер никогда не держит в памяти более ~4500 записей одновременно.

### ⚡ Smart Fast-Check
Перед полным сканированием проверяет текущий пул. Если **70% нод живы** — пайплайн пропускается. Экономит ресурс флешки и CPU.

### 🔒 Параноидальный режим
Автоматически вырезает VLESS без TLS и Shadowsocks без шифрования ещё до тестирования. Только современный **AEAD**.

</td>
<td width="50%">

### 🗺️ Матрица приоритетов
Двумерная система сортировки: по **протоколу** или по **стране**. Вы выбираете что важнее — мощность шифра или минимальный пинг.

### 🔄 Zero-Downtime Reload
Новый конфиг применяется мгновенно через `jq`-мёрдж + горячая замена процесса. Текущие соединения не рвутся.

### 🧩 Авто-декодер подписок
Прозрачно обрабатывает Base64-подписки и очищает мусор (`\0`, `\r`), который ломает встроенный `grep` прошивки Padavan.

</td>
</tr>
</table>

---

## 📦 Состав проекта

| Файл | Назначение |
|:---|:---|
| `scripts/update.sh` | 🔧 **Главный движок** — весь пайплайн от скачивания до применения |
| `scripts/gen_links2.sh` | 🔗 **Генератор ссылок** — готовые URI для клиентов в локальной сети |
| `scripts/converter.lua` | ⚙️ **Парсер URI** — конвертирует `ss://`, `vless://` и др. в формат Sing-Box |
| `scripts/utils.lua` | 🛠️ Вспомогательные функции для конвертера |
| `templates/conf3_final.json` | 📋 **Эталонный конфиг** — шаблон с инбаундами и роутингом |

---

## 🚀 Быстрый старт

### Вариант А — однострочный установщик

```bash
wget -O- https://raw.githubusercontent.com/Sophiedevops/singbox-padavan-easy-crawler-2/main/install.sh | sh
```

Установщик сам скачает бинарник, скрипты, конфиг-шаблон, пропишет автозапуск и сделает первый прогон.

---

### Вариант Б — ручная установка

```bash
# Подключитесь к роутеру по SSH
ssh admin@192.168.1.1

# Перейдите в рабочую директорию
cd /opt/tmp_sb_ext/sing-box-1.12.12-extended-1.5.1-linux-mipsle

# Скачайте файлы
RAW="https://raw.githubusercontent.com/Sophiedevops/singbox-padavan-easy-crawler-2/main"
wget -O update.sh       "$RAW/scripts/update.sh"
wget -O gen_links2.sh   "$RAW/scripts/gen_links2.sh"
wget -O converter.lua   "$RAW/scripts/converter.lua"
wget -O utils.lua       "$RAW/scripts/utils.lua"
wget -O conf3_final.json "$RAW/templates/conf3_final.json"

chmod +x update.sh gen_links2.sh

# Запуск
./update.sh
```

> **💡 Cron — автообновление каждые 3 дня в 03:00:**
> ```
> 0 3 */3 * * cd /opt/tmp_sb_ext/sing-box-1.12.12-extended-1.5.1-linux-mipsle && ./update.sh >> /opt/tmp/sb_update.log 2>&1
> ```

---

## ⚙️ Настройки

Все параметры — в шапке файла `update.sh`. Вот самые важные:

```bash
WANTED=10                      # Сколько рабочих нод нужно в итоговом конфиге
PERFECT_SPEED_KBPS=800         # Минимальная скорость загрузки для принятия ноды
MIN_FAST_CHECK_SPEED_KBPS=500  # Порог для быстрой проверки текущего пула
MAX_ACCEPTABLE_PING=3000       # Максимальный пинг по Clash API (мс)

FILTER_COUNTRIES="nl de us pl fi"                              # Приоритетные страны
PRIORITY_PROTOCOLS="shadowsocks hysteria2 vless trojan vmess"  # Порядок протоколов
```

---

### 🔒 Режим шифрования (`ENCRYPTION_PRIORITY`)

<details>
<summary><b>Нажмите, чтобы выбрать режим</b></summary>

<br>

| Значение | Режим | Описание |
|:---:|:---:|:---|
| `1` | **Стандартный** | Все протоколы без фильтрации — максимальный охват |
| `2` | **Параноидальный** ⭐ | VLESS без TLS и SS без шифрования вырезаются сразу. Только зашифрованный трафик |
| `3` | **Гибридный** | «Голые» ноды остаются, но уходят в самый конец очереди тестирования |

> Рекомендуется `2` — особенно при использовании публичных баз

</details>

---

### 🗺️ Режим сортировки (`SORT_PRIORITY`)

<details>
<summary><b>Нажмите, чтобы выбрать режим</b></summary>

<br>

| Значение | Логика | Когда выбирать |
|:---:|:---:|:---|
| `0` | **Протокол → Страна** | Сначала все SS из NL, DE, US… затем VLESS из NL, DE, US… | Для слабых роутеров: SS легче шифруется, не жжёт CPU |
| `1` | **Страна → Протокол** | Сначала все протоколы из NL, потом из DE… | Для геймеров: гарантирует минимальный пинг к нужной стране |

**Пример очереди при `SORT=0, ENC=2` (дефолт):**
```
① SS+AEAD из NL  ②  SS+AEAD из DE  ③ SS+AEAD из US ...
④ HY2 из NL      ⑤  HY2 из DE      ⑥ VLESS+TLS из NL ...
⑦ Fallback: зашифрованные ноды из всех остальных стран
```

</details>

---

### 📡 Подписки (`SUBS_LIST`)

<details>
<summary><b>Показать список источников (10 агрегаторов)</b></summary>

<br>

По умолчанию подключены 10 открытых GitHub-репозиториев, суммарная база **60 000+ нод**:

| # | Репозиторий | Протоколы |
|:---:|:---|:---:|
| 1 | `sakha1370/OpenRay` | Mix |
| 2 | `ebrasha/free-v2ray-public-list` | Mix |
| 3 | `V2RayRoot/V2RayConfig` | VLESS |
| 4 | `acymz/AutoVPN` | Mix |
| 5 | `roosterkid/openproxylist` | Mix |
| 6 | `amirkma/proxykma` | Mix |
| 7 | `mahdibland/V2RayAggregator` | Mix |
| 8 | `gongchandang49/TelegramV2rayCollector` | Mix |
| 9 | `SoliSpirit/v2ray-configs` | SS |
| 10 | `LonUp/NodeList` | Mix |

Добавить собственные источники (Telegram-каналы, платные подписки) — достаточно вписать URL в `SUBS_LIST`. Поддерживаются прямые URI и Base64-encoded подписки.

</details>

---

## 🔗 Клиентские ссылки

`gen_links2.sh` читает готовый конфиг и генерирует **URI для всех инбаундов** — чтобы использовать роутер как прокси-шлюз для телефона или ПК в локальной сети.

```bash
./gen_links2.sh
```

<details>
<summary><b>Пример вывода</b></summary>

<br>

```
Detected Router LAN IP: 192.168.1.1

--- HTTP / Mixed ---
http://192.168.1.1:2080#mixed-in

--- SOCKS5 ---
socks5://192.168.1.1:1080#socks5-in

--- Shadowsocks ---
ss://Y2hhY2hhMjAtaWV0Zi1wb2x5MTMwNTpNeVBhc3M=@192.168.1.1:8388#ss-in

--- Hysteria 2 ---
hy2://MyPassword@192.168.1.1:4443?insecure=1#hy2-in

DONE! All links saved to clients.txt
```

</details>

Ссылки совместимы с **v2rayNG** · **NekoBox** · **Hiddify** · **Sing-Box Mobile** · **Karing**

---

## 📋 Требования

| Компонент | Что нужно |
|:---|:---|
| 🔧 Прошивка | Padavan (Asus Merlin-based) или аналог на базе Linux |
| 💾 Хранилище | USB-накопитель с Entware в `/opt/` |
| 📦 Пакеты | `curl wget jq lua openssl-util bash coreutils-sort` |
| ⚙️ Бинарник | `sing-box` сборка `linux-mipsle-softfloat` или `hardfloat` |
| 📄 Конфиг | `conf3_final.json` — шаблон с инбаундами и роутингом (без аутбаундов) |

---

## 🔧 FAQ

<details>
<summary><b>❌ <code>converter.lua crashed</code></b></summary>

`converter.lua` или `utils.lua` отсутствуют в рабочей папке. Если запускаете из другого каталога — скрипт скопирует их автоматически, но только если они лежат рядом с `update.sh`.

</details>

<details>
<summary><b>❌ <code>All subscription links returned empty</code></b></summary>

Роутер не достучался до GitHub. Проверьте DNS:
```bash
nslookup raw.githubusercontent.com
```
Если `sing-box` сам блокирует трафик — временно остановите его и повторите.

</details>

<details>
<summary><b>❌ Все ноды показывают 0 KB/s</b></summary>

Тестовый URL недоступен напрямую. Проверьте:
```bash
curl -Is https://speed.cloudflare.com/__down?bytes=1
```
Должен вернуть `200 OK` без прокси.

</details>

<details>
<summary><b>❌ <code>grep: unknown option</code></b></summary>

Встроенный `grep` прошивки Padavan не поддерживает расширенный синтаксис. Установите GNU grep из Entware:
```bash
opkg install grep
```

</details>

<details>
<summary><b>❌ Скрипт завис</b></summary>

Завис временный тестовый экземпляр `sing-box`. Принудительно завершите:
```bash
killall sing-box
```

</details>

---

## ⚠️ Отказ от ответственности

Скрипт предоставляется **«как есть»** в образовательных целях.

- Публичные прокси из открытых репозиториев **могут логировать трафик** — не передавайте через них чувствительные данные
- Используйте `ENCRYPTION_PRIORITY=2` (режим по умолчанию) для минимизации рисков
- Автор не несёт ответственности за стабильность сторонних прокси-баз

---

<div align="center">

Сделано с любовью к свободной маршрутизации и старым добрым MIPS-роутерам ❤️

**Если проект оказался полезным — поставьте ⭐**

</div>
