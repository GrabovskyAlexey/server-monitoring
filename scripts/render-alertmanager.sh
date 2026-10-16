#!/usr/bin/env bash
# Создаёт alertmanager/alertmanager.yml из шаблона и .env (TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID).
set -euo pipefail
cd "$(dirname "$0")/.."

[ -f .env ] || { echo "Нет файла .env (образец: .env.example)" >&2; exit 1; }
set -a
# shellcheck disable=SC1091
. ./.env
set +a
: "${TELEGRAM_BOT_TOKEN:?задайте TELEGRAM_BOT_TOKEN в .env}"
: "${TELEGRAM_CHAT_ID:?задайте TELEGRAM_CHAT_ID в .env}"

umask 077
sed -e "s|__TELEGRAM_BOT_TOKEN__|${TELEGRAM_BOT_TOKEN}|" \
    -e "s|__TELEGRAM_CHAT_ID__|${TELEGRAM_CHAT_ID}|" \
    alertmanager/alertmanager.yml.tmpl > alertmanager/alertmanager.yml
# контейнер Alertmanager работает от nobody и должен прочитать файл
chmod 644 alertmanager/alertmanager.yml
echo "alertmanager/alertmanager.yml создан"
