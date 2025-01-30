#!/bin/bash

# setup_initial.sh
# 이 스크립트는 환경 변수를 설정하고 GitHub 저장소를 클론한 후, config.yml을 생성하고 setup_all.sh를 실행합니다.

# 스크립트 실행 중 에러 발생 시 즉시 종료
set -e

# ----------------------------------------
# 1. 환경 변수 설정
# ----------------------------------------

echo "========================================"
echo "1. 환경 변수 설정 시작"
echo "========================================"

# 환경 변수 정의 (필요한 변수만 포함)
export PUBSUB_ENDPOINT="https://pub-sub.kr-central-2.kakaocloud.com"
export DOMAIN_ID="{조직 ID}"
export PROJECT_ID="{프로젝트 ID}"
export TOPIC_NAME="{콘솔에서 생성 한 PUB/SUB Topic 이름}"
export SUB_NAME="{콘솔에서 생성한 PUB/SUB Subcription 이름}"
export TOPIC_DESCRIPTION=""
export TOPIC_RETENTION_DURATION="600s"
export CREDENTIAL_ID="{액세스 키 ID}"
export CREDENTIAL_SECRET="{보안 액세스 키}"
export API_BASE_URL="{ALB 주소}"

export TOPIC_NAME_MK="{VM2에서 진행하는 CreateTopic실습용 토픽 이름}" 
export OBJECT_STORAGE_SUBSCRIPTION_NAME_MK="{VM2에서 진행하는 CreateTopic실습용 서브스크립션 이름}"
export OBJECT_STORAGE_BUCKET="{로그 적재용 ObjectStorage 버킷 이름}"
export EXPORT_INTERVAL_MIN=10
export FILE_PREFIX=""
export FILE_SUFFIX=".log"
export CHANNEL_COUNT=4
export MAX_CHANNEL_COUNT=10
export IS_EXPORT_ENABLED=true
export LOG_FILENAME="traffic_generator.log"
export LOG_LEVEL="INFO"
export NUM_USERS=20
export MAX_THREADS=5
export ACTIONS_PER_USER=30


echo "환경 변수 설정 완료."

# 환경 변수들을 .bashrc에 추가
echo "환경 변수들을 .bashrc에 추가 중..."
cat <<EOL >> ~/.bashrc
export PUBSUB_ENDPOINT="$PUBSUB_ENDPOINT"
export DOMAIN_ID="$DOMAIN_ID"
export PROJECT_ID="$PROJECT_ID"
export TOPIC_NAME="$TOPIC_NAME"
export TOPIC_NAME_MK="$TOPIC_NAME_MK"
export TOPIC_DESCRIPTION="$TOPIC_DESCRIPTION"
export TOPIC_RETENTION_DURATION="$TOPIC_RETENTION_DURATION"
export SUB_NAME="$SUB_NAME"
export CREDENTIAL_ID="$CREDENTIAL_ID"
export CREDENTIAL_SECRET="$CREDENTIAL_SECRET"

export OBJECT_STORAGE_SUBSCRIPTION_NAME="$OBJECT_STORAGE_SUBSCRIPTION_NAME"
export OBJECT_STORAGE_BUCKET="$OBJECT_STORAGE_BUCKET"
export EXPORT_INTERVAL_MIN=$EXPORT_INTERVAL_MIN
export FILE_PREFIX="$FILE_PREFIX"
export FILE_SUFFIX="$FILE_SUFFIX"
export CHANNEL_COUNT=$CHANNEL_COUNT
export MAX_CHANNEL_COUNT=$MAX_CHANNEL_COUNT
export IS_EXPORT_ENABLED=$IS_EXPORT_ENABLED
export LOG_FILENAME="$LOG_FILENAME"
export LOG_LEVEL="$LOG_LEVEL"
export NUM_USERS=$NUM_USERS
export MAX_THREADS=$MAX_THREADS
export ACTIONS_PER_USER=$ACTIONS_PER_USER
export API_BASE_URL="$API_BASE_URL"
EOL

echo ".bashrc에 환경 변수 추가 완료."

# ----------------------------------------
# 2. GitHub 저장소 클론 및 setup_all.sh 실행
# ----------------------------------------

echo "========================================"
echo "2. GitHub 저장소 클론"
echo "========================================"

# GitHub 저장소 정보
REPO_URL="https://github.com/KOlizer/syu-DataAnalyze.git"
CLONE_DIR="$HOME/syu-DataAnalyze"

# 저장소가 Git 저장소인지 확인하는 함수
is_git_repo() {
    [ -d "$1/.git" ]
}

