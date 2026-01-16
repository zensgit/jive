package com.jive.app

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import kotlin.math.abs

class JiveAccessibilityService : AccessibilityService() {

    private val logTag = "JiveAccess"
    private val wechatPackage = "com.tencent.mm"
    private val alipayPackage = "com.eg.android.AlipayGphone"
    private val unionPayPackage = "com.unionpay"

    private val wechatClassWhitelist = setOf(
        "com.tencent.mm.ui.LauncherUI",
        "com.tencent.mm.plugin.webview.ui.tools.MMWebViewUI",
        "com.tencent.mm.framework.app.UIPageFragmentActivity",
        "com.tencent.mm.plugin.remittance.ui.RemittanceBusiUI",
        "com.tencent.mm.plugin.remittance.ui.RemittanceUI",
        "com.tencent.mm.plugin.offline.ui.WalletOfflineCoinPurseUI",
        "com.tencent.mm.plugin.wallet_index.ui.WalletBrandUI",
        "com.tencent.mm.plugin.luckymoney.ui.LuckyMoneyPrepareUI",
        "com.tencent.mm.plugin.luckymoney.ui.LuckyMoneyDetailUI",
        "com.tencent.mm.plugin.luckymoney.ui.LuckyMoneyNotHookReceiveUI",
        "com.tencent.mm.plugin.wallet_index.ui.OrderHandlerUI",
        "com.tencent.mm.plugin.remittance.ui.RemittanceDetailUI"
    )

    private val alipayClassWhitelist = setOf(
        "com.eg.android.AlipayGphone.AlipayLogin",
        "com.alipay.android.msp.ui.views.MspContainerActivity",
        "com.alipay.android.msp.ui.views.MspUniRenderActivity",
        "com.alipay.android.phone.discovery.envelope.get.SnsCouponDetailActivity"
    )

    private val unionPayClassWhitelist = setOf(
        "com.unionpay.activity.UPActivityMain",
        "com.unionpay.activity.payment.UPActivityScan",
        "com.unionpay.activity.payment.UPActivityPaymentQrCodeOut"
    )

