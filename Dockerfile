FROM php:7.2-apache-stretch

# Install apt packages
#
# Required for php extensions
# * gd: libpng-dev
# * imagick: libmagickwand-dev
# * imap: libc-client-dev, libkrb5-dev
# * intl: libicu-dev
# * soap: libxml2-dev
# * zip: zlib1g-dev
#
# Used in the build process
# * git
# * mysql-client
# * sudo
# * unzip
# * zip
# * node 9.x (from nodesource repository)
#
# iproute2 is required to get host ip from container

# gettext-base is required for envsubst
# gnupg is required for apt-key

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  gnupg \
  && curl -sL https://deb.nodesource.com/setup_9.x | bash \
  && apt-get install -y --no-install-recommends \
  gettext-base \
  git \
  iproute2 \
  libc-client-dev \
  libicu-dev \
  libkrb5-dev \
  libmagickwand-dev \
  libpng-dev \
  libxml2-dev \
  mysql-client \
  nodejs \
  sudo \
  unzip \
  zip \
  zlib1g-dev \
  && rm -r /var/lib/apt/lists/*

# Install php extensions (curl, json, mbstring, openssl, posix, phar
# are installed already and don't need to be specified here)
# mcrypt is deprecated in PHP >7.1
RUN docker-php-ext-install bcmath \
  && docker-php-ext-install gd \
  && docker-php-ext-install gettext \
  && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
  && docker-php-ext-install imap \
  && docker-php-ext-install intl \
  && docker-php-ext-install mysqli \
  && docker-php-ext-install pdo_mysql \
  && docker-php-ext-install soap \
  && docker-php-ext-install zip

# Install and enable imagick PECL extensions
RUN pecl install imagick \
  && docker-php-ext-enable imagick

RUN a2enmod rewrite

RUN a2enmod headers

ARG BUILDKIT_UID=1000

ARG BUILDKIT_GID=$BUILDKIT_UID

RUN addgroup --gid=$BUILDKIT_GID buildkit

RUN useradd --home-dir /buildkit --create-home --uid $BUILDKIT_UID --gid $BUILDKIT_GID buildkit

COPY sudo /etc/sudoers.d/buildkit

# disable Apache default site (port 80)
RUN echo "" > /etc/apache2/ports.conf
RUN rm /etc/apache2/sites-enabled/000-default.conf

USER buildkit

WORKDIR /buildkit

ENV PATH="/buildkit/bin:${PATH}"

RUN git clone https://github.com/civicrm/civicrm-buildkit.git buildkit-tmp

RUN mv buildkit-tmp/* buildkit-tmp/.git* .

RUN rmdir buildkit-tmp

# Need to create this before we configure apache, otherwise it will complain
RUN mkdir -p .amp/apache.d

RUN mkdir -p .cache/bower

RUN mkdir .composer

RUN mkdir .drush

RUN mkdir .npm

RUN civi-download-tools

RUN civibuild cache-warmup

COPY buildkit.ini /usr/local/etc/php/conf.d/buildkit.ini

COPY apache.conf /etc/apache2/conf-enabled/buildkit.conf

RUN rm /buildkit/app/civicrm.settings.d/100-mail.php

COPY civibuild.conf /buildkit/app/civibuild.conf

COPY apache24-vhost.php /buildkit/build/.amp/apache24-vhost.php

ENV VARIABLES_CIVI_CONF \
        "\$CIVI_DB_HOST \
        \$CIVI_DB_PASSWORD"

ENV SRC_CIVI_CONF /buildkit/.amp/services.yml.source
ENV FILE_CIVI_CONF /buildkit/.amp/services.yml

COPY --chown=buildkit:buildkit amp.services.yml.source $SRC_CIVI_CONF

USER root

RUN chgrp -R 0 /buildkit \
  && chmod -R g=u /buildkit

# Need to create passwd entry for the user at run-time
RUN chmod g=u /etc/passwd

COPY ./docker-civicrm-entrypoint /usr/local/bin

USER 9008

ENTRYPOINT [ "docker-civicrm-entrypoint" ]

CMD ["apache2-foreground"]
