# 图标替换指南

## 需要优先替换的图标清单

### 🔴 严重问题（12个）- 必须替换

| 当前文件名 | 搜索关键词 | Flaticon 推荐搜索 |
|-----------|-----------|------------------|
| 其它__减__Other__Minus.png | minus, subtract | `minus detailed filled` |
| 品牌__DHL__Brand__DHL.png | DHL logo | `delivery truck detailed` |
| 品牌__宜家__Brand__Ikea.png | IKEA, furniture | `furniture store detailed` |
| 品牌__暴雪__Brand__Blizzard.png | Blizzard, gaming | `game controller detailed` |
| 品牌__法拉利__Brand__Ferrari.png | Ferrari, sports car | `sports car detailed` |
| 品牌__ElevenLabs__Brand__ElevenLabs.png | AI, voice | `artificial intelligence detailed` |
| 品牌__爱彼__Brand__Audemarspiguet.png | luxury watch | `luxury watch detailed` |
| 品牌__Microsoft__Brand__Microsoft.png | Microsoft | `windows logo detailed` |
| 品牌__ThomBrowne__Brand__ThomBrowne.png | fashion brand | `fashion suit detailed` |
| 其它__加__Other__Plus.png | plus, add | `plus detailed filled` |
| 品牌__西贝__Brand__Xibei.png | restaurant | `chinese restaurant detailed` |
| 品牌__JimmyChoo__Brand__JimmyChoo.png | shoes, luxury | `high heels detailed` |

### 🟡 中等问题（前20个高优先级）

| 当前文件名 | 搜索关键词 |
|-----------|-----------|
| 数码__笔记本电脑__Digital__Laptop.png | `laptop computer detailed filled` |
| 物业__车位费__Property__ParkingSpaceFee.png | `parking lot detailed` |
| 校园__文件__Campus__File.png | `document file detailed` |
| 娱乐__盲盒__Entertainment__BlindBox.png | `mystery box gift detailed` |
| 日常__话费__Daily__PhoneBill.png | `phone bill payment detailed` |
| 收入__理财收入__Income__InvestmentIncome.png | `investment money detailed` |
| 其它__向右__Other__Right.png | `arrow right detailed` |
| 其它__向左__Other__Left.png | `arrow left detailed` |
| 物业__燃气费__Property__GasBill.png | `gas flame detailed` |
| 人情__发红包__Social__RedPacketGiving.png | `red envelope chinese detailed` |
| 护肤__化妆水__Beauty__Toner.png | `skincare bottle detailed` |
| 交通__公交牌__Transportation__BusStop.png | `bus stop sign detailed` |
| 医疗__医疗险__Medical__MedicalInsurance.png | `health insurance detailed` |
| 娱乐__演出__Entertainment__Performance.png | `theater stage detailed` |
| 数码__音响__Digital__Speaker.png | `speaker audio detailed` |
| 其它__瓶子__Other__Bottle.png | `bottle detailed` |
| 其它__向下__Other__Down.png | `arrow down detailed` |
| 其它__向上__Other__Up.png | `arrow up detailed` |
| 服饰__钱包__Clothing__Wallet.png | `wallet leather detailed` |
| 数码__电池__Digital__Battery.png | `battery power detailed` |

---

## 图标下载步骤

### 方法1: Flaticon（推荐）

1. 访问 https://www.flaticon.com
2. 搜索关键词，如 `laptop detailed filled`
3. 筛选条件：
   - Style: **Filled** 或 **Lineal color**
   - Color: **Multicolor** 或 **Gradient**
   - Size: 选择 **128px** 或 **256px**
4. 下载 PNG 格式
5. 重命名为原文件名

### 方法2: Icons8

1. 访问 https://icons8.com
2. 搜索图标名称
3. 选择风格：**3D Fluency** 或 **Color**
4. 下载 PNG 128px

### 方法3: Iconfinder

1. 访问 https://www.iconfinder.com
2. 搜索关键词
3. 筛选 **Free** + **Filled**
4. 下载 PNG

---

## 图标规格要求

| 属性 | 当前值 | 建议值 |
|------|-------|-------|
| 尺寸 | 90×90px | **128×128px** |
| 格式 | PNG | PNG (或 SVG) |
| 颜色模式 | RGBA | RGBA |
| 背景 | 透明 | 透明 |
| 风格 | 混杂 | **统一填充风格** |

---

## 批量处理脚本

处理下载的图标：

```bash
# 1. 创建临时目录
mkdir -p /tmp/new_icons

# 2. 将下载的图标放入 /tmp/new_icons

# 3. 批量调整尺寸（需要 ImageMagick）
cd /tmp/new_icons
for f in *.png; do
  convert "$f" -resize 128x128 -gravity center -background transparent -extent 128x128 "$f"
done

# 4. 复制到项目目录（注意重命名）
# cp /tmp/new_icons/laptop.png assets/category_icons/数码__笔记本电脑__Digital__Laptop.png
```

---

## 推荐的图标风格参考

### ✅ 好的图标示例（项目中已有）

- `餐饮__午餐__Catering__Lunch.png` - 有碗、筷子、勺子、热气
- `数码__电脑__Digital__Computer.png` - 有显示器、键盘、鼠标
- `交通__自行车__Transportation__Bicycle.png` - 完整的车架细节

### ❌ 需要替换的图标示例

- `数码__笔记本电脑__Digital__Laptop.png` - 只有轮廓线
- `服饰__钱包__Clothing__Wallet.png` - 细节不足
- `其它__加/减` - 过于简单

---

## 图标来源网站

| 网站 | 免费额度 | 风格 | 链接 |
|------|---------|------|------|
| Flaticon | 10个/天 | 多样 | https://flaticon.com |
| Icons8 | 100个/月 | 精美 | https://icons8.com |
| Iconfinder | 部分免费 | 专业 | https://iconfinder.com |
| SVGRepo | 完全免费 | 混合 | https://svgrepo.com |
| Noun Project | 免费(带署名) | 简洁 | https://thenounproject.com |

---

## 检测工具

运行检测脚本查看当前问题图标：

```bash
cd /Users/huazhou/Downloads/Github/Jive/app
python3 scripts/detect_simple_icons.py assets/category_icons

# 导出CSV便于追踪
python3 scripts/detect_simple_icons.py assets/category_icons --export
```
