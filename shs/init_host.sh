#
#       @Install ShadowSock batch
#       @Author: Lijun Ye
#       @Email: yelijuns@gmail.com
#       @Copyright lovelake
#       @Create time 2016-04-14
#       @Last modify time 2016-04-16
#

#!/bin/sh

menu() {
cat <<EOF
#####################################################################
#                                                                   #
#    1. Generate SSH Keys (Optional)                                #
#    2. Install ShadowSocks                                         #
#    3. Base settings, Timezone, group user, etc.                   #
#    4. Optimate the system for SS                                  #
#    5. Install ServerSpeeder for optimate the speed (Optional)     #
#    6. Deploy Alass                                                #
#    7. Set the root Password (Optional)                            #
#    8. Set the alass Password (Optional)                           #
#    9. Change the host name                                        #
#    q. Quit                                                        #
#                                                                   #
#####################################################################
EOF
}

prefixUri=https://raw.githubusercontent.com/lijiajun/alafafa/master/shs/
aliasWget='wget -N --no-check-certificate'
generateSSHKey() {
	curPath=`pwd`
	generateCFile="$curPath/generateSSH"
	echo $generateCFile
	if [ ! -e $generateCFile ]; then
		${aliasWget} "${prefixUri}generateSSH" -O ${generateCFile}
		chmod +x $generateCFile
	fi
	
	# Run the generateSSH
	$generateCFile
	
	echo "############## SSH keys has been generated #################"
	echo ""
}

installSS() {
	yum -y install python-setuptools
	easy_install pip
	
	pip install shadowsocks
	ln -s /usr/bin/ssserver /usr/local/bin/ssserver
	
	echo "############## ShadowSocks has been installed #################"
	echo ""
}

setChinaTimezone() {
	# Default the zoneinfo as the Shanghai China
	if [ "$1" -eq "Asia/Shanghai" ];
	then
		zoneinfoFile=/usr/share/zoneinfo/Asia/Shanghai
		if [ -e ${zoneinfoFile} ];
		then
			cp ${zoneinfoFile} /etc/localtime
		else
			echo "Zoneinfo File Does not exist"
		fi
	else
		# CentOS
		tzselect
	fi
}

groupAlassAdd() {
	groupExist=`cat /etc/group | grep alass | grep -v grep | wc -l`
	# Different operator system by using the different method, Linux BSD,etc.
	# If the group alass does not exist
	if [ $groupExist -eq 0 ];
	then
		groupadd alass
	fi
}

userAlassAdd() {
	userExist=`cat /etc/passwd | grep alass | grep -v grep | wc -l`
	# Different operator system by using the different method, Linux BSD,etc.
	# If the user alass does not exist
	if [ $userExist -eq 0 ];
	then
		useradd -g alass alass
	fi
}

baseSettings() {
	z=Asia/Shanghai
	read -p "Input the zoneinfo, [Asia/Shanghai]" zi
	if [ !-z $z ];
	then
		z=$zi
	fi
	setChinaTimezone $z
	
	groupAlassAdd
	userAlassAdd
	echo "############## Base settings has been set, (Timezone, user and Group) #################"
	echo ""
}

optimateForSS() {
	# For enter os 6.7
	# cat /etc/issue | grep release | awk '{print $3}'
echo '# max open files
fs.file-max = 51200
# max read buffer
net.core.rmem_max = 67108864
# max write buffer
net.core.wmem_max = 67108864
# default read buffer
net.core.rmem_default = 65536
# default write buffer
net.core.wmem_default = 65536
# max processor input queue
net.core.netdev_max_backlog = 4096
# max backlog
net.core.somaxconn = 4096

# resist SYN flood attacks
net.ipv4.tcp_syncookies = 1
# reuse timewait sockets when safe
net.ipv4.tcp_tw_reuse = 1
# turn off fast timewait sockets recycling
net.ipv4.tcp_tw_recycle = 0
# short FIN timeout
net.ipv4.tcp_fin_timeout = 30
# short keepalive time
net.ipv4.tcp_keepalive_time = 1200
# outbound port range
net.ipv4.ip_local_port_range = 10000 65000
# max SYN backlog
net.ipv4.tcp_max_syn_backlog = 4096
# max timewait sockets held by system simultaneously
net.ipv4.tcp_max_tw_buckets = 5000
# turn on TCP Fast Open on both client and server side
net.ipv4.tcp_fastopen = 3
# TCP receive buffer
net.ipv4.tcp_rmem = 4096 87380 67108864
# TCP write buffer
net.ipv4.tcp_wmem = 4096 65536 67108864
# turn on path MTU discovery
net.ipv4.tcp_mtu_probing = 1

# for high-latency network
net.ipv4.tcp_congestion_control = hybla

# for low-latency network, use cubic instead
# net.ipv4.tcp_congestion_control = cubic' > /etc/sysctl.conf

	sysctl -p
	
echo 'alass soft nproc 16384
alass hard nproc 16384
alass soft nofile 65536
alass hard nofile 65536
alass soft memlock 4000000
alass hard memlock 4000000' >> /etc/security/limits.conf

	echo "############## Optimate the server finished #################"
	echo ""
}

