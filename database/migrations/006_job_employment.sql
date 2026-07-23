-- LS:RP migration 006
-- Employment profile and reserved payday fields for civilian jobs.

USE `lsrp`;

ALTER TABLE `character_jobs`
  ADD COLUMN IF NOT EXISTS `is_employed`
    TINYINT UNSIGNED NOT NULL DEFAULT 0 AFTER `total_earnings`,
  ADD COLUMN IF NOT EXISTS `hired_at`
    DATETIME NULL DEFAULT NULL AFTER `is_employed`,
  ADD COLUMN IF NOT EXISTS `resigned_at`
    DATETIME NULL DEFAULT NULL AFTER `hired_at`,
  ADD COLUMN IF NOT EXISTS `daily_salary`
    INT UNSIGNED NOT NULL DEFAULT 0 AFTER `resigned_at`,
  ADD COLUMN IF NOT EXISTS `daily_allowance`
    INT UNSIGNED NOT NULL DEFAULT 0 AFTER `daily_salary`;
