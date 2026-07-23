-- LS:RP migration 001
-- Master account -> up to 3 IC characters.
-- Import this into the existing `lsrp` database.

USE `lsrp`;

CREATE TABLE IF NOT EXISTS `player_characters` (
  `character_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `account_id` INT UNSIGNED NOT NULL,
  `slot` TINYINT UNSIGNED NOT NULL,
  `name` VARCHAR(24) NOT NULL,
  `skin` SMALLINT UNSIGNED NOT NULL DEFAULT 26,
  `cash` INT NOT NULL DEFAULT 500,
  `bank` INT NOT NULL DEFAULT 0,
  `level` INT UNSIGNED NOT NULL DEFAULT 1,
  `health` FLOAT NOT NULL DEFAULT 100.0,
  `armour` FLOAT NOT NULL DEFAULT 0.0,
  `pos_x` FLOAT NOT NULL DEFAULT 2495.3633,
  `pos_y` FLOAT NOT NULL DEFAULT -1687.3105,
  `pos_z` FLOAT NOT NULL DEFAULT 13.5156,
  `pos_a` FLOAT NOT NULL DEFAULT 0.0,
  `interior_id` INT NOT NULL DEFAULT 0,
  `virtual_world` INT NOT NULL DEFAULT 0,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_played` DATETIME NULL DEFAULT NULL,
  PRIMARY KEY (`character_id`),
  UNIQUE KEY `uq_character_name` (`name`),
  UNIQUE KEY `uq_account_slot` (`account_id`, `slot`),
  KEY `idx_character_account` (`account_id`),
  CONSTRAINT `fk_character_account` FOREIGN KEY (`account_id`) REFERENCES `player_accounts` (`account_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
