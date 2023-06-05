
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
    http://localhost:9999/api/2/store/
```

Отправка события со сжатием:
```bash
echo '{"asd":"zxc"}' | gzip > json.gz
curl -v \
    --data-binary @json.gz \
    -H "Content-Encoding: gzip" \
    -H 'Content-type: application/json' \
    -H 'X-Sentry-Auth: Sentry sentry_version=7, sentry_client=td-agent, sentry_key=KEY' \
    http://localhost:9999/api/2/store/
```

Отправка `envelope`:
```http request
POST http://localhost:9999/api/{PROJECT_ID}/envelope/?sentry_key={KEY}&sentry_version=7
COntent-type: text/plain

{"event_id":"524a7f126d2140039e6ff34b91e0ab31","sent_at":"2023-06-05T13:28:07.810Z","sdk":{"name":"sentry.javascript.vue","version":"7.54.0"},"trace":{"environment":"production","trace_id":"5faf9b966dd843abb0b40fb6d5f1bd00","sample_rate":"1"}}
{"type":"event"}
{"asd":"asd"}
```
