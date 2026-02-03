#!/usr/bin/env python3
"""
从 Simple Icons 下载品牌Logo（彩色PNG版本）

使用 cdn.simpleicons.org 获取彩色版本的图标
URL格式: https://cdn.simpleicons.org/{slug}/{color}
"""

import os
import sys
import urllib.request
import urllib.error
from pathlib import Path

try:
    from PIL import Image
    import io
except ImportError:
    print("请先安装 Pillow: pip install Pillow")
    sys.exit(1)

# 配置
OUTPUT_DIR = "/Users/huazhou/Downloads/Github/Jive/app/assets/category_icons"
TEMP_DIR = "/tmp/simple_icons"
TARGET_SIZE = 128

# Simple Icons slug 到项目文件名的映射
ICON_MAPPING = {
    # === 科技公司 ===
    "amd": "品牌__AMD__Brand__AMD.png",
    "adobe": "品牌__Adobe__Brand__Adobe.png",
    "apple": "品牌__Apple__Brand__Apple.png",
    "amazon": "品牌__Amazon__Brand__Amazon.png",
    "airbnb": "品牌__Airbnb__Brand__Airbnb.png",
    "alibaba": "品牌__阿里巴巴__Brand__Alibaba.png",
    "alipay": "品牌__支付宝__Brand__Alipay.png",

    # === 社交媒体 ===
    "facebook": "品牌__Facebook__Brand__Facebook.png",
    "instagram": "品牌__Instagram__Brand__Instagram.png",
    "x": "品牌__Twitter__Brand__Twitter.png",
    "tiktok": "品牌__TikTok__Brand__TikTok.png",
    "linkedin": "品牌__LinkedIn__Brand__LinkedIn.png",
    "reddit": "品牌__Reddit__Brand__Reddit.png",
    "snapchat": "品牌__Snapchat__Brand__Snapchat.png",
    "telegram": "品牌__Telegram__Brand__Telegram.png",
    "whatsapp": "品牌__WhatsApp__Brand__WhatsApp.png",
    "discord": "品牌__Discord__Brand__Discord.png",
    "slack": "品牌__Slack__Brand__Slack.png",
    "wechat": "品牌__微信__Brand__Wechat.png",
    "sinaweibo": "品牌__微博__Brand__Weibo.png",
    "pinterest": "品牌__Pinterest__Brand__Pinterest.png",
    "twitch": "品牌__Twitch__Brand__Twitch.png",

    # === 流媒体 ===
    "netflix": "品牌__Netflix__Brand__Netflix.png",
    "spotify": "品牌__Spotify__Brand__Spotify.png",
    "youtube": "品牌__YouTube__Brand__Youtube.png",
    "hulu": "品牌__Hulu__Brand__Hulu.png",
    "disneyplus": "品牌__Disney+__Brand__DisneyPlus.png",
    "bilibili": "品牌__BiliBili__Brand__Bilibili.png",

    # === 开发工具 ===
    "github": "品牌__GitHub__Brand__GitHub.png",
    "gitlab": "品牌__GitLab__Brand__GitLab.png",
    "figma": "品牌__Figma__Brand__Figma.png",
    "notion": "品牌__Notion__Brand__Notion.png",
    "canva": "品牌__Canva__Brand__Canva.png",
    "dribbble": "品牌__Dribbble__Brand__Dribbble.png",
    "behance": "品牌__Behance__Brand__Behance.png",
    "arc": "品牌__Arc__Brand__Arc.png",

    # === AI 公司 ===
    "openai": "品牌__OpenAI__Brand__OpenAI.png",
    "anthropic": "品牌__Claude__Brand__Claude.png",

    # === 游戏 ===
    "steam": "品牌__Steam__Brand__Steam.png",
    "playstation": "品牌__PlayStation__Brand__Playstation.png",
    "xbox": "品牌__Xbox__Brand__Xbox.png",
    "nintendoswitch": "品牌__Switch__Brand__Switch.png",
    "nintendo": "品牌__任天堂__Brand__Nintendo.png",
    "epicgames": "品牌__EpicGames__Brand__Epicgames.png",
    "ubisoft": "品牌__育碧__Brand__Ubisoft.png",
    "ea": "品牌__EA__Brand__EA.png",
    "rockstargames": "品牌__R星__Brand__Rockstar.png",
    "battlenet": "品牌__暴雪__Brand__Blizzard.png",

    # === 云服务 ===
    "googledrive": "品牌__GoogleDrive__Brand__Googledrive.png",
    "dropbox": "品牌__Dropbox__Brand__Dropbox.png",
    "icloud": "品牌__iCloud__Brand__Icloud.png",

    # === 支付 ===
    "paypal": "品牌__PayPal__Brand__PayPal.png",
    "visa": "品牌__Visa__Brand__Visa.png",
    "mastercard": "品牌__Mastercard__Brand__Mastercard.png",
    "stripe": "品牌__Stripe__Brand__Stripe.png",
    "americanexpress": "品牌__运通__Brand__Amex.png",

    # === 汽车 ===
    "tesla": "品牌__特斯拉__Brand__Tesla.png",
    "bmw": "品牌__宝马__Brand__Bmw.png",
    "mercedesbenz": "品牌__奔驰__Brand__Mercedesbenz.png",
    "audi": "品牌__奥迪__Brand__Audi.png",
    "porsche": "品牌__保时捷__Brand__Porsche.png",
    "ferrari": "品牌__法拉利__Brand__Ferrari.png",
    "lamborghini": "品牌__兰博基尼__Brand__Lamborghini.png",
    "bentley": "品牌__宾利__Brand__Bentley.png",
    "rollsroyce": "品牌__劳斯莱斯__Brand__RollsRoyce.png",
    "astonmartin": "品牌__阿斯顿马丁__Brand__AstonMartin.png",
    "maserati": "品牌__玛莎拉蒂__Brand__Maserati.png",
    "toyota": "品牌__丰田__Brand__Toyota.png",
    "honda": "品牌__本田__Brand__Honda.png",
    "ford": "品牌__福特__Brand__Ford.png",
    "volkswagen": "品牌__大众__Brand__Volkswagen.png",
    "volvo": "品牌__沃尔沃__Brand__Volvo.png",
    "jaguar": "品牌__捷豹__Brand__Jaguar.png",
    "landrover": "品牌__路虎__Brand__LandRover.png",
    "lexus": "品牌__雷克萨斯__Brand__Lexus.png",
    "byd": "品牌__比亚迪__Brand__Byd.png",
    "nio": "品牌__蔚来__Brand__Nio.png",

    # === 运动品牌 ===
    "nike": "品牌__Nike__Brand__Nike.png",
    "adidas": "品牌__Adidas__Brand__Adidas.png",
    "puma": "品牌__Puma__Brand__Puma.png",
    "underarmour": "品牌__安德玛__Brand__UnderArmour.png",
    "newbalance": "品牌__NewBalance__Brand__Newbalance.png",
    "asics": "品牌__ASICS__Brand__ASICS.png",
    "reebok": "品牌__锐步__Brand__Reebok.png",

    # === 快餐 ===
    "mcdonalds": "品牌__麦当劳__Brand__McDonalds.png",
    "starbucks": "品牌__星巴克__Brand__Starbucks.png",
    "burgerking": "品牌__汉堡王__Brand__Burgerking.png",
    "kfc": "品牌__肯德基__Brand__KFC.png",
    "dominos": "品牌__达美乐__Brand__Dominos.png",
    "dunkindonuts": "品牌__Dunkin__Brand__Dunkin.png",
    "tacobell": "品牌__塔可钟__Brand__Tacobell.png",

    # === 饮料 ===
    "cocacola": "品牌__可口可乐__Brand__CocaCola.png",
    "pepsi": "品牌__百事__Brand__Pepsi.png",
    "redbull": "品牌__红牛__Brand__RedBull.png",
    "heineken": "品牌__Heineken__Brand__Heineken.png",

    # === 物流 ===
    "dhl": "品牌__DHL__Brand__DHL.png",
    "fedex": "品牌__FedEx__Brand__FedEx.png",
    "ups": "品牌__UPS__Brand__UPS.png",

    # === 硬件 ===
    "intel": "品牌__英特尔__Brand__Intel.png",
    "nvidia": "品牌__英伟达__Brand__NVIDIA.png",
    "qualcomm": "品牌__高通__Brand__Qualcomm.png",
    "samsung": "品牌__三星__Brand__Samsung.png",
    "huawei": "品牌__华为__Brand__Huawei.png",
    "xiaomi": "品牌__小米__Brand__Xiaomi.png",
    "sony": "品牌__索尼__Brand__Sony.png",
    "canon": "品牌__佳能__Brand__Canon.png",
    "dell": "品牌__Dell__Brand__Dell.png",
    "hp": "品牌__HP__Brand__HP.png",
    "logitech": "品牌__罗技__Brand__Logitech.png",
    "razer": "品牌__雷蛇__Brand__Razer.png",
    "dyson": "品牌__Dyson__Brand__Dyson.png",
    "philips": "品牌__飞利浦__Brand__Philips.png",
    "panasonic": "品牌__松下__Brand__Panasonic.png",
    "dji": "品牌__大疆__Brand__DJI.png",

    # === 企业软件 ===
    "microsoft": "品牌__Microsoft__Brand__Microsoft.png",
    "google": "品牌__Google__Brand__Google.png",
    "oracle": "品牌__Oracle__Brand__Oracle.png",
    "salesforce": "品牌__Salesforce__Brand__Salesforce.png",
    "sap": "品牌__SAP__Brand__SAP.png",
    "cisco": "品牌__Cisco__Brand__Cisco.png",
    "zoom": "品牌__Zoom__Brand__Zoom.png",

    # === 加密货币 ===
    "bitcoin": "品牌__比特币__Brand__Bitcoin.png",
    "ethereum": "品牌__以太坊__Brand__Ethereum.png",
    "binance": "品牌__币安__Brand__Binance.png",

    # === 银行 ===
    "hsbc": "品牌__HSBC__Brand__HSBC.png",

    # === 媒体 ===
    "bbc": "品牌__BBC__Brand__BBC.png",
    "bloomberg": "品牌__Bloomberg__Brand__Bloomberg.png",

    # === 航空 ===
    "emirates": "品牌__阿联酋航空__Brand__Emirates.png",

    # === 酒店 ===
    "marriott": "品牌__万豪__Brand__Marriott.png",
    "hilton": "品牌__Hilton__Brand__Hilton.png",

    # === 零售 ===
    "walmart": "品牌__沃尔玛__Brand__Walmart.png",
    "costco": "品牌__Costco__Brand__Costco.png",
    "ikea": "品牌__宜家__Brand__Ikea.png",
    "zara": "品牌__ZARA__Brand__Zara.png",
    "hm": "品牌__HM__Brand__Hm.png",
    "lego": "品牌__Lego__Brand__Lego.png",

    # === 奢侈品 ===
    "louisvuitton": "品牌__LV__Brand__LouisVuitton.png",
    "gucci": "品牌__Gucci__Brand__Gucci.png",
    "chanel": "品牌__Chanel__Brand__Chanel.png",
    "dior": "品牌__迪奥__Brand__Dior.png",
    "burberry": "品牌__Burberry__Brand__Burberry.png",
    "givenchy": "品牌__纪梵希__Brand__Givenchy.png",

    # === 健身 ===
    "strava": "品牌__Strava__Brand__Strava.png",

    # === 出行 ===
    "uber": "品牌__Uber__Brand__Uber.png",

    # === 中国互联网 ===
    "tencent": "品牌__腾讯__Brand__Tencent.png",
    "bytedance": "品牌__字节跳动__Brand__Bytedance.png",
    "baidu": "品牌__百度__Brand__Baidu.png",
    "jd": "品牌__京东__Brand__JD.png",
    "meituan": "品牌__美团__Brand__Meituan.png",

    # === 其他 ===
    "waltdisneystudio": "品牌__迪士尼__Brand__Disney.png",
    "marvel": "品牌__Marvel__Brand__Marvel.png",
    "hbo": "品牌__HBO__Brand__Hbo.png",
    "spacex": "品牌__SpaceX__Brand__SpaceX.png",
    "shell": "品牌__壳牌__Brand__Shell.png",
}

