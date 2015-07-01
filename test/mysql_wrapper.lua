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

local test = require("test.test")
local mysql_wrapper = require("lib.mysql_wrapper")


-- mysql_host: mysql のホスト名。
-- mysql_port: mysql のポート番号。
-- mysql_path: mysql の Unix ソケットパス。
-- mysql_database: mysql のデータベース名。
-- mysql_user: mysql のユーザー名。
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
   return test.response_error("new failed: " .. err)
end

local _, err = client:connect()
if err then
   return test.response_error("connect failed: " .. err)
end

local res, err, errcode, sqlstate = client.base:query("show databases")
if err then
   return test.response_error("query failed: " .. err .. ": " .. errno .. ": " .. sqlstate)
end

local _, err = client:close()
if err then
   return test.response_error("close failed: " .. err)
end


ngx.status = ngx.HTTP_OK
return ngx.exit(ngx.status)
