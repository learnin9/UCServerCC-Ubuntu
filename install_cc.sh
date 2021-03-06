#!/bin/bash
#downloadmirror=http://download1.astercc.org
#downloadmirror=http://astercc.org/download
#downloadmirror=http://download3.astercc.org

function apt_install(){
	apt-get -y update
	apt-get -y remove php* 
	apt-get -y remove asterisk*
	apt-get -y install patch libxml++2.6-dev python-software-properties  openvpn software-properties-common unzip bzip2 postfix ncurses-dev hylafax-client hylafax-server iaxmodem cron  libncurses5-dev libncurses5 build-essential sox  make bison flex libssl-dev unzip libpcre3 libpcre3-dev unzip make sysv-rc-conf
	add-apt-repository -y ppa:ondrej/php5
	add-apt-repository -y ppa:ondrej/mysql-5.6
	apt-get -y install mysql-server mysql-client
	apt-get update
	apt-get -y linux-image-$(uname -r)
	apt-get -y sudo
	service cron start
	update-rc.d cron defaults
	udevadm trigger --sysname-match=null
	#build-essential linux-source linux-image-$(uname -r) libpcre3 libpcre3-dev 
}

function ioncube_install(){
	echo -e "\e[32mStarting Install ioncube\e[m"
	cd /usr/src
        bit=`getconf LONG_BIT`
        if [ $bit == 32 ]; then
		if [ ! -e ./ioncube_loaders_lin_x86.tar.gz ]; then
			wget $downloadmirror/ioncube_loaders_lin_x86.tar.gz
		fi
		tar zxf ioncube_loaders_lin_x86.tar.gz
	else
		if [ ! -e ./ioncube_loaders_lin_x86-64.tar.gz ]; then
			wget $downloadmirror/ioncube_loaders_lin_x86-64.tar.gz
		fi
		tar zxf ioncube_loaders_lin_x86-64.tar.gz
	fi
	mv /usr/src/ioncube /usr/local/
	sed -i "/ioncube/d"  /etc/php5/fpm/php.ini
	echo "zend_extension = /usr/local/ioncube/ioncube_loader_lin_5.5.so" >> /etc/php5/fpm/php.ini

	sed -i "/ioncube/d"  /etc/php5/cli/php.ini
	echo "zend_extension = /usr/local/ioncube/ioncube_loader_lin_5.5.so" >> /etc/php5/cli/php.ini
	service php5-fpm restart
	echo -e "\e[32mIoncube Install OK!\e[m"

}

function php_install(){
	echo -e "\e[32mStarting Install PHP-Fpm\e[m"
	apt-get -y  --force-yes install php5-dev php5-cli php5-common php5-fpm php5-cgi php5-mysql php5-gd php5-redis php5-curl php5-readline
	mkdir -p /var/log/php-fpm
	sed -i "s/short_open_tag = Off/short_open_tag = On/" /etc/php5/fpm/php.ini
	sed -i "s/memory_limit = 16M /memory_limit = 128M /" /etc/php5/fpm/php.ini
	sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 20M /" /etc/php5/fpm/php.ini
	sed -i "s/post_max_size = 8M/post_max_size = 20M/" /etc/php5/fpm/php.ini
	sed -i '/^error_reporting/c error_reporting = E_ALL & ~E_DEPRECATED' /etc/php5/fpm/php.ini
	sed -i "s/user = www-data/user = asterisk/" /etc/php5/fpm/pool.d/www.conf
	sed -i "s/group = www-data/group = asterisk/" /etc/php5/fpm/pool.d/www.conf
	sed -i "s/listen = \/var\/run\/php5-fpm.sock/listen = 127.0.0.1:9000/" /etc/php5/fpm/pool.d/www.conf
	update-rc.d php5-fpm defaults
	echo -e "\e[32mPHP-Fpm Install OK!\e[m"
}

