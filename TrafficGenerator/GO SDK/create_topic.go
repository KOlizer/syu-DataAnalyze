// 파일: cmd/create_topic/create_topic.go
package main

import (
    "context"
    "fmt"
    "log"

    "github.kakaoenterprise.in/cloud-platform/kc-pub-sub-sdk-go"
    "github.kakaoenterprise.in/cloud-platform/kc-pub-sub-sdk-go/option"
)

func main() {
    // 환경 설정 하드 코딩
    domainID := "fa22d0db818f48829cf8b7849e3a0a26"
    projectID := "86099dec56044a43ac3f92a40784929b"
    credentialID := "833ee541fdf64847bc0ed63ff37fc565"
    credentialSecret := "a664a8068502c2e4ce55024a6cf28b6358f501ddca3812e4fa94c22ea58e65162b7269"
    topicName := "go-sdk-topic-auto"

    // 클라이언트 초기화
    ctx := context.Background()
    accessKey := pubsub.AccessKey{
        CredentialID:     credentialID,
        CredentialSecret: credentialSecret,
    }
    opts := []option.ClientOption{
        option.WithAccessKey(accessKey),
    }
    client, err := pubsub.NewClient(ctx, domainID, projectID, opts...)
    if err != nil {
        log.Fatalf("Pub/Sub 클라이언트 생성 실패: %v", err)
    }
    defer client.Close()

    // 토픽 생성
    fmt.Printf("토픽 '%s'을 생성 중...\n", topicName)
    topic, err := client.CreateTopic(ctx, topicName)
    if err != nil {
        log.Fatalf("토픽 생성 실패: %v", err)
    }
    fmt.Printf("토픽 생성 완료: %v\n", topic)
}
