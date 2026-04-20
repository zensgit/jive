import 'domestic_payment_service_base.dart';
import 'payment_provider_resolver.dart';

class AlipayPaymentService extends DomesticPaymentServiceBase {
  AlipayPaymentService({required super.orderClient, required super.channel})
    : super(provider: PaymentProvider.alipay);
}
