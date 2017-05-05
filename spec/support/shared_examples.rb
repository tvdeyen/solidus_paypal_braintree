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
