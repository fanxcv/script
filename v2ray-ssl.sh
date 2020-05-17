#!/bin/bash
yum -y install docker && systemctl start docker && mkdir -p /etc/v2ray && mkdir -p /etc/nginx &&
(
cat <<EOF
{
  "log": {
    "loglevel": "error"
  },
  "inbounds": [
    {
      "port": 80,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "9d38ee36-e96d-11e8-9f32-f2801f1b9fd9",
            "alterId": 32
          }
        ]
      },
      "streamSettings": {
        "network":"ws",
    "security": "none",
    "wsSettings": {
      "path": "/v2",
      "headers": {}
    }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ],
  "routing": {
    "rules": []
  },
  "dns": {
    "hosts": {
    },
    "servers": [
      "8.8.8.8",
      "8.8.4.4"
    ]
  }
}
EOF
) > /etc/v2ray/config.json &&
(
cat <<EOF
server {
    listen 80;
    server_name $1;
    rewrite ^(.*) https://\$server_name\$1 permanent;
}

server {
    listen 443 ssl;
    
    ssl on;                                                         
    ssl_certificate       /etc/nginx/conf.d/ssl.pem;  
    ssl_certificate_key   /etc/nginx/conf.d/ssl.key;
    ssl_protocols         TLSv1 TLSv1.1 TLSv1.2;                    
    ssl_ciphers           HIGH:!aNULL:!MD5;

    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;
    server_name $1;
    location / {
        try_files \$uri \$uri/ =404;
    }

    location /v2 {
        proxy_redirect off;
        proxy_pass http://172.88.8.8:80;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_read_timeout 300s;
    }
}
EOF
) > /etc/nginx/server.conf

docker network create --subnet 172.88.0.0/16 fan

docker run -d --name v2ray -v /etc/v2ray:/etc/v2ray --net=fan --ip=172.88.8.8 --restart=always --privileged v2ray/official
docker run -d --name nginx -p 80:80/tcp -p 443:443/tcp --net=fan --restart=always --privileged -v /etc/nginx/:/etc/nginx/conf.d/ nginx