function redis_install(){
	echo -e "\e[32mStarting Install Redis 3.0.6\e[m"
	cd /usr/src
	if [ ! -e ./redis-3.0.6.tar.gz ]; then
		wget $downloadmirror/redis-3.0.6.tar.gz
	fi
	tar -xvzf redis-3.0.6.tar.gz
	cd redis-3.0.6
	make
	make install
	bash ./utils/install_server.sh
	mv /etc/init.d/redis_6379 /etc/init.d/redis
	sysv-rc-conf redis on
	sed -i "s/# bind 127.0.0.1/bind 127.0.0.1/" /etc/redis/6379.conf
	service redis restart
	echo -e "\e[32redis Install OK!\e[m"
}
function php5_redis_install(){
	echo "\e[32mStarting Install php5-redis\e[m"
	cd /usr/src
	git clone https://github.com/phpredis/phpredis
	cd phpredis
	/usr/bin/phpize
	./configure --with-php-config=/usr/bin/php-config
	make
	make install
cat > /etc/php5/mods-available/redis.ini << EOF
extension="redis.so"
EOF
}
function mpg123_install(){
	echo -e "\e[32mStarting Install MPG123\e[m"
	cd /usr/src
	if [ ! -e ./mpg123-$mpg123ver.tar.bz2 ]; then
		wget http://sourceforge.net/projects/mpg123/files/mpg123/$mpg123ver/mpg123-$mpg123ver.tar.bz2/download -O mpg123-$mpg123ver.tar.bz2
	fi
	tar jxf mpg123-$mpg123ver.tar.bz2
	cd mpg123-$mpg123ver
	./configure
	make
	make install
	echo -e "\e[32mMPG123 Install OK!\e[m"

}

function dahdi_install() {
	echo -e "\e[32mStarting Install DAHDI\e[m"
	cd /usr/src
	if [ ! -e ./dahdi-linux-complete-$dahdiver.tar.gz ]; then
		wget $downloadmirror/dahdi-linux-complete-2.10.2.tar.gz
	fi
	tar zxf dahdi-linux-complete-2.10.2.tar.gz
	if [ $? != 0 ]; then
		echo -e "fatal: dont have valid dahdi tar package\n"
		exit 1
	fi

	cd dahdi-linux-2.10.2
	make
	if [ $? != 0 ]; then
		apt-get -y upgrade;
		echo -e "\e[32mplease reboot your server and run this script again\e[m\n"
		exit 1;
	fi
	make install
	make config
	/usr/sbin/dahdi_genconf
  echo "blacklist netjet" >> /etc/modprobe.d/dahdi.blacklist.conf
	/etc/init.d/dahdi start
	echo -e "\e[32mDAHDI Install OK!\e[m"
}

function nginx_install(){
	echo -e "\e[32mStarting install nginx\e[m"
	service apache2 stop
	sysv-rc-conf apache2 off
	cd /usr/src
	if [ ! -e ./nginx-$nginxver.tar.gz ]; then
		wget $downloadmirror/nginx-$nginxver.tar.gz
	fi
	tar zxf nginx-$nginxver.tar.gz
	if [ $? != 0 ]; then
		echo -e "fatal: dont have valid nginx tar package\n"
		exit 1
	fi

	if [ ! -e ./nginx-push-stream-module-master-20130206.tar.gz ]; then
		wget $downloadmirror/nginx-push-stream-module-master-20130206.tar.gz
	fi
	
	tar zxf nginx-push-stream-module-master-20130206.tar.gz
	if [ $? != 0 ]; then
		echo -e "fatal: dont have valid nginx push tar package\n"
		exit 1
	fi

	cd nginx-$nginxver
	./configure --add-module=/usr/src/nginx-push-stream-module-master --with-http_ssl_module  --user=asterisk --group=asterisk
	make
	make install
	cd /usr/src
	wget $downloadmirror/nginx.ubuntu.zip -t 5
	unzip ./nginx.ubuntu.zip
	mv ./nginx /etc/init.d/
	chmod +x /etc/init.d/nginx
	sysv-rc-conf nginx on
	echo -e "\e[32mNginx Install OK!\e[m"
}