installServerSpeeder() {
	${aliasWget} -N --no-check-certificate https://raw.githubusercontent.com/91yun/serverspeeder/master/serverspeeder-all.sh && bash serverspeeder-all.sh && chkconfig --add serverSpeeder && chkconfig serverSpeeder on
	echo "############## Server Speeder has been installed #################"
	echo ""
}

downloadShFile() {
	# $0: fileName
	shFileName=$1
	basePath=/home/alass/
	shPath=${basePath}maintain/shs/
	prefixUri=https://raw.githubusercontent.com/lijiajun/alafafa/master/shs/
	if [ ! -e ${shPath}${shFileName} ];
	then
		${aliasWget} ${prefixUri}$1 -O ${shPath}${shFileName}
	else
		echo "${shFileName} has exist"
	fi;
}

deployAlass() {
	basePath=/home/alass/
	shPath=${basePath}maintain/shs/
	prefixUri=https://raw.githubusercontent.com/lijiajun/alafafa/master/shs/
	mkdir -p $shPath

	downloadShFile "check_sss.sh"
	downloadShFile "reset_test_sss.sh"
	downloadShFile "start_sss.sh"
	downloadShFile "stop_sss.sh"

	c=`cat /etc/crontab | grep check_sss.sh | grep -v grep | wc -l`
	if [ $c -eq 0 ];
	then
		echo "*/2     *       *       *       *       alass   /bin/sh ${shPath}check_sss.sh" >> /etc/crontab
	fi
	
	c=`cat /etc/crontab | grep reset_test_sss.sh | grep -v grep | wc -l`
	if [ $c -eq 0 ];
	then
		echo "*/2     *       *       *       *       alass   /bin/sh ${shPath}reset_test_sss.sh" >> /etc/crontab
	fi

	ssPath=${basePath}shadowsocks/
	mkdir -p ${ssPath}logs
	
	groupAlassAdd
	userAlassAdd
	
	chown -R alass:alass ${basePath}maintain
	chmod +x ${shPath}*.sh
	chown -R alass:alass $ssPath
	
	tpl=/tmp/chg_test_pswd_mail.txt
	if [ ! -e ${tpl} ];
	then
		touch ${tpl} && chown alass:alass ${tpl}
	fi

	echo "############## Deploy Alass Finished #################"
	echo ""
}

changeHostName() {
	read -p "Input new hostname: " hostname
	# Tempory change the hostname
	hostname $hostname
	
	# Permenently change the hostname
	# It will effect after operator system reboot
	sed -i "s/hostname.*/HOSTNAME=${hostname}/Ig" /etc/sysconfig/network
	
	echo "############## Hostname has been changed to ${hostname} #################"
	echo ""
}

run() {
	menu
	while true
	do
		read -p "Choose the step:" ch
		case $ch in
			1)
				generateSSHKey
			;;
			2)
				installSS
			;;
			3)
				baseSettings
			;;
			4)
				optimateForSS
			;;
			5)
				installServerSpeeder
			;;
			6)
				deployAlass
			;;
			7)
				passwd root
			;;
			8)
				userExist=`cat /etc/passwd | grep alass | grep -v grep | wc -l`
				# If the user alass does not exist
				if [ $userExist -ge 1 ];
				then
					passwd alass
				else
					echo "Alass user does not exist!"
				fi
			;;
			9)
				changeHostName
			;;
			q)
				echo 'Exit the settings!'
				exit
			;;
		esac
		menu
	done
}

# Run the batch
run