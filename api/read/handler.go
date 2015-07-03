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

// アクセス権限読み取り。
package read

import (
	_ "github.com/go-sql-driver/mysql"
	"github.com/realglobe-Inc/edo-access-controller/database/permission"
	"github.com/realglobe-Inc/edo-lib/server"
	"github.com/realglobe-Inc/go-lib/erro"
	"github.com/realglobe-Inc/go-lib/rglog/level"
	"net/http"
)

type handler struct {
	stopper *server.Stopper

	permDb permission.Db

	debug bool
}

func New(
	stopper *server.Stopper,
	permDb permission.Db,
	debug bool,
) http.Handler {
	return &handler{
		stopper,
		permDb,
		debug,
	}
}

func (this *handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	var logPref string

	// panic 対策。
	defer func() {
		if rcv := recover(); rcv != nil {
			server.RespondErrorJson(w, r, erro.New(rcv), logPref)
			return
		}
	}()

	if this.stopper != nil {
		this.stopper.Stop()
		defer this.stopper.Unstop()
	}

	logPref = server.ParseSender(r) + ": "

	server.LogRequest(level.DEBUG, r, this.debug, logPref)

	log.Info(logPref, "Received read request")
	defer log.Info(logPref, "Handled read request")

	if err := (&environment{this, logPref}).serve(w, r); err != nil {
		server.RespondErrorJson(w, r, erro.Wrap(err), logPref)
		return
	}
}

// environment のメソッドは server.Error を返す。
type environment struct {
	*handler

	logPref string
}

// ここから処理本編。
func (this *environment) serve(w http.ResponseWriter, r *http.Request) error {
	panic("not yet implemented")
}
