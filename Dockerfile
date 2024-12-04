ARG base=debian:12
FROM $base

ARG url=https://github.com/foswiki/distro/releases/download/FoswikiRelease02x01x08/Foswiki-2.1.8.tgz
ARG sha512=8d93e1eed145e5422380a20e0945aa759b1b9f1c3f6000213b1c28e15006f152c5330e89d313d75b1991c8a9dadc4766091f17721830b312ab8ced97ac92520d
ARG root=/var/www/foswiki
ARG user=www-data
ARG group=www-data
ARG port=80
ARG lang=C.UTF-8
ARG tz=Asia/Shanghai
ARG mirror=""

ENV LANG=$lang TZ=$tz

RUN set -eux; \
    [ -z "$mirror" ] || sed -i -E "s|http(s?)://deb.debian.org|$mirror|; s/^(Suites:\s+\w+\s+(\w+)-updates)/\1 \2-backports/" /etc/apt/sources.list.d/debian.sources; \
    apt update -y \
    && apt install -y curl diffutils grep less logrotate vim w3m \
        apache2 libapache2-mod-fcgid libapache2-mod-perl2 nginx \
        libalgorithm-diff-perl \
        libapache2-request-perl \
        libarchive-zip-perl \
        libcgi-session-perl \
        libconvert-pem-perl \
        libcrypt-eksblowfish-perl \
        libcrypt-passwdmd5-perl \
        libcrypt-smime-perl \
        libcrypt-x509-perl \
        libdbd-mariadb-perl \
        libdbd-mysql-perl \
        libdbd-pg-perl \
        libdbd-sqlite3-perl \
        libemail-address-xs-perl \
        libemail-mime-perl \
        libemail-simple-perl \
        liberror-perl \
        libfcgi-procmanager-perl \
        libfile-copy-recursive-perl \
        libfile-mmagic-xs-perl \
        libjson-perl \
        liblocale-codes-perl \
        liblocale-maketext-lexicon-perl \
        liblocale-msgfmt-perl \
    && apt install -y --no-install-recommends \
        libimage-magick-perl \
    && rm -rf /var/lib/apt/lists/* \
    && a2enmod access_compat rewrite \
    && a2dissite 000-default \
    && rm /etc/nginx/sites-enabled/default

RUN set -eux; \
    mkdir -p $root \
    && cd $root \
    && curl -L -s -o foswiki.tgz "$url" \
    && echo "$sha512  foswiki.tgz" > foswiki.tgz.sha512 \
    && sha512sum -c --status foswiki.tgz.sha512 \
    && tar -xzvf foswiki.tgz --strip-components=1 \
    && rm foswiki.tgz foswiki.tgz.sha512 \
    && sh tools/fix_file_permissions.sh \
    && chown -R $user:$group $root \
    && echo "0,30 * * * *  cd $root/bin && perl ../tools/tick_foswiki.pl" | crontab -u $user - \
    && cp tools/foswiki.init-script /etc/init.d/foswiki \
    && chmod 755 /etc/init.d/foswiki \
    && update-rc.d foswiki defaults \
    && cp tools/foswiki.defaults /etc/default/foswiki \
    && chmod 644 /etc/default/foswiki

COPY foswiki-apache.conf /etc/apache2/sites-enabled/foswiki.conf
COPY foswiki-nginx.conf /etc/nginx/sites-enabled/foswiki.conf
COPY start.sh /start.sh

VOLUME $root

EXPOSE $port

CMD ["/bin/sh", "/start.sh"]
