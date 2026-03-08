-- =====================================================================
-- 🎯 Messenger Database Schema - PRODUCTION READY (MySQL 8.0)
-- نسخه: 2.2 MySQL (اصلاح M1 + M2)
-- تاریخ: 1404/12/08 (2026/02/27)
-- معماری: Typed Relational (جایگزین Hybrid EAV)
-- Database Engine: MySQL 8.0+
-- =====================================================================

-- CREATE DATABASE messengerDb
--     CHARACTER SET utf8mb4
--     COLLATE utf8mb4_persian_ci;

-- MySQL Configuration
SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;
SET character_set_connection = utf8mb4;
SET FOREIGN_KEY_CHECKS = 1;
SET SQL_MODE = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- Create Database (optional - uncomment if needed)
-- CREATE DATABASE IF NOT EXISTS qml_walkie_talkie
-- CHARACTER SET utf8mb4
-- COLLATE utf8mb4_unicode_ci;
-- USE qml_walkie_talkie;

-- =====================================================================
-- 1️⃣ ENTITIES - موجودیت‌های اصلی
-- =====================================================================

DROP TABLE IF EXISTS entity_tags;
DROP TABLE IF EXISTS tags;
DROP TABLE IF EXISTS message_states;
DROP TABLE IF EXISTS messages;
DROP TABLE IF EXISTS sessions;
DROP TABLE IF EXISTS equipments;
DROP TABLE IF EXISTS entity_memberships;
DROP TABLE IF EXISTS user_phones;
DROP TABLE IF EXISTS user_emails;
DROP TABLE IF EXISTS user_profiles;
DROP TABLE IF EXISTS group_meta;
DROP TABLE IF EXISTS channel_meta;
DROP TABLE IF EXISTS entity_avatars;
DROP TABLE IF EXISTS entities;

