FROM ubuntu:16.04
MAINTAINER li-xd <a5834099147@live.cn>

# install packages
RUN apt-get update && \
apt-get upgrade -y && \
apt-get install -y software-properties-common locales && \
locale-gen en_US.UTF-8 && \
export LANG=en_US.UTF-8 && \
apt-add-repository -y ppa:ondrej/php &&\
apt-add-repository -y ppa:ondrej/pkg-gearman && \
apt-get update && \
apt-get install -y php7.1-fpm php7.1-curl php7.1-mysql php7.1-mcrypt php7.1-gd php7.1-zip php-memcached php-gearman php-mongodb php-redis php-mbstring php7.1-mbstring php7.1-xml php7.1-intl php-xml wget php7.1-ssh2 php-bcmath php7.1-dev php7.1-bcmath php-xdebug git language-pack-zh-hans language-pack-zh-hans-base libcurl4-openssl-dev  && \
rm -rf /var/lib/apt/lists/*

# 安装 sky walking
RUN cd /tmp && \
git clone https://github.com/SkyAPM/SkyAPM-php-sdk.git && \
cd SkyAPM-php-sdk && \
phpize && ./configure && make && make install && \
wget https://github.com/SkyAPM/SkyAPM-php-sdk/releases/download/3.2.0/sky-php-agent-linux-x64


# phpunit & composer
ADD https://phar.phpunit.de/phpunit.phar /usr/local/bin/phpunit
ADD https://getcomposer.org/composer.phar /usr/local/bin/composer
ADD https://codeception.com/releases/2.4.0/codecept.phar /usr/local/bin/codecept
COPY docker-entrypoint.sh /entrypoint.sh

# connfiguration
RUN sed -E -i "s/^listen\ =.+?$/listen = 0.0.0.0:9000/" /etc/php/7.1/fpm/pool.d/www.conf && \
sed -E -i "s/^pm\ =.+?$/pm = ondemand/" /etc/php/7.1/fpm/pool.d/www.conf && \
sed -E -i "s/^pm\.max_children\ =.+?$/pm\.max_children = 5/" /etc/php/7.1/fpm/pool.d/www.conf && \
sed -E -i "s/^;pm\.process_idle_timeout\ =.+?$/pm\.process_idle_timeout=10s/" /etc/php/7.1/fpm/pool.d/www.conf && \
sed -E -i "s/^error_log\ =.+?$/error_log = \/proc\/self\/fd\/2/" /etc/php/7.1/fpm/php-fpm.conf && \
sed -E -i "s/^post_max_size\ =.+?$/post_max_size = 100M/" /etc/php/7.1/fpm/php.ini && \
sed -E -i "s/^upload_max_filesize\ =.+?$/upload_max_filesize = 100M/" /etc/php/7.1/fpm/php.ini && \
echo "opcache.enable = 1" >> /etc/php/7.1/fpm/php.ini && \
echo "opcache.validate_timestamps = 1" >> /etc/php/7.1/fpm/php.ini && \
echo "extension=skywalking.so"  >> /etc/php/7.1/fpm/php.ini && \
echo "skywalking.enable = 1" >> /etc/php/7.1/fpm/php.ini && \
echo "skywalking.version = 5" >> /etc/php/7.1/fpm/php.ini && \
echo "skywalking.app_code = AllWayTest" >> /etc/php/7.1/fpm/php.ini && \
echo "skywalking.sock_path=/tmp/sky_agent.sock" >> /etc/php/7.1/fpm/php.ini && \
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