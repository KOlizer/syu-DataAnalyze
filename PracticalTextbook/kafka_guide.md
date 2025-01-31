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
echo export KAFKA_CONSOL_TOPIC="kafka_consol" >> ~/.bashrc
echo export KAFKA_PYTHON_TOPIC="kafka-python" >> ~/.bashrc
echo export KAFKA_NGINX_TOPIC="kafka_nginx" >> ~/.bashrc
source ~/.bashrc

```

# 콘솔 스크립트(바이너리)로 메시지 프로듀싱/컨슈밍 실습
토픽 생성
```
cd kafka_2.13-3.7.1
bin/kafka-topics.sh --bootstrap-server ${KAFKA_BOOTSTRAP_SERVERS} --create --topic ${KAFKA_CONSOL_TOPIC} --partitions 1 --replication-factor 2
```

프로듀서 실행
```
bin/kafka-console-producer.sh --broker-list ${KAFKA_BOOTSTRAP_SERVERS} --topic ${KAFKA_CONSOL_TOPIC}
```

컨슈머 실행

earliest 설정:
```
bin/kafka-console-consumer.sh --bootstrap-server ${KAFKA_BOOTSTRAP_SERVERS} --topic ${KAFKA_CONSOL_TOPIC} --group consumer-group-earliest --from-beginning
```

latest 설정:
```
bin/kafka-console-consumer.sh --bootstrap-server ${KAFKA_BOOTSTRAP_SERVERS} --topic ${KAFKA_CONSOL_TOPIC} --group consumer-group-latest
```

# python 코드로 메시지 프로듀싱/컨슈밍 실습
python 토픽 생성
```
bin/kafka-topics.sh --bootstrap-server ${KAFKA_BOOTSTRAP_SERVERS} --create --topic ${KAFKA_PYTHON_TOPIC} --partitions 1 --replication-factor 2
```

producer.py실행(vm1)
```
wget -O producer.py "https://github.com/KOlizer/syu-DataAnalyze/raw/refs/heads/main/Kafka_Connect_VM/producer.py"
chmod +x producer.py
sudo ./producer.py
```

consumer.py실행(vm2)
```
wget -O consumer.py "https://github.com/KOlizer/syu-DataAnalyze/raw/refs/heads/main/Kafka_Connect_VM/consumer.py"
chmod +x consumer.py
sudo ./consumer.py
```

---
# nginx 로그 → kafka로 프로듀싱 실습 (logstash 활용)
콘솔 스크립트(바이너리)로 새로운 토픽 생성
```
bin/kafka-topics.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVERS --create --topic $KAFKA_NGINX_TOPIC --partitions 3 --replication-factor 2
```

api서버에서 logstash 설정
```
cd /etc/filebeat/conf.d
cat logs-to-kafka.conf
```

아래 코드와 동일한지 확인
```
input {
  beats {
    port => 5045
  }
}
filter {

}
output {
  # Kafka로 데이터 전송 (원본 메시지 사용)
  kafka {
    bootstrap_servers => "${LOGSTASH_KAFKA_ENDPOINT}"
    topic_id => "${TOPIC_NAME_KAFKA}"
    codec => json  # 데이터 형식에 맞게 조정하세요 (예: json, plain)
    # 필요에 따라 추가 Kafka 설정을 여기에 추가하세요
    # 예: security_protocol, sasl_mechanism 등
  }
}

```

Logstash 재실행 및 상태 확인
```
sudo systemctl restart logstash
sudo systemctl status logstash
```

TG에서 데이터 보내기
```
bin/kafka-console-consumer.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVERS --topic $KAFKA_NGINX_TOPIC --from-beginning
```


콘솔로 데이터가 쌓이고 있는지 체크






