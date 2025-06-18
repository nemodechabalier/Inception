FROM debian:11

ENV DEBIAN_FRONTEND=noninteractive

# Install NGINX and OpenSSL
RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl

# Copy config and script
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY tools/nginx_start.sh /usr/local/bin/

# Create SSL certificates (self-signed for example)
RUN  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out /etc/nginx/ssl/nginx.crt \
    -subj "/C=FR/ST=Paris/L=Paris/O=42/OU=nde-chab/CN=localhost"

# Ensure the script is executable
RUN chmod +x /usr/local/bin/nginx_start.sh

# Expose only HTTPS
EXPOSE 443

# Launch nginx properly (no tail -f, etc.)
CMD ["/usr/local/bin/nginx_start.sh"]

