#!/bin/bash
# Docker Compose 시작 및 데이터베이스 테이블 자동 생성 스크립트

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "Docker Compose 시작 중..."
echo "=========================================="

# Docker Compose 시작
docker-compose up -d

echo ""
echo "데이터베이스 준비 대기 중..."
# MySQL이 준비될 때까지 대기 (최대 60초)
MAX_WAIT=60
WAIT_COUNT=0
while ! docker exec mal-db mysqladmin ping -h 127.0.0.1 -u mal-db -p123456 --silent 2>/dev/null; do
  if [ $WAIT_COUNT -ge $MAX_WAIT ]; then
    echo "데이터베이스가 준비되지 않았습니다. (타임아웃)"
    exit 1
  fi
  echo "  대기 중... ($WAIT_COUNT/$MAX_WAIT 초)"
  sleep 2
  WAIT_COUNT=$((WAIT_COUNT + 2))
done

echo "데이터베이스 준비 완료!"
echo ""

echo "=========================================="
echo "데이터베이스 테이블 생성 중..."
echo "=========================================="

# 테이블 생성
docker exec -i mal-db mysql -u mal-db -p123456 -h 127.0.0.1 mal-db << 'EOF'
-- Users table
CREATE TABLE IF NOT EXISTS `users` (
  `idx` INT AUTO_INCREMENT PRIMARY KEY,
  `email` VARCHAR(100) NOT NULL UNIQUE,
  `password` VARCHAR(255) NOT NULL,
  `name` VARCHAR(200) NOT NULL,
  INDEX `idx_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Files table
CREATE TABLE IF NOT EXISTS `files` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `email` VARCHAR(100) NOT NULL,
  `size` BIGINT NOT NULL,
  `path` VARCHAR(500),
  `filename` VARCHAR(255) NOT NULL,
  `sha256` VARCHAR(64),
  `type` VARCHAR(100),
  `status` TEXT,
  INDEX `idx_email` (`email`),
  INDEX `idx_status` (`status`(50))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Analyses table
CREATE TABLE IF NOT EXISTS `analyses` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `filename` VARCHAR(255) NOT NULL,
  `verdict` VARCHAR(50) NOT NULL,
  `email` VARCHAR(100) NOT NULL,
  INDEX `idx_email` (`email`),
  INDEX `idx_verdict` (`verdict`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
EOF

if [ $? -eq 0 ]; then
  echo " 테이블 생성 완료!"
else
  echo " 테이블 생성 실패!"
  exit 1
fi

echo ""
echo "=========================================="
echo "데이터 복원 중..."
echo "=========================================="

# 데이터 복원 (이미 있으면 스킵)
docker exec mal-db bash -c "tail -n +2 /docker-entrypoint-initdb.d/data.sql > /tmp/data_clean.sql && mysql -u mal-db -p123456 -h 127.0.0.1 mal-db < /tmp/data_clean.sql 2>&1 | grep -v 'Warning\|Duplicate' || true"

echo ""
echo "=========================================="
echo "데이터베이스 상태 확인"
echo "=========================================="

docker exec mal-db mysql -u mal-db -p123456 -h 127.0.0.1 mal-db -e "
SHOW TABLES;
SELECT 'users' as table_name, COUNT(*) as count FROM users
UNION ALL
SELECT 'files', COUNT(*) FROM files
UNION ALL
SELECT 'analyses', COUNT(*) FROM analyses;
" 2>/dev/null | grep -v "Warning"

echo ""
echo "=========================================="
echo " 모든 작업 완료!"
echo "=========================================="
echo ""
echo "실행 중인 컨테이너:"
docker-compose ps