# 저장소 클론 또는 업데이트
if is_git_repo "$CLONE_DIR"; then
    echo "저장소가 이미 클론되어 있습니다: $CLONE_DIR"
    echo "저장소를 최신 상태로 업데이트합니다."
    cd "$CLONE_DIR"
    git pull origin main
elif [ -d "$CLONE_DIR" ]; then
    echo "디렉토리가 존재하지만 Git 저장소가 아닙니다: $CLONE_DIR"
    echo "디렉토리를 삭제하고 저장소를 다시 클론합니다."
    rm -rf "$CLONE_DIR"
    echo "저장소를 클론합니다: $REPO_URL"
    git clone "$REPO_URL" "$CLONE_DIR"
else
    echo "저장소를 클론합니다: $REPO_URL"
    git clone "$REPO_URL" "$CLONE_DIR"
fi

# ----------------------------------------
# 3. config.yml 생성
# ----------------------------------------

echo "========================================"
echo "3. config.yml 생성"
echo "========================================"

CONFIG_DIR="$HOME/syu-DataAnalyze/TrafficGenerator"
mkdir -p "$CONFIG_DIR"

# config.yml 생성
cat <<EOF > "$CONFIG_DIR/config.yml"
# 공용 설정 파일: config.yaml

# Pub/Sub 설정
pubsub:
  endpoint: "$PUBSUB_ENDPOINT"
  domain_id: "$DOMAIN_ID"
  project_id: "$PROJECT_ID"
  topic_name: "$TOPIC_NAME"
  topic_name_mk: "$TOPIC_NAME_MK"
  topic_description: "$TOPIC_DESCRIPTION"
  topic_retention_duration: "$TOPIC_RETENTION_DURATION"
  sub_name: "$SUB_NAME"
  credential_id: "$CREDENTIAL_ID"
  credential_secret: "$CREDENTIAL_SECRET"


# Object Storage 서브스크립션 설정
object_storage_subscription:
  name: "$OBJECT_STORAGE_SUBSCRIPTION_NAME"
  bucket: "$OBJECT_STORAGE_BUCKET"
  export_interval_min: $EXPORT_INTERVAL_MIN
  file_prefix: "$FILE_PREFIX"
  file_suffix: "$FILE_SUFFIX"
  channel_count: $CHANNEL_COUNT
  max_channel_count: $MAX_CHANNEL_COUNT
  is_export_enabled: $IS_EXPORT_ENABLED

# 로그 설정
logging:
  filename: "$LOG_FILENAME"
  level: "$LOG_LEVEL"

# 스레드 및 사용자 설정
threads:
  num_users: $NUM_USERS
  max_threads: $MAX_THREADS
  actions_per_user: $ACTIONS_PER_USER

# API 서버 정보
api:
  base_url: "$API_BASE_URL"
  endpoints:
    add_user: "add_user"
    delete_user: "delete_user"
    login: "login"
    logout: "logout"
    products: "products"
    product_detail: "product"
    search: "search"
    checkout_history: "checkout_history"
    categories: "categories"
    category: "category"
    cart_view: "cart/view"
    cart_add: "cart/add"
    cart_remove: "cart/remove"
    checkout: "checkout"
    add_review: "add_review"
    error_page: "error"
  time_sleep_range:
    min: 0.1
    max: 1.0

# 나이 구간 임계값
age_threshold:
  young: 25
  middle: 50
EOF

echo "config.yml 생성 완료."

# ----------------------------------------
# 4. setup_all.sh 실행
# ----------------------------------------

echo "========================================"
echo "4. setup_all.sh 실행"
echo "========================================"

SETUP_ALL_SCRIPT="$CLONE_DIR/TrafficGenerator/setup_all.sh"

if [ -f "$SETUP_ALL_SCRIPT" ]; then
    echo "setup_all.sh를 실행합니다."
    chmod +x "$SETUP_ALL_SCRIPT"
    sudo -E "$SETUP_ALL_SCRIPT"
else
    echo "setup_all.sh 스크립트를 찾을 수 없습니다: $SETUP_ALL_SCRIPT"
    exit 1
fi

# ----------------------------------------
# 5. 완료 메시지
# ----------------------------------------

echo "========================================"
echo "자동화 스크립트 실행이 완료되었습니다."
echo "Go SDK와 REST API 설정이 모두 완료되었습니다."
echo "필요 시, Python 스크립트를 수동으로 실행하세요."
echo "예:"
echo "  cd ~/syu-DataAnalyze/TrafficGenerator/REST\\ API/VM1 && python3 pub_sub_send.py"
echo "  cd ~/syu-DataAnalyze/TrafficGenerator/REST\\ API/VM1 && python3 traffic_generator.py"
echo "  cd ~/syu-DataAnalyze/TrafficGenerator/REST\\ API/VM2 && python3 restapi_sub.py"
echo "========================================"
