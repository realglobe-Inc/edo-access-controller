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

package permission

import (
	"database/sql"
)

type mysqlDb struct {
}

func NewMysqlDb(base *sql.DB, db, tbl string) (Db, error) {
	if db != "" {
		tbl = db + "." + tbl
	}
	return &mysqlDb{}, nil
}

func (this *mysqlDb) Get(own, mast, path string, usrs map[string]bool) (usrToElem map[string]Element, err error) {
	panic("not yet implemented")
}

func (this *mysqlDb) GetTree(own, mast, path string, usrs map[string]bool) (pathToUsrToElem map[string]Element, err error) {
	panic("not yet implemented")
}
