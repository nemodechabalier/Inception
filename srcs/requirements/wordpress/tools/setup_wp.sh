#!/bin/bash

set -e

# Attendre MariaDB
echo "Attente de MariaDB..."
max_attempts=30
attempt=1

while ! mysqladmin ping -h mariadb --silent; do
    if [ $attempt -ge $max_attempts ]; then
        echo "Erreur: MariaDB non accessible"
        exit 1
    fi
    echo "Tentative $attempt/$max_attempts..."
    sleep 2
    ((attempt++))
done
echo "MariaDB est prêt !"

cd /var/www/html

# Configuration WordPress
if [ ! -f wp-config.php ]; then
    echo "Création du fichier wp-config.php..."
    wp config create \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$MYSQL_PASSWORD" \
        --dbhost="mariadb:3306" \
        --allow-root \
        --force
fi

# Installation WordPress
if ! wp core is-installed --allow-root 2>/dev/null; then
    wp core install \
        --url="https://$DOMAIN_NAME" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --allow-root
    
    wp user create \
        "$WP_USER" \
        "$WP_USER_EMAIL" \
        --user_pass="$WP_USER_PASSWORD" \
        --role=editor \
        --allow-root
fi

# Permissions
chown -R www-data:www-data /var/www/html

echo "Démarrage de PHP-FPM..."
exec php-fpm7.4 -F