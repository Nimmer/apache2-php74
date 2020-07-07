FROM debian:stable
MAINTAINER Matus Demko <tobysichcelvediet@gmail.sk>

# Install common utilities
RUN apt update && \
    apt -y upgrade

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y bash zsh git grep sed curl tee \
 wget tar gzip postfix ssh vim nano tmux htop net-tools iputils-ping

CMD ["/bin/bash"]

# Copy and add files first (to make dockerhub autobuild working: https://forums.docker.com/t/automated-docker-build-fails/22831/14)
COPY run.sh /run.sh

RUN apt -y install lsb-release apt-transport-https ca-certificates
RUN wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
RUN echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list
RUN apt update

RUN apt update && \
    apt -y install \
    apache2 \
    supervisor \
    php7.4 \
    php7.4-pgsql \
    php7.4-mysql \
    php7.4-gd \
    php7.4-tidy \
    php7.4-odbc \
    php7.4-bcmath \
    php7.4-cli \
    php7.4-xml \
    php7.4-xls \
    php7.4-fpm \
    php7.4-curl \
    php7.4-intl \
    php7.4-json \
    php7.4-dev \
    php7.4-mbstring \
    php7.4-zip \
    php-memcache \
    php-memcached \
    php-imagick \
    memcached \
    imagemagick \
    postfix

# Install NPM & NPM modules (gulp, bower)
RUN apt-get -y install nodejs npm
RUN npm install -g \
    gulp \
    bower

# php-fpm configuration
COPY ./php/php.ini /etc/php/apache2/php.ini

# Install composer
ENV COMPOSER_HOME=/composer
RUN mkdir /composer \
    && curl -sS https://getcomposer.org/download/1.10.8/composer.phar > composer.phar

RUN mkdir -p /opt/composer \
    && mv composer.phar /usr/local/bin/composer \
    && chmod 777 /usr/local/bin/composer

# Configure xdebug
#RUN echo 'zend_extension="/usr/lib/php7/modules/xdebug.so"' >> /etc/php7/php.ini \
#    && echo "xdebug.remote_enable=on" >> /etc/php7/php.ini \
#    && echo "xdebug.remote_autostart=off" >> /etc/php7/php.ini \
#    && echo "xdebug.remote_connect_back=0" >> /etc/php7/php.ini \
#    && echo "xdebug.remote_port=9001" >> /etc/php7/php.ini \
#    && echo "xdebug.remote_handler=dbgp" >> /etc/php7/php.ini \
#    && echo "xdebug.remote_host=192.168.65.1" >> /etc/php7/php.ini
#     (Only for MAC users) Fill IP address from:
    # cat /Users/gtakacs/Library/Containers/com.docker.docker/Data/database/com.docker.driver.amd64-linux/slirp/host
    # Source topic on Docker forums: https://forums.docker.com/t/ip-address-for-xdebug/10460/22

# Copy Supervisor config file
COPY supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN adduser --shell /sbin/nologin --disabled-login www-data www-data
RUN chown -R www-data:www-data /run/apache2/

# Copy Apache2 config
RUN rm /etc/apache2/sites-available/000-default.conf
RUN rm /etc/apache2/sites-enabled/000-default.conf
COPY apache2/web.conf /etc/apache2/sites-available/000-default.conf
RUN a2ensite 000-default
RUN a2enmod rewrite headers

# Make run file executable
RUN chmod a+x /run.sh

RUN chmod a+rw /var/log/apache2

RUN composer global require hirak/prestissimo

#RUN apk --no-cache --update add icu icu-libs icu-dev
#RUN docker-php-ext-install intl

EXPOSE 80 443 25
CMD ["/run.sh"]
WORKDIR /var/www/web
