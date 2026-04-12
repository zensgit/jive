import 'domestic_payment_order_client.dart';
import 'payment_provider_resolver.dart';
import 'payment_service.dart';
import 'product_ids.dart';

abstract class DomesticPaymentServiceBase extends PaymentService {
  DomesticPaymentServiceBase({
    required PaymentProvider provider,
    required DomesticPaymentOrderClient orderClient,
    required PaymentChannel channel,
  }) : _provider = provider,
       _orderClient = orderClient,
       _channel = channel;

  final PaymentProvider _provider;
  final DomesticPaymentOrderClient _orderClient;
  final PaymentChannel _channel;

  bool _isReady = false;
  List<StoreProduct> _products = const [];

  @override
  bool get isAvailable => true;

  @override
  bool get isReady => _isReady;

  @override
  List<StoreProduct> get products => List.unmodifiable(_products);

  @override
  Future<void> init() async {
    _products = const [
      StoreProduct(
        id: ProductIds.paidUnlock,
        title: '专业版',
        description: '一次性解锁专业版能力',
        price: '¥28',
        isSubscription: false,
      ),
      StoreProduct(
        id: ProductIds.subscriberMonthly,
        title: '专业订阅月付',
        description: '按月订阅专业版能力',
        price: '¥8/月',
        isSubscription: true,
      ),
      StoreProduct(
        id: ProductIds.subscriberYearly,
        title: '专业订阅年付',
        description: '按年订阅专业版能力',
        price: '¥68/年',
        isSubscription: true,
      ),
    ];
    _isReady = true;
    notifyListeners();
  }

  @override
  Future<PurchaseResult> purchase(String productId) async {
    StoreProduct? product;
    for (final item in _products) {
      if (item.id == productId) {
        product = item;
        break;
      }
    }
    if (product == null) {
      return PurchaseResult.error('未找到商品: $productId', provider: _provider);
    }

    try {
      final order = await _orderClient.createOrder(
        provider: _provider,
        productId: productId,
        planCode: _planCodeForProductId(productId),
        channel: _channel,
      );
      return PurchaseResult.pending(
        provider: _provider,
        orderId: order.orderId,
        redirectUrl: order.redirectUrl,
        qrCodeUrl: order.qrCodeUrl,
        errorMessage: '${_provider.label}订单已创建，请完成支付后刷新权益',
      );
    } catch (e) {
      return PurchaseResult.error('创建支付订单失败: $e', provider: _provider);
    }
  }

  @override
  Future<PurchaseResult> restorePurchases() async {
    return PurchaseResult.error(
      '$_providerLabel 暂不支持恢复购买，请完成支付后刷新权益',
      provider: _provider,
    );
  }

  String get _providerLabel => _provider.label;
}

String _planCodeForProductId(String productId) {
  switch (productId) {
    case ProductIds.paidUnlock:
      return 'pro_lifetime';
    case ProductIds.subscriberMonthly:
      return 'pro_monthly';
    case ProductIds.subscriberYearly:
      return 'pro_yearly';
    default:
      return 'custom';
  }
}