    private val appProfiles = listOf(
        AppProfile(
            packageName = wechatPackage,
            displayName = "WeChat",
            successKeywords = listOf(
                "支付成功", "付款成功", "已收款", "资金待入账", "转账成功", "已支付", "收款成功", "退款成功"
            ),
            amountLabels = listOf(
                "支付金额", "实付金额", "收款金额", "交易金额", "付款金额", "转账金额", "退款金额", "提现金额", "红包金额"
            ),
            merchantLabels = listOf(
                "收款方", "商品", "商户", "对方账户", "收款人", "付款方", "转账说明", "付款备注", "商品名称"
            ),
            classWhitelist = wechatClassWhitelist
        ),
        AppProfile(
            packageName = alipayPackage,
            displayName = "Alipay",
            successKeywords = listOf(
                "支付成功",
                "交易成功",
                "付款成功",
                "代付成功",
                "自动扣款成功",
                "转账成功",
                "充值成功",
                "还款成功",
                "退款成功",
                "已全额退款",
                "有退款",
                "赔付成功",
                "到账成功",
                "转账到账",
                "入账成功",
                "已到账",
                "收款成功",
                "免密支付成功",
                "自动续费成功",
                "交易成功(代付成功)",
                "支付成功(代付成功)",
                "支付宝小荷包付款成功",
                "等待对方确认收货",
                "等待确认收货",
                "等待对方发货",
                "退回成功",
                "缴费中",
                "派送中",
                "领取中"
            ),
            amountLabels = listOf(
                "实付金额", "付款金额", "支付金额", "转账金额", "金额", "合计", "退款金额", "收入金额", "支出金额"
            ),
            merchantLabels = listOf(
                "收款方", "商家", "对方账户", "付款方", "商品", "商品名称", "交易对象"
            ),
            classWhitelist = alipayClassWhitelist
        ),
        AppProfile(
            packageName = unionPayPackage,
            displayName = "UnionPay",
            successKeywords = listOf(
                "支付成功", "交易详情", "转账成功", "收款成功", "订单详情", "转出成功", "转入成功"
            ),
            amountLabels = listOf(
                "支出金额", "订单金额", "实付金额（元）", "实收金额（元）", "收入金额", "交易金额", "转账金额"
            ),
            merchantLabels = listOf(
                "收款方", "交易对方", "商户", "商品", "付款卡", "收款卡"
            ),
            classWhitelist = unionPayClassWhitelist
        ),
        genericProfile("com.jd.jrapp", "京东金融"),
        genericProfile("com.jingdong.app.mall", "京东商城"),
        genericProfile("com.xunmeng.pinduoduo", "拼多多"),
        genericProfile("com.sankuai.meituan", "美团"),
        genericProfile("com.dianping.v1", "大众点评"),
        genericProfile("com.sankuai.meituan.takeoutnew", "美团外卖"),
        genericProfile("com.ss.android.ugc.aweme", "抖音"),
        genericProfile("com.ss.android.ugc.livelite", "抖音商城"),
        genericProfile("com.ss.android.ugc.aweme.lite", "抖音极速版"),
        genericProfile("com.ss.android.yumme.video", "抖音精选"),
        genericProfile("com.taobao.taobao", "淘宝"),
        genericProfile("com.alibaba.wireless", "阿里巴巴"),
        genericProfile("com.taobao.idlefish", "闲鱼"),
        genericProfile("com.wudaokou.hippo", "盒马"),
        genericProfile("me.ele", "饿了么"),
        genericProfile("com.huawei.wallet", "华为钱包"),
        genericProfile("com.ccb.longjiLife", "建行生活"),
        genericProfile("com.smile.gifmaker", "快手"),
        genericProfile("com.kuaishou.nebula", "快手极速版")
    )

    private val appProfileByPackage = appProfiles.associateBy { it.packageName }

    private val wechatSuccessKeywords = listOf(
        "支付成功",
        "付款成功",
        "已收款",
        "资金待入账",
        "已收到",
        "转账成功",
        "退款成功",
        "收款成功",
        "你已收款"
    )

    private val alipaySuccessKeywords = listOf(
        "支付成功",
        "交易成功",
        "付款成功",
        "代付成功",
        "自动扣款成功",
        "转账成功",
        "充值成功",
        "还款成功",
        "退款成功",
        "已全额退款",
        "有退款",
        "赔付成功",
        "到账成功",
        "转账到账",
        "入账成功",
        "已到账",
        "收款成功",
        "免密支付成功",
        "自动续费成功",
        "交易成功(代付成功)",
        "支付成功(代付成功)",
        "支付宝小荷包付款成功",
        "等待对方确认收货",
        "等待确认收货",
        "等待对方发货",
        "退回成功",
        "缴费中",
        "派送中",
        "领取中"
    )

    private val alipayAmountAnchors = listOf(
        "交易成功",
        "支付成功",
        "付款成功",
        "代付成功",
        "转账成功",
        "充值成功",
        "还款成功",
        "退款成功",
        "赔付成功",
        "到账成功",
        "入账成功",
        "收款成功",
        "免密支付成功",
        "自动扣款成功",
        "已收款",
        "资金待入账"
    )

    private val unionPaySuccessKeywords = listOf(
        "支付成功",
        "交易详情",
        "转账成功",
        "订单详情",
        "转入成功",
        "转出成功",
        "收款成功"
    )

    private val incomeKeywords = listOf(
        "已收款",
        "你已收款",
        "已收到",
        "资金待入账",
        "收款成功",
        "退款",
        "赔付",
        "到账"
    )

    private val transferKeywords = listOf(
        "转账",
        "转账给",
        "转入",
        "转出",
        "提现",
        "还款",
        "余额转入",
        "余额转出",
        "收款账号",
        "到账银行卡"
    )

