#!/bin/bash

echo "kakaocloud: 1. 환경 변수 설정을 시작합니다."

# /home/ubuntu/.bashrc 에 영구적으로 저장할 환경 변수들을 선언한다.
command=$(cat <<EOF
export MYSQL_HOST="{MySQL 엔드포인트}"
EOF
)

# 현재 세션에 즉시 적용
eval "$command"

# ~/.bashrc에도 추가하여 다음 세션부터 항상 사용 가능하도록 설정
echo "$command" >> /home/ubuntu/.bashrc
source /home/ubuntu/.bashrc
echo "kakaocloud: 환경 변수 설정이 완료되었습니다."


echo "kakaocloud: 2. 스크립트 다운로드 링크 유효성 체크를 시작합니다."

# main_script.sh 다운로드 가능 여부 확인
curl --output /dev/null --silent --head --fail "https://github.com/KOlizer/syu-DataAnalyze/raw/refs/heads/main/ApiServer/main_script.sh" || {
  echo "main_script.sh 다운로드 링크가 유효하지 않습니다."
  exit 1
}

# setup_db.sh 다운로드 가능 여부 확인
curl --output /dev/null --silent --head --fail "https://github.com/KOlizer/syu-DataAnalyze/raw/refs/heads/main/ApiServer/setup_db.sh" || {
  echo "setup_db.sh 다운로드 링크가 유효하지 않습니다."
  exit 1
}

echo "kakaocloud: 스크립트 다운로드 링크가 모두 유효합니다."


echo "kakaocloud: 3. 스크립트 다운로드 및 실행 권한 설정을 진행합니다."

# 스크립트 다운로드
wget -O main_script.sh "https://github.com/KOlizer/syu-DataAnalyze/raw/refs/heads/main/ApiServer/main_script.sh"
wget -O setup_db.sh "https://github.com/KOlizer/syu-DataAnalyze/raw/refs/heads/main/ApiServer/setup_db.sh"

# 실행 권한 부여
chmod +x main_script.sh
chmod +x setup_db.sh

echo "kakaocloud: 4. 스크립트 실행을 시작합니다."

# 환경 변수를 상속(-E)하여 스크립트를 실행
sudo -E ./main_script.sh
sudo -E ./setup_db.sh

echo "kakaocloud: 모든 작업이 완료되었습니다. 메인 스크립트와 DB 설정 스크립트가 차례대로 실행되었습니다."
