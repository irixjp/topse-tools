#!/bin/bash
# 第 8・10 回の演習で、ホストのネットワークの構成を図（SVG）にする。root で実行する。
#   使い方: bash netmap.sh <名前> [ホスト]
#     → /var/www/html/<名前>.svg（ブラウザで http://<実行したホストの Floating IP>/<名前>.svg）
#   第 8 回は single で、ホストを付けずに実行する（single 自身の構成を描く）。
#   第 10 回は multi の cc で実行し、ホストを付けると、そのホスト（node1・node2）の構成を ssh で読んで描く。
# plotnetcfg の出力（dot）から、演習に関係ないもの（lo、IPv6 のリンクローカルアドレス、MTU、ovs-system、vxlan_sys_4789、
# single の eth0）を外し、
# つながりが左から右への 1 本の線に見えるよう、矢印の向きをそろえてから、dot で左から右に並べて描く。
# 向きをそろえる線: br-ex から先（eth1 → br-ex はそのまま）、qbr → qvb、phy-br-ex → int-br-ex、br-tun → patch-int、
# patch-int → patch-tun
# （plotnetcfg 0.4.1 は、patch のポートの組（phy-br-ex と int-br-ex、patch-int と patch-tun）の線を、
#   実行ごとにどちらの向きでも出す）
# ssh の -n: スクリプトの中で呼んだときに、標準入力（スクリプトの残り）を ssh に読ませない
if [ -n "$2" ]; then ssh -n "$2" plotnetcfg; else plotnetcfg; fi > /tmp/netmap.$$.dot
# eth0 は、vxlan のトンネルの下の道（vxlan のポートからの点線がある。multi）なら残し、そうでなければ（single）外す
if grep -q -e '-> "/eth0" \[dir=none' /tmp/netmap.$$.dot; then drop_eth0=; else drop_eth0='"/eth0"'; fi
cat /tmp/netmap.$$.dot |
sed -e 's/\\nfe80[^\\"]*//g' -e 's/\\nMTU [0-9]*//g' \
    -e 's/\\ntype: internal//g' \
    -e 's|^\("[^"]*"\) -> \("/br-ex"\)|\2 -> \1|' \
    -e 's|^"/br-ex" -> "/eth1"|"/eth1" -> "/br-ex"|' \
    -e 's|^\("/qvb[^"]*"\) -> \("/qbr[^"]*"\)$|\2 -> \1|' \
    -e 's|^"//ovs:br-int//int-br-ex" -> "//ovs:br-ex//phy-br-ex"|"//ovs:br-ex//phy-br-ex" -> "//ovs:br-int//int-br-ex"|' \
    -e 's|^"//ovs:br-int//patch-tun" -> "//ovs:br-tun//patch-int"|"//ovs:br-tun//patch-int" -> "//ovs:br-int//patch-tun"|' \
    -e 's|^\("//ovs:br-tun//patch-int"\) -> \("/br-tun"\)|\2 -> \1|' |
grep -v -e '/lo"' -e '"/ovs-system"' -e '"/vxlan_sys_4789"' ${drop_eth0:+-e "$drop_eth0"} |
dot -Tsvg -Grankdir=LR -Gfontname=Helvetica -Nfontname=Helvetica \
    -Efontname=Helvetica -Granksep=0.8 > /var/www/html/$1.svg
rm -f /tmp/netmap.$$.dot
