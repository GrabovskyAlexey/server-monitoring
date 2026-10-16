#!/usr/bin/env bash
# Проверяет конфигурацию и (пере)запускает стек. Запускать на сервере из корня репозитория:
#   bash scripts/deploy.sh
set -euo pipefail
cd "$(dirname "$0")/.."

bash scripts/render-alertmanager.sh

echo "Проверка конфигурации Prometheus и правил"
docker run --rm --entrypoint promtool -v "$PWD/prometheus:/etc/prometheus:ro" \
  prom/prometheus:v2.55.1 check config /etc/prometheus/prometheus.yml
echo "Проверка конфигурации Alertmanager"
docker run --rm --entrypoint amtool -v "$PWD/alertmanager:/etc/alertmanager:ro" \
  prom/alertmanager:v0.27.0 check-config /etc/alertmanager/alertmanager.yml

docker compose pull
docker compose up -d
# Prometheus подхватывает изменения конфига и правил без пересоздания контейнера
curl -fsS -X POST http://127.0.0.1:9091/-/reload || true
docker compose ps
