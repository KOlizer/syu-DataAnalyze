#!/bin/bash

# setup_all.sh
# 이 스크립트는 Go SDK와 REST API 환경을 자동으로 설정합니다.

# 스크립트 실행 중 에러 발생 시 즉시 종료
set -e

# ----------------------------------------
# 1. Go SDK 설정
# ----------------------------------------

echo "========================================"
echo "1. Go SDK 설치 및 설정 시작"
echo "========================================"

# 시스템 패키지 목록 업데이트
echo "시스템 패키지 목록을 업데이트합니다."
sudo apt update

# Go 1.20.5 다운로드 및 설치
GO_VERSION="1.20.5"
GO_TAR_FILE="go${GO_VERSION}.linux-amd64.tar.gz"
GO_DOWNLOAD_URL="https://go.dev/dl/${GO_TAR_FILE}"

echo "Go ${GO_VERSION}를 다운로드하고 설치합니다."
wget "$GO_DOWNLOAD_URL"

# 기존 Go 설치 디렉토리 제거
echo "기존 Go 설치 디렉토리를 제거합니다."
sudo rm -rf /usr/local/go

# Go 설치
echo "Go를 /usr/local 디렉토리에 설치합니다."
sudo tar -C /usr/local -xzf "$GO_TAR_FILE"

# Go 설치 후 PATH를 즉시 업데이트
export PATH=$PATH:/usr/local/go/bin
echo "PATH를 업데이트했습니다: $PATH"


# Go 설치 확인
echo "Go 버전을 확인합니다."
go version

# PATH 설정을 .bashrc에 추가 (추가적으로 영구적으로 적용)
if ! grep -q 'export PATH=\$PATH:/usr/local/go/bin' ~/.bashrc; then
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    echo ".bashrc에 PATH를 추가했습니다."
fi

# 환경 변수 설정: GOPATH와 GOCACHE를 사용자 디렉토리로 설정
export GOPATH="$HOME/go"
export GOCACHE="$HOME/.cache/go-build"
echo "GOPATH와 GOCACHE를 설정했습니다: GOPATH=$GOPATH, GOCACHE=$GOCACHE"

# .bashrc에 GOPATH와 GOCACHE 추가 (영구적으로 적용)
if ! grep -q 'export GOPATH=' ~/.bashrc; then
    echo "export GOPATH=$GOPATH" >> ~/.bashrc
fi

if ! grep -q 'export GOCACHE=' ~/.bashrc; then
    echo "export GOCACHE=$GOCACHE" >> ~/.bashrc
fi

# gosdk 디렉토리 생성 및 이동
GOSDK_DIR="$HOME/gosdk"
echo "'gosdk' 디렉토리를 생성하고 이동합니다: $GOSDK_DIR"
mkdir -p "$GOSDK_DIR" && cd "$GOSDK_DIR"

# Pub/Sub SDK 다운로드 및 압축 해제
PUBSUB_SDK_URL="https://objectstorage.kr-central-2.kakaocloud.com/v1/e9130193fc734337b2b0c1da50e44395/pubsub-sdk/go/v1.0.0/pubsub.tgz"
PUBSUB_TGZ="pubsub.tgz"

echo "Pub/Sub SDK를 다운로드하고 압축을 풉니다."
wget "$PUBSUB_SDK_URL" -O "$PUBSUB_TGZ"
tar -xf "$PUBSUB_TGZ"
rm "$PUBSUB_TGZ"
echo "Pub/Sub SDK 다운로드 및 압축 해제 완료."

# Go 모듈 초기화 (이미 초기화된 경우 건너뜀)
echo "Go 모듈을 초기화합니다."
go mod init trafficgenerator-go-sdk || echo "Go 모듈이 이미 초기화되어 있습니다."

# Pub/Sub SDK 의존성 추가 및 로컬 경로로 교체
echo "Pub/Sub SDK 의존성을 추가하고 로컬 경로로 교체합니다."
go mod edit -require github.kakaoenterprise.in/cloud-platform/kc-pub-sub-sdk-go@v1.0.0
go mod edit -replace github.kakaoenterprise.in/cloud-platform/kc-pub-sub-sdk-go@v1.0.0=$GOSDK_DIR

