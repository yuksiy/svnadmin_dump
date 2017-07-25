#!/bin/sh

# ==============================================================================
#   機能
#     Subversion リポジトリ単位にダンプを実行する
#   構文
#     USAGE 参照
#
#   Copyright (c) 2007-2017 Yukio Shiiya
#
#   This software is released under the MIT License.
#   https://opensource.org/licenses/MIT
# ==============================================================================

######################################################################
# 基本設定
######################################################################
trap "" 28				# TRAP SET
trap "POST_PROCESS;exit 1" 1 2 15	# TRAP SET

SCRIPT_ROOT=`dirname $0`
SCRIPT_NAME=`basename $0`
PID=$$
YYYYMMDD=`date +%Y%m%d`

######################################################################
# 関数定義
######################################################################
PRE_PROCESS() {
	:
}

POST_PROCESS() {
	:
}

USAGE() {
	cat <<- EOF 1>&2
		Usage:
		    svnadmin_dump.sh [OPTIONS ...] REPOS_DIR DUMP_DIR
		
		    REPOS_DIR : Specify a repository directory to dump.
		    DUMP_DIR  : Specify a dump directory for storing dumped files.
		
		OPTIONS:
		    -q
		       execute 'svnadmin dump' command with '-q' option.
		    -m DUMP_MODE
		       DUMP_MODE : {full|diff|inc}
		         full : full dump
		           A full dump dumps all revisions.
		           With full dump, you need only the most recent dump file in order to
		           restore all of your repository.
		           You usually perform a full dump the first time you create a dump
		           file set.
		         diff : differential dump
		           A differential dump dumps only those revisions committed since the
		           last full dump.
		           If you are performing a combination of full and differential dump,
		           you need to have the last full dump file as well as the last
		           differential dump file in order to restore your repository.
		         inc  : incremental dump
		           An incremental dump dumps only those revisions committed since the
		           last full or incremental dump.
		           If you are performing a combination of full and incremental dump,
		           you need to have the last full dump file as well as all
		           incremental dump files in order to restore your repository.
		       (default: ${DUMP_MODE})
		    --help
		       Display this help and exit.
	EOF
}

. is_numeric_function.sh

######################################################################
# 変数定義
######################################################################
#ユーザ変数

# システム環境 依存変数
SVNADMIN="svnadmin"
SVNLOOK="svnlook"

# プログラム内部変数
DUMP_MODE="full"
REPOS_DIR=""
DUMP_DIR=""

DUMP_FILE_FULL="svnadmin_dump"
DUMP_FILE_DIFF="svnadmin_dump_diff"
DUMP_FILE_INC="svnadmin_dump_inc"

LAST_DUMP_FULL=".last_dump"
LAST_DUMP_DIFF=".last_dump_diff"
LAST_DUMP_INC=".last_dump_inc"

SVNADMIN_DUMP_OPTIONS=""

#DEBUG=TRUE

######################################################################
# メインルーチン
######################################################################

# オプションのチェック
CMD_ARG="`getopt -o qm: -l help -- \"$@\" 2>&1`"
if [ $? -ne 0 ];then
	echo "-E ${CMD_ARG}" 1>&2
	USAGE;exit 1
fi
eval set -- "${CMD_ARG}"
while true ; do
	opt="$1"
	case "${opt}" in
	-q)	SVNADMIN_DUMP_OPTIONS="${SVNADMIN_DUMP_OPTIONS} -q" ; shift 1;;
	-m)
		case $2 in
		full|diff|inc)	DUMP_MODE="$2" ; shift 2;;
		*)
			echo "-E argument to \"${opt}\" is invalid -- \"$2\"" 1>&2
			USAGE;exit 1
			;;
		esac
		;;
	--help)
		USAGE;exit 0
		;;
	--)
		shift 1;break
		;;
	esac
done

# 第1引数のチェック
if [ "$1" = "" ];then
	echo "-E Missing REPOS_DIR argument" 1>&2
	USAGE;exit 1
else
	REPOS_DIR=`echo "$1" | sed "s,/$,,"`
	# ダンプ対象リポジトリディレクトリのチェック
	"${SVNLOOK}" info "${REPOS_DIR}" > /dev/null 2>&1
	if [ $? -ne 0 ];then
		echo "-E REPOS_DIR not a repository directory -- \"${REPOS_DIR}\"" 1>&2
		USAGE;exit 1
	fi
fi

# 第2引数のチェック
if [ "$2" = "" ];then
	echo "-E Missing DUMP_DIR argument" 1>&2
	USAGE;exit 1
else
	DUMP_DIR=`echo "$2" | sed "s,/$,,"`
	# バックアップディレクトリのチェック
	if [ ! -d "${DUMP_DIR}" ];then
		echo "-E DUMP_DIR not a directory -- \"${DUMP_DIR}\"" 1>&2
		USAGE;exit 1
	fi
fi

# rev_from の初期化
case ${DUMP_MODE} in
full)
	rev_from=0
	;;
