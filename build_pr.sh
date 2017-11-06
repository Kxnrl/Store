#!/bin/bash

git fetch --unshallow
COUNT=$(git rev-list --count HEAD)
DATE=$(date +"%Y/%m/%d %H:%M:%S")
ENV="GM_PR"

echo -e "*** Trigger test ***"

echo -e "Download sourcemod ..."
wget "http://www.sourcemod.net/latest.php?version=$1&os=linux" -q -O sourcemod.tar.gz
tar -xzf sourcemod.tar.gz

echo -e "Download cg_core.inc ..."
wget "https://github.com/Kxnrl/Core/raw/master/include/cg_core.inc" -q -O include/cg_core.inc

echo -e "Download smlib"
mkdir smlib
wget "https://codeload.github.com/bcserv/smlib/zip/master" -q -O smlib.zip
unzip -qo smlib.zip -d smlib/
mv smlib/smlib-master/scripting/include/* include

echo -e "Set compiler env ..."
chmod +x addons/sourcemod/scripting/spcomp

echo -e "Prepare compile ..."
for file in store.sp
do
  sed -i "s%<commit_count>%$COUNT%g" $file > output.txt
  sed -i "s%<commit_branch>%$2%g" $file > output.txt
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
cp -r include/* addons/sourcemod/scripting/include

echo -e "Compiling store core [ttt] ..."
cp store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_TT%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp >nul

if [ ! -f "store.smx" ]; then
    echo "Compile store[ttt] failed!"
    exit 1;
fi

echo -e "Compiling store core [ze] ..."
cp store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_ZE%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp >nul

if [ ! -f "store.smx" ]; then
    echo "Compile store[ze] failed!"
    exit 1;
fi

echo -e "Compiling store core [mg] ..."
cp store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_MG%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp >nul

if [ ! -f "store.smx" ]; then
    echo "Compile store[mg] failed!"
    exit 1;
fi

echo -e "Compiling store core [jb] ..."
cp store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_JB%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp >nul

if [ ! -f "store.smx" ]; then
    echo "Compile store[jb] failed!"
    exit 1;
fi

echo -e "Compiling store core [kz] ..."
cp store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_KZ%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp >nul

if [ ! -f "store.smx" ]; then
    echo "Compile store[kz] failed!"
    exit 1;
fi

echo -e "Compiling store module [pet] ..."
cp modules/store_pet.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store_pet.sp
do
  sed -i "s%<commit_count>%$COUNT%g" $file > output.txt
  sed -i "s%<commit_branch>%$2%g" $file > output.txt
  sed -i "s%<commit_date>%$DATE%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store_pet.sp >nul

if [ ! -f "store_pet.smx" ]; then
    echo "Compile store module[pet] failed!"
    exit 1;
fi

echo -e "Compiling fpvmi ..."
cp fpvm_interface.sp addons/sourcemod/scripting
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/fpvm_interface.sp >nul

if [ ! -f "fpvm_interface.smx" ]; then
    echo "Compile fpvm_interface failed!"
    exit 1;
fi

echo -e "Compiling chat-processor ..."
cp chat-processor.sp addons/sourcemod/scripting
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/chat-processor.sp >nul

if [ ! -f "chat-processor.smx" ]; then
    echo "Compile chat-processor failed!"
    exit 1;
fi

echo -e "Test done..."