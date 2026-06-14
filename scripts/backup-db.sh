#!/usr/bin/env bash
# PostgreSQL daily backup via docker exec (pg_dump runs inside container)
# Cron: 0 2 * * * /var/www/trello-clone-prod/infra/scripts/backup-db.sh >> /var/log/trello-backup.log 2>&1

set -euo pipefail

BACKUP_DIR="/var/backups/trello"
KEEP_DAYS=7
CONTAINER="${POSTGRES_CONTAINER:-trello_postgres}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILENAME="trello_${TIMESTAMP}.sql.gz"

# Load env from .env in infra root
ENV_FILE="$(dirname "$0")/../.env"
if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

DB_NAME="${POSTGRES_DB:-trello}"
DB_USER="${POSTGRES_USER:-postgres}"

mkdir -p "$BACKUP_DIR"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting backup: $FILENAME"

docker exec "$CONTAINER" \
  pg_dump -U "$DB_USER" -d "$DB_NAME" --format=plain --clean --if-exists \
  | gzip > "$BACKUP_DIR/$FILENAME"

SIZE=$(du -sh "$BACKUP_DIR/$FILENAME" | cut -f1)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Done: $FILENAME ($SIZE)"

# Remove backups older than KEEP_DAYS
find "$BACKUP_DIR" -name "trello_*.sql.gz" -mtime "+$KEEP_DAYS" -delete
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Cleaned up backups older than $KEEP_DAYS days"

# Optional: upload to R2/S3 if rclone is configured
# rclone copy "$BACKUP_DIR/$FILENAME" r2:trello-backups/
