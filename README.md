# QGrooundControl Packaged in Docker Container

## 0. Introduction

- This repository includes resources for building QGroundControl application Docker conatiner image.
- This container is mainly used for deployment for SITL use.
- [Prebuilt images](https://hub.docker.com/r/kestr3l/qgc-app/tags) are available by Docker Hub.

## 1. List of Tags

|TAG|DESCRIPTION|Misc.|
|:-|:-|:-|
|`\<version\>`|Plain QGroundControl App. Container Image|-|
|`\<version\>-nobg`|QGrouncControl App. Container with no background map|-|

## 2. Build command

```shell
DOCKER_BUILDKIT=1 docker build \
--build-arg BASEIMAGE=ubuntu \
--build-arg BASETAG=22.04 \
-t kestr3l/qgc-app:4.2.9 \
-f ./Dockerfile .
```

## 3. Run Container

### 3.1. Run by `docker run`

> This method only only recommended for testing a container alone.

### 3.1.1. For Generic Linux System

- For support of DRI (Direct Rendering Interface = H/W Acceleration), use following command:

```shell
docker run -it --rm \
   -e DISPLAY=${DISPLAY} \
   -e QT_NO_MITSHM=1 \
   -e XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR} \
   -e HEADLESS=0 \
   -v /tmp/.X11-unix:/tmp/.X11-unix \
   --device=/dev/dri:/dev/dri \
   --privileged \
   kestr3l/qgc-app:4.2.9
```

> If you are using Wayland as a display server protocol, (Ubuntu 22.034 or else) add following:<br/>
`-e WAYLAND_DISPLAY=$WAYLAND_DISPLAY`

### 3.1.2. With WSLg GPU Acceleration Support

- WSL2 does support GPU acceleration via Direct-X **starting from Windows 11**
- Additional parameters should be handed over to use graphical H/W acceleration inside a docker container:
  - `-e LD_LIBRARY_PATH=/usr/lib/wsl/lib`
  - `-v /tmp/.X11-unix:/tmp/.X11-unix`
  - `-v /mnt/wslg:/mnt/wslg`
  - `-v /usr/lib/wsl:/usr/lib/wsl`
  - `--device=/dev/dxg \`
- **This is very recommended for WSL environment**

```shell
docker run -it --rm \
   -e DISPLAY=$DISPLAY \
   -e WAYLAND_DISPLAY=${WAYLAND_DISPLAY} \
   -e QT_NO_MITSHM=1 \
   -e XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR} \
   -e LD_LIBRARY_PATH=/usr/lib/wsl/lib \
   -e HEADLESS=0 \
   -v /tmp/.X11-unix:/tmp/.X11-unix \
   -v /mnt/wslg:/mnt/wslg \
   -v /usr/lib/wsl:/usr/lib/wsl \
   --device=/dev/dxg \
   --gpus all \
   --privileged \
   kestr3l/qgc-app:4.2.9
```

### 3.2. Run by `docker compose`

- Since QGC is usually used as a GCS for SILS/HILS, deploying a container using `docker compose` is strongly recommended.
- Configuration of `docker-compose.yml` will vary based on user's need.
- On this manual, snippet for adding QGC deployment on `docker-compse.yml` is suggested.

#### 3.2.1. `docker-compose.yml` QGC Snnipets

```shell
version: "3"
services:
  qgc:
    privileged: true
    environment:
      # -----------DEFAULT VALUE DO NOT MODIFY-----------
      DISPLAY:          :0
      QT_NO_MITSHM:     1
      XDG_RUNTIME_DIR:  /run/user/1000
      HEADLESS:         0
    volumes:
      - ${X11_SOCKET_DIR}:/tmp/.X11-unix
    devices:
      - /dev/dri/card0
      - /dev/dri/renderD128
    container_name:     qgc-container
    hostname:           qgc-container
    image:              kestr3l/qgc-app:4.2.9
```

> You can also check [this example](https://github.com/kestr31/px4-container/blob/exp/AirSim-Gazebo/docker-compose.yml) for more usage in `docker-compose.yml`

## 4. Additional Tips

### 4.1. Remove Background Map

- If you add following lines in `QGroundControl.ini`, you can remove background map from QGC:

```
[FlightMap]
mapProvider=CustomURL
mapType=Custom
```

### 4.2 Running in Headless Mode

- The container contains `xvfb`. Which is: it can be run on headless mode.
- In order to use this feature, set `HEADLESS` environment variable as `1`.