    private val alipayDetailKeywords = listOf(
        "账单详情",
        "交易详情",
        "转账详情",
        "账单明细",
        "订单详情"
    )

    private val wechatDetailFields = listOf(
        "付款方式",
        "支付方式",
        "收款方式",
        "退款方式",
        "付款信息",
        "交易方式",
        "支付时间",
        "交易时间",
        "收款时间",
        "转账时间",
        "退款时间",
        "到账时间",
        "收款账号",
        "收款方",
        "对方账户",
        "商品名称",
        "商品",
        "付款备注",
        "转账说明",
        "收款方备注",
        "付款方留言",
        "支付场景"
    )

    private val alipayDetailFields = listOf(
        "创建时间",
        "付款方式",
        "付款信息",
        "交易方式",
        "退款方式",
        "支付时间",
        "交易时间",
        "收款时间",
        "转账时间",
        "退款时间",
        "到账时间",
        "转账到",
        "转账说明",
        "处理进度",
        "账单管理",
        "账单分类",
        "交易对象",
        "收款方",
        "收款账号",
        "收款理由",
        "对方账户",
        "付款方",
        "申请电子回单",
        "计入收支"
    )

    private val alipayNoiseAmountKeywords = listOf(
        "服务推荐",
        "支付奖励",
        "福利",
        "奖励",
        "积分",
        "保障",
        "领取",
        "活动",
        "推荐",
        "手续费",
        "优惠",
        "立减",
        "红包"
    )

    private val alipayListKeywords = listOf(
        "搜索交易记录",
        "账单功能",
        "筛选",
        "交易记录",
        "账单记录",
        "账单列表",
        "我的账单",
        "全部账单"
    )

    private val processingKeywords = listOf(
        "处理中",
        "待到账",
        "预计到账",
        "转账处理中"
    )

    private val redPacketKeywords = listOf("红包", "个红包共", "红包金额")
    private val redPacketSendMarkers = listOf("发送", "发的红包", "红包金额", "个红包共", "人已领取", "领取成功")
    private val redPacketReceiveMarkers = listOf("收红包", "送你的红包", "你已收款", "已收款", "资金待入账", "收到红包")

    private val amountRegex = Regex("(?<!\\d)[-+]?\\d+(?:,\\d{3})*(?:\\.\\d{1,2})?(?!\\d)")

    private val lastTokenHashByPackage = mutableMapOf<String, Int>()
    private val lastTokenTimeByPackage = mutableMapOf<String, Long>()

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.i(logTag, "Service Connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        val packageName = event.packageName?.toString() ?: return
        val profile = appProfileByPackage[packageName] ?: return

        val rootNode = rootInActiveWindow ?: return
        val tokens = mutableListOf<String>()
        collectText(rootNode, tokens, depth = 0)
        event.text?.forEach { tokens.add(it.toString()) }
        val cleaned = normalizeTokens(tokens)
        if (cleaned.isEmpty()) return

        if (shouldSkipDuplicate(packageName, cleaned)) return

        val className = event.className?.toString()
        if (!shouldCheck(className, profile, cleaned)) return

        val result = when (packageName) {
            wechatPackage -> parseWeChat(cleaned)
            alipayPackage -> parseAlipay(cleaned)
            unionPayPackage -> parseUnionPay(cleaned)
            else -> parseGeneric(profile, cleaned)
        }
        result?.let { broadcastTransaction(it, packageName) }
    }

    private fun normalizeTokens(tokens: List<String>): List<String> {
        val seen = LinkedHashSet<String>()
        for (token in tokens) {
            val trimmed = token.trim()
            if (trimmed.isEmpty()) continue
            if (seen.size >= 260) break
            seen.add(trimmed)
        }
        return seen.toList()
    }

