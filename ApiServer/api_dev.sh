#!/bin/bash

set -e  # 에러 발생 시 스크립트 즉시 중단

# -----------------------
# 0) 사전 변수 설정
# -----------------------
MYSQL_HOST="{DB 엔드포인트}"
DOMAIN_ID="{조직 ID}"
PROJECT_ID="{프로젝트 ID}"
TOPIC_NAME_PUBSUB="{PUB/SUB Topic 이름}(로그 적재용, TG에서 API로 생성할 이름)"
TOPIC_NAME_KAFKA="{object storage 적재용 Kafka Topic 이름}"
CREDENTIAL_ID="{액세스 키 ID}"
CREDENTIAL_SECRET="{보안 액세스 키}"

LOGSTASH_ENV_FILE="/etc/default/logstash"
LOGSTASH_KAFKA_ENDPOINT="{kafka 부트스트랩 서버}"

# (원격 RAW 파일 주소)
FILEBEAT_YML_URL="https://raw.githubusercontent.com/KOlizer/syu-DataAnalyze/main/ApiServer/filebeat.yml"
LOGSTASH_CONF_1_URL="https://raw.githubusercontent.com/KOlizer/syu-DataAnalyze/main/ApiServer/logs-to-pubsub.conf"
LOGSTASH_CONF_2_URL="https://raw.githubusercontent.com/KOlizer/syu-DataAnalyze/main/ApiServer/logs-to-kafka.conf"


# -----------------------
# 1) ~/.bashrc에 환경 변수 설정
# -----------------------
echo "kakaocloud: 1. ~/.bashrc에 환경 변수를 설정합니다."

BASHRC_EXPORT=$(cat <<EOF
export MYSQL_HOST="$MYSQL_HOST"
export DOMAIN_ID="$DOMAIN_ID"
export PROJECT_ID="$PROJECT_ID"
export TOPIC_NAME_PUBSUB="$TOPIC_NAME_PUBSUB"
export TOPIC_NAME_KAFKA="$TOPIC_NAME_KAFKA"
export CREDENTIAL_ID="$CREDENTIAL_ID"
export CREDENTIAL_SECRET="$CREDENTIAL_SECRET"
export LOGSTASH_KAFKA_ENDPOINT="$LOGSTASH_KAFKA_ENDPOINT"

EOF
)

# 현재 쉘에 적용
eval "$BASHRC_EXPORT"

# ~/.bashrc에 추가 (중복 체크)
if ! grep -q "MYSQL_HOST" /home/ubuntu/.bashrc; then
  echo "$BASHRC_EXPORT" >> /home/ubuntu/.bashrc
fi

source /home/ubuntu/.bashrc
echo "kakaocloud: ~/.bashrc에 환경 변수를 추가 완료."

# -----------------------
# 1-1) Python,Flask, Gunicorn, Nginx, MySQL 관련 패키지 설치
# -----------------------
echo "kakaocloud: Python, Flask, Gunicorn, Nginx, MySQL 관련 패키지 설치"
sudo apt-get update
sudo apt-get install -y python3 python3-pip
sudo apt install -y python3 python3-pip gunicorn nginx python3-mysql.connector mysql-client
sudo apt install -y python3-flask
python3 --version
pip3 --version

# -----------------------
# 1-2) Flask 앱 서비스(flask_app.service) 구성
# -----------------------
SERVICE_FILE="/etc/systemd/system/flask_app.service"
echo "kakaocloud: flask_app.service 설정 파일 생성"

sudo bash -c "cat > $SERVICE_FILE <<EOF
[Unit]
Description=Gunicorn instance to serve Flask app
After=network.target

[Service]
User=ubuntu
Group=www-data
WorkingDirectory=/var/www/flask_app
Environment=\"MYSQL_HOST=${MYSQL_HOST}\"
Environment=\"DOMAIN_ID=${DOMAIN_ID}\"
Environment=\"PROJECT_ID=${PROJECT_ID}\"
Environment=\"TOPIC_NAME_PUBSUB=${TOPIC_NAME_PUBSUB}\"
Environment=\"TOPIC_NAME_KAFKA=${TOPIC_NAME_KAFKA}\"
Environment=\"CREDENTIAL_ID=${CREDENTIAL_ID}\"
Environment=\"CREDENTIAL_SECRET=${CREDENTIAL_SECRET}\"
ExecStart=/usr/bin/gunicorn --workers 9 --threads 4 -b 127.0.0.1:8080 app:app

[Install]
WantedBy=multi-user.target
EOF"

echo "kakaocloud: flask_app.service 설정 완료."


