# Some materials of Cloud infrastructure design and deployment course

# Requirement

必要パッケージ
```
yum install -y epel-release
yum install -y qemu-kvm libvirt virt-manager virt-install \
               libguestfs libguestfs-tools \
               docker \
               screen tmux jq ansible git
```

ディレクトリの設定
```
mv /var/lib/docker /mnt
ln -s /mnt/docker /var/lib/docker
rm -Rf /var/lib/docker/*

mv /var/lib/libvirt/images /mnt
ln -s /mnt/images /var/lib/libvirt/images
```

300GBのイメージまで作れるようにする（デフォ10GB）
```
vi /etc/sysconfig/docker-storage
DOCKER_STORAGE_OPTIONS="-g /mnt/docker --storage-opt=dm.basesize=300G"
```

```
systemctl stop firewalld
systemctl disable firewalld
systemctl enable docker
systemctl start  docker

reboot
```

```

docker run -d -p 80:80 \
       --name repo \
       -v /mnt/topse-tools/hands-on:/var/www/html/hands-on \
       -v /mnt/topse-tools/preparation:/var/www/html/preparation \
       irixjp/topse-cloud-repo:newton-v1.0
```
