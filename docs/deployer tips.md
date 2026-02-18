### Update submodules to sync with their main
```bash
(cd homepage_init_backend/ && git checkout --detach main)
(cd homepage_init_bot/ && git checkout --detach main)
git submodule foreach git pull origin main --ff-only
```

### Copy DB file from remote
- Run the command in remote
```bash
sudo cp /home/init-runner/homepage_init_be_msa/homepage_init_backend/db/YOUR_DB_FILENAME.db .
mv YOUR_DB_FILENAME.db $(date --iso-8601=date).db
```

- Then, run the command in local. Replace the address if server address is different.
```bash
scp scsc.tteokgook1.net:$(date --iso-8601=date).db .
```

### View nginx logs
- View access.log
```bash
sudo cat /var/log/nginx/access.log
```

- View error.log
```bash
sudo cat /var/log/nginx/error.log
```
