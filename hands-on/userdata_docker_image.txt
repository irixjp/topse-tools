#!/bin/bash
setenforce 0
sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

## set repogitry

mkdir -p /root/temp

echo "157.1.141.21 reposerver" >> /etc/hosts

rm -f /etc/yum.repos.d/*
curl -o /etc/yum.repos.d/edubase.repo http://reposerver/repo/edubase.repo
yum clean all
yum repolist

yum update -y
rm -f /etc/yum.repos.d/CentOS*
rm -f /etc/yum.repos.d/epel*

## Install dependency packages
yum install -y docker python-docker-py ansible gcc python-devel python-pip
pip install shade python-heatclient

systemctl disable firewalld.service
systemctl stop    firewalld.service

systemctl enable docker.service
systemctl start  docker.service


echo "### finish!! ###"

reboot
