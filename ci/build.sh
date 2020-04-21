#!/bin/bash

git fetch --unshallow
COUNT=$(git rev-list --count HEAD)
FILE=$COUNT-$2-$3.7z
LATEST=Store-SM$1-latest.7z
STABLE=Store-SM$1-stable.7z
OTHERS=Store-SM$1-$2.7Z

#INFO
echo "*** Trigger build ***"


#下载SM
echo "Download sourcemod ..."
if [ "$1" = "1.10" ]; then
  wget "https://sm.alliedmods.net/smdrop/1.10/sourcemod-1.10.0-git6366-linux.tar.gz" -q -O sourcemod.tar.gz
else
  wget "http://www.sourcemod.net/latest.php?version=$1&os=linux" -q -O sourcemod.tar.gz
fi
tar -xzf sourcemod.tar.gz


#PTaH
echo "Download PTaH.inc ..."
wget "https://github.com/komashchenko/PTaH/raw/master/PTaH.inc" -q -O include/PTaH.inc


#ArmsFix
echo "Download armsfix.inc ..."
wget "https://github.com/Kxnrl/CSGO-ArmsFix/raw/master/include/armsfix.inc" -q -O include/armsfix.inc


#Opts
echo "Download fys.opts.inc ..."
wget "https://github.com/fys-csgo/public-include/raw/master/fys.opts.inc" -q -O include/fys.opts.inc


#Pupd
echo "Download fys.pupd.inc ..."
wget "https://github.com/fys-csgo/public-include/raw/master/fys.pupd.inc" -q -O include/fys.pupd.inc


#设置文件为可执行
echo "Set compiler env ..."
chmod +x addons/sourcemod/scripting/spcomp


#更改版本信息
echo "Prepare compile ..."
for file in store.sp
do
  sed -i "s%<commit_count>%$COUNT%g" $file > output.txt
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
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"build/addons/sourcemod/plugins/store_tt.smx"
if [ ! -f "build/addons/sourcemod/plugins/store_tt.smx" ]; then
  echo "Compile store core [ttt] failed!"
  exit 1;
fi
mv addons/sourcemod/scripting/store.sp build/addons/sourcemod/scripting/store_tt.sp
echo ""
echo ""


#编译Store主程序 => ZE
echo "Compiling store core [ze] ..."
cp store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_ZE%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"build/addons/sourcemod/plugins/store_ze.smx"
if [ ! -f "build/addons/sourcemod/plugins/store_ze.smx" ]; then
  echo "Compile store core [ze] failed!"
  exit 1;
fi
mv addons/sourcemod/scripting/store.sp build/addons/sourcemod/scripting/store_ze.sp
echo ""
echo ""


#编译Store主程序 => MG
echo "Compiling store core [mg] ..."
cp store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_MG%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"build/addons/sourcemod/plugins/store_mg.smx"
if [ ! -f "build/addons/sourcemod/plugins/store_mg.smx" ]; then
  echo "Compile store core [mg] failed!"
  exit 1;
fi
mv addons/sourcemod/scripting/store.sp build/addons/sourcemod/scripting/store_mg.sp
echo ""
echo ""


#编译Store主程序 => JB
echo "Compiling store core [jb] ..."
cp store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_JB%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"build/addons/sourcemod/plugins/store_jb.smx"
if [ ! -f "build/addons/sourcemod/plugins/store_jb.smx" ]; then
  echo "Compile store core [jb] failed!"
  exit 1;
fi
mv addons/sourcemod/scripting/store.sp build/addons/sourcemod/scripting/store_jb.sp
echo ""
echo ""


#编译Store主程序 => KZ
echo "Compiling store core [kz] ..."
cp store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_KZ%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"build/addons/sourcemod/plugins/store_kz.smx"
if [ ! -f "build/addons/sourcemod/plugins/store_kz.smx" ]; then
  echo "Compile store core [kz] failed!"
  exit 1;
fi
mv addons/sourcemod/scripting/store.sp build/addons/sourcemod/scripting/store_kz.sp
echo ""
echo ""


#编译Store主程序 => Pure
echo "Compiling store core [pure] ..."
cp store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_PR%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"build/addons/sourcemod/plugins/store_pr.smx"
if [ ! -f "build/addons/sourcemod/plugins/store_pr.smx" ]; then
  echo "Compile store core [pure] failed!"
  exit 1;
fi
mv addons/sourcemod/scripting/store.sp build/addons/sourcemod/scripting/store_pr.sp
echo ""
echo ""


