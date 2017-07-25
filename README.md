# svnadmin_dump

## 概要

Subversionリポジトリのダンプ

## 使用方法

### svnadmin_dump.sh

完全ダンプを実行します。

    $ svnadmin_dump.sh -q -m full リポジトリディレクトリ名 ダンプファイル格納ディレクトリ名

差分ダンプを実行します。

    $ svnadmin_dump.sh -q -m diff リポジトリディレクトリ名 ダンプファイル格納ディレクトリ名

増分ダンプを実行します。

    $ svnadmin_dump.sh -q -m inc  リポジトリディレクトリ名 ダンプファイル格納ディレクトリ名

### その他

* 上記で紹介したツールの詳細については、「ツール名 --help」を参照してください。

## 動作環境

OS:

* Linux
* Cygwin

依存パッケージ または 依存コマンド:

* make (インストール目的のみ)
* subversion (svnadmin,svnlookコマンド)
* [common_sh](https://github.com/yuksiy/common_sh)

## インストール

ソースからインストールする場合:

    (Linux, Cygwin の場合)
    # make install

fil_pkg.plを使用してインストールする場合:

[fil_pkg.pl](https://github.com/yuksiy/fil_tools_pl/blob/master/README.md#fil_pkgpl) を参照してください。

## インストール後の設定

環境変数「PATH」にインストール先ディレクトリを追加してください。

## 最新版の入手先

<https://github.com/yuksiy/svnadmin_dump>

## License

MIT License. See [LICENSE](https://github.com/yuksiy/svnadmin_dump/blob/master/LICENSE) file.

## Copyright

Copyright (c) 2007-2017 Yukio Shiiya
