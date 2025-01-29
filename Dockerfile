FROM php:8.2-cli AS base

WORKDIR /app

RUN apt-get update && apt-get install -y \
    unzip libzip-dev && \
    docker-php-ext-install zip

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

COPY composer.json ./

RUN composer install --no-dev

FROM base AS dev

RUN pecl install xdebug && \
    docker-php-ext-enable xdebug

COPY ./docker/php/xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

COPY . .

FROM base AS test

RUN composer require --dev phpunit/phpunit

COPY . .

CMD ["./vendor/bin/phpunit", "--testdox", "tests"]

FROM base AS prod

COPY . .

RUN composer install --no-dev --optimize-autoloader

RUN rm -rf docker/ test/

CMD ["php","-S","0.0.0.0:80", "-t","public"]
