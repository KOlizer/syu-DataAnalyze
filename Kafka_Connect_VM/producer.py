#!/usr/bin/env python3
import os
import json
import time
from kafka import KafkaProducer

# 환경 변수에서 Kafka 부트스트랩 서버 정보를 가져옴
bootstrap_servers = os.environ.get("KAFKA_BOOTSTRAP_SERVERS")
if not bootstrap_servers:
    raise Exception("환경 변수 KAFKA_BOOTSTRAP_SERVERS가 설정되어 있지 않습니다.")

# 부트스트랩 서버가 쉼표(,)로 구분되어 여러 개 있을 경우 리스트로 변환
bootstrap_servers_list = [server.strip() for server in bootstrap_servers.split(",")]

producer = KafkaProducer(
    bootstrap_servers=bootstrap_servers_list,
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

topic = 'python-topic'

for i in range(5):
    message = {'message_number': i + 1, 'content': f'Message {i + 1}'}
    producer.send(topic, message)
    print(f"Sent: {message}")
    time.sleep(1)

producer.flush()
producer.close()
