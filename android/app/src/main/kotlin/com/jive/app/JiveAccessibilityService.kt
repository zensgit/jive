package com.jive.app

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import org.json.JSONObject
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

    private val jdJrClassWhitelist = setOf(
        "com.jd.jrapp.bm.mainbox.main.MainActivity",
        "com.jd.jrapp.bm.jrv8.JRCustomDyPageActivity"
    )

    private val jdMallClassWhitelist = setOf(
        "com.jd.lib.search.view.Activity.ProductListActivity",
        "com.jingdong.app.mall.MainFrameActivity",
        "com.jd.lib.productdetail.ProductDetailActivity",
        "com.jd.lib.cart.ShoppingCartNewActivity",
        "com.jingdong.common.jdreactFramework.activities.JDReactNativeCommonActivity",
        "com.wangyin.payment.jdpaysdk.counter.ui.pay.CounterActivity",
        "com.jingdong.app.mall.bundle.cashierfinish.view.CashierUserContentCompletePopActivity",
        "com.jd.lib.settlement.fillorder.activity.PopupNewFillOrderActivity",
        "com.jd.lib.cashier.complete.view.CashierCompleteActivity",
        "com.jd.lib.cashier.sdk.complete.view.CashierCompleteActivity",
        "com.jd.lib.jdpaysdk.JDPayActivity",
        "com.jd.lib.settlement.fillorder.activity.NewFillOrderActivity",
        "com.jd.lib.cashier.sdk.pay.view.CashierPayActivity",
        "com.jingdong.app.mall.WebActivity"
    )

    private val taobaoClassWhitelist = setOf(
        "com.taobao.android.tbabilitykit.pop.StdPopContainerActivity",
        "com.alibaba.android.ultron.vfw.weex2.highPerformance.widget.UltronTradeHybridActivity",
        "com.taobao.themis.container.app.TMSActivity",
        "com.taobao.tao.TBMainActivity",
        "com.taobao.tao.welcome.Welcome",
        "com.taobao.search.searchdoor.SearchDoorActivity",
        "com.taobao.search.sf.MainSearchResultActivity",
        "com.taobao.android.detail.alittdetail.TTDetailActivity",
        "com.taobao.android.detail.wrapper.activity.DetailActivity",
        "com.taobao.android.sku.widget.a",
        "com.taobao.android.sku.widget.SkuDialogFragment$1",
        "com.taobao.android.purchase.aura.TBBuyActivity",
        "com.taobao.android.tbsku.TBXSkuActivity"
    )

    private val alibabaClassWhitelist = setOf(
        "com.alibaba.wireless.launch.home.V5HomeActivity",
        "com.alibaba.wireless.search.aksearch.resultpage.SearchResultActivity",
        "com.alibaba.wireless.detail_flow.OfferDetailFlowActivity",
        "com.alibaba.wireless.container.windvane.AliWindvaneActivity",
        "com.alibaba.wireless.popwindow.core.PopPageWindow"
    )

    private val idlefishClassWhitelist = setOf(
        "com.taobao.idlefish.maincontainer.activity.MainActivity",
        "com.taobao.idlefish.search_implement.SearchResultActivity",
        "com.idlefish.flutterbridge.flutterboost.boost.FishFlutterBoostActivity"
    )

    private val hemaClassWhitelist = setOf(
        "com.wudaokou.hippo.launcher.splash.SplashActivity",
        "com.wudaokou.hippo.mine.MinePageActivity",
        "com.wudaokou.hippo.pay.PayCodeActivity"
    )

    private val kuaishouClassWhitelist = setOf(
        "com.yxcorp.gifshow.HomeActivity",
        "com.kuaishou.merchant.pagedy.page.MerchantEraActivity",
        "com.kuaishou.merchant.container.base.MerchantKwaiDialog",
        "com.yxcorp.plugin.search.SearchActivity",
        "com.yxcorp.gifshow.detail.PhotoDetailActivity",
        "com.kuaishou.live.core.basic.activity.LivePlayActivity",
        "com.kuaishou.merchant.transaction.detail.contentdetail.MerchantContentDetailActivity",
        "com.kuaishou.merchant.transaction.live.dynamic.page.MerchantPurchasePanelContainerV2Activity",
        "com.kwai.kds.krn.api.page.KwaiRnActivity",
        "com.kuaishou.merchant.basic.widget.MerchantInterceptOutsideTouchDialog"
    )

    private val elemeClassWhitelist = setOf(
        "me.ele.application.ui.Launcher.LauncherActivity",
        "me.ele.shopdetailv2.lmagex.ShopDetailV3Activity",
        "me.ele.newbooking.checkout.entrypoint.WMCheckoutActivity",
        "me.ele.newretail.submit.RetailSubmitActivity",
        "me.ele.shopdetailv2.ShopDetailV2Activity",
        "me.ele.android.emagex.container.EMagexPopupActivity"
    )

    private val meituanClassWhitelist = setOf(
        "com.meituan.android.food.deal.FoodDealDetailActivity",
        "com.meituan.android.pt.homepage.activity.MainActivity",
        "com.meituan.android.mtgb.business.main.MTGMainActivity",
        "com.sankuai.meituan.search.result.SearchResultActivity",
        "com.sankuai.waimai.business.page.homepage.TakeoutActivity",
        "com.sankuai.waimai.business.restaurant.poicontainer.WMRestaurantActivity",
        "com.sankuai.waimai.business.page.homepage.MainActivity",
        "com.meituan.android.hotel.search.HotelSearchResultActivity",
        "com.meituan.android.hotel.reuse.detail.HotelPoiDetailActivity",
        "com.sankuai.waimai.bussiness.order.confirm.OrderConfirmActivity",
        "com.sankuai.waimai.bussiness.order.confirm.OrderConfirmNoTransActivity",
        "com.meituan.android.mrn.container.MRNBaseActivity",
        "com.meituan.android.mrn.container.MRNStandardActivity",
        "com.meituan.android.movie.tradebase.activity.PaySeatActivity",
        "com.sankuai.eh.framework.EHContainerActivity",
        "com.meituan.android.neohybrid.neo.loading.b",
        "com.meituan.android.neohybrid.neo.loading.a",
        "com.meituan.traveltools.mrncontainer.HTMRNBaseActivity"
    )

    private val dianpingClassWhitelist = setOf(
        "com.dianping.v1.NovaMainActivity",
        "com.dianping.shopshell.PexusPoiActivity",
        "com.dianping.nova.picasso.DPPicassoBoxActivity"
    )

    private val ccbClassWhitelist = setOf(
        "com.ccb.longjiLife.MainActivity",
        "com.ccb.cloudmerchant.wallet.newOne.transactions.TransactionsActivity2",
        "com.ccb.cloudmerchant.wallet.newOne.WalletActivity",
        "com.ccb.cloudmerchant.wallet.newOne.view.CodeActivity",
        "com.ccb.cloudmerchant.view.WebViewActivity",
        "com.ccb.cloudmerchant.wallet.newOne.view.CodeResultActivity",
        "com.ccb.cloudmerchant.wallet.transactions.TransactionsDetailActivity"
    )

    private val orderSuccessKeywords = listOf(
        "下单成功",
        "商家已接单",
        "商家正在备餐",
        "商家备餐中",
        "商家备货完成",
        "等待商家接单"
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
        genericProfile(
            "com.jd.jrapp",
            "京东金融",
            extraSuccess = listOf("白条还款", "还款成功"),
            extraMerchantLabels = listOf("商户", "商品", "交易对象", "订单"),
            classWhitelist = jdJrClassWhitelist
        ),
        genericProfile(
            "com.jingdong.app.mall",
            "京东商城",
            extraSuccess = listOf("支付成功", "已支付", "交易成功"),
            extraMerchantLabels = listOf("商户", "商品", "店铺", "订单"),
            classWhitelist = jdMallClassWhitelist
        ),
        genericProfile(
            "com.xunmeng.pinduoduo",
            "拼多多",
            extraSuccess = listOf("拼单成功", "已支付"),
            extraAmountLabels = listOf("实付", "实付价", "合计", "订单合计", "应付金额", "优惠后金额"),
            extraMerchantLabels = listOf("商品详情", "关联商品", "退款商品", "商户", "商品", "店铺")
        ),
        genericProfile(
            "com.sankuai.meituan",
            "美团",
            extraSuccess = orderSuccessKeywords,
            extraAmountLabels = listOf("实付", "实付价", "合计", "订单合计", "应付金额", "优惠后金额"),
            extraMerchantLabels = listOf("商家", "店名", "商户", "商品", "订单"),
            classWhitelist = meituanClassWhitelist
        ),
        genericProfile(
            "com.dianping.v1",
            "大众点评",
            extraSuccess = orderSuccessKeywords,
            extraAmountLabels = listOf("实付", "合计", "订单合计", "应付金额"),
            extraMerchantLabels = listOf("商家", "店名", "商户", "商品", "订单"),
            classWhitelist = dianpingClassWhitelist
        ),
        genericProfile(
            "com.sankuai.meituan.takeoutnew",
            "美团外卖",
            extraSuccess = orderSuccessKeywords,
            extraAmountLabels = listOf("实付", "合计", "订单合计", "应付金额"),
            extraMerchantLabels = listOf("商家", "店名", "商户", "商品", "订单"),
            classWhitelist = meituanClassWhitelist
        ),
        genericProfile(
            "com.ss.android.ugc.aweme",
            "抖音",
            extraSuccess = listOf("抖音月付还款", "月付还款", "还款成功"),
            extraMerchantLabels = listOf("商户", "商品", "订单")
        ),
        genericProfile(
            "com.ss.android.ugc.livelite",
            "抖音商城",
            extraSuccess = listOf("抖音月付还款", "月付还款", "还款成功"),
            extraMerchantLabels = listOf("商户", "商品", "订单")
        ),
        genericProfile(
            "com.ss.android.ugc.aweme.lite",
            "抖音极速版",
            extraSuccess = listOf("抖音月付还款", "月付还款", "还款成功"),
            extraMerchantLabels = listOf("商户", "商品", "订单")
        ),
        genericProfile(
            "com.ss.android.yumme.video",
            "抖音精选",
            extraSuccess = listOf("抖音月付还款", "月付还款", "还款成功"),
            extraMerchantLabels = listOf("商户", "商品", "订单")
        ),
        genericProfile(
            "com.taobao.taobao",
            "淘宝",
            extraSuccess = listOf("免密支付成功") + orderSuccessKeywords,
            extraAmountLabels = listOf("实付价", "合计", "合计:", "订单合计", "应付金额", "优惠后金额"),
            extraMerchantLabels = listOf("店铺", "店名", "商家", "商品", "商品名称", "订单"),
            classWhitelist = taobaoClassWhitelist
        ),
        genericProfile(
            "com.alibaba.wireless",
            "阿里巴巴",
            extraSuccess = listOf("下单成功", "支付成功"),
            extraAmountLabels = listOf("实付", "实付价", "合计", "订单合计", "应付金额"),
            extraMerchantLabels = listOf("店铺", "商家", "商品", "订单"),
            classWhitelist = alibabaClassWhitelist
        ),
        genericProfile(
            "com.taobao.idlefish",
            "闲鱼",
            extraSuccess = listOf("交易成功", "支付成功", "已支付"),
            extraAmountLabels = listOf("实付", "合计", "应付金额"),
            extraMerchantLabels = listOf("卖家", "买家", "商家", "商品", "订单"),
            classWhitelist = idlefishClassWhitelist
        ),
        genericProfile(
            "com.wudaokou.hippo",
            "盒马",
            extraSuccess = orderSuccessKeywords,
            extraAmountLabels = listOf("实付", "合计", "订单合计", "应付金额"),
            extraMerchantLabels = listOf("商家", "店名", "商户", "商品", "订单"),
            classWhitelist = hemaClassWhitelist
        ),
        genericProfile(
            "me.ele",
            "饿了么",
            extraSuccess = orderSuccessKeywords,
            extraAmountLabels = listOf("实付", "合计", "订单合计", "应付金额"),
            extraMerchantLabels = listOf("商家", "店名", "商户", "商品", "订单"),
            classWhitelist = elemeClassWhitelist
        ),
        genericProfile(
            "com.huawei.wallet",
            "华为钱包",
            extraSuccess = listOf("支付成功", "交易成功", "付款成功"),
            extraMerchantLabels = listOf("商户", "商品", "交易对象")
        ),
        genericProfile(
            "com.ccb.longjiLife",
            "建行生活",
            extraSuccess = listOf("支付成功", "交易成功", "付款成功"),
            extraMerchantLabels = listOf("商户", "商品", "交易对象"),
            classWhitelist = ccbClassWhitelist
        ),
        genericProfile(
            "com.smile.gifmaker",
            "快手",
            extraSuccess = listOf("支付成功", "交易成功", "付款成功"),
            extraMerchantLabels = listOf("商户", "商品", "订单"),
            classWhitelist = kuaishouClassWhitelist
        ),
        genericProfile(
            "com.kuaishou.nebula",
            "快手极速版",
            extraSuccess = listOf("支付成功", "交易成功", "付款成功"),
            extraMerchantLabels = listOf("商户", "商品", "订单"),
            classWhitelist = kuaishouClassWhitelist
        )
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
        "交易完成",
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
        "支付金额",
        "实付金额",
        "收款金额",
        "转账金额",
        "支付时间",
        "交易时间",
        "收款时间",
        "转账时间",
        "退款时间",
        "到账时间",
        "到账银行卡",
        "到账账户",
        "收款账户",
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
        "实付金额",
        "支付金额",
        "转账金额",
        "到账金额",
        "支付时间",
        "交易时间",
        "收款时间",
        "转账时间",
        "退款时间",
        "到账时间",
        "转账到",
        "订单号",
        "商家订单号",
        "商品说明",
        "转账说明",
        "处理进度",
        "账单管理",
        "账单分类",
        "交易分类",
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

    private val genericDetailKeywords = listOf(
        "订单号",
        "商家订单号",
        "交易号",
        "流水号",
        "交易详情",
        "账单详情",
        "订单详情",
        "支付时间",
        "交易时间",
        "创建时间",
        "付款方式",
        "支付方式"
    )

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
        val ordered = normalizeTokensOrdered(tokens)
        if (ordered.isEmpty()) return
        val cleaned = normalizeTokens(tokens)
        if (cleaned.isEmpty()) return

        if (shouldSkipDuplicate(packageName, cleaned)) return

        val className = event.className?.toString()
        if (!shouldCheck(className, profile, cleaned)) return

        val result = when (packageName) {
            wechatPackage -> parseWeChat(ordered, cleaned)
            alipayPackage -> parseAlipay(ordered, cleaned)
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

    private fun normalizeTokensOrdered(tokens: List<String>): List<String> {
        val ordered = ArrayList<String>()
        for (token in tokens) {
            val trimmed = token.trim()
            if (trimmed.isEmpty()) continue
            if (ordered.size >= 260) break
            ordered.add(trimmed)
        }
        return ordered
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
        val metadataJson: String?,
        val timestamp: Long
    )

    private data class ParsedAuto(
        val amount: Double,
        val remark: String,
        val income: Boolean = false,
        val transfer: Boolean = false,
        val asset: String? = null,
        val fromAsset: String? = null,
        val toAsset: String? = null,
        val discount: Double? = null,
        val serviceFee: Double? = null,
        val categoryHint: String? = null
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

    private fun genericProfile(
        packageName: String,
        displayName: String,
        extraSuccess: List<String> = emptyList(),
        extraAmountLabels: List<String> = emptyList(),
        extraMerchantLabels: List<String> = emptyList(),
        classWhitelist: Set<String> = emptySet()
    ): AppProfile {
        return AppProfile(
            packageName = packageName,
            displayName = displayName,
            successKeywords = listOf(
                "支付成功", "交易成功", "付款成功", "已支付", "支付完成", "交易完成", "订单完成",
                "转账成功", "收款成功", "退款成功", "已收款", "资金待入账"
            ) + extraSuccess,
            amountLabels = listOf(
                "实付金额", "支付金额", "付款金额", "交易金额", "收款金额", "转账金额", "订单金额",
                "支出金额", "收入金额", "退款金额"
            ) + extraAmountLabels,
            merchantLabels = listOf(
                "收款方", "商户", "商品", "商品名称", "交易对象", "对方账户", "收款人"
            ) + extraMerchantLabels,
            classWhitelist = classWhitelist
        )
    }

    private fun parseWeChat(tokens: List<String>, normalized: List<String>): ParseResult? {
        val yimuParsed = parseWeChatYimu(tokens)
        if (yimuParsed != null) {
            return buildParseResultFromParsed("WeChat", tokens, yimuParsed)
        }

        if (!containsAny(normalized, wechatSuccessKeywords) && !containsAny(normalized, redPacketKeywords)) return null
        if (normalized.any { it.contains("当前状态") } &&
            normalized.none { it.contains("支付成功") || it.contains("付款成功") }
        ) {
            return null
        }
        val wechatListLike = looksLikeMultiTransactionList(normalized)
        if (wechatListLike && !containsAny(normalized, wechatDetailFields)) return null

        val amount = extractAmount(tokens, requireCurrency = true, labels = listOf(
            "支付金额",
            "实付金额",
            "实付款",
            "实收金额",
            "收款金额",
            "交易金额",
            "付款金额",
            "转账金额",
            "退款金额",
            "红包金额"
        ))
            ?: run {
                Log.w(logTag, "WeChat success hit but no amount. tokens=${sampleTokens(normalized)}")
                return null
            }

        val redPacketType = detectRedPacketType(normalized)
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

        var type = redPacketType ?: inferType(normalized, defaultType = "expense")
        val hasIncomeHint = normalized.any {
            it.contains("+") || it.contains("收入") || it.contains("已收款") || it.contains("你已收款")
        }
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
        val fromAsset = extractValueAfterAnchor(
            tokens,
            anchors = listOf(
                "付款方式",
                "支付方式",
                "支付渠道",
                "转出方式",
                "付款卡",
                "扣款卡",
                "扣款方式",
                "支付账户",
                "付款账户",
                "付款账号",
                "付款银行卡",
                "扣款银行卡",
                "充值方式"
            )
        )
        val assetFromPriority = extractValueBeforeAnchor(
            tokens,
            anchors = listOf("优先使用此支付方式付款", "优先使用此付款方式", "优先付款方式")
        )
        val toAsset = extractValueAfterAnchor(
            tokens,
            anchors = listOf(
                "到账银行卡",
                "到账卡",
                "收款银行卡",
                "收款卡",
                "收款账户",
                "收款方账户",
                "转入方式",
                "转入账户",
                "入账方式",
                "入账账户",
                "到账账户"
            )
        )
        val serviceFee = extractAmountAfterAnchor(tokens, anchors = listOf("服务费", "手续费"))
        val resolvedFromAsset = fromAsset ?: assetFromPriority
        val metadataJson = buildMetadataJson(
            mapOf(
                "asset" to resolvedFromAsset,
                "from_asset" to resolvedFromAsset,
                "to_asset" to toAsset,
                "service_fee" to serviceFee?.toString()
            )
        )

        Log.i(logTag, "WeChat parsed amount=$amount remark=$remark type=$type")
        val rawText = buildRawText(normalized, remark)
        return ParseResult(
            source = "WeChat",
            amount = amount,
            remark = remark,
            type = type,
            rawText = rawText,
            metadataJson = metadataJson,
            timestamp = System.currentTimeMillis()
        )
    }

    private fun parseAlipay(tokens: List<String>, normalized: List<String>): ParseResult? {
        val yimuParsed = parseAlipayYimu(tokens)
        if (yimuParsed != null) {
            return buildParseResultFromParsed("Alipay", tokens, yimuParsed)
        }

        if (isAlipayBillList(tokens)) return null
        val hasSuccess = containsAny(normalized, alipaySuccessKeywords) || containsAny(normalized, redPacketKeywords)
        val hasDetail = containsAny(normalized, alipayDetailKeywords)
        val hasDetailFields = containsAny(normalized, alipayDetailFields)
        if (!hasSuccess && !hasDetail && !hasDetailFields) return null
        if (isAlipayListLike(normalized)) return null
        if (containsAny(normalized, processingKeywords) && !hasSuccess) return null
        val listLike = isAlipayListLike(normalized) || looksLikeMultiTransactionList(normalized)
        if (listLike && !hasDetailFields) return null

        val refundAnchors = listOf("退款金额", "到账金额", "退款成功", "退回成功")
        val payAnchors = listOf("实付金额", "实付款", "实收金额", "支付金额", "付款金额", "交易金额", "实付")
        val orderAnchors = listOf("订单金额", "商品金额", "订单合计", "合计", "应付金额", "总金额")
        val refundAmount = extractAmountAfterAnchor(tokens, refundAnchors)
        val payAmount = extractAmountAfterAnchor(tokens, payAnchors)
        val orderAmount = extractAmountAfterAnchor(tokens, orderAnchors)

        val amountTokens = tokens.filterNot { token ->
            alipayNoiseAmountKeywords.any { keyword -> token.contains(keyword) }
        }
        val labeledAmount = extractAmount(amountTokens, requireCurrency = false, labels = listOf(
            "实付金额",
            "实付款",
            "实际付款",
            "实收金额",
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
            "总金额",
            "应付金额",
            "优惠后金额",
            "退款金额",
            "收入金额",
            "支出金额"
        ))
        val anchoredAmount = extractAmountNearAnchors(amountTokens, alipayAmountAnchors, window = 3)
        val successAmount = extractAmountBeforeMarkers(amountTokens, alipayAmountAnchors, maxLookbehind = 2)
        val preferredFallback = extractPreferredAmount(amountTokens)
        val amount = refundAmount
            ?: payAmount
            ?: successAmount
            ?: anchoredAmount
            ?: labeledAmount
            ?: orderAmount
            ?: preferredFallback
            ?: run {
            if (listLike) return null
            Log.w(logTag, "Alipay success hit but no anchored amount. tokens=${sampleTokens(normalized)}")
            return null
        }
        if (listLike && labeledAmount == null && anchoredAmount == null) {
            Log.w(logTag, "Alipay list-like without anchored amount, skip. tokens=${sampleTokens(normalized)}")
            return null
        }

        val redPacketType = detectRedPacketType(normalized)
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

        var type = redPacketType ?: inferType(normalized, defaultType = "expense")
        val hasIncomeHint = refundAmount != null ||
            normalized.any { it.contains("+") || it.contains("收入") || it.contains("已收款") || it.contains("收款成功") || it.contains("退款成功") || it.contains("退回成功") }
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
        val fromAsset = extractValueAfterAnchor(
            tokens,
            anchors = listOf(
                "付款方式",
                "支付方式",
                "支付渠道",
                "转出方式",
                "付款卡",
                "扣款卡",
                "扣款方式",
                "支付账户",
                "付款账户",
                "付款账号",
                "付款银行卡",
                "扣款银行卡",
                "充值方式"
            )
        )
        val toAsset = extractValueAfterAnchor(
            tokens,
            anchors = listOf(
                "到账银行卡",
                "到账卡",
                "收款银行卡",
                "收款卡",
                "收款账户",
                "收款方账户",
                "转入方式",
                "转入账户",
                "入账方式",
                "入账账户",
                "到账账户"
            )
        )
        val categoryHint = extractValueAfterAnchor(tokens, anchors = listOf("账单分类", "交易分类"))
        val serviceFee = extractAmountAfterAnchor(tokens, anchors = listOf("服务费", "手续费"))
        val orderId = extractOrderId(tokens)
        val detailTime = extractDetailTime(tokens)
        val resolvedFromAsset = fromAsset
        val metadataJson = buildMetadataJson(
            mapOf(
                "asset" to resolvedFromAsset,
                "from_asset" to resolvedFromAsset,
                "to_asset" to toAsset,
                "category_hint" to categoryHint,
                "service_fee" to serviceFee?.toString(),
                "order_id" to orderId,
                "detail_time" to detailTime
            )
        )

        Log.i(logTag, "Alipay parsed amount=$amount remark=$remark type=$type")
        val rawText = buildRawText(normalized, remark)
        return ParseResult(
            source = "Alipay",
            amount = amount,
            remark = remark,
            type = type,
            rawText = rawText,
            metadataJson = metadataJson,
            timestamp = System.currentTimeMillis()
        )
    }

    private fun buildParseResultFromParsed(
        source: String,
        tokens: List<String>,
        parsed: ParsedAuto
    ): ParseResult {
        val type = when {
            parsed.transfer -> "transfer"
            parsed.income -> "income"
            else -> "expense"
        }
        val metadataJson = buildMetadataJson(
            mapOf(
                "asset" to parsed.asset,
                "from_asset" to parsed.fromAsset,
                "to_asset" to parsed.toAsset,
                "discount" to parsed.discount?.toString(),
                "service_fee" to parsed.serviceFee?.toString(),
                "category_hint" to parsed.categoryHint,
                "order_id" to extractOrderId(tokens),
                "detail_time" to extractDetailTime(tokens)
            )
        )
        val rawText = buildRawText(tokens, parsed.remark)
        return ParseResult(
            source = source,
            amount = parsed.amount,
            remark = parsed.remark,
            type = type,
            rawText = rawText,
            metadataJson = metadataJson,
            timestamp = System.currentTimeMillis()
        )
    }

    private fun parseAmountToken(token: String): Double? {
        return extractAmountFromToken(token, requireCurrency = false) ?: extractPlainAmount(token)
    }

    private fun normalizeWeChatAsset(asset: String?): String? {
        if (asset == null) return null
        val trimmed = asset.trim()
        if (trimmed == "零钱") return "微信钱包"
        return trimmed
    }

    private fun normalizeAlipayAsset(asset: String?): String? {
        if (asset == null) return null
        val trimmed = asset.trim()
        if (trimmed == "账户余额" || trimmed == "余额" || trimmed == "可用余额") return "支付宝"
        return trimmed
    }

    private fun parseWeChatYimu(tokens: List<String>): ParsedAuto? {
        val hasMarker = containsAny(tokens, wechatSuccessKeywords) ||
            containsAny(tokens, wechatDetailFields) ||
            containsAny(tokens, redPacketKeywords) ||
            tokens.any { token ->
                token.contains("零钱提现") ||
                    token.contains("零钱充值") ||
                    token.contains("转入零钱通") ||
                    token.contains("转出金额") ||
                    token.contains("充值成功") ||
                    token.contains("已转入") ||
                    token.contains("已转出")
            }
        if (!hasMarker) return null
        if (tokens.any { it.contains("当前状态") } &&
            tokens.none { it.contains("支付成功") || it.contains("付款成功") }
        ) {
            return null
        }
        if (looksLikeMultiTransactionList(tokens) && !containsAny(tokens, wechatDetailFields)) {
            return null
        }

        val paymentAsset = extractWeChatPaymentAsset(tokens)
        val transferAsset = extractWeChatTransferAsset(tokens)
        val hasRedPacket = tokens.any { token ->
            token.contains("红包金额") || token.contains("个红包共") || token.contains("人已领取") ||
                token.contains("的红包") || token.contains("红包")
        }
        if (hasRedPacket) {
            parseWeChatRedPacketSend(tokens)?.let { return it }
            parseWeChatRedPacketReceive(tokens)?.let { return it }
        }

        val hasIncome = tokens.any { token ->
            token.contains("已收款") || token.contains("你已收款") || token.contains("资金待入账")
        }
        if (hasIncome) {
            parseWeChatReceive(tokens)?.let { return it }
        }

        val hasTransfer = tokens.any { token ->
            token.contains("零钱提现") || token.contains("零钱充值") || token.contains("转入零钱通") ||
                token.contains("充值成功") || token.contains("已转入") || token.contains("已转出") ||
                token.contains("转出金额") || token.contains("提现金额") || token.contains("转出说明")
        }
        if (hasTransfer) {
            parseWeChatTransferZ(tokens, transferAsset)?.let { return it }
            parseWeChatTransferA(tokens)?.let { return it }
        }

        val hasPaySuccess = tokens.any { token -> token == "支付成功" || token == "付款成功" } &&
            tokens.none { token -> token.contains("当前状态") }
        if (hasPaySuccess) {
            parseWeChatPay(tokens, paymentAsset)?.let { return it }
        }

        parseWeChatList(tokens)?.let { return it }
        return parseWeChatStatus(tokens)
    }

    private fun extractWeChatPaymentAsset(tokens: List<String>): String? {
        val idx = tokens.indexOf("付款方式")
        if (idx >= 0 && idx < tokens.size - 1) {
            var candidate = tokens[idx + 1]
            if (candidate == "更改" && idx + 2 < tokens.size) {
                candidate = tokens[idx + 2]
                if (candidate == "更改" && idx + 3 < tokens.size) {
                    candidate = tokens[idx + 3]
                }
            }
            return normalizeWeChatAsset(candidate)
        }
        val priorityPay = listOf("优先使用此支付方式付款", "优先使用此付款方式")
        for (anchor in priorityPay) {
            val pos = tokens.indexOf(anchor)
            if (pos > 0) return normalizeWeChatAsset(tokens[pos - 1])
        }
        val priority = tokens.indexOf("优先付款方式")
        if (priority >= 0 && priority < tokens.size - 1) {
            var candidate = tokens[priority + 1]
            if (candidate == "更改" && priority + 2 < tokens.size) {
                candidate = tokens[priority + 2]
            }
            return normalizeWeChatAsset(candidate)
        }
        return null
    }

    private fun extractWeChatTransferAsset(tokens: List<String>): String? {
        val rechargeIdx = tokens.indexOf("充值方式")
        if (rechargeIdx >= 0 && rechargeIdx < tokens.size - 1) {
            return normalizeWeChatAsset(tokens[rechargeIdx + 1])
        }
        val bankIdx = tokens.indexOf("到账银行卡")
        if (bankIdx >= 0 && bankIdx < tokens.size - 1) {
            return normalizeWeChatAsset(tokens[bankIdx + 1])
        }
        return null
    }

    private fun parseWeChatPay(tokens: List<String>, paymentAsset: String?): ParsedAuto? {
        var amount: Double? = null
        var remark: String? = null
        var discount: Double? = null
        var income = false
        var transfer = false

        for (i in tokens.indices) {
            val token = tokens[i]
            if ((token == "¥" || token == "￥") && i + 1 < tokens.size && amount == null) {
                amount = parseAmountToken(tokens[i + 1])
            }
            if (amount == null && (token.contains("¥") || token.contains("￥"))) {
                amount = parseAmountToken(token) ?: amount
            }
            if (token == "优惠" && i + 1 < tokens.size && discount == null) {
                val next = tokens[i + 1]
                val inline = if (next.contains("￥") || next.contains("¥")) next else ""
                discount = parseAmountToken(inline.ifEmpty { next })
            }
            if (token == "收款方" && i + 1 < tokens.size) {
                remark = tokens[i + 1]
            }
            if ((token == "支付成功" || token == "付款成功") && i + 1 < tokens.size) {
                val next = tokens[i + 1]
                if (!next.contains("¥") && !next.contains("￥")) {
                    remark = next
                    val candidate = remark
                    if (candidate != null &&
                        candidate.startsWith("待") &&
                        candidate.endsWith("确认收款") &&
                        candidate.length > 4
                    ) {
                        remark = "转账给${candidate.substring(1, candidate.length - 4)}"
                        transfer = true
                    }
                }
            }
            if (token == "保存收款码") {
                income = true
            }
            if (income && remark == null && amount != null && i > 0 && (token.contains("¥") || token.contains("￥"))) {
                remark = tokens[i - 1]
            }
        }
        val asset = normalizeWeChatAsset(paymentAsset)
        val finalRemark = remark?.takeIf { it.isNotBlank() } ?: return null
        if (amount == null) return null
        if (finalRemark.contains("转账")) transfer = true
        return ParsedAuto(
            amount = amount,
            remark = finalRemark,
            income = income,
            transfer = transfer,
            asset = asset,
            discount = discount
        )
    }

    private fun parseWeChatList(tokens: List<String>): ParsedAuto? {
        var amount: Double? = null
        var remark: String? = null
        var income = false
        var transfer = false
        var fromAsset: String? = null
        var toAsset: String? = null

        for (i in tokens.indices) {
            val token = tokens[i]
            if (token.contains(",支出") && token.contains("元")) {
                val num = token.substring(token.indexOf(",支出") + 3, token.length - 1).replace(",", "")
                val value = parseAmountToken(num)
                if (value != null) {
                    amount = value
                    remark = token.substring(0, token.indexOf(",支出"))
                    income = false
                }
            } else if (token.contains(",收入") && token.contains("元")) {
                val num = token.substring(token.indexOf(",收入") + 3, token.length - 1).replace(",", "")
                val value = parseAmountToken(num)
                if (value != null) {
                    amount = value
                    remark = token.substring(0, token.indexOf(",收入"))
                    income = true
                }
            } else if (token.contains("零钱通转出-到") && i < tokens.size - 1) {
                val candidate = if (token.contains("支出¥")) token else tokens[i + 1]
                if (candidate.contains("支出¥")) {
                    val num = candidate.substring(candidate.indexOf("支出¥") + 3).replace(",", "")
                    val value = parseAmountToken(num)
                    if (value != null) {
                        amount = value
                        remark = "零钱通转出"
                        transfer = true
                        fromAsset = "零钱通"
                        toAsset = "微信零钱"
                    }
                }
            } else if (token.contains("信用卡还款-") && i < tokens.size - 1) {
                val num = tokens[i + 1]
                val value = parseAmountToken(num)
                if (value != null) {
                    amount = value
                    remark = "信用卡还款"
                    transfer = true
                    fromAsset = "零钱通"
                    toAsset = token.replace("信用卡还款-", "").replace("还款", "")
                }
            } else if (amount == null && token.contains("收入¥")) {
                val num = token.substring(token.indexOf("收入¥") + 3).replace(",", "")
                val value = parseAmountToken(num)
                if (value != null) {
                    amount = value
                    income = true
                    remark = token.substring(0, token.indexOf("收入¥"))
                }
            } else if (amount == null && (token.contains("¥") || token.contains("￥") || token.contains("+"))) {
                val value = parseAmountToken(token)
                if (value != null && value > 0) {
                    amount = value
                    if (i > 0) {
                        remark = tokens[i - 1]
                    }
                    if (token.contains("+")) {
                        income = true
                    }
                }
            }
            if (amount != null && !remark.isNullOrBlank()) break
        }
        if (amount == null) return null
        val finalRemark = remark?.takeIf { it.isNotBlank() } ?: return null
        return ParsedAuto(
            amount = amount,
            remark = finalRemark,
            income = income,
            transfer = transfer,
            fromAsset = normalizeWeChatAsset(fromAsset),
            toAsset = normalizeWeChatAsset(toAsset)
        )
    }

    private fun parseWeChatStatus(tokens: List<String>): ParsedAuto? {
        var amount: Double? = null
        var remark: String? = null
        var income = false
        for (i in tokens.indices) {
            val token = tokens[i]
            if (token.contains("已收到¥")) {
                val num = token.replace("已收到¥", "").replace(",", "")
                val value = parseAmountToken(num)
                if (value != null) {
                    amount = value
                    income = true
                    if (i > 0) remark = tokens[i - 1]
                }
            } else if (token.contains("已支付¥") && !tokens.contains("你需支付")) {
                val num = token.replace("已支付¥", "").replace(",", "")
                val value = parseAmountToken(num)
                if (value != null) {
                    amount = value
                    income = false
                    if (i > 0) remark = tokens[i - 1]
                }
            } else if (token.contains("收到¥")) {
                val num = token.replace("收到¥", "").replace(",", "")
                val value = parseAmountToken(num)
                if (value != null) {
                    amount = value
                    income = true
                }
            } else if (token.contains("已收齐") && i > 0) {
                remark = tokens[i - 1]
            }
            if (amount != null) break
        }
        if (amount == null) return null
        val finalRemark = remark?.takeIf { it.isNotBlank() } ?: return null
        return ParsedAuto(amount = amount, remark = finalRemark, income = income)
    }

    private fun parseWeChatReceive(tokens: List<String>): ParsedAuto? {
        var amount: Double? = null
        var remark: String? = null
        var income = false
        for (i in tokens.indices) {
            val token = tokens[i]
            if ((token.contains("已收款") || token.contains("你已收款")) && i < tokens.size - 1) {
                val num = tokens[i + 1].replace("￥", "").replace("¥", "").replace("元", "").replace(",", "")
                val value = parseAmountToken(num)
                if (value != null) {
                    amount = value
                }
                if (token.contains("你已收款")) {
                    income = true
                }
            } else if (token == "转账说明" && i < tokens.size - 1) {
                remark = tokens[i + 1]
            }
        }
        if (amount == null) return null
        val finalRemark = remark?.takeIf { it.isNotBlank() } ?: if (income) "微信收款" else "微信转账"
        return ParsedAuto(amount = amount, remark = finalRemark, income = income, transfer = !income)
    }

    private fun parseWeChatTransferA(tokens: List<String>): ParsedAuto? {
        var amount: Double? = null
        var remark: String? = null
        var income = false
        var fromAsset: String? = null
        var toAsset: String? = null
        var serviceFee: Double? = null
        if (tokens.any { it.contains("零钱提现") }) {
            fromAsset = "微信钱包"
        } else if (tokens.any { it.contains("零钱充值") }) {
            toAsset = "微信钱包"
        } else if (tokens.any { it.contains("转入零钱通") }) {
            toAsset = "零钱通"
        }
        for (i in tokens.indices) {
            val token = tokens[i]
            if (token == "提现金额" && i < tokens.size - 1) {
                val num = tokens[i + 1].replace("¥", "").replace("￥", "").replace(",", "")
                val value = parseAmountToken(num)
                if (amount == null && value != null) {
                    amount = value
                }
            } else if (token == "服务费" && i < tokens.size - 1) {
                val num = tokens[i + 1].replace("¥", "").replace("￥", "").replace(",", "")
                serviceFee = parseAmountToken(num)
            } else if (amount == null && token.contains("收入¥")) {
                val num = token.substring(token.indexOf("收入¥") + 3).replace(",", "")
                val value = parseAmountToken(num)
                if (value != null) {
                    amount = value
                    income = true
                    remark = token.substring(0, token.indexOf("收入¥"))
                }
            } else if (amount == null && i < tokens.size - 1 && tokens[i + 1] == "当前状态") {
                val value = parseAmountToken(token.replace(",", ""))
                if (value != null) {
                    amount = value
                    if (i > 0) remark = tokens[i - 1]
                }
            } else if (token.contains("转入方式")) {
                fromAsset = token.replace("转入方式", "").trim()
            } else if (token == "提现银行" && i < tokens.size - 1) {
                toAsset = tokens[i + 1]
            } else if (token == "支付方式" && i < tokens.size - 1) {
                fromAsset = tokens[i + 1]
            } else if (token.contains(",") && token.contains("元")) {
                val num = token.substring(token.lastIndexOf(",") + 1, token.length - 1)
                val value = parseAmountToken(num)
                if (value != null) {
                    amount = value
                }
            } else if (token.contains("零钱充值-") && i < tokens.size - 1) {
                val num = tokens[i + 1].replace("元", "").replace(",", "")
                val value = parseAmountToken(num)
                if (amount == null && value != null) {
                    amount = value
                }
            } else if (token.contains("转入零钱通-") && i < tokens.size - 1) {
                val num = tokens[i + 1].replace("元", "").replace(",", "")
                val value = parseAmountToken(num)
                if (amount == null && value != null) {
                    amount = value
                }
            }
        }
        if (amount == null) return null
        if (remark.isNullOrBlank()) {
            remark = "微信转账"
        }
        return ParsedAuto(
            amount = amount,
            remark = remark,
            income = income,
            transfer = true,
            fromAsset = normalizeWeChatAsset(fromAsset),
            toAsset = normalizeWeChatAsset(toAsset),
            serviceFee = serviceFee
        )
    }

    private fun parseWeChatTransferZ(tokens: List<String>, method: String?): ParsedAuto? {
        var amount: Double? = null
        var fromAsset: String? = null
        var toAsset: String? = null
        var serviceFee: Double? = null
        if (tokens.any { it.contains("充值成功") }) {
            fromAsset = method
            toAsset = "微信钱包"
        } else if (tokens.any { it.contains("已转入") }) {
            fromAsset = "微信钱包"
            toAsset = "零钱通"
        } else if (tokens.any { it.contains("已转出") }) {
            fromAsset = "零钱通"
            toAsset = "微信钱包"
        } else if (tokens.any { it.contains("零钱提现") }) {
            fromAsset = "微信钱包"
            toAsset = method
        } else if (tokens.any { it.contains("转出金额") }) {
            fromAsset = "零钱通"
            toAsset = method
        }
        for (i in tokens.indices) {
            val token = tokens[i]
            if ((token == "充值成功" || token == "提现金额" || token == "转入成功") && i < tokens.size - 1) {
                val num = tokens[i + 1].replace("¥", "").replace("￥", "").replace(",", "")
                val value = parseAmountToken(num)
                if (amount == null && value != null) {
                    amount = value
                }
            } else if (token == "已转入" && i < tokens.size - 2) {
                val num = tokens[i + 2].replace("¥", "").replace("￥", "").replace(",", "")
                val value = parseAmountToken(num)
                if (amount == null && value != null) {
                    amount = value
                }
            } else if (token == "已转出" && i < tokens.size - 2) {
                val num = tokens[i + 2].replace("¥", "").replace("￥", "").replace(",", "")
                val value = parseAmountToken(num)
                if (amount == null && value != null) {
                    amount = value
                }
            } else if (token == "转出金额" && i < tokens.size - 1) {
                val num = tokens[i + 1].replace("¥", "").replace("￥", "").replace(",", "")
                val value = parseAmountToken(num)
                if (amount == null && value != null) {
                    amount = value
                }
            } else if (token == "服务费" && i < tokens.size - 1) {
                val num = tokens[i + 1].replace("¥", "").replace("￥", "").replace(",", "")
                serviceFee = parseAmountToken(num)
            }
        }
        if (amount == null) return null
        return ParsedAuto(
            amount = amount,
            remark = "微信转账",
            transfer = true,
            fromAsset = normalizeWeChatAsset(fromAsset),
            toAsset = normalizeWeChatAsset(toAsset),
            serviceFee = serviceFee
        )
    }

    private fun parseWeChatRedPacketSend(tokens: List<String>): ParsedAuto? {
        for (token in tokens) {
            if (token.contains("红包金额")) {
                val idx = token.indexOf("元")
                if (idx > 4) {
                    val num = token.substring(0, idx).replace("红包金额", "").replace(",", "")
                    val value = parseAmountToken(num)
                    if (value != null) return ParsedAuto(value, "发送微信红包", transfer = false)
                }
            } else if (token.contains("个红包共")) {
                val idx = token.indexOf("元")
                if (idx > 4) {
                    val num = token.substring(token.indexOf("个红包共") + 4, idx).replace(",", "")
                    val value = parseAmountToken(num)
                    if (value != null) return ParsedAuto(value, "发送微信红包", transfer = false)
                }
            } else if (token.contains("人已领取")) {
                val idx = token.indexOf("元")
                if (idx > 4) {
                    val num = token.substring(token.indexOf("人已领取") + 6, idx).replace(",", "")
                    val value = parseAmountToken(num)
                    if (value != null) return ParsedAuto(value, "发送微信红包", transfer = false)
                }
            } else if (token.contains("个，共") && token.contains("元")) {
                val idx = token.indexOf("元")
                if (idx > 4 && token.contains("/")) {
                    val num = token.substring(token.lastIndexOf("/") + 1, idx).replace(",", "")
                    val value = parseAmountToken(num)
                    if (value != null) return ParsedAuto(value, "发送微信红包", transfer = false)
                }
            }
        }
        return null
    }

    private fun parseWeChatRedPacketReceive(tokens: List<String>): ParsedAuto? {
        for (i in tokens.indices) {
            val token = tokens[i]
            val num = token.replace("元", "").replace(",", "")
            val value = parseAmountToken(num) ?: continue
            if (token.contains("元")) {
                if (i > 1 && tokens[i - 2].contains("的红包")) {
                    val remark = tokens[i - 2]
                    return ParsedAuto(value, remark, income = true)
                }
                if (i > 0 && tokens[i - 1].contains("的红包")) {
                    val remark = tokens[i - 1]
                    return ParsedAuto(value, remark, income = true)
                }
            }
        }
        return null
    }

    private fun parseAlipayYimu(tokens: List<String>): ParsedAuto? {
        val hasMarker = containsAny(tokens, alipaySuccessKeywords) ||
            containsAny(tokens, alipayDetailKeywords) ||
            containsAny(tokens, alipayDetailFields)
        if (!hasMarker) return null
        if (isAlipayBillList(tokens)) return null
        if (containsAny(tokens, processingKeywords) && !containsAny(tokens, alipaySuccessKeywords)) {
            return null
        }
        val listLike = isAlipayListLike(tokens) || looksLikeMultiTransactionList(tokens)
        if (listLike && !containsAny(tokens, alipayDetailFields)) {
            return null
        }

        val hasRedPacket = tokens.any { token ->
            token.contains("红包金额") || token.contains("个红包共") || token.contains("已领取") || token.contains("红包")
        }
        if (hasRedPacket) {
            parseAlipayRedPacketSend(tokens)?.let { return it }
            parseAlipayRedPacketReceive(tokens)?.let { return it }
        }

        if (tokens.any { it.contains("转账成功") }) {
            parseAlipayTransferV(tokens)?.let { return it }
        }

        if (tokens.any { it.contains("还款信用卡") }) {
            parseAlipayCreditRepay(tokens)?.let { return it }
        }

        val transferKeywords = listOf(
            "充值成功",
            "余额转入",
            "充值说明",
            "提现金额",
            "提现说明",
            "提现成功",
            "网商银行转账",
            "余额宝-单次转入",
            "余额宝-转出到余额",
            "开始计算收益",
            "转入成功",
            "转出成功",
            "转出说明",
            "到账银行卡",
            "提现到",
            "还款到",
            "到账账户",
            "转入账户",
            "还款成功",
            "花呗信用购",
            "信用卡还款",
            "还款信用卡"
        )
        if (tokens.any { token -> transferKeywords.any { keyword -> token.contains(keyword) } }) {
            parseAlipayTransferU(tokens)?.let { return it }
        }

        return parseAlipayPay(tokens)
    }

    private fun parseAlipayPay(tokens: List<String>): ParsedAuto? {
        var amount: Double? = null
        var remark: String? = null
        var asset: String? = null
        var income = false
        var discount: Double? = null
        val refundAnchors = listOf("退款金额", "到账金额", "退款成功", "退回成功")
        val payAnchors = listOf("实付金额", "实付款", "实收金额", "支付金额", "付款金额", "交易金额", "实付")
        val orderAnchors = listOf("订单金额", "商品金额", "订单合计", "合计", "应付金额", "总金额")
        val refundAmount = extractAmountAfterAnchor(tokens, refundAnchors)
        val payAmount = extractAmountAfterAnchor(tokens, payAnchors)
        val orderAmount = extractAmountAfterAnchor(tokens, orderAnchors)
        if (refundAmount != null) {
            income = true
        }
        if (payAmount != null && orderAmount != null && refundAmount == null) {
            discount = kotlin.math.abs(orderAmount - payAmount)
        }
        val successMarkers = listOf(
            "支付成功",
            "充值成功",
            "代付成功",
            "转账成功",
            "交易成功",
            "还款成功",
            "退款成功",
            "赔付成功",
            "派送中",
            "领取中",
            "退回成功",
            "免密支付成功",
            "自动续费成功",
            "收款成功"
        )
        val successAmount = extractAmountBeforeMarkers(tokens, successMarkers, maxLookbehind = 2)

        for (i in tokens.indices) {
            val token = tokens[i]
            if (token == "收款方" && i < tokens.size - 1) {
                remark = tokens[i + 1]
            } else if (token == "收款理由" && i < tokens.size - 1) {
                remark = tokens[i + 1].replaceFirst("收款理由", "")
            } else if ((token == "付款方式" || token == "付款信息" || token == "交易方式" || token == "退款方式") &&
                i < tokens.size - 1
            ) {
                var next = tokens[i + 1]
                if (next == "帮助" && i + 2 < tokens.size) {
                    next = tokens[i + 2]
                }
                asset = next
                if (!asset.isNullOrBlank() && asset.contains("亲情卡") && income) {
                    income = false
                }
            } else if (token == "商品说明" && i < tokens.size - 1) {
                remark = tokens[i + 1].replaceFirst("商品说明", "")
                if (remark.contains("余额宝") && remark.contains("收益发放")) {
                    asset = "余额宝"
                }
            } else if (token == "交易详情" && i + 2 < tokens.size) {
                val next = tokens[i + 1]
                if (next != "更多" && next != "推荐服务" && next != "服务推荐") {
                    remark = tokens[i + 2]
                }
            } else if (token == "缴费说明" && i < tokens.size - 1) {
                remark = tokens[i + 1].replaceFirst("缴费说明", "")
            } else if (token == "充值说明" && i < tokens.size - 1) {
                remark = tokens[i + 1].replaceFirst("充值说明", "")
            } else if (token == "付款备注" && i < tokens.size - 1) {
                remark = tokens[i + 1].replaceFirst("付款备注", "")
            } else if (token == "红包说明" && i < tokens.size - 1) {
                remark = tokens[i + 1].replaceFirst("红包说明", "")
            } else if (token == "理由" && i < tokens.size - 1) {
                remark = tokens[i + 1].replaceFirst("理由", "")
            } else if (token == "转账备注" && i < tokens.size - 1) {
                val next = tokens[i + 1]
                remark = if (next == "转账") {
                    if (income && remark != null) {
                        "收到${remark}转账"
                    } else if (remark != null) {
                        "转账给$remark"
                    } else {
                        "支付宝转账"
                    }
                } else {
                    next
                }
            } else if (discount == null && (token.startsWith("-￥") ||
                    token == "碰一下支付立减" || token == "支付宝随机立减" ||
                    token == "碰一下立减" || token == "碰一下共减" ||
                    token == "视频红包" || token == "优惠") && i < tokens.size - 1
            ) {
                var next = tokens[i + 1]
                if (next == "¥" && i + 2 < tokens.size) {
                    next = tokens[i + 2]
                }
                discount = parseAmountToken(next)
            }

            if (amount == null && (token.contains("￥") || token.contains("¥") || token.contains("+") || token.contains("支出"))) {
                if (i > 0 && orderAnchors.any { anchor -> tokens[i - 1].contains(anchor) }) {
                    continue
                }
                var num = token.replace("￥", "").replace("¥", "").replace(",", "").replace("+", "").replace("支出", "").replace("元", "")
                var value = parseAmountToken(num)
                if (value == null && i < tokens.size - 1) {
                    val next = tokens[i + 1]
                    num = next.replace("￥", "").replace("¥", "").replace(",", "").replace("+", "")
                    value = parseAmountToken(num)
                }
                if (value != null) {
                    amount = kotlin.math.abs(value)
                    if (token.contains("+")) {
                        income = true
                    }
                    if (remark.isNullOrBlank() && i > 0) {
                        remark = tokens[i - 1]
                    }
                }
            }

            if (token in successMarkers && i > 0) {
                val prev = tokens[i - 1].replace("￥", "").replace("¥", "").replace(",", "").replace("+", "").replace("元", "").replace("支出", "")
                val value = parseAmountToken(prev)
                if (value != null && amount == null) {
                    amount = kotlin.math.abs(value)
                    if (tokens[i - 1].contains("+") || (!tokens[i - 1].contains("支出") && token == "退回成功")) {
                        income = true
                    }
                    if (token.contains("扣款成功")) {
                        income = false
                    }
                    if (i > 1 && remark.isNullOrBlank()) {
                        remark = tokens[i - 2]
                    }
                    if (token == "退款成功" && !remark.isNullOrBlank()) {
                        remark = "退款-来自$remark"
                        income = true
                    }
                }
            }
        }

        if (amount == null) {
            val fallback = refundAmount
                ?: payAmount
                ?: successAmount
                ?: extractAmountNearAnchors(tokens, successMarkers, window = 2)
                ?: orderAmount
                ?: extractPreferredAmount(tokens)
            if (fallback != null) {
                amount = kotlin.math.abs(fallback)
            }
        }

        if (!income && tokens.any { token ->
            token.contains("退款成功") || token.contains("退回成功") || token.contains("退款金额") ||
                token.contains("收款成功") || token.contains("已收款") || token.contains("到账金额")
        }) {
            income = true
        }

        if (amount == null) return null
        val finalRemark = remark?.takeIf { it.isNotBlank() } ?: if (income) "支付宝收款" else "支付宝付款"
        val normalizedAsset = normalizeAlipayAsset(asset)
        return ParsedAuto(
            amount = amount,
            remark = finalRemark,
            income = income,
            transfer = false,
            asset = normalizedAsset,
            discount = discount
        )
    }

    private fun parseAlipayCreditRepay(tokens: List<String>): ParsedAuto? {
        var amount: Double? = null
        var toAsset: String? = null
        var fromAsset: String? = null
        for (i in tokens.indices) {
            val token = tokens[i]
            if (token == "实付金额" && i < tokens.size - 2) {
                val num = tokens[i + 2].replace("¥", "").replace(",", "").replace("支出", "").replace("元", "")
                amount = parseAmountToken(num)
            } else if (token == "还款信用卡" && i < tokens.size - 1) {
                val card = tokens[i + 1]
                val cleaned = if (card.contains("(") && card.contains(")")) {
                    card.substring(card.indexOf("(") + 1, card.lastIndexOf(")"))
                } else {
                    card
                }
                toAsset = cleaned.replace(" ", "")
            } else if ((token == "付款方式" || token == "扣款方式" || token == "扣款银行卡" || token == "扣款卡" || token == "支付方式") &&
                i < tokens.size - 1
            ) {
                fromAsset = tokens[i + 1]
            } else if (token == "还款成功" && i > 0 && amount == null) {
                val prev = tokens[i - 1].replace("¥", "").replace(",", "").replace("支出", "").replace("元", "")
                amount = parseAmountToken(prev)
            }
        }
        if (amount == null) return null
        return ParsedAuto(
            amount = amount,
            remark = "支付宝还款",
            transfer = true,
            fromAsset = normalizeAlipayAsset(fromAsset) ?: "支付宝",
            toAsset = normalizeAlipayAsset(toAsset ?: extractValueAfterAnchor(tokens, listOf("还款到")) ?: "花呗信用购")
        )
    }

    private fun parseAlipayTransferU(tokens: List<String>): ParsedAuto? {
        var amount: Double? = null
        var remark: String? = null
        var fromAsset: String? = null
        var toAsset: String? = null
        var serviceFee: Double? = null
        if (tokens.any { it.contains("充值成功") || it.contains("余额转入") || it.contains("充值说明") }) {
            toAsset = "支付宝"
        } else if (tokens.any { it.contains("提现金额") || it.contains("提现说明") || it.contains("提现成功") }) {
            fromAsset = "支付宝"
        } else if (tokens.any { it.contains("网商银行转账") }) {
            toAsset = "网商银行余利宝"
        } else if (tokens.any { it.contains("余额宝-单次转入") }) {
            toAsset = "余额宝"
        } else if (tokens.any { it.contains("余额宝-转出到余额") }) {
            fromAsset = "余额宝"
            toAsset = "支付宝"
        } else if (tokens.any { it.contains("开始计算收益") } && tokens.any { it.contains("转入成功") }) {
            toAsset = "余额宝"
        } else if (tokens.any { it.contains("转出成功") }) {
            fromAsset = "余额宝"
        }

        for (i in tokens.indices) {
            val token = tokens[i]
            if ((token == "付款方式" || token == "扣款方式" || token == "扣款银行卡" || token == "扣款卡" || token == "支付方式") &&
                i < tokens.size - 1
            ) {
                val candidate = tokens[i + 1]
                if (candidate != "帮助") {
                    fromAsset = candidate
                } else if (i + 2 < tokens.size) {
                    fromAsset = tokens[i + 2]
                }
            }
            if ((token == "充值成功" || token == "提现金额" || token == "转入成功") && i < tokens.size - 1) {
                val num = tokens[i + 1].replace("¥", "").replace(",", "").replace("支出", "").replace("元", "")
                val value = parseAmountToken(num)
                if (amount == null && value != null) {
                    amount = value
                }
            } else if (token.contains("提现金额¥")) {
                val num = token.replace("提现金额¥", "").replace(",", "").replace("支出", "").replace("元", "")
                val value = parseAmountToken(num)
                if (amount == null && value != null) {
                    amount = value
                }
            } else if (token == "转出成功" && i < tokens.size - 2 && tokens[i + 1] == "¥") {
                val value = parseAmountToken(tokens[i + 2])
                if (amount == null && value != null) {
                    amount = value
                }
            } else if (token.startsWith("成功转出") && token.contains("元至")) {
                val num = token.substring(token.indexOf("成功转出") + 4, token.indexOf("元至")).replace(",", "")
                val value = parseAmountToken(num)
                if (amount == null && value != null) {
                    amount = value
                }
                var to = token.substring(token.indexOf("元至") + 1).replace("。", "")
                if (to == "支付宝账户余额") {
                    to = "支付宝"
                }
                toAsset = to
            } else if ((token == "交易成功" || token == "还款成功") && i > 0) {
                val value = parseAmountToken(tokens[i - 1].replace("¥", "").replace(",", "").replace("支出", "").replace("元", ""))
                if (amount == null && value != null) {
                    amount = value
                }
            } else if (token.contains("成功转入")) {
                val num = token.replace("成功转入", "").replace(",", "").replace("元", "")
                val value = parseAmountToken(num)
                if (amount == null && value != null) {
                    amount = value
                }
            } else if ((token == "到账银行卡" || token == "提现到" || token == "还款到" || token == "到账账户") &&
                i < tokens.size - 1
            ) {
                toAsset = tokens[i + 1]
            } else if (token == "服务费" && i < tokens.size - 1) {
                val num = tokens[i + 1].replace("¥", "").replace(",", "")
                serviceFee = parseAmountToken(num)
            } else if ((token == "提现说明" || token == "转账备注" || token == "充值说明" || token == "商品说明") &&
                i < tokens.size - 1
            ) {
                remark = tokens[i + 1]
            } else if (token == "转出说明" && i < tokens.size - 1) {
                val next = tokens[i + 1]
                if (next.contains("转出到")) {
                    val parts = next.split("转出到")
                    if (parts.size == 2) {
                        fromAsset = parts[0].replace("转出说明", "")
                        toAsset = parts[1]
                    }
                }
            } else if (token == "转入账户" && i < tokens.size - 1) {
                toAsset = tokens[i + 1]
            }
        }
        if (amount == null) return null
        val finalRemark = remark?.takeIf { it.isNotBlank() } ?: "支付宝转账"
        return ParsedAuto(
            amount = amount,
            remark = finalRemark,
            transfer = true,
            fromAsset = normalizeAlipayAsset(fromAsset),
            toAsset = normalizeAlipayAsset(toAsset),
            serviceFee = serviceFee
        )
    }

    private fun parseAlipayTransferV(tokens: List<String>): ParsedAuto? {
        var amount: Double? = null
        var remark: String? = null
        var asset: String? = null
        for (i in tokens.indices) {
            val token = tokens[i]
            if (token == "收款方" && i < tokens.size - 1) {
                remark = "转账给${tokens[i + 1]}"
            } else if (token == "转账成功" && i < tokens.size - 2) {
                var num = tokens[i + 1].replace("￥", "").replace("¥", "").replace("元", "").replace(",", "")
                var value = parseAmountToken(num)
                if (value == null) {
                    num = tokens[i + 2].replace("￥", "").replace("¥", "").replace("元", "").replace(",", "")
                    value = parseAmountToken(num)
                }
                if (value != null) {
                    amount = value
                }
            } else if (token == "付款方式" && i < tokens.size - 1) {
                asset = tokens[i + 1]
            }
        }
        if (amount == null) return null
        val finalRemark = remark?.takeIf { it.isNotBlank() } ?: "支付宝转账"
        return ParsedAuto(
            amount = amount,
            remark = finalRemark,
            transfer = true,
            fromAsset = normalizeAlipayAsset(asset)
        )
    }

    private fun parseAlipayRedPacketSend(tokens: List<String>): ParsedAuto? {
        for (token in tokens) {
            if (token.contains("红包金额")) {
                val idx = token.indexOf("元")
                if (idx > 4) {
                    val num = token.substring(0, idx).replace("红包金额", "").replace(",", "")
                    val value = parseAmountToken(num)
                    if (value != null) return ParsedAuto(value, "发送支付宝红包", transfer = false)
                }
            } else if (token.contains("个红包共")) {
                val idx = token.indexOf("元")
                if (idx > 4) {
                    val num = token.substring(token.indexOf("个红包共") + 4, idx).replace(",", "")
                    val value = parseAmountToken(num)
                    if (value != null) return ParsedAuto(value, "发送支付宝红包", transfer = false)
                }
            } else if (token.contains("已领取") && token.contains("/")) {
                val idx = token.indexOf("元")
                if (idx > 4) {
                    val num = token.substring(token.lastIndexOf("/") + 1, idx).replace(",", "")
                    val value = parseAmountToken(num)
                    if (value != null) return ParsedAuto(value, "发送支付宝红包", transfer = false)
                }
            }
        }
        return null
    }

    private fun parseAlipayRedPacketReceive(tokens: List<String>): ParsedAuto? {
        for (i in tokens.indices) {
            val token = tokens[i]
            if (token.contains("元") && i > 2) {
                val num = token.replace("元", "").replace(",", "")
                val value = parseAmountToken(num)
                if (value != null) {
                    val remark = tokens[i - 3].replace("送你的红包", "") + "的红包"
                    return ParsedAuto(value, remark, income = true)
                }
            }
        }
        return null
    }

    private fun containsAmount(
        tokens: List<String>,
        labels: List<String>,
        requireCurrency: Boolean
    ): Boolean {
        return extractAmount(tokens, requireCurrency = requireCurrency, labels = labels) != null
    }

    private fun parseUnionPay(tokens: List<String>): ParseResult? {
        if (isGenericBillList(tokens)) return null
        if (!containsAny(tokens, unionPaySuccessKeywords)) return null

        val primaryAmount = extractAmountAfterAnchor(tokens, listOf(
            "实付金额（元）",
            "实收金额（元）",
            "支出金额",
            "收入金额",
            "转账金额",
            "订单金额",
            "交易金额"
        ))
        val amount = primaryAmount ?: extractAmount(tokens, requireCurrency = false, labels = listOf(
            "支出金额",
            "订单金额",
            "实付金额（元）",
            "实收金额（元）",
            "收入金额",
            "交易金额",
            "转账金额"
        )) ?: run {
            Log.w(logTag, "UnionPay success hit but no amount. tokens=${sampleTokens(tokens)}")
            return null
        }

        val remark = extractMerchant(tokens, listOf(
            "收款方", "交易对方", "商户", "商品", "付款卡", "收款卡"
        )) ?: "云闪付"

        val transferHint = tokens.any { token ->
            token.contains("转账") || token.contains("转出") || token.contains("转入") || token.contains("还款")
        }
        var type = inferType(tokens, defaultType = "expense")
        if (transferHint) type = "transfer"

        val fromAsset = extractCommonPayAsset(tokens)
        var toAsset = extractCommonToAsset(tokens)
        if (type == "transfer" && toAsset == null) {
            toAsset = extractValueAfterAnchor(tokens, anchors = listOf("信用卡号", "还款到")) ?: detectCreditToAsset(tokens)
        }

        val metadataJson = buildMetadataJson(
            mapOf(
                "asset" to fromAsset,
                "from_asset" to fromAsset,
                "to_asset" to toAsset,
                "order_id" to extractOrderId(tokens),
                "detail_time" to extractDetailTime(tokens)
            )
        )

        Log.i(logTag, "UnionPay parsed amount=$amount remark=$remark type=$type")
        val rawText = buildRawText(tokens, remark)
        return ParseResult(
            source = "UnionPay",
            amount = amount,
            remark = remark,
            type = type,
            rawText = rawText,
            metadataJson = metadataJson,
            timestamp = System.currentTimeMillis()
        )
    }

    private fun parseGeneric(profile: AppProfile, tokens: List<String>): ParseResult? {
        if (!containsAny(tokens, profile.successKeywords)) return null
        if (isGenericBillList(tokens)) return null
        if (looksLikeMultiTransactionList(tokens) && !containsAny(tokens, genericDetailKeywords)) return null
        val primaryAmount = extractAmountAfterAnchor(tokens, listOf(
            "实付金额",
            "实付款",
            "实付价",
            "支付金额",
            "付款金额",
            "实收金额",
            "合计",
            "订单合计",
            "应付金额",
            "优惠后金额",
            "订单金额"
        ))
        val amount = primaryAmount ?: extractAmount(tokens, requireCurrency = profile.requireCurrency, labels = profile.amountLabels)
            ?: return null
        var remark = extractMerchant(tokens, profile.merchantLabels) ?: profile.displayName
        var type = inferType(tokens, defaultType = "expense")
        val creditAsset = detectCreditToAsset(tokens)
        if (creditAsset != null && tokens.any { token -> token.contains("还款") || token.contains("还款成功") }) {
            type = "transfer"
        }
        val fromAsset = extractCommonPayAsset(tokens)
        var toAsset = extractCommonToAsset(tokens)
        if (type == "transfer" && toAsset == null) {
            toAsset = creditAsset
        }
        if (type == "transfer" && remark == profile.displayName) {
            remark = "${profile.displayName}转账"
        }
        val metadataJson = buildMetadataJson(
            mapOf(
                "asset" to fromAsset,
                "from_asset" to fromAsset,
                "to_asset" to toAsset,
                "order_id" to extractOrderId(tokens),
                "detail_time" to extractDetailTime(tokens)
            )
        )
        val rawText = buildRawText(tokens, remark)
        return ParseResult(
            source = profile.displayName,
            amount = amount,
            remark = remark,
            type = type,
            rawText = rawText,
            metadataJson = metadataJson,
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

    private fun extractPreferredAmount(tokens: List<String>): Double? {
        for (token in tokens) {
            val normalized = normalizeAmountToken(token)
            val hasSignal = normalized.contains("¥") || normalized.contains("￥") ||
                normalized.contains("+") || normalized.contains("-") || normalized.contains(".")
            if (!hasSignal) continue
            val amount = extractAmountFromToken(normalized, requireCurrency = false)
                ?: extractPlainAmount(normalized)
            if (amount != null) return amount
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

    private fun extractAmountBeforeMarkers(
        tokens: List<String>,
        markers: List<String>,
        maxLookbehind: Int = 2
    ): Double? {
        for (i in tokens.indices) {
            val token = tokens[i]
            if (!markers.any { marker -> token.contains(marker) }) continue
            for (offset in 1..maxLookbehind) {
                val candidate = tokens.getOrNull(i - offset) ?: continue
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

    private fun isAlipayBillList(tokens: List<String>): Boolean {
        if (tokens.any { it.contains("搜索交易记录") }) return true
        val hasTabs = tokens.contains("全部") && tokens.contains("支出") && tokens.contains("转账")
        if (hasTabs && tokens.any { it.contains("筛选") || it.contains("退款") || it.contains("收入") }) return true
        val hasRecord = tokens.any { token ->
            token.contains("交易记录") || token.contains("账单记录") || token.contains("账单列表")
        }
        if (hasRecord && tokens.any { it.contains("筛选") || it.contains("搜索") }) return true
        return false
    }

    private fun isGenericBillList(tokens: List<String>): Boolean {
        if (tokens.any { it.contains("搜索交易记录") }) return true
        val hasTabs = tokens.contains("全部") && tokens.contains("支出") && tokens.contains("转账")
        if (hasTabs && tokens.any { it.contains("筛选") || it.contains("退款") || it.contains("收入") }) return true
        val hasRecord = tokens.any { token ->
            token.contains("交易记录") || token.contains("账单记录") || token.contains("账单列表")
        }
        if (hasRecord && tokens.any { it.contains("筛选") || it.contains("搜索") }) return true
        return false
    }

    private fun extractValueAfterAnchor(
        tokens: List<String>,
        anchors: List<String>,
        maxLookahead: Int = 3
    ): String? {
        for (i in tokens.indices) {
            val token = tokens[i].trim()
            val anchor = anchors.firstOrNull { token == it || token.contains(it) } ?: continue
            val inline = token.substringAfter(anchor).trim().trimStart('：', ':')
            if (inline.isNotEmpty() && !isAnchorSkipToken(inline)) return inline
            for (offset in 1..maxLookahead) {
                val candidate = tokens.getOrNull(i + offset)?.trim() ?: continue
                if (candidate.isEmpty() || isAnchorSkipToken(candidate)) continue
                return candidate
            }
        }
        return null
    }

    private fun extractValueBeforeAnchor(
        tokens: List<String>,
        anchors: List<String>,
        maxLookbehind: Int = 2
    ): String? {
        for (i in tokens.indices) {
            val token = tokens[i].trim()
            if (!anchors.any { token == it || token.contains(it) }) continue
            for (offset in 1..maxLookbehind) {
                val candidate = tokens.getOrNull(i - offset)?.trim() ?: continue
                if (candidate.isEmpty() || isAnchorSkipToken(candidate)) continue
                return candidate
            }
        }
        return null
    }

    private fun extractAmountAfterAnchor(
        tokens: List<String>,
        anchors: List<String>,
        maxLookahead: Int = 3
    ): Double? {
        for (i in tokens.indices) {
            val token = tokens[i].trim()
            val anchor = anchors.firstOrNull { token == it || token.contains(it) } ?: continue
            val inline = token.substringAfter(anchor).trim().trimStart('：', ':')
            val inlineAmount = extractAmountFromToken(inline, requireCurrency = false)
                ?: extractPlainAmount(inline)
            if (inlineAmount != null) return inlineAmount
            for (offset in 1..maxLookahead) {
                val candidate = tokens.getOrNull(i + offset)?.trim() ?: continue
                val amount = extractAmountFromToken(candidate, requireCurrency = false)
                    ?: extractPlainAmount(candidate)
                if (amount != null) return amount
            }
        }
        return null
    }

    private fun extractDetailTime(tokens: List<String>): String? {
        return extractValueAfterAnchor(
            tokens,
            anchors = listOf("支付时间", "创建时间", "交易时间", "收款时间", "还款时间")
        )
    }

    private fun extractCommonPayAsset(tokens: List<String>): String? {
        return extractValueAfterAnchor(
            tokens,
            anchors = listOf(
                "付款方式",
                "支付方式",
                "支付渠道",
                "支付账户",
                "付款账户",
                "支付账号",
                "付款账号",
                "扣款方式",
                "扣款卡",
                "付款卡",
                "付款银行卡",
                "支付银行卡",
                "扣款银行卡",
                "支付卡",
                "支付工具",
                "支付来源"
            )
        )
    }

    private fun extractCommonToAsset(tokens: List<String>): String? {
        return extractValueAfterAnchor(
            tokens,
            anchors = listOf(
                "收款账户",
                "收款方账户",
                "收款卡",
                "收款银行卡",
                "到账卡",
                "到账银行卡",
                "到账账户",
                "转入账户",
                "入账账户",
                "还款到",
                "退款至"
            )
        )
    }

    private fun detectCreditToAsset(tokens: List<String>): String? {
        if (tokens.any { it.contains("花呗信用购") }) return "花呗信用购"
        if (tokens.any { it.contains("花呗") }) return "花呗"
        if (tokens.any { it.contains("京东白条") }) return "京东白条"
        if (tokens.any { it.contains("美团月付") }) return "美团月付"
        if (tokens.any { it.contains("抖音月付") }) return "抖音月付"
        if (tokens.any { it.contains("信用卡还款") || it.contains("还款信用卡") }) return "信用卡"
        return null
    }

    private fun extractOrderId(tokens: List<String>): String? {
        val raw = extractValueAfterAnchor(tokens, anchors = listOf("订单号", "商家订单号", "交易号", "流水号")) ?: return null
        val match = Regex("\\d{8,}").find(raw)
        return match?.value ?: raw.takeIf { it.isNotBlank() }
    }

    private fun isAnchorSkipToken(token: String): Boolean {
        if (token.length <= 1) return true
        if (looksLikeDateOrTime(token)) return true
        val skipMarkers = listOf("更改", "查看", "修改", "进入", "详情", "已选择", "去查看", "帮助", "更多")
        if (skipMarkers.any { marker -> token == marker || token.contains(marker) }) return true
        if (extractAmountFromToken(token, requireCurrency = false) != null) return true
        if (extractPlainAmount(token) != null) return true
        return false
    }

    private fun buildMetadataJson(values: Map<String, String?>): String? {
        val obj = JSONObject()
        for ((key, value) in values) {
            if (!value.isNullOrBlank()) {
                obj.put(key, value.trim())
            }
        }
        return if (obj.length() == 0) null else obj.toString()
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
        intent.putExtra("metadata", result.metadataJson)
        intent.putExtra("timestamp", result.timestamp)
        intent.putExtra("package_name", packageName)
        sendBroadcast(intent)
    }

    override fun onInterrupt() {}
}
