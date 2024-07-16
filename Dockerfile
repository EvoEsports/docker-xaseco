# XASECO needs PHP5.6, so we're going to build it here.
FROM alpine:3.20 AS php

ENV PHP_INI_DIR="/usr/local/etc/php"
ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -Wl,--hash-style=both -pie"
ENV PHP_VERSION="5.6.40"
ENV PHP_COMMIT="ed5aebf7d65fb67b399f9320f704b5e2bb165117"
ENV PHP_URL="https://github.com/remicollet/php-src-security/archive/${PHP_COMMIT}.zip"

RUN true \
    && set -eux \
	&& apk add --no-cache ca-certificates curl openssl tar xz autoconf dpkg-dev dpkg file g++ gcc libc-dev make pkgconf re2c patch dpkg bison gnu-libiconv libedit coreutils curl-dev gnu-libiconv-dev libsodium-dev libxml2-dev linux-headers oniguruma-dev openssl-dev readline-dev sqlite-dev unzip \
    && mkdir -p "$PHP_INI_DIR/conf.d" \
    && set -eux \
	&& mkdir -p "/usr/src" \
	&& cd "/usr/src" \
	&& wget -O php.zip "$PHP_URL" \
	&& unzip -q php.zip \
	&& mv php-src-security-${PHP_COMMIT} php-${PHP_VERSION} \
	&& rm php.zip \
	&& tar Jcf php.tar.xz -C . php-${PHP_VERSION} \
	&& rm -r php-${PHP_VERSION} \
    && true

COPY php/patches/ "/usr/src"
COPY php/docker-php-source "/usr/local/bin/"
RUN chmod +x "/usr/local/bin/"docker-php-source

RUN true \
	&& set -eux \
	&& export CFLAGS="$PHP_CFLAGS" CPPFLAGS="$PHP_CPPFLAGS" LDFLAGS="$PHP_LDFLAGS" \
	&& docker-php-source extract \
	&& patch -s --directory="/usr/src/php" --strip=1 < "/usr/src/0001-Add-support-for-ICU-70.1-PHP5.6.patch" \
	&& patch -s --directory="/usr/src/php" --strip=1 < "/usr/src/0002-Add-minimal-OpenSSL-3.0-patch-PHP5.6.patch" \
	&& patch -s --directory="/usr/src/php" --strip=1 < "/usr/src/0003-Fix-bug-79589-ssl3_read_n-unexpected-eof-while-reading-PHP5.6.patch" \
	&& patch -s --directory="/usr/src/php" --strip=1 < "/usr/src/0004-PATCH-Fix-ZEND_SIGNED_MULTIPLY_LONG-for-AArch64.patch" \
	&& patch -s --directory="/usr/src/php" --strip=1 < "/usr/src/0005-Fix-pthreads-detection-when-cross-compiling.patch" \
	&& patch -s --directory="/usr/src/php" --strip=1 < "/usr/src/0006-Use-ITIMER_REAL-for-timeout-handling-PHP-5.6.patch" \
	&& cd "/usr/src/php" \
	&& gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
	&& debMultiarch="$(dpkg-architecture --query DEB_BUILD_MULTIARCH)" \
    && if [ ! -d /usr/include/curl ]; then \
		ln -sT "/usr/include/$debMultiarch/curl" /usr/local/include/curl; \
	fi \
	&& ./buildconf --force \
	&& ./configure \
		--build="$gnuArch" \
		--with-config-file-path="$PHP_INI_DIR" \
		--with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
		--enable-option-checking=fatal \
		--with-mhash \
		--enable-ftp \
		--enable-mbstring \
		--enable-mysqlnd \
		--with-curl \
		--with-mysql \
		--with-readline \
		--with-openssl \
		--with-zlib \
		--with-libdir="lib/$debMultiarch" \
		${PHP_EXTRA_CONFIGURE_ARGS:-} \
	&& make -j "$(nproc)" \
	&& make install \
	&& find /usr/local/bin /usr/local/sbin -type f -executable -exec strip --strip-all '{}' + || true \
	&& cp -v php.ini-* "$PHP_INI_DIR/" \
	&& true

# Building our PHP 5.6 docker base image.
FROM alpine:3.20 AS base

RUN true \
	&& mkdir -p "$PHP_INI_DIR/conf.d" \
	&& apk add --no-cache ca-certificates openssl libcurl libxml2 readline \
	&& true

COPY --from=php "/usr/local/lib/php" "/usr/local/lib/php"
COPY --from=php "/usr/local/bin" "/usr/local/bin"
COPY --from=php "/usr/local/include/php" "/usr/local/include/php"
COPY --from=php "/usr/local/etc/php" "/usr/local/etc/php"

COPY php/docker-php-ext-* php/docker-php-entrypoint /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-php-ext-* /usr/local/bin/docker-php-entrypoint

ENTRYPOINT ["docker-php-entrypoint"]
CMD ["php", "-a"]

# Building the actual XASECO image, based on the image created in the previous stage.
FROM base

ARG UID="9999" \
    GID="9999" \
    VERSION \
    BUILD_DATE \
    REVISION

LABEL org.opencontainers.image.title="XASECO Server Controller" \
    org.opencontainers.image.description="Server controller for Trackmania Nations & Trackmania Forever." \
    org.opencontainers.image.authors="Nicolas Graf <nicolas.graf@evoesports.gg>" \
    org.opencontainers.image.vendor="Evo eSports e.V." \
    org.opencontainers.image.licenses="Apache-2.0" \
    org.opencontainers.image.version=${VERSION} \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${REVISION}

WORKDIR /xaseco

RUN true \
    && set -eux \
    && addgroup -g 9999 xaseco \
    && adduser -u 9999 -Hh /xaseco -G xaseco -s /sbin/nologin -D xaseco \
    && install -d -o xaseco -g xaseco -m 775 /xaseco \
    && chown xaseco:xaseco -Rf /xaseco \
    && apk add --force-overwrite --no-cache bash \
    && true

USER xaseco

COPY xaseco/xaseco.tar.gz /tmp

COPY --chmod=0755 xaseco/entrypoint.sh /usr/local/bin/

ENTRYPOINT ["entrypoint.sh"]
CMD [ "/usr/local/bin/php", "/xaseco/aseco.php" ]