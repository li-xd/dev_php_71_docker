FROM ubuntu:20.04

# install packages
RUN apt-get update && \
apt-get upgrade -y && \
apt-get install -y software-properties-common locales && \
locale-gen en_US.UTF-8 && \
export LANG=en_US.UTF-8 && \
apt-add-repository -y ppa:ondrej/php && \
apt-add-repository -y ppa:ondrej/pkg-gearman && \
apt-get update && \
apt-get install -y php7.3 php7.3-dev && \
apt-get install -y php7.3-fpm php7.3-curl php7.3-mysql php7.3-mcrypt php7.3-gd php7.3-zip php-memcached php-gearman php-mongodb php-redis php-mbstring php7.3-mbstring php7.3-xml php7.3-intl php-xml wget php7.3-ssh2 php-bcmath php-imagick php7.3-bcmath php-xdebug git curl vim proxychains language-pack-zh-hans language-pack-zh-hans-base && \
rm -rf /var/lib/apt/lists/*

RUN mkdir -p /tmp/build && \
cd /tmp/build && \
rm -rf ./swoole-src && \
mkdir -p ./tmp && \
curl -o ./tmp/swoole.tar.gz https://github.com/swoole/swoole-src/archive/master.tar.gz -L && \
tar zxvf ./tmp/swoole.tar.gz && \
mv swoole-src* swoole-src && \
cd swoole-src && \
phpize && \
./configure \
--enable-coroutine \
--enable-openssl  \
--enable-http2  \
--enable-async-redis \
--enable-sockets \
--enable-mysqlnd && \
make clean && make && sudo make install

# phpunit & composer
ADD https://phar.phpunit.de/phpunit.phar /usr/local/bin/phpunit

RUN curl -s https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer

COPY docker-entrypoint.sh /entrypoint.sh

# connfiguration
RUN sed -E -i "s/^listen\ =.+?$/listen = 0.0.0.0:9000/" /etc/php/7.1/fpm/pool.d/www.conf && \
sed -E -i "s/^pm\ =.+?$/pm = ondemand/" /etc/php/7.1/fpm/pool.d/www.conf && \
sed -E -i "s/^pm\.max_children\ =.+?$/pm\.max_children = 5/" /etc/php/7.1/fpm/pool.d/www.conf && \
sed -E -i "s/^;pm\.process_idle_timeout\ =.+?$/pm\.process_idle_timeout=10s/" /etc/php/7.1/fpm/pool.d/www.conf && \
sed -E -i "s/^error_log\ =.+?$/error_log = \/proc\/self\/fd\/2/" /etc/php/7.1/fpm/php-fpm.conf && \
sed -E -i "s/^post_max_size\ =.+?$/post_max_size = 100M/" /etc/php/7.1/fpm/php.ini && \
sed -E -i "s/^upload_max_filesize\ =.+?$/upload_max_filesize = 100M/" /etc/php/7.1/fpm/php.ini && \
sed -E -i "s/^socks4 .*?$/socks5 10.254.254.254 1080/" /etc/proxychains.conf && \
echo "opcache.enable = 1" >> /etc/php/7.1/fpm/php.ini && \
echo "opcache.validate_timestamps = 1" >> /etc/php/7.1/fpm/php.ini && \
mkdir /var/run/php && \
mkdir /var/www && \
chown -R www-data:www-data /var/www && \
chmod +x /usr/local/bin/phpunit /usr/local/bin/composer /entrypoint.sh

WORKDIR /var/www

RUN echo "xdebug.remote_enable=1" >> /etc/php/7.1/fpm/conf.d/20-xdebug.ini && \
echo "xdebug.remote_port=5900" >> /etc/php/7.1/fpm/conf.d/20-xdebug.ini && \
echo "xdebug.remote_host=docker_host" >> /etc/php/7.1/fpm/conf.d/20-xdebug.ini && \
echo "xdebug.profiler_enable=0" >> /etc/php/7.1/fpm/conf.d/20-xdebug.ini && \
echo "xdebug.profiler_enable_trigger=1" >> /etc/php/7.1/fpm/conf.d/20-xdebug.ini


RUN echo "phar.readonly = Off" >> /etc/php/7.1/cli/php.ini

ENV LANG zh_CN.UTF-8
ENV LC_ALL zh_CN.UTF-8

EXPOSE 9000
EXPOSE 5900

ENTRYPOINT ["/entrypoint.sh"]

CMD ["php-fpm7.1", "-F"]