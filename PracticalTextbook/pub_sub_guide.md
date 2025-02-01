# Traffic Generator Vm 1,2를 이용해 PUB/SUB 통신하기 
</br>
- 1. VM1을 이용해서 pub_sub_send.py을 실행

```
python3 pub_sub_send.p
```

- 정상적으로 작동시 해당 스크립트가 출력

  
```
    "CLI 입력 -> Kakao Pub/Sub 전송 프로그램입니다."
    "아래에 전송하고 싶은 문자열을 입력하세요."
    "빈 줄, Ctrl+D, 혹은 'quit' 입력 시 전송을 마칩니다."
```

- 2. VM2를 이용해서 restapi_sub.py를 실행

```
python3 restapi_sub.py
```

- 정상적으로 실행시에 VM2의 메세지를 지속적으로 받아옴




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