    private fun shouldSkipDuplicate(packageName: String, tokens: List<String>): Boolean {
        val now = System.currentTimeMillis()
        val hash = tokens.take(60).joinToString("|").hashCode()
        val lastHash = lastTokenHashByPackage[packageName]
        val lastTime = lastTokenTimeByPackage[packageName] ?: 0L
        if (lastHash == hash && now - lastTime < 2000) return true
        lastTokenHashByPackage[packageName] = hash
        lastTokenTimeByPackage[packageName] = now
        return false
    }

    private fun shouldCheck(className: String?, profile: AppProfile, tokens: List<String>): Boolean {
        val hasSuccess = containsAny(tokens, profile.successKeywords) || containsAny(tokens, redPacketKeywords)
        if (className != null && profile.classWhitelist.contains(className)) return true
        if (hasSuccess) return true
        if (profile.packageName == alipayPackage) {
            val hasDetail = containsAny(tokens, alipayDetailKeywords)
            val hasDetailFields = containsAny(tokens, alipayDetailFields)
            val hasAmount = containsAmount(tokens, profile.amountLabels, requireCurrency = false)
            return hasAmount && (hasDetail || hasDetailFields)
        }
        return false
    }

    private fun collectText(node: AccessibilityNodeInfo?, out: MutableList<String>, depth: Int) {
        if (node == null || depth > 40 || out.size > 240) return
        val text = node.text?.toString()
        if (!text.isNullOrBlank()) out.add(text)
        val desc = node.contentDescription?.toString()
        if (!desc.isNullOrBlank()) out.add(desc)
        for (i in 0 until node.childCount) {
            collectText(node.getChild(i), out, depth + 1)
        }
    }

    private data class ParseResult(
        val source: String,
        val amount: Double,
        val remark: String,
        val type: String,
        val rawText: String,
        val timestamp: Long
    )

    private data class AppProfile(
        val packageName: String,
        val displayName: String,
        val successKeywords: List<String>,
        val amountLabels: List<String>,
        val merchantLabels: List<String>,
        val requireCurrency: Boolean = true,
        val classWhitelist: Set<String> = emptySet()
    )

    private fun genericProfile(packageName: String, displayName: String): AppProfile {
        return AppProfile(
            packageName = packageName,
            displayName = displayName,
            successKeywords = listOf(
                "支付成功", "交易成功", "付款成功", "已支付", "支付完成", "交易完成", "订单完成",
                "转账成功", "收款成功", "退款成功", "已收款", "资金待入账"
            ),
            amountLabels = listOf(
                "实付金额", "支付金额", "付款金额", "交易金额", "收款金额", "转账金额", "订单金额",
                "支出金额", "收入金额", "退款金额"
            ),
            merchantLabels = listOf(
                "收款方", "商户", "商品", "商品名称", "交易对象", "对方账户", "收款人"
            )
        )
    }

    private fun parseWeChat(tokens: List<String>): ParseResult? {
        if (!containsAny(tokens, wechatSuccessKeywords) && !containsAny(tokens, redPacketKeywords)) return null
        if (tokens.any { it.contains("当前状态") } && tokens.none { it.contains("支付成功") || it.contains("付款成功") }) {
            return null
        }
        val wechatListLike = looksLikeMultiTransactionList(tokens)
        if (wechatListLike && !containsAny(tokens, wechatDetailFields)) return null

        val amount = extractAmount(tokens, requireCurrency = true, labels = listOf(
            "支付金额",
            "实付金额",
            "收款金额",
            "交易金额",
            "付款金额",
            "转账金额",
            "退款金额",
            "红包金额"
        ))
            ?: run {
                Log.w(logTag, "WeChat success hit but no amount. tokens=${sampleTokens(tokens)}")
                return null
            }

        val redPacketType = detectRedPacketType(tokens)
        val isRedPacket = redPacketType != null
        var remark = extractMerchant(tokens, listOf(
            "收款方",
            "商品",
            "商户",
            "对方账户",
            "收款人",
            "付款方",
            "转账说明",
            "付款备注",
            "商品名称",
            "收款方备注",
            "付款方留言",
            "支付场景"
        )) ?: if (isRedPacket) "微信红包" else "微信支付"

        var type = redPacketType ?: inferType(tokens, defaultType = "expense")
        val hasIncomeHint = tokens.any { it.contains("+") || it.contains("收入") || it.contains("已收款") || it.contains("你已收款") }
        if (type != "transfer" && hasIncomeHint) {
            type = "income"
        }
        if (remark == "微信支付") {
            remark = when (type) {
                "transfer" -> "微信转账"
                "income" -> "微信收款"
                else -> remark
            }
        }
        Log.i(logTag, "WeChat parsed amount=$amount remark=$remark type=$type")
        val rawText = buildRawText(tokens, remark)
        return ParseResult(
            source = "WeChat",
            amount = amount,
            remark = remark,
            type = type,
            rawText = rawText,
            timestamp = System.currentTimeMillis()
        )
    }

