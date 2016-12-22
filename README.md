# Some materials of Cloud infrastructure design and deployment course

# Requirement

必要パッケージ
```
yum install -y epel-release
yum install -y qemu-kvm libvirt virt-manager virt-install \
               libguestfs libguestfs-tools \
               docker-io \
               screen tmux jq
```

ディレクトリの設定
```
mv /var/lib/docker /mnt
ln -s /mnt/docker /var/lib/docker
rm -Rf /var/lib/docker/*

mv /var/lib/libvirt/images /mnt
ln -s /mnt/images /var/lib/libvirt/images
```

100GBのイメージまで作れるようにする（デフォ10GB）
```/etc/sysconfig/docker-storage
DOCKER_STORAGE_OPTIONS="-g /mnt/docker --storage-opt=dm.basesize=100G"
```

```
systemctl stop firewalld
systemctl disable firewalld
systemctl enable docker
systemctl start  docker

reboot
```
