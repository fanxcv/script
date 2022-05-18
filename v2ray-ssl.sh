#!/bin/bash
mkdir -p /etc/xray \
&& mkdir -p /etc/nginx/www \
&& (
cat <<EOF
{
  "log": {
    "loglevel": "error"
  },
  "dns": {
    "servers": ["8.8.8.8", "8.8.4.4", "1.1.1.1"]
  },
  "inbounds": [{
    "port": 80,
    "protocol": "vmess",
    "settings": {
      "clients": [{
        "id": "9d38ee36-e96d-11e8-9f32-f2801f1b9fd9",
        "alterId": 32
      }]
    },
    "streamSettings": {
      "network": "ws",
      "wsSettings": {
        "path": "/v2"
      }
    }
  }, {
    "port": 82,
    "protocol": "vless",
    "settings": {
      "decryption": "none",
      "clients": [{
        "id": "9d38ee36-e96d-11e8-9f32-f2801f1b9fd9"
      }]
    },
    "streamSettings": {
      "network": "ws",
      "wsSettings": {
        "path": "/vl"
      }
    }
  }, {
    "port": 86,
    "protocol": "vless",
    "settings": {
      "decryption": "none",
      "clients": [{
        "id": "9d38ee36-e96d-11e8-9f32-f2801f1b9fd9"
      }]
    },
    "streamSettings": {
      "network": "http",
      "security": "none",
      "httpSettings": {
        "host": ["shoutingtoutiao3.10010.com"],
        "path": "/h2"
      }
    }
  }, {
    "port": 88,
    "protocol": "vless",
    "settings": {
      "decryption": "none",
      "clients": [{
        "id": "9d38ee36-e96d-11e8-9f32-f2801f1b9fd9"
      }]
    },
    "streamSettings": {
      "network": "grpc",
      "security": "none",
      "grpcSettings": {
        "serviceName": "fan",
        "multiMode": true
      }
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  }]
}
EOF
) > /etc/xray/config.json &&
(
cat <<EOF
server {
    listen 80 default_server;
    server_name 127.0.0.1;

    rewrite ^(.*)\$ https://\$host\$1 permanent;

    #location / {
    #    proxy_pass http://172.88.8.1;
    #    proxy_set_header Host \$host;
    #    proxy_set_header X-Real-IP \$remote_addr;
    #    proxy_set_header REMOTE-HOST \$remote_addr;
    #    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    #}
}

server {
    listen      443 ssl http2 default_server;
    server_name 127.0.0.1;

    ssl_certificate       /etc/nginx/conf.d/ssl.pem;
    ssl_certificate_key   /etc/nginx/conf.d/ssl.key;
    ssl_protocols         TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers           HIGH:!aNULL:!MD5;
    ssl_session_timeout   60m;
    ssl_session_tickets   on;

    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;

    location /v2 {
        proxy_redirect off;
        proxy_pass http://172.88.8.8;
        proxy_set_header Connection "upgrade";
        proxy_set_header Upgrade    \$http_upgrade;
        proxy_set_header Host       \$host;
        proxy_http_version 1.1;
        proxy_read_timeout 1d;
    }

    location /vl {
        proxy_redirect off;
        proxy_pass http://172.88.8.8:82;
        proxy_set_header Connection "upgrade";
        proxy_set_header Upgrade    \$http_upgrade;
        proxy_set_header Host       \$host;
        proxy_http_version 1.1;
        proxy_read_timeout 1d;
    }
    
   location /fan {
        grpc_pass grpc://172.88.8.8:88;
        client_max_body_size 0;
        grpc_buffer_size 128M;
        grpc_read_timeout 1d;
        grpc_send_timeout 1d;
    }

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF
) > /etc/nginx/server.conf

wget -O /etc/nginx/www/index.html https://raw.githubusercontent.com/5iux/5iux.github.io/master/ip/index.html
wget -O /etc/nginx/www/logo.png https://raw.githubusercontent.com/5iux/5iux.github.io/master/ip/logo.png

# USER=5iux
# REPO=5iux.github.io
# VERSION=`wget -qO- -t1 -T2 "https://api.github.com/repos/$USER/$REPO/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g'`
# wget -O /etc/nginx/www/$VERSION.tar.gz https://github.com/$USER/$REPO/archive/refs/tags/$VERSION.tar.gz
# tar -xvf /etc/nginx/www/$VERSION.tar.gz -C /etc/nginx/www/ 
# rm -rf /etc/nginx/www/$VERSION.tar.gz

docker network create --subnet 172.88.0.0/16 fan

docker rm -f xray nginx
docker run -d --name xray -v /etc/xray:/etc/xray -e xray.vmess.aead.forced=false --net=fan --ip=172.88.8.8 --restart=always --privileged teddysun/xray
docker run -d --name nginx -p 80:80/tcp -p 443:443/tcp --net=fan --restart=always --privileged -v /etc/nginx/:/etc/nginx/conf.d/ -v /etc/nginx/www/:/var/www/html/ nginx:alpine
