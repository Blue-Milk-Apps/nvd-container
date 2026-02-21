.PHONY: help build run stop status clean

IMAGE := nvd-container
TAG   := latest

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-14s %s\n", $$1, $$2}'

build: ## Build the NVD container (requires NVD_API_KEY)
	@if [ -z "$(NVD_API_KEY)" ]; then \
		echo "Error: NVD_API_KEY is required."; \
		echo "Get a free key at: https://nvd.nist.gov/developers/request-an-api-key"; \
		exit 1; \
	fi
	docker build --build-arg NVD_API_KEY=$(NVD_API_KEY) -t $(IMAGE):$(TAG) .

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