# 의존성 정리
echo "Go 모듈 의존성을 정리합니다."
go mod tidy

# cmd 디렉토리 생성 및 이동
CMD_DIR="$GOSDK_DIR/cmd"
echo "'cmd' 디렉토리를 생성하고 이동합니다: $CMD_DIR"
mkdir -p "$CMD_DIR" && cd "$CMD_DIR"

# 필요한 Go 파일 다운로드
echo "필요한 Go 파일(config.go, publisher.go, subscriber.go)을 다운로드합니다."
wget -O config.go https://raw.githubusercontent.com/KOlizer/syu-DataAnalyze/main/TrafficGenerator/GO_SDK/config.go
wget -O publisher.go https://raw.githubusercontent.com/KOlizer/syu-DataAnalyze/main/TrafficGenerator/GO_SDK/publisher.go
wget -O subscriber.go https://raw.githubusercontent.com/KOlizer/syu-DataAnalyze/main/TrafficGenerator/GO_SDK/subscriber.go

echo "Go 파일 다운로드 완료."

# Go 패키지 설치 및 의존성 정리
echo "Go 패키지 (gopkg.in/yaml.v2)를 설치하고 의존성을 정리합니다."
go get gopkg.in/yaml.v2
go mod tidy

echo "gosdk 및 cmd 디렉토리의 소유권을 ubuntu로 변경합니다."
sudo chown -R ubuntu:ubuntu "$GOSDK_DIR"
sudo chown -R ubuntu:ubuntu "$CMD_DIR"

# Go 모듈 캐시와 빌드 캐시도 소유권 변경
sudo chown -R ubuntu:ubuntu /home/ubuntu/go
sudo chown -R ubuntu:ubuntu /home/ubuntu/.cache/go-build

echo "Go SDK 설정 완료."

# ----------------------------------------
# 2. REST API 설정
# ----------------------------------------

echo "========================================"
echo "2. REST API 설치 및 설정 시작"
echo "========================================"

# REST API 디렉토리 생성
REST_API_DIR="$HOME/syu-DataAnalyze/TrafficGenerator/REST API"
echo "REST API 디렉토리를 생성합니다: $REST_API_DIR"
mkdir -p "$REST_API_DIR/VM1" "$REST_API_DIR/VM2"

# Python3 및 pip3 설치
echo "Python3 및 pip3를 설치합니다."
sudo apt install -y python3 python3-pip

# 필요한 Python 패키지 설치
echo "Python 패키지 (requests, pyyaml)를 설치합니다."
pip3 install --user requests pyyaml

# VM1 Python 스크립트 다운로드
echo "VM1 Python 스크립트를 다운로드합니다."
cd "$REST_API_DIR/VM1"
wget -O pub_sub_send.py https://raw.githubusercontent.com/KOlizer/syu-DataAnalyze/main/TrafficGenerator/REST%20API/VM1/pub_sub_send.py
wget -O traffic_generator.py https://raw.githubusercontent.com/KOlizer/syu-DataAnalyze/main/TrafficGenerator/REST%20API/VM1/traffic_generator.py

# VM2 Python 스크립트 다운로드
echo "VM2 Python 스크립트를 다운로드합니다."
cd "$REST_API_DIR/VM2"
wget -O CreateSubscription.py https://raw.githubusercontent.com/KOlizer/syu-DataAnalyze/main/TrafficGenerator/REST%20API/VM2/CreateSubscription.py
wget -O CreateTopic.py https://raw.githubusercontent.com/KOlizer/syu-DataAnalyze/main/TrafficGenerator/REST%20API/VM2/CreateTopic.py
wget -O restapi_sub.py https://raw.githubusercontent.com/KOlizer/syu-DataAnalyze/main/TrafficGenerator/REST%20API/VM2/restapi_sub.py

# Python 스크립트 실행 권한 부여
echo "Python 스크립트에 실행 권한을 부여합니다."
chmod +x "$REST_API_DIR/VM1/"*.py "$REST_API_DIR/VM2/"*.py

echo "REST API 설정 완료."

# ----------------------------------------
# 3. 완료 메시지
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
