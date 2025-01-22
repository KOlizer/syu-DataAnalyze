#!/usr/bin/env python3
"""
create_subscription.py

- Kakao Cloud Pub/Sub에 서브스크립션(Subscription)을 생성하는 스크립트
- objectStorageConfig를 config.py에서 읽어와 설정
"""

import requests
import json
import config

def create_subscription():
    """
    Kakao Pub/Sub에서 서브스크립션을 생성하고, 응답 JSON을 반환합니다.
    """
    # (1) 요청 URL
    url = (
        f"{config.PUBSUB_ENDPOINT}/v1/domains/{config.DOMAIN_ID}/"
        f"projects/{config.PROJECT_ID}/subscriptions/{config.OBJECT_STORAGE_SUBSCRIPTION_NAME}"
    )

    # (2) subscription 요청 바디
    body = {
        "subscription": {
            "topic": config.TOPIC_NAME_MK,
            "ackDeadlineSeconds": 30,
            "messageRetentionDuration": "600s",  # 7일 예시
            "maxDeliveryAttempt": 1
        }
    }

    # (3) objectStorageConfig 설정
    # 필요하다면 조건부로 삽입할 수도 있지만, 지금은 무조건 Object Storage 서브스크립션을 사용한다고 가정
    object_storage_config = {
        "bucket": config.OBJECT_STORAGE_BUCKET,
        "exportIntervalMinutes": config.OBJECT_STORAGE_EXPORT_INTERVAL_MIN,
        "filePrefix": config.OBJECT_STORAGE_FILE_PREFIX,
        "fileSuffix": config.OBJECT_STORAGE_FILE_SUFFIX,
        "channelCount": config.OBJECT_STORAGE_CHANNEL_COUNT,
        "maxChannelCount": config.OBJECT_STORAGE_MAX_CHANNEL_COUNT,
        "isExportEnabled": config.OBJECT_STORAGE_IS_EXPORT_ENABLED
    }
    body["subscription"]["objectStorageConfig"] = object_storage_config

    # (4) 요청 헤더
    headers = {
        "Credential-ID": config.CREDENTIAL_ID,
        "Credential-Secret": config.CREDENTIAL_SECRET,
        "Content-Type": "application/json"
    }

    # (5) POST/PUT 요청 (문서에 맞춰 수정)
    resp = requests.put(url, headers=headers, json=body, timeout=10)

    # (6) 응답 검사
    if not (200 <= resp.status_code < 300):
        raise RuntimeError(
            f"[ERROR] 서브스크립션 생성 실패 (status={resp.status_code}). 응답 바디: {resp.text}"
        )

    return resp.json()

def main():
    print(f"=== Kakao Cloud Pub/Sub: 서브스크립션 '{config.SUBSCRIPTION_NAME}' 생성 (Object Storage) ===")
    try:
        result = create_subscription()
        print("[INFO] 서브스크립션 생성 성공!")
        print("응답 데이터:")
        print(json.dumps(result, ensure_ascii=False, indent=2))
    except Exception as e:
        print("[ERROR] 서브스크립션 생성 중 오류 발생:", e)

if __name__ == "__main__":
    main()
