카프카 설치
```
sudo apt update
sudo apt install -y openjdk-21-jdk
java -version

wget https://archive.apache.org/dist/kafka/3.7.1/kafka_2.13-3.7.1.tgz
tar -xzf kafka_2.13-3.7.1.tgz
cd kafka_2.13-3.7.1

```

파이썬 환경 준비
```
sudo apt update
sudo apt install -y python3 python3-pip
pip3 install kafka-python
```

kafka 클라이언트 클러스와의 네트워크 통신 확인
```
nc -zv 10.0.3.248 9092 #부트스트랩 주소1 (kakaocloud 클러스터 참고)
nc -zv 10.0.2.112 9092 #부트스트랩 주소2 (kakaocloud 클러스터 참고)
```

환경 변수 설정
```

echo export KAFKA_BOOTSTRAP_SERVERS="{부트스트랩 주소}" >> ~/.bashrc
echo export KAFKA_CONSOL_TOPIC="kafka-consol" >> ~/.bashrc

source ~/.bashrc

```

# 콘솔 스크립트(바이너리)로 메시지 프로듀싱/컨슈밍 실습
토픽 생성
```
cd kafka_2.13-3.7.1
bin/kafka-topics.sh --bootstrap-server ${KAFKA_BOOTSTRAP_SERVERS} --create --topic ${TOPIC_NAME} --partitions 1 --replication-factor 2

프로듀서 실행
```
bin/kafka-console-producer.sh --broker-list ${KAFKA_BOOTSTRAP_SERVERS} --topic ${TOPIC_NAME}
```



