require 'braintree'

module SolidusPaypalBraintree
  class PayPalPayment < PaymentMethod
    def method_type
      "braintree_paypal"
    end

    private

    def transaction_options(source, options, submit_for_settlement = false)
      params = super
      paypal_email = preferred_paypal_payee_email_map[options[:currency]]
      if paypal_email.present?
        params[:options][:paypal] = { payee_email: paypal_email }
      end
      params[:shipping] = braintree_shipping_address(options)
      params
    end

    def braintree_shipping_address(options)
      address = options[:shipping_address]
      first, last = address[:name].split(" ", 2)
      {
        first_name: first,
        last_name: last,
        street_address: [address[:address1], address[:address2]].compact.join(" "),
        locality: address[:city],
        postal_code: address[:zip],
        region: address[:state],
        country_code_alpha2: address[:country]
      }
    end
  end
end