function asterisk_install() {
	echo -e "\e[32mStarting Install Asterisk\e[m"
	#Define a user called asterisk.
	useradd -u 500 -c "Asterisk PBX" -d /var/lib/asterisk asterisk
	mkdir /var/run/asterisk /var/log/asterisk
	chown asterisk:asterisk /var/run/asterisk /var/log/asterisk /var/lib/php5 -R

	cd /usr/src
	if [ ! -e ./asterisk-$asteriskver.tar.gz ]; then
		wget $downloadmirror/asterisk-$asteriskver.tar.gz
	fi
	tar zxf asterisk-$asteriskver.tar.gz
	if [ $? != 0 ]; then
		echo "fatal: dont have valid asterisk tar package"
		exit 1
	fi

	cd asterisk-$asteriskver
	if [ ! -e ./no-ssl3-method.patch ]; then
		wget $downloadmirror/no-ssl3-method.patch
	fi
	patch main/tcptls.c <no-ssl3-method.patch 
	./configure '-disable-xmldoc'
	make
	make install
	make samples
	#This command will  install the default configuration files.
	#make progdocs
	#This command will create documentation using the doxygen software from comments placed within the source code by the developers. 
	make config
	#This command will install the startup scripts and configure the system (through the use of the chkconfig command) to execute Asterisk automatically at startup.
	sed -i "s/#AST_USER/AST_USER/" /etc/init.d/asterisk
	sed -i "s/#AST_GROUP/AST_GROUP/" /etc/init.d/asterisk

	sed -i 's/;enable=yes/enable=no/' /etc/asterisk/cdr.conf

	# set AMI user
cat > /etc/asterisk/manager.conf << EOF
[general]
enabled = yes
port = 5038
bindaddr = 0.0.0.0
displayconnects=no

[asterccuser]
secret = asterccsecret
deny=0.0.0.0/0.0.0.0
permit=127.0.0.1/255.255.255.0
read = system,call,agent
write = all
EOF

	service asterisk restart
	sysv-rc-conf asterisk on
	echo -e "\e[32mAsterisk Install OK!\e[m"
}


function lame_install(){
	echo -e "\e[32mStarting Install Lame for mp3 monitor\e[m"
	apt-get -y install lame
	return 0
	cd /usr/src
	if [ ! -e ./lame-$lamever.tar.gz ]; then
		wget http://sourceforge.net/projects/lame/files/lame/$lamever/lame-$lamever.tar.gz/download  -O lame-$lamever.tar.gz
	fi
	tar zxf lame-$lamever.tar.gz
	if [ $? != 0 ]; then
		echo -e "\e[32mdont have valid lame tar package, you may lose the feature to check recordings on line\e[m\n"
		return 1
	fi

	cd lame-$lamever
	./configure && make && make install
	if [ $? != 0 ]; then
		echo -e "\e[32mfailed to install lame, you may lose the feature to check recordings on line\e[m\n"
		return 1
	fi
	ln -s /usr/local/bin/lame /usr/bin/
	echo -e "\e[32mLame install OK!\e[m"
	return 0;
}

function UI() {
	mkdir -p /usr/src/UI
	cd /usr/src/UI
	echo "Start setting UCServer UI"
	wget http://downcc.ucserver.org:8082/Files/UCS-UI.tar.gz
	wget http://downcc.ucserver.org:8082/Files/update.sh
	bash /usr/src/UI/update.sh
	rm -rf /usr/src/UI
}

function libpri_install() {
	echo -e "\e[32mStarting Install LibPRI\e[m"
	cd /usr/src
	if [ ! -e ./libpri-$libpriver.tar.gz ]; then
		wget $downloadmirror/libpri-$libpriver.tar.gz
	fi
	tar zxf libpri-$libpriver.tar.gz
	if [ $? != 0 ]; then
		echo -e "fatal: dont have valid libpri tar package\n"
		exit 1
	fi

	cd libpri-$libpriver
	make
	make install
	echo -e "\e[32mLibPRI Install OK!\e[m"
}

