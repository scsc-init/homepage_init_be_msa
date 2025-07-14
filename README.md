### Documentation Index
- [initialize server.md](/docs/initialize%20server.md): manual for cloning the repository and initializing a server
- [update repository.md](/docs/update%20repository.md): manual for updating(pulling main branch) the repository
- [developer tips.md](/docs/developer%20tips.md): tips for developers
- [deployer tips.md](/docs/deployer%20tips.md): tips for deployers

### Change user(only on server)
Change user to `init-runner`
Be careful not to create files with accounts that are not `init-runner`

```bash
sudo -u init-runner -i
```

Change directory(if exist) after substituting user to `init-runner`

```bash
cd homepage_init_be_msa/
```

### File Structure

```
/homepage_init_be_msa
ㄴ/homepage_init_backend (submodule)
ㄴ/homepage_init_bot (submodule)
ㄴ/docs/
ㄴ/nginx/init.conf: nginx config file. included in /etc/nginx/nginx.conf on server.
ㄴ.env
ㄴdocker-compose.yml
```

### `.env` contents

#### `./.env`
Required when executing `docker-compose.yml` at root. The file location is relative to `./homepage_init_backend/`, i.e. it must be the same variable declared as below in `./homepage_init_backend/.env`.

```
SQLITE_FILENAME="db/YOUR_DB_FILENAME.db"
```

#### `./homepage_init_backend/.env`
check README of homepage_init_backend

#### `./homepage_init_bot/.env`
check README of homepage_init_bot

### Running

linux, docker, docker compose>=2.25.0 is required. 
In the root directory,

```bash
docker compose up -d
```