    private fun parseAlipay(tokens: List<String>): ParseResult? {
        val hasSuccess = containsAny(tokens, alipaySuccessKeywords) || containsAny(tokens, redPacketKeywords)
        val hasDetail = containsAny(tokens, alipayDetailKeywords)
        val hasDetailFields = containsAny(tokens, alipayDetailFields)
        if (!hasSuccess && !hasDetail && !hasDetailFields) return null
        if (isAlipayListLike(tokens)) return null
        if (containsAny(tokens, processingKeywords) && !hasSuccess) return null
        val listLike = isAlipayListLike(tokens) || looksLikeMultiTransactionList(tokens)
        if (listLike && !hasDetailFields) return null

        val amountTokens = tokens.filterNot { token ->
            alipayNoiseAmountKeywords.any { keyword -> token.contains(keyword) }
        }
        val labeledAmount = extractAmount(amountTokens, requireCurrency = false, labels = listOf(
            "实付金额",
            "付款金额",
            "支付金额",
            "转账金额",
            "转入金额",
            "转出金额",
            "提现金额",
            "充值金额",
            "还款金额",
            "订单金额",
            "到账金额",
            "金额",
            "合计",
            "退款金额",
            "收入金额",
            "支出金额"
        ))
        val anchoredAmount = extractAmountNearAnchors(amountTokens, alipayAmountAnchors, window = 3)
        val amount = labeledAmount ?: anchoredAmount ?: run {
            if (listLike) return null
            extractAmount(amountTokens, requireCurrency = false, labels = emptyList())
        }
            ?: run {
                Log.w(logTag, "Alipay success hit but no amount. tokens=${sampleTokens(tokens)}")
                return null
            }
        if (listLike && labeledAmount == null && anchoredAmount == null) {
            Log.w(logTag, "Alipay list-like without anchored amount, skip. tokens=${sampleTokens(tokens)}")
            return null
        }

        val redPacketType = detectRedPacketType(tokens)
        val isRedPacket = redPacketType != null
        var remark = extractMerchant(tokens, listOf(
            "收款方",
            "商家",
            "对方账户",
            "付款方",
            "商品",
            "商品名称",
            "交易对象",
            "收款理由"
        )) ?: if (isRedPacket) "支付宝红包" else "支付宝支付"

        var type = redPacketType ?: inferType(tokens, defaultType = "expense")
        val hasIncomeHint = tokens.any { it.contains("+") || it.contains("收入") || it.contains("已收款") || it.contains("收款成功") }
        if (type != "transfer" && hasIncomeHint) {
            type = "income"
        }
        if (remark == "支付宝支付") {
            remark = when (type) {
                "transfer" -> "支付宝转账"
                "income" -> "支付宝收款"
                else -> remark
            }
        }
        Log.i(logTag, "Alipay parsed amount=$amount remark=$remark type=$type")
        val rawText = buildRawText(tokens, remark)
        return ParseResult(
            source = "Alipay",
            amount = amount,
            remark = remark,
            type = type,
            rawText = rawText,
            timestamp = System.currentTimeMillis()
        )
    }

