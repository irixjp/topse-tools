# shellcheck shell=bash
#
# cloud-support: 演習環境の作成・一覧・削除と、演習外で作られたリソースの検出を行う。
# console の ~/.bashrc から読み込む（00_console.yml が ~/.support/support.sh に置く）。
#
#   cloud-support ls                 演習環境の一覧
#   cloud-support create 02|08|10    演習環境を作る（08/10 は構築 playbook まで流す）
#   cloud-support delete 02|06|08|10 演習環境を消す
#   cloud-support check              演習外のリソース（ゴミ）と、06 のリソースの重複を報告する
#   cloud-support log 08|10          構築 playbook のログを表示する
#   cloud-support update             support.sh を repo サーバーから取り直す

CS_REPO_URL="${CS_REPO_URL:-http://reposerver-centos7/hands-on}"
CS_DIR="${CS_DIR:-$HOME/.support}"

# 06 の正規のリソースの名前（06 は受講者が CLI で手で作る）
CS_06_SERVER=openstack-single
CS_06_PORTS="handson06-cc-eth0 handson06-cc-eth1"
CS_06_SUBNET=handson06-subnet
CS_06_NET=handson06-net
CS_06_KEY=handson06-key

_cs_template()  { case $1 in 02) echo 02_vm_vnet_vstr.yml ;; 08) echo 08_openstack_single.yml ;; 10) echo 10_openstack_multi.yml ;; esac; }
_cs_inventory() { case $1 in 08) echo 08_openstack_single_inventory.yml ;; 10) echo 10_openstack_multi_inventory ;; esac; }
_cs_playbook()  { case $1 in 08) echo 08_openstack_single_playbook.yml ;; 10) echo 10_openstack_multi_playbook.yml ;; esac; }

_cs_usage() {
  cat <<'EOF'
使い方:
  cloud-support ls                  演習環境の一覧
  cloud-support create 02|08|10     演習環境を作る（08/10 は入れ子の OpenStack の構築まで）
  cloud-support delete 02|06|08|10  演習環境を消す（消す前に確認する）
  cloud-support check               演習外で作られたリソース（ゴミ）を報告する
  cloud-support log 08|10           構築のログを表示する
  cloud-support update              cloud-support を最新にする
EOF
}

_cs_auth() {
  CS_PROJECT=$(openstack token issue -f value -c project_id 2>/dev/null)
  if [ -z "$CS_PROJECT" ]; then
    echo "OpenStack に認証できません。~/openrc の内容（OS_AUTH_URL、OS_PROJECT_NAME、OS_USERNAME、OS_PASSWORD）を確かめ、source ~/openrc を実行してください。" >&2
    return 1
  fi
}

_cs_confirm() {
  local ans
  read -r -p "$1 [y/N] " ans
  [ "$ans" = y ] || [ "$ans" = Y ]
}

# 一覧を DIR/<種類>.json に並列で取得する
_cs_fetch() {
  local dir=$1 kind
  shift
  (
    for kind in "$@"; do
      case $kind in
        stacks)    openstack stack list -f json ;;
        servers)   openstack server list -f json ;;
        ports)     openstack port list --long -f json ;;
        networks)  openstack network list --long -f json ;;
        subnets)   openstack subnet list --long -f json ;;
        routers)   openstack router list -f json ;;
        fips)      openstack floating ip list -f json ;;
        sgs)       openstack security group list -f json ;;
        keypairs)  openstack keypair list -f json ;;
        volumes)   openstack volume list -f json ;;
        snapshots) openstack volume snapshot list -f json ;;
        images)    openstack image list --private -f json ;;
        res-*)     openstack stack resource list -n 5 -f json "${kind#res-}" ;;
        rports-*)  openstack port list --router "${kind#rports-}" --long -f json ;;
        sports-*)  openstack port list --server "${kind#sports-}" -f json ;;
      esac > "$dir/$kind.json" 2> "$dir/$kind.err" &
    done
    wait
  )
  for kind in "$@"; do
    if ! jq -e 'type == "array"' "$dir/$kind.json" > /dev/null 2>&1; then
      echo "一覧の取得に失敗しました（$kind）:" >&2
      cat "$dir/$kind.err" >&2
      return 1
    fi
  done
}

# 構築 playbook の状態: none / running / ok / failed / aborted
_cs_build_state() {
  local st="$CS_DIR/state/$1"
  [ -f "$st.log" ] || { echo none; return; }
  if [ -s "$st.rc" ]; then
    if [ "$(cat "$st.rc")" = 0 ]; then echo ok; else echo failed; fi
  elif [ -s "$st.pid" ] && kill -0 "$(cat "$st.pid")" 2> /dev/null; then
    echo running
  else
    echo aborted
  fi
}

