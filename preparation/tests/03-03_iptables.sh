sudo -i

echo "This is your_name's server" > /var/www/html/index.html
cat /var/www/html/index.html

curl localhost
curl 192.168.199.10

ssh -i /home/centos/id_rsa_handson centos@192.168.199.20

curl 192.168.199.10
exit

iptables -nvL
iptables -A INPUT -p tcp --dport 80 -j REJECT
iptables -nvL --line-numbers

curl 192.168.199.10

ssh -i /home/centos/id_rsa_handson centos@192.168.199.20
curl 192.168.199.10
exit

iptables -I INPUT 1 -p tcp -s 192.168.199.20 --dport 80 -j ACCEPT
iptables -nvL --line-numbers

ssh -i /home/centos/id_rsa_handson centos@192.168.199.20
curl 192.168.199.10
exit

service iptables save
cat /etc/sysconfig/iptables

iptables -F
iptables -nvL --line-numbers

service iptables restart
iptables -nvL --line-numbers
curl 192.168.199.10
