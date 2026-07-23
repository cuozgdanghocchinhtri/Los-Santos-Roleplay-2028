-- LS:RP migration 007
-- Current job belongs directly to each character.

USE `lsrp`;

ALTER TABLE `player_characters`
    ADD COLUMN IF NOT EXISTS `job`
        TINYINT UNSIGNED NOT NULL DEFAULT 0
        AFTER `level`,
    ADD COLUMN IF NOT EXISTS `job_hired_at`
        DATETIME NULL DEFAULT NULL
        AFTER `job`,
    ADD COLUMN IF NOT EXISTS `job_salary`
        INT UNSIGNED NOT NULL DEFAULT 0
        AFTER `job_hired_at`,
    ADD COLUMN IF NOT EXISTS `job_allowance`
        INT UNSIGNED NOT NULL DEFAULT 0
        AFTER `job_salary`;