# -----------------------
# 2) Logstash, Filebeat 설치(설정 파일 만 적용, 재시작은 맨 끝에서)
# -----------------------
echo "kakaocloud: Logstash, Filebeat 설치"
curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee /etc/apt/sources.list.d/beats.list
sudo apt-get update
sudo apt-get install -y filebeat logstash

sudo systemctl enable filebeat
sudo systemctl start filebeat
sudo systemctl enable logstash
sudo systemctl start logstash

# -----------------------
# /etc/default/logstash에 환경 변수 추가 (재시작은 나중에)
# -----------------------
echo "kakaocloud: /etc/default/logstash에 환경 변수를 추가"
sudo chmod 644 "$LOGSTASH_ENV_FILE"
sudo bash -c "cat <<EOF >> $LOGSTASH_ENV_FILE


# === Additional Env for Pub/Sub and Kafka ===
CREDENTIAL_ID=\"$CREDENTIAL_ID\"
CREDENTIAL_SECRET=\"$CREDENTIAL_SECRET\"
DOMAIN_ID=\"$DOMAIN_ID\"
PROJECT_ID=\"$PROJECT_ID\"
TOPIC_NAME_PUBSUB=\"$TOPIC_NAME_PUBSUB\"
TOPIC_NAME_KAFKA=\"$TOPIC_NAME_KAFKA\"
MYSQL_HOST=\"$MYSQL_HOST\"
LOGSTASH_KAFKA_ENDPOINT=\"$LOGSTASH_KAFKA_ENDPOINT\"


export CREDENTIAL_ID CREDENTIAL_SECRET DOMAIN_ID PROJECT_ID TOPIC_NAME_PUBSUB TOPIC_NAME_KAFKA MYSQL_HOST LOGSTASH_KAFKA_ENDPOINT
EOF"

# -----------------------
# 3) Filebeat 구성 파일 다운로드 (재시작은 나중에)
# -----------------------
echo "kakaocloud: Filebeat 구성 파일 다운로드: $FILEBEAT_YML_URL"
sudo wget -O /etc/filebeat/filebeat.yml "$FILEBEAT_YML_URL"
sudo chmod 644 /etc/filebeat/filebeat.yml
sudo chown root:root /etc/filebeat/filebeat.yml

# -----------------------
# 4) Logstash conf 다운로드 (재시작은 나중에)
# -----------------------
echo "kakaocloud: Logstash 구성 파일 다운로드: $LOGSTASH_CONF_1_URL, $LOGSTASH_CONF_2_URL"
sudo wget -O /etc/logstash/conf.d/logs-to-pubsub.conf "$LOGSTASH_CONF_1_URL"
sudo wget -O /etc/logstash/conf.d/logs-to-kafka.conf "$LOGSTASH_CONF_2_URL"

# -----------------------
# 5) 스크립트들 다운로드
# -----------------------
echo "kakaocloud: main_script.sh, setup_db.sh 다운로드 링크 확인..."
curl --output /dev/null --silent --head --fail "https://github.com/KOlizer/syu-DataAnalyze/raw/refs/heads/main/ApiServer/main_script.sh" || {
  echo "main_script.sh 다운로드 링크가 유효하지 않습니다."
  exit 1
}
curl --output /dev/null --silent --head --fail "https://github.com/KOlizer/syu-DataAnalyze/raw/refs/heads/main/ApiServer/setup_db.sh" || {
  echo "setup_db.sh 다운로드 링크가 유효하지 않습니다."
  exit 1
}

echo "kakaocloud: 다운로드 실행"
wget -O main_script.sh "https://github.com/KOlizer/syu-DataAnalyze/raw/refs/heads/main/ApiServer/main_script.sh"
wget -O setup_db.sh "https://github.com/KOlizer/syu-DataAnalyze/raw/refs/heads/main/ApiServer/setup_db.sh"
chmod +x main_script.sh
chmod +x setup_db.sh

# -----------------------
# 마지막에 몰아서 재시작/enable 처리
# -----------------------
echo "kakaocloud: 모든 설정이 끝났습니다. 이제 서비스를 재시작하고 활성화합니다."

# 1) systemd 데몬 재로드
sudo systemctl daemon-reload

# 2) flask_app
sudo systemctl enable flask_app
sudo systemctl restart flask_app


echo "kakaocloud: 모든 서비스를 재시작하였습니다."

echo "kakaocloud: 모든 작업 완료."
echo ""
echo "추가 안내:"
echo "  - 환경 변수 적용 확인: source /home/ubuntu/.bashrc"
echo "  - DB 세팅 스크립트:   sudo -E ./setup_db.sh"
echo "  - 메인 스크립트:       sudo -E ./main_script.sh"
echo "  - Flask 재실행:       sudo systemctl restart flask_app && sudo systemctl status flask_app"
