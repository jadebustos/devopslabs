FROM php:7-apache
MAINTAINER mantainer@email
ENV PORT=80
COPY virtualhost.conf /etc/apache2/sites-available/000-default.conf
COPY index.php /var/www/public/index.php
COPY start-apache.sh /usr/local/bin/start-apache
RUN chown -R www-data:www-data /var/www
RUN chmod 755 /usr/local/bin/start-apache
ENTRYPOINT ["start-apache"]