-- =====================================================================
-- 1️⃣6️⃣ EXAMPLE DATA
-- =====================================================================

INSERT INTO entities (entity_type, display_name, username, password_hash) VALUES
('user',    'علی احمدی',   'ali_ahmadi',      SHA2(CONCAT('mypassword','ali_ahmadi'),256)),
('user',    'مریم رضایی',  'maryam_rezaei',   SHA2(CONCAT('mypassword','maryam_rezaei'),256)),
('user',    'سارا محمدی',  'sara_mohammadi',  SHA2(CONCAT('mypassword','sara_mohammadi'),256)),
('group',   'گروه توسعه',  'dev_group',       NULL),
('channel', 'کانال اخبار', 'news_channel',    NULL);

-- پروفایل کاربران
INSERT INTO user_profiles (entity_id, bio, birth_date, gender, language, timezone) VALUES
(1, 'توسعه‌دهنده نرم‌افزار',  '1995-05-15', 'male',   'fa', 'Asia/Tehran'),
(2, 'طراح رابط کاربری',       '1998-09-22', 'female', 'fa', 'Asia/Tehran'),
(3, 'مدیر محصول',             '1993-03-10', 'female', 'fa', 'Asia/Tehran');

-- متادیتای گروه
INSERT INTO group_meta (entity_id, description, member_limit, is_public) VALUES
(4, 'گروه تیم توسعه محصول', 50, 0);

-- متادیتای کانال
INSERT INTO channel_meta (entity_id, description, is_public) VALUES
(5, 'کانال اخبار و اطلاعیه‌های رسمی', 1);

-- ایمیل‌ها
INSERT INTO user_emails (entity_id, email, is_primary, is_verified, verified_at) VALUES
(1, 'ali@example.com',    1, 1, NOW()),
(2, 'maryam@example.com', 1, 1, NOW()),
(3, 'sara@example.com',   1, 1, NOW());

-- شماره‌ها
INSERT INTO user_phones (entity_id, phone, is_primary, is_verified, verified_at) VALUES
(1, '+989121234567', 1, 1, NOW()),
(2, '+989359876543', 1, 1, NOW());

-- آواتارها
INSERT INTO entity_avatars (entity_id, avatar_url, is_active, display_order) VALUES
(1, '/avatars/ali_001.jpg',       1, 1),
(1, '/avatars/ali_002.jpg',       0, 2),
(2, '/avatars/maryam_001.jpg',    1, 1),
(4, '/avatars/devgroup_001.jpg',  1, 1);

-- تجهیزات
INSERT INTO equipments (device_uuid, device_type, device_name, os_version, app_version) VALUES
('uuid-android-ali-001',   'android', 'Samsung Galaxy S21', 'Android 13', '1.2.0'),
('uuid-stm32-ali-002',     'stm32',   'STM32F4 Walkie',     NULL,         '0.9.0'),
('uuid-ios-maryam-001',    'ios',     'iPhone 13 Pro',      'iOS 16.4',   '1.2.0');

-- عضویت‌ها
INSERT INTO entity_memberships (parent_entity_id, member_entity_id, role) VALUES
(4, 1, 'owner'),
(4, 2, 'admin'),
(4, 3, 'member');

-- =====================================================================
-- 1️⃣7️⃣ EXAMPLE QUERIES
-- =====================================================================

-- 📨 1. ارسال پیام صوتی ساده (علی → مریم)
START TRANSACTION;
INSERT INTO messages (owner_entity_id, content_type, audio_duration, audio_format, audio_sample_rate)
VALUES (1, 'audio', 5000, 'pcm16', 16000);

INSERT INTO message_states (message_id, sender_entity_id, receiver_entity_id)
VALUES (LAST_INSERT_ID(), 1, 2);
COMMIT;

-- 🔄 2. فوروارد پیام (مریم → گروه)
START TRANSACTION;
INSERT INTO message_states (
    message_id, sender_entity_id, receiver_entity_id,
    parent_entity_id, forwarded_from_id
) VALUES (
    1, 2, NULL, 4, 1
);
COMMIT;

