from confluent_kafka import Producer
import time


# 프로듀서 인스턴스 생성
p = Producer({'bootstrap.servers': ${KAFKA_BOOTSTRAP_SERVERS}})

# 메시지 전송 완료 시 호출될 콜백 함수
def delivery_callback(err, msg):
    if err:
        print(f"Message failed delivery: {err}")
    else:
        print(f"Message delivered")

# 5개의 메시지를 1초 간격으로 전송
for i in range(5):
    message = f"Message {i}"
    p.produce(${KAFKA_PYTHON_TOPIC}, message.encode('utf-8'), callback=delivery_callback)
    p.poll(0)  # 이벤트 큐를 폴링하여 콜백이 실행되도록
    time.sleep(1)

# 남은 메시지 전송 후 종료
p.flush()
print("Producer finished sending 5 messages.")