function nginx_conf_install(){
	mkdir /var/www/html/asterCC/http-log
cat >  /usr/local/nginx/conf/nginx.conf << EOF
#user  nobody;
worker_processes  auto;
worker_rlimit_nofile 655350;

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

pid        /var/run/nginx.pid;


events {
    use epoll;
    worker_connections  1024;
}


http {
    include       mime.types;
    default_type  application/octet-stream;

    log_format  main  '\$remote_addr - \$remote_user [$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    #access_log  logs/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    #keepalive_timeout  0;
    keepalive_timeout  65;

    client_header_buffer_size 32k;
    large_client_header_buffers 4 32k;

	push_stream_store_messages on;
	push_stream_shared_memory_size  256M;
	push_stream_message_ttl  15m;

    #gzip  on;
    server
    {
        listen       80 default;
        client_max_body_size 20M;
        index index.html index.htm index.php;
        root  /var/www/html/asterCC/app/webroot;

        location / {
          index index.php;

          if (-f \$request_filename) {
            break;
          }
          if (!-f \$request_filename) {
            rewrite ^/(.+)\$ /index.php?url=\$1 last;
            break;
          }
		  location  /agentindesks/pushagent {
			push_stream_publisher admin;
			set \$push_stream_channel_id \$arg_channel;
		  }

		  location ~ /agentindesks/agentpull/(.*) {
			push_stream_subscriber      long-polling;
			set \$push_stream_channels_path    \$1;
			push_stream_message_template                 ~text~;
			push_stream_longpolling_connection_ttl        60s;	
		  }

		  location  /publicapi/pushagent {
			push_stream_publisher admin;
			set \$push_stream_channel_id             \$arg_channel;
		  }

		  location ~ /publicapi/agentpull/(.*) {
			push_stream_subscriber      long-polling;
			set \$push_stream_channels_path    \$1;
			push_stream_message_template         "{\\"text\\":\\"~text~\\",\\"tag\\":~tag~,\\"time\\":\\"~time~\\"}";
			push_stream_longpolling_connection_ttl        60s;
			push_stream_last_received_message_tag       \$arg_etag;
			push_stream_last_received_message_time      \$arg_since;
		  }
		
		  location  /systemevents/pushagent {
			push_stream_publisher admin;
			set \$push_stream_channel_id             \$arg_channel;
		  }

		  location ~ /systemevents/agentpull/(.*) {
			push_stream_subscriber      long-polling;
			set \$push_stream_channels_path    \$1;
			push_stream_message_template                 ~text~;
			push_stream_longpolling_connection_ttl        60s;
		  }
        }

        location ~ /\.ht {
          deny all;
        }
        location ~ .*\.(php|php5)?\$
        {
          fastcgi_pass  127.0.0.1:9000;
          fastcgi_index index.php;
          include fastcgi_params;
          fastcgi_param  SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
		  fastcgi_connect_timeout 60;
		  fastcgi_send_timeout 180;
		  fastcgi_read_timeout 180;
		  fastcgi_buffer_size 128k;
		  fastcgi_buffers 4 256k;
		  fastcgi_busy_buffers_size 256k;
		  fastcgi_temp_file_write_size 256k;
		  fastcgi_intercept_errors on;
        }

        location ~ .*\.(gif|jpg|jpeg|png|bmp|swf|wav)$
        {
          access_log   off;
          expires 15d;
        }

        location ~ .*\.(js|css)?$
        {
          expires 1d;
        }

#        access_log /var/www/html/asterCC/http-log/access.log main;
    }
}
EOF

echo -ne "
* soft nofile 655360
* hard nofile 655360
" >> /etc/security/limits.conf

echo "fs.file-max = 1572775" >> /etc/sysctl.conf
echo "net.ipv4.ip_local_port_range = 1024 65000" >> /etc/sysctl.conf
echo "net.ipv4.tcp_fin_timeout = 45" >> /etc/sysctl.conf
echo "vm.dirty_ratio=10" >> /etc/sysctl.conf
echo "net.ipv4.tcp_tw_reuse = 1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_tw_recycle = 1" >> /etc/sysctl.conf

sysctl -p

service nginx restart
}

