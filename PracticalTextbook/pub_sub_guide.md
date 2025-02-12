1. 사전 준비
- 콘솔로 자원 미리 구축
  - Pub/Sub topic
  - MySQL
  - Object Storage
  - API Server VM 2개
  - ALB
  - Pub/Sub pull,push subscription
  - Traffice generator VM 2개

---

# Pub/Sub 가이드

Pub/Sub을 활용한 메시지 송수신, 트래픽 로그 생성, REST API 실습, Go SDK 실습, 그리고 NGINX 로그를 Object Storage에 적재합니다.

---

## 1. 기본 환경 설정

1. **VM 접속**
    - Traffic Generator 1, 2 VM에 SSH로 접속합니다.
      ```bash
      ssh -i {keypair}.pem ubuntu@{vm public ip}
      ```
      
2. **디렉터리 내부 파일 목록 확인**
    - **Traffic-Generator-VM1**
        
        ```bash
        cd /home/ubuntu/syu-DataAnalyze/TrafficGenerator/REST_API/VM1
        ls -l
        ```
        
    - **Traffic-Generator-VM2**
        
        ```bash
        cd /home/ubuntu/syu-DataAnalyze/TrafficGenerator/REST_API/VM2
        ls -l
        ```


- **파일 생성이 안 되었을 시 아래 명령어 실행**
  - **Traffic-Generator-VM1,2 모두 실행**
  ```bash
  wget -nc -P /home/ubuntu/syu-DataAnalyze/TrafficGenerator/REST_API \
    https://github.com/kakaocloud-edu/tutorial/raw/refs/heads/main/DataAnalyzeCourse/src/TrafficGenerator/REST_API/config.py
  ```

  - **Traffic-Generator-VM1에서 실행**
  ```bash
  wget -nc -P /home/ubuntu/syu-DataAnalyze/TrafficGenerator/REST_API/VM1 \
    https://github.com/kakaocloud-edu/tutorial/raw/refs/heads/main/DataAnalyzeCourse/src/TrafficGenerator/REST_API/VM1/pub_sub_send.py \
    https://github.com/kakaocloud-edu/tutorial/raw/refs/heads/main/DataAnalyzeCourse/src/TrafficGenerator/REST_API/VM1/traffic_generator.py
  ```

  - **Traffic-Generator-VM2에서 실행**
  ```bash
  wget -nc -P /home/ubuntu/syu-DataAnalyze/TrafficGenerator/REST_API/VM2 \
    https://github.com/kakaocloud-edu/tutorial/raw/refs/heads/main/DataAnalyzeCourse/src/TrafficGenerator/REST_API/VM2/create_subscription.py \
    https://github.com/kakaocloud-edu/tutorial/raw/refs/heads/main/DataAnalyzeCourse/src/TrafficGenerator/REST_API/VM2/create_topic.py \
    https://github.com/kakaocloud-edu/tutorial/raw/refs/heads/main/DataAnalyzeCourse/src/TrafficGenerator/REST_API/VM2/restapi_pull_sub.py
  ```
---

## 2. Pub/Sub Topic 및 Subscription 생성

**Traffic-Generator-VM2에서 실행**

1. **create_topic.py 파일을 실행하여 토픽 생성**
    
    ```bash
    python3 create_topic.py
    ```

2. **카카오클라우드 콘솔 > Analytics > Pub/Sub > 토픽 메뉴 클릭**
3. **`log-topic` 토픽 생성 확인**
4. **create_subscription.py 파일을 실행하여 Subscription 생성**
    
    ```bash
    python3 create_subscription.py
    ```
5. **카카오클라우드 콘솔 > Analytics > Pub/Sub > 서브스크립션 메뉴 클릭**
6. **`obj-subscription` 서브스크립션 생성 확인**
    

---

## 3. REST API를 활용한 메시지 송수신

1. **Traffic-Generator-VM1 (Publisher)에서 아래 명령어를 입력하여 Pub/Sub 메세지 송신용 스크립트 실행**
    
    ```bash
    python3 pub_sub_send.py
    ```
2. **Traffic-Generator-VM1 터미널 창에 전송하고 싶은 메세지 입력 후 키보드의 `Enter`, `Ctrl+D` 키를 눌러 메세지 송신**
3. **Traffic-Generator-VM2 (Subscriber)에서 아래 명령어를 입력하여 Pub/Sub 메세지 수신용 스크립트 실행**
    
    ```bash
    python3 restapi_pull_sub.py
    ```
4. **Traffic-Generator-VM2 터미널에서 Traffic-Generator-VM1에서 입력한 메세지 수신 확인**
5. **웹 브라우저에서 아래 URL에 접속합니다.**
    
    ```
    http://{alb public ip 주소}/push-messages
    ```
    
6. 여러 번 새로고침하여 메시지 적재 여부를 확인합니다.
  - note (메세지 받은 부분이 뜨지 않을 경우, 전송 중이라 그런 것이므로 잠시 기다렸다가 확인)
  - **종료:** `Ctrl + C`
    - (Traceback 메시지가 뜨는 것은 정상입니다.)

---

## 4. Traffic Generator를 활용한 트래픽 생성

**Traffic-Generator-VM1에서 아래 명령어 실행**

1. 트래픽 생성 스크립트 실행
    
    ```bash
    python3 traffic_generator.py
    ```
    
2. 실행 완료 후, 생성된 로그 확인
    
    ```bash
    cat traffic_generator.log
    ```
    

---

## 5. Go SDK를 활용한 메시지 송수신

1. 작업 디렉토리 이동(VM1, 2)
```bash
cd /home/ubuntu/gosdk/cmd
```
    

2. Publisher 및 Subscriber 실행

- **Traffic-Generator-VM1 (Publisher)**
    
    ```bash
    go build -o publisher config.go publisher.go
    ```
    ```bash
    ./publisher
    ```
    
- **Traffic-Generator-VM2 (Subscriber)**
    
    ```bash
    go build -o subscriber config.go subscriber.go
    ```
    ```bash
    ./subscriber
    ```
    

> 확인: VM1에서 입력한 메시지가 VM2에서 정상적으로 수신되는지 확인합니다.
> 

---

## 6. Object Storage에 NGINX 로그 적재

### API Public ip를 이용하여 접속 후 로그 생성

- 웹 브라우저 주소창에 http://{api server public ip}를 입력하여 접속 후 웹 페이지 내용 클릭하여 로그 생성


### Pub/Sub용 Object Storage 콘솔 확인

- NGINX 로그가 Object Storage에 정상적으로 쌓이는지 Pub/Sub용 Object Storage 콘솔을 통해 확인합니다.




### API Server 접속 및 설정 파일 확인(Object Storage에 적재 안될 시 확인)

1. **API Server 1, 2에 SSH 접속**
    
    ```bash
    cd /etc/logstash/conf.d
    ```
    
2. 설정 파일 확인
    
    ```bash
    cat logs-to-pubsub.conf
    ```
    
3. 설정 파일 편집(필요시)
    
    ```bash
    vi logs-to-pubsub.conf
    ```
    
4. 편집 후 저장 및 나가기(필요시)

```jsx
Esc  :wq
```

### 서비스 상태 확인

각 서비스를 아래 명령어로 확인합니다.

```bash
sudo systemctl status filebeat
sudo systemctl status logstash
sudo systemctl status nginx
```
