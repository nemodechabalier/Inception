all: setup build up

setup:
	@echo "Création des dossiers de données..."
	@mkdir -p /home/$(USER)/data/wordpress
	@mkdir -p /home/$(USER)/data/mariadb
	@sudo chown -R 999:999 /home/nde-chab/data/mariadb 
	@sudo chown -R 33:33 /home/nde-chab/data/wordpress
	@echo "Dossiers créés avec succès !"
	@cp -r /home/nde-chab/correction/ressources/secrets .
	@cp -r /home/nde-chab/correction/ressources/.env srcs/

build:
	docker compose -f srcs/docker-compose.yml build

up:
	docker compose -f srcs/docker-compose.yml up -d

down:
	docker compose -f srcs/docker-compose.yml down

clean: down
	docker system prune -af

fclean: clean
	docker volume rm $$(docker volume ls -q) 2>/dev/null || true
	sudo rm -rf /home/$(USER)/data

re: fclean all

logs:
	docker compose -f srcs/docker-compose.yml logs -f

status:
	docker compose -f srcs/docker-compose.yml ps

.PHONY: all setup build up down clean fclean re logs status
