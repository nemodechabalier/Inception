COMPOSE_FILE = ./srcs/docker-compose.yml
DATA_DIR = $(HOME)/data

all: build

build:
	@mkdir -p $(DATA_DIR)/wordpress
	@mkdir -p $(DATA_DIR)/mariadb
	@docker compose -f $(COMPOSE_FILE) up -d --build

down:
	@docker compose -f $(COMPOSE_FILE) down

clean:
	@docker compose -f $(COMPOSE_FILE) down -v
	@docker system prune -af

fclean: clean
	@sudo rm -rf $(DATA_DIR)

re: fclean all

.PHONY: all build down clean fclean re