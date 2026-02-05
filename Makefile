# requirements: atlas, go1.25+ and a container runtime (e.g., docker, podman, [Apple] container, etc.)
# 

project := $(shell pwd)
gobin := $(project)/go/bin

CONTAINER_RUNTIME ?= container

.PHONY: db-up db-down db-clean

postgres_container := cycas-db

POSTGRES_USER ?= postgres
POSTGRES_PASSWORD ?= mysecretpassword
POSTGRES_HOST ?= localhost
POSTGRES_PORT ?= 5432

CYCAS_POSTGRES_DB ?= cycas
ATLAS_POSTGRES_DB ?= atlas

database_url_prefix := postgres://$(POSTGRES_USER):$(POSTGRES_PASSWORD)@$(POSTGRES_HOST):$(POSTGRES_PORT)

cycas_database_url := $(database_url_prefix)/$(CYCAS_POSTGRES_DB)?sslmode=disable
atlas_database_url := $(database_url_prefix)/$(ATLAS_POSTGRES_DB)?sslmode=disable

db-up:
	$(CONTAINER_RUNTIME) run \
        --name $(postgres_container) \
        --env POSTGRES_USER=$(POSTGRES_USER) \
        --env POSTGRES_PASSWORD=$(POSTGRES_PASSWORD) \
        --env POSTGRES_DB=$(CYCAS_POSTGRES_DB) \
        --publish $(POSTGRES_PORT):5432 \
        --detach postgres
	sleep 2
	$(CONTAINER_RUNTIME) exec $(postgres_container) psql -U $(POSTGRES_USER) -c "CREATE DATABASE $(ATLAS_POSTGRES_DB);"

db-down:
	$(CONTAINER_RUNTIME) stop $(postgres_container)

db-clean: db-down
	$(CONTAINER_RUNTIME) rm $(postgres_container)

.PHONY: gen

gen: _gen-api gen-sdk _gen-db
	$(MAKE) _tidy

.PHONY: gen-api _gen-api

gen-api: _gen-api
	$(MAKE) _tidy

_gen-api: gen/api/models.go gen/api/server.go gen/api/spec.go

oapi-codegen := $(gobin)/oapi-codegen

gen/api/models.go: api/openapi.yaml api/config/models.yaml | $(oapi-codegen)
	$(oapi-codegen) -config api/config/models.yaml api/openapi.yaml

gen/api/server.go: api/openapi.yaml api/config/server.yaml | $(oapi-codegen)
	$(oapi-codegen) -config api/config/server.yaml api/openapi.yaml

gen/api/spec.go: api/openapi.yaml api/config/spec.yaml | $(oapi-codegen)
	$(oapi-codegen) -config api/config/spec.yaml api/openapi.yaml

$(oapi-codegen):
	GOBIN=$(gobin) go install github.com/oapi-codegen/oapi-codegen/v2/cmd/oapi-codegen@latest

.PHONY: gen-sdk

gen-sdk: gen/sdk

gen/sdk: api/openapi.yaml
	$(CONTAINER_RUNTIME) run --rm --volume "$(project):/local" openapitools/openapi-generator-cli generate \
    	--generator-name typescript \
    	--input-spec /local/api/openapi.yaml \
    	--output /local/gen/sdk

.PHONY: gen-db _gen-db

gen-db: _gen-db
	$(MAKE) _tidy

_gen-db: gen/db gen/db/migrations/atlas.sum

sqlc := $(gobin)/sqlc

gen/db: db/sqlc.yaml $(wildcard db/schema/*.sql) $(wildcard db/queries/*.sql) $(sqlc)
	$(sqlc) generate -f db/sqlc.yaml

gen/db/migrations/atlas.sum: db/atlas.hcl $(wildcard db/schema/*.sql)
	CYCAS_DATABASE_URL=$(atlas_database_url) atlas --config file://db/atlas.hcl migrate diff --env local migration

$(sqlc):
	GOBIN=$(gobin) go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest

.PHONY: lint format

golangci-lint := $(gobin)/golangci-lint

lint: $(golangci-lint)
	$(golangci-lint) run

format: $(golangci-lint)
	$(golangci-lint) fmt

$(golangci-lint):
	GOBIN=$(gobin) go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v2.8.0

.PHONY: _tidy

_tidy:
	go mod tidy

.PHONY: tools

tools: $(oapi-codegen) $(sqlc) $(golangci-lint)
