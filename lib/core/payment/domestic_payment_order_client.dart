import 'package:supabase_flutter/supabase_flutter.dart';

import 'payment_provider_resolver.dart';

class DomesticPaymentOrder {
  final PaymentProvider provider;
  final String orderId;
  final String? redirectUrl;
  final String? qrCodeUrl;
  final String status;
  final String? productId;
  final String? planCode;

  const DomesticPaymentOrder({
    required this.provider,
    required this.orderId,
    required this.status,
    this.redirectUrl,
    this.qrCodeUrl,
    this.productId,
    this.planCode,
  });
}

abstract class DomesticPaymentOrderClient {
  Future<DomesticPaymentOrder> createOrder({
    required PaymentProvider provider,
    required String productId,
    required String planCode,
    required PaymentChannel channel,
  });
}

class SupabaseDomesticPaymentOrderClient implements DomesticPaymentOrderClient {
  SupabaseDomesticPaymentOrderClient({SupabaseClient? client})
    : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get _resolvedClient => _client ?? Supabase.instance.client;

  @override
  Future<DomesticPaymentOrder> createOrder({
    required PaymentProvider provider,
    required String productId,
    required String planCode,
    required PaymentChannel channel,
  }) async {
    final response = await _resolvedClient.functions.invoke(
      'create-payment-order',
      body: {
        'provider': _providerCode(provider),
        'product_id': productId,
        'plan_code': planCode,
        'client_channel': _channelCode(channel),
      },
    );

    final data = response.data;
    if (data is! Map) {
      throw const FormatException('invalid_payment_order_response');
    }

    final order = data['order'];
    if (order is! Map) {
      throw const FormatException('missing_payment_order');
    }

    final map = Map<String, dynamic>.from(order);
    final orderId = map['order_no']?.toString();
    if (orderId == null || orderId.isEmpty) {
      throw const FormatException('missing_payment_order_no');
    }

    return DomesticPaymentOrder(
      provider: provider,
      orderId: orderId,
      status: map['status']?.toString() ?? 'pending',
      redirectUrl: map['redirect_url']?.toString(),
      qrCodeUrl: map['qr_code_url']?.toString(),
      productId: map['product_id']?.toString(),
      planCode: map['plan_code']?.toString(),
    );
  }
}

String _providerCode(PaymentProvider provider) {
  switch (provider) {
    case PaymentProvider.wechatPay:
      return 'wechat_pay';
    case PaymentProvider.alipay:
      return 'alipay';
    case PaymentProvider.googlePlay:
      return 'google_play';
    case PaymentProvider.appleAppStore:
      return 'apple_app_store';
  }
}

String _channelCode(PaymentChannel channel) {
  switch (channel) {
    case PaymentChannel.auto:
      return 'auto';
    case PaymentChannel.appStore:
      return 'app_store';
    case PaymentChannel.googlePlay:
      return 'google_play';
    case PaymentChannel.selfHostedWeb:
      return 'self_hosted_web';
    case PaymentChannel.directAndroid:
      return 'direct_android';
    case PaymentChannel.desktopWeb:
      return 'desktop_web';
  }
}
