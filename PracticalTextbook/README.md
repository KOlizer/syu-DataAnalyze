# Kakao Cloud 실습 가이드

> **주의**  
> 본 문서는 계속 수정될 수 있습니다. 실습 환경 및 요구 사항에 따라 적절히 수정하여 사용해주세요.
# 콘솔에서 만들어야할 자원
필요한 인프라 생성(TrafficGenerator, APIServer, ALB...)


## Pub/Sub 토픽 생성

- **이름**: `test-topic`
- **기본서브스크립션**: `생성 안함`
- **토픽 메세지 보존 기간**: `0일 0시 10분`
- **인스턴스유형**: `m2a.xlarge`
- **설명**: `없음`
  
## MySQL 생성

- **이름**: `database`
- **인스턴스 가용성**: `단일`
- **MySQL 사용자 이름**: `admin`
- **MySQL 비밀번호**: `admin1234`
- **인스턴스 유형**: `m2a.large`
- **VPC**: `실습환경`
- **Subnet**: `실습환경`
- **자동 백업 옵션**: `미사용`



## Data Catalog 생성
## Kafka 생성

- **이름**: `kafka`
- **인스턴스 유형**: `r2a.2xlarge`
- **VPC**: `실습환경`
- **Subnet**: `실습환경`
- **보안 그룹**: `인바운드: 9092`
- **브로커 수**: `2`


## Hadoop
(※ 별도의 가이드 혹은 기존 실습 환경에 맞추어 진행)

## ObjectStorage 생성
- **LB Accesslog용 버킷**
  -**이름**:`lb-accesslog`
- **Nginx 로그 수집용 버킷 (`Pub/Sub` 연동)**
  -**이름**:`pubsub-nginx-log`
- **Nginx 로그 수집용 버킷 (`kafka` 연동)**
  -**이름**:`kafka-nginx-log`
- **`Data Query`의 쿼리 결과 저장용 버킷**
  -**이름**:`data-query-result`
- **Spark, Hive 처리 결과에 대한 저장용 버킷**
  -**이름**:`hive-result`

## API 서버 생성 (2대)

- **이름**: `api-server`
- **개수**: `2`
- **이미지**: `Ubuntu 22.04`
- **인스턴스유형**: `m2a.xlarge`
- **볼륨**: `30GB`
- **키페어**  
  - **키페어 생성 후 등록**
- **VPC**: 실습 환경
- **서브넷**: `main`
- **보안 그룹(SG) 생성**   
  - 필요 포트 규칙 설정:
    - 인바운드: `22, 3306, 80, 5044`

- **해당 스크립트를 API서버 생성시 고급설정에 붙혀넣기**</br>
- **환경변수는 본인의 것으로 항상 수정하기** 

