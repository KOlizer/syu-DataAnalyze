# Kakao Cloud 실습 가이드

> **주의**  
> 본 문서는 계속 수정될 수 있습니다. 실습 환경 및 요구 사항에 따라 적절히 수정하여 사용해주세요.
# 콘솔에서 만들어야할 자원
필요한 인프라 생성(TrafficGenerator, APIServer, ALB...)

## Pub/Sub 생성
## MySQL 생성
## Data Catalog 생성
## Kafaka 생성
## Hadoop
(※ 별도의 가이드 혹은 기존 실습 환경에 맞추어 진행)
## ObjectStorage 생성
 - LBAccess용 버킷
## API 서버 생성 (2대)

- **이름**: `Api-Server`
- **개수**: `2`
- **이미지**: `Ubuntu 22.04`
- **인스턴스유형**: `m2a.xlarge`
- **볼륨**: `30GB`
- **키페어**  
  - **키페어 생성 후 등록**
- **VPC**: 실습 환경
- **서브넷**: `main`
- **보안 그룹(SG) 생성**  
  - 필요 포트 규칙 설정 (예: 22, 80 등)


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


## Test용 topic
## Teet용 토픽의 Pull Subscription
## Teet용 토픽의 Push Subscription


## TG 서버 생성 (2대)

- **이름**: `Traffic_Generator`
- **이미지**: `Ubuntu 22.04`
- **인스턴스유형**: `m2a.xlarge`
- **볼륨**: `30GB`
- **VPC**: 실습 환경
- **보안 그룹(SG) 생성**  
  - 예: `22, 80, ALL` 등 필요한 포트 및 프로토콜 규칙 설정

---