CREATE TABLE entities (
    entity_id    BIGINT UNSIGNED  AUTO_INCREMENT PRIMARY KEY,
    entity_type  ENUM('user', 'group', 'channel') NOT NULL,

    -- اطلاعات پایه
    display_name  VARCHAR(255) NOT NULL,
    username      VARCHAR(64)  NOT NULL UNIQUE,
    password_hash VARCHAR(255) DEFAULT NULL,

    -- متادیتای سریع (JSON) — فقط برای کَش سمت اپلیکیشن
    quick_meta JSON DEFAULT NULL,

    -- زمان‌ها
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
               ON UPDATE CURRENT_TIMESTAMP,

    -- وضعیت
    is_active  BOOLEAN DEFAULT TRUE,
    is_deleted BOOLEAN DEFAULT FALSE,

    -- password_hash فقط برای user ها اجباری
    CONSTRAINT chk_user_password CHECK (
        (entity_type = 'user'                    AND password_hash IS NOT NULL) OR
        (entity_type IN ('group', 'channel')     AND password_hash IS NULL)
    ),

    INDEX idx_entity_type_active (entity_type, is_active, is_deleted),
    INDEX idx_entity_created     (created_at DESC)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 2️⃣ ENTITY AVATARS - آواتارهای چندگانه (مشترک بین user/group/channel)
-- =====================================================================

CREATE TABLE entity_avatars (
    avatar_id     BIGINT UNSIGNED  AUTO_INCREMENT PRIMARY KEY,
    entity_id     BIGINT UNSIGNED  NOT NULL,

    avatar_url    VARCHAR(512)     NOT NULL,

    -- فقط یکی می‌تواند is_active=1 باشد (با trigger کنترل می‌شود)
    is_active     TINYINT(1)       NOT NULL DEFAULT 0,

    -- ترتیب نمایش تاریخچه آواتارها
    display_order SMALLINT UNSIGNED NOT NULL DEFAULT 0,

    uploaded_at   TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_ea_entity
        FOREIGN KEY (entity_id) REFERENCES entities(entity_id)
        ON DELETE CASCADE,

    INDEX idx_ea_entity        (entity_id),
    INDEX idx_ea_entity_active (entity_id, is_active)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 3️⃣ USER PROFILES - پروفایل کاربران (1:1 با entities)
-- =====================================================================

CREATE TABLE user_profiles (
    user_profile_id    BIGINT UNSIGNED  AUTO_INCREMENT PRIMARY KEY,
    entity_id          BIGINT UNSIGNED  NOT NULL,

    -- محتوا
    bio                TEXT             DEFAULT NULL,
    birth_date         DATE             DEFAULT NULL,
    gender             ENUM(
                           'male',
                           'female',
                           'other',
                           'prefer_not_to_say'
                       )                DEFAULT NULL,

    -- منطقه‌بندی
    language           CHAR(5)          NOT NULL DEFAULT 'fa',
    timezone           VARCHAR(64)      NOT NULL DEFAULT 'Asia/Tehran',

    -- تصویر بنر (همیشه یکی — برخلاف آواتار)
    banner_url         VARCHAR(512)     DEFAULT NULL,

    -- حریم خصوصی last_seen
    last_seen_at       TIMESTAMP        DEFAULT NULL,
    last_seen_privacy  ENUM(
                           'everyone',
                           'contacts',
                           'nobody'
                       )                NOT NULL DEFAULT 'everyone',

    -- انعطاف برای فیلدهای آینده بدون ALTER TABLE
    extra_meta         JSON             DEFAULT NULL,

    created_at         TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP
                       ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_up_entity
        FOREIGN KEY (entity_id) REFERENCES entities(entity_id)
        ON DELETE CASCADE

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 4️⃣ USER EMAILS - ایمیل‌های چندگانه کاربران
-- =====================================================================

CREATE TABLE user_emails (
    email_id    BIGINT UNSIGNED  AUTO_INCREMENT PRIMARY KEY,
    entity_id   BIGINT UNSIGNED  NOT NULL,

    email       VARCHAR(255)     NOT NULL,
    is_primary  TINYINT(1)       NOT NULL DEFAULT 0,
    is_verified TINYINT(1)       NOT NULL DEFAULT 0,
    verified_at TIMESTAMP        DEFAULT NULL,

    created_at  TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_ue_entity
        FOREIGN KEY (entity_id) REFERENCES entities(entity_id)
        ON DELETE CASCADE,

    UNIQUE INDEX uq_ue_email    (email),
    INDEX idx_ue_entity         (entity_id),
    INDEX idx_ue_primary        (entity_id, is_primary)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 5️⃣ USER PHONES - شماره‌های چندگانه کاربران
-- =====================================================================

CREATE TABLE user_phones (
    phone_id    BIGINT UNSIGNED  AUTO_INCREMENT PRIMARY KEY,
    entity_id   BIGINT UNSIGNED  NOT NULL,

    -- فرمت استاندارد E.164 — مثل: +989123456789
    phone       VARCHAR(20)      NOT NULL,
    is_primary  TINYINT(1)       NOT NULL DEFAULT 0,
    is_verified TINYINT(1)       NOT NULL DEFAULT 0,
    verified_at TIMESTAMP        DEFAULT NULL,

    created_at  TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_uph_entity
        FOREIGN KEY (entity_id) REFERENCES entities(entity_id)
        ON DELETE CASCADE,

    UNIQUE INDEX uq_uph_phone   (phone),
    INDEX idx_uph_entity        (entity_id),
    INDEX idx_uph_primary       (entity_id, is_primary)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 6️⃣ GROUP META - متادیتای گروه‌ها (1:1 با entities)
-- =====================================================================

CREATE TABLE group_meta (
    group_meta_id   BIGINT UNSIGNED  AUTO_INCREMENT PRIMARY KEY,
    entity_id    BIGINT UNSIGNED  NOT NULL,

    description  TEXT             DEFAULT NULL,
    member_limit INT UNSIGNED     NOT NULL DEFAULT 200,
    is_public    TINYINT(1)       NOT NULL DEFAULT 0,

    -- بنر گروه (همیشه یکی)
    banner_url   VARCHAR(512)     DEFAULT NULL,

    extra_meta   JSON             DEFAULT NULL,

    created_at   TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP
                 ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_gm_entity
        FOREIGN KEY (entity_id) REFERENCES entities(entity_id)
        ON DELETE CASCADE

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 7️⃣ CHANNEL META - متادیتای کانال‌ها (1:1 با entities)
-- =====================================================================

CREATE TABLE channel_meta (
    channel_meta_id  BIGINT UNSIGNED  AUTO_INCREMENT PRIMARY KEY,
    entity_id        BIGINT UNSIGNED  NOT NULL,

    description      TEXT             DEFAULT NULL,
    is_public        TINYINT(1)       NOT NULL DEFAULT 0,
    subscriber_count INT UNSIGNED     NOT NULL DEFAULT 0,

    -- بنر کانال (همیشه یکی)
    banner_url       VARCHAR(512)     DEFAULT NULL,

    extra_meta       JSON             DEFAULT NULL,

    created_at       TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP
                     ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_cm_entity
        FOREIGN KEY (entity_id) REFERENCES entities(entity_id)
        ON DELETE CASCADE

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 8️⃣ EQUIPMENTS - تجهیزات
-- =====================================================================

CREATE TABLE equipments (
    equipment_id     BIGINT UNSIGNED  AUTO_INCREMENT PRIMARY KEY,

    device_uuid      VARCHAR(128)     UNIQUE NOT NULL,
    device_type      ENUM('android', 'ios', 'desktop', 'web', 'stm32', 'other') NOT NULL,

    device_name      VARCHAR(255)     DEFAULT NULL,
    os_version       VARCHAR(64)      DEFAULT NULL,
    app_version      VARCHAR(32)      DEFAULT NULL,
    hardware_info    JSON             DEFAULT NULL,

    created_at         TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_activity_at   TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP
                       ON UPDATE CURRENT_TIMESTAMP,

    is_active        BOOLEAN          DEFAULT TRUE,

    INDEX idx_device_uuid          (device_uuid),
    INDEX idx_device_type          (device_type, is_active),
    INDEX idx_device_last_activity (last_activity_at DESC)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 9️⃣ SESSIONS - نشست‌ها
-- =====================================================================

CREATE TABLE sessions (
    session_id       BIGINT UNSIGNED  AUTO_INCREMENT PRIMARY KEY,
    entity_id        BIGINT UNSIGNED  NOT NULL,
    equipment_id     BIGINT UNSIGNED  DEFAULT NULL,

    -- M1 Fix: توکن خام ذخیره نمی‌شود
    -- Application باید SHA-256(raw_token).toHex() ذخیره کند
    -- CHAR(64) = طول ثابت SHA-256 hex digest
    session_token    CHAR(64)         NOT NULL,
    refresh_token    CHAR(64)         DEFAULT NULL,

    ip_address       VARCHAR(45)      DEFAULT NULL,
    user_agent       TEXT             DEFAULT NULL,

    created_at       TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_activity_at TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP
                     ON UPDATE CURRENT_TIMESTAMP,
    expires_at       TIMESTAMP        NOT NULL,

    CONSTRAINT uq_session_token UNIQUE (session_token),
    CONSTRAINT uq_refresh_token UNIQUE (refresh_token),

    CONSTRAINT fk_sess_entity
        FOREIGN KEY (entity_id)    REFERENCES entities(entity_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_sess_equipment
        FOREIGN KEY (equipment_id) REFERENCES equipments(equipment_id)
        ON DELETE SET NULL,

    INDEX idx_session_token        (session_token),
    INDEX idx_session_entity_valid (entity_id, expires_at),
    INDEX idx_session_equipment    (equipment_id)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 🔟 ENTITY MEMBERSHIPS - عضویت‌ها
-- =====================================================================

CREATE TABLE entity_memberships (
    membership_id    BIGINT UNSIGNED  AUTO_INCREMENT PRIMARY KEY,

    parent_entity_id BIGINT UNSIGNED  NOT NULL,
    member_entity_id BIGINT UNSIGNED  NOT NULL,

    role ENUM(
        'owner',
        'admin',
        'moderator',
        'member',
        'restricted',
        'contact'
    ) DEFAULT 'member',

    permissions JSON     DEFAULT NULL,

    joined_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    left_at      TIMESTAMP DEFAULT NULL,

    is_active    BOOLEAN  DEFAULT TRUE,
    is_muted     BOOLEAN  DEFAULT FALSE,
    is_banned    BOOLEAN  DEFAULT FALSE,

    CONSTRAINT fk_em_parent
        FOREIGN KEY (parent_entity_id) REFERENCES entities(entity_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_em_member
        FOREIGN KEY (member_entity_id) REFERENCES entities(entity_id)
        ON DELETE CASCADE,

    UNIQUE KEY uk_membership              (parent_entity_id, member_entity_id),
    INDEX idx_membership_parent_active    (parent_entity_id, is_active),
    INDEX idx_membership_member_active    (member_entity_id, is_active),
    INDEX idx_membership_role             (parent_entity_id, role)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 1️⃣1️⃣ MESSAGES - محتوای پیام‌ها
-- =====================================================================

CREATE TABLE messages (
    message_id       BIGINT UNSIGNED  AUTO_INCREMENT PRIMARY KEY,

    -- صاحب اصلی پیام
    owner_entity_id  BIGINT UNSIGNED  NOT NULL,
    writer_entity_id  BIGINT UNSIGNED  NOT NULL,

    -- نوع و محتوا
    content_type     ENUM(
                         'text', 'audio', 'image', 'video',
                         'file', 'location', 'contact', 'poll'
                     ) NOT NULL,
    content_text     TEXT             DEFAULT NULL,
    content_data     JSON             DEFAULT NULL,

    -- ویژگی‌های صوتی (Walkie-Talkie)
    audio_duration    INT UNSIGNED    DEFAULT NULL,
    audio_format      VARCHAR(16)     DEFAULT 'pcm16',
    audio_sample_rate INT UNSIGNED    DEFAULT 16000,
    audio_channels    TINYINT UNSIGNED DEFAULT 1,

    -- فایل‌ها
    file_path         VARCHAR(512)    DEFAULT NULL,
    file_size         BIGINT UNSIGNED DEFAULT NULL,
    file_mime_type    VARCHAR(128)    DEFAULT NULL,
    thumbnail_path    VARCHAR(512)    DEFAULT NULL,

    -- زمان‌ها
    created_at    TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP
                  ON UPDATE CURRENT_TIMESTAMP,
    scheduled_at  TIMESTAMP  DEFAULT NULL,
    expires_at    TIMESTAMP  DEFAULT NULL,

    -- وضعیت
    is_deleted    BOOLEAN    DEFAULT FALSE,

    CONSTRAINT fk_msg_owner
        FOREIGN KEY (owner_entity_id) REFERENCES entities(entity_id)
        ON DELETE CASCADE,

    INDEX idx_msg_owner       (owner_entity_id, created_at DESC),
    INDEX idx_msg_type        (content_type),
    INDEX idx_msg_created     (created_at DESC),
    INDEX idx_msg_scheduled   (scheduled_at),
    INDEX idx_msg_owner_type  (owner_entity_id, content_type, created_at DESC)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 1️⃣2️⃣ MESSAGE STATES - وضعیت پیام برای هر گیرنده
-- =====================================================================

CREATE TABLE message_states (
    state_id           BIGINT UNSIGNED  AUTO_INCREMENT PRIMARY KEY,
    message_id         BIGINT UNSIGNED  NOT NULL,

    -- فرستنده و گیرنده این نسخه خاص
    sender_entity_id   BIGINT UNSIGNED  NOT NULL,
    receiver_entity_id BIGINT UNSIGNED  DEFAULT NULL,

    -- گروه/کانال (اگر پیام گروهی باشد)
    parent_entity_id   BIGINT UNSIGNED  DEFAULT NULL,

    -- پاسخ و فوروارد
    reply_to_message_id BIGINT UNSIGNED DEFAULT NULL,
    forwarded_from_id   BIGINT UNSIGNED DEFAULT NULL,

    -- عمق forward (جلوگیری از زنجیره بی‌نهایت)
    forward_depth  TINYINT UNSIGNED     DEFAULT 0,

    -- وضعیت دریافت
    is_delivered   BOOLEAN  DEFAULT FALSE,
    delivered_at   TIMESTAMP DEFAULT NULL,

    -- وضعیت خواندن
    is_read        BOOLEAN  DEFAULT FALSE,
    read_at        TIMESTAMP DEFAULT NULL,

    -- وضعیت حذف (local delete)
    is_deleted     BOOLEAN  DEFAULT FALSE,
    deleted_at     TIMESTAMP DEFAULT NULL,

    -- ستاره‌دار
    is_starred     BOOLEAN  DEFAULT FALSE,

    created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_ms_message
        FOREIGN KEY (message_id)           REFERENCES messages(message_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_ms_sender
        FOREIGN KEY (sender_entity_id)     REFERENCES entities(entity_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_ms_receiver
        FOREIGN KEY (receiver_entity_id)   REFERENCES entities(entity_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_ms_parent
        FOREIGN KEY (parent_entity_id)     REFERENCES entities(entity_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_ms_reply
        FOREIGN KEY (reply_to_message_id)  REFERENCES messages(message_id)
        ON DELETE SET NULL,
    CONSTRAINT fk_ms_forward
        FOREIGN KEY (forwarded_from_id)    REFERENCES entities(entity_id)
        ON DELETE SET NULL,

    CONSTRAINT chk_forward_depth CHECK (forward_depth >= 0 AND forward_depth <= 10),

    UNIQUE KEY uk_message_state (message_id, sender_entity_id, receiver_entity_id, parent_entity_id),

    INDEX idx_state_message         (message_id),
    INDEX idx_state_receiver_unread (receiver_entity_id, is_read, created_at DESC),
    INDEX idx_state_parent          (parent_entity_id, created_at DESC),
    INDEX idx_state_sender          (sender_entity_id, created_at DESC),
    INDEX idx_state_unread_only     (receiver_entity_id, created_at DESC),
    INDEX idx_state_reply           (reply_to_message_id),
    INDEX idx_state_forward         (forwarded_from_id)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 1️⃣3️⃣ TAGS - تگ‌ها و دسته‌بندی
-- =====================================================================

CREATE TABLE tags (
    tag_id    BIGINT UNSIGNED  AUTO_INCREMENT PRIMARY KEY,
    tag_name  VARCHAR(64)      UNIQUE NOT NULL,
    tag_type  ENUM('system', 'custom', 'auto') DEFAULT 'custom',
    created_at TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE entity_tags (
    entity_id  BIGINT UNSIGNED  NOT NULL,
    tag_id     BIGINT UNSIGNED  NOT NULL,
    tagged_at  TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (entity_id, tag_id),

    CONSTRAINT fk_etag_entity
        FOREIGN KEY (entity_id) REFERENCES entities(entity_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_etag_tag
        FOREIGN KEY (tag_id)    REFERENCES tags(tag_id)
        ON DELETE CASCADE,

    INDEX idx_entity_tags_tag (tag_id)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 1️⃣4️⃣ TRIGGERS
-- =====================================================================

DELIMITER $$

-- -------------------------------------------------------
-- آواتار: تضمین تک آواتار فعال هنگام INSERT
-- -------------------------------------------------------
DROP TRIGGER IF EXISTS trg_avatar_single_active_ins$$
CREATE TRIGGER trg_avatar_single_active_ins
BEFORE INSERT ON entity_avatars
FOR EACH ROW
BEGIN
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
END$$

-- -------------------------------------------------------
-- آواتار: تضمین تک آواتار فعال هنگام UPDATE
-- -------------------------------------------------------
DROP TRIGGER IF EXISTS trg_avatar_single_active_upd$$
CREATE TRIGGER trg_avatar_single_active_upd
BEFORE UPDATE ON entity_avatars
FOR EACH ROW
BEGIN
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
END$$

-- -------------------------------------------------------
-- پیام: بروزرسانی خودکار delivered_at
-- -------------------------------------------------------
DROP TRIGGER IF EXISTS trg_message_delivered$$
CREATE TRIGGER trg_message_delivered
BEFORE UPDATE ON message_states
FOR EACH ROW
BEGIN
    IF NEW.is_delivered = TRUE AND OLD.is_delivered = FALSE THEN
        SET NEW.delivered_at = CURRENT_TIMESTAMP;
    END IF;
END$$

-- -------------------------------------------------------
-- پیام: بروزرسانی خودکار read_at
-- -------------------------------------------------------
DROP TRIGGER IF EXISTS trg_message_read$$
CREATE TRIGGER trg_message_read
BEFORE UPDATE ON message_states
FOR EACH ROW
BEGIN
    IF NEW.is_read = TRUE AND OLD.is_read = FALSE THEN
        SET NEW.read_at = CURRENT_TIMESTAMP;
    END IF;
END$$

-- -------------------------------------------------------
-- پیام: بروزرسانی خودکار deleted_at
-- -------------------------------------------------------
DROP TRIGGER IF EXISTS trg_message_deleted$$
CREATE TRIGGER trg_message_deleted
BEFORE UPDATE ON message_states
FOR EACH ROW
BEGIN
    IF NEW.is_deleted = TRUE AND OLD.is_deleted = FALSE THEN
        SET NEW.deleted_at = CURRENT_TIMESTAMP;
    END IF;
END$$

-- -------------------------------------------------------
-- پیام: محاسبه خودکار forward_depth
-- -------------------------------------------------------
DROP TRIGGER IF EXISTS trg_message_forward_depth$$
CREATE TRIGGER trg_message_forward_depth
BEFORE INSERT ON message_states
FOR EACH ROW
BEGIN
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
END$$

-- ============================================================
-- M1 FIX: Capacity validation before new membership
-- Prevents exceeding subscriber_count (channels) or member_limit (groups)
-- ============================================================

CREATE TRIGGER trg_check_membership_capacity
BEFORE INSERT ON entity_memberships
FOR EACH ROW
BEGIN
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
END$$

DELIMITER ;

-- =====================================================================
-- 1️⃣5️⃣ VIEWS
-- =====================================================================

-- Unread summary
DROP VIEW IF EXISTS v_unread_summary;
CREATE VIEW v_unread_summary AS
SELECT
    ms.receiver_entity_id                                               AS entity_id,
    COUNT(*)                                                            AS unread_count,
    MAX(ms.created_at)                                                  AS last_message_at,
    SUM(CASE WHEN m.content_type = 'audio' THEN 1 ELSE 0 END)          AS unread_audio_count,
    SUM(CASE WHEN ms.is_starred = TRUE     THEN 1 ELSE 0 END)          AS starred_count
FROM message_states ms
INNER JOIN messages m ON ms.message_id = m.message_id
WHERE ms.is_read    = FALSE
  AND ms.is_deleted = FALSE
GROUP BY ms.receiver_entity_id;

-- Chat list with last message + unread count
DROP VIEW IF EXISTS v_chat_list;
CREATE VIEW v_chat_list AS
WITH last_messages AS (
    SELECT
        COALESCE(ms.parent_entity_id, ms.receiver_entity_id, ms.sender_entity_id) AS chat_id,
        ms.message_id,
        ms.sender_entity_id,
        ms.receiver_entity_id,
        ms.parent_entity_id,
        ms.created_at,
        ms.is_read,
        ROW_NUMBER() OVER (
            PARTITION BY COALESCE(ms.parent_entity_id, ms.receiver_entity_id, ms.sender_entity_id)
            ORDER BY ms.created_at DESC
        ) AS rn
    FROM message_states ms
    WHERE ms.is_deleted = FALSE
)
SELECT
    lm.chat_id,
    e.entity_type                                                       AS chat_type,
    e.display_name                                                      AS chat_name,
    -- آواتار فعال چت
    ea.avatar_url                                                       AS chat_avatar,
    m.content_type,
    m.content_text,
    sender.display_name                                                 AS last_sender,
    lm.created_at                                                       AS last_message_at,
    COALESCE(
        (SELECT COUNT(*)
           FROM message_states ms2
          WHERE COALESCE(ms2.parent_entity_id, ms2.sender_entity_id) = lm.chat_id
            AND ms2.is_read    = FALSE
            AND ms2.is_deleted = FALSE),
        0
    )                                                                   AS unread_count
FROM last_messages lm
INNER JOIN messages  m      ON lm.message_id       = m.message_id
INNER JOIN entities  e      ON lm.chat_id          = e.entity_id
INNER JOIN entities  sender ON lm.sender_entity_id = sender.entity_id
LEFT  JOIN entity_avatars ea
        ON ea.entity_id = lm.chat_id
       AND ea.is_active = 1
WHERE lm.rn = 1;

-- Forward chain tracking
DROP VIEW IF EXISTS v_forward_chains;
CREATE VIEW v_forward_chains AS
SELECT
    ms.message_id,
    m.owner_entity_id    AS original_sender,
    ms.sender_entity_id  AS current_sender,
    ms.forwarded_from_id,
    ms.forward_depth,
    ms.created_at        AS forwarded_at
FROM message_states ms
INNER JOIN messages m ON ms.message_id = m.message_id
WHERE ms.forwarded_from_id IS NOT NULL
ORDER BY ms.message_id, ms.forward_depth;

-- پروفایل کامل کاربر
DROP VIEW IF EXISTS v_user_profile;
CREATE VIEW v_user_profile AS
SELECT
    e.entity_id,
    e.display_name,
    e.username,
    e.is_active,
    up.bio,
    up.birth_date,
    up.gender,
    up.language,
    up.timezone,
    up.banner_url,
    up.last_seen_at,
    up.last_seen_privacy,
    ea.avatar_url                                       AS active_avatar,
    ue.email                                            AS primary_email,
    uph.phone                                           AS primary_phone
FROM entities e
LEFT JOIN user_profiles  up  ON up.entity_id  = e.entity_id
LEFT JOIN entity_avatars ea  ON ea.entity_id  = e.entity_id AND ea.is_active  = 1
LEFT JOIN user_emails    ue  ON ue.entity_id  = e.entity_id AND ue.is_primary = 1
LEFT JOIN user_phones    uph ON uph.entity_id = e.entity_id AND uph.is_primary = 1
WHERE e.entity_type = 'user'
  AND e.is_deleted  = FALSE;
