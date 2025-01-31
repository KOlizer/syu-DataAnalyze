#!/bin/bash

MYSQL_HOST="az-a.api-db-sh.0aa67b93c3ec48e587a51c9f842ca407.mysql.managed-service.kr-central-2.kakaocloud.com"
DOMAIN_ID="{조직 ID}"
PROJECT_ID="{프로젝트 ID}"
TOPIC_NAME="{Topic 이름}"
CREDENTIAL_ID="{액세스 키 ID}"
CREDENTIAL_SECRET="{보안 액세스 키}"
LOGSTASH_ENV_FILE="/etc/default/logstash"


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

echo "kakaocloud: 2. /etc/default/logstash에 환경 변수를 '추가'합니다. (append)"

# 1) 공식 Elastic GPG 키 등록
curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -

# 2) 저장소 추가
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee /etc/apt/sources.list.d/beats.list

# 3) 패키지 업데이트 후 filebeat, logstash 설치
sudo apt-get update
sudo apt-get install filebeat
sudo apt-get update
sudo apt-get install logstash

sudo systemctl enable filebeat
sudo systemctl start filebeat
sudo systemctl enable logstash
sudo systemctl start logstash

sudo chmod 777 /etc/default/logstash

sudo bash -c "cat <<EOF >> $LOGSTASH_ENV_FILE

# === Additional Env for Pub/Sub ===
CREDENTIAL_ID=\"$CREDENTIAL_ID\"
CREDENTIAL_SECRET=\"$CREDENTIAL_SECRET\"
DOMAIN_ID=\"$DOMAIN_ID\"
PROJECT_ID=\"$PROJECT_ID\"
TOPIC_NAME=\"$TOPIC_NAME\"

export CREDENTIAL_ID CREDENTIAL_SECRET DOMAIN_ID PROJECT_ID TOPIC_NAME
EOF"

echo "kakaocloud: $LOGSTASH_ENV_FILE 파일 끝에 환경변수 추가 완료."

# systemd 재시작
sudo systemctl daemon-reload
sudo systemctl restart logstash

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
  "https://github.com/KOlizer/syu-DataAnalyze/raw/refs/heads/lys-test/ApiServer/main_script.sh" || {
    echo "main_script.sh 다운로드 링크가 유효하지 않습니다."
    exit 1
  }

curl --output /dev/null --silent --head --fail \
  "https://github.com/KOlizer/syu-DataAnalyze/raw/refs/heads/lys-test/ApiServer/setup_db.sh" || {
    echo "setup_db.sh 다운로드 링크가 유효하지 않습니다."
    exit 1
  }

echo "kakaocloud: 스크립트 다운로드 링크가 모두 유효합니다."


echo "kakaocloud: 4. 실제 스크립트 다운로드 및 실행 권한 설정"
wget -O main_script.sh \
  "https://github.com/KOlizer/syu-DataAnalyze/raw/refs/heads/lys-test/ApiServer/main_script.sh"
wget -O setup_db.sh \
  "https://github.com/KOlizer/syu-DataAnalyze/raw/refs/heads/lys-test/ApiServer/setup_db.sh"

chmod +x main_script.sh
chmod +x setup_db.sh

echo "kakaocloud: 5. 스크립트 실행을 시작합니다."
# -E로 현재 쉘의 환경 변수를 루트 실행에 전달
sudo -E ./main_script.sh
sudo -E ./setup_db.sh

echo "kakaocloud: 모든 작업 완료."
