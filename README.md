# WebServer

This is WebServer on top of Ubuntu-16.04 + Mysql-5.7 + Apache2 + PHP 7.1.
It can be configured with environment variables.

# Build image

1. sudo docker build -t "web-server" .

# Parameters: 
MYSQL_ROOT_PWD : root Password default "mysql" 
MYSQL_USER : new User 
MYSQL_USER_PWD : new User Password 
MYSQL_USER_DB : new Database for new User 
PMA_SECURITY_USER: username used to pass in phpMyAdmin interface
PMA_SECURITY_PWD: password used to pass in phpMyAdmin interface

# Usage

Create directories used as volume for webserver: 
mkdir -p /home/ubuntu/workspace/storage/apache-apps 
mkdir -p /home/ubuntu/workspace/storage/mysql/data

Run a default contaier: 
docker run -dit --name webserver \
  -v /home/ubuntu/workspace/storage/apache-apps:/var/www/ \
  -v /home/ubuntu/workspace/storage/mysql/data/:/var/lib/mysql \
  -p 8888:80 -p 3306:3306 web-server

Run a container with new User and Password: 
docker run -dit --name webserver \
  -v /home/ubuntu/workspace/storage/apache-apps:/var/www/ \
  -v /home/ubuntu/workspace/storage/mysql/data/:/var/lib/mysql \
  -p 8888:80 -p 3306:3306 \
  -e MYSQL_ROOT_PWD=123 -e MYSQL_USER=dev -e MYSQL_USER_PWD=dev web-server

Run a container with new Database for new User and Password: 
docker run -dit --name webserver \
  -v /home/ubuntu/workspace/storage/apache-apps:/var/www/ \
  -v /home/ubuntu/workspace/storage/mysql/data/:/var/lib/mysql \
  -p 8888:80 -p 3306:3306 \
  -e MYSQL_ROOT_PWD=123 -e MYSQL_USER=dev -e MYSQL_USER_PWD=dev -e MYSQL_USER_DB=userdb web-server

  
Container usefull commands:

MySQL Config: /etc/mysql/my.cnf 
Management MySQL: service mysql start | stop | restart 
Status MySQL: mysqladmin -u root -p status or /etc/init.d/mysql status 
Login to MySQL: mysql -u root -p

Check container log: docker logs <container_id>
