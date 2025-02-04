#!/bin/bash
# setup_all.sh
set -e

echo "=== [Step 0] setup_all.sh 스크립트 시작 ==="

# 환경 변수 파일 소스 (setup_initial.sh에서 생성한 traffic_generator.env)
ENV_FILE="$HOME/traffic_generator.env"
if [ -f "$ENV_FILE" ]; then
    echo "=== [Step X] 환경 변수 파일($ENV_FILE) 소스 ==="
    source "$ENV_FILE"
else
    echo "경고: 환경 변수 파일($ENV_FILE)이 없습니다."
fi

# [Step 1] 네트워크 및 환경 준비를 위해 잠시 대기
echo "=== [Step 1] 네트워크 및 환경 준비를 위해 잠시 대기합니다..."
sleep 3

# [Step 2] USER_HOME 설정
USER_HOME="/home/ubuntu"
echo "=== [Step 2] USER_HOME 설정 시작 ==="
echo "USER_HOME: $USER_HOME"
echo "=== [Step 2] USER_HOME 설정 완료 ==="

# [Step 3] 환경 변수 적용 (.bashrc 소스 – 필요 시)
echo "=== [Step 3] 환경 변수 적용: /home/ubuntu/.bashrc 소스 시작 ==="
if [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc"
fi
echo "=== [Step 3] 환경 변수 적용 완료 ==="

# [Step 4] config.yml 파일 생성
echo "=== [Step 4] config.yml 파일 생성 시작 ==="
CONFIG_FILE="$USER_HOME/syu-DataAnalyze/TrafficGenerator/config.yml"
cat <<EOF > "$CONFIG_FILE"
# 공용 설정 파일: config.yml

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

object_storage_subscription:
  name: "$OBJECT_STORAGE_SUBSCRIPTION_NAME"
  bucket: "$OBJECT_STORAGE_BUCKET"
  export_interval_min: $EXPORT_INTERVAL_MIN
  file_prefix: "$FILE_PREFIX"
  file_suffix: "$FILE_SUFFIX"
  channel_count: $CHANNEL_COUNT
  max_channel_count: $MAX_CHANNEL_COUNT
  is_export_enabled: $IS_EXPORT_ENABLED

logging:
  filename: "$LOG_FILENAME"
  level: "$LOG_LEVEL"

threads:
  num_users: $NUM_USERS
  max_threads: $MAX_THREADS
  actions_per_user: $ACTIONS_PER_USER

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

age_threshold:
  young: 25
  middle: 50
EOF

echo "=== [Step 4] config.yml 생성 완료 ==="
echo "생성된 config.yml 내용:"
cat "$CONFIG_FILE"

# [Step 5] Go SDK 설치 및 설정
echo "=== [Step 5] Go SDK 설치 및 설정 시작 ==="
echo "Go 1.20.5 다운로드 중..."
GO_VERSION="1.20.5"
GO_TAR="go${GO_VERSION}.linux-amd64.tar.gz"
wget "https://go.dev/dl/$GO_TAR" -O "/tmp/$GO_TAR"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "/tmp/$GO_TAR"
rm "/tmp/$GO_TAR"
export PATH=$PATH:/usr/local/go/bin
echo "Go 설치 완료:"
go version
# 추가 Go SDK 설정(예: GOPATH 설정 등) 필요 시 여기에 추가할 수 있습니다.
echo "=== [Step 5] Go SDK 설정 완료 ==="

# [Step 6] REST API 설치 및 설정
echo "=== [Step 6] REST API 설치 및 설정 시작 ==="
sudo apt update
sudo apt install -y python3 python3-pip
pip3 install --user requests pyyaml

# VM1 Python 스크립트 다운로드
echo "=== [Step 6.1] VM1 Python 스크립트 다운로드 중... ==="
cd "$USER_HOME/syu-DataAnalyze/TrafficGenerator/REST API/VM1"
wget -O pub_sub_send.py "https://raw.githubusercontent.com/KOlizer/syu-DataAnalyze/main/TrafficGenerator/REST%20API/VM1/pub_sub_send.py"
wget -O traffic_generator.py "https://raw.githubusercontent.com/KOlizer/syu-DataAnalyze/main/TrafficGenerator/REST%20API/VM1/traffic_generator.py"

# VM2 Python 스크립트 다운로드
echo "=== [Step 6.2] VM2 Python 스크립트 다운로드 중... ==="
cd "$USER_HOME/syu-DataAnalyze/TrafficGenerator/REST API/VM2"
wget -O CreateSubscription.py "https://raw.githubusercontent.com/KOlizer/syu-DataAnalyze/main/TrafficGenerator/REST%20API/VM2/CreateSubscription.py"
wget -O CreateTopic.py "https://raw.githubusercontent.com/KOlizer/syu-DataAnalyze/main/TrafficGenerator/REST%20API/VM2/CreateTopic.py"
wget -O restapi_sub.py "https://raw.githubusercontent.com/KOlizer/syu-DataAnalyze/main/TrafficGenerator/REST%20API/VM2/restapi_sub.py"

echo "=== [Step 6] REST API 설정 완료 ==="

# [Step 7] REST API 관련 디렉토리 소유권 및 쓰기 권한 수정
echo "=== [Step 7] REST API 관련 디렉토리 소유권/쓰기 권한 수정 시작 ==="
sudo chown -R ubuntu:ubuntu "$USER_HOME/syu-DataAnalyze/TrafficGenerator/REST API/VM1"
sudo chown -R ubuntu:ubuntu "$USER_HOME/syu-DataAnalyze/TrafficGenerator/REST API/VM2"
chmod -R u+w "$USER_HOME/syu-DataAnalyze/TrafficGenerator/REST API/VM1"
chmod -R u+w "$USER_HOME/syu-DataAnalyze/TrafficGenerator/REST API/VM2"
echo "=== [Step 7] 권한 수정 완료 ==="

# [Step 8] 환경 변수 재적용 (현재 셸)
echo "=== [Step 8] 환경 변수 재적용 (현재 셸) 시작 ==="
if [ "$EUID" -ne 0 ]; then
    source "$HOME/.bashrc"
else
    echo "현재 스크립트는 루트 권한으로 실행되었습니다."
    echo "일반 사용자(ubuntu)로 재로그인하거나 다음 명령어를 실행하여 환경 변수가 적용되도록 하세요:"
    echo "source $HOME/.bashrc"
fi
echo "=== [Step 8] 환경 변수 재적용 완료 ==="

# [Step 9] 완료 메시지 출력
echo "========================================"
echo "=== [Step 9] 자동화 스크립트 실행 완료 ==="
echo "Go SDK 및 REST API 설정이 완료되었습니다."
echo "========================================"
