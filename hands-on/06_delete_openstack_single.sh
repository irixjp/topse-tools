#!/bin/bash

cd ~/
source openrc

# 0. サーバーの削除
openstack server delete openstack-single

# 1. ポートの削除
openstack port delete handson06-cc-eth0 handson06-cc-eth1

# 2. ルーターからのサブネット解除
openstack router remove subnet Ext-Router handson06-subnet

# 3. サブネットの削除
openstack subnet delete handson06-subnet

# 4. ネットワークの削除
openstack network delete handson06-net

# 5. キーペアの削除（およびローカルファイルの削除）
openstack keypair delete handson06-key
rm -f handson06-key.pem
