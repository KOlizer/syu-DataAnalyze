# Traffic Generator VM 1,2를 이용해 PUB/SUB 통신하기

이 가이드는 VM1과 VM2를 사용하여 PUB/SUB 통신을 설정하는 방법을 설명합니다.

## 1. VM1: PUB 메시지 전송

- **스크립트 실행**  
  터미널에서 다음 명령어를 입력하여 `pub_sub_send.py` 스크립트를 실행합니다.

  ```
  python3 pub_sub_send.py
  ```
**정상 실행 시 출력 메시지**
스크립트가 정상적으로 실행되면 아래와 같은 메시지가 출력됩니다.
```
"CLI 입력 -> Kakao Pub/Sub 전송 프로그램입니다."
"아래에 전송하고 싶은 문자열을 입력하세요."
"빈 줄, Ctrl+D, 혹은 'quit' 입력 시 전송을 마칩니다."
```

## 2. VM2: SUB 메시지 수신
스크립트 실행
터미널에서 다음 명령어를 입력하여 restapi_sub.py 스크립트를 실행합니다.

```
python3 restapi_sub.py
```
**정상 실행 시 동작**
스크립트가 정상적으로 실행되면 VM2에서 지속적으로 메시지를 받아옵니다.


# Traffic Generator VM 2를 이용해 PUB/SUB 토픽, 서브스크립션 생성

## 1. VM2: PUB/SUB 토픽생성 

- **스크립트 실행**  
  터미널에서 다음 명령어를 입력하여 `CreateTopic.py` 스크립트를 실행합니다.

```
python3 CreateTopic.py
```

**실행후 카카오 클라우드 콘솔에서 확인**

## 2. VM2: PUB/SUB 서브스크립션 생성 

- **스크립트 실행**  
  터미널에서 다음 명령어를 입력하여 `CreateSubscription.py` 스크립트를 실행합니다.

```
python3 CreateSubscription.py
```


# GO 실습
- publisher.go 실습
```
cd /home/ubuntu/gosdk/cmd
go build -o publisher config.go publisher.go
./publisher
```

- subscriber.go 실습
```
cd /home/ubuntu/gosdk/cmd
go build -o subscriber config.go subscriber.go
./subscriber
```
