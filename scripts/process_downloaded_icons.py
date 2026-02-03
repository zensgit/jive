#!/usr/bin/env python3
"""
图标批量下载和处理脚本

使用方法：
1. 手动从图标网站下载图标到 input_dir
2. 运行此脚本进行批量处理和重命名

依赖：pip install Pillow
"""

import os
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("请先安装 Pillow: pip install Pillow")
    sys.exit(1)

# 配置
INPUT_DIR = "/tmp/downloaded_icons"  # 下载的原始图标目录
OUTPUT_DIR = "/Users/huazhou/Downloads/Github/Jive/app/assets/category_icons"
TARGET_SIZE = 128  # 目标尺寸

# 图标映射表：下载的文件名 -> 项目中的文件名
ICON_MAPPING = {
    # === 第一批：严重问题图标 ===
    "minus.png": "其它__减__Other__Minus.png",
    "plus.png": "其它__加__Other__Plus.png",
    "delivery-truck.png": "品牌__DHL__Brand__DHL.png",
    "furniture.png": "品牌__宜家__Brand__Ikea.png",
    "game-controller.png": "品牌__暴雪__Brand__Blizzard.png",
    "sports-car.png": "品牌__法拉利__Brand__Ferrari.png",
    "ai-voice.png": "品牌__ElevenLabs__Brand__ElevenLabs.png",
    "luxury-watch.png": "品牌__爱彼__Brand__Audemarspiguet.png",
    "windows.png": "品牌__Microsoft__Brand__Microsoft.png",
    "suit.png": "品牌__ThomBrowne__Brand__ThomBrowne.png",
    "chinese-restaurant.png": "品牌__西贝__Brand__Xibei.png",
    "high-heels.png": "品牌__JimmyChoo__Brand__JimmyChoo.png",

    # === 第一批：中等问题图标 ===
    "laptop.png": "数码__笔记本电脑__Digital__Laptop.png",
    "parking.png": "物业__车位费__Property__ParkingSpaceFee.png",
    "document.png": "校园__文件__Campus__File.png",
    "mystery-box.png": "娱乐__盲盒__Entertainment__BlindBox.png",
    "phone-bill.png": "日常__话费__Daily__PhoneBill.png",
    "investment.png": "收入__理财收入__Income__InvestmentIncome.png",
    "gas.png": "物业__燃气费__Property__GasBill.png",
    "red-envelope.png": "人情__发红包__Social__RedPacketGiving.png",
    "skincare.png": "护肤__化妆水__Beauty__Toner.png",
    "bus-stop.png": "交通__公交牌__Transportation__BusStop.png",
    "health-insurance.png": "医疗__医疗险__Medical__MedicalInsurancePolicy.png",
    "theater.png": "娱乐__演出__Entertainment__Performance.png",
    "speaker.png": "数码__音响__Digital__Speaker.png",
    "bottle.png": "其它__瓶子__Other__Bottle.png",
    "wallet.png": "服饰__钱包__Clothing__Wallet.png",
    "battery.png": "数码__电池__Digital__Battery.png",

    # === 第二批：箭头 (3D风格) ===
    "arrow-up-3d.png": "其它__向上__Other__Up.png",
    "arrow-down-3d.png": "其它__向下__Other__Down.png",
    "arrow-left-3d.png": "其它__向左__Other__Left.png",
    "arrow-right-3d.png": "其它__向右__Other__Right.png",

    # === 第二批：品牌替代图标 ===
    "cloud-storage.png": "品牌__小米云__Brand__XiaomiCloud.png",
    "video-call.png": "品牌__Zoom__Brand__Zoom.png",
    "online-shop.png": "品牌__小米商城__Brand__XiaomiStore.png",
    "rocket.png": "品牌__SpaceX__Brand__SpaceX.png",
    "streaming.png": "品牌__Hulu__Brand__Hulu.png",
    "car-luxury.png": "品牌__雷克萨斯__Brand__Lexus.png",

    # === 第二批：运动/日常 ===
    "dumbbell.png": "运动__力量__Sports__Strength.png",
    "flashlight.png": "日常__手电筒__Daily__Flashlight.png",
    "appliances.png": "日常__电器__Daily__Appliances.png",

    # === 第二批：校园 ===
    "chart.png": "校园__图表__Campus__Chart.png",
    "magazine.png": "校园__杂志__Campus__Magazine.png",
    "ruler.png": "校园__测量__Campus__Measurement.png",
    "writing.png": "校园__写作__Campus__Writing.png",
    "ink.png": "校园__墨水__Campus__Ink.png",

    # === 第二批：其它 ===
    "fine-ticket.png": "其它__罚款__Other__Fine.png",
    "flag.png": "其它__旗帜__Other__Flag.png",
    "photocopy.png": "其它__复印__Other__Photocopy.png",

    # === 第二批：装修 ===
    "curtain.png": "装修__窗帘__Renovation__Curtain.png",
    "door.png": "装修__门窗__Renovation__DoorsAndWindows.png",

    # === 第二批：餐饮 ===
    "water-bottle.png": "餐饮__矿泉水__Catering__MineralWater.png",
    "smoking.png": "餐饮__抽烟__Catering__Smoking.png",

    # === 第二批：数码 ===
    "signal.png": "数码__LTE信号__Digital__LTESignal.png",
    "phone-accessories.png": "数码__手机配件__Digital__PhoneAccessories.png",
    "app.png": "数码__应用__Digital__App.png",
    "workstation.png": "数码__工作站电脑__Digital__Workstation.png",
    "usb.png": "数码__USB__Digital__Usb.png",

    # === 第二批：收入 ===
    "discount.png": "收入__优惠__Income__Discount.png",
    "lottery.png": "收入__中奖__Income__LotteryWinning.png",
    "scholarship.png": "收入__奖学金__Income__Scholarship.png",

    # === 第二批：娱乐 ===
    "ticket.png": "娱乐__买票__Entertainment__TicketPurchase.png",
    "music.png": "娱乐__音乐__Entertainment__Music.png",

    # === 第二批：护肤/母婴 ===
    "dressing-table.png": "护肤__梳妆台__Beauty__DressingTable.png",
    "early-education.png": "母婴育儿__早教__MaternalChild__EarlyEducation.png",

    # === 第二批：宠物/日常 ===
    "pet-food.png": "宠物__粮食__Pets__Grains.png",
    "toothpaste.png": "日常__牙膏__Daily__Toothpaste.png",

    # === 第二批：旅行 ===
    "temple.png": "旅行__宗教__Travel__Religion.png",
    "church.png": "旅行__教堂__Travel__Church.png",

    # === 第二批：汽车 ===
    "car-maintenance.png": "汽车__保养__Auto__Maintenance.png",

    # === 第三批：购物 ===
    "lipstick.png": "购物__口红__Shopping__Lipstick.png",
    "home-appliances.png": "购物__家电__Shopping__Appliances.png",

    # === 第三批：餐饮 ===
    "martini.png": "餐饮__马蒂尼鸡尾酒__Catering__Martini.png",

    # === 第三批：日常 ===
    "towel.png": "日常__毛巾__Daily__Towel.png",
    "printer-print.png": "日常__打印__Daily__Printing.png",
    "consumption.png": "日常__消费__Daily__Consumption.png",

    # === 第三批：品牌替代 ===
    "winter-jacket.png": "品牌__加拿大鹅__Brand__Canadagoose.png",
    "fashion-brand.png": "品牌__纪梵希__Brand__Givenchy.png",
    "luxury-brand.png": "品牌__BV__Brand__BottegaVeneta.png",
    "ai-chip.png": "品牌__MistralAI__Brand__Mistral.png",

    # === 第三批：交通 ===
    "travel.png": "交通__出行__Transportation__Travel.png",
    "jet.png": "交通__喷射__Transportation__Jet.png",
    "bus.png": "交通__公交车__Transportation__Bus.png",

    # === 第三批：医疗 ===
    "supplements.png": "医疗__保健品__Medical__Supplements.png",

    # === 第三批：其它 ===
    "location.png": "其它__地点__Other__Location.png",
    "poster.png": "其它__海报__Other__Poster.png",
    "crossroad.png": "其它__十字路口__Other__Crossroad.png",
    "foot.png": "其它__脚__Other__Foot.png",

    # === 第三批：服饰 ===
    "wristwatch.png": "服饰__腕表__Clothing__Wristwatch.png",
    "flat-shoes.png": "服饰__平底鞋__Clothing__FlatShoes.png",

    # === 第三批：饰品 ===
    "diamond.png": "饰品__钻石__Jewelry__Diamond.png",

    # === 第三批：数码 ===
    "desktop-pc.png": "数码__台式电脑__Digital__Desktop.png",

    # === 第三批：护肤 ===
    "facial-cleansing.png": "护肤__洁面__Beauty__FacialCleansing.png",
    "eyeliner.png": "护肤__眼线笔__Beauty__Eyeliner.png",

    # === 第三批：运动 ===
    "protein-powder.png": "运动__蛋白粉__Sports__ProteinPowder.png",
    "fitness-equipment.png": "运动__健身器材__Sports__FitnessEquipment.png",

    # === 第三批：宠物 ===
    "pet-id.png": "宠物__鉴别__Pets__Identification.png",

    # === 第三批：家庭 ===
    "bathroom.png": "家庭__卫浴__Family__Bathroom.png",

    # === 第三批：装修 ===
    "curtain-new.png": "装修__窗帘__Renovation__Curtain.png",

    # === 第四批：数码 ===
    "workstation-new.png": "数码__工作站电脑__Digital__Workstation.png",
    "desktop-new.png": "数码__台式电脑__Digital__Desktop.png",
    "tablet-new.png": "数码__平板__Digital__Tablet.png",

    # === 第四批：品牌替代 ===
    "database.png": "品牌__Oracle__Brand__Oracle.png",
    "fashion-miumiu.png": "品牌__MiuMiu__Brand__MiuMiu.png",
    "jaguar-car.png": "品牌__捷豹__Brand__Jaguar.png",
    "jewelry-brand.png": "品牌__梵克雅宝__Brand__Vca.png",

    # === 第四批：餐饮 ===
    "milk.png": "餐饮__牛奶__Catering__Milk.png",

    # === 第四批：医疗 ===
    "drugs.png": "医疗__药物__Medical__Drugs.png",

    # === 第四批：护肤 ===
    "lip-balm.png": "护肤__唇膏__Beauty__LipBalm.png",

    # === 第四批：装修 ===
    "appliances-reno.png": "装修__电器__Renovation__Appliances.png",

    # === 第四批：运动 ===
    "supplies.png": "运动__补给品__Sports__Supplies.png",

    # === 第四批：收入 ===
    "lucky-money.png": "收入__压岁钱__Income__LuckyMoney.png",

    # === 第五批：品牌类（轻微问题）===
    "bulgari-jewelry.png": "品牌__宝格丽__Brand__Bulgari.png",
    "puma-sports.png": "品牌__Puma__Brand__Puma.png",
    "miumiu-fashion.png": "品牌__Miu_Miu__Brand__MiuMiu.png",
    "sia-airline.png": "品牌__新加坡航空__Brand__Sia.png",
    "margiela-fashion.png": "品牌__MaisonMargiela__Brand__Margiela.png",
    "cathay-airline.png": "品牌__国泰航空__Brand__CathayPacific.png",
    "tiffany-jewelry.png": "品牌__蒂芙尼__Brand__Tiffany.png",
    "balenciaga-fashion.png": "品牌__巴黎世家__Brand__Balenciaga.png",
    "veromoda-fashion.png": "品牌__Vero_Moda__Brand__VeroModa.png",
    "esteelauder-cosmetic.png": "品牌__雅诗兰黛__Brand__EsteeLauder.png",
    "familymart-store.png": "品牌__全家__Brand__Familymart.png",
    "geely-car.png": "品牌__吉利__Brand__Geely.png",
    "mcqueen-fashion.png": "品牌__McQueen__Brand__McQueen.png",
    "weread-book.png": "品牌__微信读书__Brand__Weread.png",
    "chanel-perfume.png": "品牌__Chanel__Brand__Chanel.png",
    "netflix-streaming.png": "品牌__Netflix__Brand__Netflix.png",
    "volvo-car.png": "品牌__沃尔沃__Brand__Volvo.png",
    "lvmh-luxury.png": "品牌__LVMH__Brand__LVMH.png",
    "primark-retail.png": "品牌__Primark__Brand__Primark.png",

    # === 第五批：餐饮类 ===
    "smoke-cigarette.png": "餐饮__烟__Catering__Smoke.png",
    "coffee-cup.png": "餐饮__咖啡__Catering__Coffee.png",
    "drink-beverage.png": "餐饮__喝__Catering__Drink.png",
    "tea-drink.png": "餐饮__茶饮__Catering__TeaDrink.png",
    "ice-cream.png": "餐饮__雪糕__Catering__IceCream.png",
    "water-bottle.png": "餐饮__水__Catering__Water.png",
    "pure-water.png": "餐饮__纯净水__Catering__PureWater.png",
    "seasoning.png": "餐饮__调料__Catering__Seasoning.png",
    "bread.png": "餐饮__面包__Catering__Bread.png",
    "green-onion.png": "餐饮__葱__Catering__GreenOnion.png",
    "tulip.png": "餐饮__郁金香__Catering__Tulip.png",
    "popsicle.png": "餐饮__冰棍__Catering__Popsicle.png",

    # === 第五批：金融类 ===
    "euro.png": "金融__欧元__Finance__Euro.png",
    "pound.png": "金融__磅__Finance__Pound.png",

    # === 第五批：日常类 ===
    "lock.png": "日常__锁__Daily__Lock.png",
    "cleaning.png": "日常__清洁__Daily__Cleaning.png",
    "spoon.png": "日常__勺子__Daily__Spoon.png",
    "knife.png": "日常__刀__Daily__Knife.png",

    # === 第五批：汽车类 ===
    "car-loan.png": "汽车__车贷__Auto__CarLoan.png",
    "fuel.png": "汽车__燃油__Auto__Fuel.png",
    "parking.png": "汽车__停车__Auto__Parking.png",

    # === 第六批：更多品牌类 ===
    "lexus-car.png": "品牌__雷克萨斯__Brand__Lexus.png",
    "anta-sports.png": "品牌__安踏__Brand__Anta.png",
    "nike-swoosh.png": "品牌__Nike__Brand__Nike.png",
    "ea-game.png": "品牌__EA__Brand__EA.png",
    "delta-airline.png": "品牌__达美航空__Brand__Delta.png",
    "costa-coffee.png": "品牌__Costa__Brand__Costa.png",
    "prada-luxury.png": "品牌__Prada__Brand__Prada.png",
    "loreal-beauty.png": "品牌__欧莱雅__Brand__Loreal.png",
    "bbc-media.png": "品牌__BBC__Brand__BBC.png",
    "burberry-fashion.png": "品牌__Burberry__Brand__Burberry.png",
    "gucci-luxury.png": "品牌__Gucci__Brand__Gucci.png",
    "lawson-store.png": "品牌__罗森__Brand__Lawson.png",
    "weidian-shop.png": "品牌__微店__Brand__Weidian.png",
    "futu-stock.png": "品牌__富途证券__Brand__Futu.png",
    "sams-club.png": "品牌__山姆会员商店__Brand__SamsClub.png",
    "toyota-car.png": "品牌__丰田__Brand__Toyota.png",
    "binance-crypto.png": "品牌__币安__Brand__Binance.png",
    "shiseido-beauty.png": "品牌__资生堂__Brand__Shiseido.png",
    "daikin-ac.png": "品牌__大金__Brand__Daikin.png",
    "fog-fashion.png": "品牌__FearOfGod__Brand__FOG.png",
    "heineken-beer.png": "品牌__Heineken__Brand__Heineken.png",
    "jandj-pharma.png": "品牌__强生__Brand__JandJ.png",
    "icbc-bank.png": "品牌__工商银行__Brand__Icbc.png",
    "cms-stock.png": "品牌__招商证券__Brand__Cms.png",
    "qualcomm-chip.png": "品牌__高通__Brand__Qualcomm.png",
    "fila-sports.png": "品牌__Fila__Brand__Fila.png",
    "icloud-cloud.png": "品牌__iCloud__Brand__Icloud.png",
    "porsche-car.png": "品牌__保时捷__Brand__Porsche.png",
    "discord-chat.png": "品牌__Discord__Brand__Discord.png",

    # === 第六批：服饰类 ===
    "high-boots.png": "服饰__高筒靴__Clothing__HighBoots.png",
    "shorts.png": "服饰__短裤__Clothing__Shorts.png",
    "clothes-outfit.png": "服饰__服装__Clothing__Clothes.png",
    "hard-hat.png": "服饰__安全帽__Clothing__HardHat.png",
    "long-johns.png": "服饰__秋裤__Clothing__LongJohns.png",
    "stockings.png": "服饰__丝袜__Clothing__Stockings.png",
    "jk-uniform.png": "服饰__JK__Clothing__Jk.png",
    "pants.png": "服饰__裤子__Clothing__Pants.png",

    # === 第六批：娱乐类 ===
    "exhibition.png": "娱乐__展览__Entertainment__Exhibition.png",
    "bar-drink.png": "娱乐__酒吧__Entertainment__Bar.png",
    "mobile-game.png": "娱乐__手游__Entertainment__MobileGame.png",
    "fish-keeping.png": "娱乐__养鱼__Entertainment__FishKeeping.png",

    # === 第六批：收入类 ===
    "reimbursement.png": "收入__报销收入__Income__Reimbursement.png",
    "bonus.png": "收入__奖金__Income__Bonus.png",
    "secondhand.png": "收入__二手置换__Income__SecondHandTrade.png",
    "subsidy.png": "收入__补贴收入__Income__SubsidyIncome.png",
    "salary.png": "收入__工资__Income__Salary.png",
    "parttime.png": "收入__兼职收入__Income__PartTimeIncome.png",

    # === 第六批：装修类 ===
    "kitchen-reno.png": "装修__厨房__Renovation__Kitchen.png",
    "house-reno.png": "装修__屋__Renovation__House.png",
    "home-reno.png": "装修__家__Renovation__Home.png",
    "decoration.png": "装修__装饰物品__Renovation__Decoration.png",
    "furniture-reno.png": "装修__家具__Renovation__Furniture.png",
    "flooring.png": "装修__地板瓷砖__Renovation__Flooring.png",

    # === 第七批：校园类 ===
    "online-course.png": "校园__网课__Campus__OnlineCourse.png",
    "school.png": "校园__学校__Campus__School.png",
    "university.png": "校园__大学__Campus__University.png",
    "painting.png": "校园__绘画__Campus__Painting.png",
    "course.png": "校园__课程__Campus__Course.png",
    "paper.png": "校园__纸__Campus__Paper.png",
    "brush.png": "校园__毛笔__Campus__Brush.png",

    # === 第七批：护肤类 ===
    "eyeshadow.png": "护肤__眼影__Beauty__Eyeshadow.png",
    "beauty-products.png": "护肤__护肤品__Beauty__BeautyProducts.png",
    "beauty-device.png": "护肤__美容仪__Beauty__BeautyDevice.png",
    "eyebrow-pencil.png": "护肤__眉笔__Beauty__EyebrowPencil.png",
    "nail-polish.png": "护肤__指甲油__Beauty__NailPolish.png",
    "face-mask.png": "护肤__面膜__Beauty__FaceMask.png",
    "acne-needle.png": "护肤__粉刺针__Beauty__AcneNeedle.png",
    "shampoo.png": "护肤__洗发露__Beauty__Shampoo.png",
    "lips.png": "护肤__嘴唇__Beauty__Lips.png",

    # === 第七批：交通类 ===
    "maglev.png": "交通__磁悬浮__Transportation__Maglev.png",
    "van.png": "交通__面包车__Transportation__Van.png",
    "rocket.png": "交通__火箭__Transportation__Rocket.png",
    "traffic.png": "交通__交通__Transportation__Traffic.png",
    "subway.png": "交通__地铁__Transportation__Subway.png",
    "submarine.png": "交通__潜艇__Transportation__Submarine.png",
    "train.png": "交通__火车__Transportation__Train.png",

    # === 第七批：旅行类 ===
    "temple.png": "旅行__寺庙__Travel__Temple.png",
    "religion.png": "旅行__宗教__Travel__Religion.png",
    "map.png": "旅行__地图__Travel__Map.png",

    # === 第七批：数码类 ===
    "web-video.png": "数码__网络视频__Digital__WebVideo.png",
    "top-up.png": "数码__充值__Digital__TopUp.png",
    "watch.png": "数码__手表__Digital__Watch.png",
    "video.png": "数码__视频__Digital__Video.png",
    "keyboard.png": "数码__键盘__Digital__Keyboard.png",
    "phone-call.png": "数码__通话__Digital__PhoneCall.png",
    "touch-device.png": "数码__触摸设备__Digital__TouchDevice.png",
    "speaker-audio.png": "数码__音响__Digital__Speaker.png",
    "cloud-network.png": "数码__云网络__Digital__CloudNetwork.png",
    "apple-watch.png": "数码__Apple_Watch__Digital__AppleWatch.png",

    # === 第七批：医疗类 ===
    "mask.png": "医疗__口罩__Medical__Mask.png",
    "medicine.png": "医疗__买药__Medical__BuyingMedicine.png",
    "pill.png": "医疗__药丸__Medical__Pill.png",
    "hospital.png": "医疗__医院__Medical__Hospital.png",

    # === 第七批：其它类 ===
    "expense.png": "其它__支出__Other__Expense.png",
    "work.png": "其它__工作__Other__Work.png",
    "arrow-left.png": "其它__向左__Other__Left.png",
    "question.png": "其它__问题__Other__Question.png",
    "moon.png": "其它__月亮__Other__Moon.png",
    "arrow-down.png": "其它__向下__Other__Down.png",

    # === 第七批：家庭/母婴类 ===
    "home-insurance.png": "家庭__住家险__Family__HomeInsurance.png",
    "construction.png": "家庭__建造__Family__Construction.png",
    "crib.png": "母婴育儿__婴儿床__MaternalChild__Crib.png",
    "woman.png": "家庭__女人__Family__Woman.png",

    # === 第七批：购物/运动类 ===
    "shopping-clothes.png": "购物__服装__Shopping__Clothes.png",
    "travel-bag.png": "购物__旅行包__Shopping__TravelBag.png",
    "equipment.png": "运动__器材__Sports__Equipment.png",

    # === 第七批：公司/兴趣类 ===
    "server.png": "公司__服务器__Business__Server.png",
    "folder.png": "公司__文件夹__Business__Folder.png",
    "briefcase.png": "公司__公文包__Business__Briefcase.png",
    "music-hobby.png": "兴趣__音乐__Hobbies__Music.png",
    "harmonica.png": "兴趣__口琴__Hobbies__Harmonica.png",

    # === 第七批：物业/园艺/汽车 ===
    "living-home.png": "物业__居家__Property__LivingAtHome.png",
    "greenery.png": "园艺__绿植__Gardening__Greenery.png",
    "accessories.png": "汽车__配件__Auto__Accessories.png",

    # === 第八批：剩余问题图标 ===
    "arrow-left-3d.png": "其它__向左__Other__Left.png",
    "mobile-game-3d.png": "娱乐__手游__Entertainment__MobileGame.png",
    "arrow-down-3d.png": "其它__向下__Other__Down.png",
    "hospital-3d.png": "医疗__医院__Medical__Hospital.png",
    "toyota-car-3d.png": "品牌__丰田__Brand__Toyota.png",
    "bbc-news.png": "品牌__BBC__Brand__BBC.png",
    "submarine-3d.png": "交通__潜艇__Transportation__Submarine.png",
    "briefcase-3d.png": "公司__公文包__Business__Briefcase.png",
    "phone-call-3d.png": "数码__通话__Digital__PhoneCall.png",
    "moon-3d.png": "其它__月亮__Other__Moon.png",
    "question-3d.png": "其它__问题__Other__Question.png",
    "traffic-3d.png": "交通__交通__Transportation__Traffic.png",
    "long-johns-3d.png": "服饰__秋裤__Clothing__LongJohns.png",
    "cloud-network-3d.png": "数码__云网络__Digital__CloudNetwork.png",
    "lock-3d.png": "日常__锁__Daily__Lock.png",
    "rocket-3d.png": "交通__火箭__Transportation__Rocket.png",
    "stockings-3d.png": "服饰__丝袜__Clothing__Stockings.png",
    "school-3d.png": "校园__学校__Campus__School.png",
    "work-3d.png": "其它__工作__Other__Work.png",

    # === 第九批：最终修复 ===
    "down-arrow-final.png": "其它__向下__Other__Down.png",
    "left-arrow-final.png": "其它__向左__Other__Left.png",
    "briefcase-final.png": "公司__公文包__Business__Briefcase.png",
    "cloud-final.png": "数码__云网络__Digital__CloudNetwork.png",
    "call-final.png": "数码__通话__Digital__PhoneCall.png",
    "traffic-final.png": "交通__交通__Transportation__Traffic.png",
    "work-final.png": "其它__工作__Other__Work.png",

    # === 第十批：最后4个 ===
    "arrow-left-rich.png": "其它__向左__Other__Left.png",
    "arrow-down-rich.png": "其它__向下__Other__Down.png",
    "phone-call-rich.png": "数码__通话__Digital__PhoneCall.png",
    "cloud-rich.png": "数码__云网络__Digital__CloudNetwork.png",
}


