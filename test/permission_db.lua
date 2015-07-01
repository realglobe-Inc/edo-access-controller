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

local mysql_wrapper = require("lib.mysql_wrapper")
local tutil = require("lib.table")
local permission = require("lib.permission")
local permission_db = require("lib.permission_db")


-- mysql_host: mysql のホスト名。
-- mysql_port: mysql のポート番号。
-- mysql_path: mysql の Unix ソケットパス。
-- mysql_database: mysql のデータベース名。
-- mysql_user: mysql のユーザー名。
-- 事前に "owner", "master", "/p/a/t/h", "user", "from" に "r" を付与しておくこと。
-- 成功したら 200 OK を返す。

local client, err = mysql_wrapper.new(
   {
      host = ngx.var.mysql_host,
      port = ngx.var.mysql_port,
      path = ngx.var.mysql_path,
      database = ngx.var.mysql_database,
      user = ngx.var.mysql_user,
   }, 1000, 10 * 1000, 16)
if err then
   return test.response_error("mysql_wrapper.new failed: " .. err)
end
local db, err = permission_db.new_mysql(client)
if err then
   return test.response_error("new failed: " .. err)
end


local perm, err = db:get("owner", "master", "/p/a/t/h", "user", "from")
if err then
   return test.response_error("get failed: " .. err)
elseif not perm:read() then
   return test.response_error("read not allowed")
elseif perm:write() then
   return test.response_error("write allowed")
end

ngx.status = ngx.HTTP_OK
return ngx.exit(ngx.status)
