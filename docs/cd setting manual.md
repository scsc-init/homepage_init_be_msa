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

Manually create the `.env` and `data.json` files in this directory (or specific submodule paths) since these contain sensitive or persistent data that shouldn't be overwritten by git pulls.

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

Add a new server block to your Nginx configuration on the Ubuntu server to handle the `dev` subdomain:

```nginx
upstream init_dev_backend {
    server 127.0.0.1:9080;
}

server {
    listen 80;
    server_name dev.scsc.tteokgook1.net;

    location /api {
        proxy_pass http://init_dev_backend;
        # ... keep other proxy headers same as main ...
    }

    location / {
        # If the bot has a web UI or webhook listener
        proxy_pass http://127.0.0.1:9081; 
        # ... keep other proxy headers same as main ...
    }
}

```

---

### Final Considerations

* **Database Persistence:** Since the `backend` service in your Compose file uses `./db/:/app/db/`, and we are running the commands in `/var/www/init_be_msa_dev`, the SQLite file will stay in that folder on the host even if the container is deleted and rebuilt.
* **Bot Private Access:** Your Nginx config shows the bot is the "root" `/` handler. If the bot doesn't need to be accessed by users' browsers, you can simply remove the `location /` block in the Nginx dev config.
