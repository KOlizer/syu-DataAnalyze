from kafka import KafkaConsumer

consumer = KafkaConsumer(
    ${KAFKA_PYTHON_TOPIC},
    bootstrap_servers=${KAFKA_BOOTSTRAP_SERVERS},
    group_id='python-group',
    enable_auto_commit=False,
    auto_offset_reset='earliest'
)

print("컨슈머가 메시지를 기다리는 중입니다...")

for message in consumer:
    print(f"받은 메시지: {message.value.decode('utf-8')}, 오프셋: {message.offset}")
    
    # 특정 오프셋에서 커밋 (예: 메시지 3까지 읽었을 때 커밋)
    if message.offset == 2:
        consumer.commit()
        print(f"오프셋 {message.offset}까지 커밋 완료")
