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
local tutil = require("lib.table")
local permission = require("lib.permission")


-- 成功したら 200 OK を返す。

for _, v in pairs({"", "r", "w", "rw"}) do
   local perm = permission.new(v)
   if v:find("r") then
      if not perm:read()  then
         return test.response_error("read is not allowed")
      end
   else
      if perm:read()  then
         return test.response_error("read is allowed")
      end
   end
   if v:find("w") then
      if not perm:write()  then
         return test.response_error("write is not allowed")
      end
   else
      if perm:write()  then
         return test.response_error("write is allowed")
      end
   end

   if perm:to_string() ~= v then
      return test.response_error(v .. " -> " .. perm:to_string())
   end

   local perm2 = permission.new(perm:to_string())
   if perm2 ~= perm then
      return test.response_error("failed to equal " .. perm2:to_string() .. " not " .. perm:to_string())
   end
end


ngx.status = ngx.HTTP_OK
return ngx.exit(ngx.status)
