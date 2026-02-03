#!/usr/bin/env python3
"""
图标细节检测脚本
检测 category_icons 目录中细节不足的图标

检测标准：
1. 文件大小 < 2KB（细节少）
2. 文件大小 < 3KB 且为非品牌图标（功能图标应更丰富）
3. 图像唯一颜色数 < 10（过于单调）

用法：
    python detect_simple_icons.py [目录路径]
    python detect_simple_icons.py --export csv  # 导出CSV
"""

import os
import sys
from pathlib import Path
from collections import defaultdict

# 可选：PIL 用于更精确的检测
try:
    from PIL import Image
    HAS_PIL = True
except ImportError:
    HAS_PIL = False
    print("提示: 安装 Pillow 可启用更精确的颜色检测 (pip install Pillow)")


def get_file_size(filepath):
    """获取文件大小（字节）"""
    return os.path.getsize(filepath)


def get_unique_colors(filepath):
    """获取图像唯一颜色数（需要PIL）"""
    if not HAS_PIL:
        return None
    try:
        img = Image.open(filepath)
        colors = img.getcolors(maxcolors=1000)
        return len(colors) if colors else 1000
    except:
        return None


def extract_category(filename):
    """从文件名提取分类"""
    parts = filename.split('__')
    return parts[0] if parts else 'unknown'


def is_brand_icon(filename):
    """判断是否为品牌图标"""
    return filename.startswith('品牌__') or '__Brand__' in filename


def analyze_icon(filepath):
    """分析单个图标"""
    filename = os.path.basename(filepath)
    size = get_file_size(filepath)
    colors = get_unique_colors(filepath) if HAS_PIL else None
    category = extract_category(filename)
    is_brand = is_brand_icon(filename)

    issues = []
    severity = 0  # 0=正常, 1=轻微, 2=中等, 3=严重

    # 检测规则
    if size < 500:
        issues.append("极小文件(<500B)，可能只有简单线条")
        severity = 3
    elif size < 1000:
        issues.append("文件很小(<1KB)，细节可能不足")
        severity = 3
    elif size < 2000:
        issues.append("文件较小(<2KB)，建议增加细节")
        severity = 2
    elif size < 3000 and not is_brand:
        issues.append("功能图标偏小(<3KB)，可考虑优化")
        severity = 1

    if colors is not None:
        if colors < 5:
            issues.append(f"颜色过少({colors}色)，图标过于单调")
            severity = max(severity, 2)
        elif colors < 10:
            issues.append(f"颜色较少({colors}色)")
            severity = max(severity, 1)

    return {
        'filename': filename,
        'filepath': filepath,
        'size': size,
        'colors': colors,
        'category': category,
        'is_brand': is_brand,
        'issues': issues,
        'severity': severity
    }


def scan_directory(directory):
    """扫描目录中的所有PNG图标"""
    results = []
    for filepath in Path(directory).glob('*.png'):
        result = analyze_icon(str(filepath))
        if result['severity'] > 0:
            results.append(result)

    # 按严重程度和文件大小排序
    results.sort(key=lambda x: (-x['severity'], x['size']))
    return results


def print_report(results):
    """打印检测报告"""
    if not results:
        print("✅ 未发现问题图标")
        return

    # 按严重程度分组
    by_severity = defaultdict(list)
    for r in results:
        by_severity[r['severity']].append(r)

    print("=" * 70)
    print("📊 图标细节检测报告")
    print("=" * 70)
    print(f"共发现 {len(results)} 个需要优化的图标\n")

    severity_names = {3: "🔴 严重", 2: "🟡 中等", 1: "🟢 轻微"}

    for sev in [3, 2, 1]:
        items = by_severity.get(sev, [])
        if not items:
            continue

        print(f"\n{severity_names[sev]} ({len(items)}个)")
        print("-" * 50)

        for item in items[:20]:  # 每级最多显示20个
            size_str = f"{item['size']:>5}B"
            color_str = f"{item['colors']:>3}色" if item['colors'] else "   -"
            cat = item['category'][:6].ljust(6)
            name = item['filename'][:40]
            print(f"  {size_str} | {color_str} | [{cat}] {name}")

        if len(items) > 20:
            print(f"  ... 还有 {len(items) - 20} 个")

    # 按分类统计
    print("\n" + "=" * 70)
    print("📁 按分类统计")
    print("-" * 50)

    by_category = defaultdict(int)
    for r in results:
        by_category[r['category']] += 1

    for cat, count in sorted(by_category.items(), key=lambda x: -x[1])[:10]:
        print(f"  {cat}: {count}个")


def export_csv(results, output_path):
    """导出为CSV"""
    import csv
    with open(output_path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(['文件名', '大小(B)', '颜色数', '分类', '是否品牌', '严重程度', '问题'])
        for r in results:
            writer.writerow([
                r['filename'],
                r['size'],
                r['colors'] or '',
                r['category'],
                '是' if r['is_brand'] else '否',
                r['severity'],
                '; '.join(r['issues'])
            ])
    print(f"已导出到: {output_path}")


def main():
    # 默认目录
    default_dir = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        'assets', 'category_icons'
    )

    # 解析参数
    export_mode = '--export' in sys.argv
    if export_mode:
        sys.argv.remove('--export')

    directory = sys.argv[1] if len(sys.argv) > 1 else default_dir

    if not os.path.isdir(directory):
        print(f"错误: 目录不存在 - {directory}")
        sys.exit(1)

    print(f"扫描目录: {directory}")
    results = scan_directory(directory)

    if export_mode:
        csv_path = os.path.join(directory, 'icon_issues.csv')
        export_csv(results, csv_path)
    else:
        print_report(results)

    # 返回问题数量作为退出码
    return len(results)


if __name__ == '__main__':
    sys.exit(main())
