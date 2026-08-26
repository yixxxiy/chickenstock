class_name Loc
extends Object

const SETTINGS_PATH := "user://cluck-settings.json"

static var lang := "zh"
static var _booted := false
static var _toggle_ms := 0

const ZH := {
	"settings": "设置",
	"close": "关闭",
	"sfx_on": "音效：开",
	"sfx_off": "音效：关",
	"amb_on": "环境音：开",
	"amb_off": "环境音：关",
	"help": "只点气泡和按钮。长按可以连续收、买、卖。八日挑战：资产 3000，同时养 15 只鸡。",
	"credits": "制作人：hhhhhnicaia@gmail.com",
	"restart": "重新开始",
	"lang": "English / 中文",
	"lang_zh": "语言：中文",
	"lang_en": "Language: English",
	"cash": "现金",
	"stock": "股票",
	"day_frac": "%d/8天",
	"end_day": "结束本日",
	"dusk_warn": "天快黑了",
	"buy_chick": "买 %d",
	"sell_hen": "卖 %d",
	"buy_share": "买1股",
	"sell_share": "卖1股",
	"eggs_count": "蛋 %d",
	"oven_max": "烤炉 Lv.%d\n已满级",
	"oven_up": "升级烤炉 Lv.%d→%d\n%d 金币",
	"gold_n": "金币  %d",
	"shares_n": "%d股",
	"baking": "烘焙中 %.1fs",
	"sell_cake_tip": "出售蛋糕，现有 %d 个",
	"cake_baking_tip": "蛋糕制作中",
	"news_hoard": "狼商囤粮",
	"news_cake": "蛋糕热销",
	"news_rain": "雨天减产",
	"tonight_news": "今夜告示 · %s",
	"quest_head": "农场任务",
	"quest_goal": "资产 3000，同时养 15 只鸡",
	"quest_done": "同一时刻双线达标",
	"quest_wealth": "总资产 %d / %d",
	"quest_flock": "拥有鸡 %d / %d",
	"quest_wealth_name": "总资产",
	"quest_flock_name": "拥有鸡",
	"quest_need_gold": "还差 %d",
	"quest_need_birds": "还差 %d 只",
	"quest_hit": "已达标",
	"quest_note": "两项要同时达到。资产掉下去或把鸡卖掉，完成会取消。",
	"quest_note_done": "三千金币和十五只鸡，同一时刻到手。",
	"toast_dusk": "天快黑了，蛋会碎！",
	"toast_eggs_done": "今天的鸡蛋已经收完啦",
	"toast_no_chick": "还没有孵出来的小鸡",
	"toast_hatch_once": "每天只能孵 1 枚蛋",
	"toast_need_egg": "还差鸡蛋",
	"toast_hatching": "放进孵蛋器啦，明天出壳",
	"toast_no_cake": "还没有可出售的蛋糕",
	"toast_need_gold_share": "金币不够买入一股",
	"toast_no_shares": "还没有持股",
	"toast_need_gold_chick": "金币不够买小鸡",
	"toast_oven_short": "升级烤炉还差 %d 金币",
	"toast_oven_up": "烤炉升到 Lv.%d · 制作只需 %.1f 秒",
	"toast_no_hen": "还没有可以卖的母鸡",
	"toast_eggs_lost": "今天的蛋没有留到明天",
	"toast_no_rewind": "这一天没法重玩",
	"toast_watching_ad": "正在招商…",
	"toast_rewound": "已重玩第 %d 天",
	"toast_quest": "双线达标！",
	"daily_title": "晚间报告",
	"report_stats": "本日账目",
	"day_to_day": "第 %d 天  →  第 %d 天",
	"night_n": "第 %d 夜",
	"close_price": "收盘股价",
	"broken": "碎蛋",
	"grown": "长成",
	"cakes": "蛋糕",
	"wealth_flow": "总资产  %d  →  %d",
	"hatch_note": "新孵 %d 只，天亮后点孵蛋器领取",
	"start_new_day": "开始新一天",
	"watch_ad": "看广告重玩",
	"finale_title": "小鸡股市",
	"finale_hook": "我在八日挑战里混成了",
	"rank_n": "第 %d / 10 等",
	"wealth_cap": "总资产",
	"flock_cap": "鸡群",
	"birds_n": "%d 只",
	"goal_n": "目标 %d",
	"goal_frac": "%d / %d",
	"goal_gap": "还差 %d",
	"goal_over": "超出 %d",
	"quest_stamp": "双线通关",
	"quest_miss": "八日翻车",
	"wealth_split": "现金 %d  ·  股票 %d",
	"chart_cap": "八日资产曲线",
	"chart_goal": "目标 %d",
	"retry_eight": "再战八天",
	"share_card": "晒成绩",
	"share_saved": "已保存",
	"share_mark": "小鸡股市 · 敢不敢比",
	"toast_card_saved": "成绩图已保存，发到聊天里晒一下",
	"toast_card_fail": "图片没存下来，再试一次",
	"rank_1_title": "流浪小鸡",
	"rank_1_copy": "八天空手而归。鸡：这人我都不认识。",
	"rank_2_title": "见习股民",
	"rank_2_copy": "刚进股市，学费已经交齐。",
	"rank_3_title": "咯咯佃农",
	"rank_3_copy": "农场转了，钱包没转。",
	"rank_4_title": "小本鸡舍",
	"rank_4_copy": "有点积蓄，动物街刚记得住脸。",
	"rank_5_title": "温饱农场",
	"rank_5_copy": "能吃饱，还不够拿出来炫耀。",
	"rank_6_title": "街口商贩",
	"rank_6_copy": "买卖像样了，邻居开始打听你。",
	"rank_7_title": "农场掌柜",
	"rank_7_copy": "鸡舍和股市两边都能转。",
	"rank_8_title": "动物街新贵",
	"rank_8_copy": "资产过三千，街上开始传你的名。",
	"rank_9_title": "金币大亨",
	"rank_9_copy": "股价和农场都听你的。",
	"rank_10_title": "农场传奇",
	"rank_10_copy": "八日登顶。明天他们还在讨论你。",
}

