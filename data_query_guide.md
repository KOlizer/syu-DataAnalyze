# DataQuery 가이드

## 1. ObjectStrage 버킷 생성
- 이전 실습에서 이미 생성하였다면 생략 가능
</br>

1. 콘솔을 통한 버킷 생성
  - 버킷 정보
    - 이름: `data-query`

2. 권한 설정
   1. `생성한 버킷` 클릭
   2. `권한` 클릭
   3. `역할 추가` 클릭
   4. 역할 추가
      - 서비스 계정: `{프로젝트 이름}@data-query.kc.serviceaccount.com`
      - 역할: `스토리지 편집자`

## 2. 데이터 원본 생성
1. 콘솔 -> Analytics -> Data Query -> 데이터 원본 관리
2. `데이터 원본 관리` 클릭
3. `데이터 원본 생성` 클릭
   - 데이터 원본 정보
     - 이름: data_orign
     - 상세 정보:
       - 데이터 원본 유형: `MySQL`
       - 인스턴스 그룹: `database` (앞서 생성한 DB)
       - 연결 정보:
         - ID: admin
         - 비밀번호: admin1234
4. `생성` 클릭

## 3. Data Query 실습
1. 콘솔 -> Analytics -> Data Query -> 쿼리 편집기
