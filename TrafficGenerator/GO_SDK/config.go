ubuntu@host-10-0-3-24:~/gosdk/cmd$ cat config.go
package main

import (
    "gopkg.in/yaml.v2"
    "io/ioutil"
    "log"
)

// Config 구조체는 설정 변수를 포함합니다.
type Config struct {
    DomainID         string `yaml:"domain_id"`
    ProjectID        string `yaml:"project_id"`
    SubscriptionName string `yaml:"subscription_name"`
    TopicName        string `yaml:"topic_name"`
    CredentialID     string `yaml:"credential_id"`
    CredentialSecret string `yaml:"credential_secret"`
}

// 전역 설정 변수
var config Config

func init() {
    // config.yml 파일을 읽어와서 config 구조체에 매핑
    configFile, err := ioutil.ReadFile("/home/ubuntu/config.yml")  // 절대 경로 사용
    if err != nil {
        log.Fatalf("Error reading config.yml: %v", err)
    }

    err = yaml.Unmarshal(configFile, &config)
    if err != nil {
        log.Fatalf("Error unmarshalling config.yml: %v", err)
    }
}
