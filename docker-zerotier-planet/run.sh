#!/bin/sh
echo "开始执行"
count=`ls /var/lib/zerotier-one | wc -w`
if [ "$count" == "0" ];then
 cp /var/lib/zerotier/* /var/lib/zerotier-one -R
 echo "复制文件到相关目录"
fi

zerotier-one -d 

cd /opt/ztncui/src
npm start
