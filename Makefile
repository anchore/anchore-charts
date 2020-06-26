############################################################
# Makefile for Anchore Helm charts
############################################################


#### Docker Hub, git repos
############################################################
CHART_TEST_IMAGE := quay.io/helmpack/chart-testing
CHARTS_REPO := git://github.com/anchore/anchore-charts.git
TEST_HARNESS_REPO := https://github.com/anchore/test-infra.git


#### CircleCI environment variables
# DOCKER_USER and DOCKER_PASS are declared in CircleCI contexts
# LATEST_RELEASE_BRANCH is declared in CircleCI project env variables settings
############################################################
export CI ?= false
export DOCKER_USER ?=
export DOCKER_PASS ?=
export LATEST_RELEASE_BRANCH ?=
export PROD_IMAGE_REPO ?=
export RELEASE_BRANCHES ?=

# Use $CIRCLE_BRANCH if it's set, otherwise use current HEAD branch
GIT_BRANCH := $(shell echo $${CIRCLE_BRANCH:=$$(git rev-parse --abbrev-ref HEAD)})

# Use $CIRCLE_PROJECT_REPONAME if it's set, otherwise the git project top level dir name
GIT_REPO := $(shell echo $${CIRCLE_PROJECT_REPONAME:=$$(basename `git rev-parse --show-toplevel`)})
TEST_IMAGE_NAME := $(GIT_REPO):dev

# Use $CIRCLE_SHA if it's set, otherwise use SHA from HEAD
COMMIT_SHA := $(shell echo $${CIRCLE_SHA:=$$(git rev-parse HEAD)})

# Use $CIRCLE_TAG if it's set
GIT_TAG ?= $(shell echo $${CIRCLE_TAG:=null})

CLUSTER_NAME := chart-install
HELM_INSTALL_NAME := chart-test


# Make environment configuration
############################################################
VENV := venv
ACTIVATE_VENV := . $(VENV)/bin/activate
PYTHON := $(VENV)/bin/python3
.DEFAULT_GOAL := help # Running make without args will run the help target
CONFIG_CI := scripts/ci/kind-config.yaml
CONFIG_LOCAL := scripts/ci/kind-config-local.yaml
CLUSTER_CONFIG := $(CONFIG_CI)
K8S_VERSION := 1.15.7
ENGINE_CHART_DIR := stable/anchore-engine
ENTERPRISE_CHART_DIR := stable/anchore-enterprise

# Run make serially. Note that recursively invoked make will still
# run recipes in parallel (unless they also contain .NOTPARALLEL)
.NOTPARALLEL:

CI_CMD := anchore-ci/ci_harness


#### Make targets
############################################################

.PHONY: ci lint-chart-engine install-chart-engine smoke-tests
.PHONY: cluster-up cluster-down venv
.PHONY: clean clean-venv clean-ci-scripts clean-py-cache
.PHONY: printvars help

ci: lint-chart-engine install-chart-engine smoke-tests cluster-down ## Run full CI pipeline, locally

anchore-ci: ## Fetch test artifacts for local CI
	rm -rf /tmp/test-infra 2>/dev/null; git clone $(TEST_HARNESS_REPO) /tmp/test-infra
	mv ./anchore-ci ./anchore-ci-`date +%F-%H-%M-%S` 2>/dev/null; mv /tmp/test-infra/anchore-ci .

venv: $(VENV)/bin/activate ## Set up a virtual environment
$(VENV)/bin/activate:
	python3 -m venv $(VENV)

install-cluster-deps: anchore-ci venv ## Install kind, helm, and kubectl (unless installed)
	$(CI_CMD) install-cluster-deps "$(VENV)"

# If running CI locally, don't clog up the port mapping in control plane node definition
ifeq ($(CI),false)
CLUSTER_CONFIG := $(CONFIG_LOCAL)
endif

cluster-up: anchore-ci venv ## Set up and run kind cluster
	@$(MAKE) install-cluster-deps
	$(ACTIVATE_VENV) && $(CI_CMD) cluster-up "$(CLUSTER_NAME)" "$(CLUSTER_CONFIG)" "$(K8S_VERSION)"

cluster-down: anchore-ci venv ## Tear down/stop kind cluster
	@$(MAKE) install-cluster-deps
	$(ACTIVATE_VENV) && $(CI_CMD) cluster-down "$(CLUSTER_NAME)"

lint-chart-engine: venv anchore-ci ## Lint charts using 'helm lint'
	@$(MAKE) install-cluster-deps
	@$(ACTIVATE_VENV) && helm repo add stable https://kubernetes-charts.storage.googleapis.com
	@$(ACTIVATE_VENV) && $(CI_CMD) lint-chart "$(ENGINE_CHART_DIR)"

install-chart-engine: anchore-ci venv ## Install Anchore Engine with Helm chart
	@$(MAKE) install-cluster-deps
	@$(ACTIVATE_VENV) && helm repo add stable https://kubernetes-charts.storage.googleapis.com
	@$(MAKE) cluster-up
	@$(ACTIVATE_VENV) && $(CI_CMD) install-chart "$(ENGINE_CHART_DIR)" "$(HELM_INSTALL_NAME)"
	@$(ACTIVATE_VENV) && $(CI_CMD) port-forward "$(HELM_INSTALL_NAME)"

smoke-tests: anchore-ci venv ## Run Anchore Engine smoke tests
	@$(ACTIVATE_VENV) && $(CI_CMD) smoke-tests

run-smoke-tests: anchore-ci venv ## Set up and run Anchore Engine smoke tests
	@$(MAKE) install-chart-engine
	@$(MAKE) smoke-tests

clean-engine: ## Clean virtual env, CI scripts, and py cache for Anchore Engine charts
	@$(MAKE) clean-venv
	@$(MAKE) clean-ci-scripts
	@$(MAKE) clean-py-cache

clean-venv: anchore-ci ## Delete virtual environment
	@$(CI_CMD) clean-venv "$(VENV)" "$(TEST_IMAGE_NAME)"

clean-ci: anchore-ci ## Delete CI scripts
	@$(CI_CMD) clean-ci-scripts

clean-py-cache: anchore-ci ## Delete local python cache files
	@$(CI_CMD) clean-py-cache

printvars: ## Print make variables
	@$(foreach V,$(sort $(.VARIABLES)),$(if $(filter-out environment% default automatic,$(origin $V)),$(warning $V=$($V) ($(value $V)))))

help: ## Show this usage message
	@printf "\n%s\n\n" "usage: make <target>"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[0;36m%-30s\033[0m %s\n", $$1, $$2}'
