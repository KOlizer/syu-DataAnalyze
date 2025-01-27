# Kakao Cloud 실습 가이드

> **주의**  
> 본 문서는 계속 수정될 수 있습니다. 실습 환경 및 요구 사항에 따라 적절히 수정하여 사용해주세요.
---

## API 서버 생성

- **이름**: `Api-Server`
- **이미지**: `Ubuntu 22.04`
- **인스턴스유형**: `m2a.xlarge`
- **볼륨**: `30GB`
- **키페어**  
  - **키페어 생성 후 등록**
- **VPC**: 실습 환경
- **서브넷**: `main`
- **보안 그룹(SG) 생성**  
  - 필요 포트 규칙 설정 (예: 22, 80 등)

---

## 로드 밸런서(ALB) 생성

- **유형**: `ALB`
- **이름**: `Trafic_ALB`
- **상태 확인**: `x`
- **VPC**: 실습 환경
- **서브넷**: `main`
- **생성**  
  - 퍼블릭 IP 부여
  - 리스너 추가  
    - **새 대상 그룹 추가**  
      - 리스너: `HTTP:80`  
      - 대상 그룹 이름: `ApiServer`  
      - **다음**  
      - 연결할 인스턴스 선택: `api vm` 2대  
      - **대상추가**  
      - **다음**  
      - **생성**
  - 새로고침 후, 생성된 대상 그룹 선택 → **추가**

---

## TG 서버 생성

- **이름**: `Traffic_Generator`
- **이미지**: `Ubuntu 22.04`
- **인스턴스유형**: `m2a.xlarge`
- **볼륨**: `30GB`
- **VPC**: 실습 환경
- **보안 그룹(SG) 생성**  
  - 예: `22, 80, ALL` 등 필요한 포트 및 프로토콜 규칙 설정

---

## MySQL 생성

(※ 별도의 가이드 혹은 기존 실습 환경에 맞추어 진행)

---

## 토픽(Pub/Sub) 생성

(※ Kakao Cloud Pub/Sub 사용 시, 콘솔에서 직접 생성하거나 API를 통해 생성 가능)

---

# API 서버 설정

     cd /etc/logstash/conf.d
     sudo vi logs-to-pubsub.conf
     ```
2. **Logstash 재시작**
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl restart logstash
