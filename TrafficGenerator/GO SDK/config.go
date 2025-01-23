// config.go
package main

// Config 구조체는 모든 설정 변수를 포함합니다.
type Config struct {
    DomainID         string
    ProjectID        string
    SubscriptionName string
    TopicName        string
    CredentialID     string
    CredentialSecret string
}

// 전역 설정 변수
var config = Config{
    DomainID:         "fa22d0db818f48829cf8b7849e3a0a26",
    ProjectID:        "86099dec56044a43ac3f92a40784929b",
    SubscriptionName: "go-sdk-pull-sub-auto",
    TopicName:        "go-sdk-topic-auto",
    CredentialID:     "833ee541fdf64847bc0ed63ff37fc565",
    CredentialSecret: "a664a8068502c2e4ce55024a6cf28b6358f501ddca3812e4fa94c22ea58e65162b7269",
}
