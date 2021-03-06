describe "#restore_iaps" do
  class TestIAP
    include PM::IAP
  end

  mock_transaction = Struct.new(:transactionState, :error, :payment) do
    def matchingIdentifier; end
  end
  mock_payment = Struct.new(:productIdentifier)

  it "responds to #restore_iaps" do
    TestIAP.new.respond_to?(:restore_iaps).should.be.true
  end

  context "restored transaction" do
    restored_transaction = mock_transaction.new(SKPaymentTransactionStateRestored, Struct.new(:code).new(nil), mock_payment.new("restoredproductid"))

    it "returns success" do
      callback_called = false
      subject = TestIAP.new
      subject.mock!(:completion_handlers, return: {
        "restore-restoredproductid" => ->(status, data) {
          status.should == :restored
          data[:product_id].should == "restoredproductid"
          data[:error].code.should.be.nil
          data[:transaction].transactionState.should == SKPaymentTransactionStateRestored
          callback_called = true
        },
      })
      subject.paymentQueue(nil, updatedTransactions:[ restored_transaction ])
      callback_called.should.be.true
    end
  end

  context "error in restore" do
    restored_transaction = mock_transaction.new(SKPaymentTransactionStateRestored, Struct.new(:code).new(nil), mock_payment.new("restoredproductid"))

    it "returns success" do
      callback_called = false
      subject = TestIAP.new
      subject.mock!(:completion_handlers, return: {
        "restore-all" => ->(status, data) {
          status.should == :error
          data[:product_id].should.be.nil
          data[:error].localizedDescription.should == "Failed to restore"
          data[:transaction].should.be.nil
          callback_called = true
        },
      })
      subject.paymentQueue(nil, restoreCompletedTransactionsFailedWithError:Struct.new(:localizedDescription).new("Failed to restore"))
      callback_called.should.be.true
    end
  end

end
