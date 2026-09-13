# UI Kit Spreadsheet（可切割）

来源：界面重设计三张对版图（主菜单/农场/教程、设置/任务/成就、结算）。
生成后已洪水抠白底，四角透明。草图目录，未接主场景。

## 文件

- ui-elements-spreadsheet.png — 整张元素表（透明底）
- slices/ — 连通域自动切出的原尺寸碎片（按位置编号）
- 
amed/ — 语义命名副本，便于挑图

## named 索引

### 面板 / 框（建议九宫）
| 文件 | 用途 |
| --- | --- |
| 01-panel-tall-modal | 设置/任务/成就/结算主框 |
| 02-panel-medium-dialog | 教程弹窗、中等对话框 |
| 03-panel-hud-bar | 顶栏资源条 |
| 04-chip-value-slot | 现金/股价数字槽 |
| 05-panel-dock | 底栏交易面板 |
| 06-strip-news | 告示/新闻条 |

### 按钮
| 文件 | 用途 |
| --- | --- |
| 07-btn-green-wide | 开始游戏 / 结束今天 / 主 CTA |
| 08-btn-beige-wide | 教程 / 无尽 / 次要 |
| 09-btn-red-medium | 重置等危险操作 |
| 10-btn-green-short | 买入 |
| 11-btn-red-short | 卖出 |
| 12-btn-square-icon | 设置/成就方钮壳 |
| 13-btn-close-x | 弹窗关闭 |
| 14-chip-toggle-on | 分段选中（绿） |
| 15-chip-toggle-off | 分段未选（米） |

### 条 / 徽 / 装饰
| 文件 | 用途 |
| --- | --- |
| 16-bar-progress-track | 进度槽 |
| 23-bar-progress-fill | 进度填充 |
| 17-seal-check-green | 达标印 |
| 18-seal-x-red | 未达标印 |
| 19-bubble-action | 收集/孵化气泡壳 |
| 20-pip-filled-gold | 日程点亮 |
| 21-pip-empty | 日程未亮 |
| 22-ribbon-red | 八日总结缎带 |
| 24-deco-flourish | 标题下分隔饰 |

### 图标
| 文件 | 用途 |
| --- | --- |
| 25-icon-coin-chick | 金币 |
| 32-icon-arrow-up | 涨幅箭头 |
| 33-icon-mail | 信封 |
| 26-icon-gear | 齿轮 |
| 27-icon-trophy | 奖杯 |
| 34-icon-egg | 蛋 |
| 28-icon-chick | 小鸡 |
| 29-icon-hen | 母鸡 |
| 30-icon-clock | 时钟 |
| 35-icon-cake | 蛋糕 |
| 36-icon-egg-cracked | 碎蛋 |
| 31-icon-coop | 鸡舍 |

## 已接入运行时（2026-09-06）

已从 named/ 覆盖 simple-ui、frame/dock、close/mail/gear、icons、结算 pip。
九宫边距已在 Game.gd / UiLayout.gd / SettlementCard.gd / frame_tall_panel.tres / Game.tscn 对齐。

## 注意

- 空壳无字；文案仍走 Loc.gd。
- 图标若不满意可单文件回滚。
