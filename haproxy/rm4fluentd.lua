
-- создание ответа на плохой запрос
local function make_bad_response(txn, reason)
  local reply = txn:reply()
  reply:set_status(400, 'Bad request')
  reply:add_header('content-type', 'text/plain')
  reply:add_header('cache-control', 'no-cache')
  reply:add_header('cache-control', 'no-store')
  reply:add_header('handler', 'lua')
  reply:set_body(reason)
  return reply;
end

-- обработчик запроса
local function rm4fluentd(txn)

  --извлечение projectId из пути запроса
  local projectId = string.match(txn.sf:path(), '/api/(%d+)/store');
  if (projectId == nil) then
    local err = 'path projectId is nil'
    core.Alert(err)
    txn:done(make_bad_response(txn, err))
    return
  end

  -- извеление заголовка авторизации для sentry
  local headerAuth = txn.http:req_get_headers()['x-sentry-auth'];
  if (headerAuth == nil) then
    local err = 'header x-sentry-auth not found'
    core.Alert(err)
    txn:done(make_bad_response(txn, err))
    return
  end
  headerAuth = headerAuth[0];

  -- извлечение ключа для проекта
  local key = string.match(headerAuth, 'sentry_key%s*=%s*(%w+)');
  if (key == nil) then
    local err = 'sentry_key not found in header x-sentry-auth'
    core.Alert(err)
    txn:done(make_bad_response(txn, err))
    return
  end

  -- формирование и подмена пути для fluentd
  local newPath = '/sentry.' .. projectId .. '.' .. key;
  core.Info('new path: ' .. newPath);
  txn.http:req_set_path(newPath);
end

--##########################################################################

core.register_action('rm4fluentd', {'http-req'}, rm4fluentd, 0)
