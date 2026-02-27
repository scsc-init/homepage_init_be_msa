# BE MSA 배포 관련 문서

> 최초작성일: 2025-07-14
>
> 최신개정일: 2026-02-27
>
> 최신개정자: 이한경
>
> 작성자: [강명석](mailto:tomskang@naver.com), 이한경

## 배포 방법

### 계정 변경
서버에서 `init-runner` 계정으로 변경합니다. `init-runner`가 아닌 계정으로 코드를 실행하거나 파일을 생성하지 않도록 주의합니다. 

```bash
sudo -u init-runner -i
```

### 레포지토리 복제
```bash
git clone --recurse-submodules https://github.com/scsc-init/homepage_init_be_msa.git
cd homepage_init_be_msa
```

기존 레포지토리에서는 pull합니다. 
```bash
git pull --ff-only origin main
git submodule sync --recursive
git submodule update --init --recursive
```

### 실행 전 준비사항
- `.env` 파일과 data 파일을 생성합니다. submodule 레포지토리를의 README를 참고하여 생성한 파일의 내용을 작성합니다. 
```bash
touch ./homepage_init_backend/.env
touch ./homepage_init_backend/.db_admin_password
touch ./homepage_init_backend/flyway.conf
touch ./homepage_init_bot/.env
mkdir -p ./homepage_init_bot/src/bot/discord/data
cp -n ./homepage_init_bot/src/bot/discord/data/data.example.json ./homepage_init_bot/src/bot/discord/data/data.json
```

- `.env` 파일 등의 권한을 제한합니다.
```bash
chmod 600 ./homepage_init_backend/.env ./homepage_init_backend/.db_admin_password ./homepage_init_backend/flyway.conf ./homepage_init_bot/.env
```

- 디스코드 봇을 디스코드 서버에 초대합니다. 
- 디스코드 서버에 [/homepage_init_backend/docs/common.md](/homepage_init_backend/docs/common.md)에서 정의하는 역할을 만듭니다.
- 관리자만 볼 수 있는 "지원금-신청" 텍스트 채널을 서버에 만듭니다. 

### `.env`와 data 설정
[README.md](/README.md) 및 서브모듈의 README를 따라 필요한 값을 설정합니다. 

### 도커 실행

linux, docker, docker compose>=2.25.0, nginx를 요구합니다. 

레포지토리 루트 경로에서 도커 이미지를 빌드하고 실행합니다. 
```bash
docker compose up --build -d
```

### Nginx 설정
[/nginx/init.conf](/nginx/init.conf) nginx 설정 파일을 다음을 따라 설정합니다. 

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
  - `include /home/init-runner/homepage_init_be_msa/nginx/init.conf;`를 두 줄 사이에 추가합니다.

- nginx를 재시작합니다.
  - 설정 파일이 유효한지 확인합니다. 
  ```bash
  sudo nginx -t
  ```
  - 유효하다면 nginx를 재시작합니다. 
  ```bash
  sudo systemctl restart nginx
  ```

## 배포 체크리스트

### Frontend (BFF)

- [ ] `.env` 값 조정
- [ ] Vercel에 배포하기 (+ URL 가져다붙이기)
- [ ] OAuth Redirect URL, URL 등록하기

### Backend DB

- [ ] `.env` 값 조정
- [ ] 회장 권한 사용자 등록

### Backend Bot

- [ ] `.env` 값 조정
- [ ] `data.json` 값 조정
- [ ] Testbed 서버 구축 및 세팅

