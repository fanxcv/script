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
) > /etc/v2ray/config.json 

docker run -d --name v2ray -v /etc/v2ray:/etc/v2ray --net=host --restart=always --privileged v2ray/official v2ray -config=/etc/v2ray/config.json
