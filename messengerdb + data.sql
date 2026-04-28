/*
 Navicat MySQL Dump SQL

 Source Server         : mySQL
 Source Server Type    : MySQL
 Source Server Version : 80408 (8.4.8)
 Source Host           : localhost:3306
 Source Schema         : messengerdb

 Target Server Type    : MySQL
 Target Server Version : 80408 (8.4.8)
 File Encoding         : 65001

 Date: 26/04/2026 23:09:53
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for channel_meta
-- ----------------------------
DROP TABLE IF EXISTS `channel_meta`;
CREATE TABLE `channel_meta`  (
  `channel_meta_id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `entity_id` bigint UNSIGNED NOT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL,
  `is_public` tinyint(1) NOT NULL DEFAULT 0,
  `subscriber_count` int UNSIGNED NOT NULL DEFAULT 0,
  `banner_url` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `extra_meta` json NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`channel_meta_id`) USING BTREE,
  INDEX `fk_cm_entity`(`entity_id` ASC) USING BTREE,
  CONSTRAINT `fk_cm_entity` FOREIGN KEY (`entity_id`) REFERENCES `entities` (`entity_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of channel_meta
-- ----------------------------

-- ----------------------------
-- Table structure for entities
-- ----------------------------
DROP TABLE IF EXISTS `entities`;
CREATE TABLE `entities`  (
  `entity_id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `entity_type` enum('user','group','channel') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `display_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `username` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `quick_meta` json NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_active` tinyint(1) NULL DEFAULT 1,
  `is_deleted` tinyint(1) NULL DEFAULT 0,
  PRIMARY KEY (`entity_id`) USING BTREE,
  UNIQUE INDEX `username`(`username` ASC) USING BTREE,
  INDEX `idx_entity_type_active`(`entity_type` ASC, `is_active` ASC, `is_deleted` ASC) USING BTREE,
  INDEX `idx_entity_created`(`created_at` DESC) USING BTREE,
  CONSTRAINT `chk_user_password` CHECK (((`entity_type` = _utf8mb4'user') and (`password_hash` is not null)) or ((`entity_type` in (_utf8mb4'group',_utf8mb4'channel')) and (`password_hash` is null)))
) ENGINE = InnoDB AUTO_INCREMENT = 2 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of entities
-- ----------------------------
INSERT INTO `entities` VALUES (1, 'user', 'ali naseri', 'alinaseri25', '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', NULL, '2026-03-09 15:21:14', '2026-04-26 22:43:25', 1, 0);

-- ----------------------------
-- Table structure for entity_avatars
-- ----------------------------
DROP TABLE IF EXISTS `entity_avatars`;
CREATE TABLE `entity_avatars`  (
  `avatar_id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `entity_id` bigint UNSIGNED NOT NULL,
  `avatar_url` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 0,
  `display_order` smallint UNSIGNED NOT NULL DEFAULT 0,
  `uploaded_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`avatar_id`) USING BTREE,
  INDEX `idx_ea_entity`(`entity_id` ASC) USING BTREE,
  INDEX `idx_ea_entity_active`(`entity_id` ASC, `is_active` ASC) USING BTREE,
  CONSTRAINT `fk_ea_entity` FOREIGN KEY (`entity_id`) REFERENCES `entities` (`entity_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of entity_avatars
-- ----------------------------

-- ----------------------------
-- Table structure for entity_memberships
-- ----------------------------
DROP TABLE IF EXISTS `entity_memberships`;
CREATE TABLE `entity_memberships`  (
  `membership_id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `parent_entity_id` bigint UNSIGNED NOT NULL,
  `member_entity_id` bigint UNSIGNED NOT NULL,
  `role` enum('owner','admin','moderator','member','restricted','contact') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT 'member',
  `permissions` json NULL,
  `joined_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `left_at` timestamp NULL DEFAULT NULL,
  `is_active` tinyint(1) NULL DEFAULT 1,
  `is_muted` tinyint(1) NULL DEFAULT 0,
  `is_banned` tinyint(1) NULL DEFAULT 0,
  PRIMARY KEY (`membership_id`) USING BTREE,
  UNIQUE INDEX `uk_membership`(`parent_entity_id` ASC, `member_entity_id` ASC) USING BTREE,
  INDEX `idx_membership_parent_active`(`parent_entity_id` ASC, `is_active` ASC) USING BTREE,
  INDEX `idx_membership_member_active`(`member_entity_id` ASC, `is_active` ASC) USING BTREE,
  INDEX `idx_membership_role`(`parent_entity_id` ASC, `role` ASC) USING BTREE,
  CONSTRAINT `fk_em_member` FOREIGN KEY (`member_entity_id`) REFERENCES `entities` (`entity_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `fk_em_parent` FOREIGN KEY (`parent_entity_id`) REFERENCES `entities` (`entity_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of entity_memberships
-- ----------------------------

-- ----------------------------
-- Table structure for entity_tags
-- ----------------------------
DROP TABLE IF EXISTS `entity_tags`;
CREATE TABLE `entity_tags`  (
  `entity_id` bigint UNSIGNED NOT NULL,
  `tag_id` bigint UNSIGNED NOT NULL,
  `tagged_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`entity_id`, `tag_id`) USING BTREE,
  INDEX `idx_entity_tags_tag`(`tag_id` ASC) USING BTREE,
  CONSTRAINT `fk_etag_entity` FOREIGN KEY (`entity_id`) REFERENCES `entities` (`entity_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `fk_etag_tag` FOREIGN KEY (`tag_id`) REFERENCES `tags` (`tag_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of entity_tags
-- ----------------------------

-- ----------------------------
-- Table structure for equipments
-- ----------------------------
DROP TABLE IF EXISTS `equipments`;
CREATE TABLE `equipments`  (
  `equipment_id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `device_uuid` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `device_type` enum('other','android','ios','desktop','web','stm32','esp32') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `device_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `os_version` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `app_version` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `hardware_info` json NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_activity_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_active` tinyint(1) NULL DEFAULT 1,
  PRIMARY KEY (`equipment_id`) USING BTREE,
  UNIQUE INDEX `device_uuid`(`device_uuid` ASC) USING BTREE,
  INDEX `idx_device_uuid`(`device_uuid` ASC) USING BTREE,
  INDEX `idx_device_type`(`device_type` ASC, `is_active` ASC) USING BTREE,
  INDEX `idx_device_last_activity`(`last_activity_at` DESC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1189 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of equipments
-- ----------------------------
INSERT INTO `equipments` VALUES (8, 'esp32-24:0A:C4:9B:15:A8', 'esp32', 'ESP', NULL, NULL, NULL, '2026-03-06 18:32:25', '2026-03-11 13:46:06', 1);
INSERT INTO `equipments` VALUES (182, 'a7cad039-ca3a-4b42-8501-c436812861ed', 'desktop', 'Application', NULL, NULL, NULL, '2026-03-11 11:51:32', '2026-04-23 20:52:54', 1);
INSERT INTO `equipments` VALUES (218, '', 'other', '', NULL, NULL, NULL, '2026-03-12 16:38:29', '2026-03-12 16:39:43', 1);
INSERT INTO `equipments` VALUES (1130, 'b049ad69-c7c9-483d-bb5d-77a37c2cf4a8', 'desktop', 'Application', NULL, NULL, NULL, '2026-04-10 20:32:21', '2026-04-10 20:39:25', 1);
INSERT INTO `equipments` VALUES (1138, '4db7c483-cd0e-4861-b577-8965c76a35ad', 'desktop', 'Application', NULL, NULL, NULL, '2026-04-23 20:22:51', '2026-04-26 22:43:04', 1);

-- ----------------------------
-- Table structure for group_meta
-- ----------------------------
DROP TABLE IF EXISTS `group_meta`;
CREATE TABLE `group_meta`  (
  `group_meta_id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `entity_id` bigint UNSIGNED NOT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL,
  `member_limit` int UNSIGNED NOT NULL DEFAULT 200,
  `is_public` tinyint(1) NOT NULL DEFAULT 0,
  `banner_url` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `extra_meta` json NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`group_meta_id`) USING BTREE,
  INDEX `fk_gm_entity`(`entity_id` ASC) USING BTREE,
  CONSTRAINT `fk_gm_entity` FOREIGN KEY (`entity_id`) REFERENCES `entities` (`entity_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of group_meta
-- ----------------------------

-- ----------------------------
-- Table structure for message_states
-- ----------------------------
DROP TABLE IF EXISTS `message_states`;
CREATE TABLE `message_states`  (
  `state_id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `message_id` bigint UNSIGNED NOT NULL,
  `receiver_entity_id` bigint UNSIGNED NOT NULL,
  `reply_to_message_S_id` bigint UNSIGNED NULL DEFAULT NULL,
  `forwarded_from_S_id` bigint UNSIGNED NULL DEFAULT NULL,
  `delivered_at` timestamp NULL DEFAULT NULL,
  `read_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `is_starred` tinyint(1) NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`state_id`) USING BTREE,
  UNIQUE INDEX `uk_message_state`(`message_id` ASC, `receiver_entity_id` ASC) USING BTREE,
  INDEX `idx_state_message`(`message_id` ASC) USING BTREE,
  INDEX `idx_state_receiver_unread`(`receiver_entity_id` ASC, `created_at` DESC) USING BTREE,
  INDEX `idx_state_parent`(`created_at` DESC) USING BTREE,
  INDEX `idx_state_sender`(`created_at` DESC) USING BTREE,
  INDEX `idx_state_unread_only`(`receiver_entity_id` ASC, `created_at` DESC) USING BTREE,
  INDEX `idx_state_reply`(`reply_to_message_S_id` ASC) USING BTREE,
  INDEX `idx_state_forward`(`forwarded_from_S_id` ASC) USING BTREE,
  CONSTRAINT `fk_ms_forward` FOREIGN KEY (`forwarded_from_S_id`) REFERENCES `message_states` (`state_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `fk_ms_message` FOREIGN KEY (`message_id`) REFERENCES `messages` (`message_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `fk_ms_receiver` FOREIGN KEY (`receiver_entity_id`) REFERENCES `entities` (`entity_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `fk_ms_reply` FOREIGN KEY (`reply_to_message_S_id`) REFERENCES `message_states` (`state_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of message_states
-- ----------------------------

-- ----------------------------
-- Table structure for messages
-- ----------------------------
DROP TABLE IF EXISTS `messages`;
CREATE TABLE `messages`  (
  `message_id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `session_id_writer` bigint UNSIGNED NOT NULL,
  `owner_entity_id` bigint UNSIGNED NOT NULL,
  `content_type` enum('text','audio','image','video','file','location','contact','poll') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `content_text` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL,
  `content_data` json NULL,
  `file_path` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `file_size` bigint UNSIGNED NULL DEFAULT NULL,
  `file_mime_type` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `thumbnail_path` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `scheduled_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `is_deleted` tinyint(1) NULL DEFAULT 0,
  PRIMARY KEY (`message_id`) USING BTREE,
  INDEX `idx_msg_owner`(`created_at` DESC) USING BTREE,
  INDEX `idx_msg_type`(`content_type` ASC) USING BTREE,
  INDEX `idx_msg_created`(`created_at` DESC) USING BTREE,
  INDEX `idx_msg_scheduled`(`scheduled_at` ASC) USING BTREE,
  INDEX `idx_msg_owner_type`(`content_type` ASC, `created_at` DESC) USING BTREE,
  INDEX `fk_owner_entity`(`owner_entity_id` ASC) USING BTREE,
  INDEX `fk_writer_session`(`session_id_writer` ASC) USING BTREE,
  CONSTRAINT `fk_owner_entity` FOREIGN KEY (`owner_entity_id`) REFERENCES `entities` (`entity_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `fk_writer_session` FOREIGN KEY (`session_id_writer`) REFERENCES `sessions` (`session_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of messages
-- ----------------------------

-- ----------------------------
-- Table structure for sessions
-- ----------------------------
DROP TABLE IF EXISTS `sessions`;
CREATE TABLE `sessions`  (
  `session_id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `entity_id` bigint UNSIGNED NOT NULL,
  `equipment_id` bigint UNSIGNED NOT NULL,
  `session_token` char(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `refresh_token` char(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `ip_address` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `user_agent` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_activity_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `expires_at` timestamp NOT NULL,
  PRIMARY KEY (`session_id`) USING BTREE,
  UNIQUE INDEX `uq_session_token`(`session_token` ASC) USING BTREE,
  UNIQUE INDEX `uq_refresh_token`(`refresh_token` ASC) USING BTREE,
  INDEX `idx_session_token`(`session_token` ASC) USING BTREE,
  INDEX `idx_session_entity_valid`(`entity_id` ASC, `expires_at` ASC) USING BTREE,
  INDEX `idx_session_equipment`(`equipment_id` ASC) USING BTREE,
  CONSTRAINT `fk_sess_entity` FOREIGN KEY (`entity_id`) REFERENCES `entities` (`entity_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `fk_sess_equipment` FOREIGN KEY (`equipment_id`) REFERENCES `equipments` (`equipment_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB AUTO_INCREMENT = 7 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of sessions
-- ----------------------------
INSERT INTO `sessions` VALUES (3, 1, 8, 'e4bdd86524a94b8cb6054056f4c702f7', 'cea6db0125ea46d398b73f537c3040a8', '::ffff:192.168.1.104', 'ESP', '2026-03-09 21:56:10', '2026-03-11 13:46:07', '2026-04-08 18:26:10');
INSERT INTO `sessions` VALUES (4, 1, 182, '66e451b1f14c41c1a8983bf4cec38e38', '4adc1c0c606f4f9c85159be4c583d531', '::ffff:192.168.1.100', 'Application', '2026-03-11 15:10:34', '2026-04-23 20:50:54', '2026-04-23 17:20:54');
INSERT INTO `sessions` VALUES (5, 1, 1130, '8273a9975bcc49639cb07d99c81c2270', 'ea5d7cce3aa940b38e4facacea6b97fb', '::ffff:192.168.1.101', 'Descktop App', '2026-04-10 20:32:38', '2026-04-10 20:39:25', '2026-05-10 17:02:38');
INSERT INTO `sessions` VALUES (6, 1, 1138, '3d0e18f49d3543b282b3d7bdb8c94a3d', '6a8492b45c94413d975bd60302c5c528', '::ffff:192.168.1.103', 'Application', '2026-04-23 20:23:23', '2026-04-26 22:43:25', '2026-05-26 19:13:25');

-- ----------------------------
-- Table structure for tags
-- ----------------------------
DROP TABLE IF EXISTS `tags`;
CREATE TABLE `tags`  (
  `tag_id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `tag_name` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `tag_type` enum('system','custom','auto') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT 'custom',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`tag_id`) USING BTREE,
  UNIQUE INDEX `tag_name`(`tag_name` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of tags
-- ----------------------------

-- ----------------------------
-- Table structure for user_emails
-- ----------------------------
DROP TABLE IF EXISTS `user_emails`;
CREATE TABLE `user_emails`  (
  `email_id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `entity_id` bigint UNSIGNED NOT NULL,
  `email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_primary` tinyint(1) NOT NULL DEFAULT 0,
  `is_verified` tinyint(1) NOT NULL DEFAULT 0,
  `verified_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`email_id`) USING BTREE,
  UNIQUE INDEX `uq_ue_email`(`email` ASC) USING BTREE,
  INDEX `idx_ue_entity`(`entity_id` ASC) USING BTREE,
  INDEX `idx_ue_primary`(`entity_id` ASC, `is_primary` ASC) USING BTREE,
  CONSTRAINT `fk_ue_entity` FOREIGN KEY (`entity_id`) REFERENCES `entities` (`entity_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of user_emails
-- ----------------------------

-- ----------------------------
-- Table structure for user_phones
-- ----------------------------
DROP TABLE IF EXISTS `user_phones`;
CREATE TABLE `user_phones`  (
  `phone_id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `entity_id` bigint UNSIGNED NOT NULL,
  `phone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_primary` tinyint(1) NOT NULL DEFAULT 0,
  `is_verified` tinyint(1) NOT NULL DEFAULT 0,
  `verified_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`phone_id`) USING BTREE,
  UNIQUE INDEX `uq_uph_phone`(`phone` ASC) USING BTREE,
  INDEX `idx_uph_entity`(`entity_id` ASC) USING BTREE,
  INDEX `idx_uph_primary`(`entity_id` ASC, `is_primary` ASC) USING BTREE,
  CONSTRAINT `fk_uph_entity` FOREIGN KEY (`entity_id`) REFERENCES `entities` (`entity_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of user_phones
-- ----------------------------

-- ----------------------------
-- Table structure for user_profiles
-- ----------------------------
DROP TABLE IF EXISTS `user_profiles`;
CREATE TABLE `user_profiles`  (
  `user_profile_id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `entity_id` bigint UNSIGNED NOT NULL,
  `bio` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL,
  `birth_date` date NULL DEFAULT NULL,
  `gender` enum('male','female','other','prefer_not_to_say') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `language` char(5) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'fa',
  `timezone` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Asia/Tehran',
  `banner_url` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL,
  `last_seen_at` timestamp NULL DEFAULT NULL,
  `last_seen_privacy` enum('everyone','contacts','nobody') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'everyone',
  `extra_meta` json NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_profile_id`) USING BTREE,
  INDEX `fk_up_entity`(`entity_id` ASC) USING BTREE,
  CONSTRAINT `fk_up_entity` FOREIGN KEY (`entity_id`) REFERENCES `entities` (`entity_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of user_profiles
-- ----------------------------

-- ----------------------------
-- View structure for v_chat_list
-- ----------------------------
DROP VIEW IF EXISTS `v_chat_list`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `v_chat_list` AS with `last_messages` as (select coalesce(`ms`.`parent_entity_id`,`ms`.`receiver_entity_id`,`ms`.`sender_entity_id`) AS `chat_id`,`ms`.`message_id` AS `message_id`,`ms`.`sender_entity_id` AS `sender_entity_id`,`ms`.`receiver_entity_id` AS `receiver_entity_id`,`ms`.`parent_entity_id` AS `parent_entity_id`,`ms`.`created_at` AS `created_at`,`ms`.`is_read` AS `is_read`,row_number() OVER (PARTITION BY coalesce(`ms`.`parent_entity_id`,`ms`.`receiver_entity_id`,`ms`.`sender_entity_id`) ORDER BY `ms`.`created_at` desc )  AS `rn` from `message_states` `ms` where (`ms`.`is_deleted` = false)) select `lm`.`chat_id` AS `chat_id`,`e`.`entity_type` AS `chat_type`,`e`.`display_name` AS `chat_name`,`ea`.`avatar_url` AS `chat_avatar`,`m`.`content_type` AS `content_type`,`m`.`content_text` AS `content_text`,`sender`.`display_name` AS `last_sender`,`lm`.`created_at` AS `last_message_at`,coalesce((select count(0) from `message_states` `ms2` where ((coalesce(`ms2`.`parent_entity_id`,`ms2`.`sender_entity_id`) = `lm`.`chat_id`) and (`ms2`.`is_read` = false) and (`ms2`.`is_deleted` = false))),0) AS `unread_count` from ((((`last_messages` `lm` join `messages` `m` on((`lm`.`message_id` = `m`.`message_id`))) join `entities` `e` on((`lm`.`chat_id` = `e`.`entity_id`))) join `entities` `sender` on((`lm`.`sender_entity_id` = `sender`.`entity_id`))) left join `entity_avatars` `ea` on(((`ea`.`entity_id` = `lm`.`chat_id`) and (`ea`.`is_active` = 1)))) where (`lm`.`rn` = 1);

-- ----------------------------
-- View structure for v_forward_chains
-- ----------------------------
DROP VIEW IF EXISTS `v_forward_chains`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `v_forward_chains` AS select `ms`.`message_id` AS `message_id`,`m`.`owner_entity_id` AS `original_sender`,`ms`.`sender_entity_id` AS `current_sender`,`ms`.`forwarded_from_id` AS `forwarded_from_id`,`ms`.`forward_depth` AS `forward_depth`,`ms`.`created_at` AS `forwarded_at` from (`message_states` `ms` join `messages` `m` on((`ms`.`message_id` = `m`.`message_id`))) where (`ms`.`forwarded_from_id` is not null) order by `ms`.`message_id`,`ms`.`forward_depth`;

-- ----------------------------
-- View structure for v_unread_summary
-- ----------------------------
DROP VIEW IF EXISTS `v_unread_summary`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `v_unread_summary` AS select `ms`.`receiver_entity_id` AS `entity_id`,count(0) AS `unread_count`,max(`ms`.`created_at`) AS `last_message_at`,sum((case when (`m`.`content_type` = 'audio') then 1 else 0 end)) AS `unread_audio_count`,sum((case when (`ms`.`is_starred` = true) then 1 else 0 end)) AS `starred_count` from (`message_states` `ms` join `messages` `m` on((`ms`.`message_id` = `m`.`message_id`))) where ((`ms`.`is_read` = false) and (`ms`.`is_deleted` = false)) group by `ms`.`receiver_entity_id`;

-- ----------------------------
-- View structure for v_user_profile
-- ----------------------------
DROP VIEW IF EXISTS `v_user_profile`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `v_user_profile` AS select `e`.`entity_id` AS `entity_id`,`e`.`display_name` AS `display_name`,`e`.`username` AS `username`,`e`.`is_active` AS `is_active`,`up`.`bio` AS `bio`,`up`.`birth_date` AS `birth_date`,`up`.`gender` AS `gender`,`up`.`language` AS `language`,`up`.`timezone` AS `timezone`,`up`.`banner_url` AS `banner_url`,`up`.`last_seen_at` AS `last_seen_at`,`up`.`last_seen_privacy` AS `last_seen_privacy`,`ea`.`avatar_url` AS `active_avatar`,`ue`.`email` AS `primary_email`,`uph`.`phone` AS `primary_phone` from ((((`entities` `e` left join `user_profiles` `up` on((`up`.`entity_id` = `e`.`entity_id`))) left join `entity_avatars` `ea` on(((`ea`.`entity_id` = `e`.`entity_id`) and (`ea`.`is_active` = 1)))) left join `user_emails` `ue` on(((`ue`.`entity_id` = `e`.`entity_id`) and (`ue`.`is_primary` = 1)))) left join `user_phones` `uph` on(((`uph`.`entity_id` = `e`.`entity_id`) and (`uph`.`is_primary` = 1)))) where ((`e`.`entity_type` = 'user') and (`e`.`is_deleted` = false));

-- ----------------------------
-- Triggers structure for table entity_avatars
-- ----------------------------
DROP TRIGGER IF EXISTS `trg_avatar_single_active_ins`;
delimiter ;;
CREATE TRIGGER `trg_avatar_single_active_ins` BEFORE INSERT ON `entity_avatars` FOR EACH ROW BEGIN
    DECLARE active_count INT;

    IF NEW.is_active = 1 THEN
        SELECT COUNT(*) INTO active_count
          FROM entity_avatars
         WHERE entity_id = NEW.entity_id
           AND is_active = 1;

        IF active_count > 0 THEN
            -- به جای UPDATE، از INSERT جلوگیری می‌کنیم
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'An active avatar already exists for this entity. Deactivate it first.';
        END IF;
    END IF;
END
;;
delimiter ;

-- ----------------------------
-- Triggers structure for table entity_avatars
-- ----------------------------
DROP TRIGGER IF EXISTS `trg_avatar_single_active_upd`;
delimiter ;;
CREATE TRIGGER `trg_avatar_single_active_upd` BEFORE UPDATE ON `entity_avatars` FOR EACH ROW BEGIN
    DECLARE active_count INT;

    IF NEW.is_active = 1 AND OLD.is_active = 0 THEN
        SELECT COUNT(*) INTO active_count
          FROM entity_avatars
         WHERE entity_id = NEW.entity_id
           AND is_active = 1
           AND avatar_id != NEW.avatar_id;

        IF active_count > 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'An active avatar already exists for this entity. Deactivate it first.';
        END IF;
    END IF;
END
;;
delimiter ;

-- ----------------------------
-- Triggers structure for table entity_memberships
-- ----------------------------
DROP TRIGGER IF EXISTS `trg_check_membership_capacity`;
delimiter ;;
CREATE TRIGGER `trg_check_membership_capacity` BEFORE INSERT ON `entity_memberships` FOR EACH ROW BEGIN
    DECLARE v_entity_type VARCHAR(20);
    DECLARE v_capacity     INT UNSIGNED;
    DECLARE v_current_count INT UNSIGNED;

    -- فقط برای عضویت‌های فعال بررسی انجام شود
    IF NEW.is_active = TRUE THEN

        -- نوع entity والد را بگیر
        SELECT entity_type INTO v_entity_type
        FROM entities
        WHERE entity_id = NEW.parent_entity_id;

        IF v_entity_type = 'channel' THEN
            -- ظرفیت از channel_meta
            SELECT subscriber_count INTO v_capacity
            FROM channel_meta
            WHERE entity_id = NEW.parent_entity_id;

        ELSEIF v_entity_type = 'group' THEN
            -- ظرفیت از group_meta
            SELECT member_limit INTO v_capacity
            FROM group_meta
            WHERE entity_id = NEW.parent_entity_id;

        ELSE
            -- برای user/bot نیازی به بررسی نیست
            SET v_capacity = NULL;
        END IF;

        -- اگر ظرفیت تعریف شده باشد، بررسی کن
        IF v_capacity IS NOT NULL THEN
            SELECT COUNT(*) INTO v_current_count
            FROM entity_memberships
            WHERE parent_entity_id = NEW.parent_entity_id
              AND is_active = TRUE;

            IF v_current_count >= v_capacity THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'Membership capacity limit reached for this entity';
            END IF;
        END IF;

    END IF;
END
;;
delimiter ;

-- ----------------------------
-- Triggers structure for table message_states
-- ----------------------------
DROP TRIGGER IF EXISTS `trg_message_forward_depth`;
delimiter ;;
CREATE TRIGGER `trg_message_forward_depth` BEFORE INSERT ON `message_states` FOR EACH ROW BEGIN
    DECLARE max_depth TINYINT;

    IF NEW.forwarded_from_id IS NOT NULL THEN
        SELECT COALESCE(MAX(forward_depth), 0) + 1 INTO max_depth
          FROM message_states
         WHERE message_id = NEW.message_id;

        IF max_depth > 10 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Forward depth limit exceeded';
        END IF;

        SET NEW.forward_depth = max_depth;
    END IF;
END
;;
delimiter ;

-- ----------------------------
-- Triggers structure for table message_states
-- ----------------------------
DROP TRIGGER IF EXISTS `trg_message_delivered`;
delimiter ;;
CREATE TRIGGER `trg_message_delivered` BEFORE UPDATE ON `message_states` FOR EACH ROW BEGIN
    IF NEW.is_delivered = TRUE AND OLD.is_delivered = FALSE THEN
        SET NEW.delivered_at = CURRENT_TIMESTAMP;
    END IF;
END
;;
delimiter ;

-- ----------------------------
-- Triggers structure for table message_states
-- ----------------------------
DROP TRIGGER IF EXISTS `trg_message_read`;
delimiter ;;
CREATE TRIGGER `trg_message_read` BEFORE UPDATE ON `message_states` FOR EACH ROW BEGIN
    IF NEW.is_read = TRUE AND OLD.is_read = FALSE THEN
        SET NEW.read_at = CURRENT_TIMESTAMP;
    END IF;
END
;;
delimiter ;

-- ----------------------------
-- Triggers structure for table message_states
-- ----------------------------
DROP TRIGGER IF EXISTS `trg_message_deleted`;
delimiter ;;
CREATE TRIGGER `trg_message_deleted` BEFORE UPDATE ON `message_states` FOR EACH ROW BEGIN
    IF NEW.is_deleted = TRUE AND OLD.is_deleted = FALSE THEN
        SET NEW.deleted_at = CURRENT_TIMESTAMP;
    END IF;
END
;;
delimiter ;

SET FOREIGN_KEY_CHECKS = 1;
