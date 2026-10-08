topse-tools
=========

TOPSE「クラウド基盤構築演習」の演習資材と環境構築資材。

ディレクトリ
------------

| ディレクトリ | 読み手 | 内容 |
|---|---|---|
| [hands-on/](hands-on/) | 受講者 | 演習で使う heat テンプレートと playbook。演習中は repo サーバーの `http://<repo サーバー>/hands-on/` から配布される |
| [preparation/](preparation/) | 講師 | 母艦 OpenStack（Rocky Linux 9 + OpenStack Epoxy）を構築し、演習用のイメージとテナントを準備する Ansible の資材。手順は [preparation/README.md](preparation/README.md) |

repo サーバーは、構築時にこのリポジトリを clone し、`hands-on/` と `preparation/` を HTTP で配信する。

正本の所在
------------

`hands-on/` と、`preparation/` の `ansible/`・`docker/`・`pyproject.toml`・`uv.lock` は、講師の手元の正本のリポジトリ（openstack-rocky）から自動で同期される写しである。正本でコミットするたびに、同期の結果が `Sync from openstack-rocky <コミット>` というコミットとしてこのリポジトリに入る。

これらはこのリポジトリで直接編集しない。直接編集しても、次の同期で上書きされる。このリポジトリで直接編集するのは、この README と `preparation/README.md` だけである。

公開リポジトリなので、実際の環境の inventory は載せない。`preparation/ansible/inventory/example/` の雛形を複製して使う。

ブランチ運用
------------

| ブランチ | 役割 |
|---|---|
| 開発ブランチ（例: `2027-rocky9-dev`） | 次の期に向けた開発。正本からの同期はここに入る |
| 期ブランチ（例: `2027-01`、`2026-01`） | その期の講義で使う資材。開講前に開発ブランチから切り、以後は講義中に必要な修正だけを入れる |
| `master` | 最新の期ブランチと同じ内容にそろえる |

1. 開発は開発ブランチで行う。
2. 開講前に、開発ブランチから期ブランチを切る。repo サーバーは期ブランチを clone する。
3. 期ブランチを切ったら、`master` をその期ブランチにそろえる（これまでの `Make master tree match 2026-01` と同じ）。
4. 過去の期ブランチは消さずに残す。過去の資材（CentOS 7 + Newton の演習など）は、それぞれの期ブランチで参照できる。
