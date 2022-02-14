FROM node:16.14.0-alpine as builder

ADD ./patch /opt/patch/

RUN apk add --no-cache git python3 python2 make g++ linux-headers zerotier-one &&\
    # 安装ztncui
    cd /opt && git clone --depth 1 https://github.com/key-networks/ztncui.git &&\
    cd ztncui/src && npm install -g node-gyp && npm install &&\
    cp -pv ./etc/default.passwd ./etc/passwd &&\
    echo 'HTTP_ALL_INTERFACES=true' > .env &&\
    echo 'NODE_ENV=production' >> .env &&\
    echo 'HTTP_PORT=3443' >> .env &&\
    rm -rf /opt/ztncui/.git &&\
    # 添加补丁
    cd /opt &&\
    git clone --depth 1 https://github.com/zerotier/ZeroTierOne.git &&\
    cd /var/lib/zerotier-one && \
    zerotier-idtool generate identity.public identity.secret &&\
    zerotier-idtool initmoon identity.public >> moon.json &&\
    cp /opt/patch/* . &&\
    python3 patch.py &&\
    zerotier-idtool genmoon moon.json &&\
    mkdir moons.d && cp ./*.moon ./moons.d &&\
    rm /opt/ZeroTierOne/attic/world/mkworld.cpp &&\
    cp mkworld.cpp /opt/ZeroTierOne/attic/world/ &&\
    cd /opt/ZeroTierOne/attic/world/ && \
    sh build.sh &&\
    cp ./world.bin /var/lib/zerotier-one/planet

FROM alpine
ADD ./run.sh /app/

VOLUME ["/var/lib/zerotier-one/"]
EXPOSE 3443 9993

RUN apk add --no-cache zerotier-one nodejs npm && mkdir -p /var/lib/zerotier

COPY --from=builder /var/lib/zerotier-one/moons.d /var/lib/zerotier/moons.d
COPY --from=builder /var/lib/zerotier-one/planet /var/lib/zerotier/planet
COPY --from=builder /opt/ztncui /opt/ztncui

WORKDIR /app/
CMD ["sh","./run.sh"]
