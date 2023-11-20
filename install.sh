#!/bin/bash

public_ip=$(curl -s ifconfig.me)

# Update the package repository
sudo apt-get update

# Install expect for automation
sudo apt install expect -y

# Set timeout for expect
set timeout -1

# Install Node.js using nsolid_setup_deb.sh
curl -SLO https://deb.nodesource.com/nsolid_setup_deb.sh
chmod 500 nsolid_setup_deb.sh
./nsolid_setup_deb.sh 20
apt-get install nodejs -y

# Install PostgreSQL
sudo sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get -y install postgresql

# Install Nginx
sudo apt install nginx -y
sudo ufw allow 'Nginx HTTP'

# Configure Nginx
sudo tee "/etc/nginx/sites-available/${public_ip}" <<EOF
server {
    listen 80;
    listen [::]:80;

    server_name ${public_ip} www.${public_ip};

    location / {
        proxy_pass http://localhost:1337;
        include proxy_params;
    }
}
EOF

sudo ln -s "/etc/nginx/sites-available/${public_ip}" /etc/nginx/sites-enabled/
sudo systemctl restart nginx

# Create PostgreSQL database
sudo -i -u postgres createdb strapi-db

# Configure PostgreSQL
expect <<'END_EXPECT'
spawn sudo -i -u postgres createuser --interactive

expect "Enter name of role to add:"
send "abhi\r"

expect "Shall the new role be a superuser? (y/n)"
send "y\r"

expect eof
END_EXPECT

# Set PostgreSQL user password
sudo -u postgres psql <<EOF
ALTER USER abhi PASSWORD 'root';
\q
EOF

# create a Strapi app project
expect <<'END_EXPECT'
spawn npx create-strapi-app@latest abhi-project

expect "Ok to proceed?" 
send "\r"

expect "Choose your installation type" 
send "\033\[B" ; send "\r"

expect "Choose your preferred language" 
send "\r"

expect "Choose your default database client" 
send "\033\[B" ; send "\r"

expect "Database name:" 
send "strapi-db\r"

expect "Host:" 
send "\r"

expect "Port:" 
send "\r"

expect "Username:" 
send "abhi\r"

expect "Password:" 
send "root\r"

expect "Enable SSL connection:" 
send "N\r"

expect eof
END_EXPECT

# build and run the strapi server
cd /home/adminuser/abhi-project
npm install
NODE_ENV=production npm run build
nohup node /home/ubuntu/chinmay-project/node_modules/.bin/strapi start > /dev/null 2>&1 &
