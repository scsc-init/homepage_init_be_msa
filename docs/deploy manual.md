# BE MSA 배포 관련 문서

> 최초작성일: 2025-07-14
>
> 최신개정일: 2026-07-14  
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
touch ./homepage_init_bot/.env
mkdir -p ./homepage_init_bot/src/bot/discord/data
cp -n ./homepage_init_bot/src/bot/discord/data/data.example.json ./homepage_init_bot/src/bot/discord/data/data.json
```

- `.env` 파일 등의 권한을 제한합니다.
```bash
chmod 600 ./homepage_init_backend/.env ./homepage_init_backend/.db_admin_password ./homepage_init_backend/flyway.conf ./homepage_init_bot/.env
```

- `homepage_init_backend`의 env 링크를 만들어 docker compose가 해당 env를 사용할 수 있게 합니다. 
```bash
ln -s homepage_init_backend/.env .env
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

## HTTPS 인증서 발급 방법

현재 백엔드는 api.scsc.dev에 배포되어 있고, 문서 작성일 기준으로 작성했습니다. 

먼저 nginx/init.conf의 server 블록 안에 다음을 추가하고 nginx를 재시작합니다.

```
location ^~ /.well-known/acme-challenge/ {
        root /var/www/html;
        default_type "text/plain";
        try_files $uri =404;
    }
```

그 다음 테스트 파일을 만들어서 ACME 경로가 열리는지 확인합니다.

```bash
sudo mkdir -p /var/www/html/.well-known/acme-challenge
echo test | sudo tee /var/www/html/.well-known/acme-challenge/test-file

curl -i http://scsc.dev/.well-known/acme-challenge/test-file
```

200 OK와 test가 나오면 Certbot 발급을 진행합니다.

```bash
sudo certbot certonly --webroot \
  -w /var/www/html \
  -d scsc.dev
```

### 수동 DNS 인증으로 발급·갱신하기

HTTP(webroot) 인증이 실패하면 DNS의 TXT 레코드로 도메인 소유권을 확인할 수 있습니다. 이 방법은 앞의 ACME 경로 설정 없이 진행할 수 있습니다.

2026년 10월 12일에는 기존 수동 인증 설정에 `--manual-auth-hook`이 없어 `certbot renew`가 실패했고, HTTP 인증도 리다이렉트 문제로 완료되지 않아 아래 방식으로 갱신했습니다.

#### 1. 기존 인증서 확인

인증서를 사용하는 서버에서 다음을 실행해 `Certificate Name`, `Domains`, 만료일과 인증서 경로를 확인합니다.

```bash
sudo certbot certificates
```

갱신할 때는 기존 `Certificate Name`을 `--cert-name`에 사용하고, 기존 인증서의 `Domains`에 있는 도메인을 모두 `-d`로 지정합니다. 아래 명령어는 각 인증서가 해당 도메인 하나만 포함하는 경우의 예시입니다. 추가 서브도메인이 있다면 빠뜨리지 않도록 주의합니다.

#### 2. Certbot 수동 DNS 인증 실행

프론트엔드(`scsc.dev`):

```bash
sudo certbot certonly --manual --preferred-challenges dns \
  --cert-name scsc.dev \
  -d scsc.dev
```

백엔드(`api.scsc.dev`):

```bash
sudo certbot certonly --manual --preferred-challenges dns \
  --cert-name api.scsc.dev \
  -d api.scsc.dev
```

각 명령어는 해당 인증서를 사용하는 서버에서 실행합니다. 기존 인증서 이름이 예시와 다르면 확인한 이름으로 바꿉니다. 갱신 시 기존 인증서를 유지할지 갱신할지 묻는 경우에는 만료일을 확인하고 갱신 항목을 선택합니다.

Certbot이 TXT 레코드 이름과 값을 표시하면 **아직 Enter를 누르지 말고 터미널을 그대로 둡니다.** 이 과정에서는 webroot나 `/var/www/html`을 선택하지 않습니다.

#### 3. 가비아에 TXT 레코드 등록

