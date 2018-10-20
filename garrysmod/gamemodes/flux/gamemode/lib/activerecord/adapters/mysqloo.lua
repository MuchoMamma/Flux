class 'ActiveRecord::Adapters::Mysqloo' extends 'ActiveRecord::Adapters::Abstract'

ActiveRecord.Adapters.Mysqloo.types = {
  primary_key = 'bigint(20) NOT NULL AUTO_INCREMENT',
  string = 'varchar(255)',
  text = 'text',
  integer = 'bigint(20)',
  float = 'float',
  decimal = 'decimal',
  datetime = 'datetime',
  timestamp = 'datetime',
  time = 'time',
  date = 'date',
  binary = 'blob',
  boolean = 'tinyint(1)',
  json = 'text'
}

ActiveRecord.Adapters.Mysqloo._sql_syntax = 'mysql'

function ActiveRecord.Adapters.Mysqloo:init()
  require('mysqloo')
end

function ActiveRecord.Adapters.Mysqloo:is_mysql()
  return true
end

function ActiveRecord.Adapters.Mysqloo:connect(config)
  local host, user, password, port, database, socket, flags = config.host, config.user, config.password, config.port, config.database, config.socket, config.flags

  if !port then
    port = 3306
  end

  if mysqloo then
    local client_flag = flags or 0

    if !isstring(socket) then
      self.connection = mysqloo.connect(host, user, password, database, port)
    else
      self.connection = mysqloo.connect(host, user, password, database, port, socket, client_flag)
    end

    self.connection.onConnected = function(database)
      local success, error_message = database:setCharacterSet(ActiveRecord.db_settings.encoding or 'utf8')

      if !success then
        ErrorNoHalt('ActiveRecord - Failed to set MySQL encoding to UTF-8!\n')
        ErrorNoHalt(error_message..'\n')
      end
      self:on_connected()
    end

    self.connection.onConnectionFailed = function(database, error_text)
      self:on_connection_failed(error_text)
    end

    self.connection:connect()

    timer.Create("Mysqloo#keep_alive", 300, 0, function()
      self.connection:ping()
    end)
  else
    ErrorNoHalt('ActiveRecord - MySQLOO is not found!\nPlease make sure you have gmsv_mysqloo in your lua/bin folder!\n')
  end
end

function ActiveRecord.Adapters.Mysqloo:disconnect()
  if self.connection then
    self.connection:disconnect(true)
  end
  self.connection = nil
end

function ActiveRecord.Adapters.Mysqloo:escape(str)
  return self.connection:escape(str)
end

function ActiveRecord.Adapters.Mysqloo:quote_name(str)
  return '`'..str..'`'
end

function ActiveRecord.Adapters.Mysqloo:raw_query(query, callback, flags, ...)
  if !self.connection then
    return self:queue(query)
  end

  local query_obj = self.connection:query(query)
  local query_start = os.clock()
  local success_func = function(query_obj, result)
    if callback then
      for k, v in pairs(result) do
        if isstring(v) then
          result[k] = self:unescape(v)
        end
      end

      local status, a, b, c, d = pcall(callback, result, query, math.Round(os.clock() - query_start, 3))

      if !status then
        ErrorNoHalt('ActiveRecord - MySQL Callback Error!\n')
        ErrorNoHalt(a..'\n')
      end

      return a, b, c, d
    end
  end

  query_obj:setOption(mysqloo.OPTION_NAMED_FIELDS)
  query_obj.onSuccess = success_func
  query_obj.onError = function(query_obj, error_text)
    ErrorNoHalt('ActiveRecord - MySQL Query Error!\n')
    ErrorNoHalt('Query: '..query..'\n')
    ErrorNoHalt(error_text..'\n')
  end
  if self._sync then
    query_obj.onSuccess = nil
    query_obj:start()
    query_obj:wait(true)

    local data = query_obj:getData()

    if data then
      return success_func(query_obj, data)
    end
  else
    query_obj:start()
  end
end

function ActiveRecord.Adapters.Mysqloo:append_query(query, query_type, queue)
  query.options = 'ENGINE=InnoDB DEFAULT CHARSET='..(ActiveRecord.db_settings.encoding or 'utf8')
end

function ActiveRecord.Adapters.Mysqloo:create_column(query, column, args, obj, type, def)
  if type == 'primary_key' then
    query:set_primary_key(column)
  end
end
