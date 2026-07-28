sudo -i
ip netns
ip addr

cd ~/
mkdir wwwroot1 wwwroot2
echo "wwwroot1 - 172.168.10.10" > wwwroot1/index.html
echo "wwwroot2 - 172.168.10.10" > wwwroot2/index.html

cd ~/wwwroot1
python -m SimpleHTTPServer 8001 &
curl localhost:8001

cd ~/wwwroot2
python -m SimpleHTTPServer 8001

python -m SimpleHTTPServer 8002 &
cd
curl localhost:8001
curl localhost:8002

ps -ef | grep "python -m SimpleHTTPServer"

kill -9 

ip netns add WWW1
ip netns add WWW2
ip netns
ip addr

ip tuntap add tap0 mode tap
ip addr

ip tuntap add tap0 mode tap
ip link set tap0 netns WWW1
ip addr

ip netns exec WWW1 ip addr
ip tuntap add tap0 mode tap
ip addr

ip link set tap0 netns WWW2
ip addr
ip netns exec WWW2 ip addr

ip netns exec WWW1 ip addr add 127.0.0.1/8 dev lo
ip netns exec WWW2 ip addr add 127.0.0.1/8 dev lo
ip netns exec WWW1 ip addr add 172.16.10.10/24 dev tap0
ip netns exec WWW2 ip addr add 172.16.10.10/24 dev tap0

ip netns exec WWW1 ip link set lo up
ip netns exec WWW2 ip link set lo up
ip netns exec WWW1 ip link set tap0 up
ip netns exec WWW2 ip link set tap0 up

ip netns exec WWW1 ip addr
ip netns exec WWW2 ip addr

ip netns exec WWW1 bash
cd ~/wwwroot1
python -m SimpleHTTPServer 8000 &
exit

ip netns exec WWW2 bash
cd ~/wwwroot2
python -m SimpleHTTPServer 8000 &
exit

ps -ef |grep SimpleHTTPServer
ip netns identify 
ip netns identify 

curl localhost:8000
ip netns exec WWW1 curl localhost:8000
ip netns exec WWW2 curl localhost:8000



