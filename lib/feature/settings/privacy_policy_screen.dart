import 'package:flutter/material.dart';

/// 隐私政策页面
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('隐私政策', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jive 积叶 隐私政策', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('最后更新: 2026年4月5日', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 20),

            _Section(title: '1. 信息收集', content:
              '我们收集以下信息以提供服务：\n'
              '• 账户信息：邮箱地址（用于登录和数据同步）\n'
              '• 财务数据：您手动输入的交易记录、账户、预算等数据\n'
              '• 设备信息：设备型号、操作系统版本（用于故障排查）\n\n'
              '我们不会收集您的通讯录、短信、通话记录或精确位置信息。'
            ),

            _Section(title: '2. 数据存储', content:
              '• 本地优先：所有财务数据首先存储在您的设备本地\n'
              '• 云同步（可选）：如果您启用云同步，数据会加密传输至我们的服务器（Supabase）\n'
              '• 游客模式：您可以在不注册的情况下使用所有本地功能，数据仅存在于您的设备'
            ),

            _Section(title: '3. 数据使用', content:
              '我们使用您的数据仅用于：\n'
              '• 提供记账、统计、预算等核心功能\n'
              '• 跨设备数据同步（需您主动开启）\n'
              '• 改善应用性能和用户体验\n\n'
              '我们不会将您的个人财务数据出售给第三方。'
            ),

            _Section(title: '4. 第三方服务', content:
              '我们使用以下第三方服务：\n'
              '• Google AdMob：为免费用户展示广告\n'
              '• Google Play 计费：处理应用内购买\n'
              '• Supabase：提供用户认证和云存储\n\n'
              '这些服务有各自的隐私政策，建议您查阅。'
            ),

            _Section(title: '5. 数据安全', content:
              '• 所有网络传输使用 HTTPS 加密\n'
              '• 支持 PIN 码和手势图案锁保护应用\n'
              '• 支持加密备份导出\n'
              '• 我们定期审查安全措施'
            ),

            _Section(title: '6. 您的权利', content:
              '您有权：\n'
              '• 随时导出您的所有数据（CSV/Excel/加密备份）\n'
              '• 删除您的账户和所有关联数据\n'
              '• 关闭云同步，仅使用本地模式\n'
              '• 退出登录并以游客模式使用'
            ),

            _Section(title: '7. 儿童隐私', content:
              '本应用不面向13岁以下儿童。我们不会故意收集儿童的个人信息。'
            ),

            _Section(title: '8. 政策变更', content:
              '我们可能会不时更新本隐私政策。变更将在应用内通知。继续使用本应用即表示接受更新后的政策。'
            ),

            _Section(title: '9. 联系我们', content:
              '如果您对本隐私政策有任何疑问，请联系：\n'
              'Email: privacy@jivemoney.app\n'
              '应用内：设置 → 反馈'
            ),

            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;

  const _Section({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF333333))),
        ],
      ),
    );
  }
}
