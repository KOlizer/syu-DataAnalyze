#!/usr/bin/env python3

import os
from kafka import KafkaConsumer

# 환경 변수 이름을 올바르게 사용합니다.
bootstrap_servers = os.environ.get('KAFKA_BOOTSTRAP_SERVERS')
if not bootstrap_servers:
    raise ValueError("환경 변수 'KAFKA_BOOTSTRAP_SERVERS'가 설정되어 있지 않습니다.")

# 쉼표로 구분된 문자열일 경우 리스트로 변환합니다.
bootstrap_servers_list = [server.strip() for server in bootstrap_servers.split(',')]

consumer = KafkaConsumer(
    'python-topic',
    bootstrap_servers=bootstrap_servers_list,
    auto_offset_reset='earliest',  # 가장 처음부터 메시지 읽기
    enable_auto_commit=False,
    group_id='python-consumer-group'
)

for message in consumer:
    print(f"받은 메시지: {message.value.decode('utf-8')}, 오프셋: {message.offset}")
    
    # 특정 오프셋에서 커밋 (예: 메시지 3까지 읽었을 때 커밋)
    if message.offset == 2:
        consumer.commit()
        print(f"오프셋 {message.offset}까지 커밋 완료")
