#!/bin/bash

# Stop script on error
set -e

echo "[MariaDB] Démarrage de la configuration..."

# Lire les mots de passe depuis les secrets
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
DB_PASSWORD=$(cat /run/secrets/db_password)

# Lancer MariaDB en arrière-plan temporairement
echo "[MariaDB] Démarrage de mysqld pour configuration initiale..."
mysqld_safe --datadir="/var/lib/mysql" &
sleep 5

# Attendre que MariaDB soit prêt à recevoir des connexions
until mysqladmin ping --silent --connect-timeout=2; do
    echo "[MariaDB] En attente de MariaDB..."
    sleep 2
done

echo "[MariaDB] MariaDB est prêt."

# Appliquer configuration
echo "[MariaDB] Création de la base de données et de l'utilisateur..."
mysql -u root <<-EOSQL
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';

    CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};

    CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
    GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
    FLUSH PRIVILEGES;
EOSQL

echo "[MariaDB] Configuration terminée."

# Attendre que le processus mysqld_safe termine
echo "[MariaDB] Arrêt temporaire de MariaDB pour redémarrage propre..."
mysqladmin -u root -p${DB_ROOT_PASSWORD} shutdown

# Redémarrage de MariaDB en mode normal
echo "[MariaDB] Démarrage final de MariaDB..."
exec mysqld_safe --datadir="/var/lib/mysql"

