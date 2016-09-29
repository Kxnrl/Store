bool GetItemString(int iRandom_Type, iRandom_Item, char[] m_szType, char[] m_szName, char[] m_szPath)
{
	// Type  1帽子/2面具/3翅膀/4足迹/5光环/6名字颜色/7名字标签/8信息颜色/9喷图/10语音/11刀子模型
	if(iRandom_Type == 1)
	{
		if(iRandom_Item == 1)
		{
			Format(m_szType, 16, "hat");
			Format(m_szName, 128, "维京海盗");
			Format(m_szPath, 128, "models/vikinghelmet/vikinghelmet.mdl");
			return true;
		}
		if(iRandom_Item == 2)
		{
			Format(m_szType, 16, "hat");
			Format(m_szName, 128, "鹿角");
			Format(m_szPath, 128, "models/sam/antlers.mdl");
			return true;
		}
		if(iRandom_Item == 3)
		{
			Format(m_szType, 16, "hat");
			Format(m_szName, 128, "宇航员头盔");
			Format(m_szPath, 128, "models/astronauthelmet/astronauthelmet.mdl");
			return true;
		}
		if(iRandom_Item == 4)
		{
			Format(m_szType, 16, "hat");
			Format(m_szName, 128, "软呢帽");
			Format(m_szPath, 128, "models/gmod_tower/fedorahat.mdl");
			return true;
		}
		if(iRandom_Item == 5)
		{
			Format(m_szType, 16, "hat");
			Format(m_szName, 128, "特务帽");
			Format(m_szPath, 128, "models/gmod_tower/pimphat.mdl");
			return true;
		}
		if(iRandom_Item == 6)
		{
			Format(m_szType, 16, "hat");
			Format(m_szName, 128, "Seuss帽");
			Format(m_szPath, 128, "models/gmod_tower/seusshat.mdl");
			return true;
		}
		if(iRandom_Item == 7)
		{
			Format(m_szType, 16, "hat");
			Format(m_szName, 128, "墨西哥草帽");
			Format(m_szPath, 128, "models/gmod_tower/sombrero.mdl");
			return true;
		}
		if(iRandom_Item == 8)
		{
			Format(m_szType, 16, "hat");
			Format(m_szName, 128, "鼠帽");
			Format(m_szPath, 128, "models/gmod_tower/toetohat.mdl");
			return true;
		}
		if(iRandom_Item == 9)
		{
			Format(m_szType, 16, "hat");
			Format(m_szName, 128, "女巫帽");
			Format(m_szPath, 128, "models/gmod_tower/witchhat.mdl");
			return true;
		}
		if(iRandom_Item == 10)
		{
			Format(m_szType, 16, "hat");
			Format(m_szName, 128, "爆炸头");
			Format(m_szPath, 128, "models/gmod_tower/afro.mdl");
			return true;
		}
		if(iRandom_Item == 11)
		{
			Format(m_szType, 16, "hat");
			Format(m_szName, 128, "猫耳");
			Format(m_szPath, 128, "models/gmod_tower/catears.mdl");
			return true;
		}
		if(iRandom_Item == 12)
		{
			Format(m_szType, 16, "hat");
			Format(m_szName, 128, "顶帽");
			Format(m_szPath, 128, "models/gmod_tower/tophat.mdl");
			return true;
		}
		if(iRandom_Item == 13)
		{
			Format(m_szType, 16, "hat");
			Format(m_szName, 128, "圣诞帽");
			Format(m_szPath, 128, "models/player/holiday/santahat.mdl");
			return true;
		}
		if(iRandom_Item == 14)
		{
			Format(m_szType, 16, "hat");
			Format(m_szName, 128, "KFC");
			Format(m_szPath, 128, "models/gmod_tower/kfcbucket.mdl");
			return true;
		}
		if(iRandom_Item == 15)
		{
			Format(m_szType, 16, "hat");
			Format(m_szName, 128, "皮卡丘");
			Format(m_szPath, 128, "models/pikahat/pikahat.mdl");
			return true;
		}
		if(iRandom_Item == 16)
		{
			Format(m_szType, 16, "hat");
			Format(m_szName, 128, "赛亚人");
			Format(m_szPath, 128, "models/anime_patron/animepatr.mdl");
			return true;
		}
		if(iRandom_Item == 17)
		{
			Format(m_szType, 16, "hat");
			Format(m_szName, 128, "舞会帽");
			Format(m_szPath, 128, "models/duncehat/duncehat.mdl");
			return true;
		}
		if(iRandom_Item == 18)
		{
			Format(m_szType, 16, "hat");
			Format(m_szName, 128, "山姆大叔");
			Format(m_szPath, 128, "models/store/hats/uncle_sam_hat.mdl");
			return true;
		}
		if(iRandom_Item == 19)
		{
			Format(m_szType, 16, "hat");
			Format(m_szName, 128, "Daft Punk");
			Format(m_szPath, 128, "models/store/hats/daft_punk_v1.mdl");
			return true;
		}
	}
	else if(iRandom_Type == 2)
	{
		if(iRandom_Item == 1)
		{
			Format(m_szType, 16, "hat");
			Format(m_szName, 128, "Chicken(动态)");
			Format(m_szPath, 128, "models/player/holiday/facemasks/facemask_chicken.mdl");
			return true;
		}
		if(iRandom_Item == 2)
		{
			Format(m_szType, 16, "hat");
			Format(m_szName, 128, "南瓜面具");
			Format(m_szPath, 128, "models/player/holiday/facemasks/facemask_pumpkin.mdl");
			return true;
		}
	}
	else if(iRandom_Type == 3)
	{
		if(iRandom_Item == 1)
		{
			Format(m_szType, 16, "hat");
			Format(m_szName, 128, "燕子翅膀");
			Format(m_szPath, 128, "models/shop/perfectworld_wings01_v3.mdl");
			return true;
		}
		if(iRandom_Item == 2)
		{
			Format(m_szType, 16, "hat");
			Format(m_szName, 128, "冰火之翼");
			Format(m_szPath, 128, "models/shop/perfectworld_wings03_v3.mdl");
			return true;
		}
		if(iRandom_Item == 3)
		{
			Format(m_szType, 16, "hat");
			Format(m_szName, 128, "精灵之翼");
			Format(m_szPath, 128, "models/shop/perfectworld_wings04_v3.mdl");
			return true;
		}
		if(iRandom_Item == 4)
		{
			Format(m_szType, 16, "hat");
			Format(m_szName, 128, "大天使之翼");
			Format(m_szPath, 128, "models/shop/perfectworld_wings05_v3.mdl");
			return true;
		}
		if(iRandom_Item == 5)
		{
			Format(m_szType, 16, "hat");
			Format(m_szName, 128, "Hawk Wing");
			Format(m_szPath, 128, "models/shop/perfectworld_wings06_v3.mdl");
			return true;
		}
		if(iRandom_Item == 6)
		{
			Format(m_szType, 16, "hat");
			Format(m_szName, 128, "妖精之翼");
			Format(m_szPath, 128, "models/shop/perfectworld_wings07_v3.mdl");
			return true;
		}
		if(iRandom_Item == 7)
		{
			Format(m_szType, 16, "hat");
			Format(m_szName, 128, "恶魔之翼");
			Format(m_szPath, 128, "models/shop/perfectworld_wings08_v3.mdl");
			return true;
		}
		if(iRandom_Item == 8)
		{
			Format(m_szType, 16, "hat");
			Format(m_szName, 128, "翼展天际");
			Format(m_szPath, 128, "models/shop/perfectworld_wings09_v3.mdl");
			return true;
		}
	}
	else if(iRandom_Type == 4)
	{
		if(iRandom_Item == 1)
		{
			Format(m_szType, 16, "trail");
			Format(m_szName, 128, "彩色箭头");
			Format(m_szPath, 128, "materials/sprites/store/trails/arrowrainbow.vmt");
			return true;
		}
		if(iRandom_Item == 2)
		{
			Format(m_szType, 16, "trail");
			Format(m_szName, 128, "305");
			Format(m_szPath, 128, "materials/sprites/store/trails/awesome.vmt");
			return true;
		}
		if(iRandom_Item == 3)
		{
			Format(m_szType, 16, "trail");
			Format(m_szName, 128, "钞票");
			Format(m_szPath, 128, "materials/sprites/store/trails/banknote.vmt");
			return true;
		}
		if(iRandom_Item == 4)
		{
			Format(m_szType, 16, "trail");
			Format(m_szName, 128, "闪电");
			Format(m_szPath, 128, "materials/sprites/store/trails/bluelightning.vmt");
			return true;
		}
		if(iRandom_Item == 5)
		{
			Format(m_szType, 16, "trail");
			Format(m_szName, 128, "皇冠");
			Format(m_szPath, 128, "materials/sprites/store/trails/crown.vmt");
			return true;
		}
		if(iRandom_Item == 6)
		{
			Format(m_szType, 16, "trail");
			Format(m_szName, 128, "暴漫 Fuu 1");
			Format(m_szPath, 128, "materials/sprites/store/trails/fuu1.vmt");
			return true;
		}
		if(iRandom_Item == 7)
		{
			Format(m_szType, 16, "trail");
			Format(m_szName, 128, "数码宝贝");
			Format(m_szPath, 128, "materials/sprites/store/trails/pokeball.vmt");
			return true;
		}
		if(iRandom_Item == 8)
		{
			Format(m_szType, 16, "trail");
			Format(m_szName, 128, "精神球");
			Format(m_szPath, 128, "materials/sprites/store/trails/psychball.vmt");
			return true;
		}
		if(iRandom_Item == 9)
		{
			Format(m_szType, 16, "trail");
			Format(m_szName, 128, "彩虹");
			Format(m_szPath, 128, "materials/sprites/store/trails/rainbow.vmt");
			return true;
		}
		if(iRandom_Item == 10)
		{
			Format(m_szType, 16, "trail");
			Format(m_szName, 128, "藤藤蛇");
			Format(m_szPath, 128, "materials/sprites/store/trails/smugleaf.vmt");
			return true;
		}
		if(iRandom_Item == 11)
		{
			Format(m_szType, 16, "trail");
			Format(m_szName, 128, "海绵宝宝");
			Format(m_szPath, 128, "materials/sprites/store/trails/spongebob.vmt");
			return true;
		}
		if(iRandom_Item == 12)
		{
			Format(m_szType, 16, "trail");
			Format(m_szName, 128, "暴漫 Troll");
			Format(m_szPath, 128, "materials/sprites/store/trails/trollface.vmt");
			return true;
		}
		if(iRandom_Item == 13)
		{
			Format(m_szType, 16, "trail");
			Format(m_szName, 128, "Windows");
			Format(m_szPath, 128, "materials/sprites/store/trails/windows.vmt");
			return true;
		}
		if(iRandom_Item == 14)
		{
			Format(m_szType, 16, "trail");
			Format(m_szName, 128, "太极");
			Format(m_szPath, 128, "materials/sprites/store/trails/yingyang2.vmt");
			return true;
		}
		if(iRandom_Item == 15)
		{
			Format(m_szType, 16, "Particles");
			Format(m_szName, 128, "渐变粒子");
			Format(m_szPath, 128, "Trail");
			return true;
		}
		if(iRandom_Item == 16)
		{
			Format(m_szType, 16, "Particles");
			Format(m_szName, 128, "火焰粒子");
			Format(m_szPath, 128, "Trail5");
			return true;
		}
		if(iRandom_Item == 17)
		{
			Format(m_szType, 16, "Particles");
			Format(m_szName, 128, "鞭炮");
			Format(m_szPath, 128, "Trail2");
			return true;
		}
		if(iRandom_Item == 18)
		{
			Format(m_szType, 16, "Particles");
			Format(m_szName, 128, "浪花");
			Format(m_szPath, 128, "Trail3");
			return true;
		}
		if(iRandom_Item == 19)
		{
			Format(m_szType, 16, "Particles");
			Format(m_szName, 128, "喷射粒子");
			Format(m_szPath, 128, "Trail4");
			return true;
		}
		if(iRandom_Item == 20)
		{
			Format(m_szType, 16, "Particles");
			Format(m_szName, 128, "绿色星火");
			Format(m_szPath, 128, "Trail7");
			return true;
		}
		if(iRandom_Item == 21)
		{
			Format(m_szType, 16, "Particles");
			Format(m_szName, 128, "星光");
			Format(m_szPath, 128, "Trail8");
			return true;
		}
		if(iRandom_Item == 22)
		{
			Format(m_szType, 16, "Particles");
			Format(m_szName, 128, "粉色尖刺");
			Format(m_szPath, 128, "Trail9");
			return true;
		}
		if(iRandom_Item == 23)
		{
			Format(m_szType, 16, "Particles");
			Format(m_szName, 128, "细菌孢");
			Format(m_szPath, 128, "Trail10");
			return true;
		}
		if(iRandom_Item == 24)
		{
			Format(m_szType, 16, "Particles");
			Format(m_szName, 128, "橙色星火");
			Format(m_szPath, 128, "Trail11");
			return true;
		}
		if(iRandom_Item == 25)
		{
			Format(m_szType, 16, "trail");
			Format(m_szName, 128, "Planeptune");
			Format(m_szPath, 128, "materials/maoling/trails/planeptune.vmt");
			return true;
		}
		if(iRandom_Item == 26)
		{
			Format(m_szType, 16, "trail");
			Format(m_szName, 128, "滑稽");
			Format(m_szPath, 128, "materials/maoling/trails/huaji.vmt");
			return true;
		}
	}
	else if(iRandom_Type == 5)
	{
		if(iRandom_Item == 1)
		{
			Format(m_szType, 16, "Aura");
			Format(m_szName, 128, "橙色旋风");
			Format(m_szPath, 128, "Aura1");
			return true;
		}
		if(iRandom_Item == 2)
		{
			Format(m_szType, 16, "Aura");
			Format(m_szName, 128, "红色尖刺黑洞");
			Format(m_szPath, 128, "Aura2");
			return true;
		}
		if(iRandom_Item == 3)
		{
			Format(m_szType, 16, "Aura");
			Format(m_szName, 128, "蓝紫尖刺");
			Format(m_szPath, 128, "Aura3");
			return true;
		}
		if(iRandom_Item == 4)
		{
			Format(m_szType, 16, "Aura");
			Format(m_szName, 128, "绿色尖刺黑洞");
			Format(m_szPath, 128, "Aura4");
			return true;
		}
		if(iRandom_Item == 5)
		{
			Format(m_szType, 16, "Aura");
			Format(m_szName, 128, "慢-星空");
			Format(m_szPath, 128, "Aura5");
			return true;
		}
		if(iRandom_Item == 6)
		{
			Format(m_szType, 16, "Aura");
			Format(m_szName, 128, "星空");
			Format(m_szPath, 128, "Aura6");
			return true;
		}
		if(iRandom_Item == 7)
		{
			Format(m_szType, 16, "Aura");
			Format(m_szName, 128, "粒子漩涡");
			Format(m_szPath, 128, "Aura7");
			return true;
		}
		if(iRandom_Item == 8)
		{
			Format(m_szType, 16, "Aura");
			Format(m_szName, 128, "青紫粒子漩涡");
			Format(m_szPath, 128, "Aura8");
			return true;
		}
		if(iRandom_Item == 9)
		{
			Format(m_szType, 16, "Aura");
			Format(m_szName, 128, "蓝色粒子漩涡");
			Format(m_szPath, 128, "Aura9");
			return true;
		}
		if(iRandom_Item == 10)
		{
			Format(m_szType, 16, "Aura");
			Format(m_szName, 128, "紫色尖刺漩涡");
			Format(m_szPath, 128, "Aura10");
			return true;
		}
	}
	else if(iRandom_Type == 6)
	{
		if(iRandom_Item == 1)
		{
			Format(m_szType, 16, "namecolor");
			Format(m_szName, 128, "蓝色");
			Format(m_szPath, 128, "{blue}");
			return true;
		}
		if(iRandom_Item == 2)
		{
			Format(m_szType, 16, "namecolor");
			Format(m_szName, 128, "深红色");
			Format(m_szPath, 128, "{darkred}");
			return true;
		}
		if(iRandom_Item == 3)
		{
			Format(m_szType, 16, "namecolor");
			Format(m_szName, 128, "灰色");
			Format(m_szPath, 128, "{gray}");
			return true;
		}
		if(iRandom_Item == 4)
		{
			Format(m_szType, 16, "namecolor");
			Format(m_szName, 128, "绿色");
			Format(m_szPath, 128, "{green}");
			return true;
		}
		if(iRandom_Item == 5)
		{
			Format(m_szType, 16, "namecolor");
			Format(m_szName, 128, "淡红色");
			Format(m_szPath, 128, "{lightred}");
			return true;
		}
		if(iRandom_Item == 6)
		{
			Format(m_szType, 16, "namecolor");
			Format(m_szName, 128, "橙色");
			Format(m_szPath, 128, "{orange}");
			return true;
		}
		if(iRandom_Item == 7)
		{
			Format(m_szType, 16, "namecolor");
			Format(m_szName, 128, "白色");
			Format(m_szPath, 128, "{white}");
			return true;
		}
		if(iRandom_Item == 8)
		{
			Format(m_szType, 16, "namecolor");
			Format(m_szName, 128, "黄色");
			Format(m_szPath, 128, "{yellow}");
			return true;
		}
	}
	else if(iRandom_Type == 7)
	{
		if(iRandom_Item == 1)
		{
			Format(m_szType, 16, "nametag");
			Format(m_szName, 128, "[东山大法]");
			Format(m_szPath, 128, "{lightred}[东山大法]{teamcolor} ");
			return true;
		}
		if(iRandom_Item == 2)
		{
			Format(m_szType, 16, "nametag");
			Format(m_szName, 128, "[比较萌的]");
			Format(m_szPath, 128, "{lightred}[比较萌的]{teamcolor} ");
			return true;
		}
		if(iRandom_Item == 3)
		{
			Format(m_szType, 16, "nametag");
			Format(m_szName, 128, "_(:з」∠)_");
			Format(m_szPath, 128, "{lightblue}_(:з」∠)_{teamcolor}");
			return true;
		}
		if(iRandom_Item == 4)
		{
			Format(m_szType, 16, "nametag");
			Format(m_szName, 128, "[抖S]");
			Format(m_szPath, 128, "{lightblue}[抖S]{teamcolor}");
			return true;
		}
		if(iRandom_Item == 5)
		{
			Format(m_szType, 16, "nametag");
			Format(m_szName, 128, "[萝莉]");
			Format(m_szPath, 128, "{lightred}[萝莉]{teamcolor} ");
			return true;
		}
		if(iRandom_Item == 6)
		{
			Format(m_szType, 16, "nametag");
			Format(m_szName, 128, "[抖M]");
			Format(m_szPath, 128, "{lightblue}[抖M]{teamcolor}");
			return true;
		}
		if(iRandom_Item == 7)
		{
			Format(m_szType, 16, "nametag");
			Format(m_szName, 128, "[小学生]");
			Format(m_szPath, 128, "{lightblue}[小学生]{teamcolor}");
			return true;
		}
		if(iRandom_Item == 8)
		{
			Format(m_szType, 16, "nametag");
			Format(m_szName, 128, "[德玛西亚]");
			Format(m_szPath, 128, "{lightblue}[德玛西亚]{teamcolor}");
			return true;
		}
		if(iRandom_Item == 9)
		{
			Format(m_szType, 16, "nametag");
			Format(m_szName, 128, "[工口]");
			Format(m_szPath, 128, "{lightblue}[工口]{teamcolor}");
			return true;
		}
		if(iRandom_Item == 10)
		{
			Format(m_szType, 16, "nametag");
			Format(m_szName, 128, "[么么哒]");
			Format(m_szPath, 128, "{lightblue}[么么哒]{teamcolor}");
			return true;
		}
		if(iRandom_Item == 11)
		{
			Format(m_szType, 16, "nametag");
			Format(m_szName, 128, "[本子狂魔]");
			Format(m_szPath, 128, "{lightblue}[本子狂魔]{teamcolor}");
			return true;
		}
		if(iRandom_Item == 12)
		{
			Format(m_szType, 16, "nametag");
			Format(m_szName, 128, "[大地球]");
			Format(m_szPath, 128, "{lightred}[大地球]{teamcolor} ");
			return true;
		}
		if(iRandom_Item == 13)
		{
			Format(m_szType, 16, "nametag");
			Format(m_szName, 128, "[我最帅]");
			Format(m_szPath, 128, "{lightred}[我最帅]{teamcolor} ");
			return true;
		}
		if(iRandom_Item == 14)
		{
			Format(m_szType, 16, "nametag");
			Format(m_szName, 128, "[薄荷味]");
			Format(m_szPath, 128, "{lightred}[薄荷味]{teamcolor} ");
			return true;
		}
		if(iRandom_Item == 15)
		{
			Format(m_szType, 16, "nametag");
			Format(m_szName, 128, "[公交车]");
			Format(m_szPath, 128, "{lightred}[公交车]{teamcolor} ");
			return true;
		}
		if(iRandom_Item == 16)
		{
			Format(m_szType, 16, "nametag");
			Format(m_szName, 128, "[老司机]");
			Format(m_szPath, 128, "{lightred}[老司机]{teamcolor} ");
			return true;
		}
		if(iRandom_Item == 17)
		{
			Format(m_szType, 16, "nametag");
			Format(m_szName, 128, "[HENTAI]");
			Format(m_szPath, 128, "{lightred}[HENTAI]{teamcolor} ");
			return true;
		}
		if(iRandom_Item == 18)
		{
			Format(m_szType, 16, "nametag");
			Format(m_szName, 128, "[TTT影帝]");
			Format(m_szPath, 128, "{lightred}[TTT影帝]{teamcolor} ");
			return true;
		}
		if(iRandom_Item == 19)
		{
			Format(m_szType, 16, "nametag");
			Format(m_szName, 128, "[新机表]");
			Format(m_szPath, 128, "{lightred}[新机表]{teamcolor} ");
			return true;
		}
		if(iRandom_Item == 20)
		{
			Format(m_szType, 16, "nametag");
			Format(m_szName, 128, "[黑枪王子]");
			Format(m_szPath, 128, "{lightred}[黑枪王子]{teamcolor} ");
			return true;
		}
		if(iRandom_Item == 21)
		{
			Format(m_szType, 16, "nametag");
			Format(m_szName, 128, "[暴动狂魔]");
			Format(m_szPath, 128, "{lightred}[暴动狂魔]{teamcolor} ");
			return true;
		}
		if(iRandom_Item == 22)
		{
			Format(m_szType, 16, "nametag");
			Format(m_szName, 128, "[跑男]");
			Format(m_szPath, 128, "{lightred}[跑男]{teamcolor} ");
			return true;
		}
	}
	else if(iRandom_Type == 8)
	{
		if(iRandom_Item == 1)
		{
			Format(m_szType, 16, "msgcolor");
			Format(m_szName, 128, "蓝色");
			Format(m_szPath, 128, "{blue}");
			return true;
		}
		if(iRandom_Item == 2)
		{
			Format(m_szType, 16, "msgcolor");
			Format(m_szName, 128, "深红色");
			Format(m_szPath, 128, "{darkred}");
			return true;
		}
		if(iRandom_Item == 3)
		{
			Format(m_szType, 16, "msgcolor");
			Format(m_szName, 128, "灰色");
			Format(m_szPath, 128, "{gray}");
			return true;
		}
		if(iRandom_Item == 4)
		{
			Format(m_szType, 16, "msgcolor");
			Format(m_szName, 128, "绿色");
			Format(m_szPath, 128, "{green}");
			return true;
		}
		if(iRandom_Item == 5)
		{
			Format(m_szType, 16, "msgcolor");
			Format(m_szName, 128, "淡红色");
			Format(m_szPath, 128, "{lightred}");
			return true;
		}
		if(iRandom_Item == 6)
		{
			Format(m_szType, 16, "msgcolor");
			Format(m_szName, 128, "橙色");
			Format(m_szPath, 128, "{orange}");
			return true;
		}
		if(iRandom_Item == 7)
		{
			Format(m_szType, 16, "msgcolor");
			Format(m_szName, 128, "白色");
			Format(m_szPath, 128, "{white}");
			return true;
		}
		if(iRandom_Item == 8)
		{
			Format(m_szType, 16, "msgcolor");
			Format(m_szName, 128, "黄色");
			Format(m_szPath, 128, "{yellow}");
			return true;
		}
	}
	else if(iRandom_Type == 9)
	{
		if(iRandom_Item == 1)
		{
			Format(m_szType, 16, "spray");
			Format(m_szName, 128, "互相伤害");
			Format(m_szPath, 128, "materials/maoling/sprays/laia.vmt");
			return true;
		}
		if(iRandom_Item == 2)
		{
			Format(m_szType, 16, "spray");
			Format(m_szName, 128, "呐!!");
			Format(m_szPath, 128, "materials/maoling/sprays/na.vmt");
			return true;
		}
		if(iRandom_Item == 3)
		{
			Format(m_szType, 16, "spray");
			Format(m_szName, 128, "害怕");
			Format(m_szPath, 128, "materials/maoling/sprays/cghaipa.vmt");
			return true;
		}
		if(iRandom_Item == 4)
		{
			Format(m_szType, 16, "spray");
			Format(m_szName, 128, "materials/maoling/sprays/slaydog.vmt");
			Format(m_szPath, 128, "{green}");
			return true;
		}
		if(iRandom_Item == 5)
		{
			Format(m_szType, 16, "spray");
			Format(m_szName, 128, "50已到");
			Format(m_szPath, 128, "materials/maoling/sprays/50highnoon.vmt");
			return true;
		}
	}
	else if(iRandom_Type == 10)
	{
		if(iRandom_Item == 1)
		{
			Format(m_szType, 16, "sound");
			Format(m_szName, 128, "溜金哇开呀酷裂");
			Format(m_szPath, 128, "sound/maoling/store/overwatch/genji.mp3");
			return true;
		}
		if(iRandom_Item == 2)
		{
			Format(m_szType, 16, "sound");
			Format(m_szName, 128, "溜噶哇噶叠其噢酷啦污");
			Format(m_szPath, 128, "sound/maoling/store/overwatch/hanzo.mp3");
			return true;
		}
		if(iRandom_Item == 3)
		{
			Format(m_szType, 16, "sound");
			Format(m_szName, 128, "Fire in the Hole");
			Format(m_szPath, 128, "sound/maoling/store/overwatch/junkrat.mp3");
			return true;
		}
		if(iRandom_Item == 4)
		{
			Format(m_szType, 16, "sound");
			Format(m_szName, 128, "午时已到");
			Format(m_szPath, 128, "sound/maoling/store/overwatch/mccree.mp3");
			return true;
		}
		if(iRandom_Item == 5)
		{
			Format(m_szType, 16, "sound");
			Format(m_szName, 128, "冻住不许走");
			Format(m_szPath, 128, "sound/maoling/store/overwatch/mei.mp3");
			return true;
		}
		if(iRandom_Item == 6)
		{
			Format(m_szType, 16, "sound");
			Format(m_szName, 128, "噢!在这停顿");
			Format(m_szPath, 128, "sound/maoling/store/overwatch/lucio.mp3");
			return true;
		}
	}
	else if(iRandom_Type == 11)
	{
		if(iRandom_Item == 1)
		{
			Format(m_szType, 16, "vwmodel");
			Format(m_szName, 128, "龙神剑");
			Format(m_szPath, 128, "models/maoling/weapon/overwatch/knife/genji/katana_v.mdl");
			return true;
		}
	}
	return false;
}

