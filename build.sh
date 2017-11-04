#!/bin/bash

FTP_HOST=$2
FTP_USER=$3
FTP_PSWD=$4

git fetch --unshallow
COUNT=$(git rev-list --count HEAD)
FILE=$COUNT-$5-$6.zip
DATE=$(date +"%Y/%m/%d %H:%M:%S")
ENV="GM_PR"

echo -e "Download sourcemod ..."
wget "http://www.sourcemod.net/latest.php?version=$1&os=linux" -q -O sourcemod.tar.gz
tar -xzf sourcemod.tar.gz

echo -e "Download cg_core.inc ..."
wget "https://github.com/Kxnrl/Core/raw/master/include/cg_core.inc" -q -O include/cg_core.inc

echo -e "Set compiler env ..."
chmod +x addons/sourcemod/scripting/spcomp

echo -e "Prepare compile ..."
for file in store.sp
do
  sed -i "s%<commit_count>%$COUNT%g" $file > output.txt
  sed -i "s%<commit_branch>%$5%g" $file > output.txt
  sed -i "s%<commit_date>%$DATE%g" $file > output.txt
  rm output.txt
done

echo -e "Check addons/sourcemod/scripting/store ..."
if [ ! -d "addons/sourcemod/scripting/store" ]; then
  mkdir addons/sourcemod/scripting/store
fi

echo -e "Check addons/sourcemod/scripting/store/modules ..."
if [ ! -d "addons/sourcemod/scripting/store/modules" ]; then
  mkdir addons/sourcemod/scripting/store/modules
fi

echo -e "Copy scripts to compiler folder ..."
cp -r store/* addons/sourcemod/scripting/store
cp include/* addons/sourcemod/scripting/include
cp store.sp addons/sourcemod/scripting

echo -e "Check build folder"
mkdir build
mkdir build/plugins
mkdir build/plugins/smx
mkdir build/models
mkdir build/materials
mkdir build/particles
mkdir build/sound

echo -e "Compiling store [ttt] ..."
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_TT%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp

if [ ! -f "store.smx" ]; then
    echo "Compile store[ttt] failed!"
    exit 1;
fi

mkdir build/plugins/smx/ttt
mv store.smx build/plugins/smx/ttt

echo -e "Compiling store [ze] ..."
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%GM_TT%GM_ZE%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp

if [ ! -f "store.smx" ]; then
    echo "Compile store[ze] failed!"
    exit 1;
fi

mkdir build/plugins/smx/ze
mv store.smx build/plugins/smx/ze

echo -e "Compiling store [mg] ..."
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%GM_ZE%GM_MG%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp

if [ ! -f "store.smx" ]; then
    echo "Compile store[mg] failed!"
    exit 1;
fi

mkdir build/plugins/smx/mg
mv store.smx build/plugins/smx/mg

echo -e "Compiling store [jb] ..."
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%GM_MG%GM_JB%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp

if [ ! -f "store.smx" ]; then
    echo "Compile store[jb] failed!"
    exit 1;
fi

mkdir build/plugins/smx/jb
mv store.smx build/plugins/smx/jb

mkdir build/plugins/smx/mg
mv store.smx build/plugins/smx/mg

echo -e "Compiling store [kz] ..."
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%GM_JB%GM_KZ%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp

if [ ! -f "store.smx" ]; then
    echo "Compile store[kz] failed!"
    exit 1;
fi

mkdir build/plugins/smx/kz
mv store.smx build/plugins/smx/kz

echo -e "Compiling fpvmi ..."
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/fpvm_interface.sp

if [ ! -f "fpvm_interface.smx" ]; then
    echo "Compile fpvm_interface failed!"
    exit 1;
fi

mv fpvm_interface.smx build/plugins

echo -e "Compiling chat-processor ..."
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/chat-processor.sp

if [ ! -f "chat-processor.smx" ]; then
    echo "Compile chat-processor failed!"
    exit 1;
fi

mv chat-processor.smx build/plugins

echo -e "Compress file ..."
cd build
zip -9rq $FILE LICENSE plugins

lftp -c "open -u $FTP_USER,$FTP_PSWD $FTP_HOST; put -O Store/$5/$1/ $FILE"