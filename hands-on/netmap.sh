#!/bin/bash
# 第 8 回の演習で、ホストのネットワークの構成を図（SVG）にする。演習環境 single の root で実行する。
#   使い方: bash netmap.sh <名前>   → /var/www/html/<名前>.svg（ブラウザで http://<single の Floating IP>/<名前>.svg）
# plotnetcfg の出力（dot）から、演習に関係ないもの（lo、IPv6 のリンクローカルアドレス、MTU、ovs-system、eth0）を外し、
# つながりが左から右への 1 本の線に見えるよう、矢印の向きをそろえてから、dot で左から右に並べて描く。
# 向きをそろえる線: br-ex から先（eth1 → br-ex はそのまま）、qbr → qvb、phy-br-ex → int-br-ex、br-tun → patch-int
# （plotnetcfg 0.4.1 は phy-br-ex と int-br-ex の線を、実行ごとにどちらの向きでも出す）
plotnetcfg |
sed -e 's/\\nfe80[^\\"]*//g' -e 's/\\nMTU [0-9]*//g' \
    -e 's/\\ntype: internal//g' \
    -e 's|^\("[^"]*"\) -> \("/br-ex"\)|\2 -> \1|' \
    -e 's|^"/br-ex" -> "/eth1"|"/eth1" -> "/br-ex"|' \
    -e 's|^\("/qvb[^"]*"\) -> \("/qbr[^"]*"\)$|\2 -> \1|' \
    -e 's|^"//ovs:br-int//int-br-ex" -> "//ovs:br-ex//phy-br-ex"|"//ovs:br-ex//phy-br-ex" -> "//ovs:br-int//int-br-ex"|' \
    -e 's|^\("//ovs:br-tun//patch-int"\) -> \("/br-tun"\)|\2 -> \1|' |
grep -v -e '/lo"' -e '"/ovs-system"' -e '"/eth0"' |
dot -Tsvg -Grankdir=LR -Gfontname=Helvetica -Nfontname=Helvetica \
    -Efontname=Helvetica -Granksep=0.8 > /var/www/html/$1.svg
