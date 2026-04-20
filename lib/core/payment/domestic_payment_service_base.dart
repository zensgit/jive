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
  List<PaymentProvider> get availableProviders => [_provider];

  @override
  PaymentProvider? get defaultProvider => _provider;

  @override
  Future<void> init() async {
    _products = domesticPaymentProducts;
    _isReady = true;
    notifyListeners();
  }

  @override
  Future<PurchaseResult> purchase(
    String productId, {
    PaymentProvider? provider,
  }) async {
    final selectedProvider = provider ?? _provider;
    if (selectedProvider != _provider) {
      return PurchaseResult.error(
        '${_provider.label}服务不支持${selectedProvider.label}',
        provider: selectedProvider,
      );
    }

    return createDomesticPaymentOrder(
      provider: selectedProvider,
      productId: productId,
      products: _products,
      orderClient: _orderClient,
      channel: _channel,
    );
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

class DomesticPaymentService extends PaymentService {
  DomesticPaymentService({
    required List<PaymentProvider> providers,
    required DomesticPaymentOrderClient orderClient,
    required PaymentChannel channel,
  }) : _providers = _normalizeProviders(providers),
       _orderClient = orderClient,
       _channel = channel;

  final List<PaymentProvider> _providers;
  final DomesticPaymentOrderClient _orderClient;
  final PaymentChannel _channel;

  bool _isReady = false;
  List<StoreProduct> _products = const [];

  @override
  bool get isAvailable => _providers.isNotEmpty;

  @override
  bool get isReady => _isReady;

  @override
  List<StoreProduct> get products => List.unmodifiable(_products);

  @override
  List<PaymentProvider> get availableProviders => List.unmodifiable(_providers);

  @override
  PaymentProvider? get defaultProvider =>
      _providers.isEmpty ? null : _providers.first;

  @override
  Future<void> init() async {
    _products = _providers.isEmpty ? const [] : domesticPaymentProducts;
    _isReady = true;
    notifyListeners();
  }

  @override
  Future<PurchaseResult> purchase(
    String productId, {
    PaymentProvider? provider,
  }) async {
    final selectedProvider = provider ?? defaultProvider;
    if (selectedProvider == null || !_providers.contains(selectedProvider)) {
      return PurchaseResult.error(
        '当前支付服务不支持所选支付方式',
        provider: selectedProvider,
      );
    }

    return createDomesticPaymentOrder(
      provider: selectedProvider,
      productId: productId,
      products: _products,
      orderClient: _orderClient,
      channel: _channel,
    );
  }

  @override
  Future<PurchaseResult> restorePurchases() async {
    return const PurchaseResult.error('国内支付暂不支持恢复购买，请完成支付后刷新权益');
  }
}

Future<PurchaseResult> createDomesticPaymentOrder({
  required PaymentProvider provider,
  required String productId,
  required List<StoreProduct> products,
  required DomesticPaymentOrderClient orderClient,
  required PaymentChannel channel,
}) async {
  StoreProduct? product;
  for (final item in products) {
    if (item.id == productId) {
      product = item;
      break;
    }
  }
  if (product == null) {
    return PurchaseResult.error('未找到商品: $productId', provider: provider);
  }

  try {
    final order = await orderClient.createOrder(
      provider: provider,
      productId: productId,
      planCode: _planCodeForProductId(productId),
      channel: channel,
    );
    return PurchaseResult.pending(
      provider: provider,
      orderId: order.orderId,
      redirectUrl: order.redirectUrl,
      qrCodeUrl: order.qrCodeUrl,
      errorMessage: '${provider.label}订单已创建，请完成支付后刷新权益',
    );
  } catch (e) {
    return PurchaseResult.error('创建支付订单失败: $e', provider: provider);
  }
}

const domesticPaymentProducts = [
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

List<PaymentProvider> _normalizeProviders(List<PaymentProvider> providers) {
  final seen = <PaymentProvider>{};
  return [
    for (final provider in providers)
      if (provider.isDomestic && seen.add(provider)) provider,
  ];
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
