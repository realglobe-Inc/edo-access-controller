-- 権限を保存するテーブルの作成例。

CREATE DATABASE IF NOT EXISTS edo;
USE edo;


DROP TABLE IF EXISTS access_right;
CREATE TABLE access_right (owner_master VARCHAR(255), data_path VARCHAR(255), user_from VARCHAR(255), permission CHAR(2), UNIQUE(owner_master, user_from, data_path));
