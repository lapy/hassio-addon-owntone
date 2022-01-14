FROM linuxserver/daapd:28.2.20211118

ARG BUILD_ARCH=amd64

RUN apk add --no-cache jq

RUN sed -i -e s#"ipv6 = yes"#"ipv6 = no"#g /etc/owntone.conf.orig \
    && sed -i s#/srv/music#/share/owntone/music#g /etc/owntone.conf.orig \
    && sed -i s#/var/cache/owntone/songs3.db#/share/owntone/dbase_and_logs/songs3.db#g /etc/owntone.conf.orig \
    && sed -i s#/var/cache/owntone/cache.db#/share/owntone/dbase_and_logs/cache.db#g /etc/owntone.conf.orig \
    && sed -i s#/var/log/owntone.log#/share/owntone/dbase_and_logs/owntone.log#g /etc/owntone.conf.orig \
    && sed -i "/websocket_port\ =/ s/# *//" /etc/owntone.conf.orig \
    && sed -i "/trusted_networks\ =/ s/# *//" /etc/owntone.conf.orig \
    && sed -i "/pipe_autostart\ =/ s/# *//" /etc/owntone.conf.orig \
    && sed -i "/airplay_shared/ s/# *//" /etc/owntone.conf.orig \
    && sed -i "/control_port\ =/ s/#/ /" /etc/owntone.conf.orig \
    && sed -i "/timing_port\ =/ s/#/ /" /etc/owntone.conf.orig \
    && sed -i "/timing_port/{N;s/\n#/\n/}" /etc/owntone.conf.orig \
    && sed -i "s/\(control_port =\).*/\1 3690/" /etc/owntone.conf.orig \
    && sed -i "s/\(timing_port =\).*/\1 3691/" /etc/owntone.conf.orig \
    && sed -i "/type\ =/ s/#/ /" /etc/owntone.conf.orig \
    && sed -i 's/\(type =\).*/\1 "pulseaudio"/' /etc/owntone.conf.orig

ADD 90-homeassistant /etc/cont-init.d/90-homeassistant

RUN chmod +x /etc/cont-init.d/90-homeassistant

RUN \
    set -o pipefail \
    \
    && apk add --no-cache --virtual .build-dependencies \
        tar \
    \
    && apk add --no-cache \
        libcrypto1.1 \
        libssl1.1 \
        musl-utils \
        musl \
    \
    && apk add --no-cache \
        bash \
        curl \
        jq \
        tzdata \
    \
    && S6_ARCH="${BUILD_ARCH}" \
    && if [ "${BUILD_ARCH}" = "i386" ]; then S6_ARCH="x86"; fi \
    && if [ "${BUILD_ARCH}" = "armv7" ]; then S6_ARCH="arm"; fi \
    \
    && curl -L -s "https://github.com/just-containers/s6-overlay/releases/download/v2.2.0.3/s6-overlay-${S6_ARCH}.tar.gz" \
        | tar zxvf - -C / \
    \
    && mkdir -p /etc/fix-attrs.d \
    && mkdir -p /etc/services.d \
    \
    && curl -J -L -o /tmp/bashio.tar.gz \
        "https://github.com/hassio-addons/bashio/archive/v0.14.3.tar.gz" \
    && mkdir /tmp/bashio \
    && tar zxvf \
        /tmp/bashio.tar.gz \
        --strip 1 -C /tmp/bashio \
    \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    \
    && curl -L -s -o /usr/bin/tempio \
        "https://github.com/home-assistant/tempio/releases/download/2021.09.0/tempio_${BUILD_ARCH}" \
    && chmod a+x /usr/bin/tempio \
    \
    && apk del --no-cache --purge .build-dependencies \
    && rm -f -r \
        /tmp/*
	
# Setup base
# hadolint ignore=DL3003
RUN \
    apk add --no-cache --virtual .build-dependencies \
        build-base \
        git \
        protobuf-dev \
        pulseaudio-dev \
    \
    && apk add --no-cache \
        pulseaudio \
    \
    && apk del --no-cache --purge .build-dependencies \
    && rm -fr \
        /tmp/*
