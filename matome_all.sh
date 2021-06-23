#!/usr/bin/bash

### ------------------------------------------------------
### 新聞社向け不要画像削除　ファイル容量集計プログラム
### 作成日：2020/06/12
### 更新日：2020/08/03
###         ・バグfix(ls -laの集計フィールドを4列→5列に変更)
### ------------------------------------------------------

# 入力受け取り
target_dir=""
local=""

# getopt
while getopts "l:t:" optKey; do
  case "$optKey" in
    t)
      target_dir=${OPTARG}
      ;;
    l)
      local=${OPTARG}
      ;;
    * )
      ;;
  esac
done


# ls
files=($(ls $target_dir))
if [ ${#files[@]} -eq 0 ] ; then
  echo "No Files in "$1
  exit 0
fi

year=`echo ${target_dir}       | sed -r 's/.*(201[0-9]).*/\1/g'`
month=`echo ${target_dir}      | sed -r 's/.*201[0-9]\/([^\/]+)\/.*/\1/g'`

if [ -z $local ]; then
  # s3パス変数の配列作成
  s3_path=()
  for file in ${files[@]}; do

    while read line
    do
      date=`echo ${line} | sed -r 's/.*2018.{2}(.{2}).{14}\.jpg/\1/g'`
      group_name=`echo ${line} | sed -r 's/.*(2018.{16})_1\.jpg/\1/g'`
      s3_path+=("s3://news-2018-test/${year}/${month}/${date}/${group_name}/")

    done < $target_dir/$file
  done

  # s3パスの容量表示
  s3_size=()
  i=0
  for s3 in ${s3_path[@]}; do
     echo $s3
     if [ $((i % 2)) -ne 0 ]; then
        s3_size+=($(aws s3 ls $s3 | awk '{s += $3} END {print s}'))
     fi
     i=$(( i+1 ))
  done

  # 容量表示
  sum=0
  for s in ${s3_size[@]}; do
    sum=$(( sum + s ))
  done

else
  # パス変数の配列作成
  path=()
  for file in ${files[@]}; do
    while read line
    do
      # マルチバイト文字が含まれる場合のみ以下コードを行うこと
      line=`echo $line | awk '{gsub(/[^[:alnum:]]/," ");print}' | cut -d ' ' -f 4`
      date=`echo ${line} | sed -r 's/.*201[0-9].{2}(.{2}).{12}/\1/g'`
      group_name=`echo ${line} |  sed -r 's/.*(201[0-9].{16})/\1/g'`
      path+=("$local/${year}/${month}/${date}/${group_name}/")

    done <  $target_dir/$file
  done


  # パスの容量表示
  size=()
  i=0
  for p in ${path[@]}; do
     #if [ $((i % 2)) -ne 0 ]; then
     #  size+=($(ls -la $p | awk '{s += $5} END {print s}'))
     #fi
     size+=($(ls -la $p | awk '{s += $5} END {print s}'))
     i=$(( i+1 ))
  done

  # 容量表示
  sum=0
  for s in ${size[@]}; do
    sum=$(( sum + s ))
  done

fi
echo $year$month":"$sum
