# Inventory — fixture.example (SYNTHETIC — not a real server)

Test data for reconcile-backups.sh. All names are invented.

## Web roots & apps on disk

### /var/www
  - /var/www/shop.example.com → package.json
  - /var/www/blog.example.com → wp-config.php
  - /var/www/api.example.com → package.json
  - /var/www/staging.example.com → package.json
  - /var/www/html → (default)

## Databases

### PostgreSQL
  - shop_db
  - blog_db

## Scheduled jobs (cron / timers)

### This user's crontab
```
0 2 * * * /root/backup_shop.sh >> /var/log/shop.log 2>&1
30 2 * * * /root/backup_blog.sh >> /var/log/blog.log 2>&1
0 4 * * * /root/backup_vps_system_state.sh >> /var/log/state.log 2>&1
```
