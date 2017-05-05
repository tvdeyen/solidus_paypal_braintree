require 'braintree'

module SolidusPaypalBraintree
  class CreditCardPayment < PaymentMethod
    def method_type
      'braintree_credit_card'
    end
  end
end
