// Copyright 2015 realglobe, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main

import (
	"github.com/realglobe-Inc/edo-access-controller/api/read"
	"github.com/realglobe-Inc/edo-access-controller/database/permission"
	"github.com/realglobe-Inc/edo-lib/driver"
	logutil "github.com/realglobe-Inc/edo-lib/log"
	"github.com/realglobe-Inc/edo-lib/server"
	"github.com/realglobe-Inc/go-lib/erro"
	"github.com/realglobe-Inc/go-lib/rglog"
	"os"
)

func main() {
	var exitCode = 0
	defer func() {
		if exitCode != 0 {
			os.Exit(exitCode)
		}
	}()
	defer rglog.Flush()

	logutil.InitConsole(logRoot)

	param, err := parseParameters(os.Args...)
	if err != nil {
		log.Err(erro.Unwrap(err))
		log.Debug(erro.Wrap(err))
		exitCode = 1
		return
	}

	logutil.SetupConsole(logRoot, param.consLv)
	if err := logutil.Setup(logRoot, param.logType, param.logLv, param); err != nil {
		log.Err(erro.Unwrap(err))
		log.Debug(erro.Wrap(err))
		exitCode = 1
		return
	}

	if err := serve(param); err != nil {
		log.Err(erro.Unwrap(err))
		log.Debug(erro.Wrap(err))
		exitCode = 1
		return
	}

	log.Info("Shut down")
}

func serve(param *parameters) (err error) {

	// バックエンドの準備。

	stopper := server.NewStopper()

	sqlPools := driver.NewSqlPoolSet("mysql")
	defer sqlPools.Close()

	// アクセス権限。
	var permDb permission.Db
	switch param.permDbType {
	case "mysql":
		pool, err := sqlPools.Get(param.permDbAddr)
		if err != nil {
			return erro.Wrap(err)
		}
		permDb, err = permission.NewMysqlDb(pool, param.permDbTag, param.permDbTag2)
		if err != nil {
			return erro.Wrap(err)
		}
		log.Info("Use permission in mysql " + param.permDbAddr + "<" + param.permDbTag + "." + param.permDbTag2 + ">")
	default:
		return erro.New("invalid permission DB type " + param.permDbType)
	}

	// バックエンドの準備完了。

	if param.debug {
		server.Debug = true
	}

	defer func() {
		// 処理の終了待ち。
		stopper.Lock()
		defer stopper.Unlock()
		for stopper.Stopped() {
			stopper.Wait()
		}
	}()
	return server.Serve(param, read.New(
		stopper,
		permDb,
		param.debug,
	))
}
