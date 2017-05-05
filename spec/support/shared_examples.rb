RSpec.shared_examples 'a SolidusPaypalBraintree::PaymentMethod' do
  describe "saving preference hashes as strings" do
    subject { gateway.update(update_params) }

    context "with valid hash syntax" do
      let(:update_params) do
        {
          preferred_merchant_currency_map: '{"EUR" => "test_merchant_account_id"}',
          preferred_paypal_payee_email_map: '{"CAD" => "bruce+wayne@example.com"}'
        }
      end

      it "successfully updates the preference" do
        subject
        expect(gateway.preferred_merchant_currency_map).to eq({ "EUR" => "test_merchant_account_id" })
        expect(gateway.preferred_paypal_payee_email_map).to eq({ "CAD" => "bruce+wayne@example.com" })
      end
    end

    context "with invalid user input" do
      let(:update_params) do
        { preferred_merchant_currency_map: '{this_is_not_a_valid_hash}' }
      end

      it "raise a JSON parser error" do
        expect{ subject }.to raise_error(JSON::ParserError)
      end
    end
  end

  describe '#generate_token' do
    subject { gateway.generate_token }

    context 'connection enabled', vcr: { cassette_name: 'payment_method/generate_token' } do
      it { is_expected.to be_a(String).and be_present }
    end

    context 'when token generation is disabled' do
      around do |ex|
        allowed = WebMock.net_connect_allowed?
        WebMock.disable_net_connect!
        ex.run
        WebMock.allow_net_connect! if allowed
      end

      let(:gateway) do
        gateway = described_class.create!(name: 'braintree')
        gateway.preferred_token_generation_enabled = false
        gateway
      end

      it { is_expected.to match(/Token generation is disabled/) }
    end
  end
end

RSpec.shared_examples "successful response" do
  it 'returns a successful billing response', aggregate_failures: true do
    expect(subject).to be_a ActiveMerchant::Billing::Response
    expect(subject).to be_success
    expect(subject).to be_test
  end
end

RSpec.shared_examples "sources_by_order" do
  let(:order) { FactoryGirl.create :order, user: user, state: "complete", completed_at: DateTime.current }
  let(:gateway) { new_gateway.tap(&:save!) }

  let(:other_payment_method) { FactoryGirl.create(:payment_method) }

  let(:source_without_profile) do
    SolidusPaypalBraintree::Source.create!(
      payment_method_id: gateway.id,
      payment_type: payment_type,
      user_id: user.id
    )
  end

  let(:source_with_profile) do
    SolidusPaypalBraintree::Source.create!(
      payment_method_id: gateway.id,
      payment_type: payment_type,
      user_id: user.id
    ).tap do |source|
      source.create_customer!(user: user)
      source.save!
    end
  end

  let!(:source_payment) { FactoryGirl.create(:payment, order: order, payment_method_id: payment_method_id, source: source) }

  context "when the order has payments with the braintree payment method" do
    let(:payment_method_id) { gateway.id }

    context "when the payment has a saved source with a profile" do
      let(:source) { source_with_profile }

      it "returns the source" do
        expect(subject.to_a).to eql([source])
      end
    end

    context "when the payment has a saved source without a profile" do
      let(:source) { source_without_profile }

      it "returns no result" do
        expect(subject.to_a).to eql([])
      end
    end
  end

  context "when the order has no payments with the braintree payment method" do
    let(:payment_method_id) { other_payment_method.id }
    let(:source) { FactoryGirl.create :credit_card }

    it "returns no results" do
      expect(subject.to_a).to eql([])
    end
  end
end
