
local app = {}

-- создание ответа на плохой запрос
app.make_bad_response = function(txn, reason)
  local reply = txn:reply()
  reply:set_status(400, 'Bad request')
  reply:add_header('content-type', 'text/plain')
  reply:add_header('cache-control', 'no-cache')
  reply:add_header('cache-control', 'no-store')
  reply:add_header('handler', 'lua')
  reply:set_body(reason)
  return reply;
end

-- выход из приложения с отдачей http ответа
app.exit = function(txn, err)
  core.Alert(err)
  txn:done(app.make_bad_response(txn, err))
end

-- если v == (false | nil) тогда выход из приложения с отдачей http ответа
app.assert = function(txn, v, msg)
  if (v == false or v == nil) then
    app.exit(txn, msg)
  end
end

----------------------------------------------------------------------------

-- обработчик запроса
local function rm4fluentd(txn)
  core.Info("url: " .. txn.f:url())
  -- извлечение id проекта и типа сообщения (store || envelope) из пути запроса
  local project_id, type_msg = string.match(txn.sf:path(), '/api/(%d+)/(%w+)/')
  app.assert(txn, project_id, 'path project_id is nil')
  app.assert(txn, type_msg, 'type_msg is nil, expected store or envelope')

  -- ключ проекта в sentry
  local sentry_key = nil

  -- извлечение заголовка авторизации для sentry
  local header_auth = txn.http:req_get_headers()['x-sentry-auth']
  if (header_auth ~= nil) then
    header_auth = header_auth[0];
    local key = string.match(header_auth, 'sentry_key%s*=%s*(%w+)')
    if (key ~= nil) then
      sentry_key = key
    end
  end

  -- извлечение sentry_key из пути запроса (для tunnel)
  local path_key = string.match(txn.sf:path(), '/api/%d+/%w+/(%w+)')
  if (path_key ~= nil) then
    sentry_key = path_key
  end

  -- извлечение sentry_key из параметров запроса
  local query_key = string.match(txn.sf:url(), 'sentry_key=(%w+)')
  if (query_key ~= nil) then
    sentry_key = query_key
  end

  -- если все-таки не удалось найти sentry_key тогда уходим
  app.assert(txn, sentry_key, 'sentry_key not found in header or path')

  -- формирование и подмена пути для fluentd
  local new_path = '/sentry.' .. type_msg .. '.' .. project_id .. '.' .. sentry_key
  core.Info('new path: ' .. new_path)
  txn.http:req_set_path(new_path)
end

--##########################################################################

core.register_action('rm4fluentd', {'http-req'}, rm4fluentd, 0)
