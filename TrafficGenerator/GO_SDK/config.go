// config.go
package main

import (
    "io/ioutil"
    "log"
    "os"
    "path/filepath"

    "gopkg.in/yaml.v2"
)

// Config 구조체는 필요한 설정 변수를 포함합니다.
type Config struct {
    DomainID         string
    ProjectID        string
    SubscriptionName string
    TopicName        string
    CredentialID     string
    CredentialSecret string
}

// PubsubConfig 구조체는 pubsub 섹션의 설정을 포함합니다.
type PubsubConfig struct {
    Endpoint               string `yaml:"endpoint"`
    DomainID               string `yaml:"domain_id"`
    ProjectID              string `yaml:"project_id"`
    TopicName              string `yaml:"topic_name"`
    TopicNameMk            string `yaml:"topic_name_mk"`
    TopicDescription       string `yaml:"topic_description"`
    TopicRetentionDuration string `yaml:"topic_retention_duration"`
    CredentialID           string `yaml:"credential_id"`
    CredentialSecret       string `yaml:"credential_secret"`
}

// SubscriptionConfig 구조체는 subscription 섹션의 설정을 포함합니다.
type SubscriptionConfig struct {
    Name string `yaml:"name"`
}

// ConfigFile 구조체는 config.yml 파일의 전체 구조를 나타냅니다.
type ConfigFile struct {
    Pubsub                 PubsubConfig        `yaml:"pubsub"`
    Subscription           SubscriptionConfig  `yaml:"subscription"`
    ObjectStorageSubscription struct {
        Name              string `yaml:"name"`
        Bucket            string `yaml:"bucket"`
        ExportIntervalMin int    `yaml:"export_interval_min"`
        FilePrefix        string `yaml:"file_prefix"`
        FileSuffix        string `yaml:"file_suffix"`
        ChannelCount      int    `yaml:"channel_count"`
        MaxChannelCount   int    `yaml:"max_channel_count"`
        IsExportEnabled   bool   `yaml:"is_export_enabled"`
    } `yaml:"object_storage_subscription"`
    Logging struct {
        Filename string `yaml:"filename"`
        Level    string `yaml:"level"`
    } `yaml:"logging"`
    Threads struct {
        NumUsers       int `yaml:"num_users"`
        MaxThreads     int `yaml:"max_threads"`
        ActionsPerUser int `yaml:"actions_per_user"`
    } `yaml:"threads"`
    Api struct {
        BaseURL        string            `yaml:"base_url"`
        Endpoints      map[string]string `yaml:"endpoints"`
        TimeSleepRange struct {
            Min float64 `yaml:"min"`
            Max float64 `yaml:"max"`
        } `yaml:"time_sleep_range"`
    } `yaml:"api"`
    AgeThreshold struct {
        Young  int `yaml:"young"`
        Middle int `yaml:"middle"`
    } `yaml:"age_threshold"`
}

var config Config

func init() {
    // 홈 디렉토리 경로 가져오기
    homeDir, err := os.UserHomeDir()
    if err != nil {
        log.Fatalf("홈 디렉토리 가져오기 실패: %v", err)
    }

    // config.yml 파일 경로 설정
    configPath := filepath.Join(homeDir, "config.yml")

    // config.yml 파일 읽기
    data, err := ioutil.ReadFile(configPath)
    if err != nil {
        log.Fatalf("config.yml 파일 읽기 실패: %v", err)
    }

    // YAML 파싱
    var cfgFile ConfigFile
    err = yaml.Unmarshal(data, &cfgFile)
    if err != nil {
        log.Fatalf("config.yml 파일 파싱 실패: %v", err)
    }

    // 환경 변수에서 민감한 정보 로드 (보안 강화)
    credentialID := os.Getenv("CREDENTIAL_ID")
    if credentialID == "" {
        credentialID = cfgFile.Pubsub.CredentialID
    }

    credentialSecret := os.Getenv("CREDENTIAL_SECRET")
    if credentialSecret == "" {
        credentialSecret = cfgFile.Pubsub.CredentialSecret
    }

    // 필요한 설정 변수만 Config 구조체에 할당
    config = Config{
        DomainID:         cfgFile.Pubsub.DomainID,
        ProjectID:        cfgFile.Pubsub.ProjectID,
        SubscriptionName: cfgFile.Subscription.Name,
        TopicName:        cfgFile.Pubsub.TopicName,
        CredentialID:     credentialID,
        CredentialSecret: credentialSecret,
    }

    // 디버깅: 설정 로드 확인 (필요 시 주석 해제)
    // log.Printf("Config loaded: %+v", config)
}
