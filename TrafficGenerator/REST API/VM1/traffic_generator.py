#!/usr/bin/env python3
"""
traffic_generator.py

- 다양한 사용자 시뮬레이션을 통해 API 서버의 트래픽을 생성
- config.py와 traffic_config.py에서 설정을 읽어옴
"""

import os
import sys
import requests
import threading
import time
import random
import uuid
import logging

# 현재 스크립트의 디렉토리 경로 가져오기
current_dir = os.path.dirname(os.path.abspath(__file__))

# REST API 디렉토리의 절대 경로 가져오기 (상위 디렉토리)
rest_api_dir = os.path.abspath(os.path.join(current_dir, '..'))

# REST API 디렉토리를 Python 경로에 추가하여 config.py와 traffic_config.py를 임포트 가능하게 함
sys.path.append(rest_api_dir)

# config.py 불러오기 (REST API 패키지에서)
import config

# traffic_config.py 불러오기 (REST API 패키지에서)
import traffic_config

#################################
# 전역 상품/카테고리 캐시
#################################
products_cache = []
categories_cache = []

#################################
# 로깅 설정
#################################
logging.basicConfig(
    filename=config.LOG_FILENAME,
    level=getattr(logging, config.LOG_LEVEL.upper(), logging.INFO),
    format='%(asctime)s - %(levelname)s - %(message)s'
)

#################################
# 나이 구간 판단 함수
#################################
def get_age_segment(age: int) -> str:
    if age < config.AGE_THRESHOLD_YOUNG:
        return "young"
    elif age < config.AGE_THRESHOLD_MIDDLE:
        return "middle"
    else:
        return "old"

#################################
# 상품/카테고리 데이터 가져오기
#################################
def fetch_products():
    global products_cache
    headers = {"Accept": "application/json"}
    try:
        url = f"{config.API_BASE_URL}{config.API_ENDPOINTS['PRODUCTS']}"
        resp = requests.get(url, headers=headers)
        if resp.status_code == 200:
            products_cache = resp.json().get("products", [])
            logging.info(f"Fetched {len(products_cache)} products.")
        else:
            logging.error(f"Failed to fetch products: {resp.status_code}, content={resp.text}")
    except Exception as e:
        logging.error(f"Exception while fetching products: {e}")

def fetch_categories():
    global categories_cache
    headers = {"Accept": "application/json"}
    try:
        url = f"{config.API_BASE_URL}{config.API_ENDPOINTS['CATEGORIES']}"
        resp = requests.get(url, headers=headers)
        if resp.status_code == 200:
            categories_cache = resp.json().get("categories", [])
            logging.info(f"Fetched {len(categories_cache)} categories.")
        else:
            logging.error(f"Failed to fetch categories: {resp.status_code}, content={resp.text}")
    except Exception as e:
        logging.error(f"Exception while fetching categories: {e}")

#################################
# 확률 전이 공통 함수
#################################
def pick_next_state(prob_dict: dict) -> str:
    states = list(prob_dict.keys())
    probs = list(prob_dict.values())
    return random.choices(states, weights=probs, k=1)[0]

#################################
# 선호 카테고리 상품 선택
#################################
def pick_preferred_product_id(gender: str, age_segment: str) -> str:
    if not products_cache:
        return "default"  # Fallback ID
    preferred_categories = config.CATEGORY_PREFERENCE.get(gender, {}).get(age_segment, [])
    filtered_products = [p for p in products_cache if p.get("category", "") in preferred_categories]
    if filtered_products:
        return random.choice(filtered_products).get("id", "default")
    return random.choice(products_cache).get("id", "default")

#################################
# API 요청 공통 함수
#################################
def send_api_request(endpoint: str, method: str = "GET", payload: dict = None) -> (int, str):
    try:
        url = f"{config.API_BASE_URL}{endpoint}"
        if method == "POST":
            response = requests.post(url, json=payload)
        elif method == "GET":
            response = requests.get(url, params=payload)
        else:
            raise ValueError("Unsupported HTTP method.")
        return response.status_code, response.text
    except Exception as e:
        logging.error(f"Exception during API call to {endpoint}: {e}")
        return 500, str(e)

#################################
# 사용자 동작 실행
#################################
def simulate_user_action(user_id: str):
    try:
        logging.info(f"[{user_id}] Starting simulation.")
        session = requests.Session()
        current_state = "Anon_NotRegistered"
        transitions_count = 0
        while transitions_count < config.ACTIONS_PER_USER and current_state != "Done":
            next_state = pick_next_state(traffic_config.STATE_TRANSITIONS[current_state])
            logging.info(f"[{user_id}] Transitioning: {current_state} -> {next_state}")
            current_state = next_state
            time.sleep(random.uniform(*config.TIME_SLEEP_RANGE))
        logging.info(f"[{user_id}] Simulation completed.")
    except Exception as e:
        logging.error(f"[{user_id}] Simulation failed: {e}")

#################################
# 메인 실행
#################################
def main():
    fetch_products()
    fetch_categories()
    threads = []
    for i in range(config.NUM_USERS):
        user_id = f"user_{uuid.uuid4().hex[:6]}"
        thread = threading.Thread(target=simulate_user_action, args=(user_id,))
        threads.append(thread)
        thread.start()
        time.sleep(0.1)

    for thread in threads:
        thread.join()
    logging.info("All simulations completed.")

if __name__ == "__main__":
    main()
    print("Traffic generation completed. Check the log file for details.")
