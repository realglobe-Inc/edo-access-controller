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
	"flag"
	"fmt"
	"github.com/realglobe-Inc/go-lib/erro"
	"github.com/realglobe-Inc/go-lib/rglog/level"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
)

type parameters struct {
	// 画面ログ。
	consLv level.Level
	// 追加ログ。
	logType string
	logLv   level.Level
	// ファイルログ。
	logPath string
	logSize int64
	logNum  int
	// fluentd ログ。
	logAddr string
	logTag  string

	// ソケット。
	socType string
	// UNIX ソケット。
	socPath string
	// TCP ソケット。
	socPort int
	// プロトコル。
	protType string

	// アクセス権限 DB。
	permDbType string
	permDbAddr string
	permDbTag  string
	permDbTag2 string

	debug bool
	// テスト用。
	shutCh chan struct{}
}

func parseParameters(args ...string) (param *parameters, err error) {

	const label = "edo-id-provider"

	flags := flag.NewFlagSet(label+" parameters", flag.ExitOnError)
	flags.Usage = func() {
		fmt.Fprintln(os.Stderr, "Usage:")
		fmt.Fprintln(os.Stderr, "  "+args[0]+" [{FLAG}...]")
		fmt.Fprintln(os.Stderr, "FLAG:")
		flags.PrintDefaults()
	}

	param = &parameters{}

	flags.Var(level.Var(&param.consLv, level.INFO), "consLv", "Console log level")
	flags.StringVar(&param.logType, "logType", "", "Extra log: Type")
	flags.Var(level.Var(&param.logLv, level.ALL), "logLv", "Extra log: Level")
	flags.StringVar(&param.logPath, "logPath", filepath.Join(filepath.Dir(os.Args[0]), "log", label+".log"), "Extra log: File path")
	flags.Int64Var(&param.logSize, "logSize", 10*(1<<20) /* 10 MB */, "Extra log: File size limit")
	flags.IntVar(&param.logNum, "logNum", 10, "Extra log: File number limit")
	flags.StringVar(&param.logAddr, "logAddr", "localhost:24224", "Extra log: Fluentd address")
	flags.StringVar(&param.logTag, "logTag", label, "Extra log: Fluentd tag")

	flags.StringVar(&param.socType, "socType", "tcp", "Socket type")
	flags.StringVar(&param.socPath, "socPath", filepath.Join(filepath.Dir(os.Args[0]), "run", label+".soc"), "Unix socket path")
	flags.IntVar(&param.socPort, "socPort", 1607, "TCP socket port")
	flags.StringVar(&param.protType, "protType", "http", "Protocol type")

	flags.StringVar(&param.permDbType, "permDbType", "mysql", "Permission DB type")
	flags.StringVar(&param.permDbAddr, "permDbAddr", "root@tcp(localhost:3306)/", "Permission DB address")
	flags.StringVar(&param.permDbTag, "permDbTag", "edo", "Permission DB tag")
	flags.StringVar(&param.permDbTag2, "permDbTag2", "access_right", "Permission DB sub tag")

	flags.BoolVar(&param.debug, "debug", false, "Debug mode")

	var config string
	flags.StringVar(&config, "c", "", "Config file path")

	// 実行引数を読んで、設定ファイルを指定させてから、
	// 設定ファイルを読んで、また実行引数を読む。
	flags.Parse(args[1:])
	if config != "" {
		if buff, err := ioutil.ReadFile(config); err != nil {
			if !os.IsNotExist(err) {
				return nil, erro.Wrap(err)
			}
			log.Warn("Config file " + config + " is not exist")
		} else {
			flags.Parse(strings.Fields(string(buff)))
		}
	}
	flags.Parse(args[1:])

	if l := len(flags.Args()); l > 0 {
		log.Warn("Ignore extra parameters ", flags.Args())
	}

	return param, nil
}

func (param *parameters) LogFilePath() string       { return param.logPath }
func (param *parameters) LogFileLimit() int64       { return param.logSize }
func (param *parameters) LogFileNumber() int        { return param.logNum }
func (param *parameters) LogFluentdAddress() string { return param.logAddr }
func (param *parameters) LogFluentdTag() string     { return param.logTag }

func (param *parameters) SocketType() string   { return param.socType }
func (param *parameters) SocketPort() int      { return param.socPort }
func (param *parameters) SocketPath() string   { return param.socPath }
func (param *parameters) ProtocolType() string { return param.protType }

// テスト用。
// 使うときは手動で param.shutCh = make(chan struct{}, 5) とかする。
func (param *parameters) ShutdownChannel() chan struct{} { return param.shutCh }
