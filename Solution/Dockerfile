FROM bandi13/docker-obs

ENV VNC_PASSWD=123456
EXPOSE 5901

RUN apt update && apt install -y \
    pulseaudio socat alsa-utils ffmpeg \
    nano

# SED load-module module-native-protocol-tcp auth-anonymous=1
RUN sed -i \
    's/native-protocol-unix/native-protocol-unix auth-anonymous=1/g' /etc/pulse/system.pa

RUN adduser root audio && \
    mkdir -p /var/run/dbus

RUN dbus-uuidgen > /var/lib/dbus/machine-id && \
    dbus-daemon --config-file=/usr/share/dbus-1/system.conf --print-address

RUN echo "pulseaudio -vvv --exit-idle-time=-1 --system" >  /opt/startup_scripts/start_audio.sh