#编译Store主程序 => HG
echo "Compiling store core [hg] ..."
cp store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_HG%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"build/addons/sourcemod/plugins/store_hg.smx"
if [ ! -f "build/addons/sourcemod/plugins/store_hg.smx" ]; then
  echo "Compile store core [hg] failed!"
  exit 1;
fi
mv addons/sourcemod/scripting/store.sp build/addons/sourcemod/scripting/store_hg.sp
echo ""
echo ""


#编译Store主程序 => Surf
echo "Compiling store core [surf] ..."
cp store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_SR%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"build/addons/sourcemod/plugins/store_sr.smx"
if [ ! -f "build/addons/sourcemod/plugins/store_sr.smx" ]; then
  echo "Compile store core [surf] failed!"
  exit 1;
fi
mv addons/sourcemod/scripting/store.sp build/addons/sourcemod/scripting/store_sr.sp
echo ""
echo ""


#编译Store主程序 => HZ
echo "Compiling store core [hz] ..."
cp store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_HZ%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"build/addons/sourcemod/plugins/store_hz.smx"
if [ ! -f "build/addons/sourcemod/plugins/store_hz.smx" ]; then
  echo "Compile store core [hz] failed!"
  exit 1;
fi
mv addons/sourcemod/scripting/store.sp build/addons/sourcemod/scripting/store_hz.sp
echo ""
echo ""


#编译Store主程序 => BHOP
echo "Compiling store core [bhop] ..."
cp store.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store.sp
do
  sed -i "s%<Compile_Environment>%GM_BH%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store.sp -o"build/addons/sourcemod/plugins/store_bh.smx"
if [ ! -f "build/addons/sourcemod/plugins/store_bh.smx" ]; then
  echo "Compile store core [bhop] failed!"
  exit 1;
fi
mv addons/sourcemod/scripting/store.sp build/addons/sourcemod/scripting/
mv build/addons/sourcemod/scripting/store.sp build/addons/sourcemod/scripting/store_bh.sp
echo ""
echo ""


#编译Store模组Pets
echo "Compiling store module [pet] ..."
cp -f modules/store_pet.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store_pet.sp
do
  sed -i "s%<commit_count>%$COUNT%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store_pet.sp
if [ ! -f "store_pet.smx" ]; then
  echo "Compile store module [pet] failed!"
  exit 1;
fi
mv addons/sourcemod/scripting/store_pet.sp build/addons/sourcemod/scripting/modules
mv store_pet.smx build/addons/sourcemod/plugins/modules
echo ""
echo ""


#编译Store模组WeaponSkin
echo "Compiling store module [weapon skin] ..."
cp -f modules/store_weaponskin.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store_weaponskin.sp
do
  sed -i "s%<commit_count>%$COUNT%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store_weaponskin.sp
if [ ! -f "store_weaponskin.smx" ]; then
  echo "Compile store module [weapon skin] failed!"
  exit 1;
fi
mv addons/sourcemod/scripting/store_weaponskin.sp build/addons/sourcemod/scripting/modules
mv store_weaponskin.smx build/addons/sourcemod/plugins/modules
echo ""
echo ""


#编译Store模组DefaultSkin
echo "Compiling store module [default skin] ..."
cp -f modules/store_defaultskin.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store_defaultskin.sp
do
  sed -i "s%<commit_count>%$COUNT%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store_defaultskin.sp
if [ ! -f "store_defaultskin.smx" ]; then
  echo "Compile store module [default skin] failed!"
  exit 1;
fi
mv addons/sourcemod/scripting/store_defaultskin.sp build/addons/sourcemod/scripting/modules
mv store_defaultskin.smx build/addons/sourcemod/plugins/modules
echo ""
echo ""


#编译Store模组MusicKit
echo "Compiling store module [music kit] ..."
cp -f modules/store_musickit.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store_musickit.sp
do
  sed -i "s%<commit_count>%$COUNT%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store_musickit.sp
if [ ! -f "store_musickit.smx" ]; then
  echo "Compile store module [music kit] failed!"
  exit 1;
fi
mv addons/sourcemod/scripting/store_musickit.sp build/addons/sourcemod/scripting/modules
mv store_musickit.smx build/addons/sourcemod/plugins/modules
echo ""
echo ""


#编译Store模组GiveCreditsCommand
echo "Compiling store module [give credits command] ..."
cp -f modules/store_givecreditscommand.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store_givecreditscommand.sp
do
  sed -i "s%<commit_count>%$COUNT%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store_givecreditscommand.sp
if [ ! -f "store_givecreditscommand.smx" ]; then
  echo "Compile store module [give credits command] failed!"
  exit 1;
