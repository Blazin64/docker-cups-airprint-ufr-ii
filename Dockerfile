#LABEL maintainer="znetwork@me.com"
LABEL version="0.1"
LABEL description="AIRPRINT FROM DOCKER (Canon UFR II)"

ENV CANON_DRIVER_URL='https://gdlp01.c-wss.com/gds/6/0100009236/20/linux-UFRII-drv-v600-us-02.tar.gz'

RUN apt-get update && apt-get install --no-install-recommends -y \
	locales \
	cups \
	cups-bsd \
	cups-pdf \
	cups-client \
	cups-filters \
	curl \
	inotify-tools \
	libcups2 \
	libcupsimage2 \
	libgtk-3.0 \
	libjpeg62 \
	libjbig0 \
	libgcrypt20 \
	lsb-release \
	avahi-daemon \
	avahi-discover \
	python3 \
	python3-dev \
	python3-pip \
	python3-cups \
	wget \
	zlib1g \
	rsync \
	&& rm -rf /var/lib/apt/lists/*

# Install UFRII drivers
RUN curl $CANON_DRIVER_URL | tar xz && \
    dpkg -i *-UFRII-*/x64/Debian/*ufr2*.deb && \
    rm -rf *-UFRII-*

# SMB --- TODO
EXPOSE 137/udp 139/tcp 445/tcp

# IPP
EXPOSE 631/tcp

# LDP
EXPOSE 515/tcp

# JetDirect / AppSocket
EXPOSE 9100

# Discovery (Avahi)
EXPOSE 5353/udp

# We want a mount for these
VOLUME /config
VOLUME /services

# Add scripts
ADD root /
RUN chmod +x /root/*

#Run Script
CMD ["/root/run_cups.sh"]

# Baked-in config file changes
RUN sed -i 's/Listen localhost:631/Listen *:631/' /etc/cups/cupsd.conf && \
	sed -i 's/Browsing No/Browsing On/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/>/<Location \/>\n  Allow All/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/admin>/<Location \/admin>\n  Allow All\n  Require user @SYSTEM/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/admin\/conf>/<Location \/admin\/conf>\n  Allow All/' /etc/cups/cupsd.conf && \
	sed -i 's/.*enable\-dbus=.*/enable\-dbus\=no/' /etc/avahi/avahi-daemon.conf && \
	echo "ServerAlias *" >> /etc/cups/cupsd.conf && \
	echo "DefaultEncryption Never" >> /etc/cups/cupsd.conf && \
	echo "BrowseWebIF Yes" >> /etc/cups/cupsd.conf
