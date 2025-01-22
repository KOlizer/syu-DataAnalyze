#!/usr/bin/env python3
"""
create_topic.py

- Kakao Cloud Pub/Sub에 새 토픽을 생성하는 스크립트
- 모든 설정을 config.py에서 가져오며, 사용자 입력 없이 바로 생성
"""

import requests
import config
import json

def create_topic():
    """
    Kakao Pub/Sub에 새 토픽을 생성하고, 응답 JSON을 반환합니다.
    """
    # 1) 실제 Kakao Pub/Sub 문서 확인:
    #   - 토픽 생성이 PUT인지 POST인지, path param인지 query param인지 확인
    #   - 여기서는 예시로 POST /v1/domains/{domainId}/projects/{projectId}/topics/{topicName} 형태
    url = (
        f"{config.PUBSUB_ENDPOINT}/v1/domains/{config.DOMAIN_ID}/"
        f"projects/{config.PROJECT_ID}/topics/{config.TOPIC_NAME_MK}"
    )

    # 2) 요청 바디
    body = {
        "topic": {
            "description": config.TOPIC_DESCRIPTION,
            "messageRetentionDuration": config.TOPIC_RETENTION_DURATION
        }
    }

    # 3) 요청 헤더
    headers = {
        "Credential-ID": config.CREDENTIAL_ID,
        "Credential-Secret": config.CREDENTIAL_SECRET,
        "Content-Type": "application/json"
    }

    # 4) PUT 요청 (문서에 따라 PUT이어야 할 수도 있음)
    resp = requests.put(url, headers=headers, json=body, timeout=10)

    # 5) 결과 처리
    if not (200 <= resp.status_code < 300):
        raise RuntimeError(
            f"[ERROR] 토픽 생성 실패 (status={resp.status_code}). 응답 바디: {resp.text}"
        )

    return resp.json()


def main():
    print("=== Kakao Cloud Pub/Sub: 토픽 자동 생성 ===")
    print(f"토픽 이름: {config.TOPIC_NAME}")
    try:
        result = create_topic()
        print("[INFO] 토픽 생성 성공!")
        print("응답 데이터:")
        print(json.dumps(result, ensure_ascii=False, indent=2))
    except Exception as e:
        print("[ERROR] 토픽 생성 중 오류:", e)

if __name__ == "__main__":
    main()