stock bool GetModelPath(int id, char[] szPath, int maxlen)
{
	if(id == 1)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/guilty_crown/inori/inori.mdl");
		return true;
	}
	else if(id == 2)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/misc/banana_joe/banana_joe.mdl");
		return true;
	}
	else if(id == 3)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/date_a_live/tohka/spirit/tohka.mdl");
		return true;
	}
	else if(id == 4)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/date_a_live/kurumi/spirit/kurumi.mdl");
		return true;
	}
	else if(id == 5)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/touhou/remilia_scarlet/remilia_scarlet.mdl");
		return true;
	}
	else if(id == 6)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/touhou/flandre_scarlet/flandre_scarlet.mdl");
		return true;
	}
	else if(id == 7)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/seirei_tsukai_no_blade_dance/terminus_est/terminus_est.mdl");
		return true;
	}
	else if(id == 8)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/kantai_collection/shimakaze/shimakaze.mdl");
		return true;
	}
	else if(id == 9)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/neptunia/neptune/swimsuit/neptune.mdl");
		return true;
	}
	else if(id == 10)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/haipa/haipa.mdl");
		return true;
	}
	else if(id == 11)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/neptunia/uni/normal/uni.mdl");
		return true;
	}
	else if(id == 12)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/date_a_live/yoshino/spirit/yoshino.mdl");
		return true;
	}
	else if(id == 13)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/neptunia/neptune/swimwear/neptune.mdl");
		return true;
	}
	else if(id == 14)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/vocaloid/hatsune_miku/tda/miku.mdl");
		return true;
	}
	else if(id == 15)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/neptunia/blanc/normal/blanc.mdl");
		return true;
	}
	else if(id == 16)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/vocaloid/hatsune_miku/magnet/miku.mdl");
		return true;
	}
	else if(id == 17)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/misc/rikka/rikka.mdl");
		return true;
	}
	else if(id == 18)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/touhou/momiji/momiji.mdl");
		return true;
	}
	else if(id == 19)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/black_rock_shooter/brs/brs.mdl");
		return true;
	}
	else if(id == 20)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/kantai_collection/amatsukaze/amatsukaze.mdl");
		return true;
	}else if(id == 21)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/lovelive/kotori/school/kotori.mdl");
		return true;
	}
	else if(id == 22)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/neptunia/noire/normal/noire.mdl");
		return true;
	}
	else if(id == 23)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/kantai_collection/hoppou/hoppou.mdl");
		return true;
	}
	else if(id == 24)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/date_a_live/kotori/school/kotori.mdl");
		return true;
	}
	else if(id == 25)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/neptunia/adult_neptune/swimsuit_v2/neptune.mdl");
		return true;
	}
	else if(id == 26)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/neptunia/adult_neptune/normal/neptune.mdl");
		return true;
	}
	else if(id == 27)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/neptunia/noire/nextform/nextblack.mdl");
		return true;
	}
	else if(id == 28)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/neptunia/noire/nextform/nextblack_nothruster.mdl");
		return true;
	}
	else if(id == 29)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/neptunia/vert/nextform/nextgreen.mdl");
		return true;
	}
	else if(id == 30)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/neptunia/blanc/nextform/nextwhite.mdl");
		return true;
	}
	else if(id == 31)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/neptunia/blanc/nextform/nextwhite_nothruster.mdl");
		return true;
	}
	else if(id == 32)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/kantai_collection/hikibi/hikibi.mdl");
		return true;
	}
	else if(id == 33)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/neptunia/hatsumi_sega/normal/sega_girl.mdl");
		return true;
	}
	else if(id == 34)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/vocaloid/haku/uniform/haku.mdl");
		return true;
	}
	else if(id == 35)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/sword_art_online/shino/ggo/shino.mdl");
		return true;
	}
	else if(id == 36)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/kantai_collection/yuudachi/yuudachi.mdl");
		return true;
	}
	else if(id == 37)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/neptunia/histoire/normal/histoire.mdl");
		return true;
	}
	else if(id == 38)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/fairyfancyf/tiara/tiara.mdl");
		return true;
	}
	else if(id == 39)
	{
		Format(szPath, maxlen, "models/player/custom_player/maoling/vocaloid/luka/punk/luka.mdl");
		return true;
	}

	return false;
}

