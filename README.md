### Documentation Index
- [***deploy manual.md***](/docs/deploy%20manual.md): manual for initialization and deployment
- [update repository.md](/docs/update%20repository.md): manual for updating(pulling main branch) the repository
- [developer tips.md](/docs/developer%20tips.md): tips for developers
- [deployer tips.md](/docs/deployer%20tips.md): tips for deployers

### Change user(only on server)
Change user to `init-runner`
Be careful not to create files with accounts that are not `init-runner`

```bash
sudo -u init-runner -i
```

### File Structure

```
/homepage_init_be_msa
ㄴ/homepage_init_backend (submodule)
ㄴ/homepage_init_bot (submodule)
ㄴ/docs/
ㄴ/nginx/init.conf: nginx config file. include it in /etc/nginx/nginx.conf on server.
ㄴ.env
ㄴdocker-compose.yml
```
