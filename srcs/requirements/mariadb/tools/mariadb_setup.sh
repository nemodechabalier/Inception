#!/bin/bash

set -e

# Read secrets from files
if [ -f /run/secrets/db_root_password ]; then
    MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
else
    echo "Error: db_root_password secret not found"
    exit 1
fi

if [ -f /run/secrets/db_password ]; then
    MYSQL_PASSWORD=$(cat /run/secrets/db_password)
else
    echo "Error: db_password secret not found"
    exit 1
fi

# Debug: Print variables
echo "DEBUG: MYSQL_DATABASE=${MYSQL_DATABASE}"
echo "DEBUG: MYSQL_USER=${MYSQL_USER}"

# Create necessary directories
mkdir -p /var/run/mysqld /var/log/mysql
chown mysql:mysql /var/run/mysqld /var/log/mysql

# Check if database is already initialized
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB database..."
    
    # Initialize the database
    mysql_install_db --user=mysql --datadir=/var/lib/mysql --skip-test-db
    
    # Start MariaDB temporarily for setup
    mysqld --user=mysql --skip-networking --socket=/var/run/mysqld/mysqld.sock &
    MYSQL_PID=$!
    
    # Wait for MariaDB to start
    echo "Waiting for MariaDB to start..."
    while ! mysqladmin ping --socket=/var/run/mysqld/mysqld.sock --silent; do
        sleep 1
    done
    
    # Run initialization SQL
    mysql --socket=/var/run/mysqld/mysqld.sock << EOSQL
-- Secure installation
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

-- Set root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

-- Create database
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};

-- Create user with permissions for all possible hostnames
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'wordpress.srcs_inception_network' IDENTIFIED BY '${MYSQL_PASSWORD}';
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'172.18.0.%' IDENTIFIED BY '${MYSQL_PASSWORD}';

-- Grant all privileges
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'localhost';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'wordpress.srcs_inception_network';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'172.18.0.%';

-- Flush privileges
FLUSH PRIVILEGES;
EOSQL

    # Stop temporary MariaDB
    kill $MYSQL_PID
    wait $MYSQL_PID
    
    echo "MariaDB initialization completed."
else
    echo "MariaDB database already exists."
fi

# Start MariaDB normally
echo "Starting MariaDB server..."
exec mysqld --user=mysql --console
