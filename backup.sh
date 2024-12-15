#    __     __         __         __     __  __     __    __
#   /\ \   /\ \       /\ \       /\ \   /\ \/\ \   /\ "-./  \
#   \ \ \  \ \ \____  \ \ \____  \ \ \  \ \ \_\ \  \ \ \-./\ \
#    \ \_\  \ \_____\  \ \_____\  \ \_\  \ \_____\  \ \_\ \ \_\
#     \/_/   \/_____/   \/_____/   \/_/   \/_____/   \/_/  \/_/
#                                     powered by FiveM & QBCore
#
#                                       illium.cx-server-backup

TIMESTAMP="$(date +'%Y-%m-%d_%H-%M-%S')"

# SET BEFORE RUNNING
SERVER_PATH="/opt/fivem-server"
SERVICE_NAME="fivem-server.service"

TXDATA_DIR="$SERVER_PATH/txData"
BACKUP_DIR="$SERVER_PATH/backups"
BACKUP_ARCHIVE="$SERVER_PATH/backups/archive"
ARCHIVE_LIMIT=100

LOG_FILE="$SERVER_PATH/backups/$(date +'%Y-%m-%d-%H-%M-%S')-backup.log"
LOG_ARCHIVE="$SERVER_PATH/backups/archive/logs"

SERVICE_STATUS="$(systemctl is-active --quiet "$SERVICE_NAME" && { echo "ACTIVE"; } || { echo "NOT ACTIVE"; })"

exit_script() {
    local message="$1"
    echo "// $TIMESTAMP - $message - EXITING"
    echo "// $TIMESTAMP - $message - EXITING" >> "$LOG_FILE"
    exit "${2:-1}"
}

log() {
    local message="$1"
    echo "// $TIMESTAMP - $message"
    echo "// $TIMESTAMP - $message" >> "$LOG_FILE"
}

# // ----------------------------------
# // DIR CHECK
[[ ! -d "$TXDATA_DIR" ]] && echo "ERROR: No server files found - EXITING" && exit 1

for dir in "$BACKUP_DIR" "$BACKUP_ARCHIVE" "$LOG_ARCHIVE"; do
    [[ ! -d "$dir" ]] && { echo "$TIMESTAMP - WARNING: $dir does not exist, creating: $dir"; mkdir "$dir" || exit_script "ERROR: Failed to create $dir"; }
done

# // ----------------------------------
# // FILE CHECK
shopt -s nullglob
[[ -n "$(find "$BACKUP_DIR" -maxdepth 1 -name '*.log' -print -quit)" ]] && mv "$BACKUP_DIR"/*.log "$LOG_ARCHIVE"
[[ -n "$BACKUP_DIR"/*.log ]] && touch "$LOG_FILE" || exit_script "ERROR: Failed to create log file: $LOG_FILE"

log "FIVEM SERVER BACKUP"
log "----------------------------------"

# If there's already a backup in $BACKUP_DIR, move it to archive
backup=("$BACKUP_DIR"/*.tar.gz)
[[ ${#backup[@]} -gt 0 ]] && mv "${backup[@]}" "$BACKUP_ARCHIVE"

# If archive contains >$ARCHIVE_LIMIT, delete oldest backup
backup_archive=("$BACKUP_ARCHIVE"/*.tar.gz)
log "Archive backup count: ${#backup_archive[@]}"
if [[ ${#backup_archive[@]} -ge $ARCHIVE_LIMIT ]]; then
    backup_oldest=$(ls -t "$BACKUP_ARCHIVE"/*.tar.gz | tail -n 1)
    rm -f "$backup_oldest" && log "Removed oldest backup"
fi

log "$SERVICE_NAME is currently: $([[ "$SERVICE_STATUS" == "ACTIVE" ]] && echo -e "\033[0;32mACTIVE\033[0m" || echo -e "\033[0;31mNOT ACTIVE\033[0m")"

if [[ "$SERVICE_STATUS" == "ACTIVE" ]]; then 
    if [[ $1 == "-S" ]]; then
        log "Server shutdown enabled"
        log "Shutting down $SERVICE_NAME"
        sudo systemctl stop "$SERVICE_NAME" && log "Successfully stopped $SERVICE_NAME" || { exit_script "ERROR: Failed to stop $SERVICE_NAME"; } 
    fi
fi

shopt -u nullglob

cd $SERVER_PATH
log "SERVER ARCHIVE - START"
log "----------------------------------"
tar -cvzf "backups/$TIMESTAMP-backup.tar.gz" "txData" | while read line; do
	log "$line"
done
log "----------------------------------"
log "SERVER ARCHIVE - FINISH "
[[ -f "$BACKUP_DIR/$TIMESTAMP-backup.tar.gz" ]] && log "Backup created: $BACKUP_DIR/$TIMESTAMP-backup.tar.gz"
[[ $1 == "-S" ]] && sudo systemctl start $SERVICE_NAME && log "$SERVICE_NAME started successfully"

exit_script "FINISHED"
