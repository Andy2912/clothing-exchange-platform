/*add database admin for safety?
users: last_login, banned, phone nr
clothes: need to show multiple pictures(how?)
if disliked -> make sure items dont show up anymore*/

-- =============================================
-- Clothing Swap App Database Schema
-- SQL Server / T-SQL
-- Last improved: March 2025
-- =============================================
IF DB_ID(N'swipestyle') IS NULL
    CREATE DATABASE swipestyle;
GO
USE swipestyle;
GO
-- =============================================
-- 1. USERS
-- =============================================
CREATE TABLE users (
    user_id         INT IDENTITY(1,1) PRIMARY KEY,
    username        VARCHAR(50)   UNIQUE NOT NULL,
    email           VARCHAR(100)  UNIQUE NOT NULL,
    password_hash   VARCHAR(255)  NOT NULL,
    last_login      DATETIME2(0)  NULL,
    is_active       BIT           NOT NULL DEFAULT 1,
    gender          CHAR(1)   NULL,
    country         VARCHAR(100)  NULL,
    city            VARCHAR(100)  NULL,
    postal_code     VARCHAR(20)   NULL,
    street_address  VARCHAR(255) NULL,     -- for main address
    street_address2 VARCHAR(255) NULL,     -- for apartment/suite numbers
    profile_pic_url VARCHAR(255)  NULL,
    bio             VARCHAR(MAX)  NULL,
    created_at      DATETIME2(0)  NOT NULL DEFAULT GETDATE(),
    updated_at      DATETIME2(0) NOT NULL DEFAULT GETDATE()
);
GO
-- =============================================
-- 2. CLOTHING ITEMS
-- =============================================
CREATE TABLE clothes (
    cloth_id         INT IDENTITY(1,1) PRIMARY KEY,
    user_id          INT          NOT NULL,
    name             VARCHAR(100) NOT NULL,
    description      VARCHAR(MAX) NULL,
    image_url        VARCHAR(255) NULL,
    category         VARCHAR(50)  NULL,     -- e.g. 'jackets', 'hoodies', 'pants', 'shoes'
    brand            VARCHAR(50)  NULL,
    size             VARCHAR(20)  NULL,
    color            VARCHAR(30)  NULL,
    material         VARCHAR(50)  NULL,
    gender           CHAR(1)   NULL,        -- e.g. 'M', 'F', 'U' for unisex
    condition_rating VARCHAR(20)  NULL
        CONSTRAINT CHK_clothes_condition
        CHECK (condition_rating IN ('new', 'like_new', 'good', 'worn', 'damaged')),
    estimated_value  DECIMAL(10,2) NULL,
    is_available     BIT          NOT NULL DEFAULT 1,
    created_at       DATETIME2(0) NOT NULL DEFAULT GETDATE(),
    updated_at       DATETIME2(0) NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_clothes_users
        FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE CASCADE           -- delete clothes when user is deleted
        ON UPDATE NO ACTION
);
GO
-- =============================================
-- 3. SWIPES / LIKES
-- =============================================
CREATE TABLE swipes (
    swipe_id        INT IDENTITY(1,1) PRIMARY KEY,
    swiper_user_id  INT          NOT NULL,
    swiped_cloth_id INT          NOT NULL,
    action          VARCHAR(10)  NOT NULL
        CONSTRAINT CHK_swipes_action
        CHECK (action IN ('like', 'dislike')),
    created_at      DATETIME2(0) NOT NULL DEFAULT GETDATE(),
    CONSTRAINT UQ_swipes UNIQUE (swiper_user_id, swiped_cloth_id),
    CONSTRAINT FK_swipes_swiper
        FOREIGN KEY (swiper_user_id) REFERENCES users(user_id)
        ON DELETE NO ACTION         -- prevent cascade cycles
        ON UPDATE NO ACTION,
    CONSTRAINT FK_swipes_cloth
        FOREIGN KEY (swiped_cloth_id) REFERENCES clothes(cloth_id)
        ON DELETE CASCADE           -- swipe disappears if item is deleted
        ON UPDATE NO ACTION
);
GO
-- =============================================
-- 4. MATCHES (mutual likes)
-- =============================================
CREATE TABLE matches (
    match_id    INT IDENTITY(1,1) PRIMARY KEY,
    user1_id    INT          NOT NULL,
    user2_id    INT          NOT NULL,
    cloth1_id   INT          NULL,
    cloth2_id   INT          NULL,
    status      VARCHAR(20)  NOT NULL
        CONSTRAINT DF_matches_status DEFAULT 'active'
        CONSTRAINT CHK_matches_status
        CHECK (status IN ('active', 'negotiating', 'declined', 'completed', 'archived')),
    created_at  DATETIME2(0) NOT NULL DEFAULT GETDATE(),
    updated_at  DATETIME2(0) NOT NULL DEFAULT GETDATE(),

    CONSTRAINT UQ_matches UNIQUE (user1_id, user2_id),
    CONSTRAINT CK_user1_user2 CHECK (user1_id < user2_id),

    CONSTRAINT FK_matches_user1
        FOREIGN KEY (user1_id) REFERENCES users(user_id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,

    CONSTRAINT FK_matches_user2
        FOREIGN KEY (user2_id) REFERENCES users(user_id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,

    CONSTRAINT FK_matches_cloth1
        FOREIGN KEY (cloth1_id) REFERENCES clothes(cloth_id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,

    CONSTRAINT FK_matches_cloth2
        FOREIGN KEY (cloth2_id) REFERENCES clothes(cloth_id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
);
GO
-- =============================================
-- 5. TRADES / AGREEMENTS
-- =============================================
CREATE TABLE trades (
    trade_id       INT IDENTITY(1,1) PRIMARY KEY,
    match_id       INT          NOT NULL,
    trade_status   VARCHAR(20)  NOT NULL
        CONSTRAINT DF_trades_status DEFAULT 'pending'
        CONSTRAINT CHK_trades_status
        CHECK (trade_status IN ('pending', 'agreed', 'shipping', 'delivered', 'completed', 'cancelled', 'disputed')),
    meeting_method VARCHAR(20)  NULL
        CONSTRAINT CHK_meeting_method
        CHECK (meeting_method IN ('shipping', 'meetup', 'drop-off', NULL)),
    details        VARCHAR(MAX) NULL,
    created_at     DATETIME2(0) NOT NULL DEFAULT GETDATE(),
    updated_at     DATETIME2(0) NOT NULL DEFAULT GETDATE(),
    completed_at   DATETIME2(0) NULL,
    CONSTRAINT FK_trades_match
        FOREIGN KEY (match_id) REFERENCES matches(match_id)
        ON DELETE CASCADE
        ON UPDATE NO ACTION
);
GO
-- =============================================
-- 6. MESSAGES (chat between matched users)
-- =============================================
CREATE TABLE messages (
    message_id     INT IDENTITY(1,1) PRIMARY KEY,
    match_id       INT          NOT NULL,
    sender_user_id INT          NOT NULL,
    content        VARCHAR(MAX) NOT NULL,
    is_read        BIT          NOT NULL DEFAULT 0,
    sent_at        DATETIME2(0) NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_messages_match
        FOREIGN KEY (match_id) REFERENCES matches(match_id)
        ON DELETE CASCADE,
    CONSTRAINT FK_messages_sender
        FOREIGN KEY (sender_user_id) REFERENCES users(user_id)
        ON DELETE NO ACTION
);
GO
-- =============================================
-- 7. NOTIFICATIONS
-- =============================================
CREATE TABLE notifications (
    notification_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id         INT          NOT NULL,
    type            VARCHAR(50)  NOT NULL
        CONSTRAINT CHK_notification_type
        CHECK (type IN ('new_match', 'new_message', 'trade_update', 'trade_completed', 'like_received')),
    content         VARCHAR(MAX) NOT NULL,
    is_read         BIT          NOT NULL DEFAULT 0,
    created_at      DATETIME2(0) NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_notifications_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE CASCADE
);
GO
-- =============================================
-- INDEXES (querry performance)
-- =============================================
CREATE NONCLUSTERED INDEX IX_clothes_user_id          ON clothes(user_id);
CREATE NONCLUSTERED INDEX IX_swipes_swiper_user_id    ON swipes(swiper_user_id);
CREATE NONCLUSTERED INDEX IX_swipes_swiped_cloth_id   ON swipes(swiped_cloth_id);
CREATE NONCLUSTERED INDEX IX_messages_match_id        ON messages(match_id);
CREATE NONCLUSTERED INDEX IX_matches_user1_user2      ON matches(user1_id, user2_id);
CREATE NONCLUSTERED INDEX IX_trades_match_id          ON trades(match_id);
GO
-- =============================================
-- TRIGGER: Create match when mutual like occurs
-- =============================================
-- CREATE OR ALTER TRIGGER trg_swipes_after_insert
-- ON swipes
-- AFTER INSERT
-- AS
-- BEGIN
--     SET NOCOUNT ON;
--
--     INSERT INTO matches (
--         user1_id, user2_id, 
--         cloth1_id, cloth2_id
--     )
--     SELECT DISTINCT
--         LEAST(i.swiper_user_id, c.owner_id),
--         GREATEST(i.swiper_user_id, c.owner_id),
--         i.swiped_cloth_id,                      -- the new like
--         rev.swiped_cloth_id                     -- the reverse like
--     FROM inserted i
--     CROSS APPLY (
--         SELECT user_id AS owner_id
--         FROM clothes 
--         WHERE cloth_id = i.swiped_cloth_id
--     ) c
--     INNER JOIN swipes rev
--         ON  rev.swiper_user_id = c.owner_id
--         AND rev.action         = 'like'
--         AND rev.swiped_cloth_id IN (
--             SELECT cloth_id FROM clothes WHERE user_id = i.swiper_user_id
--         )
--     WHERE i.action = 'like'
--       AND NOT EXISTS (
--           SELECT 1 FROM matches m
--           WHERE m.user1_id = LEAST(i.swiper_user_id, c.owner_id)
--             AND m.user2_id = GREATEST(i.swiper_user_id, c.owner_id)
--       );
-- END;
-- GO