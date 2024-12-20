############################# HELP MESSAGE #############################
# Make sure the help command stays first, so that it's printed by default when `make` is called without arguments
.PHONY: help tests
help:
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

___DEPLOY___: ## 

build-contracts: ## builds all contracts
	forge build

deploy-all: deploy-symbiotic-core deploy-collateral deploy-vault deploy-operator-reward deploy-staker-reward deploy-liveness deploy-reward deploy-validation-service-manager ## Deploy all contracts

deploy-symbiotic-core: ## Deploy symbiotic core
	./utils/deploy/01_deploy-symbiotic-core.sh

deploy-collateral: ## Deploy collateral
	./utils/deploy/02_deploy-collateral.sh

deploy-vault: ## Deploy vault
	./utils/deploy/03_deploy-vault.sh
	
deploy-operator-reward: ## Deploy operator reward
	./utils/deploy/04_deploy-operator-reward.sh

deploy-staker-reward: ## Deploy staker reward
	./utils/deploy/05_deploy-staker-reward.sh

deploy-liveness: ## Deploy liveness
	./utils/deploy/07_deploy-liveness.sh

deploy-reward: ## Deploy reward
	./utils/deploy/08_deploy-reward.sh

deploy-validation-service-manager: ## Deploy validation service manager (AVS)
	./utils/deploy/06_deploy-validation-service-manager.sh



___START___: ## 

start: ## Start blockchain
	./utils/start.sh

-----------------------------: ##

___SETUP___: ## 

register: ## Register (Network & Operator)
	./utils/core/01_register.sh

___VAULT___: ## 

deposit: ## Despoit (Vault)
	./utils/vault/01_deposit.sh

delegate: ## Delegate (Vault)
	./utils/vault/02_delegate.sh

___VALIDATION_SERVICE_MANAGER___: ## 

register-vault: ## Register vault (Vault)
	./utils/validation_service_manager/01_register-vault.sh

register-operator: ## Register operator (Operator)
	./utils/validation_service_manager/02_register-operator.sh