# 品牌颜色
BRAND_COLORS = {
    "amd": "ED1C24",
    "adobe": "FF0000",
    "apple": "000000",
    "amazon": "FF9900",
    "airbnb": "FF5A5F",
    "alibaba": "FF6A00",
    "alipay": "00A1E9",
    "facebook": "0866FF",
    "instagram": "E4405F",
    "x": "000000",
    "tiktok": "000000",
    "linkedin": "0A66C2",
    "reddit": "FF4500",
    "snapchat": "FFFC00",
    "telegram": "26A5E4",
    "whatsapp": "25D366",
    "discord": "5865F2",
    "slack": "4A154B",
    "wechat": "07C160",
    "sinaweibo": "E6162D",
    "pinterest": "BD081C",
    "twitch": "9146FF",
    "netflix": "E50914",
    "spotify": "1DB954",
    "youtube": "FF0000",
    "hulu": "1CE783",
    "disneyplus": "113CCF",
    "bilibili": "00A1D6",
    "github": "181717",
    "gitlab": "FC6D26",
    "figma": "F24E1E",
    "notion": "000000",
    "canva": "00C4CC",
    "dribbble": "EA4C89",
    "behance": "1769FF",
    "arc": "FCBFBD",
    "openai": "412991",
    "anthropic": "191919",
    "steam": "000000",
    "playstation": "003791",
    "xbox": "107C10",
    "nintendoswitch": "E60012",
    "nintendo": "E60012",
    "epicgames": "313131",
    "ubisoft": "000000",
    "ea": "000000",
    "rockstargames": "FCAF17",
    "battlenet": "00AEFF",
    "googledrive": "4285F4",
    "dropbox": "0061FF",
    "icloud": "3693F3",
    "paypal": "003087",
    "visa": "1A1F71",
    "mastercard": "EB001B",
    "stripe": "635BFF",
    "americanexpress": "006FCF",
    "tesla": "CC0000",
    "bmw": "0066B1",
    "mercedesbenz": "242424",
    "audi": "BB0A30",
    "porsche": "B12B28",
    "ferrari": "D40000",
    "lamborghini": "DDB321",
    "bentley": "333333",
    "rollsroyce": "662A5E",
    "astonmartin": "006847",
    "maserati": "0C2340",
    "toyota": "EB0A1E",
    "honda": "E40521",
    "ford": "003478",
    "volkswagen": "151F5D",
    "volvo": "003057",
    "jaguar": "000000",
    "landrover": "005A2B",
    "lexus": "000000",
    "byd": "FF0000",
    "nio": "0066FF",
    "nike": "111111",
    "adidas": "000000",
    "puma": "000000",
    "underarmour": "1D1D1D",
    "newbalance": "D61A23",
    "asics": "E31837",
    "reebok": "000000",
    "mcdonalds": "FFC72C",
    "starbucks": "006241",
    "burgerking": "D62300",
    "kfc": "F40027",
    "dominos": "006491",
    "dunkindonuts": "FF671F",
    "tacobell": "702082",
    "cocacola": "F40009",
    "pepsi": "004B93",
    "redbull": "DB0A40",
    "heineken": "00843D",
    "dhl": "FFCC00",
    "fedex": "4D148C",
    "ups": "351C15",
    "intel": "0071C5",
    "nvidia": "76B900",
    "qualcomm": "3253DC",
    "samsung": "1428A0",
    "huawei": "FF0000",
    "xiaomi": "FF6900",
    "sony": "000000",
    "canon": "BC0024",
    "dell": "007DB8",
    "hp": "0096D6",
    "logitech": "00B8FC",
    "razer": "00FF00",
    "dyson": "9E1F63",
    "philips": "0B5ED7",
    "panasonic": "0F58A8",
    "dji": "000000",
    "microsoft": "5E5E5E",
    "google": "4285F4",
    "oracle": "F80000",
    "salesforce": "00A1E0",
    "sap": "0FAAFF",
    "cisco": "1BA0D7",
    "zoom": "0B5CFF",
    "bitcoin": "F7931A",
    "ethereum": "3C3C3D",
    "binance": "F0B90B",
    "hsbc": "DB0011",
    "bbc": "000000",
    "bloomberg": "2800D7",
    "emirates": "D71A21",
    "marriott": "8D0034",
    "hilton": "104C97",
    "walmart": "0071CE",
    "costco": "E31837",
    "ikea": "0051BA",
    "zara": "000000",
    "hm": "E50010",
    "lego": "D01012",
    "louisvuitton": "000000",
    "gucci": "000000",
    "chanel": "000000",
    "dior": "000000",
    "burberry": "D4A853",
    "givenchy": "000000",
    "strava": "FC4C02",
    "uber": "000000",
    "tencent": "00A3FF",
    "bytedance": "000000",
    "baidu": "2932E1",
    "jd": "E2001A",
    "meituan": "FFD300",
    "waltdisneystudio": "113CCF",
    "marvel": "EC1D24",
    "hbo": "000000",
    "spacex": "000000",
    "shell": "FFD500",
}


