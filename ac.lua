-- Copyright 2015 realglobe, Inc.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.


-- アクセス制御。

local varutil = require("lib.varutil")
local erro = require("lib.erro")
local mysql_wrapper = require("lib.mysql_wrapper")
local permission = require("lib.permission")
local permission_db = require("lib.permission_db")


-- $edo_log_level: デバッグログのレベル。
local log_level = varutil.get_level(ngx.var.edo_log_level)
-- $edo_path_prefix: パスの接頭辞。
local path_prefix = ngx.var.edo_path_prefix or ""
-- $edo_force_user: user が必須かどうか。
local force_user = varutil.get_boolean(ngx.var.edo_force_user, true)
-- $edo_force_from: from が必須かどうか。
local force_from = varutil.get_boolean(ngx.var.edo_force_from, true)
-- $edo_mysql_host: mysql のホスト名。
local mysql_host = ngx.var.edo_mysql_host or "127.0.0.1"
-- $edo_mysql_port: mysql のポート。
local mysql_port = ngx.var.edo_mysql_port
-- $edo_mysql_path: mysql の UNIX ソケット。
local mysql_path = ngx.var.edo_mysql_path
-- $edo_mysql_database: mysql のデータベース名。
local mysql_database = ngx.var.edo_mysql_database or "edo"
-- $edo_mysql_user: mysql のユーザー名。
local mysql_user = ngx.var.edo_mysql_user or "root"
-- $edo_mysql_password: mysql のパスワード。
local mysql_password = ngx.var.edo_mysql_password
-- $edo_mysql_timeout: mysql の接続待ち時間 (ミリ秒)。
local mysql_timeout = ngx.var.edo_mysql_timeout or 30 * 1000 -- 30 秒。
-- $edo_mysql_keepalive: mysql ソケットの待機時間 (ミリ秒)。
local mysql_keepalive = ngx.var.edo_mysql_keepalive or 60 * 1000 -- 1 分。
-- $edo_mysql_pool_size: 1 ワーカー当たりの mysql ソケット確保数。
local mysql_pool_size = ngx.var.edo_mysql_pool_size or 16

-- $edo_lib_parser: リクエストからリソースとアクセス元を特定するモジュール名。
local lib_parser = ngx.var.edo_parser or "parser_sample"
local parser = require(lib_parser)


-- ここから本編。


local owner, master, path, user, from, err = parser.parse(path_prefix)
if err then
   return erro.respond_json({status = ngx.HTTP_BAD_REQUEST, message = "request error: " .. err})
elseif force_user and (not user or user == "") then
   return erro.respond_json({status = ngx.HTTP_BAD_REQUEST, message = "no user"})
elseif force_from and (not from or from == "") then
   return erro.respond_json({status = ngx.HTTP_BAD_REQUEST, message = "no from"})
end


ngx.log(log_level, "parsed request: "
           .. owner .. ", "
           .. master .. ", "
           .. path .. ", "
           .. user .. ", "
           .. from)

local mysql, err = mysql_wrapper.new(
   {
      host = mysql_host,
      port = mysql_port,
      path = mysql_path,
      database = mysql_database,
      user = mysql_user,
      password = mysql_password,
   }, mysql_timeout, mysql_keepalive, mysql_pool_size)
if err then
   return erro.respond_json({status = ngx.HTTP_INTERNAL_SERVER_ERROR, message = "database error: " .. err})
end
local database = permission_db.new_mysql(mysql, mysql_table)

local right, err = database:get(owner, master, path, user, from)
if err then
   return erro.respond_json({status = ngx.HTTP_INTERNAL_SERVER_ERROR, message = "database error: " .. err})
elseif not right then
   -- 権限が無かった。
   return erro.respond_json({status = ngx.HTTP_FORBIDDEN, message = "permission denied: no rights"})
end

ngx.log(ngx.ERR, "permission is " .. right:to_string())

local method = ngx.req.get_method()
if method == "GET" or method == "HEAD" then
   if not right:read() then
      return erro.respond_json({status = ngx.HTTP_FORBIDDEN, message = "permission denied: read"})
   end
else
   if not right:write() then
      return erro.respond_json({status = ngx.HTTP_FORBIDDEN, message = "permission denied: write"})
   end
end

ngx.log(log_level, "access allowed")
