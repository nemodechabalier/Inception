#!/bin/bash

set -e  # Arrêter le script en cas d'erreur

# Attendre que MariaDB soit prêt
echo "Attente de MariaDB..."
max_attempts=30
attempt=1

while ! mysqladmin ping -h mariadb --silent; do
    if [ $attempt -ge $max_attempts ]; then
        echo "Erreur: MariaDB n'est pas accessible après $max_attempts tentatives"
        exit 1
    fi
    echo "Tentative $attempt/$max_attempts..."
    sleep 2
    ((attempt++))
done
echo "MariaDB est prêt !"

# Aller dans le répertoire WordPress
cd /var/www/html

# Lire les mots de passe depuis les fichiers secrets
echo "Lecture des secrets..."
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)
MYSQL_PASSWORD=$(cat /run/secrets/db_password)

echo "Variables d'environnement:"
echo "- DOMAIN_NAME: $DOMAIN_NAME"
echo "- MYSQL_DATABASE: $MYSQL_DATABASE"
echo "- MYSQL_USER: $MYSQL_USER"
echo "- WP_ADMIN_USER: $WP_ADMIN_USER"

# Configuration de WordPress si wp-config.php n'existe pas
if [ ! -f wp-config.php ]; then
    echo "Création du fichier wp-config.php..."
    
    wp config create \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$MYSQL_PASSWORD" \
        --dbhost="mariadb:3306" \
        --allow-root \
        --force
        
    echo "wp-config.php créé avec succès"
fi

# Vérifier la connexion à la base de données
echo "Test de connexion à la base de données..."
if ! wp db check --allow-root; then
    echo "Erreur: Impossible de se connecter à la base de données"
    exit 1
fi

# Vérifier si WordPress est déjà installé
if wp core is-installed --allow-root 2>/dev/null; then
    echo "WordPress est déjà installé."
else
    echo "Installation de WordPress..."
    
    # Installation de WordPress
    wp core install \
        --url="https://$DOMAIN_NAME" \
        --title="Mon Site WordPress" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --allow-root
    
    echo "Création de l'utilisateur standard..."
    # Créer un utilisateur standard
    wp user create \
        "$WP_USER" \
        "$WP_USER_EMAIL" \
        --user_pass="$WP_USER_PASSWORD" \
        --role=editor \
        --allow-root
    
    echo "WordPress installé avec succès !"
fi

# Vérifier l'installation
echo "Vérification de l'installation..."
wp core version --allow-root
wp user list --allow-root

# Changer les permissions pour www-data
echo "Configuration des permissions..."
chown -R www-data:www-data /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;

# Démarrer PHP-FPM
echo "Démarrage de PHP-FPM..."
exec php-fpm7.4 -F

