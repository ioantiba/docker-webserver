#Download base image ubuntu
FROM ubuntu:16.04
MAINTAINER Ioan Tiba <ioantiba@gmail.com>

ARG DEBIAN_FRONTEND=noninteractive

#Add entrypoint script to image
ADD startup.sh /startup.sh

#Make startup script executable
RUN chmod +x /startup.sh

#PHP and Apache2 section
RUN \
  apt-get update && \
  apt-get install -y --no-install-recommends apt-utils

RUN \
  chmod +x /*.sh && \
  apt-get clean && \
  apt-get update && \
  apt-get install -y locales && \
  apt-get -y install software-properties-common python-software-properties && \
  apt-get -y install vim && \
  apt-get install -y openssh-server && mkdir /var/run/sshd && \
  locale-gen en_US.UTF-8 && \
  export LANG=en_US.UTF-8 && \
  add-apt-repository -y ppa:ondrej/php && \
  add-apt-repository -y ppa:ondrej/apache2

RUN \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y apache2 php7.1 php7.1-common php7.1-json php7.1-opcache php-uploadprogress php-memcache php7.1-zip php7.1-mysql php7.1-mysqli php7.1-mongodb php7.1-solr php7.1-geoip php7.1-gmp php7.1-curl php7.1-exif php7.1-memcache php7.1-iconv php7.1-pdo-mysql php7.1-pgsql php7.1-dom php7.1-smbclient php7.1-bcmath php7.1-phpdbg php7.1-gd php7.1-imap php7.1-ldap php7.1-pgsql php7.1-pspell php7.1-recode php7.1-tidy php7.1-dev php7.1-intl php7.1-curl php7.1-mcrypt php7.1-xmlrpc php7.1-xsl php7.1-bz2 php7.1-mbstring pkg-config libmagickwand-dev imagemagick build-essential && \

  #Set Global ServerName to Suppress Syntax Warnings
  echo "ServerName localhost" >> /etc/apache2/apache2.conf && \
  
  #Copy index.html to work directory /var/www
  #cp /var/www/html/index.html /var/www/index.html && \

  #remove html directory
  #rm -rf  /var/www/html && \

  #Replce olr root directory with new one
  sed -i 's#DocumentRoot /var/www/html#DocumentRoot /var/www#g' /etc/apache2/sites-available/000-default.conf && \
       
  #Create new file for get info about php installed
  #echo "<?php phpinfo(); ?>" > /var/www/info.php && \
  
  ln -sf ../mods-available/rewrite.load /etc/apache2/mods-enabled/rewrite.load

#Install MySQL
#RUN echo "deb http://cn.archive.ubuntu.com/ubuntu/ $(lsb_release -s -c) main restricted universe multiverse" >> /etc/apt/sources.list

RUN echo "mysql-server mysql-server/root_password password root" | debconf-set-selections
RUN echo "mysql-server mysql-server/root_password_again password root" | debconf-set-selections

RUN apt-get update && \
	apt-get -y install libmysqlclient-dev mysql-common mysql-client-5.7 mysql-server-5.7 && \
	mkdir -p /var/lib/mysql && \
	mkdir -p /var/run/mysqld && \
	mkdir -p /var/log/mysql && \
	chown -R mysql:mysql /var/lib/mysql && \
	chown -R mysql:mysql /var/run/mysqld && \
	chown -R mysql:mysql /var/log/mysql

# UTF-8 and bind-address
RUN \
  sed -i -e "$ a [client]\n\n[mysql]\n\n[mysqld]" /etc/mysql/my.cnf && \
  sed -i -e "s/\(\[client\]\)/\1\ndefault-character-set = utf8/g" /etc/mysql/my.cnf && \
  sed -i -e "s/\(\[mysql\]\)/\1\ndefault-character-set = utf8/g" /etc/mysql/my.cnf && \
  sed -i -e "s/\(\[mysqld\]\)/\1\ninit_connect='SET NAMES utf8'\ncharacter-set-server = utf8\ncollation-server=utf8_unicode_ci\nbind-address = 0.0.0.0\nskip-grant-tables/g" /etc/mysql/my.cnf

# Volume configuration
VOLUME ["/var/www", "/var/lib/mysql"]

#Expose ports for apache2, mysql
#EXPOSE 22
EXPOSE 80
EXPOSE 3306

WORKDIR /

ENTRYPOINT ["/startup.sh"]

#CMD ["service mysql start", "service apache2 start"]
