#!/bin/bash

#参数
FTP_HOST=$2
FTP_USER=$3
FTP_PSWD=$4

git fetch --unshallow
COUNT=$(git rev-list --count HEAD)
FILE=$COUNT-$5-$6.7z
DATE=$(date +"%Y/%m/%d %H:%M:%S")
ENV="GM_PR"


#INFO
echo "*** Trigger build ***"


#下载SM
echo "Download sourcemod ..."
wget "http://www.sourcemod.net/latest.php?version=$1&os=linux" -q -O sourcemod.tar.gz
tar -xzf sourcemod.tar.gz


#设置文件为可执行
echo "Set compiler env ..."
chmod +x addons/sourcemod/scripting/spcomp


#更改版本信息
echo "Prepare compile ..."
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
echo "Copy scripts to compiler folder ..."
cp -rf store/* addons/sourcemod/scripting/store
cp -rf include/* addons/sourcemod/scripting/include


#建立输出文件夹
echo "Check build folder ..."
mkdir build
mkdir build/addons
mkdir build/addons/sourcemod/
mkdir build/addons/sourcemod/configs
mkdir build/addons/sourcemod/plugins
mkdir build/addons/sourcemod/plugins/modules
mkdir build/addons/sourcemod/scripting
mkdir build/addons/sourcemod/scripting/modules
mkdir build/addons/sourcemod/translations
mkdir build/models
mkdir build/materials
mkdir build/particles
mkdir build/sound


#编译Store主程序 => TTT
echo "Compiling store core [ttt] ..."
cp store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_TT%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"build/addons/sourcemod/plugins/store_tt.smx" >nul
if [ ! -f "build/addons/sourcemod/plugins/store_tt.smx" ]; then
    echo "Compile store core [ttt] failed!"
    exit 1;
fi
mv addons/sourcemod/scripting/store.sp build/addons/sourcemod/scripting/store_tt.sp


#编译Store主程序 => ZE
echo "Compiling store core [ze] ..."
cp store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_ZE%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"build/addons/sourcemod/plugins/store_ze.smx" >nul
if [ ! -f "build/addons/sourcemod/plugins/store_ze.smx" ]; then
    echo "Compile store core [ze] failed!"
    exit 1;
fi
mv addons/sourcemod/scripting/store.sp build/addons/sourcemod/scripting/store_ze.sp


#编译Store主程序 => MG
echo "Compiling store core [mg] ..."
cp store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_MG%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"build/addons/sourcemod/plugins/store_mg.smx" >nul
if [ ! -f "build/addons/sourcemod/plugins/store_mg.smx" ]; then
    echo "Compile store core [mg] failed!"
    exit 1;
fi
mv addons/sourcemod/scripting/store.sp build/addons/sourcemod/scripting/store_mg.sp


#编译Store主程序 => JB
echo "Compiling store core [jb] ..."
cp store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_JB%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"build/addons/sourcemod/plugins/store_jb.smx" >nul
if [ ! -f "build/addons/sourcemod/plugins/store_jb.smx" ]; then
    echo "Compile store core [jb] failed!"
    exit 1;
fi
mv addons/sourcemod/scripting/store.sp build/addons/sourcemod/scripting/store_jb.sp


#编译Store主程序 => KZ
echo "Compiling store core [kz] ..."
cp store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_KZ%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"build/addons/sourcemod/plugins/store_kz.smx" >nul
if [ ! -f "build/addons/sourcemod/plugins/store_kz.smx" ]; then
    echo "Compile store core [kz] failed!"
    exit 1;
fi
mv addons/sourcemod/scripting/store.sp build/addons/sourcemod/scripting/store_kz.sp


#编译Store主程序 => Pure
echo "Compiling store core [pure] ..."
cp store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_PR%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"build/addons/sourcemod/plugins/store_pr.smx" >nul
if [ ! -f "build/addons/sourcemod/plugins/store_pr.smx" ]; then
    echo "Compile store core [pure] failed!"
    exit 1;
fi
mv addons/sourcemod/scripting/store.sp build/addons/sourcemod/scripting/store_pr.sp


#编译Store主程序 => HG
echo "Compiling store core [hg] ..."
cp store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_HG%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"build/addons/sourcemod/plugins/store_hg.smx" >nul
if [ ! -f "build/addons/sourcemod/plugins/store_hg.smx" ]; then
    echo "Compile store core [hg] failed!"
    exit 1;
fi
mv addons/sourcemod/scripting/store.sp build/addons/sourcemod/scripting/store_hg.sp


#编译Store主程序 => Surf
echo "Compiling store core [surf] ..."
cp store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_SR%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"build/addons/sourcemod/plugins/store_sr.smx" >nul
if [ ! -f "build/addons/sourcemod/plugins/store_sr.smx" ]; then
    echo "Compile store core [surf] failed!"
    exit 1;
fi
mv addons/sourcemod/scripting/store.sp build/addons/sourcemod/scripting/store_sr.sp


#编译Store主程序 => HZ
echo "Compiling store core [hz] ..."
cp store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_HZ%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"build/addons/sourcemod/plugins/store_hz.smx" >nul
if [ ! -f "build/addons/sourcemod/plugins/store_hz.smx" ]; then
    echo "Compile store core [hz] failed!"
    exit 1;
fi
mv addons/sourcemod/scripting/store.sp build/addons/sourcemod/scripting/store_hz.sp


#编译Store主程序 => BHOP
echo "Compiling store core [bhop] ..."
cp store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_BH%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"build/addons/sourcemod/plugins/store_bh.smx" >nul
if [ ! -f "build/addons/sourcemod/plugins/store_bh.smx" ]; then
    echo "Compile store core [bhop] failed!"
    exit 1;
fi
mv addons/sourcemod/scripting/store.sp build/addons/sourcemod/scripting/
mv build/addons/sourcemod/scripting/store.sp build/addons/sourcemod/scripting/store_bh.sp


#编译Store模组Pets
echo "Compiling store module [pet] ..."
cp -f modules/store_pet.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store_pet.sp
do
  sed -i "s%<commit_count>%$COUNT%g" $file > output.txt
  sed -i "s%<commit_branch>%$5%g" $file > output.txt
  sed -i "s%<commit_date>%$DATE%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store_pet.sp >nul
if [ ! -f "store_pet.smx" ]; then
    echo "Compile store module [pet] failed!"
    exit 1;
fi
mv addons/sourcemod/scripting/store_pet.sp build/addons/sourcemod/scripting/modules
mv store_pet.smx build/addons/sourcemod/plugins/modules


#解压素材文件
echo "Extract resource file ..."
echo "Processing archive: resources/materials/materials.7z"
7z x "resources/materials/materials.7z" -o"build/materials" >nul
mv resources/materials/materials.txt build/materials
echo "Processing archive: resources/materials/models.7z"
7z x "resources/models/models.7z" -o"build/models" >nul
mv resources/models/models.txt build/models
echo "Processing archive: resources/materials/particles.7z"
7z x "resources/particles/particles.7z" -o"build/particles" >nul
mv resources/particles/particles.txt build/particles
echo "Processing archive: resources/materials/sound.7z"
7z x "resources/sound/sound.7z" -o"build/sound" >nul
mv resources/sound/sound.txt build/sound


#移动配置和翻译文件
echo "Move configs and translations to build folder ..."
mv configs/* build/addons/sourcemod/configs
mv translations/* build/addons/sourcemod/translations
mv utils build
mv LICENSE build
mv README.md build


#移动其他的代码文件
echo "Move other scripts to build folder ..."
mv -f store build/addons/sourcemod/scripting
mv -f include build/addons/sourcemod/scripting


#打包
echo "Compress file ..."
cd build
if [ "$5" = "master" ]; then
#    7z a $FILE -t7z -mx9 README.md addons utils materials models particles sound >nul
# disallow package resouorce.
    7z a $FILE -t7z -mx9 README.md addons utils >nul
else
    7z a $FILE -t7z -mx9 README.md addons utils >nul
fi


#上传
echo "Upload file ..."
lftp -c "open -u $FTP_USER,$FTP_PSWD $FTP_HOST; put -O /Store/$5/$1/ $FILE"


#RAW
if [ "$1" = "1.8" ] && [ "$5" = "master" ]; then
    echo "Upload RAW..."
    cd addons/sourcemod/plugins
    lftp -c "open -u $FTP_USER,$FTP_PSWD $FTP_HOST; put -O /Store/Raw/ store_tt.smx"
    lftp -c "open -u $FTP_USER,$FTP_PSWD $FTP_HOST; put -O /Store/Raw/ store_ze.smx"
    lftp -c "open -u $FTP_USER,$FTP_PSWD $FTP_HOST; put -O /Store/Raw/ store_mg.smx"
    lftp -c "open -u $FTP_USER,$FTP_PSWD $FTP_HOST; put -O /Store/Raw/ store_jb.smx"
    lftp -c "open -u $FTP_USER,$FTP_PSWD $FTP_HOST; put -O /Store/Raw/ store_kz.smx"
    lftp -c "open -u $FTP_USER,$FTP_PSWD $FTP_HOST; put -O /Store/Raw/ store_hz.smx"
    lftp -c "open -u $FTP_USER,$FTP_PSWD $FTP_HOST; put -O /Store/Raw/ store_pr.smx"
    lftp -c "open -u $FTP_USER,$FTP_PSWD $FTP_HOST; put -O /Store/Raw/ store_hg.smx"
    lftp -c "open -u $FTP_USER,$FTP_PSWD $FTP_HOST; put -O /Store/Raw/ store_sr.smx"
    lftp -c "open -u $FTP_USER,$FTP_PSWD $FTP_HOST; put -O /Store/Raw/ store_bh.smx"
fi
