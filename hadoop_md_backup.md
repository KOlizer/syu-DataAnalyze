
## 6. Hadoop 연동을 통한 메시지 확인
### Hadoop 생성
1. 카카오 클라우드 콘솔 > 전체 서비스 > Hadoop Eco
2. 클러스터 생성 클릭

   - 클러스터 이름: `core-hadoop-cluster`
   - 클러스터 구성
        - 클러스터 버전: `Hadoop Eco 2.1.0`
        - 클러스터 유형: `Core-Hadoop`
        - 클러스터 가용성: `미체크`
   - 관리자 설정
        - 관리자 아이디: `admin`
        - 관리자 비밀번호: `Admin1234!`
        - 관리자 비밀번호 확인: `Admin1234!`
   - VPC 설정
        - VPC: `kc-vpc`
        - 서브넷: `kr-central-2-a의 Public 서브넷`
   - 보안 그룹 설정
        - 보안 그룹 설정: `새 보안 그룹 생성`
        - 보안 그룹 이름: `HDE-210-hadoop` {기본 입력 정보 사용}
   - 다음 버튼 클릭
   - 마스터 노드 설정
        - 마스터 노드 인스턴스 개수: `1`
        - 마스터 노드 인스턴스 유형: `m2a.xlarge`
        - 디스크 볼륨 유형 / 크기: `50`
   - 워커 노드 설정
        - 워커 노드 인스턴스 개수: `2`
        - 마스터 노드 인스턴스 유형: `m2a.xlarge`
        - 디스크 볼륨 유형 / 크기: `100`
   - 총 YARN 사용량
        - YARN Core: `6개` {입력 필요X}
        - YARN Memory: `20GB` {입력 필요X}
   - 키 페어: `{기존 생성 키 페어}`
   - 사용자 스크립트(선택): `없음`
   - 다음 버튼 클릭

   - 모니터링 에이전트 설치: `설치 안함`
   - 서비스 연동: `Data Catalog 연동`
        - 카탈로그 이름: `data_catalog`
   - HDFS 설정
        - HDFS 블록 크기: `128`
        - HDFS 복제 개수: `2`
   - 클러스터 구성 설정(선택): `{아래 코드 입력}`
      ```
         {
         "configurations": [
             {
             "classification": "core-site",
             "properties": {
                 "fs.swifta.service.kic.credential.id": "${ACCESS_KEY}",
                 "fs.swifta.service.kic.credential.secret": "${ACCESS_SECRET_KEY}"
             }
             }
         ]
         }
        ```
   - Kerberos 설치: `설치 안함`
   - Ranger 설치: `설치 안함`
3. 생성 버튼 클릭
4. Hadoop Eco 클러스터 생성 확인
5. 마스터/워커 노드 VM 생성 확인
      - 카카오 클라우드 콘솔 > 전체 서비스 > Virtual Machine > 인스턴스

      - **Note**: 보안 그룹 22번 포트 열기
   
   5-1. 마스터 노드 VM(HadoopMST) 옆의 `...` 클릭 후 `보안 그룹 수정` 클릭
   
   5-2. `보안 그룹 선택` 클릭
   
   5-3. `보안 그룹 생성` 버튼 클릭
   
      - 보안 그룹 이름: `hadoop_mst`
      - 보안 그룹 설명: `없음`
      - 인바운드 규칙
        - 프로토콜: `TCP`, 출발지: `0.0.0.0/0`, 포트 번호: `22`
      - 아웃바운드 규칙
        - 프로토콜: `ALL`, 출발지: `0.0.0.0/0`, 포트 번호: `ALL`
      - 생성 버튼 클릭
  
   5-4. 적용 버튼 클릭

7. 마스터 노드에 public IP 부여 후 ssh 접속
   
   - 마스터 노드 VM(HadoopMST)에 SSH로 접속
   
   #### **lab3-1-1**

   ```bash
   ssh -i {keypair}.pem ubuntu@{vm public ip}
   ```
   
8. Hadoop 설정

   - core-site.xml 설정 변경

   #### **lab3-1-2**
   ```
   cd /etc/hadoop/conf
   sudo vi core-site.xml
   ```

   - 아래 값으로 변경 

   ```
   <property>
      <name>fs.s3a.endpoint</name>
      <value>objectstorage.kr-central-2.kakaocloud.com</value>
   </property>
   <property>
      <name>s3service.s3-endpoint</name>
      <value>objectstorage.kr-central-2.kakaocloud.com</value>
   </property>
   ```
   
9. Hive 실행
   #### **lab3-1-3**
   ```
   hive
   ```

10. 사용할 데이터 베이스 선택
    #### **lab3-1-4** 
    ```
    use dc_database;
    ```

11. 테이블에 파티션 추가

    - **Note**: 사용하는 모든 테이블의 파티션을 추가해줘야함!! (ex: kafka_data, alb_data)

    #### **lab3-1-5**
    ```
    ALTER TABLE {테이블 이름}
    ADD PARTITION (partition_key='0')
    LOCATION 's3a://{Object Storage 경로}';
    ```
    
    - 예시
    ```
    ALTER TABLE kafka_data
    ADD PARTITION (partition_key='0')
    LOCATION 's3a://kafka-nginx-log/nginx-log/CustomTopicDir/MyPartition_0';
    ```