-- 🔄 3. فوروارد زنجیره‌ای (سارا → کانال)
START TRANSACTION;
INSERT INTO message_states (
    message_id, sender_entity_id, receiver_entity_id,
    parent_entity_id, forwarded_from_id
) VALUES (
    1, 3, NULL, 5, 2
);
COMMIT;

-- 📬 4. کوئری unread messages
SELECT
    m.message_id,
    m.content_type,
    m.content_text,
    sender.display_name                                                   AS sender_name,
    ms.created_at,
    CASE WHEN ms.forwarded_from_id IS NOT NULL
         THEN (SELECT display_name FROM entities WHERE entity_id = ms.forwarded_from_id)
         ELSE NULL
    END                                                                   AS forwarded_from
FROM message_states ms
INNER JOIN messages  m      ON ms.message_id       = m.message_id
INNER JOIN entities  sender ON ms.sender_entity_id = sender.entity_id
WHERE ms.receiver_entity_id = 2
  AND ms.is_read    = FALSE
  AND ms.is_deleted = FALSE
ORDER BY ms.created_at DESC;

-- 📊 5. تاریخچه گروه
SELECT
    m.content_type,
    m.content_text,
    sender.display_name AS sender_name,
    ms.created_at,
    ms.forward_depth
FROM message_states ms
INNER JOIN messages m      ON ms.message_id       = m.message_id
INNER JOIN entities sender ON ms.sender_entity_id = sender.entity_id
WHERE ms.parent_entity_id = 4
  AND ms.is_deleted = FALSE
ORDER BY ms.created_at DESC
LIMIT 50;

-- 🔍 6. یافتن همه فوروارد‌های یک پیام
SELECT
    sender.display_name                                        AS forwarded_by,
    COALESCE(receiver.display_name, parent.display_name)      AS forwarded_to,
    ms.forward_depth,
    ms.created_at
FROM message_states ms
LEFT JOIN entities sender   ON ms.sender_entity_id   = sender.entity_id
LEFT JOIN entities receiver ON ms.receiver_entity_id = receiver.entity_id
LEFT JOIN entities parent   ON ms.parent_entity_id   = parent.entity_id
WHERE ms.message_id        = 1
  AND ms.forwarded_from_id IS NOT NULL
ORDER BY ms.forward_depth;

-- 📈 7. آمار پیام‌های یک کاربر
SELECT
    e.display_name,
    COUNT(DISTINCT m.message_id)                                    AS total_messages_created,
    COUNT(DISTINCT ms.state_id)                                     AS total_messages_sent,
    SUM(CASE WHEN m.content_type = 'audio'         THEN 1 ELSE 0 END) AS audio_messages,
    SUM(CASE WHEN ms.forwarded_from_id IS NOT NULL THEN 1 ELSE 0 END) AS forwarded_messages
FROM entities e
LEFT JOIN messages      m  ON e.entity_id = m.owner_entity_id
LEFT JOIN message_states ms ON e.entity_id = ms.sender_entity_id
WHERE e.entity_id = 1
GROUP BY e.entity_id, e.display_name;

-- 👤 8. پروفایل کامل کاربر (از view)
SELECT * FROM v_user_profile WHERE entity_id = 1;

-- 🖼️ 9. تاریخچه آواتارهای یک entity
SELECT
    avatar_id,
    avatar_url,
    is_active,
    display_order,
    uploaded_at
FROM entity_avatars
WHERE entity_id = 1
ORDER BY display_order;

-- =====================================================================
-- ✅ VERIFICATION QUERIES
-- =====================================================================

-- بررسی ساختار جداول
SHOW TABLES;

-- بررسی constraint ها
SELECT
    TABLE_NAME,
    CONSTRAINT_NAME,
    CONSTRAINT_TYPE
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA = DATABASE()
ORDER BY TABLE_NAME, CONSTRAINT_TYPE;

-- بررسی indexes
SELECT
    TABLE_NAME,
    INDEX_NAME,
    GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS COLUMNS
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = DATABASE()
GROUP BY TABLE_NAME, INDEX_NAME
ORDER BY TABLE_NAME, INDEX_NAME;