fi
mv addons/sourcemod/scripting/store_givecreditscommand.sp build/addons/sourcemod/scripting/modules
mv store_givecreditscommand.smx build/addons/sourcemod/plugins/modules
echo ""
echo ""


#编译Store模组随机皮肤
echo "Compiling store module [random skin] ..."
cp -f modules/store_randomskin.sp addons/sourcemod/scripting
for file in addons/sourcemod/scripting/store_randomskin.sp.sp
do
  sed -i "s%<commit_count>%$COUNT%g" $file > output.txt
  rm output.txt
done
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/store_randomskin.sp
if [ ! -f "store_randomskin.smx" ]; then
  echo "Compile store module [randoms kin] failed!"
  exit 1;
fi
mv addons/sourcemod/scripting/store_randomskin.sp build/addons/sourcemod/scripting/modules
mv store_randomskin.smx build/addons/sourcemod/plugins/modules
echo ""
echo ""


#解压素材文件
#echo "Extract resource file ..."
#echo "Processing archive: resources/materials/materials.7z"
#7z x "resources/materials/materials.7z" -o"build/materials" >nul
#mv resources/materials/materials.txt build/materials
#echo "Processing archive: resources/materials/models.7z"
#7z x "resources/models/models.7z" -o"build/models" >nul
#mv resources/models/models.txt build/models
#echo "Processing archive: resources/materials/particles.7z"
#7z x "resources/particles/particles.7z" -o"build/particles" >nul
#mv resources/particles/particles.txt build/particles
#echo "Processing archive: resources/materials/sound.7z"
#7z x "resources/sound/sound.7z" -o"build/sound" >nul
#mv resources/sound/sound.txt build/sound


#移动配置和翻译文件
echo "Move configs and translations to build folder ..."
mv configs/* build/addons/sourcemod/configs
mv translations/* build/addons/sourcemod/translations
mv utils build
mv README.md build


#移动其他的代码文件
echo "Move other scripts to build folder ..."
mv -f store build/addons/sourcemod/scripting
mv -f include build/addons/sourcemod/scripting


#打包
echo "Compress file ..."
cd build
7z a $FILE   -t7z -mx9 README.md addons utils >nul
if [ "$2" = "master" ]; then
#    7z a $FILE -t7z -mx9 README.md addons utils materials models particles sound >nul
# disallow package resouorce.
  7z a $LATEST -t7z -mx9 README.md addons utils >nul
elif [ "$2" = "stable" ]; then
  7z a $STABLE -t7z -mx9 README.md addons utils >nul
else
  7z a $OTHERS -t7z -mx9 README.md addons utils >nul
fi


#上传
echo "Upload file RSYNC ..."
RSYNC_PASSWORD=$RSYNC_PSWD rsync -avz --port $RSYNC_PORT ./$FILE $RSYNC_USER@$RSYNC_HOST::TravisCI/Store/$1/

#上传通用版本
if [ "$2" = "master" ]; then
#    7z a $FILE -t7z -mx9 README.md addons utils materials models particles sound >nul
# disallow package resouorce.
  RSYNC_PASSWORD=$RSYNC_PSWD rsync -avz --port $RSYNC_PORT ./$LATEST $RSYNC_USER@$RSYNC_HOST::TravisCI/Store/
elif [ "$2" = "stable" ]; then
  RSYNC_PASSWORD=$RSYNC_PSWD rsync -avz --port $RSYNC_PORT ./$STABLE $RSYNC_USER@$RSYNC_HOST::TravisCI/Store/
else
  RSYNC_PASSWORD=$RSYNC_PSWD rsync -avz --port $RSYNC_PORT ./$OTHERS $RSYNC_USER@$RSYNC_HOST::TravisCI/Store/
fi


#RAW
if [ "$1" = "1.10" ] && [ "$2" = "master" ]; then
  echo "Upload RAW [core] RSYNC ..."
  RSYNC_PASSWORD=$RSYNC_PSWD rsync -avz --port $RSYNC_PORT ./addons/sourcemod/plugins/*.smx $RSYNC_USER@$RSYNC_HOST::TravisCI/_Raw/
  echo "Upload RAW [modules] RSYNC ..."
  RSYNC_PASSWORD=$RSYNC_PSWD rsync -avz --port $RSYNC_PORT ./addons/sourcemod/plugins/modules/*.smx $RSYNC_USER@$RSYNC_HOST::TravisCI/_Raw/
  echo "Upload RAW [translation] RSYNC ..."
  RSYNC_PASSWORD=$RSYNC_PSWD rsync -avz --port $RSYNC_PORT ./addons/sourcemod/translations/*.txt $RSYNC_USER@$RSYNC_HOST::TravisCI/_Raw/translations
fi