_cs_build_label() {
  case $(_cs_build_state "$1") in
    running) echo "構築中（cloud-support log $1 で表示）" ;;
    ok)      echo "構築完了" ;;
    failed)  echo "構築失敗（cloud-support log $1 で表示）" ;;
    aborted) echo "構築中断（cloud-support log $1 で表示）" ;;
  esac
}

# 06 の正規の名前のリソースを「種類<TAB>名前<TAB>ID」で出力する（DIR に servers ports subnets networks keypairs が必要）
_cs_06_resources() {
  local dir=$1
  jq -r --arg n "$CS_06_SERVER" '.[] | select(.Name == $n) | "server\t\(.Name)\t\(.ID)"' "$dir/servers.json"
  jq -r --arg n "$CS_06_PORTS" '.[] | select(.Name as $x | $n | split(" ") | index($x)) | "port\t\(.Name)\t\(.ID)"' "$dir/ports.json"
  jq -r --arg n "$CS_06_SUBNET" --arg p "$CS_PROJECT" '.[] | select(.Name == $n and .Project == $p) | "subnet\t\(.Name)\t\(.ID)"' "$dir/subnets.json"
  jq -r --arg n "$CS_06_NET" --arg p "$CS_PROJECT" '.[] | select(.Name == $n and .Project == $p) | "network\t\(.Name)\t\(.ID)"' "$dir/networks.json"
  jq -r --arg n "$CS_06_KEY" '.[] | select(.Name == $n) | "keypair\t\(.Name)\t\(.Name)"' "$dir/keypairs.json"
}

# 存在する演習環境を「番号<TAB>説明」で出力する
_cs_envs() {
  local dir=$1 n names
  for n in 02 08 10; do
    jq -r --arg s "handson$n" --arg n "$n" '.[] | select(."Stack Name" == $s) | "\($n)\tスタック \($s)（\(."Stack Status")）"' "$dir/stacks.json"
  done
  names=$(_cs_06_resources "$dir" | cut -f2 | sort -u | paste -sd ' ')
  [ -n "$names" ] && printf '06\t手で作ったリソース（%s）\n' "$names"
}

_cs_ls() {
  local dir envs n desc label
  _cs_auth || return 1
  dir=$(mktemp -d)
  _cs_fetch "$dir" stacks servers ports subnets networks keypairs || { rm -rf "$dir"; return 1; }
  envs=$(_cs_envs "$dir")
  rm -rf "$dir"
  if [ -z "$envs" ]; then
    echo "演習環境はありません（console だけです）"
    return 0
  fi
  echo "演習環境:"
  while IFS=$'\t' read -r n desc; do
    label=""
    case $n in 08|10) label=$(_cs_build_label "$n") ;; esac
    echo "  $n  $desc${label:+  $label}"
  done <<< "$envs"
}

_cs_create() {
  local n=$1 dir envs f files stack status
  case $n in 02|08|10) ;; *) echo "作れる演習環境は 02、08、10 です" >&2; return 1 ;; esac
  _cs_auth || return 1
  dir=$(mktemp -d)
  _cs_fetch "$dir" stacks servers ports subnets networks keypairs || { rm -rf "$dir"; return 1; }
  envs=$(_cs_envs "$dir")
  rm -rf "$dir"
  if [ -n "$envs" ]; then
    echo "演習環境が残っているため作れません（console と演習環境 1 つまでしか作れません）:" >&2
    while IFS=$'\t' read -r f stack; do echo "  $f  $stack" >&2; done <<< "$envs"
    echo "cloud-support delete <番号> で消してから、もう一度実行してください。" >&2
    return 1
  fi

  files="$(_cs_template "$n") $(_cs_inventory "$n") $(_cs_playbook "$n")"
  mkdir -p "$CS_DIR/$n"
  for f in $files; do
    if ! curl -fsS -o "$CS_DIR/$n/$f.tmp" "$CS_REPO_URL/$f"; then
      echo "資材を取得できません: $CS_REPO_URL/$f" >&2
      return 1
    fi
    mv "$CS_DIR/$n/$f.tmp" "$CS_DIR/$n/$f"
  done

  stack="handson$n"
  echo "スタック $stack を作成します（1〜2 分）"
  (cd "$CS_DIR/$n" && openstack stack create -t "$(_cs_template "$n")" --wait "$stack")
  status=$(openstack stack show "$stack" -f value -c stack_status 2> /dev/null)
  if [ "$status" != CREATE_COMPLETE ]; then
    echo "スタックの作成に失敗しました（${status:-不明}）:" >&2
    openstack stack show "$stack" -f value -c stack_status_reason >&2
    echo "cloud-support delete $n で消してから、もう一度実行してください。" >&2
    return 1
  fi
  openstack stack output show "$stack" --all
  case $n in 08|10) ;; *) return 0 ;; esac

  echo "入れ子の OpenStack を構築します（10〜12 分）"
  _cs_build_start "$n"
  _cs_follow "$n"
}

