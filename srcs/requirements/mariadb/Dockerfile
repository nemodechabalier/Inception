FROM debian:11

ENV DEBIAN_FRONTEND=noninteractive

# Installation de MariaDB
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y mariadb-server mariadb-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Configuration MariaDB
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY tools/mariadb_setup.sh /mariadb_setup.sh

RUN chmod +x /mariadb_setup.sh

# Création des répertoires nécessaires
RUN mkdir -p /var/run/mysqld && \
    chown mysql:mysql /var/run/mysqld

EXPOSE 3306

CMD ["/mariadb_setup.sh"]
