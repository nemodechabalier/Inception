#!/bin/bash

# Attendre que MariaDB soit prêt
echo "Attente de MariaDB..."
while ! mysqladmin ping -h mariadb --silent; do
    sleep 1
done
echo "MariaDB est prêt !"

# Aller dans le répertoire WordPress
cd /var/www/html

# Lire les mots de passe depuis les fichiers secrets
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)
MYSQL_PASSWORD=$(cat /run/secrets/db_password)

# Configuration de WordPress si wp-config.php n'existe pas
if [ ! -f wp-config.php ]; then
    echo "Configuration de WordPress..."
    
    # Créer wp-config.php
    wp config create \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$MYSQL_PASSWORD" \
        --dbhost="mariadb:3306" \
        --allow-root

    # Installation de WordPress
    wp core install \
        --url="$DOMAIN_NAME" \
        --title="Mon Site WordPress" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --allow-root

    # Créer un utilisateur standard
    wp user create \
        "$WP_USER" \
        "$WP_USER_EMAIL" \
        --user_pass="$WP_USER_PASSWORD" \
        --role=editor \
        --allow-root

    echo "WordPress configuré avec succès !"
fi

# Démarrer PHP-FPM
echo "Démarrage de PHP-FPM..."
exec php-fpm7.4 -F

