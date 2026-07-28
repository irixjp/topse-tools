dd if=/dev/zero of=/disk01.img bs=1MB count=2048
ll -h /disk01.img
losetup -v /dev/loop0 /disk01.img
losetup

pvcreate /dev/loop0
pvs
vgcreate vg01 /dev/loop0
vgs
lvcreate -L 512MB -n lv01 vg01
lvcreate -L 1024MB -n lv02 vg01
lvs
vgs

targetcli ls /
targetcli /backstores/block create name=data01 dev=/dev/vg01/lv01
targetcli /backstores/block create name=data02 dev=/dev/vg01/lv02
targetcli ls /
targetcli /iscsi create iqn.1994-05.com.redhat:srv1
targetcli ls /

targetcli /iscsi/iqn.1994-05.com.redhat:srv1/tpg1/luns create /backstores/block/data01
targetcli /iscsi/iqn.1994-05.com.redhat:srv1/tpg1/luns create /backstores/block/data02
targetcli ls /

ssh -i /home/centos/id_rsa_handson centos@192.168.199.20

sudo -i
iscsiadm -m discovery --type sendtargets --portal 192.168.199.10
iscsiadm -m node -T iqn.1994-05.com.redhat:srv1 -p 192.168.199.10:3260 -l

cat /etc/iscsi/initiatorname.iscsi
exit
exit
targetcli ls

IQN_NAME=
targetcli /iscsi/iqn.1994-05.com.redhat:srv1/tpg1/acls create ${IQN_NAME:?}
targetcli ls

ssh -i /home/centos/id_rsa_handson centos@192.168.199.20
sudo -i
lsblk

iscsiadm -m node -T iqn.1994-05.com.redhat:srv1 -p 192.168.199.10:3260 -l
lsblk

fdisk /dev/sda

lsblk
mkfs.ext4 /dev/sda1

mkdir /mnt/iscsi01
df -h
mount /dev/sda1 /mnt/iscsi01
echo "My name is your_name" >> /mnt/iscsi01/my_file.txt
cat /mnt/iscsi01/my_file.txt

fdisk /dev/sdb

lsblk
mkfs.ext4 /dev/sdb1
mkdir /mnt/iscsi02
mount /dev/sdb1 /mnt/iscsi02
df -h
echo "This server is SRV2" >> /mnt/iscsi02/server_name.txt
cat /mnt/iscsi02/server_name.txt

cd
umount /mnt/iscsi01
umount /mnt/iscsi02

iscsiadm -m node
iscsiadm -m node -T iqn.1994-05.com.redhat:srv1 -p 192.168.199.10:3260 --logout
lsblk
exit
exit

cat /etc/iscsi/initiatorname.iscsi
targetcli ls

IQN_NAME=
targetcli /iscsi/iqn.1994-05.com.redhat:srv1/tpg1/acls create ${IQN_NAME:?}
targetcli ls
lsblk
iscsiadm -m discovery --type sendtargets --portal 192.168.199.10
iscsiadm -m node -T iqn.1994-05.com.redhat:srv1 -p 192.168.199.10:3260 -l

lsblk
blkid
mkdir /mnt/iscsi{01,02}
mount /dev/sda1 /mnt/iscsi01
mount /dev/sdb1 /mnt/iscsi02
df -h
find /mnt
cat /mnt/iscsi01/my_file.txt
cat /mnt/iscsi02/server_name.txt

cd
umount /mnt/iscsi01
umount /mnt/iscsi02
iscsiadm -m node -T iqn.1994-05.com.redhat:srv1 -p 192.168.199.10:3260 --logout
lsblk
exit


