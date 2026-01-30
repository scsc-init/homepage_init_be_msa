## 1. Server Preparation (One-time setup)

We need to create the `cd-runner` user and set up the directory structure so that the database and logs persist.

### Create the CD User

Log in to your Ubuntu server as root/sudo and run:

```bash
# Create user
sudo useradd -m -s /bin/bash cd-runner
sudo usermod -aG docker cd-runner

# Setup SSH directory
sudo sudo -u cd-runner mkdir -p /home/cd-runner/.ssh
sudo chmod 700 /home/cd-runner/.ssh

```

* **Action Required:** Generate an SSH key pair. Put the **Public Key** in `/home/cd-runner/.ssh/authorized_keys` and save the **Private Key** for GitHub Secrets.

### Create Project Directory & Secrets

To keep `main` and `develop` isolated, create a dedicated folder:

```bash
sudo mkdir -p /var/www/init_be_msa_dev
sudo chown cd-runner:cd-runner /var/www/init_be_msa_dev

```

```bash
sudo -u cd-runner -i
git clone -b develop https://github.com/scsc-init/homepage_init_be_msa.git .
git submodule update --init --recursive
git submodule foreach 'git fetch origin develop && git checkout develop && git pull origin develop'

```

Manually create the `.env`, `data.json`, etc. in this directory or specific submodule paths.
Use `SQLITE_FILENAME=db/dev_database.db`

---

## 2. GitHub Secrets Configuration

In your GitHub repository (**homepage_init_be_msa**), add the following Secrets:

* `SSH_PRIVATE_KEY`: The private key for `cd-runner`.
* `REMOTE_HOST`: Your server IP or domain.
* `REMOTE_USER`: `cd-runner`

---

## 3. The GitHub Actions Workflow

Create `.github/workflows/cd-dev.yml` in your root repository. This script handles the submodule updates and triggers the build.

```yaml
name: CD Develop Branch

on:
  push:
    branches: [ develop ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy via SSH
        uses: appleboy/ssh-action@v1.0.3
        with:
          host: ${{ secrets.REMOTE_HOST }}
          username: ${{ secrets.REMOTE_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            cd /var/www/init_be_msa_dev
            
            # 1. Pull the root repo
            
            git fetch origin develop
            git reset --hard origin/develop
            

            # 2. Update submodules to latest develop
            git submodule update --init --recursive
            git submodule foreach 'git fetch origin develop && git checkout develop && git pull origin develop'

            # 3. Build and Run
            # We use -p to create a unique project name (isolation)
            # We use a separate override file for dev ports
            docker compose -p init-dev -f docker-compose.yml -f docker-compose.dev.yml up -d --build

```

---

## 4. Handling Port & Environment Isolation

Since you don't want to change your base `docker-compose.yml`, we use a **Docker Compose Override** file. Create `docker-compose.dev.yml` in the root folder:

```yaml
services:
  backend:
    ports:
      - "127.0.0.1:9080:8080" # Different host port for dev
    environment:
      - SQLITE_FILENAME=db/dev_database.db
    # Bot port is NOT exposed to the host, keeping it private

  bot:
    ports:
      - "127.0.0.1:9081:8081" # Optional: Keep internal or use for testing
    environment:
      - BACKEND_URL=http://backend:8080 # Uses internal Docker network

```

---

## 5. Nginx Configuration for Dev

[/nginx/init.dev.conf](/nginx/init.dev.conf) nginx 설정 파일을 다음을 따라 설정합니다. 

- 서버에서 `/etc/nginx/nginx.conf`를 수정합니다. 
  - 파일을 루트 권한으로 엽니다. 
  - http 블록 하단 근처의 다음 부분을 찾습니다. 
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
  - `include /var/www/init_be_msa_dev/nginx/init.dev.conf;`를 두 줄 사이에 추가합니다.

- nginx를 재시작합니다.
  - 설정 파일이 유효한지 확인합니다. 
  ```bash
  sudo nginx -t
  ```
  - 유효하다면 nginx를 재시작합니다. 
  ```bash
  sudo systemctl restart nginx
  ```

---

### Final Considerations

* **Database Persistence:** Since the `backend` service in your Compose file uses `./db/:/app/db/`, and we are running the commands in `/var/www/init_be_msa_dev`, the SQLite file will stay in that folder on the host even if the container is deleted and rebuilt.
* **Bot Private Access:** Your Nginx config shows the bot is the "root" `/` handler. If the bot doesn't need to be accessed by users' browsers, you can simply remove the `location /` block in the Nginx dev config.
