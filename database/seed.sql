USE swipestyle;
GO

-- ======================
-- Seed Users
-- ======================
-- Password for all users: hashedpassword
INSERT INTO users (username, email, password_hash, city, country)
VALUES
    ('testuser1', 'testuser1@example.com', '$2b$12$j6NP2Ey3o2tDYyReIOVrO.YM9KYkDjSmlRHJUKLy9StkW6W0O5oy6', 'Brussels', 'Belgium'),
    ('testuser2', 'testuser2@example.com', '$2b$12$j6NP2Ey3o2tDYyReIOVrO.YM9KYkDjSmlRHJUKLy9StkW6W0O5oy6', 'Antwerp', 'Belgium'),
    ('testuser3', 'testuser3@example.com', '$2b$12$j6NP2Ey3o2tDYyReIOVrO.YM9KYkDjSmlRHJUKLy9StkW6W0O5oy6', 'Ghent', 'Belgium'),
    ('testuser4', 'testuser4@example.com', '$2b$12$j6NP2Ey3o2tDYyReIOVrO.YM9KYkDjSmlRHJUKLy9StkW6W0O5oy6', 'Leuven', 'Belgium');
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
    (1, 'Plaid Flannel Shirt', 'Warm and comfortable flannel shirt.', 'https://res.cloudinary.com/dhzlcplsa/image/upload/v1779349985/flannel_jzvwac.jpg', 'shirts', 'Carhartt', 'M', 'good', 35),
    (2, 'Vintage Denim Jacket', 'Classic denim jacket in good condition.', 'https://res.cloudinary.com/dhzlcplsa/image/upload/v1779349986/denim_q39mo2.jpg', 'jackets', 'Levis', 'L', 'good', 45),
    (3, 'Nike Hoodie', 'Oversized Nike hoodie.', 'https://res.cloudinary.com/dhzlcplsa/image/upload/v1779349984/nikehoodie_xf5ydo.jpg', 'hoodies', 'Nike', 'XL', 'like_new', 50),
    (4, 'Grey Sweatpants', 'Comfortable sweatpants for everyday wear.', 'https://res.cloudinary.com/dhzlcplsa/image/upload/v1779349985/sweatpants_dddgsr.jpg', 'pants', 'Adidas', 'M', 'good', 25);
GO

-- ======================
-- Seed Matches
-- ======================
INSERT INTO matches (user1_id, user2_id, cloth1_id, cloth2_id, status)
VALUES (1, 2, 1, 2, 'active');
GO
