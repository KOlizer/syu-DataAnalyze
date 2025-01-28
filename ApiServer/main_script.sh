#!/bin/bash

echo "MYSQL_HOST set to: $MYSQL_HOST"
source /home/ubuntu/.bashrc

# 전역 변수 초기화
LOG_PREFIX="kakaocloud: "
LOG_COUNTER=0

# 로깅 함수 정의
log() {
    LOG_COUNTER=$((LOG_COUNTER + 1))
    echo "${LOG_PREFIX}${LOG_COUNTER}. $1"
}

# 명령 실행 및 상태 확인 함수
run_command() {
    "$@"
    if [ $? -eq 0 ]; then
        log "$1 succeeded."
    else
        log "Error: $1 failed."
        exit 1
    fi
}


# 3. Flask 애플리케이션 설정
APP_DIR="/var/www/flask_app"
API_SERVER_RAW_URL="https://raw.githubusercontent.com/KOlizer/syu-DataAnalyze/refs/heads/main/ApiServer/Api_server.py"

log "Setting up Flask application in $APP_DIR..."
run_command mkdir -p "$APP_DIR"

# GitHub에서 app.py(= Api_server.py) 파일 다운로드
log "Downloading Flask app (app.py) from GitHub..."
run_command wget -O "$APP_DIR/app.py" "$API_SERVER_RAW_URL"

# 혹시 필요하다면 권한/소유자 설정(옵션)
# run_command chown -R ubuntu:www-data "$APP_DIR"
# run_command chmod -R 755 "$APP_DIR"

log "Flask application setup completed successfully."

# 4. 워커 및 스레드 개수 계산
log "Calculating Gunicorn workers and threads..."
CPU_CORES=$(nproc)
WORKERS=$((CPU_CORES * 2 + 1))  # 공식: (코어 수 * 2) + 1
THREADS=4                       # 스레드 기본값 (I/O 바운드 환경)
log "Detected $CPU_CORES CPU cores: setting $WORKERS workers and $THREADS threads."

# 5. Gunicorn 서비스 파일 생성
log "Creating Gunicorn service..."

LOG_FORMAT_NAME="custom_json"

cat > /etc/systemd/system/flask_app.service <<EOL
[Unit]
Description=Gunicorn instance to serve Flask app
After=network.target

[Service]
User=ubuntu
Group=www-data
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/gunicorn --workers $WORKERS --threads $THREADS -b 127.0.0.1:8080 app:app

[Install]
WantedBy=multi-user.target
EOL

run_command systemctl daemon-reload
run_command systemctl enable flask_app
run_command systemctl start flask_app

# Nginx 설정
NGINX_CONF_MAIN="/etc/nginx/nginx.conf"

if ! grep -q "log_format $LOG_FORMAT_NAME" $NGINX_CONF_MAIN; then
    echo "Adding custom_json log format to NGINX configuration..."
    sed -i "/http {/a \
        log_format $LOG_FORMAT_NAME escape=json '{\\n\
            \"timestamp\":\"\$time_local\",\\n\
            \"remote_addr\":\"\$remote_addr\",\\n\
            \"request\":\"\$request\",\\n\
            \"status\":\"\$status\",\\n\
            \"body_bytes_sent\":\"\$body_bytes_sent\",\\n\
            \"http_referer\":\"\$http_referer\",\\n\
            \"http_user_agent\":\"\$http_user_agent\",\\n\
            \"session_id\":\"\$cookie_session_id\",\\n\
            \"user_id\":\"\$cookie_user_id\",\\n\
            \"request_time\":\"\$request_time\",\\n\
            \"upstream_response_time\":\"\$upstream_response_time\",\\n\
            \"endpoint\":\"\$uri\",\\n\
            \"method\":\"\$request_method\",\\n\
            \"query_params\":\"\$args\",\\n\
            \"product_id\":\"\$arg_id\",\\n\
            \"category\":\"\$arg_name\",\\n\
            \"x_forwarded_for\":\"\$http_x_forwarded_for\",\\n\
            \"host\":\"\$host\"\\n\
        }';" $NGINX_CONF_MAIN
    echo "custom_json log format added successfully."
else
    echo "custom_json log format already exists. Skipping addition."
fi

NGINX_CONF="/etc/nginx/sites-available/flask_app"
cat > "$NGINX_CONF" <<EOL
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    error_log /var/log/nginx/flask_app_error.log;
    access_log /var/log/nginx/flask_app_access.log $LOG_FORMAT_NAME;
}
EOL

run_command ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/
run_command rm -f /etc/nginx/sites-enabled/default

run_command nginx -t
run_command systemctl restart nginx

log "Setup complete. Flask application is running with Gunicorn and Nginx."
echo "You can access your application at http://<your_server_ip>/"
