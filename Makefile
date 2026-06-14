.PHONY: up down logs dev prod health migrate seed restart ps build pull

DC_DEV = docker compose -f docker-compose.yml -f docker-compose.dev.yml
DC_PROD = docker compose -f docker-compose.yml -f docker-compose.prod.yml

# Start all containers in detached mode (base only)
up:
	docker compose up -d

# Stop and remove containers
down:
	docker compose down

# Tail logs (all services or specific: make logs s=backend)
logs:
	docker compose logs -f $(s)

# Dev workflow: hot-reload bind mounts + development build
dev:
	$(DC_DEV) up -d --build

# Prod workflow: production build, no bind mounts
prod:
	$(DC_PROD) up -d --build

# Health check
health:
	@curl -sf http://localhost/api/health | python3 -m json.tool 2>/dev/null || curl -sf http://localhost/api/health || echo "Health check FAILED"

# Run Prisma db push (dev - no migration files needed)
db-push:
	docker compose exec backend npx prisma db push

# Run Prisma migrations inside backend container
migrate:
	docker compose exec backend npx prisma migrate deploy

# Run seed script inside backend container
seed:
	docker compose exec backend npx prisma db seed

# Restart a specific service: make restart s=backend
restart:
	docker compose restart $(s)

# Show running containers
ps:
	docker compose ps

# Rebuild specific service: make build s=backend
build:
	docker compose build $(s)

# Pull latest images
pull:
	docker compose pull

# Open psql inside postgres container
psql:
	docker compose exec postgres psql -U $${POSTGRES_USER:-trello} -d $${POSTGRES_DB:-trello_db}

# Open Redis CLI
redis-cli:
	docker compose exec redis redis-cli -a $${REDIS_PASSWORD:-redis_secret}

# Full reset: stop, remove volumes, rebuild
reset:
	docker compose down -v
	docker compose up -d --build
