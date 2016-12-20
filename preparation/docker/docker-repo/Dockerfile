FROM centos:7

LABEL Description="This is the yum repository server that has CentOS7, EPEL and OpenStack for a TOPSE class" Version="1.2"

MAINTAINER @irix_jp

RUN yum install -y https://repos.fedorapeople.org/repos/openstack/openstack-mitaka/rdo-release-mitaka-6.noarch.rpm \
    && yum install -y epel-release \
    && yum clean all \
    && yum repolist

RUN yum install -y createrepo yum-utils httpd supervisor bash-completion git vim wget

RUN mkdir -p /var/www/html/openstack/{repo/centos7,tools,images,prepare}

RUN cd /var/www/html/openstack/repo/centos7 && reposync -l --repoid=base             --downloadcomps --download-metadata && createrepo -v base    -g comps.xml
RUN cd /var/www/html/openstack/repo/centos7 && reposync -l --repoid=updates          --downloadcomps --download-metadata && createrepo -v updates
RUN cd /var/www/html/openstack/repo/centos7 && reposync -l --repoid=extras           --downloadcomps --download-metadata && createrepo -v extras
RUN cd /var/www/html/openstack/repo/centos7 && reposync -l --repoid=epel             --downloadcomps --download-metadata && createrepo -v epel    -g comps.xml
RUN cd /var/www/html/openstack/repo/centos7 && reposync -l --repoid=openstack-mitaka --downloadcomps --download-metadata && createrepo -v openstack-mitaka

RUN yum clean all

RUN wget -q -t 5 -O /var/www/html/openstack/images/CentOS-7-x86_64-GenericCloud.qcow2 http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud-1608.qcow2
RUN wget -q -t 5 -O /var/www/html/openstack/images/cirros-x86_64-disk.img http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img

ADD edubase.repo /var/www/html/openstack/repo
ADD supervisord.d/httpd.ini /etc/supervisord.d

EXPOSE 80

CMD supervisord -n
