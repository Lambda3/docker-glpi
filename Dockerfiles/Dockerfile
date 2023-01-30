#On choisit une debian
FROM php:8.1-apache

RUN apt update \
&& apt install --yes --no-install-recommends \
cron \
wget \
ca-certificates \
jq \
libapache2-mod-rpaf \
syslog-ng \
&& a2enmod remoteip \
&& rm -rf /var/lib/apt/lists/*

RUN mv /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini && \
echo "* * * * * /usr/local/bin/php /var/www/html/glpi/front/cron.php &>/dev/null" >> "${FOLDER_WEB}/glpicron" && \
crontab -u www-data "${FOLDER_WEB}/glpicron"

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN chmod +x /usr/local/bin/install-php-extensions && \
install-php-extensions gd mysqli pdo_mysql intl exif zip imagick ldap apcu bz2 opcache xmlrpc

ARG VERSION_GLPI
ENV VERSION_GLPI=$VERSION_GLPI

COPY glpi-start.sh /opt/
RUN chmod +x /opt/glpi-start.sh
ENTRYPOINT ["/opt/glpi-start.sh"]

EXPOSE 80 443