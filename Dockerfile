FROM linuxserver/daapd:28.2.20211118

ARG BUILD_ARCH

RUN apk add --no-cache jq

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
    && rm -fr \
        /tmp/*


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
