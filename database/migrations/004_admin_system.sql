-- LS:RP migration 004
-- Persistent OOC administrator level on the master account.

USE `lsrp`;

ALTER TABLE `player_accounts`
    ADD COLUMN IF NOT EXISTS `admin_level`
        TINYINT UNSIGNED NOT NULL DEFAULT 0
        AFTER `password_hash`;

