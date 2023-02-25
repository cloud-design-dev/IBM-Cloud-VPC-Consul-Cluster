.ONESHELL:
.SHELL := /bin/zsh
.PHONY: apply destroy plan prep
VARS="terraform.tfvars"
CURRENT_FOLDER=$(shell basename "$$(pwd)")
WORKSPACE="$(ENV)"
BOLD=$(shell tput bold)
RED=$(shell tput setaf 1)
GREEN=$(shell tput setaf 2)
YELLOW=$(shell tput setaf 3)
RESET=$(shell tput sgr0)

# Check for necessary tools
ifeq (, $(shell which jq))
	$(error "No jq in $(PATH), please install jq")
endif
ifeq (, $(shell which terraform))
	$(error "No terraform in $(PATH), get it from https://www.terraform.io/downloads.html")
endif

default:
	@echo "Interact with Terraform environments."
	@echo "The following commands are available:"
	@echo " - init               : Runs a terraform init against an environment"
	@echo " - plan               : Runs a terraform plan against an environment"
	@echo " - apply              : Runs a terraform apply against an environment"
	@echo " - destroy            : Run a delete option against an environment"

init: 
	$(call check_defined, ENV, Please set the ENV to plan for. Values should be dev, test, uat or prod)
	@terraform fmt --recursive

	@echo 'Switching to the [$(value ENV)] environment ...'
	@if [[ $(value ENV) == "dev" ]]; then
		unset IBMCLOUD_APIKEY;
		export IBMCLOUD_API_KEY=$(jq -r .apikey ~/Sync/SynologyDrive/Systems/api-keys/dev-account-ibmcloud-apikey.json)
	endif
	@echo "Initializing directory."
	@terraform init -upgrade=true

	@terraform validate

plan: 
	$(call check_defined, ENV, Please set the ENV to plan for. Values should be cde or dev)

	@echo 'Switching to the [$(value ENV)] environment ...'
	@terraform workspace select $(value ENV) 

	@terraform plan  \
  	  -var-file="env/$(value ENV).tfvars" \
		-out $(value ENV).plan




apply: 
	$(call check_defined, ENV, Please set the ENV to apply. Values should be dev, test, uat or prod)

	@echo 'Switching to the [$(value ENV)] environment ...'
	@terraform workspace select $(value ENV)

	@echo "Will be applying the following to [$(value ENV)]environment:"
	@terraform show -no-color $(value ENV).plan

	@terraform apply $(value ENV).plan
	@rm $(value ENV).plan



taint: 
	$(call check_defined, ENV, Please set the ENV to plan for. Values should be dev, test, uat or prod)
	@terraform fmt

	@echo "Pulling the required modules..."
	@terraform get

	@echo 'Switching to the [$(value ENV)] environment ...'
	@terraform workspace select $(value ENV) 

	@terraform taint  \
		 "$(value restype).$(value resname)" 

	@ENV=$(value ENV) restype=$(value restype) resname=$(value resname) make targetplan

	@ENV=$(value ENV) make apply
	

destroy: 
	@echo "Switching to the [$(value ENV)] environment ..."
	@terraform workspace select $(value ENV)

	@echo "## 💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥 ##"
	@echo "Are you really sure you want to completely destroy [$(value ENV)]  environment ?"
	@echo "## 💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥 ##"
	@read -p "Press enter to continue"
	@terraform destroy \
		-var-file="env/$(value ENV).tfvars"

destroytarget: 
	@echo "Switching to the [$(value ENV)] environment ..."
	@terraform workspace select $(value ENV)

	@echo "## 💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥 ##"
	@echo "Are you really sure you want to completely destroy [$(value ENV)]  Resource:  [$(value restype).$(value resname)]  ?"
	@echo "## 💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥💥 ##"
	@read -p "Press enter to continue"
	@terraform destroy \
  	  -var-file="env/$(value ENV).tfvars" \
		-target "$(value restype).$(value resname)" \

# Check that given variables are set and all have non-empty values,
# die with an error otherwise.
#
# Params:
#   1. Variable name(s) to test.
#   2. (optional) Error message to print.
check_defined = \
    $(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
    $(if $(value $1),, \
      $(error Undefined $1$(if $2, ($2))))
