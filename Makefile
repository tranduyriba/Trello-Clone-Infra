.PHONY: up down logs dev health migrate seed restart ps build pull

# Start all containers in detached mode
up:
	docker compose up -d

# Stop and remove containers
down:
	docker compose down

# Tail logs (all services or specific: make logs s=backend)
logs:
	docker compose logs -f $(s)

# Build images + start all (dev workflow)
dev:
	docker compose up -d --build

# Health check
health:
	@curl -sf http://localhost/api/health | python -m json.tool || echo "Health check FAILED"

# Run Prisma migrations inside backend container
migrate:
	docker compose exec backend npx prisma migrate dev

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
