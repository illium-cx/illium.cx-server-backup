# FiveM Server Backup

For more information on configuring the backup script, check out [this write-up](https://fivem.illium.cx/fivem/automated-fivem-server-backup).

### Outline

- You must have `rw` permission in the `$SERVER_PATH`, since the script
   creates the `backups` directory in it. It doesn't matter where the script is run. 
- Once you start the script, the various paths are set based on `$SERVER_PATH`. 
- Checks/outputs the server's daemon status.
- Any missing folders are then created, i.e `backups`, `archive`, etc.
- The previous backup **log** file is moved to `backups/archive/logs`, and a new one is created
- The previous **backup** file is moved to `backups/archive`
- If the server daemon is running, it's stopped
- A new timestamped backup file is created in `backups`
- The server is restarted

### Usage

Clone the repo, preferably to the server folder, e.g `/opt/fivem-server`:
```
cd /opt/fivem-server
git clone https://github.com/illium-cx/illium.cx-server-backup.git backups/
```

and then edit the following in the script:

- `$SERVER_PATH`

   Path to the server files, e.g `/opt/fivem-server`

- `$SERVICE_NAME`

   The name of the server's background service

- `$ARCHIVE_LIMIT` - default: `100`

   If the number of backup files in `backup/archive`
   is > this value, the oldest backup is deleted

`nano backups/backup.sh`
```
# backup.sh

$SERVER_PATH="/path/to/your/server/files"
$SERVICE_NAME="fivem-server.service"
$ARCHIVE_LIMIT=100
```

At this point, you can manually run the script whenever you prefer. 

### Automate


To automate the process, create a cronjob to run the script every hour. Start by making the script executable
```
chmod +x backup.sh
```

And finally, add an entry to the crontab file. This will run `backup.sh` at the 0 minute of every hour:
`crontab -e`

```
# Add this to the bottom of the file
0 * * * * /opt/fivem-server/backup.sh
```

