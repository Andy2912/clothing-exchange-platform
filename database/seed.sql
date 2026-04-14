USE swipestyle;
GO

DISABLE TRIGGER trg_swipes_after_insert ON swipes;
-- ======================
-- Seed User
-- ======================

INSERT INTO users (username, email, password_hash, city, country)
VALUES (
    'testuser',
    'test@example.com',
    '$2b$12$j6NP2Ey3o2tDYyReIOVrO.YM9KYkDjSmlRHJUKLy9StkW6W0O5oy6',
    'Brussels',
    'Belgium'
);

GO

-- ======================
-- Seed Clothing Items
-- ======================

INSERT INTO clothes (
    user_id,
    name,
    description,
    image_url,
    category,
    brand,
    size,
    condition_rating,
    estimated_value
)
VALUES
(
    1,
    'Plaid Flannel Shirt',
    'Warm and comfortable flannel shirt.',
    '/uploads/flannel.jpg',
    'shirts',
    'Carhartt',
    'M',
    'good',
    35
),

(
    2,
    'Vintage Denim Jacket',
    'Classic denim jacket in good condition.',
    '/uploads/denim.jpg',
    'jackets',
    'Levis',
    'L',
    'good',
    45
),

(
    3,
    'Nike Hoodie',
    'Oversized Nike hoodie.',
    '/uploads/nikehoodie.jpg',
    'hoodies',
    'Nike',
    'XL',
    'like_new',
    50
),

(
    4,
    'Grey Sweatpants',
    'Comfortable sweatpants for everyday wear.',
    '/uploads/sweatpants.jpg',
    'pants',
    'Adidas',
    'M',
    'good',
    25
),

(
    5,
    'Basic White T-Shirt',
    'Simple cotton t-shirt.',
    '/uploads/tshirt.jpg',
    'shirts',
    'Uniqlo',
    'M',
    'good',
    15
);


-- test fot match with another user
USE swipestyle;
GO

-- ======================
-- Seed Match (mutual like)
-- ======================

-- Ensure there is another user to match with
INSERT INTO users (username, email, password_hash, city, country)
VALUES (
    'matchuser',
    'match@example.com',
    '$2b$12$j6NP2Ey3o2tDYyReIOVrO.YM9KYkDjSmlRHJUKLy9StkW6W0O5oy6',
    'Antwerp',
    'Belgium'
);

GO

INSERT INTO matches (user1_id, user2_id, cloth1_id, cloth2_id, status)
VALUES (
    1,      -- existing user
    2,      -- new match user
    1,      -- an item from user 1
    NULL,   -- no item from user 2 yet
    'active'
);

GO