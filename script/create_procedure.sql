-- 権限を取得するストアドプロシージャの設定例。

USE edo;

DELIMITER //


-- パスを 1 つずつ遡って調べる。
DROP PROCEDURE IF EXISTS GetPermission//
CREATE PROCEDURE GetPermission(IN owner_in VARCHAR(255), IN master_in VARCHAR(255), IN data_path_in VARCHAR(255), IN user_in VARCHAR(255), IN from_in VARCHAR(255), OUT permission_out CHAR(2))
BEGIN
  DECLARE owner_master_value VARCHAR(255) DEFAULT CONCAT(owner_in, '_', master_in);
  DECLARE user_from_value    VARCHAR(255) DEFAULT CONCAT(user_in, '_', from_in);
  DECLARE user_any_value     VARCHAR(255) DEFAULT CONCAT(user_in, '_*');
  DECLARE any_from_value     VARCHAR(255) DEFAULT CONCAT('*_', from_in);

  DECLARE data_path_var VARCHAR(255) DEFAULT data_path_in;
  DECLARE pos_var  INT UNSIGNED;

  l1: LOOP
    SELECT permission FROM access_right WHERE owner_master = owner_master_value AND user_from = user_from_value AND data_path = data_path_var INTO permission_out;
    IF permission_out IS NOT NULL THEN LEAVE l1; END IF;

    SELECT permission FROM access_right WHERE owner_master = owner_master_value AND user_from = user_any_value AND data_path = data_path_var INTO permission_out;
    IF permission_out IS NOT NULL THEN LEAVE l1; END IF;

    SELECT permission FROM access_right WHERE owner_master = owner_master_value AND user_from = any_from_value AND data_path = data_path_var INTO permission_out;
    IF permission_out IS NOT NULL THEN LEAVE l1; END IF;

    SELECT permission FROM access_right WHERE owner_master = owner_master_value AND user_from = '*_*' AND data_path = data_path_var INTO permission_out;
    IF permission_out IS NOT NULL THEN LEAVE l1; END IF;

    SET pos_var = LOCATE('/', REVERSE(data_path_var));
    IF pos_var = 0 THEN LEAVE l1; END IF;

    SET data_path_var = LEFT(data_path_var, LENGTH(data_path_var) - pos_var);
  END LOOP;
END//


-- 最初に自分も含めて直上のパスを求める。
DROP PROCEDURE IF EXISTS GetPermission2//
CREATE PROCEDURE GetPermission2(IN owner_in VARCHAR(255), IN master_in VARCHAR(255), IN data_path_in VARCHAR(255), IN user_in VARCHAR(255), IN from_in VARCHAR(255), OUT permission_out CHAR(2))
BEGIN
  DECLARE owner_master_value VARCHAR(255) DEFAULT CONCAT(owner_in, '_', master_in);
  DECLARE user_from_value    VARCHAR(255) DEFAULT CONCAT(user_in, '_', from_in);
  DECLARE user_any_value     VARCHAR(255) DEFAULT CONCAT(user_in, '_*');
  DECLARE any_from_value     VARCHAR(255) DEFAULT CONCAT('*_', from_in);

  DECLARE user_from_var   VARCHAR(255);
  DECLARE user_from_var2  VARCHAR(255);
  DECLARE permission_var  CHAR(2);
  DECLARE permission_var2 CHAR(2);

  DECLARE done INT DEFAULT 0;
  DECLARE cur CURSOR FOR
    SELECT user_from, permission
      FROM access_right
      WHERE owner_master = owner_master_value
        AND (user_from = user_from_value
          OR user_from = user_any_value
          OR user_from = any_from_value
          OR user_from = '*_*')
        AND data_path = (SELECT MAX(data_path)
          FROM access_right sub
          WHERE sub.owner_master = owner_master_value
            AND (sub.user_from = user_from_value
              OR sub.user_from = user_any_value
              OR sub.user_from = any_from_value
              OR sub.user_from = '*_*')
            AND data_path_in LIKE CONCAT(sub.data_path, '%'));
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

  OPEN cur;
  FETCH NEXT FROM cur INTO user_from_var2, permission_var2;
  l1: WHILE done = 0 DO
    IF user_from_var = user_from_value THEN LEAVE l1;
    ELSEIF (user_from_var IS NULL)
      OR (user_from_var = user_any_value AND user_from_var2 = user_from_value)
      OR (user_from_var = any_from_value AND (user_from_var2 = user_from_value
                                           OR user_from_var2 = user_any_value))
      OR (user_from_var = '*_*' AND (user_from_var2 = user_from_value
                                  OR user_from_var2 = user_any_value
                                  OR user_from_var2 = any_from_value)) THEN
      SET user_from_var = user_from_var2;
      SET permission_var = permission_var2;
    END IF;

    FETCH NEXT FROM cur INTO user_from_var2, permission_var2;
  END WHILE;
  CLOSE cur;

  IF permission_var IS NOT NULL THEN SELECT permission_var INTO permission_out; END IF;
END//


DELIMITER ;
