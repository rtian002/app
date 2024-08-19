#!/usr/bin/bash
#--------------20240819
# 先决条件：登录控制面板设置
#  1. 添加一个UDP端口
#  2. 设置允许“运行自己的程序（Run your own applications）”
#--------------
UDP_PORT="16100"	# 定义UDP端口
UUID="8fd27963-5dbb-11ef-996c-6cb311233542"		# 定义UUID（留空则使用随机）
#================
[ "$#" -gt 0 ] && UDP_PORT=$1
[ "$#" -eq 2 ] && UUID=$2
USERNAME=$(whoami)
HOSTNAME=$(hostname)
if [[ "$HOSTNAME" == "s1.ct8.pl" ]];then
	WORKDIR="${HOME}/domains/${USERNAME}.ct8.pl/app"
	Server="CT8-S1"
else
	WORKDIR="${HOME}/domains/${USERNAME}.serv00.net/app"
	Server=$(echo $HOSTNAME|awk -F'.' '{print $2"-"$1}'|sed 's/s/S/g')
fi
[ -d "$WORKDIR" ] || (mkdir -p "$WORKDIR" && chmod 755 "$WORKDIR")
#====================================================================
pkill -kill -u $USERNAME > /dev/null 2>&1
cd $WORKDIR
if [ ! -f $WORKDIR/config.json ];then
  wget http://appstores.ct8.pl/app.tar.gz && tar -zxvf app.tar.gz -C ./ 
  sleep 1
  UUID=${UUID:-$(uuidgen)}
  cp config.json config
  [ -n $UDP_PORT ] && sed -i '' "46s/16000/${UDP_PORT}/" config
  sed -i '' "49s/ec97f674-c578-4940-9234-0a1da46041b9/${UUID}/" config
else
  [ "$#" -gt 0 ] && sed -i '' "46s/[0-9]\{1,5\}/${UDP_PORT}/" config
fi
#-----------------------
APPID="app-$(date +%s)"
mv app-* $APPID
nohup ./"$APPID" run -c config >/dev/null 2>&1 &
echo "${APPID}: 新程序已运行..."
#=========================================
UUID=$(awk -F'"' 'NR==49 {print $4}' config)
HOST_IP=$(curl -s --max-time 2 ipv4.ip.sb)
link="hysteria2://${UUID}@${HOST_IP}:${UDP_PORT}/?sni=www.bing.com&alpn=h3&insecure=1#${Server}%23${USERNAME}"
echo $link > ../logs/app.log
echo -e "\e[1;32m"
cat ../logs/app.log 
echo -e "\033[0m"

appstatus=$(pgrep app-)
if [ $appstatus ];then
  sed -i '' "7s/\".*\"/\"${UDP_PORT}\"/" ~/$0
  sed -i '' "8s/\".*\"/\"${UUID}\"/" ~/$0
fi
