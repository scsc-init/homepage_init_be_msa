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

#### Trouble shooting about pulling on server
If pull does not work well with this message, the reason may be problem about file ownership
```
error: insufficient permission for adding an object to repository database .git/objects
```

Run the command below to ensure that all files are owned by `init-runner`
```bash
ls -la .git/objects
```

If not, then run the command below to change the file owner
```bash
sudo chown init-runner:init-runner .git/objects/*
```

### Running

linux, docker, docker compose>=2.25.0 is required. 
In the root directory,

```bash
docker compose down
docker compose up -d
```
