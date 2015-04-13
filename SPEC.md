<!--
Copyright 2015 realglobe, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->


# edo-access-controller の仕様（目標）

[アクセス制御]を代行し、[PDS データアクセス API] の一部を担う。

以降の動作記述において、箇条書きに以下の構造を持たせることがある。

* if
    * then
* else if
    * then
* else


## 1. edo-auth の使用

[edo-auth] TA を通すことを前提とする。


## 2. アクセス制御

[アクセス制御]と [PDS データアクセス API] も参照のこと。

* リクエストからリソースの指定が読み取れない場合、
    * エラー (`invalid_request`) を返す。
* そうでなく、アクセス制御によりアクセスが拒否される場合、
    * エラー (`access_denied`) を返す。
* そうでなければ、リクエストを通す。

リソースに対応するアクセス権限が存在しない場合、パスについて直上の先祖のアクセス権限を用いる。
それも無ければ拒否する。


### 2.1. リソース指定の読み取り

リソース指定の読み取り部分は、利用者側で置換して運用できるように独立させる。
標準では、[PDS データアクセス API] の URL による指定から所有アカウントタグ、割り当て TA の ID、パスを、[edo-auth] TA によるヘッダからアカウント情報を読み取り、リソース識別子にする。


## 3. アクセス権限の読み取り

[PDS データアクセス API] も参照のこと。

リクエストメソッドが GET でない場合、リクエストをそのまま通し、レスポンスをそのまま返す。
GET の場合、必要に応じて以下の処理を行う（加える）。

1. アクセス権限の読み取り
3. ディレクトリ内データのフィルタリング
2. ディレクトリ内データのアクセス権限の読み取り


### 3.1. アクセス権限の読み取り

* リクエストの読み込みタイプが `permission` を含まない場合、
    * アクセス権限の読み取りとしてはこれ以上何もしない。
* そうでなく、他の読み込みタイプを含まない場合、
    * レスポンスボディにてアクセス権限を返す。
* そうでなければ、リクエストの読み込みタイプから `permission` を取り除く。


* リクエストが `content` 読み込みタイプを含まない場合、
    * レスポンスの Content-Type が application/json の場合、
        * レスポンスボディにアクセス権限を加える。
    * そうでなければ、
        * 何もしない。
* そうでなく、レスポンスに X-Pds-Datainfo ヘッダがある場合、
    * レスポンスの X-Pds-Datainfo の値にアクセス権限を加える。
* そうでなければ、レスポンスに X-Pds-Datainfo ヘッダでアクセス権限を加える。


### 3.2. ディレクトリ内データのフィルタリング

* リクエストのデータ型が `directory` でない、または、再帰フラグが偽である、または、レスポンスの Conten-Type が application/json でない場合、
    * 何もしない。
* そうでなければ、レスポンスボディから読み取り権限の無いデータの情報を取り除く。


### 3.3. ディレクトリ内データのアクセス権限の読み取り

* リクエストのディレクトリ内読み込みタイプが `permission` を含まない場合、
    * ディレクトリ内データのアクセス権限の読み取りとしてはこれ以上何もしない。
* そうでなければ、リクエストのディレクトリ内読み込みタイプから `permission` を取り除く。


* レスポンスの Content-Type が application/json の場合、
    * レスポンスボディにアクセス権限を加える。
* そうでなければ、何もしない。


## 4. エラーレスポンス

[PDS データアクセス API] を参照のこと。


## 5. 外部データ
以下に分ける。

* 共有データ
    * 他のプログラムと共有する可能性のあるもの。
* 非共有データ
    * 共有するとしてもこのプログラムの別プロセスのみのもの。


### 5.1. 共有データ


#### 5.1.1. アクセス権限

以下を含む。

* リソース識別子
    * 所有アカウントの ID
    * 割り当て TA の ID
    * パス
* アカウント・TA ごとの権限

以下の操作が必要。

* リソース識別子による取得
    * パスが一致するものがなければ、直上のパスのものを返す。
    * 権限をアカウントでフィルタする。


### 5.2. 非共有データ

無し。


<!-- 参照 -->
[PDS データアクセス API]: https://github.com/realglobe-Inc/edo/blob/master/pds_data.md
[edo-auth]: https://github.com/realglobe-Inc/edo-auth
[アクセス制御]: https://github.com/realglobe-Inc/edo/blob/master/access_control.md
