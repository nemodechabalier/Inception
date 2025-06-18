FROM debian:11

ENV DEBIAN_FRONTEND=noninteractive

# Installation des paquets PHP et dépendances
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
    php7.4-fpm \
    php7.4-mysql \
    php7.4-curl \
    php7.4-gd \
    php7.4-intl \
    php7.4-mbstring \
    php7.4-soap \
    php7.4-xml \
    php7.4-xmlrpc \
    php7.4-zip \
    php7.4-cli \
    wget \
    curl \
    mariadb-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Créer le répertoire de destination AVANT d'y déplacer WordPress
RUN mkdir -p /var/www/html

# Téléchargement et installation de WordPress
WORKDIR /tmp
RUN wget https://wordpress.org/latest.tar.gz && \
    tar -xzf latest.tar.gz && \
    mv wordpress/* /var/www/html/ && \
    rmdir wordpress && \
    rm latest.tar.gz && \
    chown -R www-data:www-data /var/www/html

# Installation de WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/wp-cli/master/utils/wp-completion.bash && \
    curl -o /usr/local/bin/wp https://github.com/wp-cli/wp-cli/releases/download/v2.8.1/wp-cli-2.8.1.phar && \
    chmod +x /usr/local/bin/wp

# Configuration PHP-FPM
COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf
COPY tools/wordpress_setup.sh /wordpress_setup.sh

RUN chmod +x /wordpress_setup.sh

# Création des répertoires nécessaires
RUN mkdir -p /run/php

EXPOSE 9000

CMD ["/wordpress_setup.sh"]