    private fun containsAmount(
        tokens: List<String>,
        labels: List<String>,
        requireCurrency: Boolean
    ): Boolean {
        return extractAmount(tokens, requireCurrency = requireCurrency, labels = labels) != null
    }

    private fun parseUnionPay(tokens: List<String>): ParseResult? {
        if (!containsAny(tokens, unionPaySuccessKeywords)) return null

        val amount = extractAmount(tokens, requireCurrency = false, labels = listOf(
            "支出金额",
            "订单金额",
            "实付金额（元）",
            "实收金额（元）",
            "收入金额",
            "交易金额",
            "转账金额"
        ))
            ?: run {
                Log.w(logTag, "UnionPay success hit but no amount. tokens=${sampleTokens(tokens)}")
                return null
            }

        val remark = extractMerchant(tokens, listOf(
            "收款方", "交易对方", "商户", "商品", "付款卡", "收款卡"
        )) ?: "云闪付"

        val type = inferType(tokens, defaultType = "expense")
        Log.i(logTag, "UnionPay parsed amount=$amount remark=$remark type=$type")
        val rawText = buildRawText(tokens, remark)
        return ParseResult(
            source = "UnionPay",
            amount = amount,
            remark = remark,
            type = type,
            rawText = rawText,
            timestamp = System.currentTimeMillis()
        )
    }

    private fun parseGeneric(profile: AppProfile, tokens: List<String>): ParseResult? {
        if (!containsAny(tokens, profile.successKeywords)) return null
        val amount = extractAmount(tokens, requireCurrency = profile.requireCurrency, labels = profile.amountLabels)
            ?: return null
        val remark = extractMerchant(tokens, profile.merchantLabels) ?: profile.displayName
        val type = inferType(tokens, defaultType = "expense")
        val rawText = buildRawText(tokens, remark)
        return ParseResult(
            source = profile.displayName,
            amount = amount,
            remark = remark,
            type = type,
            rawText = rawText,
            timestamp = System.currentTimeMillis()
        )
    }

    private fun containsAny(tokens: List<String>, keywords: List<String>): Boolean {
        for (token in tokens) {
            for (keyword in keywords) {
                if (token.contains(keyword)) return true
            }
        }
        return false
    }

    private fun inferType(tokens: List<String>, defaultType: String): String {
        if (containsAny(tokens, incomeKeywords)) return "income"
        if (containsAny(tokens, transferKeywords)) return "transfer"
        return defaultType
    }

    private fun extractAmount(
        tokens: List<String>,
        requireCurrency: Boolean,
        labels: List<String>
    ): Double? {
        for (token in tokens) {
            val inline = extractInlineAmount(token, labels)
            if (inline != null) return inline
        }

        val labeled = amountAfterLabel(tokens, labels)
        if (labeled != null) return labeled

        for (token in tokens) {
            val amount = extractAmountFromToken(token, requireCurrency)
            if (amount != null) return amount
        }

        if (!requireCurrency) {
            for (token in tokens) {
                val amount = extractPlainAmount(token)
                if (amount != null) return amount
            }
        }
        return null
    }

    private fun extractInlineAmount(token: String, labels: List<String>): Double? {
        for (label in labels) {
            val idx = token.indexOf(label)
            if (idx >= 0) {
                val tail = token.substring(idx + label.length)
                val amount = extractAmountFromToken(tail, requireCurrency = false)
                    ?: extractPlainAmount(tail)
                if (amount != null) return amount
            }
        }
        return null
    }

    private fun amountAfterLabel(tokens: List<String>, labels: List<String>): Double? {
        for (i in tokens.indices) {
            val token = tokens[i]
            for (label in labels) {
                if (token == label || token.contains(label)) {
                    val inline = extractInlineAmount(token, listOf(label))
                    if (inline != null) return inline
                    for (offset in 1..2) {
                        val target = tokens.getOrNull(i + offset) ?: continue
                        val amount = extractAmountFromToken(target, requireCurrency = false)
                            ?: extractPlainAmount(target)
                        if (amount != null) return amount
                    }
                }
            }
        }
        return null
    }

