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


-- 権限読み込みとディレクトリ情報のフィルタリング。

local varutil = require("lib.varutil")


-- $edo_log_level: デバッグログのレベル。
local log_level = varutil.get_level(ngx.var.edo_log_level)
-- $edo_backend_location: バックエンドに処理を渡すための location。
local backend_location = ngx.var.edo_backend_location or "@backend"


-- 読み込みタイプの中に permission が含まれているかどうか。
function contains_permission(rty)
   if not rty then
      return false
   elseif type(rty) == "table" then
      for _, v in pairs(rty) do
         local res = contains_permission(v)
         if res then
            return true
         end
      end
      return false
   end

   for v in rty:gmatch(" ?([^ ]+)") do
      if v == "permission" then
         return true
      end
   end
   return false
end


-- ここから本編。


local args = ngx.req.get_uri_args()
if args.recursive then
   -- 再帰フラグ付き。
   ngx.log(log_level, "detected recursive flag")
   return ngx.exec(backend_location)
elseif contains_permission(args.rty) then
   -- 権限読み取り。
   ngx.log(log_level, "detected permission reading")
   return ngx.exec(backend_location)
end

ngx.log(log_level, "no need to pass to backend")
