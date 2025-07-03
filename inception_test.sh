#!/bin/bash

echo "========== 🧼 CLEANING DOCKER ENVIRONMENT =========="
docker stop $(docker ps -qa) 2>/dev/null
docker rm $(docker ps -qa) 2>/dev/null
docker rmi -f $(docker images -qa) 2>/dev/null
docker volume rm $(docker volume ls -q) 2>/dev/null
docker network rm $(docker network ls -q) 2>/dev/null
echo "✅ Docker cleaned"

echo ""
echo "========== 🛠️ BUILDING PROJECT =========="
make
if [ $? -ne 0 ]; then
    echo "❌ Make failed"
    exit 1
else
    echo "✅ Make succeeded"
fi

echo ""
echo "========== 🌐 CHECKING NETWORK =========="
docker network ls | grep srcs_inception_network
if [ $? -ne 0 ]; then
    echo "❌ Network not found"
else
    echo "✅ Network found"
fi

echo ""
echo "========== 📦 CHECKING CONTAINERS =========="
docker compose -f srcs/docker-compose.yml up -d

echo ""
echo "========== 🔐 TESTING NGINX HTTPS =========="
curl -kIs https://localhost | grep "200 OK"
if [ $? -ne 0 ]; then
    echo "❌ HTTPS not working"
else
    echo "✅ HTTPS working"
fi

echo ""
echo "========== 🔒 CHECKING TLS CERTIFICATE =========="
openssl s_client -connect localhost:443 </dev/null 2>/dev/null | grep "TLSv"
if [ $? -ne 0 ]; then
    echo "❌ TLS certificate not valid"
else
    echo "✅ TLS certificate valid"
fi

echo ""
echo "========== 📝 TESTING WORDPRESS =========="
docker exec wordpress wp core is-installed --allow-root
if [ $? -ne 0 ]; then
    echo "❌ WordPress not installed"
else
    echo "✅ WordPress installed"
fi

echo ""
echo "========== 🛢️ TESTING MARIADB =========="
docker exec mariadb mariadb -u root -p$MYSQL_ROOT_PASSWORD -e "SHOW DATABASES;" | grep $MYSQL_DATABASE
if [ $? -ne 0 ]; then
    echo "❌ MariaDB database not found"
else
    echo "✅ MariaDB database found"
fi

echo ""
echo "========== 💾 TESTING PERSISTENCE =========="
echo "Adding test article to WordPress..."
docker exec wordpress wp post create --post_title='PersistenceTest' --post_status=publish --allow-root

echo "Rebooting VM... (simulate by restarting docker compose)"
docker compose down
docker compose up -d
sleep 10

docker exec wordpress wp post list --allow-root | grep 'PersistenceTest'
if [ $? -ne 0 ]; then
    echo "❌ Persistence failed (post missing after restart)"
else
    echo "✅ Persistence working"
fi

echo ""
echo "========== ✅ ALL TESTS COMPLETED =========="

