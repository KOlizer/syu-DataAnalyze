# 1. 사전 준비
- 콘솔로 자원 미리 구축
  - Traffice generator VM 2개
  - ALB
  - API Server VM 2개

# 카카오클라우드 콘솔
### 1.1 Test용 topic생성

- 이름: `test-topic`
- 기본서브스크립션: `생성 안함`
- 토픽 메세지 보존 기간: `0일 0시 10분`
- 인스턴스유형: `m2a.xlarge`
- 설명: `없음`

</br>

### 1.2 Data Catalog 실습용 topic 생성
- 이름: `datacatalog-topic`
- 기본서브스크립션: `생성 안함`
- 토픽 메세지 보존 기간: `0일 0시 10분`
- 인스턴스유형: `m2a.xlarge`
- 설명: `없음`

</br>

### 1.3 Test용 pull Subscription 생성

- 이름: `pull-subscription`
- 토픽선택: `test-topic`
- 유형: `PULL`
- 서브스크립션 메세지 보존 기간: `0일 0시 10분`
- 응답 대기 시간: `20초`

</br>


### 1.4 Test용 pull Subscription 생성
- 이름: `push-subscription`
- 토픽선택: `test-topic`
- 유형**: `PUSH`
- 프로토콜:`http://push-subscription`
- 엔드포인트URL:{API서버1 URL}
- 서브스크립션 메세지 보존 기간: `0일 0시 10분`
- 응답 대기 시간: `20초`

</br>
</br>

# Traffic Generator VM 2를 이용해 PUB/SUB 토픽, 서브스크립션 생성

  </br>
  </br>

  ## 1. VM2: PUB/SUB 토픽생성 

- 새로운 터미널에서 Traffic Generator 2 VM에 SSH 접속합니다.
  터미널에서 다음 명령어를 입력하여 `create_topic.py` 스크립트를 실행합니다.
  - 파일 경로로 이동 후 파이썬 파일 실행

```
python3 create_topic.py
```

- 실행후 카카오 클라우드 콘솔에서 확인

</br>
</br>
  
## 2. VM2: PUB/SUB 서브스크립션 생성 

- 터미널에서 다음 명령어를 입력하여 `create_subscription.py` 스크립트를 실행합니다.
  - 파일 경로로 이동 후 파이썬 파일 실행

```
python3 create_subscription.py
```

  </br>
  </br>

  
# REST API를 활용한 PUB/SUB 통신

이 가이드는 VM1과 VM2를 사용하여 PUB/SUB 통신을 설정하는 방법을 설명합니다.

</br>
</br>

## 1. VM1: PUB 메시지 전송

- 새로운 터미널에서 Traffic Generator 1 VM에 SSH 접속합니다.
  터미널에서 다음 명령어를 입력하여 `pub_sub_send.py` 스크립트를 실행합니다.
  - 파일 경로로 이동 후 파이썬 파일 실행

  ```
  python3 pub_sub_send.py
  ```
  
  - 정상 실행 시 출력 메시지
  스크립트가 정상적으로 실행되면 아래와 같은 메시지가 출력됩니다.
  ```
  "CLI 입력 -> Kakao Pub/Sub 전송 프로그램입니다."
  "아래에 전송하고 싶은 문자열을 입력하세요."
  "빈 줄, Ctrl+D, 혹은 'quit' 입력 시 전송을 마칩니다."
  ```
  </br>
  </br>
  
- 1-1. 카카오 콘솔에 접속하여 PUB/SUB 서브스크립션에 메세지 전송 확인
</br>
  </br>
  
 - [카카오클라우드 콘솔](https://console.kakaocloud.com/)에 접속하여 **VM1** 에서 입력한 메세지가 출력되는지 확인함
   
   </br>
  </br>
  
## 2. VM2: SUB 메시지 수신
- 파일 경로로 이동 후 파이썬 파일 실행
- 터미널에서 다음 명령어를 입력하여 restapi_sub.py 스크립트를 실행합니다.

  ```
  python3 restapi_pull_sub.py
  ```
  
  - 정상 실행 시 화면
  스크립트가 정상적으로 실행되면 VM2에서 지속적으로 메시지를 받아옵니다.

  </br>
  </br>

  
- 이후 카카오 콘솔에서 publish된 메세지 확인


</br>
  </br>
  </br>
  </br>

# GO 실습

## 1. VM1: 메시지 publish
  
```
cd /home/ubuntu/gosdk/cmd
go build -o publisher config.go publisher.go
./publisher
```

</br>
</br>
  
- 카카오 콘솔에 접속하여 PUB/SUB 서브스크립션에 메세지 전송 확인
</br>
</br>

## 2. VM1: 메시지 publish

```
cd /home/ubuntu/gosdk/cmd
go build -o subscriber config.go subscriber.go
./subscriber
```
</br>
</br>
   
- 이후 카카오 콘솔에서 publish된 메세지 확인

</br>
</br>
  
# Push Subscription 실습
- 위에서 전달한 메시지들이 Web의 특정 endpoint로 push 방식으로 전달되어 API 서버에는 데이터가 쌓는 것 확인하는 실습
- 웹을 통해 확인
```
http://{ALB의 IP주소}/push-messages
```

# filebeat, Logstash를 활용한 nginx 로그 수집 실습
