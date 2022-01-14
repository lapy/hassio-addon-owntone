ARG BUILD_FROM=ghcr.io/hassio-addons/base/amd64:11.0.0
# hadolint ignore=DL3006
FROM ${BUILD_FROM} as buildstage

############## build stage ##############

ARG DAAPD_RELEASE

RUN \
 echo "**** install build packages ****" && \
 apk add --no-cache \
	alsa-lib-dev \
	autoconf \
	automake \
	avahi-dev \
	bash \
	bsd-compat-headers \
	confuse-dev \
	curl \
	curl-dev \
	ffmpeg-dev \
	file \
	flac-dev \
	g++ \
	gcc \
	gettext-dev \
	gnutls-dev \
	gperf \
	json-c-dev \
	libcurl \
	libevent-dev \
	libgcrypt-dev \
	libogg-dev \
	libplist-dev \
	libressl-dev \
	libsodium-dev \
	libtool \
	libunistring-dev \
	libwebsockets-dev \
	make \
	openjdk8-jre-base \
	protobuf-c-dev \
	sqlite-dev \
	taglib-dev \
    jq \
	tar && \
 apk add --no-cache \
	--repository http://nl.alpinelinux.org/alpine/edge/community \
	mxml-dev && \
 echo "**** make antlr wrapper ****" && \
 mkdir -p \
	/tmp/source/owntone && \
 echo \
	"#!/bin/bash" > /tmp/source/antlr3 && \
 echo \
	"exec java -cp /tmp/source/antlr-3.4-complete.jar org.antlr.Tool \"\$@\"" >> /tmp/source/antlr3 && \
 chmod a+x /tmp/source/antlr3 && \
 curl -o \
 /tmp/source/antlr-3.4-complete.jar -L \
	http://www.antlr3.org/download/antlr-3.4-complete.jar && \
 echo "**** compile and install antlr3c ****" && \
 curl -o \
 /tmp/libantlr3c-3.4.tar.gz -L \
	https://github.com/antlr/website-antlr3/raw/gh-pages/download/C/libantlr3c-3.4.tar.gz && \
 tar xf /tmp/libantlr3c-3.4.tar.gz  -C /tmp && \
 cd /tmp/libantlr3c-3.4 && \
 ./configure --build arm-unknown-linux-gnueabi --disable-abiflags --disable-antlrdebug --enable-64bit --prefix=/usr && \
 make && \
 make DESTDIR=/tmp/antlr3c-build install && \
 export LDFLAGS="-L/tmp/antlr3c-build/usr/lib" && \
 export CFLAGS="-I/tmp/antlr3c-build/usr/include" && \
 echo "**** compile owntone-server ****" && \
 if [ -z ${DAAPD_RELEASE+x} ]; then \
	DAAPD_RELEASE=$(curl -sX GET "https://api.github.com/repos/owntone/owntone-server/releases/latest" \
	| awk '/tag_name/{print $4;exit}' FS='[""]'); \
 fi && \
 curl -o \
 /tmp/source/owntone.tar.gz -L \
	"https://github.com/owntone/owntone-server/archive/${DAAPD_RELEASE}.tar.gz" && \
 tar xf /tmp/source/owntone.tar.gz -C \
	/tmp/source/owntone --strip-components=1 && \
 export PATH="/tmp/source:$PATH" && \
 cd /tmp/source/owntone && \
 autoreconf -i -v && \
 ./configure \
	--build=$CBUILD \
	--disable-avcodecsend \
	--enable-chromecast \
	--enable-itunes \
	--enable-lastfm \
	--enable-mpd \
	--host=$CHOST \
	--infodir=/usr/share/info \
	--localstatedir=/var \
	--mandir=/usr/share/man \
	--prefix=/usr \
	--sysconfdir=/etc && \
 make && \
 make DESTDIR=/tmp/daapd-build install && \
 mv /tmp/daapd-build/etc/owntone.conf /tmp/daapd-build/etc/owntone.conf.orig
 
RUN \
    apk add --no-cache --virtual .build-dependencies \
        build-base=0.5-r2 \
        git=2.34.1-r0 \
        protobuf-dev=3.18.1-r1 \
        pulseaudio-dev=15.0-r2 \
    \
    && apk add --no-cache \
        pulseaudio=15.0-r2 \
    \
    && apk del --no-cache --purge .build-dependencies \
    && rm -fr /tmp/*
############## runtime stage ##############
FROM ${BUILD_FROM}
ARG BUILD_ARCH
# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="BernsteinA"

RUN \
 echo "**** install runtime packages ****" && \
 apk add --no-cache \
	avahi \
	confuse \
	dbus \
	ffmpeg \
	json-c \
	libcurl \
	libevent \
	libgcrypt \
	libplist \
	libressl \
	libsodium \
	libunistring \
	libwebsockets \
	protobuf-c \
	sqlite \
	sqlite-libs && \
 apk add --no-cache \
	--repository http://nl.alpinelinux.org/alpine/edge/community \
	mxml && \
 apk add --no-cache \
    --repository https://dl-cdn.alpinelinux.org/alpine/edge/testing \
    librespot

# copy buildstage and local files
COPY --from=buildstage /tmp/daapd-build/ /
COPY --from=buildstage /tmp/antlr3c-build/ /
COPY root/ /

# ports and volumes
EXPOSE 3689
VOLUME /config /music

##################################



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
