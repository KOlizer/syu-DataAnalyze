from confluent_kafka import Consumer, KafkaError, TopicPartition


c = Consumer({
    'bootstrap.servers': ${KAFKA_BOOTSTRAP_SERVERS},
    'group.id': 'python-group',
    'enable.auto.commit': False,
    'auto.offset.reset': 'earliest'
})

# 특정 파티션 오프셋 설정 (예: 0번 파티션, 오프셋 2부터 시작)
# 만약 여러 파티션이면 리스트 형태로 여러 TopicPartition을 지정
c.assign([TopicPartition(${KAFKA_PYTHON_TOPIC}, 0, 2)])  

try:
    while True:
        msg = c.poll(timeout=1.0)
        if msg is None:
            continue
        if msg.error():
            if msg.error().code() == KafkaError._PARTITION_EOF:
                print("End of partition event")
            elif msg.error():
                print(msg.error())
                break
        else:
            # 실제 메시지 처리
            print(f"Received message: {msg.value().decode('utf-8')} (offset: {msg.offset()})")
            # 여기서 수동 커밋
            c.commit(asynchronous=False)  # 또는 commit(msg)를 사용 가능

except KeyboardInterrupt:
    pass
finally:
    c.close()
