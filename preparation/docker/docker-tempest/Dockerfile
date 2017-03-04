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
ENV OS_AUTH_VERSION v3

CMD cd /root/tempest && \
    tempest init workdir && \
    cd workdir && \
    crudini --set etc/tempest.conf auth admin_username $OS_USERNAME && \
    crudini --set etc/tempest.conf auth admin_password $OS_PASSWORD && \
    crudini --set etc/tempest.conf auth admin_project_name $OS_USERNAME && \
    crudini --set etc/tempest.conf auth admin_domain_name default && \
    crudini --set etc/tempest.conf identity uri $OS_AUTH_URL/v2.0 && \
    crudini --set etc/tempest.conf identity uri_v3 $OS_AUTH_URL/v3 && \
    crudini --set etc/tempest.conf identity region $OS_OS_REGION_NAME && \
    crudini --set etc/tempest.conf identity auth_version $OS_AUTH_VERSION && \
    crudini --set etc/tempest.conf service_available cinder yes && \
    crudini --set etc/tempest.conf service_available neutron yes && \
    crudini --set etc/tempest.conf service_available glance yes && \
    crudini --set etc/tempest.conf service_available swift yes && \
    crudini --set etc/tempest.conf service_available nova yes && \
    crudini --set etc/tempest.conf service_available heat yes && \
    crudini --set etc/tempest.conf service_available horizon yes && \
    crudini --set etc/tempest.conf service_available ceilometer no && \
    crudini --set etc/tempest.conf service_available sahara false && \
    crudini --set etc/tempest.conf service_available ironic false && \
    crudini --set etc/tempest.conf dashboard dashboard_url ${OS_AUTH_URL}/  && \
    crudini --set etc/tempest.conf dashboard login_url ${$OS_AUTH_URL}/auth/login  && \
    supervisord -n
    