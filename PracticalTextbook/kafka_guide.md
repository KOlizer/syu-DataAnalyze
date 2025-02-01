### **1.3 각 VM에 Kafka 클라이언트(바이너리) 설치**

1. **Java 설치**
    
    ```bash
    sudo apt update
    sudo apt install -y openjdk-21-jdk
    java -version
    ```
    
2. **Kafka 바이너리 다운로드 및 설치**
    
    ```bash
    cd /opt
    sudo wget https://archive.apache.org/dist/kafka/3.7.1/kafka_2.13-3.7.1.tgz
    sudo tar -xzf kafka_2.13-3.7.1.tgz
    sudo mv kafka_2.13-3.7.1 kafka
    sudo rm kafka_2.13-3.7.1.tgz
    ```
    
3. **환경 변수 설정**
    
    ```bash
    echo 'export KAFKA_HOME=/opt/kafka' >> ~/.bashrc
    echo 'export PATH=$PATH:$KAFKA_HOME/bin' >> ~/.bashrc
    source ~/.bashrc
    ```
### **1.4 Python 환경 준비**

1. **Python 설치**
    
    ```bash
    sudo apt update
    sudo apt install -y python3 python3-pip
    python3 --version
    pip3 --version
    ```
    
2. **가상 환경 생성**
    
    ```bash
    sudo apt update
    sudo apt install -y python3-venv
    python3 -m venv ~/kafka_env
    ```
    
3. **가상 환경 활성화**
    
    ```bash
    source ~/kafka_env/bin/activate
    ```
    
4. Kafka Python 라이브러리 설치 + 누락된 vendor 폴더 수동 패치
아래처럼 kafka-python 설치 후, kafka.vendor.six 폴더를 직접 만들어 복사
    
    ```bash
    # (1) kafka-python 설치
    pip install kafka-python==2.0.2
    
    # (2) six 업그레이드
    pip install --upgrade six
    
    # (3) site-packages로 이동
    cd ~/kafka_env/lib/python3.12/site-packages/kafka
    
    # (4) vendor 폴더(및 하위 six 폴더) 수동 생성
    mkdir -p vendor/six
    
    # (5) 시스템에 설치된 six.py를 복사해 __init__.py로 둠
    cp ~/kafka_env/lib/python3.12/site-packages/six.py vendor/six/__init__.py
    ```
    

### **1.5 Kafka 클러스터와 통신 확인**

1. **네트워크 통신 가능 여부 체크(각 클러스터의 부트스트랩 서버)**
    
    ```bash
    nc -zv 172.16.2.139 9092
    nc -zv 172.16.2.180 9092
    ```
    
    - 실패 시 네트워크 및 보안 그룹 설정을 확인합니다.
---

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

---
# kafka → kafka connector → object storage 실습
## Object Storage 준비(사전 준비)

Confluent Hub Client 설치
```
cd /
sudo mkdir /confluent-hub
cd /confluent-hub
sudo curl -LO http://client.hub.confluent.io/confluent-hub-client-latest.tar.gz
sudo tar -zxvf /confluent-hub/confluent-hub-client-latest.tar.gz
sudo mkdir /confluent-hub/plugins
```

환경 변수 설정 
```
echo export CONFLUENT_HOME='/confluent-hub' >> ~/.bashrc
echo export PATH="$PATH:$CONFLUENT_HOME/bin" >> ~/.bashrc
echo export JAVA_HOME='/usr/lib/jvm/java-21-openjdk-amd64' >> ~/.bashrc
echo export PATH="$JAVA_HOME/bin:$PATH" >> ~/.bashrc
source ~/.bashrc
```

API 인증 토큰 발급
```
export API_TOKEN=$(curl -s -X POST -i https://iam.kakaocloud.com/identity/v3/auth/tokens -H "Content-Type: application/json" -d \
'{
    "auth": {
        "identity": {
            "methods": [
                "application_credential"
            ],
            "application_credential": {
                "id": "{액세스 키}",
                "secret": "{시크릿 키}"
            }
        }
    }
}' | grep x-subject-token | awk -v RS='\r\n' '{print $2}')
```

환경 변수로 토큰 지정
```
echo "export API_TOKEN=${API_TOKEN}" >> ~/.bashrc
source ~/.bashrc

```

토큰 확인
```
echo $API_TOKEN
```

발급받은 API 토큰을 사용하여 임시 자격 증명을 요청
```
echo $(curl -s -X POST -i https://iam.kakaocloud.com/identity/v3/users/{사용자 고유 ID}/credentials/OS-EC2 \
 -H "Content-Type: application/json" \
 -H "X-Auth-Token: ${API_TOKEN}" -d \
 '{
     "tenant_id": "{프로젝트 ID}"
 }')
```

환경 변수에 AWS 자격 증명 추가
```
  echo export AWS_ACCESS_KEY_ID="{발급받은 S3_ACCESS_KEY}" >> ~/.bashrc
  echo export AWS_SECRET_ACCESS_KEY="{발급받은 S3_SECRET_ACCESS_KEY}" >> ~/.bashrc
  source ~/.bashrc
```

## S3 Sink Connector 설치
권한 변경
```
sudo chown ubuntu:ubuntu /confluent-hub/plugins
```

Confluent Hub로 S3 Sink Connector 설치
```
/confluent-hub/bin/confluent-hub install confluentinc/kafka-connect-s3:latest \
  --component-dir /confluent-hub/plugins \
  --worker-configs /home/ubuntu/kafka_2.13-3.7.1/config/connect-standalone.properties
```

AWS CLI 설치 및 설정
```
cd /home/ubuntu
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.22.0.zip" -o "awscliv2.zip"

unzip /home/ubuntu/awscliv2.zip
sudo /home/ubuntu/aws/install
aws --version
```

AWS CLI 구성
```
aws configure
```
- AWS Access Key ID: {위에서 추가한 `AWS_ACCESS_KEY_ID`}
- AWS Secret Access Key: {위에서 추가한 `AWS_SECRET_ACCESS_KEY`}
- Default region name: kr-central-2
- Default output format: json


Bucket ACL(쓰기 권한 부여)
```
aws s3api put-bucket-acl \
  --bucket {버킷 이름} \
  --grant-write 'uri="http://acs.amazonaws.com/groups/global/AllUsers"' \
  --endpoint-url https://objectstorage.kr-central-2.kakaocloud.com
```









