-- 1. Создание схемы
CREATE SCHEMA IF NOT EXISTS store;
SET search_path TO store;

-- 2. DDL: Создание таблиц
CREATE TABLE IF NOT EXISTS developers (
    dev_id SERIAL PRIMARY KEY,
    dev_name VARCHAR(100) NOT NULL,
    contact_email VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS genres (
    genre_id SERIAL PRIMARY KEY,
    genre_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS games (
    game_id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    dev_id INT,
    base_price NUMERIC(10,2) CHECK (base_price >= 0),
    discount_pct NUMERIC(5,2) DEFAULT 0,
    final_price NUMERIC(10,2) GENERATED ALWAYS AS (base_price - (base_price * discount_pct / 100)) STORED,
    CONSTRAINT fk_dev FOREIGN KEY (dev_id) REFERENCES developers(dev_id) ON DELETE CASCADE
);

-- Таблица-связка для реализации "многие ко многим"
CREATE TABLE IF NOT EXISTS game_genres (
    game_id INT,
    genre_id INT,
    PRIMARY KEY (game_id, genre_id),
    CONSTRAINT fk_gg_game FOREIGN KEY (game_id) REFERENCES games(game_id) ON DELETE CASCADE,
    CONSTRAINT fk_gg_genre FOREIGN KEY (genre_id) REFERENCES genres(genre_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    account_status VARCHAR(20) DEFAULT 'Active' CHECK (account_status IN ('Active', 'Suspended'))
);

CREATE TABLE IF NOT EXISTS purchases (
    purchase_id SERIAL PRIMARY KEY,
    user_id INT,
    game_id INT,
    purchase_date DATE CHECK (purchase_date > DATE '2026-01-01'),
    amount_paid NUMERIC(10,2),
    CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_game FOREIGN KEY (game_id) REFERENCES games(game_id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS reviews (
    review_id SERIAL PRIMARY KEY,
    user_id INT,
    game_id INT,
    rating INT CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT NOT NULL,
    CONSTRAINT fk_review_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_review_game FOREIGN KEY (game_id) REFERENCES games(game_id) ON DELETE CASCADE
);

-- 3. ALTER: Безопасное изменение структуры
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_login TIMESTAMP;
ALTER TABLE games ALTER COLUMN title TYPE VARCHAR(150);
ALTER TABLE purchases ALTER COLUMN amount_paid SET DEFAULT 0.00;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='store' AND table_name='developers' AND column_name='contact_email') THEN
        ALTER TABLE store.developers RENAME COLUMN contact_email TO support_email;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name='uq_username' AND table_schema='store') THEN
        ALTER TABLE store.users ADD CONSTRAINT uq_username UNIQUE (username);
    END IF;
END $$;

-- Очистка перед вставкой 
TRUNCATE developers, genres, games, game_genres, users, purchases, reviews RESTART IDENTITY CASCADE;

-- 4. DML: Вставка данных
INSERT INTO developers (dev_name, support_email) VALUES 
('NetherRealm Studios', 'support@netherrealm.com'),
('Mojang', 'hello@mojang.com'),
('Valve', 'contact@valvesoftware.com'),
('Epic Games', 'help@epicgames.com'),
('Re-Logic', 'support@re-logic.com');

INSERT INTO genres (genre_name) VALUES 
('Fighting'),
('Sandbox'),
('Puzzle'),
('Battle Royale'),
('RPG');

INSERT INTO games (title, dev_id, base_price, discount_pct) VALUES 
('Mortal Kombat 1', (SELECT dev_id FROM developers WHERE dev_name = 'NetherRealm Studios'), 69.99, 0),
('Minecraft', (SELECT dev_id FROM developers WHERE dev_name = 'Mojang'), 29.99, 0),
('Portal 2', (SELECT dev_id FROM developers WHERE dev_name = 'Valve'), 9.99, 50),
('Fortnite', (SELECT dev_id FROM developers WHERE dev_name = 'Epic Games'), 0.00, 0),
('Terraria', (SELECT dev_id FROM developers WHERE dev_name = 'Re-Logic'), 9.99, 10);

-- Заполнение связки Игры-Жанры
INSERT INTO game_genres (game_id, genre_id) VALUES 
((SELECT game_id FROM games WHERE title = 'Mortal Kombat 1'), (SELECT genre_id FROM genres WHERE genre_name = 'Fighting')),
((SELECT game_id FROM games WHERE title = 'Minecraft'), (SELECT genre_id FROM genres WHERE genre_name = 'Sandbox')),
((SELECT game_id FROM games WHERE title = 'Portal 2'), (SELECT genre_id FROM genres WHERE genre_name = 'Puzzle')),
((SELECT game_id FROM games WHERE title = 'Fortnite'), (SELECT genre_id FROM genres WHERE genre_name = 'Battle Royale')),
((SELECT game_id FROM games WHERE title = 'Terraria'), (SELECT genre_id FROM genres WHERE genre_name = 'RPG')),
((SELECT game_id FROM games WHERE title = 'Terraria'), (SELECT genre_id FROM genres WHERE genre_name = 'Sandbox'));

INSERT INTO users (username, email, account_status) VALUES 
('symbat', 'symbat@example.com', 'Active'),
('scorpion_fan', 'mk@example.com', 'Active'),
('steve_miner', 'steve@example.com', 'Active'),
('cheater99', 'banme@example.com', 'Suspended'),
('glados_lover', 'cake@example.com', 'Active'),
('pro_gamer', 'pro@example.com', 'Active'),
('casual_player', 'casual@example.com', 'Active'),
('rpg_master', 'rpg@example.com', 'Active'),
('speedrunner', 'speed@example.com', 'Active'),
('noob_saibot', 'shadow@example.com', 'Suspended');

INSERT INTO purchases (user_id, game_id, purchase_date, amount_paid)
SELECT 
    u.user_id,
    (SELECT game_id FROM games WHERE title = 'Minecraft'),
    '2026-05-15',
    29.99
FROM users u
WHERE u.account_status = 'Active';

INSERT INTO purchases (user_id, game_id, purchase_date, amount_paid) VALUES 
(
    (SELECT user_id FROM users WHERE username = 'symbat'),
    (SELECT game_id FROM games WHERE title = 'Mortal Kombat 1'),
    '2026-06-01',
    69.99
),
(
    (SELECT user_id FROM users WHERE username = 'scorpion_fan'),
    (SELECT game_id FROM games WHERE title = 'Mortal Kombat 1'),
    '2026-02-10',
    69.99
);

INSERT INTO reviews (user_id, game_id, rating, review_text) VALUES 
(
    (SELECT user_id FROM users WHERE username = 'symbat'),
    (SELECT game_id FROM games WHERE title = 'Mortal Kombat 1'),
    5, 'Отличная механика боев и проработанный сюжет.'
),
(
    (SELECT user_id FROM users WHERE username = 'steve_miner'),
    (SELECT game_id FROM games WHERE title = 'Minecraft'),
    5, 'Лучшая песочница всех времен.'
),
(
    (SELECT user_id FROM users WHERE username = 'glados_lover'),
    (SELECT game_id FROM games WHERE title = 'Portal 2'),
    5, 'Потрясающие головоломки и сюжет.'
),
(
    (SELECT user_id FROM users WHERE username = 'cheater99'),
    (SELECT game_id FROM games WHERE title = 'Fortnite'),
    1, 'Игра хорошая, но меня забанили ни за что.'
),
(
    (SELECT user_id FROM users WHERE username = 'rpg_master'),
    (SELECT game_id FROM games WHERE title = 'Terraria'),
    4, 'Очень затягивает, много контента.'
);

-- 5. Обновление данных (UPDATE)
UPDATE users 
SET account_status = 'Suspended' 
WHERE email LIKE '%banme%';

UPDATE games 
SET discount_pct = 20.00 
FROM developers 
WHERE games.dev_id = developers.dev_id 
  AND developers.dev_name = 'Valve';

-- 6. Удаление данных в транзакции
BEGIN;
DELETE FROM reviews 
WHERE rating = 1 
  AND user_id IN (SELECT user_id FROM users WHERE account_status = 'Suspended')
RETURNING review_id, review_text;
ROLLBACK;

-- 7. DCL: Управление ролями и правами
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'gamestore_readonly') THEN
        CREATE ROLE gamestore_readonly;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'gamestore_writer') THEN
        CREATE ROLE gamestore_writer;
    END IF;
END $$;

GRANT SELECT ON ALL TABLES IN SCHEMA store TO gamestore_readonly;
GRANT INSERT, UPDATE ON games TO gamestore_writer;
REVOKE UPDATE ON games FROM gamestore_writer;