const EN := {
	"settings": "Settings",
	"close": "Close",
	"sfx_on": "SFX: On",
	"sfx_off": "SFX: Off",
	"amb_on": "Ambience: On",
	"amb_off": "Ambience: Off",
	"help": "Tap bubbles and buttons. Hold to collect, buy, or sell. 8-day challenge: 3000 wealth and 15 birds at once.",
	"credits": "Contact: hhhhhhnicaia@gmail.com",
	"restart": "Start Over",
	"lang": "English / 中文",
	"lang_zh": "语言：中文",
	"lang_en": "Language: English",
	"cash": "Cash",
	"stock": "Stocks",
	"day_frac": "Day %d/8",
	"end_day": "End Day",
	"dusk_warn": "Night falling",
	"buy_chick": "Buy %d",
	"sell_hen": "Sell %d",
	"buy_share": "Buy 1",
	"sell_share": "Sell 1",
	"eggs_count": "Eggs %d",
	"oven_max": "Oven Lv.%d\nMaxed",
	"oven_up": "Upgrade oven Lv.%d→%d\n%d gold",
	"gold_n": "Gold  %d",
	"shares_n": "%d shares",
	"baking": "Baking %.1fs",
	"sell_cake_tip": "Sell cakes (%d)",
	"cake_baking_tip": "Cake in the oven",
	"news_hoard": "Wolf hoards grain",
	"news_cake": "Cakes selling fast",
	"news_rain": "Rain cuts yield",
	"tonight_news": "Tonight · %s",
	"quest_head": "Farm Quest",
	"quest_goal": "Hit 3000 wealth and 15 birds at the same time",
	"quest_done": "Both goals met",
	"quest_wealth": "Wealth %d / %d",
	"quest_flock": "Birds %d / %d",
	"quest_wealth_name": "Wealth",
	"quest_flock_name": "Birds",
	"quest_need_gold": "%d to go",
	"quest_need_birds": "%d birds to go",
	"quest_hit": "Done",
	"quest_note": "Both must be true at the same time. Selling birds or losing wealth undoes it.",
	"quest_note_done": "3000 gold and 15 birds, held together.",
	"toast_dusk": "Night is falling — eggs will spoil!",
	"toast_eggs_done": "No more eggs today",
	"toast_no_chick": "No chicks have hatched yet",
	"toast_hatch_once": "Only 1 egg can hatch per day",
	"toast_need_egg": "Need an egg first",
	"toast_hatching": "In the incubator — hatches tomorrow",
	"toast_no_cake": "No cakes to sell",
	"toast_need_gold_share": "Not enough gold for a share",
	"toast_no_shares": "You don't hold any shares",
	"toast_need_gold_chick": "Not enough gold for a chick",
	"toast_oven_short": "Need %d more gold to upgrade",
	"toast_oven_up": "Oven Lv.%d · bakes in %.1fs",
	"toast_no_hen": "No hens to sell",
	"toast_eggs_lost": "Today's eggs didn't last the night",
	"toast_no_rewind": "Can't rewind this day",
	"toast_watching_ad": "Ads coming soon…",
	"toast_rewound": "Rewound to day %d",
	"toast_quest": "Both goals hit!",
	"daily_title": "Night Report",
	"report_stats": "Today's tally",
	"day_to_day": "Day %d  →  Day %d",
	"night_n": "Night %d",
	"close_price": "Closing price",
	"broken": "Broken",
	"grown": "Grown",
	"cakes": "Cakes",
	"wealth_flow": "Wealth  %d  →  %d",
	"hatch_note": "%d hatched. Collect at the incubator after dawn.",
	"start_new_day": "Start a new day",
	"watch_ad": "Watch ad to replay",
	"finale_title": "Chick Street",
	"finale_hook": "I finished the 8-day run as",
	"rank_n": "Rank %d / 10",
	"wealth_cap": "Wealth",
	"flock_cap": "Flock",
	"birds_n": "%d birds",
	"goal_n": "Goal %d",
	"goal_frac": "%d / %d",
	"goal_gap": "%d short",
	"goal_over": "+%d over",
	"quest_stamp": "Both goals cleared",
	"quest_miss": "Eight-day flop",
	"wealth_split": "Cash %d  ·  Stocks %d",
	"chart_cap": "8-day wealth",
	"chart_goal": "Goal %d",
	"retry_eight": "Run 8 days again",
	"share_card": "Flex this",
	"share_saved": "Saved",
	"share_mark": "Chick Street · beat me",
	"toast_card_saved": "Card saved. Post it.",
	"toast_card_fail": "Couldn't save. Try again.",
	"rank_1_title": "Stray Chick",
	"rank_1_copy": "Eight days. Empty pockets. The hens don't know you.",
	"rank_2_title": "Rookie Trader",
	"rank_2_copy": "Found the market. Paid tuition immediately.",
	"rank_3_title": "Cluck Tenant",
	"rank_3_copy": "Farm's running. Wallet isn't.",
	"rank_4_title": "Small Coop",
	"rank_4_copy": "A little saved. Animal Street almost knows your face.",
	"rank_5_title": "Full-Belly Farm",
	"rank_5_copy": "You eat. You still wouldn't post this.",
	"rank_6_title": "Corner Vendor",
	"rank_6_copy": "Trade looks real. Neighbors started asking.",
	"rank_7_title": "Farm Keeper",
	"rank_7_copy": "Coop and market both run.",
	"rank_8_title": "Street Star",
	"rank_8_copy": "Over 3000. The street says your name.",
	"rank_9_title": "Gold Baron",
	"rank_9_copy": "Price and farm listen to you.",
	"rank_10_title": "Farm Legend",
	"rank_10_copy": "Eight days at the top. They're still talking.",
}

static func t(key: String, args: Array = []) -> String:
	if not _booted:
		_booted = true
		load_settings()
	var table: Dictionary = EN if lang == "en" else ZH
	var s := str(table.get(key, ZH.get(key, key)))
	if args.is_empty():
		return s
	return s % args

static func news(id: String) -> String:
	return t("news_%s" % id)

static func rank_title(lv: int) -> String:
	return t("rank_%d_title" % clampi(lv, 1, 10))

static func rank_copy(lv: int) -> String:
	return t("rank_%d_copy" % clampi(lv, 1, 10))

static func toggle() -> void:
	var now := Time.get_ticks_msec()
	if now - _toggle_ms < 280:
		return
	_toggle_ms = now
	lang = "en" if lang == "zh" else "zh"
	save()

static func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var next := str(parsed.get("lang", lang))
	if next == "en" or next == "zh":
		lang = next

static func save() -> void:
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"lang": lang}))
