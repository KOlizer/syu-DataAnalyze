# python_producer.py
from kafka import KafkaProducer
import json
import time

producer = KafkaProducer(
    bootstrap_servers=[${KAFKA_BOOTSTRAP_SERVERS}],
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
