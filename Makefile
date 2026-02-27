.PHONY: help build push run stop status clean

IMAGE    := nvd-container
TAG      := latest
REGISTRY :=
PLATFORMS := linux/amd64,linux/arm64

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-14s %s\n", $$1, $$2}'

build: ## Build the NVD container for the local platform (requires NVD_API_KEY)
	@if [ -z "$(NVD_API_KEY)" ]; then \
		echo "Error: NVD_API_KEY is required."; \
		echo "Get a free key at: https://nvd.nist.gov/developers/request-an-api-key"; \
		exit 1; \
	fi
	docker build --secret id=NVD_API_KEY,env=NVD_API_KEY -t $(IMAGE):$(TAG) .

push: ## Build and push multi-arch image (requires NVD_API_KEY and REGISTRY, e.g. REGISTRY=ghcr.io/your-org)
	@if [ -z "$(NVD_API_KEY)" ]; then \
		echo "Error: NVD_API_KEY is required."; \
		exit 1; \
	fi
	@if [ -z "$(REGISTRY)" ]; then \
		echo "Error: REGISTRY is required (e.g. REGISTRY=ghcr.io/your-org)."; \
		exit 1; \
	fi
	docker buildx build \
		--platform $(PLATFORMS) \
		--secret id=NVD_API_KEY,env=NVD_API_KEY \
		-t $(REGISTRY)/$(IMAGE):$(TAG) \
		--push \
		.

run: ## Start the NVD data container
	docker run -d --name $(IMAGE) \
		-v nvd-owasp-data:/data/owasp \
		$(IMAGE):$(TAG)

stop: ## Stop the NVD data container
	docker stop $(IMAGE) && docker rm $(IMAGE)

status: ## Show container health and NVD version info
	@docker inspect --format='{{.State.Health.Status}}' $(IMAGE) 2>/dev/null || echo "Container not running"
	@echo ""
	@docker exec $(IMAGE) cat /data/NVD_VERSION.txt 2>/dev/null || true

clean: ## Stop container and remove named volumes
	-docker stop $(IMAGE) 2>/dev/null
	-docker rm $(IMAGE) 2>/dev/null
	-docker volume rm nvd-owasp-data 2>/dev/null
