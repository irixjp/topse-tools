FROM centos:8

LABEL maintainer "@irix_jp"

ENV JP_CONF_PATH /jupyter/.jupyter

RUN dnf update -y && \
    dnf install -y glibc-all-langpacks git sudo which tree jq && \
    dnf install -y epel-release && dnf install -y sshpass && \
    dnf module install -y python38:3.8/common && \
    dnf module install -y python38:3.8/build && \
    dnf module install -y nodejs:12/common && \
    alternatives --set python /usr/bin/python3 && \
    dnf clean all

RUN pip3 install -U pip setuptools && \
    pip install ansible-core==2.11.5 && \
    pip install openstacksdk==0.59.0 && \
    pip install jupyterlab && \
    rm -rf ~/.cache/pip

RUN ansible-galaxy collection install -p /usr/share/ansible/collections openstack.cloud

RUN jupyter labextension install -y @jupyterlab/toc && \
    jupyter labextension install -y @jupyter-widgets/jupyterlab-manager

RUN useradd jupyter -m -d /jupyter && \
    mkdir -p /notebooks && \
    chown -R jupyter:jupyter /notebooks && \
    echo 'jupyter ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER jupyter
WORKDIR /jupyter

COPY --chown=jupyter:jupyter assets/.jupyter /jupyter/.jupyter
COPY --chown=jupyter:jupyter assets/.ansible.cfg /jupyter/.ansible.cfg

RUN echo "alias ls='ls --color'" >> /jupyter/.bashrc  && \
    echo "alias ll='ls -alF --color'" >> /jupyter/.bashrc

EXPOSE 8888
CMD ["jupyter", "lab", "--ip", "0.0.0.0", "--port", "8888", "--no-browser"]
