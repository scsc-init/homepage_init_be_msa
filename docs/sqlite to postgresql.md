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

pgadmin에 접속해서 다음을 실행합니다. 계정 비밀번호를 적절히 바꾸십시오.
![pgadmin](image.png)

```sql
-- 1. 수정 권한이 있는 계정 (App용)
CREATE USER app_user WITH PASSWORD 'app_password';
GRANT ALL ON DATABASE main_db TO app_user;
GRANT ALL ON ALL TABLES IN SCHEMA public TO app_user;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO app_user;

-- 2. 읽기 권한만 있는 계정 (ReadOnly용)
CREATE USER readonly_user WITH PASSWORD 'readonly_password';
GRANT CONNECT ON DATABASE main_db TO readonly_user;
GRANT USAGE ON SCHEMA public TO readonly_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO readonly_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO readonly_user;
```

이후 도커 컴포즈를 다시 시작합니다. 
