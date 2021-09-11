FROM amd64/php:7.3-fpm

# Install the packages we need
# Install the PHP extensions we need
# see https://wiki.dolibarr.org/index.php/Dependencies_and_external_libraries
# Prepare folders
RUN set -ex; \
	apt-get update -q; \
	apt-get install -y --no-install-recommends \
		bzip2 \
		default-mysql-client \
		cron \
		rsync \
		sendmail \
		unzip \
		zip \
	; \
	apt-get install -y --no-install-recommends \
		g++ \
		libcurl4-openssl-dev \
		libfreetype6-dev \
		libicu-dev \
		libjpeg-dev \
		libldap2-dev \
		libmagickcore-dev \
		libmagickwand-dev \
		libmcrypt-dev \
		libpng-dev \
		libpq-dev \
		libxml2-dev \
		libzip-dev \
		unzip \
		zlib1g-dev \
	; \
	debMultiarch="$(dpkg-architecture --query DEB_BUILD_MULTIARCH)"; \
	docker-php-ext-configure ldap --with-libdir="lib/$debMultiarch"; \
	docker-php-ext-configure gd --with-freetype-dir=/usr --with-png-dir=/usr --with-jpeg-dir=/usr; \
	docker-php-ext-configure intl; \
	docker-php-ext-configure zip --with-libzip; \
	docker-php-ext-install -j "$(nproc)" \
		calendar \
		gd \
		intl \
		ldap \
		mbstring \
		mysqli \
		pdo \
		pdo_mysql \
		pdo_pgsql \
		pgsql \
		soap \
		zip \
	; \
	pecl install imagick; \
	docker-php-ext-enable imagick; \
	rm -rf /var/lib/apt/lists/*; \
	mkdir -p /var/www/documents; \
	chown -R www-data:root /var/www; \
	chmod -R g=u /var/www

VOLUME /var/www/html /var/www/documents /var/www/scripts

# Runtime env var
ENV DOLI_AUTO_CONFIGURE=1 \
	DOLI_DB_TYPE=mysqli \
	DOLI_DB_HOST= \
	DOLI_DB_PORT=3306 \
	DOLI_DB_USER=dolibarr \
	DOLI_DB_PASSWORD='' \
	DOLI_DB_NAME=dolibarr \
	DOLI_DB_PREFIX=llx_ \
	DOLI_DB_CHARACTER_SET=utf8 \
	DOLI_DB_COLLATION=utf8_unicode_ci \
	DOLI_DB_ROOT_LOGIN='' \
	DOLI_DB_ROOT_PASSWORD='' \
	DOLI_ADMIN_LOGIN=admin \
	DOLI_MODULES='' \
	DOLI_URL_ROOT='http://localhost' \
	DOLI_AUTH=dolibarr \
	DOLI_LDAP_HOST= \
	DOLI_LDAP_PORT=389 \
	DOLI_LDAP_VERSION=3 \
	DOLI_LDAP_SERVERTYPE=openldap \
	DOLI_LDAP_LOGIN_ATTRIBUTE=uid \
	DOLI_LDAP_DN='' \
	DOLI_LDAP_FILTER='' \
	DOLI_LDAP_ADMIN_LOGIN='' \
	DOLI_LDAP_ADMIN_PASS='' \
	DOLI_LDAP_DEBUG=false \
	DOLI_HTTPS=0 \
	DOLI_PROD=0 \
	DOLI_NO_CSRF_CHECK=0 \
	WWW_USER_ID=33 \
	WWW_GROUP_ID=33 \
	PHP_INI_DATE_TIMEZONE='UTC' \
	PHP_MEMORY_LIMIT=256M \
	PHP_MAX_UPLOAD=20M \
	PHP_MAX_EXECUTION_TIME=300
RUN set -eux; \
	docker-php-ext-enable opcache; \
	{ \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=2'; \
		echo 'opcache.fast_shutdown=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini
# Build time env var
ARG DOLI_VERSION=13.0.4

# Get Dolibarr
ADD https://github.com/Dolibarr/dolibarr/archive/${DOLI_VERSION}.zip /tmp/dolibarr.zip

# Install Dolibarr from tag archive
RUN set -ex; \
	mkdir -p /tmp/dolibarr; \
	unzip -q /tmp/dolibarr.zip -d /tmp/dolibarr; \
	rm /tmp/dolibarr.zip; \
	mkdir -p /usr/src/dolibarr; \
	cp -r "/tmp/dolibarr/dolibarr-${DOLI_VERSION}"/* /usr/src/dolibarr; \
	rm -rf /tmp/dolibarr; \
	chmod +x /usr/src/dolibarr/scripts/*; \
    echo "${DOLI_VERSION}" > /usr/src/dolibarr/.docker-image-version; \
    echo "<?php phpinfo();?>" > /usr/src/dolibarr/html/info.php

COPY entrypoint.sh /
RUN set -ex; \
	chmod 755 /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]

# Arguments to label built container
ARG VCS_REF
ARG BUILD_DATE

# Container labels (http://label-schema.org/)
# Container annotations (https://github.com/opencontainers/image-spec)
LABEL maintainer="Monogramm maintainers <opensource at monogramm dot io>" \
	  product="Dolibarr" \
	  version=${DOLI_VERSION} \
	  org.label-schema.vcs-ref=${VCS_REF} \
	  org.label-schema.vcs-url="https://github.com/Monogramm/docker-dolibarr" \
	  org.label-schema.build-date=${BUILD_DATE} \
	  org.label-schema.name="Dolibarr" \
	  org.label-schema.description="Open Source ERP & CRM for Business" \
	  org.label-schema.url="https://www.dolibarr.org/" \
	  org.label-schema.vendor="Dolibarr" \
	  org.label-schema.version=$DOLI_VERSION \
	  org.label-schema.schema-version="1.0" \
	  org.opencontainers.image.revision=${VCS_REF} \
	  org.opencontainers.image.source="https://github.com/Monogramm/docker-dolibarr" \
	  org.opencontainers.image.created=${BUILD_DATE} \
	  org.opencontainers.image.title="Dolibarr" \
	  org.opencontainers.image.description="Open Source ERP & CRM for Business" \
	  org.opencontainers.image.url="https://www.dolibarr.org/" \
	  org.opencontainers.image.vendor="Dolibarr" \
	  org.opencontainers.image.version=${DOLI_VERSION} \
	  org.opencontainers.image.authors="Monogramm maintainers <opensource at monogramm dot io>"
