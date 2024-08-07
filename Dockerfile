ARG BASEIMAGE
ARG BASETAG

#          __                                     __ 
#    _____/ /_____ _____ ____        ____ _____  / /_
#   / ___/ __/ __ `/ __ `/ _ \______/ __ `/ __ \/ __/
#  (__  ) /_/ /_/ / /_/ /  __/_____/ /_/ / /_/ / /_  
# /____/\__/\__,_/\__, /\___/      \__,_/ .___/\__/  
#                /____/                /_/           

# BASE STAGE FOR CACHINE APT PACKAGE LISTS
FROM ${BASEIMAGE}:${BASETAG} as stage_apt

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV \
    DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

RUN \
    rm -rf /etc/apt/apt.conf.d/docker-clean \
	&& echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache \
	&& sed -i 's/archive.ubuntu.com/mirror.kakao.com/g' /etc/apt/sources.list \
    && apt-get update

RUN \
    apt install -y \
        ca-certificates \
        curl \
        software-properties-common \
        wget

RUN \
    add-apt-repository ppa:kisak/kisak-mesa -y


#          __                         _____             __
#    _____/ /_____ _____ ____        / __(_)___  ____ _/ /
#   / ___/ __/ __ `/ __ `/ _ \______/ /_/ / __ \/ __ `/ / 
#  (__  ) /_/ /_/ / /_/ /  __/_____/ __/ / / / / /_/ / /  
# /____/\__/\__,_/\__, /\___/     /_/ /_/_/ /_/\__,_/_/   
#                /____/                                   

FROM ${BASEIMAGE}:${BASETAG} as stage_final

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV \
    DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

RUN \
    sed -i 's/archive.ubuntu.com/mirror.kakao.com/g' /etc/apt/sources.list

COPY aptDeps.txt /tmp/aptDeps.txt

# UPGRADE THE BASIC ENVIRONMENT FIRST
RUN \
    --mount=type=cache,target=/var/cache/apt,from=stage_apt,source=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt,from=stage_apt,source=/var/lib/apt \
    --mount=type=cache,target=/etc/apt/sources.list.d,from=stage_apt,source=/etc/apt/sources.list.d \
	apt-get upgrade -y

# INSTALL ca-certifiactes TO AVOID CERTIFICATE ERROR FOR KISAK MESA DRIVERS
RUN \
    --mount=type=cache,target=/var/cache/apt,from=stage_apt,source=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt,from=stage_apt,source=/var/lib/apt \
    --mount=type=cache,target=/etc/apt/sources.list.d,from=stage_apt,source=/etc/apt/sources.list.d \
	apt-get install --no-install-recommends -y \
        ca-certificates

# INSTALL PACKAGES AVAIABLE BY APT REPOSITORY
RUN \
    --mount=type=cache,target=/var/cache/apt,from=stage_apt,source=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt,from=stage_apt,source=/var/lib/apt \
    --mount=type=cache,target=/etc/apt/sources.list.d,from=stage_apt,source=/etc/apt/sources.list.d \
	apt-get install --no-install-recommends -y $(cat /tmp/aptDeps.txt) \
    && rm -rf /tmp/*

RUN \
    groupadd user \
    && useradd -ms /bin/bash user -g user \
	&& usermod -a -G dialout user

COPY config /home/user/.config/QGroundControl.org

RUN \
    wget -P /home/user https://github.com/mavlink/qgroundcontrol/releases/download/v4.4.0/QGroundControl.AppImage \
    && chmod +x /home/user/QGroundControl.AppImage \
    && chown -R user:user /home/user \
    && locale-gen en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

USER user
WORKDIR /home/user

# ENTRYPOINT SCRIPT
# SET PERMISSION SO THAT USER CAN EDIT INSIDE THE CONTAINER
COPY --chown=user:user \
    entrypoint.sh /usr/local/bin/entrypoint.sh

# CREATE SYMBOLIC LINK FOR QUICK ACCESS
RUN \
    mkdir /home/user/scripts \
    && ln -s /usr/local/bin/entrypoint.sh /home/user/scripts/entrypoint.sh

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]

# docker run -it --rm \
#    -e DISPLAY=$DISPLAY \
#    -e QT_NO_MITSHM=1 \
#    -e XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR} \
#    -e HEADLESS=0 \
#    -v /tmp/.X11-unix:/tmp/.X11-unix \
#    --net host \
#    --device=/dev/dri:/dev/dri \
#    --privileged \
#    kestr3l/qgc-app:4.4.0

# DOCKER_BUILDKIT=1 docker build \
# --build-arg BASEIMAGE=ubuntu \
# --build-arg BASETAG=22.04 \
# -t kestr3l/qgc-app:4.4.0 \
# -f ./Dockerfile .