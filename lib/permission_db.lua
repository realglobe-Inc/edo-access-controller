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

local cjson = require("cjson.safe")
local permission = require("lib.permission")


-- 権限 DB。
-- バックエンドのデータもこのプログラム専用の前提。
-- "r" or "w" or "rw"

-- メソッド定義。
local db_mysql = {

   -- 取得。
   get = function(self, owner, master, path, user, from)
      local _, err = self.mysql:connect()
      if err then
         return nil, err
      end

      local query = "CALL GetPermission("
         .. ngx.quote_sql_str(owner) .. ","
         .. ngx.quote_sql_str(master) .. ","
         .. ngx.quote_sql_str(path) .. ","
         .. ngx.quote_sql_str(user) .. ","
         .. ngx.quote_sql_str(from) .. ",@permission); SELECT @permission AS permission;"

      local res, err, errcode, sqlstate = self.mysql.base:query(query)
      self.mysql:close()
      if not res then
         return nil, err .. ": " .. errcode .. ": " .. sqlstate
      elseif err ~= 'again' then
         return nil, "cannot get permission"
      end

      local res, err, errcode, sqlstate = self.mysql.base:read_result()
      if not res then
         return nil, err .. ": " .. errcode .. ": " .. sqlstate
      elseif res == ngx.null then
         -- 無かった。
         return nil
      end

      local elem = res[1]
      if not elem then
         -- 無かった。
         return nil
      end
      return permission.new(elem.permission)
   end,
}


-- mysql ドライバとテーブルを指定して作成する。
new_mysql = function(mysql)
   local obj = {
      mysql = mysql,
   }
   setmetatable(obj, {__index = db_mysql})
   return obj
end


return {
   new_mysql = new_mysql,
}
