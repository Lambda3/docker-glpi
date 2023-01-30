#!/bin/bash

#Controle du choix de version ou prise de la latest
[[ ! "$VERSION_GLPI" ]] \
	&& VERSION_GLPI=$(curl -s https://api.github.com/repos/glpi-project/glpi/releases/latest | grep tag_name | cut -d '"' -f 4)

if [[ -z "${TIMEZONE}" ]]; then echo "TIMEZONE is unset"; 
else 
echo "date.timezone = \"$TIMEZONE\"" > /usr/local/etc/php/conf.d/timezone.ini;
fi

SRC_GLPI=$(curl -s https://api.github.com/repos/glpi-project/glpi/releases/tags/${VERSION_GLPI} | jq .assets[0].browser_download_url | tr -d \")
TAR_GLPI=$(basename ${SRC_GLPI})
FOLDER_GLPI=glpi/
FOLDER_WEB=/var/www/html/

#Téléchargement et extraction des sources de GLPI
if [ "$(ls ${FOLDER_WEB}${FOLDER_GLPI})" ];
then
	echo "GLPI is already installed"
	VERSION_INSTALLED=`${FOLDER_WEB}${FOLDER_GLPI}/bin/console -V | cut -d ' ' -f 3`
	MAIN_VERSION=`echo ${VERSION_INSTALLED} | cut -d ' ' -f 3 | cut -d '.' -f 1`
	MINOR_VERSION1=`echo ${VERSION_INSTALLED} | cut -d ' ' -f 3 | cut -d '.' -f 2`
	MINOR_VERSION2=`echo ${VERSION_INSTALLED} | cut -d ' ' -f 3 | cut -d '.' -f 3`

	if [ "$(echo $VERSION_GLPI | cut -d '.' -f 1)" -gt $MAIN_VERSION ]; 
	then 
		echo "Version Installed: $VERSION_INSTALLED New version $VERSION_GLPI"
		wget -P ${FOLDER_WEB} ${SRC_GLPI}
		tar -xzf ${FOLDER_WEB}${TAR_GLPI} -C ${FOLDER_WEB}
		rm -Rf ${FOLDER_WEB}${TAR_GLPI}
		chown -R www-data:www-data ${FOLDER_WEB}${FOLDER_GLPI}
		$FOLDER_WEB/$FOLDER_GLPI/bin/console db:update
	else
		if [ "$(echo $VERSION_GLPI | cut -d '.' -f 1)" -eq $MAIN_VERSION ] && [ "$(echo $VERSION_GLPI | cut -d '.' -f 2)" -gt $MINOR_VERSION1 ];
		then
			echo "Version Installed: $VERSION_INSTALLED New version $VERSION_GLPI"
			wget -P ${FOLDER_WEB} ${SRC_GLPI}
			tar -xzf ${FOLDER_WEB}${TAR_GLPI} -C ${FOLDER_WEB}
			rm -Rf ${FOLDER_WEB}${TAR_GLPI}
			chown -R www-data:www-data ${FOLDER_WEB}${FOLDER_GLPI}
			$FOLDER_WEB/$FOLDER_GLPI/bin/console db:update
		else
			if [ "$(echo $VERSION_GLPI | cut -d '.' -f 1)" -eq $MAIN_VERSION ] && [ "$(echo $VERSION_GLPI | cut -d '.' -f 2)" -eq $MINOR_VERSION1 ] && [ "$(echo $VERSION_GLPI | cut -d '.' -f 3)" -gt $MINOR_VERSION2 ];
			then
				echo "Version Installed: $VERSION_INSTALLED New version $VERSION_GLPI"
				wget -P ${FOLDER_WEB} ${SRC_GLPI}
				tar -xzf ${FOLDER_WEB}${TAR_GLPI} -C ${FOLDER_WEB}
				rm -Rf ${FOLDER_WEB}${TAR_GLPI}
				chown -R www-data:www-data ${FOLDER_WEB}${FOLDER_GLPI}
				$FOLDER_WEB/$FOLDER_GLPI/bin/console db:update
			else
				echo "Version Installed: $VERSION_INSTALLED Version Informed $VERSION_GLPI"
			fi
		fi
	fi
	echo "Removing $FOLDER_WEB/$FOLDER_GLPI/install/install.php"
	rm -rf "$FOLDER_WEB/$FOLDER_GLPI/install/install.php"
else
	wget -P ${FOLDER_WEB} ${SRC_GLPI}
	tar -xzf ${FOLDER_WEB}${TAR_GLPI} -C ${FOLDER_WEB}
	rm -Rf ${FOLDER_WEB}${TAR_GLPI}
	chown -R www-data:www-data ${FOLDER_WEB}${FOLDER_GLPI}
fi

#Modification du vhost par défaut
echo -e "<VirtualHost *:80>\n\tDocumentRoot /var/www/html/glpi\n\n\t<Directory /var/www/html/glpi>\n\t\tAllowOverride All\n\t\tOrder Allow,Deny\n\t\tAllow from all\n\t</Directory>\n\n\tErrorLog /var/log/apache2/error-glpi.log\n\tLogLevel warn\n\tCustomLog /var/log/apache2/access-glpi.log combined\n</VirtualHost>" > /etc/apache2/sites-available/000-default.conf

#Start services
service cron start
service syslog-ng start

#Activation du module rewrite d'apache
a2enmod rewrite && service apache2 restart && service apache2 stop

#Lancement du service apache au premier plan
#/usr/sbin/apache2ctl -D FOREGROUND
apache2-foreground