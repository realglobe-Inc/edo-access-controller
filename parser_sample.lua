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


-- リクエストからリソース識別子 (アカウント、TA、パス) とアクセス元 (アカウント、TA) を特定する。


-- パスからリソース識別子、ヘッダからアクセス元を特定する。
-- /p/r/e/f/i/x/owner/master/p/a/t/h
-- X-User: user
-- X-From: from
local function parse_sample(prefix)
   local path = ngx.var.request_uri -- ngx.var.uri はなぜかデコードしてある。

   local pos = path:find('?', 1, true)
   if pos then
      path = path:sub(1, pos - 1)
   end

   if prefix then
      if path:len() <= prefix:len() then
         return nil, nil, nil, nil, nil, 'too short path'
      elseif path:sub(1, prefix:len()) ~= prefix then
         return nil, nil, nil, nil, nil, 'invalid path: not prefix'
      else
         path = path:sub(prefix:len() + 1)
      end
   end

   if path:sub(1, 1) ~= '/' then
      return nil, nil, nil, nil, nil, 'invalid path: no head slash'
   end
   path = path:sub(2)

   local pos = path:find('/', 1, true)
   if not pos then
      return nil, nil, nil, nil, nil, 'invalid path: no slash after owner'
   end
   local owner = path:sub(1, pos - 1)
   path = path:sub(pos + 1)

   local pos = path:find('/', 1, true)
   if not pos then
      return nil, nil, nil, nil, nil, 'invalid path: no slash after master'
   end
   local master = ngx.unescape_uri(path:sub(1, pos - 1))
   path = path:sub(pos)

   local user = ngx.var.http_x_user or ""
   local from = ngx.var.http_x_from or ""

   return owner, master, path, user, from
end


return {
   parse = parse_sample,
}
