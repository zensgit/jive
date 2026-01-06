package com.jive.app

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.util.Log
import java.util.regex.Pattern

class JiveAccessibilityService : AccessibilityService() {

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.i("JiveAccess", "Service Connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        
        val packageName = event.packageName?.toString() ?: return
        val rootNode = rootInActiveWindow ?: return

        // 1. 提取全屏文本
        val textList = mutableListOf<String>()
        traverseNode(rootNode, textList)

        // 2. 识别逻辑
        if (packageName == "com.tencent.mm") {
            parseWeChat(textList)
        } else if (packageName == "com.eg.android.AlipayGphone") {
            parseAlipay(textList)
        }
    }

    private fun traverseNode(node: AccessibilityNodeInfo?, list: MutableList<String>) {
        if (node == null) return
        if (node.text != null && node.text.isNotEmpty()) {
            list.add(node.text.toString())
        }
        for (i in 0 until node.childCount) {
            traverseNode(node.getChild(i), list)
        }
    }

    // --- 微信解析逻辑 (移植自 p.java) ---
    private fun parseWeChat(list: List<String>) {
        // 关键词过滤
        val isPayment = list.any { it.contains("支付成功") || it.contains("付款成功") || it.contains("已收款") }
        if (!isPayment) return

        Log.d("JiveAccess", "WeChat Page: $list")

        var amount = 0.0
        var remark = "微信商家"

        // 1. 找金额 (优先找带 ¥ 符号的)
        for (text in list) {
            if (text.startsWith("¥") || text.startsWith("￥")) {
                val numStr = text.substring(1).replace(",", "").trim()
                amount = parseDouble(numStr)
                if (amount > 0) break
            }
        }

        // 2. 没找到？找 "支付金额" 下面的数字
        if (amount == 0.0) {
            val keywords = listOf("支付金额", "实付金额", "当前状态")
            for (i in list.indices) {
                if (keywords.contains(list[i])) {
                    if (i + 1 < list.size) {
                        val nextStr = list[i + 1].replace("¥", "").replace("￥", "").replace(",", "")
                        amount = parseDouble(nextStr)
                        if (amount > 0) break
                    }
                }
            }
        }

        // 3. 找商户名
        if (amount > 0) {
            // 策略 A: 找 "收款方"
            if (list.contains("收款方")) {
                val index = list.indexOf("收款方")
                if (index + 1 < list.size) remark = list[index + 1]
            } 
            // 策略 B: 找 "商品"
            else if (list.contains("商品")) {
                val index = list.indexOf("商品")
                if (index + 1 < list.size) remark = list[index + 1]
            }
            // 策略 C: 盲猜第一行 (通常是商户名)
            else if (list.isNotEmpty()) {
                val candidate = list[0]
                if (!candidate.contains("支付成功") && !candidate.contains("¥")) {
                    remark = candidate
                }
            }
            
            broadcastTransaction("WeChat", amount, remark)
        }
    }

    // --- 支付宝解析逻辑 (移植自 b.java) ---
    private fun parseAlipay(list: List<String>) {
        val isPayment = list.any { it.contains("支付成功") || it.contains("交易成功") || it.contains("付款成功") }
        if (!isPayment) return

        Log.d("JiveAccess", "Alipay Page: $list")

        var amount = 0.0
        var remark = "支付宝商家"

        // 1. 找金额 (支付宝通常是纯数字，或者 -xx.xx)
        // 正则: 匹配 -12.50 或 12.50
        val amountRegex = Regex("^-?\\s*(\\d{1,3}(,\\d{3})*(\\.\\d{2})?|\\d+(\\.\\d{2})?)$")

        for (text in list) {
            // 排除干扰项 (如 "优惠 0.00")
            if (text.contains("优惠") || text.contains("积分")) continue

            if (amountRegex.matches(text)) {
                val numStr = text.replace("-", "").replace(",", "").trim()
                val tempAmount = parseDouble(numStr)
                // 排除极大或极小的异常值
                if (tempAmount > 0.01 && tempAmount < 1000000) {
                    amount = tempAmount
                    break 
                }
            }
        }

        // 2. 找商户名
        if (amount > 0) {
            // 支付宝第一行通常就是商户名
            if (list.isNotEmpty()) {
                val first = list[0]
                // 排除 "支付成功" 这种标题
                if (!first.contains("成功") && !first.contains("完成")) {
                    remark = first
                } else if (list.size > 1) {
                    // 如果第一行是标题，试第二行
                    remark = list[1]
                }
            }
            
            broadcastTransaction("Alipay", amount, remark)
        }
    }

    private fun parseDouble(str: String): Double {
        return try {
            str.toDouble()
        } catch (e: Exception) {
            0.0
        }
    }

    private var lastBroadcastTime = 0L
    private var lastAmount = 0.0

    private fun broadcastTransaction(source: String, amount: Double, rawText: String) {
        val now = System.currentTimeMillis()
        // 防抖: 3秒内不发送同一笔金额 (防止页面刷新导致重复记账)
        if (now - lastBroadcastTime < 3000 && amount == lastAmount) return
        
        lastBroadcastTime = now
        lastAmount = amount

        Log.i("JiveAccess", "SUCCESS: $source - $amount - $rawText")

        val intent = Intent("com.jive.app.NEW_TRANSACTION")
        intent.putExtra("source", source)
        intent.putExtra("amount", amount.toString())
        intent.putExtra("raw_text", rawText) // 这里其实传的是商户名/备注
        sendBroadcast(intent)
    }

    override fun onInterrupt() {}
}