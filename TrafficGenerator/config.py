# TrafficGenerator/REST API/config.py

import yaml
import logging
import os

# 홈 디렉토리에 있는 config.yml 경로 설정
CONFIG_PATH = os.path.expanduser('~/config.yml')

# config.yml 로드
with open(CONFIG_PATH, 'r') as file:
    config = yaml.safe_load(file)

# Pub/Sub 설정
PUBSUB_ENDPOINT = config['pubsub']['endpoint']
DOMAIN_ID = config['pubsub']['domain_id']
PROJECT_ID = config['pubsub']['project_id']
TOPIC_NAME = config['pubsub']['topic_name']
TOPIC_NAME_MK = config['pubsub']['topic_name_mk']
TOPIC_DESCRIPTION = config['pubsub']['topic_description']
TOPIC_RETENTION_DURATION = config['pubsub']['topic_retention_duration']

CREDENTIAL_ID = config['pubsub']['credential_id']
CREDENTIAL_SECRET = config['pubsub']['credential_secret']

# 구독 설정
SUBSCRIPTION_NAME = config['subscription']['name']
SUBSCRIPTION_ENDPOINT = (
    f"{PUBSUB_ENDPOINT}/v1/domains/{DOMAIN_ID}/projects/{PROJECT_ID}/subscriptions/{SUBSCRIPTION_NAME}/pull"
)

# Object Storage 서브스크립션 환경변수
OBJECT_STORAGE_SUBSCRIPTION_NAME = config['object_storage_subscription']['name']
OBJECT_STORAGE_BUCKET = config['object_storage_subscription']['bucket']
OBJECT_STORAGE_EXPORT_INTERVAL_MIN = config['object_storage_subscription']['export_interval_min']
OBJECT_STORAGE_FILE_PREFIX = config['object_storage_subscription']['file_prefix']
OBJECT_STORAGE_FILE_SUFFIX = config['object_storage_subscription']['file_suffix']
OBJECT_STORAGE_CHANNEL_COUNT = config['object_storage_subscription']['channel_count']
OBJECT_STORAGE_MAX_CHANNEL_COUNT = config['object_storage_subscription']['max_channel_count']
OBJECT_STORAGE_IS_EXPORT_ENABLED = config['object_storage_subscription']['is_export_enabled']

# 로그 설정
LOG_FILENAME = config['logging']['filename']
LOG_LEVEL = getattr(logging, config['logging']['level'].upper(), logging.INFO)

# 스레드 및 사용자 수 관련 설정
NUM_USERS = config['threads']['num_users']
MAX_THREADS = config['threads']['max_threads']
ACTIONS_PER_USER = config['threads']['actions_per_user']

# API 서버 정보-로드밸런서 주소
API_BASE_URL = config['api']['base_url']
TIME_SLEEP_RANGE = (config['api']['time_sleep_range']['min'], config['api']['time_sleep_range']['max'])

# 엔드포인트 경로
API_ENDPOINTS = config['api']['endpoints']

# 나이 구간 임계값
AGE_THRESHOLD_YOUNG = config['age_threshold']['young']
AGE_THRESHOLD_MIDDLE = config['age_threshold']['middle']