diff|inc)
	case ${DUMP_MODE} in
	diff)
		last_dump_from="${LAST_DUMP_FULL}"
		;;
	inc)
		# LAST_DUMP_INC ファイルが存在する場合
		if [ -f "${DUMP_DIR}/${LAST_DUMP_INC}" ];then
			last_dump_from="${LAST_DUMP_INC}"
		# LAST_DUMP_INC ファイルが存在しない場合
		else
			last_dump_from="${LAST_DUMP_FULL}"
		fi
		;;
	esac
	# last_dump_from ファイルを読み取れない場合
	if [ ! -r "${DUMP_DIR}/${last_dump_from}" ];then
		echo "-E \"${DUMP_DIR}/${last_dump_from}\" file cannot read" 1>&2
		exit 1
	else
		# last_dump_from ファイルの読み取り
		rev_from=`cat "${DUMP_DIR}/${last_dump_from}"`
		# last_dump_from ファイルから読み取られた文字列が数値か否かのチェック
		IS_NUMERIC "${rev_from}"
		if [ $? -ne 0 ];then
			echo "-E string read from \"${DUMP_DIR}/${last_dump_from}\" not numeric -- \"${rev_from}\"" 1>&2
			exit 1
		# last_dump_from ファイルから読み取られた数値のチェック
		elif [ ${rev_from} -lt 0 ];then
			echo "-E revision number read from \"${DUMP_DIR}/${last_dump_from}\" is invalid -- \"${rev_from}\"" 1>&2
			exit 1
		fi
	fi
	;;
esac

# rev_to の初期化
rev_to=`"${SVNLOOK}" youngest --no-newline "${REPOS_DIR}"`

# rev_from=rev_to である場合
if [ ${rev_from} -eq ${rev_to} ];then
	# 処理終了
	echo "-I No new revisions to dump."
	exit 1
# rev_from=rev_to でない場合
else
	case ${DUMP_MODE} in
	full)
		# 何もしない
		:
		;;
	diff|inc)
		# rev_from を1増加
		rev_from=`expr ${rev_from} + 1`
		;;
	esac
fi

# SVNADMIN_DUMP_OPTIONS の初期化
case ${DUMP_MODE} in
full)
	SVNADMIN_DUMP_OPTIONS="${SVNADMIN_DUMP_OPTIONS} -r ${rev_from}:${rev_to}"
	;;
diff|inc)
	SVNADMIN_DUMP_OPTIONS="${SVNADMIN_DUMP_OPTIONS} -r ${rev_from}:${rev_to} --incremental"
	;;
esac

# last_dump, dump_file の初期化
case ${DUMP_MODE} in
full)
	dump_file="${DUMP_FILE_FULL}.${YYYYMMDD}.${rev_from}-${rev_to}"
	last_dump="${LAST_DUMP_FULL}"
	;;
diff)
	dump_file="${DUMP_FILE_DIFF}.${YYYYMMDD}.${rev_from}-${rev_to}"
	last_dump="${LAST_DUMP_DIFF}"
	;;
inc)
	dump_file="${DUMP_FILE_INC}.${YYYYMMDD}.${rev_from}-${rev_to}"
	last_dump="${LAST_DUMP_INC}"
	;;
esac

# 作業開始前処理
PRE_PROCESS

# 処理開始メッセージの表示
echo "-I Repository dump has started."

#####################
# メインループ 開始 #
#####################

# ダンプの実行
echo "-I Dumping to \"${DUMP_DIR}/${dump_file}\"..."
echo "     REPOS_DIR : ${REPOS_DIR}"
echo "     DUMP_MODE : ${DUMP_MODE}"
"${SVNADMIN}" dump ${SVNADMIN_DUMP_OPTIONS} "${REPOS_DIR}" > "${DUMP_DIR}/${dump_file}"
if [ $? -ne 0 ];then
	echo "-E Command has ended unsuccessfully." 1>&2
	POST_PROCESS;exit 1
fi

# ダンプファイルの圧縮
echo "-I Compressing \"${DUMP_DIR}/${dump_file}\"..."
gzip -f "${DUMP_DIR}/${dump_file}"
if [ $? -ne 0 ];then
	echo "-E Command has ended unsuccessfully." 1>&2
	POST_PROCESS;exit 1
fi

# 最終ダンプリビジョンファイルの書き込み
echo "-I Writing \"${DUMP_DIR}/${last_dump}\"..."
echo "${rev_to}" > "${DUMP_DIR}/${last_dump}"
if [ $? -ne 0 ];then
	echo "-E Command has ended unsuccessfully." 1>&2
	POST_PROCESS;exit 1
fi

# DUMP_MODE=full である場合
if [ "${DUMP_MODE}" = "full" ];then
	# 最終差分ダンプリビジョンファイルの削除
	if [ -f "${DUMP_DIR}/${LAST_DUMP_DIFF}" ];then
		echo "-I Removing \"${DUMP_DIR}/${LAST_DUMP_DIFF}\"..."
		rm -f "${DUMP_DIR}/${LAST_DUMP_DIFF}"
	fi
	# 最終増分ダンプリビジョンファイルの削除
	if [ -f "${DUMP_DIR}/${LAST_DUMP_INC}" ];then
		echo "-I Removing \"${DUMP_DIR}/${LAST_DUMP_INC}\"..."
		rm -f "${DUMP_DIR}/${LAST_DUMP_INC}"
	fi
fi

#####################
# メインループ 終了 #
#####################

# 処理終了メッセージの表示
echo "-I Repository dump has ended successfully."
# 作業終了後処理
POST_PROCESS;exit 0

