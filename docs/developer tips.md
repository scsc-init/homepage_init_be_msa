### Update submodules(when developing)
```bash
(cd homepage_init_backend/ && git checkout --detach main)
(cd homepage_init_bot/ && git checkout --detach main)
git submodule foreach git pull origin main --ff-only
```
