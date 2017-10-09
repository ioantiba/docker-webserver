#! /bin/bash

MYSQL_ROOT_PWD=${MYSQL_ROOT_PWD:-"root"}
MYSQL_USER=${MYSQL_USER:-""}
MYSQL_USER_PWD=${MYSQL_USER_PWD:-""}
MYSQL_USER_DB=${MYSQL_USER_DB:-""}
PMA_SECURITY_USER=${PMA_SECURITY_USER:-"admin"}
PMA_SECURITY_PWD=${PMA_SECURITY_PWD:-"rO8CFZ6nqNqO?jMgV7PL"}

#Apache section
ln -sf /usr/share/zoneinfo/Europe/Bucharest /etc/localtime

echo "[i] Start Apache Server..."
service apache2 start

#MySQL section

#Change home directory of mysql from nonexistent to original directory where it is supposed to be:
usermod -d /var/lib/mysql/ mysql

#Ensure about permissions for mysql data
chown -R mysql:mysql /var/lib/mysql

#initialize the data directory
mysqld --initialize-insecure

echo "[i] Setting up new power user credentials."
service mysql start $ sleep 10

echo "[i] Setting root new password."
mysql --user=root --password=root -e "UPDATE mysql.user set authentication_string=password('$MYSQL_ROOT_PWD') where user='root'; FLUSH PRIVILEGES;"

echo "[i] Setting root remote password."
mysql --user=root --password=$MYSQL_ROOT_PWD -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PWD' WITH GRANT OPTION; FLUSH PRIVILEGES;"

if [ -n "$MYSQL_USER_DB" ]; then
  echo "[i] Creating datebase: $MYSQL_USER_DB"
  mysql --user=root --password=$MYSQL_ROOT_PWD -e "CREATE DATABASE IF NOT EXISTS \`$MYSQL_USER_DB\` CHARACTER SET utf8 COLLATE utf8_general_ci; FLUSH PRIVILEGES;"

  if [ -n "$MYSQL_USER" ] && [ -n "$MYSQL_USER_PWD" ]; then
    echo "[i] Create new User: $MYSQL_USER with password $MYSQL_USER_PWD for new database $MYSQL_USER_DB."
    mysql --user=root --password=$MYSQL_ROOT_PWD -e "GRANT ALL PRIVILEGES ON \`$MYSQL_USER_DB\`.* TO '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_USER_PWD' WITH GRANT OPTION; FLUSH PRIVILEGES;"
  else
    echo "[i] Don\`t need to create new User."
  fi
else
  if [ -n "$MYSQL_USER" ] && [ -n "$MYSQL_USER_PWD" ]; then
    echo "[i] Create new User: $MYSQL_USER with password $MYSQL_USER_PWD for all database."
    mysql --user=root --password=$MYSQL_ROOT_PWD -e "GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_USER_PWD' WITH GRANT OPTION; FLUSH PRIVILEGES;"
  else
    echo "[i] Don\`t need to create new User."
  fi
fi

#Commment the settings skip-grant-tables
sed -i '/skip-grant-tables/s/^/#/g' /etc/mysql/my.cnf

killall mysqld
sleep 5
echo "[i] Setting end,have fun."

#Install phpMyAdmin
if [ ! -d /share/phpmyadmin/ ];
  echo "phpmyadmin phpmyadmin/dbconfig-install boolean false" | debconf-set-selections
  echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections

  echo "phpmyadmin phpmyadmin/app-password-confirm password $MYSQL_ROOT_PWD" | debconf-set-selections
  echo "phpmyadmin phpmyadmin/mysql/admin-pass password $MYSQL_ROOT_PWD" | debconf-set-selections
  echo "phpmyadmin phpmyadmin/password-confirm password $MYSQL_ROOT_PWD" | debconf-set-selections
  echo "phpmyadmin phpmyadmin/setup-password password $MYSQL_ROOT_PWD" | debconf-set-selections
  echo "phpmyadmin phpmyadmin/database-type select mysql" | debconf-set-selections
  echo "phpmyadmin phpmyadmin/mysql/app-pass password $MYSQL_ROOT_PWD" | debconf-set-selections
  
  echo "dbconfig-common dbconfig-common/mysql/app-pass password $MYSQL_ROOT_PWD" | debconf-set-selections
  echo "dbconfig-common dbconfig-common/mysql/app-pass password" | debconf-set-selections
  echo "dbconfig-common dbconfig-common/app-password-confirm password $MYSQL_ROOT_PWD" | debconf-set-selections
  echo "dbconfig-common dbconfig-common/password-confirm password $MYSQL_ROOT_PWD" | debconf-set-selections
  
  apt-get install -q -y phpmyadmin
then
  echo "phpmyadmin already installed"
fi

#Create symbolic link to phpMyAdmin
sudo ln -s /usr/share/phpmyadmin/ /var/www/phpmyadmin

#Secure your phpMyAdmin Instance

#Enable the use of .htaccess and add an AllowOverride All directive within the <Directory /usr/share/phpmyadmin>
sed -i 's#DirectoryIndex index.php#DirectoryIndex index.php\n    AllowOverride All#g' /etc/apache2/conf-available/phpmyadmin.conf
#Restart Apache:
service apache2 restart

#Create an .htaccess File to actually implement some security:
#echo -e 'AuthType Basic\nAuthName "Restricted Files"\nAuthUserFile /etc/phpmyadmin/.htpasswd\nRequire valid-user' > /usr/share/phpmyadmin/.htaccess
echo -e "#specifies the authentication type that we are implementing. This type will implement password authentication using a password file.\nAuthType Basic" > /usr/share/phpmyadmin/.htaccess
echo -e "#sets the message for the authentication dialog box. You should keep this generic so that unauthorized users won't gain any information about what is being protected.\nAuthName 'Restricted Files'" >> /usr/share/phpmyadmin/.htaccess
echo -e "#location of the password file that will be used for authentication. This should be outside of the directories that are being served.\nAuthUserFile /etc/phpmyadmin/.htpasswd" >> /usr/share/phpmyadmin/.htaccess
echo -e "#specifies that only authenticated users should be given access to this resource. This is what actually stops unauthorized users from entering.\nRequire valid-user" >> /usr/share/phpmyadmin/.htaccess

#Create the .htpasswd file for Authentication
apt -y install apache2-utils
htpasswd -b -c /etc/phpmyadmin/.htpasswd $PMA_SECURITY_USER $PMA_SECURITY_PWD

#Start MySQL service
service mysql start

/bin/bash

exec "$@"

#/bin/bash
