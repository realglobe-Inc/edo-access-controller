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


ngx_installer=${ngx_installer:=$(dirname $0)/../../edo-auth/script/install_nginx.sh}
if ! [ -f ${ngx_installer} ]; then
    echo "nginx installer ${ngx_installer} is not exist" 1>&2
    exit 1
fi

project_dir=$(cd $(dirname $0)/.. && pwd)
install_dir=${install_dir:=${project_dir}/root}

install_dir=${install_dir} ${ngx_installer}
