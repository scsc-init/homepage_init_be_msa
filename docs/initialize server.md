### Change user(only on server)
Change user to `init-runner`
Be careful not to create files with accounts that are not `init-runner`

```bash
sudo -u  init-runner -i
```

### Clone the repository
```bash
git clone https://github.com/scsc-init/homepage_init_be_msa.git
cd homepage_init_be_msa
git submodule init
git submodule update --recursive
```

### Prerequisites
- Make .env files and data files
```bash
touch .env
touch ./homepage_init_backend/.env
touch ./homepage_init_bot/.env
touch ./homepage_init_bot/src/bot/discord/data/data.json
```

- Make directories defined in `./homepage_init_backend/.env`
```bash
mkdir ./homepage_init_backend/db
mkdir ./homepage_init_backend/download
mkdir ./homepage_init_backend/static
mkdir ./homepage_init_backend/static/image
mkdir ./homepage_init_backend/static/image/photo
mkdir ./homepage_init_backend/static/article
```

- Invite the bot to a discord server
- Make roles(defined at [homepage_init_backend/docs/common.md](homepage_init_backend/docs/common.md)) at the discord server.

### `.env` settings
Follow [README.md](/README.md)

### Docker Compose Building and Running

linux, docker, docker compose>=2.25.0 is required. 
In the root directory,

```bash
docker compose up --build -d
```

### Nginx Settings
To set config file [/nginx/init.conf](/nginx/init.conf) working on nginx, follow the manual.

- On server, modify `/etc/nginx/nginx.conf` file
    * Open file with root permission
    * Find the code below inside the http block(near the end of the block)
    ```nginx
    ...
    http {
        ...
        include /etc/nginx/conf.d/*.conf;
        include /etc/nginx/sites-enabled/*;
        ...
    }
    ...
    ```
    * Add `include /home/init-runner/homepage_init_be_msa/nginx/init.conf;` between the code above

- Restart nginx
```bash
sudo nginx -t
sudo systemctl restart nginx
```