    private fun extractAmountFromToken(token: String, requireCurrency: Boolean): Double? {
        val text = normalizeAmountToken(token).replace(",", "")
        if (shouldSkipAmountToken(text)) return null
        if (looksLikeDateOrTime(text)) return null
        if (looksLikeCardTail(text)) return null

        val hasCurrency = text.contains("¥") || text.contains("￥") || text.contains("元") ||
            text.contains("支出") || text.contains("收入") || text.contains("已支付") ||
            text.contains("已收到") || text.contains("已收款") || text.contains("实付")
        if (requireCurrency && !hasCurrency) return null

        val match = amountRegex.find(text) ?: return null
        val value = match.value.replace(",", "").toDoubleOrNull() ?: return null
        val absValue = abs(value)
        if (absValue == 0.0 || absValue < 0.01) return null
        return absValue
    }

    private fun extractPlainAmount(token: String): Double? {
        val trimmed = normalizeAmountToken(token).trim()
        if (trimmed.contains("年") || trimmed.contains("月") || trimmed.contains(":")) return null
        if (!trimmed.contains(".")) return null
        if (!trimmed.matches(Regex("[-+]?\\d+(\\.\\d{1,2})?"))) return null
        val value = trimmed.toDoubleOrNull() ?: return null
        val absValue = abs(value)
        if (absValue == 0.0 || absValue < 0.01) return null
        return absValue
    }

    private fun normalizeAmountToken(token: String): String {
        return token
            .replace("－", "-")
            .replace("−", "-")
            .replace("＋", "+")
            .replace("，", ",")
            .replace("．", ".")
    }

    private fun shouldSkipAmountToken(text: String): Boolean {
        if (text.contains("订单") || text.contains("交易号")) return true
        if (text.contains("支付时间") || text.contains("交易时间") || text.contains("收款时间")) return true
        if (text.contains("优惠") || text.contains("积分") || text.contains("手续费")) return true
        if (text.contains("余额") || text.contains("余额宝") || text.contains("可用额度") || text.contains("限额")) return true
        if (text.contains("年") && text.contains("月")) return true
        if (text.contains("尾号") || text.contains("末四位") || text.contains("末尾")) return true
        if (Regex("^\\d{6,}\$").matches(text)) return true
        return false
    }

    private fun looksLikeCardTail(text: String): Boolean {
        if (Regex("^[（(]?\\d{3,4}[）)]?$").matches(text)) return true
        val hasCard = text.contains("银行卡") || text.contains("信用卡") || text.contains("储蓄卡")
        val hasTail = Regex("\\(\\d{3,4}\\)").containsMatchIn(text)
        val hasCurrency = text.contains("¥") || text.contains("￥") || text.contains("元")
        if (hasCard && hasTail && !hasCurrency) return true
        return false
    }

    private fun looksLikeDateOrTime(text: String): Boolean {
        if (text.contains(":") && Regex("\\d{1,2}:\\d{2}").containsMatchIn(text)) return true
        if (Regex("\\d{4}[-/]\\d{1,2}[-/]\\d{1,2}").containsMatchIn(text)) return true
        return false
    }

    private fun looksLikeMultiTransactionList(tokens: List<String>): Boolean {
        var amountCount = 0
        for (token in tokens) {
            val amount = extractAmountFromToken(token, requireCurrency = false) ?: extractPlainAmount(token)
            if (amount != null) {
                amountCount++
                if (amountCount >= 5) return true
            }
        }
        return false
    }

    private fun extractAmountNearAnchors(
        tokens: List<String>,
        anchors: List<String>,
        window: Int
    ): Double? {
        for (i in tokens.indices) {
            val token = tokens[i]
            if (!anchors.any { anchor -> token.contains(anchor) }) continue
            for (offset in -window..window) {
                if (offset == 0) continue
                val candidate = tokens.getOrNull(i + offset) ?: continue
                val amount = extractAmountFromToken(candidate, requireCurrency = false)
                    ?: extractPlainAmount(candidate)
                if (amount != null) return amount
            }
        }
        return null
    }

