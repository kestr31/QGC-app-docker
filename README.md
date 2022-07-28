# QGrooundControl Packaged in Docker Container

## Introductionm

## 1. Build

```shell
DOCKER_BUILDKIT=1 docker build --no-cache 
-t <IMAGE_NAME>:<TAG_NAME> .\
--build-ARG BASEIMAGE=Ubuntu:20.24
```

## 2. Run Container

### 2.1 For Generic Linux System

- Before entering command after boot, type `xhost +` first.
- For support of DRI (Direct Rendering Interface = H/W Acceleration), use following command:

```shell
docker run -it --rm \
   -e DISPLAY=$DISPLAY \
   -e QT_NO_MITSHM=1 \
   -e XDG_RUNTIME_DIR=/tmp \
   -v /tmp/.X11-unix:/tmp/.X11-unix \
   --net host \
   --device=/dev/dri:/dev/dri \
   --privileged \
   <IMAGE_NAME>:<TAG>
```

> If you are using Wayland as a display server protocol, (Ubuntu 22.034 or else) add following:<br/>
`-e WAYLAND_DISPLAY=$WAYLAND_DISPLAY`

### 2.2 With WSLg GPU Acceleration Support

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
   -e WAYLAND_DISPLAY=$WAYLAND_DISPLAY \
   -e QT_NO_MITSHM=1 \
   -e XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR \
   -e LD_LIBRARY_PATH=/usr/lib/wsl/lib \
   -v /tmp/.X11-unix:/tmp/.X11-unix \
   -v /mnt/wslg:/mnt/wslg \
   -v /usr/lib/wsl:/usr/lib/wsl \
   --device=/dev/dxg \
   --net host \
   --gpus all \
   --privileged \
   <IMAGE_NAME>:<TAG> bash
```