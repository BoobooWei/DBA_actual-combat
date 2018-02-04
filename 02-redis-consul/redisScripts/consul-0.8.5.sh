#!/bin/bash
# consul安装
masterip=$1
masterport=$2
masterpassword=$3
slaveip=$4
slaveport=$5

if [ $# -ne 0 ]
then
	# 创建软件目录
	mkdir -p /alidata/consul &> /dev/null 
	cd /alidata/consul &> /dev/null
	mkdir conf data &> /dev/null
	mkdir -p /alidata/install &> /dev/null
	cd /alidata/install

	# 下载软件并编译安装
	if [ `uname -m` == "x86_64" ];then
		wget https://releases.hashicorp.com/consul/0.8.5/consul_0.8.5_linux_amd64.zip?_ga=2.137222896.1530840127.1499765262-598930965.1499233390 -O consul_0.8.5_linux_amd64.zip
		unzip consul_0.8.5_linux_amd64.zip
	else
		wget https://releases.hashicorp.com/consul/0.8.5/consul_0.8.5_linux_386.zip?_ga=2.91175898.1530840127.1499765262-598930965.1499233390 -O consul_0.8.5_linux_386.zip
		unzip consul_0.8.5_linux_386.zip
	fi

	mv consul /bin

	# 创建配置文件
	cat > /alidata/consul/conf/redis.json << ENDF
{
    "services": [
        {
	    "id":"redisnode1",
            "name": "redis",
            "tags": [
                "master"
            ],
            "address": "${masterip}",
            "port": ${masterport},
    	    "checks": [
            {  
              "script": "redis-cli -h ${masterip} -p ${masterport} -a ${masterpassword} info | grep role:master || exit 2",
              "interval": "5s"
            }
          ]
        },
        {
	    "id":"redisnode2",
            "name": "redis",
            "tags": [
                "master"
            ],
            "address": "${slaveip}",
            "port": ${slaveport},
    	    "checks": [
            {  
              "script": "redis-cli -h ${slaveip} -p ${slaveport} -a ${masterpassword} info | grep role:master || exit 2",
              "interval": "5s"
            }
          ]
        }
    ]
}
ENDF



	# 检查安装结果
	which consul
	ls -l /alidata/consul;ls -l /alidata/consul/conf
	# 绑定dns 53号端口
	yum install -y bind bind-chroot
	sed -i 's/{ .*; };/{ any; };/' /etc/named.conf
	sed -i 's/dnssec-enable yes;/dnssec-enable no;/' /etc/named.conf
	sed -i 's/dnssec-validation yes;/dnssec-validation no;/' /etc/named.conf
	cat >> /etc/named.conf << ENDF
zone "consul" IN {
	type forward;
  	forward only;
  	forwarders { 127.0.0.1 port 8600; };
};
ENDF
	if cat /etc/redhat-release | grep '6' &> /dev/null;then
		service named restart
	else
		systemctl restart named
	fi
	sed -i 's/\(.*\)/#\1/' /etc/resolv.conf
	sed -i 'anameserver 127.0.0.1' /etc/resolv.conf
else
	echo "Usage： bash consul-0.8.5.sh masterip masterport masterpassword slaveip slaveport"

fi

	# 启动服务
#	nohup /bin/consul agent -dev  -config-dir=/alidata/consul/conf &> /alidata/consul/consul.log &
#	dig redis.service.consul.
