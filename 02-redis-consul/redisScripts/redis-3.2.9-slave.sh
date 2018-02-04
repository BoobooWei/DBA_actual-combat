#!/bin/bash

# redis slave 单实例安装
# Usage： bash redis-3.2.9-slave.sh 172.25.0.12 6379 172.25.0.11 6379 zyadmin #配置1个slave实例，监听端口为6379,masterip为172.25.0.11，port：6379 master 密码为zyadmin

if [ $# -ne 0 ]
then
	# 创建软件目录
	mkdir -p /alidata/redis &> /dev/null
	cd /alidata/redis &> /dev/null
	mkdir conf data log pid &> /dev/null
	mkdir -p /alidata/install &> /dev/null
	cd /alidata/install

        # 下载软件并编译安装
        if [ ! -f /alidata/redis/src/redis-server ]
        then
                wget http://download.redis.io/releases/redis-3.2.9.tar.gz
                tar -xf redis-3.2.9.tar.gz
                cd redis-3.2.9
                make && make install
                mv /alidata/install/redis-3.2.9/* /alidata/redis
        fi

	# 创建配置文件

	mip=$3
	mport=$4
	mpassword=$5
	i=$2

	cd /alidata/redis
	mkdir data/$i
	grep -v '^#\|^$' redis.conf > /alidata/redis/conf/redis${i}.conf
	sed -i 's/daemonize no/daemonize yes/' /alidata/redis/conf/redis${i}.conf
	sed -i '/^bind/d' /alidata/redis/conf/redis${i}.conf
	sed -i "1ibind $1 127.0.0.1" /alidata/redis/conf/redis${i}.conf
	sed -i 's/appendonly no/appendonly yes/' /alidata/redis/conf/redis${i}.conf
	sed -i "s/port.*/port $i/" /alidata/redis/conf/redis${i}.conf
	sed -i "s@dir.*@dir \/alidata\/redis\/data\/${i}@" /alidata/redis/conf/redis${i}.conf 
	sed -i "s@pid.*@pidfile \/alidata\/redis\/pid\/redis${i}.pid@" /alidata/redis/conf/redis${i}.conf
	sed -i "s@logfile.*@logfile \/alidata\/redis\/log\/redis${i}.log@" /alidata/redis/conf/redis${i}.conf
	sed -i "21islaveof ${mip} ${mport}" /alidata/redis/conf/redis${i}.conf
	sed -i "22imasterauth ${mpassword}" /alidata/redis/conf/redis${i}.conf
	sed -i "23irequirepass ${mpassword}" /alidata/redis/conf/redis${i}.conf


	# 优化路径和命令
	if ! cat /etc/profile | grep "export PATH=\$PATH:/alidata/redis/src" &> /dev/null;then
		echo "export PATH=\$PATH:/alidata/redis/src" >> /etc/profile
	fi
	source /etc/profile

	# 检查安装结果
	which redis-server
	which redis-cli
	ls -l /alidata/redis;ls -l /alidata/redis/conf

else
	echo "Usage： bash redis-3.2.9-slave.sh 172.25.0.12 6379 172.25.0.11 6379 zyadmin #配置1个slave实例，监听端口为6379,masterip为172.25.0.11>，port：6379 master 密码为zyadmin"
fi
