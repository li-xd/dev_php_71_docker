FROM php:7.2-cli

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN chmod +x /usr/local/bin/install-php-extensions && sync && \
    install-php-extensions gd xdebug redis mbstring xml intl swoole zookeeper 

RUN install-php-extensions pcntl opcache

ENV LANG zh_CN.UTF-8
ENV LC_ALL zh_CN.UTF-8