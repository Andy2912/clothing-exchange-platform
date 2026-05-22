import bcrypt

hashed = '$2b$12$j6NP2Ey3o2tDYyReIOVrO.YM9KYkDjSmlRHJUKLy9StkW6W0O5oy6'
password = 'hashedpassword'

result = bcrypt.checkpw(password.encode(), hashed.encode())
print("Hash matches:", result)