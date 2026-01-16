package com.jive.app

import android.app.Notification
import android.content.Intent
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import java.util.regex.Pattern
import kotlin.math.abs

class JiveNotificationService : NotificationListenerService() {

    private val logTag = "JiveNotify"

    private val supportedApps = mapOf(
        "com.eg.android.AlipayGphone" to "Alipay",
        "com.tencent.mm" to "WeChat",
        "com.unionpay" to "UnionPay",
        "com.jd.jrapp" to "京东金融",
        "com.jingdong.app.mall" to "京东商城",
        "com.xunmeng.pinduoduo" to "拼多多",
        "com.sankuai.meituan" to "美团",
        "com.dianping.v1" to "大众点评",
        "com.sankuai.meituan.takeoutnew" to "美团外卖",
        "com.ss.android.ugc.aweme" to "抖音",
        "com.ss.android.ugc.livelite" to "抖音商城",
        "com.ss.android.ugc.aweme.lite" to "抖音极速版",
        "com.ss.android.yumme.video" to "抖音精选",
        "com.taobao.taobao" to "淘宝",
        "com.alibaba.wireless" to "阿里巴巴",
        "com.taobao.idlefish" to "闲鱼",
        "com.wudaokou.hippo" to "盒马",
        "me.ele" to "饿了么",
        "com.huawei.wallet" to "华为钱包",
        "com.ccb.longjiLife" to "建行生活",
        "com.smile.gifmaker" to "快手",
        "com.kuaishou.nebula" to "快手极速版"
    )

    private val incomeKeywords = listOf(
        "已收款",
        "已收到",
        "资金待入账",
        "退款",
        "赔付",
        "到账"
    )

    private val transferKeywords = listOf(
        "转账",
        "转入",
        "转出",
        "提现",
        "还款",
        "余额转入",
        "余额转出"
    )

    private val notificationKeywords = listOf(
        "支付成功",
        "交易成功",
        "付款成功",
        "支付",
        "付款",
        "收款",
        "到账",
        "转账",
        "退款",
        "红包",
        "实付",
        "代付"
    )

    private val currencyPattern = Pattern.compile("(?:¥|￥|元)\\s*([-+]?\\d+(?:\\.\\d{1,2})?)")
    private val labelPattern = Pattern.compile("(?:金额|实付|支付|付款|转账|收款|退款|入账)[:：]?\\s*([-+]?\\d+(?:\\.\\d{1,2})?)")

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val packageName = sbn.packageName ?: return
        val displayName = supportedApps[packageName] ?: return
        val notification = sbn.notification
        val extras = notification.extras

        val title = extras.getString(Notification.EXTRA_TITLE) ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        val subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString() ?: ""
        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: ""
        val lines = extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)?.joinToString(" ") { it.toString() } ?: ""
        val content = listOf(title, text, subText, bigText, lines)
            .filter { it.isNotBlank() }
            .joinToString(" ")
            .trim()

        if (content.isEmpty()) return
        if (!containsAny(content, notificationKeywords)) return

        Log.d(logTag, "Captured: [$packageName] $content")

        val amount = extractAmount(content) ?: return
        val type = inferType(content)
        val rawText = content

        val intent = Intent("com.jive.app.NEW_TRANSACTION")
        intent.putExtra("source", displayName)
        intent.putExtra("amount", amount.toString())
        intent.putExtra("raw_text", rawText)
        intent.putExtra("type", type)
        intent.putExtra("timestamp", System.currentTimeMillis())
        intent.putExtra("package_name", packageName)
        sendBroadcast(intent)
    }

    private fun extractAmount(text: String): Double? {
        val currencyMatcher = currencyPattern.matcher(text)
        if (currencyMatcher.find()) {
            val value = currencyMatcher.group(1)?.replace(",", "")?.toDoubleOrNull()
            if (value != null && value >= 0.01) return abs(value)
        }

        val labelMatcher = labelPattern.matcher(text)
        if (labelMatcher.find()) {
            val value = labelMatcher.group(1)?.replace(",", "")?.toDoubleOrNull()
            if (value != null && value >= 0.01) return abs(value)
        }
        return null
    }

    private fun inferType(text: String): String {
        for (keyword in incomeKeywords) {
            if (text.contains(keyword)) return "income"
        }
        for (keyword in transferKeywords) {
            if (text.contains(keyword)) return "transfer"
        }
        return "expense"
    }

    private fun containsAny(text: String, keywords: List<String>): Boolean {
        for (keyword in keywords) {
            if (text.contains(keyword)) return true
        }
        return false
    }
}
