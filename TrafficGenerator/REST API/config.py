#!/usr/bin/env python3
"""
config.py

- config.yml 파일을 로드하여 설정을 관리합니다.
"""

import os
import yaml

# 현재 스크립트의 디렉토리 경로 가져오기
current_dir = os.path.dirname(os.path.abspath(__file__))
# 상위 디렉토리 경로 가져오기 (REST API의 상위 디렉토리는 TrafficGenerator)
parent_dir = os.path.dirname(current_dir)
# config.yml 파일의 전체 경로 설정
config_path = os.path.join(parent_dir, "config.yml")

# config.yml 파일 열기
with open(config_path, "r") as f:
    config = yaml.safe_load(f)

# 설정 변수 할당
PUBSUB_ENDPOINT = config['pubsub']['endpoint']
DOMAIN_ID = config['pubsub']['domain_id']
PROJECT_ID = config['pubsub']['project_id']
TOPIC_NAME = config['pubsub']['topic_name']
TOPIC_NAME_MK = config['pubsub']['topic_name_mk']
TOPIC_DESCRIPTION = config['pubsub']['topic_description']
TOPIC_RETENTION_DURATION = config['pubsub']['topic_retention_duration']
SUB_NAME = config['pubsub']['sub_name']
CREDENTIAL_ID = config['pubsub']['credential_id']
CREDENTIAL_SECRET = config['pubsub']['credential_secret']

SUBSCRIPTION_NAME = config['subscription']['name']

OBJECT_STORAGE_SUBSCRIPTION_NAME = config['object_storage_subscription']['name']
OBJECT_STORAGE_BUCKET = config['object_storage_subscription']['bucket']
EXPORT_INTERVAL_MIN = config['object_storage_subscription']['export_interval_min']
FILE_PREFIX = config['object_storage_subscription']['file_prefix']
FILE_SUFFIX = config['object_storage_subscription']['file_suffix']
CHANNEL_COUNT = config['object_storage_subscription']['channel_count']
MAX_CHANNEL_COUNT = config['object_storage_subscription']['max_channel_count']
IS_EXPORT_ENABLED = config['object_storage_subscription']['is_export_enabled']

LOG_FILENAME = config['logging']['filename']
LOG_LEVEL = config['logging']['level']

NUM_USERS = config['threads']['num_users']
MAX_THREADS = config['threads']['max_threads']
ACTIONS_PER_USER = config['threads']['actions_per_user']

API_BASE_URL = config['api']['base_url']

# 추가 설정이 필요하면 여기에 작성
