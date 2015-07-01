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


# nginx -s reload が反映されるのを sleep して待つ期間。
INTERVAL=0.5

MYSQL_DATABASE=${MYSQL_DATABASE:="edo_test"}
MYSQL_USER=${MYSQL_USER:="root"}

PROJECT_DIR=$(cd $(dirname $0)/.. && pwd)

WORK_DIR=${WORK_DIR:=/tmp/edo-access-controller-test}
NGINX_DIR=${NGINX_DIR:=${PROJECT_DIR}/root/opt/nginx}

if ! [ -f ${NGINX_DIR}/sbin/nginx ]; then
    echo "no nginx in ${NGINX_DIR}" 1>&2
    exit 1
fi

NGINX_PORT=${NGINX_PORT:=7000}
while nc -z localhost ${NGINX_PORT}; do
    NGINX_PORT=$((${NGINX_PORT} + 1))
done


if ! [ -d ${WORK_DIR} ]; then
    mkdir -p ${WORK_DIR}
    echo "${WORK_DIR} was created"
fi

UPPER_LIB_DIR=${UPPER_LIB_DIR:=$(dirname $0)/../../edo-auth/lib}
if ! [ -d ${UPPER_LIB_DIR} ]; then
    echo "upper library directory ${UPPER_LIB_DIR} is not exist" 1>&2
    exit 1
fi
UPPER_LIB_DIR=$(cd ${UPPER_LIB_DIR} && pwd)

UPPER_TEST_DIR=${UPPER_TEST_DIR:=$(dirname $0)/../../edo-auth/test}
if ! [ -d ${UPPER_TEST_DIR} ]; then
    echo "upper test directory ${UPPER_TEST_DIR} is not exist" 1>&2
    exit 1
fi
UPPER_TEST_DIR=$(cd ${UPPER_TEST_DIR} && pwd)


(cd ${WORK_DIR}

 nginx_prefix=${WORK_DIR}/nginx
 mkdir -p ${nginx_prefix}/conf
 mkdir -p ${nginx_prefix}/logs
 mkdir -p ${nginx_prefix}/lua/lib
 mkdir -p ${nginx_prefix}/lua/test
 cp ${PROJECT_DIR}/*.lua ${nginx_prefix}/lua/
 for lib in erro.lua table.lua varutil.lua; do
     cp ${UPPER_LIB_DIR}/${lib} ${nginx_prefix}/lua/lib/
 done
 cp ${PROJECT_DIR}/lib/*.lua ${nginx_prefix}/lua/lib/
 for lib in test.lua; do
     cp ${UPPER_TEST_DIR}/${lib} ${nginx_prefix}/lua/test/
 done
 cp ${PROJECT_DIR}/test/*.lua ${nginx_prefix}/lua/test/

 cat ${PROJECT_DIR}/script/create_table.sql | sed 's/edo/'${MYSQL_DATABASE}'/g' | mysql -u ${MYSQL_USER}
 cat ${PROJECT_DIR}/script/create_procedure.sql | sed 's/edo/'${MYSQL_DATABASE}'/g' | mysql -u ${MYSQL_USER}

 cat <<EOF > ${nginx_prefix}/conf/nginx.conf
events {}
http {
    lua_package_path '\${prefix}lua/?.lua;;';
    server {
        listen       ${NGINX_PORT};
        location / {
        }
    }
}
EOF
 ${NGINX_DIR}/sbin/nginx -p ${nginx_prefix}
 close_script="${NGINX_DIR}/sbin/nginx -p ${nginx_prefix} -s stop"
 trap "${close_script}" EXIT

 while ! nc -z localhost ${NGINX_PORT}; do
     sleep ${INTERVAL}
 done

 # nginx が立った。


 # ############################################################
 cat <<EOF > ${nginx_prefix}/conf/nginx.conf
events {}
http {
    lua_package_path '\${prefix}lua/?.lua;;';
    server {
        listen       ${NGINX_PORT};
        location / {
            set \$mysql_host 127.0.0.1;
            set \$mysql_database ${MYSQL_DATABASE};
            set \$mysql_user ${MYSQL_USER};
            access_by_lua_file lua/test/mysql_wrapper.lua;
        }
    }
}
EOF
 ${NGINX_DIR}/sbin/nginx -p ${nginx_prefix} -s reload
 sleep ${INTERVAL}

 result=$(curl -o out -s -w "%{http_code}" http://localhost:${NGINX_PORT})
 if [ "${result}" != "200" ]; then
     echo ${result} 1>&2
     cat out 1>&2
     exit 1
 fi
 echo "===== mysql passed ====="


 # ############################################################
 cat <<EOF > ${nginx_prefix}/conf/nginx.conf
events {}
http {
    lua_package_path '\${prefix}lua/?.lua;;';
    server {
        listen       ${NGINX_PORT};
        location / {
            access_by_lua_file lua/test/permission.lua;
        }
    }
}
EOF
 ${NGINX_DIR}/sbin/nginx -p ${nginx_prefix} -s reload
 sleep ${INTERVAL}

 result=$(curl -o out -s -w "%{http_code}" http://localhost:${NGINX_PORT})
 if [ "${result}" != "200" ]; then
     echo ${result} 1>&2
     cat out 1>&2
     exit 1
 fi
 echo "===== permission passed ====="


 # ############################################################
 echo "USE ${MYSQL_DATABASE}; INSERT INTO access_right VALUES('owner_master', '/p/a/t/h', 'user_from', 'r')" | mysql -u ${MYSQL_USER}
 cat <<EOF > ${nginx_prefix}/conf/nginx.conf
events {}
http {
    lua_package_path '\${prefix}lua/?.lua;;';
    server {
        listen       ${NGINX_PORT};
        location / {
            set \$mysql_host 127.0.0.1;
            set \$mysql_database ${MYSQL_DATABASE};
            set \$mysql_user ${MYSQL_USER};
            access_by_lua_file lua/test/permission_db.lua;
        }
    }
}
EOF
 ${NGINX_DIR}/sbin/nginx -p ${nginx_prefix} -s reload
 sleep ${INTERVAL}

 result=$(curl -o out -s -w "%{http_code}" http://localhost:${NGINX_PORT})
 if [ "${result}" != "200" ]; then
     echo ${result} 1>&2
     cat out 1>&2
     exit 1
 fi
 echo "===== user session DB passed ====="
)

echo "===== all test passed ====="
