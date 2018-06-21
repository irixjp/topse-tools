TOPSE クラウド基盤構築演習用 リポジトリサーバーコンテナ
=========

# BUILD方法

```shell
$ REPO_VERSION=queens-latest

$ docker build -t irixjp/topse-cloud-repo:${REPO_VERSION} --no-cache=true --force-rm=true --rm=true .
```

# アップロード方法

```shell
$ docker push irixjp/topse-cloud-repo:${REPO_VERSION}
```

# 利用方法

```shell
$ docker run -d -p 80:80 \
    --name repo \
    -v /mnt/topse-tools/hands-on:/var/www/html/hands-on \
    -v /mnt/topse-tools/preparation:/var/www/html/preparation \
    -v /mnt/dvd:/var/www/html/dvd \
    irixjp/topse-cloud-repo:${REPO_VERSION}

```
