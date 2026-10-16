# Repository Guidelines
- Всегда общайся и веди заметки на русском языке.
- Все файлы сохраняй в кодировке UTF-8 без BOM.
- Не выполняй коммиты без моего явного запроса; такие запросы считаю разовыми, а не постоянными.
- Коммиты — на английском, в повелительном наклонении.
- Секреты (`.env`, токены, сгенерированный `alertmanager/alertmanager.yml`) не коммитим.

Стек мониторинга сервера (Prometheus, Alertmanager, Grafana, node_exporter, cAdvisor), описание — в `README.md`.
Всё слушает только `127.0.0.1`, наружу порты не открываем; Grafana — по SSH-туннелю.

## Проверка конфигурации
- Prometheus и правила: `docker run --rm --entrypoint promtool -v "$PWD/prometheus:/etc/prometheus:ro" prom/prometheus:v2.55.1 check config /etc/prometheus/prometheus.yml`
- Дашборды Grafana — JSON в `grafana/dashboards/`, источник данных с uid `prometheus`.
- Выкладка на сервер — `bash scripts/deploy.sh`.
