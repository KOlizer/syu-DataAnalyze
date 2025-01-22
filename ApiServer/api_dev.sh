#!/bin/bash

#### (A) 여기에 본인 환경값을 직접 작성해둔다.
MYSQL_HOST="{MySQL 엔드포인트}"
DOMAIN_ID="{조직 ID}"
PROJECT_ID="{프로젝트 ID}"
TOPIC_NAME="{Topic 이름}"
CREDENTIAL_ID="{액세스 키 ID}"
CREDENTIAL_SECRET="{보안 액세스 키}"


echo "kakaocloud: 1. ~/.bashrc에 환경 변수를 설정합니다."
##########################################################################
# 1) .bashrc에 기록
##########################################################################

# .bashrc에 추가할 export 문들 하나로 묶기
BASHRC_EXPORT=$(cat <<EOF
export MYSQL_HOST="$MYSQL_HOST"
export DOMAIN_ID="$DOMAIN_ID"
export PROJECT_ID="$PROJECT_ID"
export TOPIC_NAME="$TOPIC_NAME"
export CREDENTIAL_ID="$CREDENTIAL_ID"
export CREDENTIAL_SECRET="$CREDENTIAL_SECRET"
EOF
)

# 현재 세션에 즉시 적용
eval "$BASHRC_EXPORT"

# ~/.bashrc에도 추가(중복 방지 위해 grep 확인 가능)
if ! grep -q "MYSQL_HOST" /home/ubuntu/.bashrc; then
  echo "$BASHRC_EXPORT" >> /home/ubuntu/.bashrc
fi

# 다시 로드 (현재 쉘 세션에서 바로 사용 가능)
source /home/ubuntu/.bashrc

echo "kakaocloud: ~/.bashrc에 환경 변수를 추가 완료."


##########################################################################
# 2) systemd(예: Logstash 등)에서 같은 변수를 쓰려면?
##########################################################################
# 방법 1: /etc/default/logstash (Debian/Ubuntu 계열) 파일에 key=value 저장
# 방법 2: 특정 service.override에 [Service] Environment= 로 지정
# 여기서는 Logstash 예시로 /etc/default/logstash 사용

LOGSTASH_ENV_FILE="/etc/default/logstash"

echo "kakaocloud: 2. /etc/default/logstash에 환경 변수를 설정합니다."
sudo bash -c "cat <<EOF > $LOGSTASH_ENV_FILE
# Logstash 실행 시 불러올 환경 변수
MYSQL_HOST=\"$MYSQL_HOST\"
DOMAIN_ID=\"$DOMAIN_ID\"
PROJECT_ID=\"$PROJECT_ID\"
TOPIC_NAME=\"$TOPIC_NAME\"
CREDENTIAL_ID=\"$CREDENTIAL_ID\"
CREDENTIAL_SECRET=\"$CREDENTIAL_SECRET\"

export MYSQL_HOST DOMAIN_ID PROJECT_ID TOPIC_NAME CREDENTIAL_ID CREDENTIAL_SECRET
EOF"

echo "kakaocloud: /etc/default/logstash 설정 완료. Logstash 재시작 시 해당 변수 사용 가능."


##########################################################################
# (선택) 3) Flask 앱 서비스(flask_app.service)에도 같은 변수를 써야 한다면
##########################################################################
# main_script.sh에서 /etc/systemd/system/flask_app.service를 생성한다고 가정
# 아래처럼 override 파일을 생성해 [Service] Environment="..." 추가

SERVICE_FILE="/etc/systemd/system/flask_app.service"
OVERRIDE_DIR="/etc/systemd/system/flask_app.service.d"
OVERRIDE_FILE="$OVERRIDE_DIR/env.conf"

# Flask 앱 서비스가 존재한다고 가정
if [ -f "$SERVICE_FILE" ]; then
  echo "kakaocloud: flask_app.service override 설정을 진행합니다."
  sudo mkdir -p "$OVERRIDE_DIR"
  sudo bash -c "cat <<EOF > $OVERRIDE_FILE
[Service]
Environment=\"MYSQL_HOST=$MYSQL_HOST\"
Environment=\"DOMAIN_ID=$DOMAIN_ID\"
Environment=\"PROJECT_ID=$PROJECT_ID\"
Environment=\"TOPIC_NAME=$TOPIC_NAME\"
Environment=\"CREDENTIAL_ID=$CREDENTIAL_ID\"
Environment=\"CREDENTIAL_SECRET=$CREDENTIAL_SECRET\"
EOF"

  sudo systemctl daemon-reload
  sudo systemctl restart flask_app
  echo "kakaocloud: flask_app.service 재시작 완료."
else
  echo "kakaocloud: flask_app.service가 없어 override를 생략합니다."
fi


##########################################################################
# 4) 이어서 main_script.sh, setup_db.sh 다운로드 & 실행 권한 & 실행
##########################################################################

echo "kakaocloud: 3. 스크립트 다운로드 링크 유효성 체크"
curl --output /dev/null --silent --head --fail \
  "https://github.com/KOlizer/syu-DataAnalyze/raw/refs/heads/main/ApiServer/main_script.sh" || {
    echo "main_script.sh 다운로드 링크가 유효하지 않습니다."
    exit 1
  }

curl --output /dev/null --silent --head --fail \
  "https://github.com/KOlizer/syu-DataAnalyze/raw/refs/heads/main/ApiServer/setup_db.sh" || {
    echo "setup_db.sh 다운로드 링크가 유효하지 않습니다."
    exit 1
  }

echo "kakaocloud: 스크립트 다운로드 링크가 모두 유효합니다."


echo "kakaocloud: 4. 실제 스크립트 다운로드 및 실행 권한 설정"
wget -O main_script.sh \
  "https://github.com/KOlizer/syu-DataAnalyze/raw/refs/heads/main/ApiServer/main_script.sh"
wget -O setup_db.sh \
  "https://github.com/KOlizer/syu-DataAnalyze/raw/refs/heads/main/ApiServer/setup_db.sh"

chmod +x main_script.sh
chmod +x setup_db.sh

echo "kakaocloud: 5. 스크립트 실행을 시작합니다."
# -E로 현재 쉘의 환경 변수를 루트 실행에 전달
sudo -E ./main_script.sh
sudo -E ./setup_db.sh

echo "kakaocloud: 모든 작업 완료."
