require 'test_helper'

class Payment::ReceiptMailerTest < ActionMailer::TestCase
  def setup
    Payola.pdf_receipt = false
    @sale = FactoryGirl.create(:sale)
  end

  context "#receipt" do
    should "send a receipt" do
      mail = Payment::ReceiptMailer.receipt(@sale.guid)
      assert_equal "Payment receipt", mail.subject
    end

    should "deliver a receipt" do
      assert_difference "ActionMailer::Base.deliveries.count", 1 do
        mail = Payment::ReceiptMailer.receipt(@sale.guid).deliver_now
      end
    end

    should "send a receipt with a pdf" do
      Payola.pdf_receipt = true
      Docverter::Conversion.expects(:run).returns("pdf")
      mail = Payment::ReceiptMailer.receipt(@sale.guid)
      assert_not_nil mail.attachments["receipt-#{@sale.guid}.pdf"]
    end

    should "allow product to override subject" do
      Plan.any_instance.stubs(:receipt_subject).returns("Override Subject")
      mail = Payment::ReceiptMailer.receipt(@sale.guid)
      assert_equal 'Override Subject', mail.subject
    end

    should "allow product to override from address" do
      Plan.any_instance.stubs(:receipt_from_address).returns("Override <override@example.com>")
      mail = Payment::ReceiptMailer.receipt(@sale.guid)
      assert_equal 'override@example.com', mail.from.first
    end
  end

  context "#refund" do
    should "send refund email" do
      mail = Payment::ReceiptMailer.refund(@sale.guid)
      assert_equal "Refund confirmation", mail.subject
    end

    should "deliver refund email" do
      assert_difference "ActionMailer::Base.deliveries.count", 1 do
        Payment::ReceiptMailer.refund(@sale.guid).deliver_now
      end
    end

    should "allow product to override subject" do
      Plan.any_instance.stubs(:refund_subject).returns("Override Subject")
      mail = Payment::ReceiptMailer.refund(@sale.guid)
      assert_equal 'Override Subject', mail.subject
    end

    should "allow product to override from address" do
      Plan.any_instance.stubs(:refund_from_address).returns("Override <override@example.com>")
      mail = Payment::ReceiptMailer.refund(@sale.guid)
      assert_equal 'override@example.com', mail.from.first
    end
  end
end
