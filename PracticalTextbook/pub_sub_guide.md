
## PUB/SUB TOPIC 콘솔에서 생성
</br>
  
## 1. 사전 준비
## 카카오클라우드 콘솔
## 1.1 Test용 topic, Data Catalog 실습용 topic 생성

- **이름**: `TestTopic`
- **기본서브스크립션**: `생성 안함`
- **토픽 메세지 보존 기간**: `0일 0시 10분`
- **인스턴스유형**: `m2a.xlarge`
- **설명**: `없음`
--------------------------------------------------
- **이름**: `DataCatalogTopic`
- **기본서브스크립션**: `생성 안함`
- **토픽 메세지 보존 기간**: `0일 0시 10분`
- **인스턴스유형**: `m2a.xlarge`
- **설명**: `없음`

</br>
</br>

## 1.2 Test용 topic Subscription 생성

- **이름**: `TestTopic-pull`
- **토픽선택**: `TestTopic`
- **유형**: `PULL`
- **서브스크립션 메세지 보존 기간**: `0일 0시 10분`
- **응답 대기 시간**: `20초`
------------------------------------------------------
- **이름**: `TestTopic-push`
- **토픽선택**: `TestTopic`
- **유형**: `PUSH`
- **프로토콜**:`http://`
- **엔드포인트URL**:{API서버1 URL}
- **서브스크립션 메세지 보존 기간**: `0일 0시 10분`
- **응답 대기 시간**: `20초`

</br>
</br>
</br>
</br>

# Traffic Generator VM 2를 이용해 PUB/SUB 토픽, 서브스크립션 생성

  </br>
  </br>

  ## 1. VM2: PUB/SUB 토픽생성 

- **스크립트 실행**  
  터미널에서 다음 명령어를 입력하여 `CreateTopic.py` 스크립트를 실행합니다.

```
python3 CreateTopic.py
```
**실행후 카카오 클라우드 콘솔에서 확인**

</br>
  </br>
  
## 2. VM2: PUB/SUB 서브스크립션 생성 

- **스크립트 실행**  
  터미널에서 다음 명령어를 입력하여 `CreateSubscription.py` 스크립트를 실행합니다.

```
python3 CreateSubscription.py
```

  </br>
  </br>
  </br>
  </br>
  
# Traffic Generator VM 1,2를 이용해 PUB/SUB 통신하기

이 가이드는 VM1과 VM2를 사용하여 PUB/SUB 통신을 설정하는 방법을 설명합니다.

</br>
</br>

## 1. VM1: PUB 메시지 전송

- **스크립트 실행**  
  터미널에서 다음 명령어를 입력하여 `pub_sub_send.py` 스크립트를 실행합니다.

  ```
  python3 pub_sub_send.py
  ```
- **정상 실행 시 출력 메시지**
  스크립트가 정상적으로 실행되면 아래와 같은 메시지가 출력됩니다.
  ```
  "CLI 입력 -> Kakao Pub/Sub 전송 프로그램입니다."
  "아래에 전송하고 싶은 문자열을 입력하세요."
  "빈 줄, Ctrl+D, 혹은 'quit' 입력 시 전송을 마칩니다."
  ```
  </br>
  </br>
## 1-1. 카카오 콘솔에 접속하여 PUB/SUB 서브스크립션에 메세지 전송 확인
</br>
  </br>
  
 - [카카오클라우드 콘솔](https://console.kakaocloud.com/)에 접속하여 **VM1** 에서 입력한 메세지가 출력되는지 확인함
   
   </br>
  </br>
  
## 2. VM2: SUB 메시지 수신
- **스크립트 실행**
  터미널에서 다음 명령어를 입력하여 restapi_sub.py 스크립트를 실행합니다.

  ```
  python3 restapi_sub.py
  ```
  **정상 실행 시 동작**
  스크립트가 정상적으로 실행되면 VM2에서 지속적으로 메시지를 받아옵니다.

  </br>
  </br>
  </br>
  </br>
  
**이후 카카오 콘솔에서 publish된 메세지 확인** 


</br>
  </br>
  </br>
  </br>

# GO 실습

</br>
  </br>
  
- publisher.go 실습
```
cd /home/ubuntu/gosdk/cmd
go build -o publisher config.go publisher.go
./publisher
```

</br>
  </br>
  
- subscriber.go 실습
```
cd /home/ubuntu/gosdk/cmd
go build -o subscriber config.go subscriber.go
./subscriber
```

</br>
  </br>
  </br>
  </br>
  
**이후 카카오 콘솔에서 publish된 메세지 확인** 

</br>
  </br>
  
## API 서버에서 PUB/SUB PUSH 서브스크립션 확인
  </br>
  </br>

**{API서버1 vm 퍼블릭 IP}/push-subscription 으로 push 된 메세지들 저장**
   </br>
 **{API서버1 vm 퍼블릭 IP}/push-messages 메세지 보기**
  
  </br>
  </br>
  
**이전 VM2 에서 받아진 메세지들이 오면 정상!**

</br>
  </br>
  
## API 서버에서 logstash로 보내진 PUB/SUB 확인
</br>
  </br>
  
- **카카오 콘솔에 접속**
- **Nginx 로그 수집용 버킷 (Pub/Sub 연동):Pub/Sub-nginx-log 확인**

  