2026년 10월 12일 작업 당시에는 가비아 DNS를 사용했습니다. [가비아 DNS 관리툴](https://dns.gabia.com/dns)에 로그인하여 `scsc.dev`의 DNS 설정을 열고, 레코드 수정 → 레코드 추가에서 Certbot이 안내한 TXT 레코드를 등록한 뒤 확인 및 저장합니다. 네임서버 제공업체가 변경되었다면 현재 DNS를 관리하는 곳에서 작업합니다.

`scsc.dev` DNS 영역에서 입력할 호스트는 다음과 같습니다.

| 인증 대상 | 타입 | 호스트 | 값/위치 |
| --- | --- | --- | --- |
| `scsc.dev` | TXT | `_acme-challenge` | 현재 Certbot 화면에 표시된 인증값 |
| `api.scsc.dev` | TXT | `_acme-challenge.api` | 현재 Certbot 화면에 표시된 인증값 |

가비아에서 도메인 접미사를 자동으로 붙이는 호스트 칸에는 위의 상대 이름을 입력합니다. 최종 레코드 이름이 Certbot이 안내한 `_acme-challenge.scsc.dev` 또는 `_acme-challenge.api.scsc.dev`와 일치해야 합니다. 인증값은 이전 작업의 값을 재사용하지 말고 현재 안내된 값을 그대로 입력합니다. 기존 서비스용 A, CNAME, MX 등 다른 레코드는 변경하지 않습니다.

#### 4. DNS 반영 확인 후 인증 완료

`dig`가 설치된 터미널에서 인증 중인 도메인의 TXT 레코드가 조회되는지 확인합니다.

```bash
dig +short TXT _acme-challenge.scsc.dev @1.1.1.1
dig +short TXT _acme-challenge.api.scsc.dev @1.1.1.1
```

현재 작업 중인 도메인의 조회 결과에 Certbot이 요구한 인증값이 나타나야 합니다. 값이 없거나 이전 값만 나오면 DNS 반영을 기다린 뒤 다시 조회합니다. 공용 DNS에서 조회되더라도 다른 DNS에는 아직 반영 중일 수 있으므로, Certbot에서 전파를 추가로 확인하라고 안내하면 그 안내도 따릅니다.

반영을 확인한 뒤 Certbot 터미널에서 Enter를 눌러 진행합니다. TXT 레코드를 추가로 요청하면 같은 절차를 반복합니다. 모든 인증이 성공하고 인증서 저장 경로가 표시될 때까지 진행합니다. 완료 후에는 이번 인증에 사용한 TXT 레코드만 정리할 수 있습니다.

#### 5. nginx에 인증서 적용 및 확인

Certbot의 `certonly`는 인증서 발급·저장까지만 수행합니다. `sudo certbot certificates`와 발급 결과에서 실제 인증서 경로를 확인합니다. 기존 nginx 설정이 같은 경로를 사용한다면 설정을 교체할 필요 없이 reload하면 됩니다.

최초 HTTPS 설정이거나 경로가 달라진 경우에는 실제 서비스 중인 nginx 설정 파일을 백업한 뒤, 해당 도메인의 `listen 443 ssl` 서버 블록에서 다음 두 항목을 실제 경로에 맞춥니다. 기존 프록시 설정은 유지합니다.

프론트엔드 예시:

```nginx
ssl_certificate /etc/letsencrypt/live/scsc.dev/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/scsc.dev/privkey.pem;
```

백엔드 예시:

```nginx
ssl_certificate /etc/letsencrypt/live/api.scsc.dev/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/api.scsc.dev/privkey.pem;
```

인증서 이름에 `-0001` 등이 붙었다면 위 예시 대신 실제 경로를 사용합니다. 설정 검사가 성공한 경우에만 reload합니다.

```bash
sudo nginx -t && sudo systemctl reload nginx
```

작업한 도메인의 HTTPS 응답을 확인합니다. 인증서 검증을 생략하는 `-k` 옵션은 사용하지 않습니다.

```bash
curl -I --max-time 15 https://scsc.dev/
curl -I --max-time 15 https://api.scsc.dev/
```

응답 코드는 요청한 경로에 따라 달라질 수 있습니다. 인증서 오류가 없는지 확인하고, 브라우저의 인증서 정보에서 실제 제공 중인 인증서의 대상 도메인과 만료일도 확인합니다.

#### 다음 갱신 시 주의사항

이 방식은 사람이 TXT 레코드를 등록하는 수동 인증입니다. DNS 자동화 플러그인이나 `--manual-auth-hook`을 별도로 구성하지 않았다면 `certbot renew`만으로 자동 갱신되지 않습니다. 다음 갱신 때도 같은 수동 명령어로 시작하여 새로 요청되는 TXT 레코드를 등록하고, 발급 후 nginx를 reload합니다.

참고: [Certbot 수동 인증 및 갱신 문서](https://eff-certbot.readthedocs.io/en/stable/using.html#manual), [가비아 DNS 레코드 설정 매뉴얼](https://customer.gabia.com/manual/domain/287/1201)
