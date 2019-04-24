OS?=ubuntu

docker-compose:
	@docker-compose version

docker-build:
	docker-compose -f docker-compose.${OS}.yml build

docker-start: docker-compose
	docker-compose -f docker-compose.${OS}.yml up -d

docker-start-masterless: docker-compose
	docker-compose -f docker-compose.${OS}.yml up -d masterless

docker-clean: docker-compose
	docker-compose -f docker-compose.${OS}.yml down
	docker-compose -f docker-compose.${OS}.yml rm

docker-setup: docker-start ## setup salt with docker containers for testing
	docker exec saltstack_masterless_1 make setup

masterless-shell:  ## enter salt masterless container
	docker exec -it saltstack_masterless_1 /bin/bash

master-shell:  ## enter salt master container
	docker exec -it saltstack_master_1 /bin/bash

minion-shell:  ## enter salt minion container
	docker exec -it saltstack_minion1_1 /bin/bash

setup: ## setup python dependencies
	@pipenv --python $$(which python3) install --dev --system --deploy

test-style: setup ## test all style check
	@pipenv --python $$(which python3) run flake8 .

test: test-style

help: ## display this help screen
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
