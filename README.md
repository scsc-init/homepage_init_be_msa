### Change user
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

### Update submodules(when required)
```bash
git submodule foreach git pull origin main
```

### File Structure

```
/homepage_init_be_msa
ㄴ/homepage_init_backend (submodule)
ㄴ/homepage_init_bot (submodule)
ㄴ.env
ㄴdocker-compose.yml
```


### Prerequisites
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
docker compose up --build
```