def download_icon(slug, color):
    """从 Simple Icons CDN 下载彩色图标"""
    # CDN URL 格式: https://cdn.simpleicons.org/{slug}/{color}
    url = f"https://cdn.simpleicons.org/{slug}/{color}"
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=15) as response:
            return response.read()
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return None
        print(f"  HTTP错误 {slug}: {e.code}")
        return None
    except Exception as e:
        print(f"  下载失败 {slug}: {e}")
        return None


def svg_to_png_pillow(svg_data, output_path, size=128):
    """使用 Pillow 将 SVG 渲染为 PNG（通过临时保存）"""
    try:
        # Simple Icons CDN 返回的是 SVG，我们需要另一种方式
        # 尝试使用 svglib 或直接下载 PNG
        return False
    except Exception as e:
        print(f"  转换失败: {e}")
        return False


def download_png_directly(slug, output_path, size=128):
    """直接从 jsdelivr 下载 SVG 并创建简化的 PNG"""
    # 使用 jsdelivr CDN 获取 SVG
    svg_url = f"https://cdn.jsdelivr.net/npm/simple-icons@latest/icons/{slug}.svg"
    try:
        req = urllib.request.Request(svg_url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=15) as response:
            svg_content = response.read().decode('utf-8')

        # 获取颜色
        color = BRAND_COLORS.get(slug, "000000")

        # 创建带颜色的 SVG
        colored_svg = svg_content.replace('<svg', f'<svg fill="#{color}"')

        # 保存临时 SVG
        temp_svg = os.path.join(TEMP_DIR, f"{slug}.svg")
        with open(temp_svg, 'w', encoding='utf-8') as f:
            f.write(colored_svg)

        # 使用系统命令转换（如果有 rsvg-convert 或 inkscape）
        import subprocess

        # 尝试 rsvg-convert
        try:
            subprocess.run([
                'rsvg-convert',
                '-w', str(size),
                '-h', str(size),
                '-o', output_path,
                temp_svg
            ], check=True, capture_output=True)
            return True
        except (subprocess.CalledProcessError, FileNotFoundError):
            pass

        # 尝试 inkscape
        try:
            subprocess.run([
                'inkscape',
                '--export-type=png',
                f'--export-filename={output_path}',
                f'--export-width={size}',
                f'--export-height={size}',
                temp_svg
            ], check=True, capture_output=True)
            return True
        except (subprocess.CalledProcessError, FileNotFoundError):
            pass

        # 如果都没有，尝试安装 homebrew 的 librsvg
        print(f"  需要 rsvg-convert 或 inkscape 来转换 SVG")
        return False

    except Exception as e:
        print(f"  下载/转换失败 {slug}: {e}")
        return False


