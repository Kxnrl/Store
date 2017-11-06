#!/bin/bash

#参数
FTP_HOST=$2
FTP_USER=$3
FTP_PSWD=$4

git fetch --unshallow
COUNT=$(git rev-list --count HEAD)
FILE=$COUNT-$5-$6.zip
DATE=$(date +"%Y/%m/%d %H:%M:%S")
ENV="GM_PR"


#INFO
echo -e "*** Trigger test ***"


#下载SM
echo -e "Download sourcemod ..."
wget "http://www.sourcemod.net/latest.php?version=$1&os=linux" -q -O sourcemod.tar.gz
tar -xzf sourcemod.tar.gz


#下载CG头文件
echo -e "Download cg_core.inc ..."
wget "https://github.com/Kxnrl/Core/raw/master/include/cg_core.inc" -q -O include/cg_core.inc


#下载FPVMI头文件
echo -e "Download fpvm_interface.inc ..."
wget "https://github.com/Franc1sco/First-Person-View-Models-Interface/raw/master/scripting/include/fpvm_interface.inc" -q -O include/fpvm_interface.inc


#设置文件为可执行
echo -e "Set compiler env ..."
chmod +x addons/sourcemod/scripting/spcomp


#更改版本信息
echo -e "Prepare compile ..."
for file in store.sp
do
  sed -i "s%<commit_count>%$COUNT%g" $file > output.txt
  sed -i "s%<commit_branch>%$5%g" $file > output.txt
  sed -i "s%<commit_date>%$DATE%g" $file > output.txt
  rm output.txt
done


#建立文件夹以准备拷贝文件
mkdir addons/sourcemod/scripting/store
mkdir addons/sourcemod/scripting/store/modules


#拷贝文件到编译器文件夹
echo -e "Copy scripts to compiler folder ..."
cp -r store/* addons/sourcemod/scripting/store
cp -r include/* addons/sourcemod/scripting/include


#编译Store主程序 => TTT
#编译CG版本
echo -e "Compiling store core [ttt] *CG* ..."
cp store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_TT%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"addons/sourcemod/plugins/store_ttt.smx_cg" >nul
if [ ! -f "addons/sourcemod/plugins/store_ttt_cg.smx" ]; then
    echo "Compile store core [ttt] *CG* failed!"
    exit 1;
fi
#编译通用版本
echo -e "Compiling store core [ttt] *Global* ..."
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%#include <cg_core>%//Global%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"addons/sourcemod/plugins/store_ttt.smx" >nul
if [ ! -f "addons/sourcemod/plugins/store_ttt.smx" ]; then
    echo "Compile store core [ttt] *Global* failed!"
    exit 1;
fi


#编译Store主程序 => ZE
#编译CG版本
echo -e "Compiling store core [ze] *CG* ..."
cp store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_ZE%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"addons/sourcemod/plugins/store_ze_cg.smx" >nul
if [ ! -f "addons/sourcemod/plugins/store_ze_cg.smx" ]; then
    echo "Compile store core [ze] *CG* failed!"
    exit 1;
fi
#编译通用版本
echo -e "Compiling store core [ze] *Global* ..."
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%#include <cg_core>%//Global%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"addons/sourcemod/plugins/store_ze.smx" >nul
if [ ! -f "addons/sourcemod/plugins/store_ze.smx" ]; then
    echo "Compile store core [ze] *Global* failed!"
    exit 1;
fi


#编译Store主程序 => MG
#编译CG版本
echo -e "Compiling store core [mg] *CG* ..."
cp store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_MG%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"addons/sourcemod/plugins/store_mg_cg.smx" >nul
if [ ! -f "addons/sourcemod/plugins/store_mg_cg.smx" ]; then
    echo "Compile store core [mg] *CG* failed!"
    exit 1;
fi
#编译通用版本
echo -e "Compiling store core [mg] *Global* ..."
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%#include <cg_core>%//Global%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"addons/sourcemod/plugins/store_mg.smx" >nul
if [ ! -f "addons/sourcemod/plugins/store_mg.smx" ]; then
    echo "Compile store core [mg] *Global* failed!"
    exit 1;
fi


#编译Store主程序 => JB
#编译CG版本
echo -e "Compiling store core [jb] *CG* ..."
cp store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_JB%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"addons/sourcemod/plugins/store_jb_cg.smx" >nul
if [ ! -f "addons/sourcemod/plugins/store_jb_cg.smx" ]; then
    echo "Compile store core [jb] *CG* failed!"
    exit 1;
fi
#编译通用版本
echo -e "Compiling store core [jb] *Global* ..."
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%#include <cg_core>%//Global%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"addons/sourcemod/plugins/store_jb.smx" >nul
if [ ! -f "addons/sourcemod/plugins/store_jb.smx" ]; then
    echo "Compile store core [jb] *Global* failed!"
    exit 1;
fi


#编译Store主程序 => KZ
#编译CG版本
echo -e "Compiling store core [kz] *CG* ..."
cp store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_KZ%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"addons/sourcemod/plugins/store_kz_cg.smx" >nul
if [ ! -f "addons/sourcemod/plugins/store_kz_cg.smx" ]; then
    echo "Compile store core [kz] *CG* failed!"
    exit 1;
fi
#编译通用版本
echo -e "Compiling store core [kz] *Global* ..."
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%#include <cg_core>%//Global%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"addons/sourcemod/plugins/store_kz.smx" >nul
if [ ! -f "addons/sourcemod/plugins/store_kz.smx" ]; then
    echo "Compile store core [kz] *Global* failed!"
    exit 1;
fi


#编译Store模组Pets
echo -e "Compiling store module [pet] ..."
cp modules/store_pet.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store_pet.sp
do
  sed -i "s%<commit_count>%$COUNT%g" $file > output.txt
  sed -i "s%<commit_branch>%$5%g" $file > output.txt
  sed -i "s%<commit_date>%$DATE%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store_pet.sp >nul
if [ ! -f "store_pet.smx" ]; then
    echo "Compile store module[pet] failed!"
    exit 1;
fi


#编译第三方模组Chat-Processor
echo -e "Compiling chat-processor ..."
mv chat-processor.sp addons/sourcemod/scripting
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/chat-processor.sp >nul
if [ ! -f "chat-processor.smx" ]; then
    echo "Compile chat-processor failed!"
    exit 1;
fi
