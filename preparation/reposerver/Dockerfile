FROM centos:8.3.2011

LABEL maintainer "@irix_jp"

RUN dnf install -y 'dnf-command(config-manager)' yum-utils httpd && \
    dnf config-manager --set-enabled powertools && \
    dnf install -y centos-release-openstack-train && \
    dnf install -y epel-release && \
    dnf clean all

RUN mkdir -p /var/www/html/repos && \
    REPOLIST=("baseos" "appstream" "extras" "powertools") && \
    for REPO in ${REPOLIST[@]}; do reposync -p /var/www/html/repos/ --repo=${REPO} --download-metadata; done && \
    chmod -R 755 /var/www/html/repos && \
    dnf clean all

RUN REPOLIST=("advanced-virtualization" "centos-openstack-train" "centos-rabbitmq-38" "ceph-nautilus") && \
    for REPO in ${REPOLIST[@]}; do reposync -p /var/www/html/repos/ --repo=${REPO} --download-metadata; done && \
    chmod -R 755 /var/www/html/repos && \
    dnf clean all

RUN REPOLIST=("epel" "epel-modular") && \
    for REPO in ${REPOLIST[@]}; do reposync -p /var/www/html/repos/ --repo=${REPO} --download-metadata; done && \
    chmod -R 755 /var/www/html/repos && \
    dnf clean all

RUN mkdir -p /var/www/html/images && \
    curl -L -o /var/www/html/images/CentOS-8-GenericCloud-8.3.2011-20201204.2.x86_64.qcow2 https://cloud.centos.org/centos/8/x86_64/images/CentOS-8-GenericCloud-8.3.2011-20201204.2.x86_64.qcow2 && \
    curl -L -o /var/www/html/images/CentOS-8.3.2011-x86_64-minimal.iso http://ftp.iij.ad.jp/pub/linux/centos/8.3.2011/isos/x86_64/CentOS-8.3.2011-x86_64-minimal.iso && \
    curl -L -o /var/www/html/images/cirros-0.5.2-x86_64-disk.img http://download.cirros-cloud.net/0.5.2/cirros-0.5.2-x86_64-disk.img && \
    chmod -R 755 /var/www/html/images

COPY edubase.repo /var/www/html/repos/edubase.repo

RUN date > /var/www/html/build_date.txt

EXPOSE 80
CMD ["/usr/sbin/httpd","-DFOREGROUND"]
