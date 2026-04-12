import 'domestic_payment_service_base.dart';
import 'payment_provider_resolver.dart';

class WechatPayPaymentService extends DomesticPaymentServiceBase {
  WechatPayPaymentService({required super.orderClient, required super.channel})
    : super(provider: PaymentProvider.wechatPay);
}
