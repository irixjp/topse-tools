# コンテナビルド

``` shell
dnf install -y podman

IMAGE_NAME=irixjp/topse-cloud-repo:train-v1.4
podman build -t ${IMAGE_NAME:?} .

podman login docker.io

podman images
podman push 752ae24a66ff docker.io/${IMAGE_NAME:?}
```
