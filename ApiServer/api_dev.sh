#!/bin/bash

set -e  # 에러 발생 시 스크립트 즉시 중단

# -----------------------
# 0) 사전 변수 설정
# -----------------------
MYSQL_HOST="{DB 엔드포인트}"
DOMAIN_ID="{조직 ID}"
PROJECT_ID="{프로젝트 ID}"
TOPIC_NAME_PUBSUB="{PUB/SUB Topic 이름}(로그 적재용, API로 생성할 이름)"
TOPIC_NAME_KAFKA="{Kafka Topic 이름}"
CREDENTIAL_ID="{액세스 키 ID}"
CREDENTIAL_SECRET="{보안 액세스 키}"

LOGSTASH_ENV_FILE="/etc/default/logstash"
LOGSTASH_KAFKA_ENDPOINT="{카프카 엔드포인트}"

# (원격 RAW 파일 주소)
FILEBEAT_YML_URL="https://raw.githubusercontent.com/KOlizer/syu-DataAnalyze/main/ApiServer/filebeat.yml"
LOGSTASH_CONF_URL="https://raw.githubusercontent.com/KOlizer/syu-DataAnalyze/main/ApiServer/logs-to-pubsub.conf"

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
# 1-1) Python,Flask gunicorn nginx mysql.conneter ,client, kafka 설치
# -----------------------
echo "kakaocloud: Python 설치"
sudo apt-get update
sudo apt-get install -y python3 python3-pip
sudo apt install -y python3 python3-pip gunicorn nginx python3-mysql.connector mysql-client
sudo apt install -y python3-flask
python3 --version
pip3 --version
sudo apt update
sudo apt install -y openjdk-21-jdk

cat << EOF | sudo tee -a /etc/profile
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export PATH=\$JAVA_HOME/bin:\$PATH
export CLASSPATH=\$CLASSPATH:\$JAVA_HOME/lib/ext:\$JAVA_HOME/lib/tools.jar
EOF

curl https://archive.apache.org/dist/kafka/3.7.1/kafka_2.13-3.7.1.tgz -o kafka_2.13-3.7.1.tgz
tar -xzf kafka_2.13-3.7.1.tgz
rm kafka_2.13-3.7.1.tgz
##########################################################################
# 1-2) Flask 앱 서비스(flask_app.service)에도 같은 변수를 써야 한다면
##########################################################################
SERVICE_FILE="/etc/systemd/system/flask_app.service"
# 서비스 파일 내용 작성
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
Environment=\"CREDENTIAL_ID=${CREDENTIAL_ID}\"
Environment=\"CREDENTIAL_SECRET=${CREDENTIAL_SECRET}\"
ExecStart=/usr/bin/gunicorn --workers 9 --threads 4 -b 127.0.0.1:8080 app:app

[Install]
WantedBy=multi-user.target
EOF"

echo "FLASK 앱 환경변수 설정 완료!."

# systemd 데몬 재로드 및 서비스 재시작
sudo systemctl daemon-reload
sudo systemctl restart flask_app
sudo systemctl enable flask_app

echo "flask_app.service has been reloaded and restarted successfully."

# -----------------------
# 2) Logstash, Filebeat 설치
# -----------------------
echo "kakaocloud: Logstash, Filebeat 설치 및 설정"
curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee /etc/apt/sources.list.d/beats.list
sudo apt-get update
sudo apt-get install -y filebeat logstash
sudo systemctl enable filebeat
sudo systemctl start filebeat
sudo systemctl enable logstash
sudo systemctl start logstash

# -----------------------
# /etc/default/logstash에 환경 변수 추가
# -----------------------
echo "kakaocloud: /etc/default/logstash에 환경 변수를 추가합니다."
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

export CREDENTIAL_ID CREDENTIAL_SECRET DOMAIN_ID PROJECT_ID TOPIC_NAME_PUBSUB TOPIC_NAME_KAFKA MYSQL_HOST
EOF"

sudo systemctl daemon-reload
sudo systemctl restart logstash

# -----------------------
# 3) Filebeat 설정 파일 다운로드
# -----------------------
echo "kakaocloud: Filebeat 구성 파일 다운로드: $FILEBEAT_YML_URL"
sudo wget -O /etc/filebeat/filebeat.yml "$FILEBEAT_YML_URL"
echo "kakaocloud: Filebeat 구성 파일 권한 설정"
sudo chmod 644 /etc/filebeat/filebeat.yml
sudo chown root:root /etc/filebeat/filebeat.yml
echo "kakaocloud: Filebeat 서비스 재시작"
sudo systemctl daemon-reload
sudo systemctl restart filebeat

# -----------------------
# 4) Logstash conf 다운로드
# -----------------------
echo "kakaocloud: Logstash 구성 파일 다운로드: $LOGSTASH_CONF_URL"
sudo wget -O /etc/logstash/conf.d/logs-to-pubsub-and-kafka.conf "$LOGSTASH_CONF_URL"
echo "kakaocloud: Logstash 재시작"
sudo systemctl daemon-reload
sudo systemctl restart logstash

# -----------------------
# 6) 스크립트들 다운로드
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

echo "kakaocloud: 모든 작업 완료."
