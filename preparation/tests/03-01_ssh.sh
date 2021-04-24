source openrc
openstack stack output show handson03 password
get_heat_output handson03 private_key

ssh centos@192.168.199.10
vi ~/id_rsa_handson
chmod 600 ~/id_rsa_handson
ssh -i ~/id_rsa_handson centos@192.168.199.20
exit

ssh-keygen -P '' -f ~/id_rsa_handson_user
cat id_rsa_handson_user.pub
ssh -i ~/id_rsa_handson centos@192.168.199.20

sudo -i
useradd newuser
su - newuser

mkdir ~/.ssh/
vi ~/.ssh/authorized_keys
chmod 700 ~/.ssh/
chmod 600 ~/.ssh/authorized_keys
exit
exit
exit

ssh -i ~/id_rsa_handson_user newuser@192.168.199.20
id

exit


ssh -i ~/id_rsa_handson centos@192.168.199.20
sudo -i
rm -f /etc/ssh/ssh_host_*
systemctl restart sshd.service
ll /etc/ssh/

exit
exit

ssh -i ~/id_rsa_handson centos@192.168.199.20
rm ~/.ssh/known_hosts
ssh -i ~/id_rsa_handson centos@192.168.199.20

exit

