-- LS:RP migration 005
-- Shared per-character progression for every civilian job.

USE `lsrp`;

CREATE TABLE IF NOT EXISTS `character_jobs` (
  `character_id` INT UNSIGNED NOT NULL,
  `job_type` TINYINT UNSIGNED NOT NULL,
  `experience` INT UNSIGNED NOT NULL DEFAULT 0,
  `completed_runs` INT UNSIGNED NOT NULL DEFAULT 0,
  `completed_tasks` INT UNSIGNED NOT NULL DEFAULT 0,
  `best_streak` INT UNSIGNED NOT NULL DEFAULT 0,
  `total_earnings` INT UNSIGNED NOT NULL DEFAULT 0,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`character_id`, `job_type`),
  KEY `idx_character_jobs_type_xp` (`job_type`, `experience`),
  CONSTRAINT `fk_character_jobs_character`
    FOREIGN KEY (`character_id`)
    REFERENCES `player_characters` (`character_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
