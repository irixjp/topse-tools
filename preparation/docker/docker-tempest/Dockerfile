FROM centos:7

LABEL Description="This images is tempest that test openstack env" Version="1.0"

MAINTAINER @irix_jp

ARG reposerver_ip

RUN echo $reposerver_ip reposerver >> /etc/hosts && \
    cat /etc/hosts && \
    rm -Rf /etc/yum.repos.d/* && \
    curl -o /etc/yum.repos.d/edubase.repo http://reposerver/repo/edubase.repo && \
    yum clean all && \
    yum repolist

RUN echo $reposerver_ip reposerver >> /etc/hosts && \
    yum update -y && \
    rm -Rf /etc/yum.repos.d/CentOS*

RUN echo $reposerver_ip reposerver >> /etc/hosts && \
    yum install -y openssh-server supervisor gcc python-devel libffi-devel openssl-devel git python-pip crudini && \
    ls -alF /etc/yum.repos.d

RUN echo "root:password" | chpasswd  

RUN mkdir -p /var/run/sshd && \
    ssh-keygen -t rsa     -f /etc/ssh/ssh_host_rsa_key     -C '' -N '' && \
    ssh-keygen -t ecdsa   -f /etc/ssh/ssh_host_ecdsa_key   -C '' -N '' && \
    ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -C '' -N '' && \
    sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd  
  
RUN mkdir -p /var/run/supervisord
ADD supervisord.d/sshd.ini /etc/supervisord.d/sshd.ini

RUN echo $reposerver_ip reposerver >> /etc/hosts && \
    cd /root && \
    git clone https://github.com/redhat-openstack/tempest.git && \
    cd tempest && \
    git checkout -b newton origin/newton && \
    cd /root && \
    pip install --upgrade setuptools pip && \
    pip install tempest/  && \
    pip install tox

EXPOSE 22  

ENV OS_AUTH_URL http://192.168.100.100:5000
ENV OS_OS_REGION_NAME RegionOne
ENV OS_TENANT_NAME admin
ENV OS_USERNAME admin
ENV OS_PASSWORD password

CMD cd /root/tempest && \
    tempest init workdir && \
    cd workdir && \
    