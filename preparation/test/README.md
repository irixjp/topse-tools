テスト環境の整備
```
bash ./create_virtual_network.sh
virsh net-define ./virbr100.xml
virsh net-start virbr100
```

```
cd /mnt/topse-tools/preparation/test
ansible localhost -i etc/ansible_hosts -u root -m ping

chmod 600 ansible_key
export ANSIBLE_HOST_KEY_CHECKING=False

ansible-playbook -i etc/ansible_hosts -u root 01_create_instances.yaml
ansible-playbook -i etc/ansible_hosts -u root --private-key=ansible_key 02_pre-configuration.yaml

```
