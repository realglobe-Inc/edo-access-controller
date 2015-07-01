#!/bin/sh -e

# Copyright 2015 realglobe, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Lua に対応した nginx と Lua ライブラリがインストール済みとして、
# edo-access-controller をインストールする。

upper_lib_dir=${upper_lib_dir:=$(dirname $0)/../../edo-auth/lib}
if ! [ -d ${upper_lib_dir} ]; then
    echo "upper library directory ${upper_lib_dir} is not exist" 1>&2
    exit 1
fi
upper_lib_dir=$(cd ${upper_lib_dir} && pwd)

project_dir=$(cd $(dirname $0)/.. && pwd)

install_dir=${install_dir:=${project_dir}/root}
# フルパスにする。
if ! [ -d ${install_dir} ]; then
    mkdir -p ${install_dir}
    echo "${install_dir} was created"
fi
install_dir=$(cd ${install_dir} && pwd)
nginx_dir=${nginx_dir:=${install_dir}/opt/nginx}


if ! [ -d ${nginx_dir}/lua/lib ]; then
    mkdir -p ${nginx_dir}/lua/lib
fi
cp ${project_dir}/*.lua ${nginx_dir}/lua/
cp ${project_dir}/lib/*.lua ${nginx_dir}/lua/lib/
for lib in erro.lua table.lua varutil.lua; do
    cp ${upper_lib_dir}/${lib} ${nginx_dir}/lua/lib/
done


echo "---------- edo-access-controller was installed in ${install_dir} ----------"