function astercc_install() {
	service asterisk start
	echo -e "\e[32mStarting Install AsterCC\e[m"
	cd /usr/src
	if [ ! -e ./astercc-$asterccver.tar.gz ]; then
		wget $downloadmirror/astercc-$asterccver.tar.gz -t 5
	fi
	tar zxf astercc-$asterccver.tar.gz
	if [ $? != 0 ]; then
		echo "dont have valid astercc tar package, try run this script again or download astercc-$asterccver.tar.gz to /usr/src manually then run this script again"
		exit 1
	fi

	cd astercc-$asterccver
	chmod +x install.sh
	. /tmp/.mysql_root_pw.$$

	./install.sh -dbu=root -dbpw=$mysql_root_pw -amiu=$amiu -amipw=$amipw -allbydefault
	echo -e "\e[32mAsterCC Commercial Install OK!\e[m"
}

function set_ami(){
	while true;do
		echo -e "\e[32mplease give an AMI user\e[m";
		read amiu;
		if [ "X${amiu}" != "X" ]; then
			break;
		fi
	done

	while true;do
		echo -e "\e[32mplease give an AMI secret\e[m";
		read amipw;
		if [ "X${amipw}" != "X" ]; then
			break;
		fi
	done
cat > /etc/asterisk/manager.conf << EOF
[general]
enabled = yes
port = 5038
bindaddr = 0.0.0.0
displayconnects=no

[$amiu]
secret = $amipw
deny=0.0.0.0/0.0.0.0
permit=127.0.0.1/255.255.255.0
read = system,call,agent
write = all
EOF

	asterisk -rx "manager reload"

	echo amiu=$amiu >> /tmp/.mysql_root_pw.$$
	echo amipw=$amipw >> /tmp/.mysql_root_pw.$$
}

function get_mysql_passwd(){
	service mysql start
	update-rc.d mysql defaults
	while true;do
		echo -e "\e[32mplease enter your mysql root passwd\e[m";
		read mysql_passwd;
		# make sure it's not a empty passwd
		if [ "X${mysql_passwd}" != "X" ]; then
			mysqladmin -uroot -p$mysql_passwd password $mysql_passwd	# try empty passwd
			if [ $? == 0  ]; then
				break;
			fi

			mysqladmin password "$mysql_passwd" 
			if [ $? == 0  ]; then
				break;
			fi

			echo -e "\e[32minvalid password,please try again\e[m"
		fi
	done
	echo mysql_root_pw=$mysql_passwd > /tmp/.mysql_root_pw.$$
}

function run() {

downloadmirror=http://download3.astercc.org

echo "please select the mirror you want to download from:"
echo "1: HuaQiao Mirror Server"
read downloadserver;

if [ "$downloadserver" == "1"  ]; then
	downloadmirror=http://downcc.ucserver.org:8082/Files;
fi

	wget $downloadmirror/ucservercc1 -t 5
	if [ ! -e ./ucservercc1 ]; then
		echo "failed to get version infromation,please try again"
		exit 1;
	fi
	. ./ucservercc1
	/bin/rm -rf ./ucservercc1
	apt_install
	php_install
	dahdi_install
	libpri_install
	asterisk_install
	lame_install
	mpg123_install
	nginx_install
	ioncube_install
	get_mysql_passwd
	set_ami
	service asterisk restart
	astercc_install
	nginx_conf_install
	service mysql restart
	redis_install
#	php5_redis_install
	UI
	echo "asterisk ALL=NOPASSWD :/etc/init.d/asterisk" >> /etc/sudoers
	echo "asterisk ALL = NOPASSWD: /usr/bin/reboot" >> /etc/sudoers
	echo "asterisk ALL = NOPASSWD: /sbin/shutdown" >> /etc/sudoers
	/bin/rm -rf /tmp/.mysql_root_pw.$$
	ln -s /var/lib/asterisk/moh /var/lib/asterisk/mohmp3
	service php5-fpm restart
	service asterccd restart
	echo -e "\e[32mUCServer-CC installation finished，Please mail to xuke@ucserver.cc to get License!\e[m";
}

run
