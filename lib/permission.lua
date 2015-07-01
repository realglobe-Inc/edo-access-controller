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


-- 権限。

-- メソッド定義。
local permission = {

   -- 読み込み権限があるかどうか。
   read = function(self)
      return self.r
   end,

   -- 書き込み権限があるかどうか。
   write = function(self)
      return self.w
   end,

   to_string = function(e)
      if e.r then
         if e.w then
            return "rw"
         else
            return "r"
         end
      elseif e.w then
         return "w"
      else
         return ""
      end
   end,
}

local equal = function(o1, o2)
   return o1.r == o2.r
      and o1.w == o2.w
end

-- 権限を作成する。
local new = function(perm_str)
   local obj = {}
   if perm_str == "rw" then
      obj.r = true
      obj.w = true
   elseif perm_str == "r" then
      obj.r = true
   elseif perm_str == "w" then
      obj.w = true
   end
   setmetatable(obj, {
                   __index = permission,
                   __eq = equal,
   })
   return obj
end

return {
   new = new,
}