# 構築 playbook を、端末から切り離して起動する（SSH の切断や Ctrl-C では止まらない）
_cs_build_start() {
  local n=$1 st="$CS_DIR/state" i
  mkdir -p "$CS_DIR/logs" "$st"
  rm -f "$st/$n.pid" "$st/$n.rc"
  echo "$CS_DIR/logs/$n-$(date +%Y%m%d-%H%M%S).log" > "$st/$n.log"
  (
    cd "$CS_DIR/$n" || exit 1
    setsid nohup bash -c 'echo $$ > "$1"; ansible-playbook -i "$2" "$3"; echo $? > "$4"' \
      _ "$st/$n.pid" "$(_cs_inventory "$n")" "$(_cs_playbook "$n")" "$st/$n.rc" \
      > "$(cat "$st/$n.log")" 2>&1 < /dev/null &
  )
  for i in 1 2 3 4 5 6 7 8 9 10; do
    [ -s "$st/$n.pid" ] && break
    sleep 0.5
  done
}

# 構築のログを表示する。構築中なら終わるまで追従する
_cs_follow() {
  local n=$1 st="$CS_DIR/state/$1" log
  log=$(cat "$st.log")
  if [ "$(_cs_build_state "$n")" = running ]; then
    echo "（Ctrl-C で表示を止めても、SSH が切れても、構築は続きます。続きは cloud-support log $n で表示できます）"
    tail -n +1 -f --pid="$(cat "$st.pid")" "$log"
  else
    cat "$log"
  fi
  echo
  case $(_cs_build_state "$n") in
    ok)      echo "構築完了（ログ: $log）" ;;
    failed)  echo "構築失敗（終了コード $(cat "$st.rc")、ログ: $log）。講師に連絡してください。" ;;
    aborted) echo "構築が途中で止まっています（ログ: $log）。cloud-support delete $n で消して、作り直してください。" ;;
  esac
}

_cs_log() {
  local n=$1
  case $n in 08|10) ;; *) echo "ログがあるのは 08 と 10 です" >&2; return 1 ;; esac
  if [ "$(_cs_build_state "$n")" = none ]; then
    echo "$n の構築のログはありません" >&2
    return 1
  fi
  _cs_follow "$n"
}

_cs_delete() {
  local n=$1 dir envs desc
  case $n in
    02|06|08|10) ;;
    *)
      echo "消す演習環境の番号を指定してください: cloud-support delete 02|06|08|10" >&2
      _cs_auth || return 1
      dir=$(mktemp -d)
      _cs_fetch "$dir" stacks servers ports subnets networks keypairs && envs=$(_cs_envs "$dir")
      rm -rf "$dir"
      if [ -n "$envs" ]; then
        echo "いまある演習環境:" >&2
        while IFS=$'\t' read -r n desc; do echo "  $n  $desc" >&2; done <<< "$envs"
      else
        echo "いまある演習環境はありません" >&2
      fi
      return 1 ;;
  esac
  _cs_auth || return 1
  if [ "$n" = 06 ]; then _cs_delete_06; else _cs_delete_stack "$n"; fi
}

