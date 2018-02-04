#!/bin/bash
# Usage： bash xx.sh sentinelport masterip masterport masterpassword

if [ $# -ne 0 ]
then

	# 创建配置文件
	cd /alidata/redis
	cat > /alidata/redis/conf/sentinel${1}.conf << ENDF
port $1
dir /tmp
daemonize yes
logfile "/alidata/redis/log/sentinel${1}.log"
sentinel monitor mymaster $2 $3 1 
sentinel auth-pass mymaster $4
sentinel down-after-milliseconds mymaster 30000
sentinel parallel-syncs mymaster 1
sentinel failover-timeout mymaster 180000
ENDF
	ls -l /alidata/redis/conf
else
	echo  "Usage： bash xx.sh sentinelport masterip masterport masterpassword"
fi
