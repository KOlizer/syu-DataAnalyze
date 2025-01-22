//계속 오류 발생 수정 필요
//카카오 기술문서 확인하여 수정 필요






// 파일: cmd/create_subscription/create_subscription.go
package main

import (
    "context"
    "fmt"
    "log"
    "time"

    "github.kakaoenterprise.in/cloud-platform/kc-pub-sub-sdk-go"
    "github.kakaoenterprise.in/cloud-platform/kc-pub-sub-sdk-go/option"
)

func main() {
    // 설정 값들
    domainID := "fa22d0db818f48829cf8b7849e3a0a26"         // 도메인 ID를 여기에 입력하세요
    projectID := "86099dec56044a43ac3f92a40784929b"       // 프로젝트 ID를 여기에 입력하세요
    topicName := "go-sdk-topic-auto"                       // 이미 존재하는 토픽 이름을 여기에 입력하세요
    subscriptionName := "go-sdk-pull-sub-auto"             // 생성할 서브스크립션 이름

    credentialID := "833ee541fdf64847bc0ed63ff37fc565"      // 액세스 키 ID를 여기에 입력하세요
    credentialSecret := "a664a8068502c2e4ce55024a6cf28b6358f501ddca3812e4fa94c22ea58e65162b7269" // 보안 액세스 키를 여기에 입력하세요

    // 컨텍스트 생성
    ctx := context.Background()

    // 액세스 키 설정
    accessKey := pubsub.AccessKey{
        CredentialID:     credentialID,
        CredentialSecret: credentialSecret,
    }

    // 클라이언트 옵션 설정
    clientOptions := []option.ClientOption{
        option.WithAccessKey(accessKey),
        // 필요한 경우 추가 옵션을 설정할 수 있습니다.
    }

    // Pub/Sub 클라이언트 생성
    client, err := pubsub.NewClient(ctx, domainID, projectID, clientOptions...)
    if err != nil {
        log.Fatalf("pubsub.NewClient 오류: %v", err)
    }
    defer func() {
        if err := client.Close(); err != nil {
            log.Fatalf("클라이언트 닫기 오류: %v", err)
        }
    }()

    // 서브스크립션 설정
    subscriptionConfig := &pubsub.SubscriptionConfig{
        Topic:              topicName,
        AckDeadline:        20 * time.Second, // 메시지 확인 기한 설정 (예: 20초)
        RetentionDuration:  24 * time.Hour,    // 메시지 보존 기간 설정 (예: 24시간)
        MaxDeliveryAttempt: 10,                // 재처리 시도 횟수 설정 (예: 10회)
    }

    // 서브스크립션 생성 요청 (단일 변수로 할당)
    result := client.CreateSubscription(ctx, subscriptionName, subscriptionConfig, option.WithWaitStatus())

    // 서브스크립션 생성 완료 대기 및 결과 확인
    if err := result.Err(); err != nil {
        log.Fatalf("CreateSubscription 완료 대기 오류: %v", err)
    }

    fmt.Printf("서브스크립션 생성 완료: %s\n", result.Name())
}
