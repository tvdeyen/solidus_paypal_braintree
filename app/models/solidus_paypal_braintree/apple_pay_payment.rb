require 'braintree'

module SolidusPaypalBraintree
  class ApplePayPayment < PaymentMethod
    def method_type
      "braintree_apple_pay"
    end
  end
end
