#!/bin/bash
yum -y install docker && systemctl start docker && mkdir -p /etc/v2ray && 
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
        "network":"ws"
      }
    },
    {
      "tag": "tg-in",
      "port": 5432,
      "protocol": "mtproto",
      "settings": {
        "users": [
          {
            "secret": "ee07dda1deb56c761dc7116eb3ae8716"
          }
        ]
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "tag": "tg-out",
      "protocol": "mtproto",
      "settings": {}
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "inboundTag": [
          "tg-in"
        ],
        "outboundTag": "tg-out"
      }
    ]
  },
  "dns": {
    "hosts": {
    },
    "servers": [
      "8.8.8.8",
      "1.1.1.1"
    ]
  }
}
EOF
) > /etc/v2ray/config.json 

docker run -d --name v2ray -v /etc/v2ray:/etc/v2ray -p 80:80/tcp -p 5432:5432/tcp v2ray/official v2ray -config=/etc/v2ray/config.json
