# server-monitoring

Мониторинг одного VPS и работающих на нём приложений (сейчас — Telegram-бот Drink Me): Prometheus, Alertmanager (алерты в Telegram), Grafana, node_exporter и cAdvisor.

Всё работает в сети хоста и слушает только `127.0.0.1`, наружу порты не выставлены. Grafana открывается по SSH-туннелю.

| Сервис | Адрес на сервере | Назначение |
|---|---|---|
| Prometheus | `127.0.0.1:9091` | сбор метрик, хранение 15 дней, правила алертов |
| Alertmanager | `127.0.0.1:9093` | отправка алертов в Telegram |
| Grafana | `127.0.0.1:3001` | дашборды «Сервер», «Контейнеры», «Drink Me» |
| node_exporter | `127.0.0.1:9100` | метрики сервера (CPU, память, диск, сеть) |
| cAdvisor | `127.0.0.1:8081` | метрики Docker-контейнеров |
| drinkmebot | `127.0.0.1:8019/actuator/prometheus` | метрики бота (порт — `USE_PORT` в `~/drinkmebot/.env`) |

## Установка на сервере

1. Создайте отдельного бота для алертов в @BotFather и напишите ему `/start` (иначе он не сможет вам писать). Свой id узнайте у @userinfobot.
2. Клонируйте репозиторий и создайте `.env`:
   ```bash
   git clone <url> ~/server-monitoring && cd ~/server-monitoring
   cp .env.example .env && chmod 600 .env
   nano .env   # GRAFANA_ADMIN_PASSWORD, TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID
   ```
3. Перед первым запуском убедитесь, что порты свободны: `ss -ltn | grep -E ':(9091|9093|3001|9100|8081)\b'` не должно ничего выводить.
4. Запустите: `bash scripts/deploy.sh`. Скрипт создаёт `alertmanager/alertmanager.yml` из шаблона и `.env`, проверяет конфигурацию (`promtool`, `amtool`), поднимает стек и перечитывает конфиг Prometheus.
5. Проверка: `curl -s 127.0.0.1:9091/api/v1/targets | grep -o '"health":"[a-z]*"' | sort | uniq -c` — все цели `up`.

Токен бота лежит только в `.env` и в сгенерированном `alertmanager/alertmanager.yml` (оба в `.gitignore`).

## Grafana через SSH-туннель

```bash
ssh -p 2242 -L 3001:127.0.0.1:3001 <user>@<сервер>
```

Затем откройте http://localhost:3001, логин `admin`, пароль из `GRAFANA_ADMIN_PASSWORD`. Дашборды создаются автоматически из `grafana/dashboards/*.json` (правка в интерфейсе запрещена, чтобы источником правды остался git: меняйте JSON и выкладывайте заново).

## Алерты

Правила — `prometheus/alerts.yml`: цель не отдаёт метрики, критичный контейнер пропал или перезапускается, мало памяти, OOM, диск больше 85%, CPU больше 90%, ошибки и медленные ответы бота, куча JVM и пул БД. Проверить доставку: остановите бота (`docker stop drinkmebot`, не забудьте вернуть) и через ~3 минуты придёт сообщение `TargetDown`.

Список критичных контейнеров (`ContainerGone`) — отдельные правила в `alerts.yml`; новый контейнер добавляется копией правила.

## Подключение нового приложения (например, poi-bot)

1. В приложении подключите Micrometer Prometheus и откройте `/actuator/prometheus` только на `127.0.0.1` (как в drink-me-bot: профиль `prod`, `management.endpoints.web.exposure.include: health,prometheus`, `server.address: 127.0.0.1`), общий тег `application`.
2. Добавьте `job` в `prometheus/prometheus.yml` (образец в комментарии файла) с портом приложения.
3. `bash scripts/deploy.sh`.

## Обновление

`git pull && bash scripts/deploy.sh`. Версии образов зафиксированы в `compose.yaml`; обновляйте их осознанно.

## Что не покрыто

- Логи (Loki) — не поставлены: у бота небольшой лог, хватает `docker logs`.
- Если упадёт сам сервер или Prometheus, алерт не придёт: внешней проверки («dead man's switch») нет. При необходимости добавьте внешний ping (например, UptimeRobot на публичный адрес).