stock bool GetModelName(int id, char[] szPath, int maxlen)
{
	if(id == 1)
	{
		Format(szPath, maxlen, "Inori");
		return true;
	}
	else if(id == 2)
	{
		Format(szPath, maxlen, "香蕉人");
		return true;
	}
	else if(id == 3)
	{
		Format(szPath, maxlen, "Tohka十香");
		return true;
	}
	else if(id == 4)
	{
		Format(szPath, maxlen, "Kurumi狂三");
		return true;
	}
	else if(id == 5)
	{
		Format(szPath, maxlen, "Remilia蕾米莉亚");
		return true;
	}
	else if(id == 6)
	{
		Format(szPath, maxlen, "Flandre芙兰朵露");
		return true;
	}
	else if(id == 7)
	{
		Format(szPath, maxlen, "提露密努斯·艾斯特");
		return true;
	}
	else if(id == 8)
	{
		Format(szPath, maxlen, "Shimakaze岛风");
		return true;
	}
	else if(id == 9)
	{
		Format(szPath, maxlen, "妮普褆努.泳装(Neptune)");
		return true;
	}
	else if(id == 10)
	{
		Format(szPath, maxlen, "Afraid害怕");
		return true;
	}
	else if(id == 11)
	{
		Format(szPath, maxlen, "優尼(Uni)");
		return true;
	}
	else if(id == 12)
	{
		Format(szPath, maxlen, "四糸乃(Yoshino)");
		return true;
	}
	else if(id == 13)
	{
		Format(szPath, maxlen, "妮普褆努.夏日鮮黃(Neptune)");
		return true;
	}
	else if(id == 14)
	{
		Format(szPath, maxlen, "初音未来.TDA(Miku)");
		return true;
	}
	else if(id == 15)
	{
		Format(szPath, maxlen, "布蘭(Blanc)");
		return true;
	}
	else if(id == 16)
	{
		Format(szPath, maxlen, "初音未来.和服(Miku)");
		return true;
	}
	else if(id == 17)
	{
		Format(szPath, maxlen, "Rikka小鸟游六花");
		return true;
	}
	else if(id == 18)
	{
		Format(szPath, maxlen, "犬走椛(Momiji)");
		return true;
	}
	else if(id == 19)
	{
		Format(szPath, maxlen, "黑岩射手(BRS)");
		return true;
	}
	else if(id == 20)
	{
		Format(szPath, maxlen, "Amatsukaze天津风");
		return true;
	}else if(id == 21)
	{
		Format(szPath, maxlen, "Kotori南小鸟");
		return true;
	}
	else if(id == 22)
	{
		Format(szPath, maxlen, "南小鸟(kotori)");
		return true;
	}
	else if(id == 23)
	{
		Format(szPath, maxlen, "北方栖姬(Hoppou)");
		return true;
	}
	else if(id == 24)
	{
		Format(szPath, maxlen, "琴里.校服(Kotori)");
		return true;
	}
	else if(id == 25)
	{
		Format(szPath, maxlen, "大個子妮普褆努(Swimsult)");
		return true;
	}
	else if(id == 26)
	{
		Format(szPath, maxlen, "大個子妮普褆努Adult Neptune(Normal)");
		return true;
	}
	else if(id == 27)
	{
		Format(szPath, maxlen, "次時代諾娃(NextBlack)");
		return true;
	}
	else if(id == 28)
	{
		Format(szPath, maxlen, "次時代諾娃[Non-Thruster]");
		return true;
	}
	else if(id == 29)
	{
		Format(szPath, maxlen, "次時代貝兒(NextGreen)");
		return true;
	}
	else if(id == 30)
	{
		Format(szPath, maxlen, "次時代布蘭(NextWhite)");
		return true;
	}
	else if(id == 31)
	{
		Format(szPath, maxlen, "次時代布蘭[Non-Thruster]");
		return true;
	}
	else if(id == 32)
	{
		Format(szPath, maxlen, "响(Hikibi)");
		return true;
	}
	else if(id == 33)
	{
		Format(szPath, maxlen, "世嘉少女(HatsumiSega)");
		return true;
	}
	else if(id == 34)
	{
		Format(szPath, maxlen, "弱音(Haku)");
		return true;
	}
	else if(id == 35)
	{
		Format(szPath, maxlen, "朝田诗乃(Shino)");
		return true;
	}
	else if(id == 36)
	{
		Format(szPath, maxlen, "夕立(Yuudachi)");
		return true;
	}
	else if(id == 37)
	{
		Format(szPath, maxlen, "希斯(Historie)");
		return true;
	}
	else if(id == 38)
	{
		Format(szPath, maxlen, "褆亞拉(Tiara)");
		return true;
	}
	else if(id == 39)
	{
		Format(szPath, maxlen, "巡音露卡.摇滚(Luka)");
		return true;
	}
	return false;
}
