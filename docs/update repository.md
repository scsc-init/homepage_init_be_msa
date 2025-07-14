### Change user(only on server)
Change user to `init-runner`
Be careful not to create files with accounts that are not `init-runner`

```bash
sudo -u init-runner -i
```

Change directory after substituting user to `init-runner`

```bash
cd homepage_init_be_msa/
```

### Pull the repository
```bash
git pull origin main
git submodule update --recursive
```

### Running

linux, docker, docker compose>=2.25.0 is required. 
In the root directory,

```bash
docker compose up -d
```
