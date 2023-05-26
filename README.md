
# Транспортировка событий в Sentry через HAProxy + td-agent

## Схема работы

* Приложение отправляет сформированный для `Sentry` запрос на `HAProxy`
* `HAProxy` преобразовывает в понятные данные для `td-agent`
* `td-agent` преобразовывает в понятные данные для `Sentry` и отправлет в `Sentry` если сервер доступен, иначе ждет доступности

## Запуск и тестирование

Запуск инфраструктуры:
```bash
$ export SENTRY_ADDR="https://sentry.domain:port"
$ docker compose up
```

Отправка события без сжатия:
```bash
curl -v \
    -d '{"asd":"zxc"}' \
    -H 'Content-type: application/json' \
    -H 'X-Sentry-Auth: Sentry sentry_version=7, sentry_client=td-agent, sentry_key=KEY' \
    http://localhost:9999/api/2/store
```

Отправка события со сжатием:
```bash
echo '{"asd":"zxc"}' | gzip > json.gz
curl -v \
    --data-binary @json.gz \
    -H "Content-Encoding: gzip" \
    -H 'Content-type: application/json' \
    -H 'X-Sentry-Auth: Sentry sentry_version=7, sentry_client=td-agent, sentry_key=KEY' \
    http://localhost:9999/api/2/store
```
