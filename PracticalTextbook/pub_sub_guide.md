# 1. 사전 준비
- 콘솔로 자원 미리 구축
  - Pub/Sub topic
  - MySQL
  - Object Storage
  - API Server VM 2개
  - ALB
  - Pub/Sub pull,push subscription
  - Traffice generator VM 2개

---

##Pub/Sub 가이드
###이 가이드는 Pub/Sub 기능을 활용한 메시지 송수신, 트래픽 로그 생성, Go SDK 실습, 그리고 NGINX 로그를 Object Storage에 적재하는 전체 과정을 설명합니다.
- 환경 구성:
  - Traffic Generator VM 1 & 2: Public IP 연결 및 SSH 접속
  - API Server 1 & 2: NGINX, Logstash, Filebeat 실행

### 1. 기본 환경 설정
###VM 접속

Traffic Generator VM 1, 2에 public IP를 통해 연결합니다.
각 VM에 SSH로 접속합니다.
디렉토리 이동

VM1 (REST API for VM1):
bash
복사
cd syu-DataAnalyze/TrafficGenerator/REST_API/VM1
VM2 (REST API for VM2):
bash
복사
cd syu-DataAnalyze/TrafficGenerator/REST_API/VM2
2. Topic 및 Subscription 생성
VM2에서 실행

토픽 생성:

bash
복사
python3 CreateTopic.py
Pub/Sub 콘솔에서 토픽 생성 여부를 확인할 수 있습니다.

Subscription 생성:

bash
복사
python3 CreateSubscription.py
3. 메시지 송수신 테스트
A. Pub/Sub send/receive 스크립트 실행
VM1 (Publisher):
bash
복사
python3 pub_sub_send.py
VM2 (Subscriber):
bash
복사
python3 restapi_sub.py
B. 메시지 전송
VM1에서:

터미널에 메시지를 입력 후 엔터를 누릅니다.
전송할 메시지를 모두 입력한 후, 마지막 엔터로 전송합니다.
VM2에서:

입력한 메시지가 수신되는지 확인합니다.
4. 웹 API로 메시지 확인
웹 브라우저에서 아래 URL에 접속합니다.
url
복사
http://{alb public ip 주소}/push-messages
여러 번 새로고침하여 메시지 적재 여부를 확인합니다.
종료: Ctrl + C
(Traceback 메시지가 뜨는 것은 정상입니다.)
5. Traffic Generator 실행
VM1에서:

트래픽 생성 스크립트 실행:
bash
복사
python3 traffic_generator.py
실행 완료 후, 생성된 로그 확인:
bash
복사
cat traffic_generator.log
6. Go SDK 실습
A. 작업 디렉토리 이동
홈 디렉토리로 이동:
bash
복사
cd
gosdk/cmd 디렉토리로 이동:
bash
복사
cd gosdk/cmd
B. Publisher 및 Subscriber 실행
VM1 (Publisher):
bash
복사
go build -o publisher config.go publisher.go
./publisher
VM2 (Subscriber):
bash
복사
go build -o subscriber config.go subscriber.go
./subscriber
확인: VM1에서 입력한 메시지가 VM2에서 정상적으로 수신되는지 확인합니다.

7. NGINX 로그를 Object Storage에 적재
A. API Server 접속 및 설정 파일 확인
API Server 1, 2에 SSH 접속 후:
bash
복사
cd /etc/logstash/conf.d
설정 파일 확인:
bash
복사
cat logs-to-pubsub.conf
필요 시 편집:
bash
복사
vi logs-to-pubsub.conf
B. 서비스 상태 확인
각 서비스를 아래 명령어로 확인합니다.

bash
복사
sudo systemctl status filebeat
sudo systemctl status logstash
sudo systemctl status nginx
C. Pub/Sub용 Object Storage 콘솔 확인
NGINX 로그가 Object Storage에 정상적으로 쌓이는지 Pub/Sub용 Object Storage 콘솔을 통해 확인합니다.
마
