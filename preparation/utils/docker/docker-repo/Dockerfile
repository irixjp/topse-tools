FROM centos:7

LABEL Version="10.2"
LABEL Description="This is the yum repository server that has CentOS7, EPEL and OpenStack for a TOPSE class. \
docker run -d -p 80:80 \
       --name repo \
       -v /mnt/topse-tools/hands-on:/var/www/html/hands-on \
       -v /mnt/topse-tools/preparation:/var/www/html/preparation \
       irixjp/topse-cloud-repo:version"

MAINTAINER @irix_jp

RUN yum install -y centos-release-openstack-queens epel-release \
    && yum clean all \
    && yum repolist \
    && yum install -y createrepo yum-utils httpd supervisor bash-completion git vim wget \
    && mkdir -p /var/www/html/{repo/centos/7,hands-on,images,preparation} \
    && yum clean all

RUN cd /var/www/html/repo/centos/7 && reposync -l --repoid=base                    --downloadcomps --download-metadata && createrepo -v base    -g comps.xml
RUN cd /var/www/html/repo/centos/7 && reposync -l --repoid=updates                 --downloadcomps --download-metadata && createrepo -v updates
RUN cd /var/www/html/repo/centos/7 && reposync -l --repoid=extras                  --downloadcomps --download-metadata && createrepo -v extras
RUN cd /var/www/html/repo/centos/7 && reposync -l --repoid=epel                    --downloadcomps --download-metadata && createrepo -v epel    -g comps.xml
RUN cd /var/www/html/repo/centos/7 && reposync -l --repoid=centos-openstack-queens --downloadcomps --download-metadata && createrepo -v centos-openstack-queens
RUN cd /var/www/html/repo/centos/7 && reposync -l --repoid=centos-qemu-ev          --downloadcomps --download-metadata && createrepo -v centos-qemu-ev
RUN cd /var/www/html/repo/centos/7 && reposync -l --repoid=centos-ceph-luminous    --downloadcomps --download-metadata && createrepo -v centos-ceph-luminous

RUN yum clean all

RUN wget -q -t 5 -O /var/www/html/images/CentOS-7-x86_64-GenericCloud.qcow2 http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud-1805.qcow2
RUN wget -q -t 5 -O /var/www/html/images/cirros-x86_64-disk.img             http://download.cirros-cloud.net/0.3.5/cirros-0.3.5-x86_64-disk.img
RUN wget -q -t 5 -O /var/www/html/images/Cent7-Mini.iso                     http://ftp.iij.ad.jp/pub/linux/centos/7/isos/x86_64/CentOS-7-x86_64-Minimal-1804.iso

COPY edubase.repo /var/www/html/repo
COPY supervisord.d/httpd.ini /etc/supervisord.d

EXPOSE 80

CMD supervisord -n