_cs_delete_stack() {
  local n=$1 stack="handson$1" status pid i
  status=$(openstack stack show "$stack" -f value -c stack_status 2> /dev/null)
  if [ -z "$status" ]; then
    echo "$n の演習環境（スタック $stack）はありません"
    return 0
  fi
  echo "消すもの: スタック $stack（$status）"
  openstack server list --name "^$stack-" -f value -c Name | sed 's/^/  サーバー: /'
  if [ "$(_cs_build_state "$n")" = running ]; then
    echo "  構築中の playbook も止めます"
  fi
  _cs_confirm "削除しますか?" || { echo "中止しました"; return 1; }

  if [ "$(_cs_build_state "$n")" = running ]; then
    pid=$(cat "$CS_DIR/state/$n.pid")
    kill -TERM -- "-$pid" 2> /dev/null
    for i in 1 2 3 4 5 6 7 8 9 10; do kill -0 "$pid" 2> /dev/null || break; sleep 1; done
    kill -KILL -- "-$pid" 2> /dev/null
  fi
  rm -f "$CS_DIR/state/$n".*

  openstack stack delete -y --wait "$stack" > /dev/null 2>&1
  # --wait の表示は完了の前に途切れることがあるので、スタックが消えるまで確かめる
  for i in $(seq 60); do
    status=$(openstack stack show "$stack" -f value -c stack_status 2> /dev/null)
    [ -z "$status" ] && { echo "スタック $stack を削除しました"; return 0; }
    [ "$status" = DELETE_FAILED ] && break
    sleep 5
  done
  echo "スタック $stack を削除できませんでした（$status）。講師に連絡してください。" >&2
  openstack stack show "$stack" -f value -c stack_status_reason >&2
  return 1
}

_cs_delete_06() {
  local dir res sid rid err=0 type name id
  dir=$(mktemp -d)
  _cs_fetch "$dir" servers ports subnets networks keypairs || { rm -rf "$dir"; return 1; }
  res=$(_cs_06_resources "$dir")
  rm -rf "$dir"
  if [ -z "$res" ] && [ ! -e "$HOME/$CS_06_KEY.pem" ]; then
    echo "06 のリソースはありません"
    return 0
  fi
  echo "消すもの:"
  while IFS=$'\t' read -r type name id; do
    [ -n "$type" ] && printf '  %-8s %-20s %s\n' "$type" "$name" "$id"
  done <<< "$res"
  [ -e "$HOME/$CS_06_KEY.pem" ] && echo "  file     ~/$CS_06_KEY.pem"
  _cs_confirm "削除しますか?" || { echo "中止しました"; return 1; }

  # 消す順序: サーバー → ポート → ルーターからサブネットを外す → サブネット → ネットワーク → キーペア
  for id in $(awk -F'\t' '$1 == "server" { print $3 }' <<< "$res"); do
    openstack server delete --wait "$id" || err=1
  done
  for id in $(awk -F'\t' '$1 == "port" { print $3 }' <<< "$res"); do
    openstack port delete "$id" || err=1
  done
  for sid in $(awk -F'\t' '$1 == "subnet" { print $3 }' <<< "$res"); do
    for id in $(openstack port list --fixed-ip subnet="$sid" --device-owner network:router_interface -f value -c ID); do
      rid=$(openstack port show "$id" -f value -c device_id)
      openstack router remove subnet "$rid" "$sid" || err=1
    done
    openstack subnet delete "$sid" || err=1
  done
  for id in $(awk -F'\t' '$1 == "network" { print $3 }' <<< "$res"); do
    openstack network delete "$id" || err=1
  done
  if grep -q '^keypair' <<< "$res"; then
    openstack keypair delete "$CS_06_KEY" || err=1
  fi
  rm -f "$HOME/$CS_06_KEY.pem"

  if [ "$err" = 0 ]; then
    echo "06 のリソースを削除しました"
  else
    echo "一部を削除できませんでした。cloud-support check で、残っているものを確かめてください。" >&2
    return 1
  fi
}

