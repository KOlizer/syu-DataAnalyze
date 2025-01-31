from kafka import KafkaProducer
import time

producer = KafkaProducer(bootstrap_servers=${KAFKA_BOOTSTRAP_SERVERS})

for i in range(5):
    message = f"메시지 {i+1}"
    producer.send(${KAFKA_PYTHON_TOPIC}, value=message.encode('utf-8'))
    print(f"전송: {message}")
    time.sleep(1)

producer.flush()
producer.close()