def process_icon(input_path, output_path, size=TARGET_SIZE):
    """处理单个图标：调整尺寸、确保透明背景"""
    try:
        img = Image.open(input_path)

        # 转换为RGBA（确保透明通道）
        if img.mode != 'RGBA':
            img = img.convert('RGBA')

        # 计算缩放比例，保持宽高比
        ratio = min(size / img.width, size / img.height)
        new_size = (int(img.width * ratio), int(img.height * ratio))
        img = img.resize(new_size, Image.Resampling.LANCZOS)

        # 创建透明画布并居中放置
        canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        offset = ((size - new_size[0]) // 2, (size - new_size[1]) // 2)
        canvas.paste(img, offset, img)

        # 保存
        canvas.save(output_path, 'PNG', optimize=True)
        return True
    except Exception as e:
        print(f"  错误: {e}")
        return False


def main():
    if not os.path.exists(INPUT_DIR):
        os.makedirs(INPUT_DIR)
        print(f"已创建输入目录: {INPUT_DIR}")
        print(f"请将下载的图标放入此目录，文件名参考 ICON_MAPPING")
        print("\n需要的文件名:")
        for src in sorted(ICON_MAPPING.keys()):
            print(f"  - {src}")
        return

    processed = 0
    skipped = 0
    errors = 0

    print(f"输入目录: {INPUT_DIR}")
    print(f"输出目录: {OUTPUT_DIR}")
    print(f"目标尺寸: {TARGET_SIZE}x{TARGET_SIZE}")
    print("-" * 50)

    for src_name, dst_name in ICON_MAPPING.items():
        src_path = os.path.join(INPUT_DIR, src_name)
        dst_path = os.path.join(OUTPUT_DIR, dst_name)

        if not os.path.exists(src_path):
            # 尝试其他扩展名
            for ext in ['.svg', '.jpg', '.jpeg', '.webp']:
                alt_path = src_path.rsplit('.', 1)[0] + ext
                if os.path.exists(alt_path):
                    src_path = alt_path
                    break
            else:
                skipped += 1
                continue

        print(f"处理: {src_name} -> {dst_name}")
        if process_icon(src_path, dst_path):
            processed += 1
        else:
            errors += 1

    print("-" * 50)
    print(f"完成! 处理: {processed}, 跳过: {skipped}, 错误: {errors}")


if __name__ == '__main__':
    main()
