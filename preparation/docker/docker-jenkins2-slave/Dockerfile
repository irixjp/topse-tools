FROM centos:7

LABEL Description="This images is jenkin slave is for a TOPSE class" Version="1.0"

MAINTAINER @irix_jp

ARG reposerver_ip

RUN echo $reposerver_ip reposerver >> /etc/hosts && \
    cat /etc/hosts && \
    rm -Rf /etc/yum.repos.d/* && \
    curl -o /etc/yum.repos.d/edubase.repo http://reposerver/openstack/repo/edubase.repo && \
    yum clean all && \
    yum repolist

RUN echo $reposerver_ip reposerver >> /etc/hosts && \
    yum update -y

RUN echo $reposerver_ip reposerver >> /etc/hosts && \
    yum install -y openssh-server \
                   supervisor \
                   java-1.7.0-openjdk \
                   rpm-build \
                   redhat-rpm-config \
                   make \
                   git 

RUN echo "root:password" | chpasswd  

RUN useradd jenkins -m -d /build && \
    echo "jenkins:jenkins" | chpasswd && \
    su - jenkins -c 'ssh-keygen -t rsa -f ~/.ssh/id_rsa  -P ""' && \
    su - jenkins -c 'cat ~/.ssh/id_rsa' && \
    su - jenkins -c 'cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys' && \
    su - jenkins -c 'chmod 600 ~/.ssh/authorized_keys'

RUN mkdir -p /var/run/sshd && \
    ssh-keygen -t rsa     -f /etc/ssh/ssh_host_rsa_key     -C '' -N '' && \
    ssh-keygen -t ecdsa   -f /etc/ssh/ssh_host_ecdsa_key   -C '' -N '' && \
    ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -C '' -N '' && \
    sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd  
  
RUN mkdir -p /var/run/supervisord
ADD supervisord.d/sshd.ini /etc/supervisord.d/sshd.ini

RUN echo $reposerver_ip reposerver >> /etc/hosts && \
    yum install -y ansible \
                   python-openstackclient \
                   python-novaclient \
                   python-swiftclient \
                   python-glanceclient \
                   python-keystoneclient \
                   python-neutronclient \
                   python-cinderclient \
                   python-heatclient \
                   python-troveclient \
                   python-saharaclient

EXPOSE 22  

CMD supervisord -n
