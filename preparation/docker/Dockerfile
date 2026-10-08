FROM rockylinux:9

RUN dnf install -y nginx dnf-plugins-core createrepo_c && \
    dnf config-manager --enable crb && \
    dnf install -y centos-release-openstack-epoxy && \
    dnf clean all

COPY repo.conf /etc/nginx/conf.d/repo.conf

SHELL ["/bin/bash", "-c"]

RUN for i in 1 2 3; do dnf reposync --repoid=baseos --download-metadata -p /usr/share/nginx/html/ && break || sleep 30; done
RUN for i in 1 2 3; do dnf reposync --repoid=appstream --download-metadata -p /usr/share/nginx/html/ && break || sleep 30; done
RUN for i in 1 2 3; do dnf reposync --repoid=crb --download-metadata -p /usr/share/nginx/html/ && break || sleep 30; done
RUN for i in 1 2 3; do dnf reposync --repoid=extras --download-metadata -p /usr/share/nginx/html/ && break || sleep 30; done
RUN for i in 1 2 3; do dnf reposync --repoid=centos-openstack-epoxy --download-metadata -p /usr/share/nginx/html/ && break || sleep 30; done
RUN for i in 1 2 3; do dnf reposync --repoid=centos-ceph-reef --download-metadata -p /usr/share/nginx/html/ && break || sleep 30; done
RUN for i in 1 2 3; do dnf reposync --repoid=centos-nfv-openvswitch --download-metadata -p /usr/share/nginx/html/ && break || sleep 30; done
RUN for i in 1 2 3; do dnf reposync --repoid=centos-rabbitmq-38 --download-metadata -p /usr/share/nginx/html/ && break || sleep 30; done

RUN dnf clean all && rm -rf /var/cache/dnf

RUN curl -sL -o /usr/share/nginx/html/cirros.img \
      https://download.cirros-cloud.net/0.6.2/cirros-0.6.2-x86_64-disk.img && \
    curl -sL -o /usr/share/nginx/html/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2 \
      https://download.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
