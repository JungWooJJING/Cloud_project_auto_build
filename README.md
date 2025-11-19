# Cloud_project_auto_build

이 리포지토리는 Cloud 프로젝트 환경을 한 번에 올리기 위한 자동 실행 스크립트를 포함하고 있습니다.  
`docker-compose.yml` 기반으로 컨테이너를 띄우고, MySQL 데이터베이스 테이블 생성 및 초기 데이터 복원을 수행합니다.

## 사전 준비

- Docker
- Docker Compose
- Git

## 사용 방법

```bash
# 리포지토리 클론
git clone https://github.com/JungWooJJING/Cloud_project_auto_build.git
cd Cloud_projec_auto_build

# 실행 권한 부여 (최초 1회)
chmod +x auto_build.sh

# 자동 실행
./auto_build.sh

