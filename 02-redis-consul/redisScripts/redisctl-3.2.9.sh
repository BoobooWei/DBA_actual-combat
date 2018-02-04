#!/bin/bash
#Usage: redisctl start|stop|status port num
# redisctl start 6379 

start_sentinel(){
	nohup /alidata/redis/src/redis-sentinel /alidata/redis/conf/sentinel${1}.conf &> /tmp/sentinel.log &
}

# 启动单实例
start_redis(){
	nohup /alidata/redis/src/redis-server /alidata/redis/conf/redis${1}.conf &> /dev/null &
}

# 查看所有实例的守护进程
status_redis(){
count=`ps -ef|grep "redis-server" | grep -v 'grep'|wc -l`
if [[ $count == 1 ]] ;then echo redis server is running ;else echo redis server is not running;fi
}

# 停止所有实例
stop_redis(){
for i in `ps -ef|grep "redis-server" | grep -v 'grep' | awk '{print $2}'`
do
	kill -9 $i
done
}

case $1 in
sentinel)
	start_sentinel $2;;
start)
	start_redis $2;;
status)
	status_redis;;
stop)
	stop_redis;;
restart)
	stop_redis;
	start_redis $2;;
*)
	echo "Usage: redisctl start|stop|status|restart|sentinel port "
esac