def main():
    # 创建临时目录
    os.makedirs(TEMP_DIR, exist_ok=True)

    # 先检查是否有 rsvg-convert
    import subprocess
    has_rsvg = False
    try:
        subprocess.run(['rsvg-convert', '--version'], capture_output=True)
        has_rsvg = True
    except FileNotFoundError:
        print("未找到 rsvg-convert，尝试安装...")
        try:
            subprocess.run(['brew', 'install', 'librsvg'], check=True)
            has_rsvg = True
        except:
            print("请手动安装: brew install librsvg")

    if not has_rsvg:
        print("无法转换 SVG，退出")
        return

    processed = 0
    skipped = 0
    errors = 0

    print(f"开始下载 Simple Icons ({len(ICON_MAPPING)} 个)")
    print(f"输出目录: {OUTPUT_DIR}")
    print("-" * 50)

    for slug, filename in ICON_MAPPING.items():
        output_path = os.path.join(OUTPUT_DIR, filename)

        print(f"处理: {slug} -> {filename}")
        if download_png_directly(slug, output_path, TARGET_SIZE):
            processed += 1
        else:
            errors += 1

    print("-" * 50)
    print(f"完成! 处理: {processed}, 跳过: {skipped}, 错误: {errors}")


if __name__ == '__main__':
    main()
