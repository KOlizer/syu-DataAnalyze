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
     - 이름: `data_orign`
     - 상세 정보:
       - 데이터 원본 유형: `MySQL`
       - 인스턴스 그룹: `database` (앞서 생성한 DB)
       - 연결 정보:
         - ID: `admin`
         - 비밀번호: `admin1234`
4. `생성` 클릭

## 3. Data Query 실습

#### 쿼리 결과 저장 위치 설정
1. 콘솔 -> Analytics -> Data Query -> 쿼리 편집기
2. `설정` 클릭
3. `관리` 클릭
4. 생성해둔 `data-query` 선택
5. `저장` 클릭

- **Note**: 예상 파일 저장 형식
  ```
  {버킷 이름}/{하위 상세 경로}/{YYYY}/{MM}/{DD}/{쿼리 ID}.csv
  {버킷 이름}/{하위 상세 경로}/{YYYY}/{MM}/{DD}/{쿼리 ID}.metadata
  ```

#### 쿼리 실습
1. 콘솔 -> Analytics -> Data Query -> 쿼리 편집기
2. 편집기 설정 정보
   - 데이터 원본: `data_orign`
   - 데이터 베이스: `shopdb`
  
3. 시간당 PV(페이지 뷰) count 쿼리
   ```
   SELECT
    DATE_FORMAT(searched_at, '%Y-%m-%d %H:00:00') AS hour,
    COUNT(*) AS pv_count
   FROM
       search_logs
   GROUP BY
       DATE_FORMAT(searched_at, '%Y-%m-%d %H:00:00')
   ORDER BY
     hour DESC;
   ```

4. 세션 쿠키(session_id) 기반 방문자 수 추출
    ```
    SELECT
        session_id,
        COUNT(DISTINCT user_id) AS visitors_count
    FROM
        sessions
    WHERE
        login_time IS NOT NULL
    GROUP BY
        session_id
    ORDER BY
        visitors_count DESC;
    ```
5. 상품 상세 페이지 접근 로그를 집계하여 인기 상품 상위 5개 추출 
   ```
   SELECT 
    search_query AS product_name,
    COUNT(*) AS search_count
    FROM 
        shopdb.search_logs
    GROUP BY 
        search_query
    ORDER BY 
        search_count DESC
    LIMIT 5;
    ```

6. HTTP status code별 count로 에러율 추출 (현재 권한 문제)
  - 쿼리는 성공하는데 테이블이 안 뜨는 문제
    ```
	WITH parsed AS (
	  SELECT 
	    endpoint,
	    request,
	    CAST(status AS integer) AS status_int
	  FROM db3_lsh.partition_test
	),
	extracted AS (
	  SELECT 
	    endpoint,
	    -- /search인 경우, request에서 ?query= 이후의 값을 추출하여 subcategory로 사용하고, 아니면 '-'로 처리
	    CASE 
	      WHEN endpoint = '/search'
	      THEN regexp_extract(request, '^(?:GET|POST|PUT|DELETE)\\s+[^\\s\\?]+\\?query=([^\\s]+)', 1)
	      ELSE '-' 
	    END AS subcategory,
	    status_int
	  FROM parsed
	)
	SELECT 
	  endpoint,
	  subcategory,
	  COUNT(*) AS total,
	  SUM(CASE WHEN status_int >= 400 THEN 1 ELSE 0 END) AS error_count,
	  ROUND(SUM(CASE WHEN status_int >= 400 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS error_rate_percentage
	FROM extracted
	GROUP BY endpoint, subcategory
	ORDER BY endpoint;

    ```