    private fun isAlipayListLike(tokens: List<String>): Boolean {
        if (containsAny(tokens, alipayListKeywords)) return true
        val hasSearch = tokens.any { token -> token.contains("搜索") }
        val hasRecord = tokens.any { token ->
            token.contains("交易记录") || token.contains("账单记录") || token.contains("账单列表")
        }
        if (hasSearch && hasRecord) return true
        val hasTabs = tokens.contains("全部") && tokens.contains("支出") && tokens.contains("转账")
        if (hasTabs && tokens.any { it.contains("筛选") || it.contains("退款") || it.contains("收入") }) return true
        return false
    }

    private fun extractMerchant(tokens: List<String>, labels: List<String>): String? {
        for (label in labels) {
            val idx = tokens.indexOf(label)
            if (idx >= 0 && idx + 1 < tokens.size) {
                val candidate = tokens[idx + 1].trim()
                if (candidate.isNotEmpty()) return candidate
            }
        }

        for (token in tokens) {
            val trimmed = token.trim()
            if (trimmed.isEmpty()) continue
            if (isNoiseToken(trimmed)) continue
            return trimmed
        }
        return null
    }

    private fun isNoiseToken(token: String): Boolean {
        if (token.length <= 1) return true
        val noiseKeywords = listOf(
            "支付成功",
            "交易成功",
            "付款成功",
            "转账成功",
            "已收款",
            "资金待入账",
            "微信支付",
            "支付宝",
            "账单详情",
            "交易详情",
            "支付时间",
            "交易时间",
            "收款时间"
        )
        if (containsAny(listOf(token), noiseKeywords)) return true
        if (extractAmountFromToken(token, requireCurrency = false) != null) return true
        return false
    }

    private fun buildRawText(tokens: List<String>, remark: String): String {
        val joined = tokens.joinToString(" ")
        val capped = if (joined.length > 400) joined.substring(0, 400) else joined
        return "$remark $capped".trim()
    }

    private fun sampleTokens(tokens: List<String>, limit: Int = 28): String {
        return tokens.take(limit).joinToString(" | ")
    }

    private fun detectRedPacketType(tokens: List<String>): String? {
        if (!containsAny(tokens, redPacketKeywords)) return null
        val hasSendMarkers = tokens.any { token ->
            redPacketSendMarkers.any { marker -> token.contains(marker) }
        }
        val hasReceiveMarkers = tokens.any { token ->
            redPacketReceiveMarkers.any { marker -> token.contains(marker) }
        }
        return when {
            hasReceiveMarkers && !hasSendMarkers -> "income"
            hasSendMarkers && !hasReceiveMarkers -> "expense"
            hasReceiveMarkers -> "income"
            else -> "expense"
        }
    }

    private var lastBroadcastKey: String? = null
    private var lastBroadcastTime = 0L

    private fun broadcastTransaction(result: ParseResult, packageName: String) {
        val key = "${result.source}|${result.amount}|${result.remark}"
        val now = System.currentTimeMillis()
        if (lastBroadcastKey == key && now - lastBroadcastTime < 3000) return
        lastBroadcastKey = key
        lastBroadcastTime = now

        Log.i(logTag, "SUCCESS: ${result.source} ${result.amount} ${result.remark}")

        val intent = Intent("com.jive.app.NEW_TRANSACTION")
        intent.putExtra("source", result.source)
        intent.putExtra("amount", result.amount.toString())
        intent.putExtra("raw_text", result.rawText)
        intent.putExtra("type", result.type)
        intent.putExtra("timestamp", result.timestamp)
        intent.putExtra("package_name", packageName)
        sendBroadcast(intent)
    }

    override fun onInterrupt() {}
}
