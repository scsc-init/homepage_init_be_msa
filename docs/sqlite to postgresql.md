루트 경로에 `migration.load` 파일을 작성합니다. postgresql 관리자 계정의 아이디와 비밀번호, postgres 접속 주소 및 포트, db 이름을 정확히 작성하십시오.

```pgloader
LOAD DATABASE
     FROM sqlite:///db/YOUR_DB_FILENAME.db
     INTO postgresql://postgres:admin_password_here@localhost:5432/main_db

 WITH data only,
      on error resume next,
      reset sequences,
      workers = 8, 
      concurrency = 1

 SET work_mem to '16MB', maintenance_work_mem to '256MB'

 CAST type datetime to timestamp;
```

postgresql 컨테이너가 실행 중인 상태에서, 루트 경로에서 다음을 실행합니다.

```bash
docker run --rm \
  --network host \
  -v $(pwd)/homepage_init_backend/db:/db \
  -v $(pwd)/migration.load:/migration.load \
  dimitri/pgloader:latest pgloader /migration.load
```