_cs_check() {
  local dir s legit_stacks other_stacks r f out cmds dup
  _cs_auth || return 1
  dir=$(mktemp -d)
  _cs_fetch "$dir" stacks servers ports networks subnets routers fips sgs keypairs volumes snapshots images \
    || { rm -rf "$dir"; return 1; }
  # 正規のスタック（console と演習環境）と、それ以外のスタック
  legit_stacks=$(jq -r '.[] | ."Stack Name" | select(test("^(console|handson02|handson08|handson10)$"))' "$dir/stacks.json")
  other_stacks=$(jq -r '.[] | ."Stack Name" | select(test("^(console|handson02|handson08|handson10)$") | not)' "$dir/stacks.json")
  f=""
  for s in $(jq -r '.[].ID' "$dir/stacks.json"); do f="$f res-$s"; done
  for r in $(jq -r --arg p "$CS_PROJECT" '.[] | select(.Project == $p) | .ID' "$dir/routers.json"); do f="$f rports-$r"; done
  for s in $(jq -r '.[].ID' "$dir/servers.json"); do f="$f sports-$s"; done
  # shellcheck disable=SC2086
  [ -n "$f" ] && { _cs_fetch "$dir" $f || { rm -rf "$dir"; return 1; }; }

  # スタックのリソースの ID（どのスタックのものでも、スタックごと扱うので個別には報告しない）
  jq -n '[inputs[] | .physical_resource_id | select(. != null and . != "")]' "$dir"/res-*.json < /dev/null > "$dir/covered.json" 2> /dev/null \
    || echo '[]' > "$dir/covered.json"
  # ルーターのインターフェース: [ルーター ID, サブネット ID]
  jq -n '[inputs as $p | input_filename as $f | $p[] | select(."Device Owner" == "network:router_interface")
          | ."Fixed IP Addresses"[] | [($f | capture("rports-(?<r>[^/]+)\\.json$").r), .subnet_id]]' \
    "$dir"/rports-*.json < /dev/null > "$dir/rifs.json" 2> /dev/null || echo '[]' > "$dir/rifs.json"
  # サーバーのポート: {ポート ID: サーバー ID}
  jq -n '[inputs as $p | input_filename as $f | $p[] | {(.ID): ($f | capture("sports-(?<s>[^/]+)\\.json$").s)}] | add // {}' \
    "$dir"/sports-*.json < /dev/null > "$dir/sports.json" 2> /dev/null || echo '{}' > "$dir/sports.json"

  out=$(jq -r -n \
    --arg p "$CS_PROJECT" \
    --arg sv "$CS_06_SERVER" --arg pt "$CS_06_PORTS" --arg sn "$CS_06_SUBNET" --arg nt "$CS_06_NET" --arg kp "$CS_06_KEY" \
    --slurpfile cov "$dir/covered.json" --slurpfile rifs "$dir/rifs.json" --slurpfile sports "$dir/sports.json" \
    --slurpfile stacks "$dir/stacks.json" --slurpfile servers "$dir/servers.json" --slurpfile ports "$dir/ports.json" \
    --slurpfile networks "$dir/networks.json" --slurpfile subnets "$dir/subnets.json" --slurpfile routers "$dir/routers.json" \
    --slurpfile fips "$dir/fips.json" --slurpfile sgs "$dir/sgs.json" --slurpfile keypairs "$dir/keypairs.json" \
    --slurpfile volumes "$dir/volumes.json" --slurpfile snapshots "$dir/snapshots.json" --slurpfile images "$dir/images.json" '
    ($cov[0]) as $cov
    | def notcov: (.ID as $i | $cov | index($i)) == null;
      def g(t; n): "G\t\(t)\t\(n)\t\(.ID)";
      def c(o; cmd): "C\t\(o)\t\(cmd)";
      ([$servers[0][] | select(notcov and .Name != $sv)]) as $gsv
    | ([$routers[0][] | select(.Project == $p and notcov)]) as $grt
    | ([$subnets[0][] | select(.Project == $p and notcov and .Name != $sn)]) as $gsn
    | ([$subnets[0][] | select(.Project == $p) | .ID]) as $mysn
    | ([$gsn[].ID]) as $gsnid | ([$grt[].ID]) as $grtid | ([$gsv[].ID]) as $gsvid
    | ($gsv[] | g("server"; .Name), c(1; "openstack server delete --wait \(.ID)")),
      ($stacks[0][] | select(."Stack Name" | test("^(console|handson02|handson08|handson10)$") | not)
        | g("stack"; ."Stack Name"), c(0; "openstack stack delete -y --wait \(.ID)")),
      ($fips[0][] | select(notcov) | g("floating ip"; ."Floating IP Address"), c(2; "openstack floating ip delete \(.ID)")),
      ($rifs[0][] | select((.[0] as $r | $grtid | index($r)) != null or (.[1] as $s | $gsnid | index($s)) != null)
        | select(.[1] as $s | $mysn | index($s)) | c(3; "openstack router remove subnet \(.[0]) \(.[1])")),
      ($ports[0][] | select((."Device Owner" | startswith("network:")) | not)
        | select(notcov and (.Name as $n | $pt | split(" ") | index($n)) == null)
        | ($sports[0][.ID]) as $owner
        | if $owner != null and ($gsvid | index($owner)) != null
          then "G\tport\t\(if .Name == "" then "-" else .Name end)\t\(.ID)\t（演習外のサーバーに接続。サーバーを消すと一緒に消えることがある）"
          else g("port"; if .Name == "" then "-" else .Name end), c(4; "openstack port delete \(.ID)") end),
      ($grt[] | g("router"; .Name), c(5; "openstack router delete \(.ID)")),
      ($gsn[] | g("subnet"; .Name), c(6; "openstack subnet delete \(.ID)")),
      ($networks[0][] | select(.Project == $p and notcov and .Name != $nt)
        | g("network"; .Name), c(7; "openstack network delete \(.ID)")),
      ($sgs[0][] | select(.Project == $p and notcov and .Name != "default")
        | g("security group"; .Name), c(8; "openstack security group delete \(.ID)")),
      ($keypairs[0][] | select(.Name != $kp) | "G\tkeypair\t\(.Name)\t\(.Name)", c(8; "openstack keypair delete \(.Name)")),
      ($snapshots[0][] | select(notcov) | g("volume snapshot"; .Name), c(9; "openstack volume snapshot delete \(.ID)")),
      ($volumes[0][] | select(notcov) | g("volume"; .Name), c(10; "openstack volume delete \(.ID)")),
      ($images[0][] | select(notcov) | g("image"; .Name), c(11; "openstack image delete \(.ID)")),
      # 06 の正規の名前のリソースの重複
      ([$servers[0][] | select(.Name == $sv)], [$subnets[0][] | select(.Project == $p and .Name == $sn)],
       [$networks[0][] | select(.Project == $p and .Name == $nt)],
       ($pt | split(" ")[] as $n | [$ports[0][] | select(.Name == $n)])
        | select(length > 1) | "D\t\(.[0].Name)\t\(length)\t\([.[].ID] | join(" "))")
    ')
  rm -rf "$dir"

  echo "正規のリソース: スタック $(echo "$legit_stacks" | paste -sd ' ')、06 の $CS_06_SERVER / $CS_06_NET / $CS_06_SUBNET / $(echo "$CS_06_PORTS" | sed 's/ / \/ /') / $CS_06_KEY"
  if [ -z "$out" ]; then
    echo "演習外のリソースは見つかりませんでした"
    return 0
  fi
  if grep -q '^G' <<< "$out"; then
    echo
    echo "演習外のリソース（演習の手順にない名前で作られたもの）:"
    grep '^G' <<< "$out" | awk -F'\t' '{ printf "  %-16s %-28s %s%s\n", $2, $3, $4, ($5 == "" ? "" : "  " $5) }'
    [ -n "$other_stacks" ] && echo "  （スタックのリソースは、スタックを消すと一緒に消えます）"
  fi
  dup=$(grep '^D' <<< "$out")
  if [ -n "$dup" ]; then
    echo
    echo "重複（06 の名前のリソースが複数あります）:"
    awk -F'\t' '{ printf "  %s が %s 個: %s\n", $2, $3, $4 }' <<< "$dup"
    echo "  不要なものを ID で消すか、cloud-support delete 06 で 06 のリソースをすべて消して作り直してください。"
  fi
  cmds=$(grep '^C' <<< "$out" | sort -t$'\t' -k2,2n -s | cut -f3)
  if [ -n "$cmds" ]; then
    echo
    echo "消すためのコマンド（内容を確かめてから、この順に実行してください）:"
    sed 's/^/  /' <<< "$cmds"
    grep -q '^G.server' <<< "$out" && echo "  （サーバーを消したあとに、もう一度 cloud-support check を実行してください）"
  fi
  return 2
}

_cs_update() {
  local tmp
  tmp=$(mktemp)
  if ! curl -fsS -o "$tmp" "$CS_REPO_URL/support.sh"; then
    echo "取得できません: $CS_REPO_URL/support.sh" >&2
    rm -f "$tmp"
    return 1
  fi
  if ! bash -n "$tmp"; then
    echo "取得した support.sh に構文エラーがあるため、更新しません" >&2
    rm -f "$tmp"
    return 1
  fi
  mkdir -p "$CS_DIR"
  mv "$tmp" "$CS_DIR/support.sh"
  # shellcheck source=/dev/null
  source "$CS_DIR/support.sh"
  echo "cloud-support を更新しました"
}

cloud-support() {
  local cmd=$1
  shift 2> /dev/null
  case $cmd in
    ls)     _cs_ls ;;
    create) _cs_create "$1" ;;
    delete) _cs_delete "$1" ;;
    check)  _cs_check ;;
    log)    _cs_log "$1" ;;
    update) _cs_update ;;
    *)      _cs_usage; [ -z "$cmd" ] || [ "$cmd" = help ] ;;
  esac
}

complete -W "ls create delete check log update help" cloud-support 2> /dev/null