```   
#!/bin/bash

MYSQL_HOST="MySQL 엔드포인트"
DOMAIN_ID="조직 ID"
PROJECT_ID="프로젝트 ID"
PUBSUB_TOPIC_NAME="Pub/Sub 토픽 이름"
TOPIC_NAME_KAFKA="Kafka 토픽 이름"
CREDENTIAL_ID="액세스 키 ID"
CREDENTIAL_SECRET="보안 액세스 키"
LOGSTASH_ENV_FILE="/etc/default/logstash"
LOGSTASH_KAFKA_ENDPOINT="Kafka 클러스터 부트스트랩 서버"


echo "kakaocloud: 1. ~/.bashrc에 환경 변수를 설정합니다."
##########################################################################
# 1) .bashrc에 기록
##########################################################################

BASHRC_EXPORT=$(cat <<EOF
export MYSQL_HOST="$MYSQL_HOST"
export DOMAIN_ID="$DOMAIN_ID"
export PROJECT_ID="$PROJECT_ID"
export PUBSUB_TOPIC_NAME="$PUBSUB_TOPIC_NAME"
export TOPIC_NAME_KAFKA="$TOPIC_NAME_KAFKA"
export CREDENTIAL_ID="$CREDENTIAL_ID"
export CREDENTIAL_SECRET="$CREDENTIAL_SECRET"
export LOGSTASH_KAFKA_ENDPOINT="$LOGSTASH_KAFKA_ENDPOINT"
EOF
)

eval "$BASHRC_EXPORT"

if ! grep -q "MYSQL_HOST" /home/ubuntu/.bashrc; then
  echo "$BASHRC_EXPORT" >> /home/ubuntu/.bashrc
fi

source /home/ubuntu/.bashrc

echo "kakaocloud: ~/.bashrc에 환경 변수를 추가 완료."

##########################################################################
# 2) filebeat / logstash 설치
##########################################################################

echo "kakaocloud: 2. filebeat / logstash 설치 후 환경 변수 추가"

curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee /etc/apt/sources.list.d/beats.list

sudo apt-get update
# 설치 중 사용자 입력이 없도록 -y 옵션
sudo apt-get install -y filebeat
sudo apt-get install -y logstash

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
PUBSUB_TOPIC_NAME=\"$PUBSUB_TOPIC_NAME\"
TOPIC_NAME_KAFKA=\"$TOPIC_NAME_KAFKA\"
LOGSTASH_KAFKA_ENDPOINT=\"$LOGSTASH_KAFKA_ENDPOINT\"

export CREDENTIAL_ID CREDENTIAL_SECRET DOMAIN_ID PROJECT_ID TOPIC_NAME_PUBSUB TOPIC_NAME_KAFKA MYSQL_HOST LOGSTASH_KAFKA_ENDPOINT
EOF"

sudo systemctl daemon-reload
sudo systemctl restart logstash

##########################################################################
# 4) (선택) Flask 앱 서비스(flask_app.service)에 같은 변수 쓰기
##########################################################################

SERVICE_FILE="/etc/systemd/system/flask_app.service"
OVERRIDE_DIR="/etc/systemd/system/flask_app.service.d"
OVERRIDE_FILE="$OVERRIDE_DIR/env.conf"

if [ -f "$SERVICE_FILE" ]; then
  echo "kakaocloud: flask_app.service override 설정을 진행합니다."
  sudo mkdir -p "$OVERRIDE_DIR"
  sudo bash -c "cat <<EOF > $OVERRIDE_FILE
[Service]
Environment=\"MYSQL_HOST=$MYSQL_HOST\"
Environment=\"DOMAIN_ID=$DOMAIN_ID\"
Environment=\"PROJECT_ID=$PROJECT_ID\"
Environment=\"PUBSUB_TOPIC_NAME=$PUBSUB_TOPIC_NAME\"
Environment=\"TOPIC_NAME_KAFKA=$TOPIC_NAME_KAFKA\"
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
# 5) main_script.sh & setup_db.sh 다운로드, 실행
##########################################################################

echo "kakaocloud: 5. 스크립트 다운로드 링크 유효성 체크"
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
echo "kakaocloud: 6. 실제 스크립트 다운로드 및 실행 권한 설정"

wget -O main_script.sh \
  "https://github.com/KOlizer/syu-DataAnalyze/raw/refs/heads/main/ApiServer/main_script.sh"

wget -O setup_db.sh \
  "https://github.com/KOlizer/syu-DataAnalyze/raw/refs/heads/main/ApiServer/setup_db.sh"

chmod +x main_script.sh
chmod +x setup_db.sh

echo "kakaocloud: 7. 스크립트 실행을 시작합니다."
sudo -E ./main_script.sh
sudo -E ./setup_db.sh



##########################################################################
# 3) filebeat.yml & logs-to-pubsub.conf 다운로드
##########################################################################

echo "kakaocloud: 3. filebeat.yml과 logs-to-pubsub.conf를 다운로드합니다."
sudo wget -O /etc/filebeat/filebeat.yml \
  "https://github.com/KOlizer/syu-DataAnalyze/raw/refs/heads/main/ApiServer/filebeat.yml"

sudo wget -O /etc/logstash/conf.d/logs-to-pubsub.conf \
  "https://github.com/KOlizer/syu-DataAnalyze/raw/refs/heads/main/ApiServer/logs-to-pubsub.conf"

sudo wget -O /etc/logstash/conf.d/logs-to-kafka.conf \
  "https://github.com/KOlizer/syu-DataAnalyze/raw/refs/heads/main/ApiServer/logs-to-kafka.conf"

echo "kakaocloud: filebeat.yml 및 logs-to-pubsub.conf 파일 다운로드 완료."

echo "kakaocloud: filebeat, logstash 서비스를 다시 시작합니다."
sudo systemctl restart filebeat
sudo systemctl restart logstash

echo "kakaocloud: 모든 작업 완료"
```
## 로드 밸런서(ALB) 생성

- **유형**: `ALB`
- **이름**: `api-lb`
- **상태 확인**: `x`
- **VPC**: `실습 환경`
- **서브넷**: `실습 환경`
- **생성**  
  - 퍼블릭 IP 부여
  - 리스너 추가  
    - **새 대상 그룹 추가**  
      - 리스너: `HTTP:80`  
      - 대상 그룹 이름: `api-lb-group`
      - 상태 확인: `미사용`
        
      - `다음`  
      - 연결할 인스턴스 선택: `api-server` 2대  
      - `대상추가`
      - `다음` 
      - `생성`
  - 새로고침 후, 생성된 대상 그룹 선택 → `추가`



## TestTopic 토픽의 Pull Subscription
- **이름**: `pull-subscription`
- **토픽 선택**: `test-topic`
- **유형**: `Pull`
  
## TestTopic 토픽의 Push Subscription
- **이름**: `push-subscription`
- **토픽 선택**: `test-topic`
- **유형**: `Push`
  - **엔드포인트**: `http://` + `ALB 퍼블릭 아이피` + `/push-subscription`

## Traffic_Generator 서버 생성 (2대)

- **이름**: `traffic-generator`
- **이미지**: `Ubuntu 22.04`
- **인스턴스유형**: `m2a.xlarge`
- **볼륨**: `30GB`
- **VPC**: 실습 환경
- **보안 그룹(SG) 생성**  
  - `22, 80, 8080, 443, 3306, 5044, 9092`
 

- 고급 스크립트 부분에 환경변수 수정 후 입력하여 생성
  ```
  
  ```
- 실습 진행
---
