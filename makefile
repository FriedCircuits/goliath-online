ver = v$(shell sed -n 's/^VERSION="\(.*\)"/\1/p' VERSION)
COMPOSE = docker compose --env-file build.cfg

.PHONY: help build up down logs shell upgrade release on-host

help:
	@echo "make build     Build the image"
	@echo "make up        Start or update the container"
	@echo "make down      Stop and remove the container, the home volume is kept"
	@echo "make logs      Follow the container output"
	@echo "make shell     Open a shell in the container"
	@echo "make upgrade   Pull, rebuild and recreate the container"
	@echo "make release   Tag and publish the version in VERSION"

build:
	./docker-build.sh

up: on-host
	$(COMPOSE) up -d

down: on-host
	$(COMPOSE) down

logs:
	$(COMPOSE) logs -f

shell:
	$(COMPOSE) exec goliath zsh

upgrade: on-host
	git pull --ff-only
	./docker-build.sh
	$(COMPOSE) up -d

release:
	git pull --ff-only
	git tag -s $(ver) -m $(ver)
	git push origin $(ver)
	gh release create $(ver) --verify-tag --generate-notes

# Recreating the container from inside it would stop the command halfway.
on-host:
	@if [ -f /.dockerenv ]; then echo "Run this on the Docker host, not in the container."; exit 1; fi
