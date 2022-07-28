ARG BASEIMAGE=ubuntu
ARG BASETAG=20.04

FROM ${BASEIMAGE}:${BASETAG} as stage_apt

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV \
    DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN \
    rm -f /etc/apt/apt.conf.d/docker-clean \
	&& echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache \
	&& apt-get update


FROM ${BASEIMAGE}:${BASETAG} as stage_deps

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV \
    DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

COPY aptdeps.txt /tmp/aptdeps.txt

RUN \
    --mount=type=cache,target=/var/cache/apt,from=stage_apt,source=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt,from=stage_apt,source=/var/lib/apt \
    --mount=type=cache,target=/etc/apt/sources.list.d,from=stage_apt,source=/etc/apt/sources.list.d \
	apt-get install --no-install-recommends -y $(cat /tmp/aptdeps.txt) \
    && rm -rf /tmp/*

RUN \
  useradd --shell /bin/bash -u 1000 -c "" -m user \
	&& usermod -a -G dialout user

COPY config /home/user/.config/QGroundControl.org

RUN \
    wget -P /home/user https://d176tv9ibo4jno.cloudfront.net/latest/QGroundControl.AppImage \
    && chmod +x /home/user/QGroundControl.AppImage \
    && chown -R user:user /home/user

WORKDIR /home/user
USER user

ENTRYPOINT ["/bin/bash","-l","-c","/home/user/QGroundControl.AppImage"]