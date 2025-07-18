#!/bin/bash
# filepath: /home/nde-chab/Documents/inception/srcs/requirements/mariadb/tools/init_db.sh

set -e

echo "Initialisation de MariaDB..."

# Créer les répertoires nécessaires
mkdir -p /var/run/mysqld
chown mysql:mysql /var/run/mysqld

# Initialiser la base de données si nécessaire
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Installation de la base de données..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql

    # Démarrer MariaDB temporairement (en arrière-plan)
    mysqld_safe --user=mysql --skip-networking --skip-grant-tables &
    pid="$!"

    # Attendre que MariaDB soit prêt
    echo "Attente du démarrage de MariaDB..."
    while ! mysqladmin ping --silent; do
        sleep 1
    done

    echo "MariaDB est prêt, configuration initiale..."

    # Configuration initiale (sans mot de passe car skip-grant-tables)
    mysql -e "FLUSH PRIVILEGES;"
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';"
    mysql -e "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;"
    mysql -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"
    mysql -e "GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';"
    mysql -e "FLUSH PRIVILEGES;"

    echo "Configuration terminée"

    # Arrêter MariaDB temporaire proprement
    kill "$pid"
    sleep 5
fi

# Démarrer MariaDB en mode normal
echo "Démarrage de MariaDB..."
exec mysqld_safe --user=mysql