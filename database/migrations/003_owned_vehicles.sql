-- LS:RP migration 003
-- Character-owned persistent vehicles.

USE `lsrp`;

CREATE TABLE IF NOT EXISTS `player_vehicles` (
  `vehicle_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `owner_character_id` INT UNSIGNED NOT NULL,
  `model_id` SMALLINT UNSIGNED NOT NULL,
  `plate` VARCHAR(16) NOT NULL,
  `color_1` SMALLINT NOT NULL DEFAULT 1,
  `color_2` SMALLINT NOT NULL DEFAULT 1,
  `park_x` FLOAT NOT NULL DEFAULT 2495.3633,
  `park_y` FLOAT NOT NULL DEFAULT -1687.3105,
  `park_z` FLOAT NOT NULL DEFAULT 13.5156,
  `park_a` FLOAT NOT NULL DEFAULT 0.0,
  `interior_id` INT NOT NULL DEFAULT 0,
  `virtual_world` INT NOT NULL DEFAULT 0,
  `health` FLOAT NOT NULL DEFAULT 1000.0,
  `panels_damage` INT UNSIGNED NOT NULL DEFAULT 0,
  `doors_damage` INT UNSIGNED NOT NULL DEFAULT 0,
  `lights_damage` INT UNSIGNED NOT NULL DEFAULT 0,
  `tyres_damage` INT UNSIGNED NOT NULL DEFAULT 0,
  `mileage_km` DECIMAL(12,3) UNSIGNED NOT NULL DEFAULT 0.000,
  `storage_state` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `is_favorite` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `is_locked` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `gps_installed` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `gps_active` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `theft_state` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `last_driver_character_id` INT UNSIGNED NULL DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` DATETIME NULL DEFAULT NULL,
  PRIMARY KEY (`vehicle_id`),
  UNIQUE KEY `uq_player_vehicle_plate` (`plate`),
  KEY `idx_player_vehicle_owner_state` (`owner_character_id`, `storage_state`, `deleted_at`),
  CONSTRAINT `fk_player_vehicle_character`
    FOREIGN KEY (`owner_character_id`)
    REFERENCES `player_characters` (`character_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
