#!/bin/bash
#--------------
# 先决条件：登录控制面板设置
#		1. 添加一个UDP端口
#		2. 设置允许“运行自己的程序（Run your own applications）”
#--------------
# 定义UDP端口（留空则使用默认16000）
myport="16101"
# 定义UUID（留空则使用随机）
UUID=""
#================
UDP_PORT=${myport:-"16000"}
UUID=${UUID:-$(uuidgen)}
USERNAME=$(whoami)
HOSTNAME=$(hostname)
pkill -kill -u $USERNAME > /dev/null & sleep 1
echo "注销当前用户程序"
if [[ "$HOSTNAME" == "s1.ct8.pl" ]];then
	WORKDIR="${HOME}/domains/${USERNAME}.ct8.pl/app"
	Title="CT8-S1"
else
	WORKDIR="${HOME}/domains/${USERNAME}.serv00.net/app"
	Title=$(echo $HOSTNAME|awk -F'.' '{print $2"-"$1}'|sed 's/s/S/g')
fi
[ -d "$WORKDIR" ] || (mkdir -p "$WORKDIR" && chmod 755 "$WORKDIR")

cd $WORKDIR
if [ ! -f $WORKDIR/config.json ];then
	wget https://github.com/rtian002/app/releases/download/Singbox/app.tar.gz && tar -zxvf app.tar.gz -C ./ 
	sleep 1
fi

cp config.json config
sed -i '' "46s/16000/${UDP_PORT}/" config
sed -i '' "49s/ec97f674-c578-4940-9234-0a1da46041b9/${UUID}/" config
sleep 1
echo "已初始化程序配置。"
APPID="app-$(date +%s)"
mv app-* $APPID
nohup ./"$APPID" run -c config >/dev/null 2>&1 &
echo "程序已运行..."

get_ip() {
	ip=$(curl -s --max-time 2 ipv4.ip.sb)
	if [ -z "$ip" ]; then
		if [[ "$HOSTNAME" =~ s[0-9]\.serv00\.com ]]; then
			ip=${HOSTNAME/s/web}
		else
			ip="$HOSTNAME"
		fi
	fi
	echo $ip
}
HOST_IP=$(get_ip)
link="hysteria2://${UUID}@${HOST_IP}:${UDP_PORT}/?sni=www.bing.com&alpn=h3&insecure=1#${Title}%23${USERNAME}"
echo $link > ../logs/app.log

echo -e "\e[1;32m"
cat ../logs/app.log 
echo -e "\033[0m"


