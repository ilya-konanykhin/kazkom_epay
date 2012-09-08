require 'spec_helper'
require File.expand_path('lib/kazkom_epay')

describe KazkomEpay::Epay do
  describe "Request to the bank" do
    it "should give XML with valid signature for using as request to the bank" do
      # xml = '<document><merchant cert_id="00C182B189" name="Autokupon"><order order_id="242473" amount="10" currency="398"><department merchant_id="92061101" amount="10"/></order></merchant><merchant_sign type="RSA">nU+OPJl5cwUaePrLjMt8omv9qJbnZewUarj66DWflDgkUIk+i80evth70eJ/S/td3fxItd/7EKV5tZliAYkvcA==</merchant_sign></document>'
      xml_with_valid_signature = 'PGRvY3VtZW50PjxtZXJjaGFudCBjZXJ0X2lkPSIwMEMxODJCMTg5IiBuYW1lPSJBdXRva3Vwb24iPjxvcmRlciBvcmRlcl9pZD0iMjQyNDczIiBhbW91bnQ9IjEwIiBjdXJyZW5jeT0iMzk4Ij48ZGVwYXJ0bWVudCBtZXJjaGFudF9pZD0iOTIwNjExMDEiIGFtb3VudD0iMTAiLz48L29yZGVyPjwvbWVyY2hhbnQ+PG1lcmNoYW50X3NpZ24gdHlwZT0iUlNBIj5uVStPUEpsNWN3VWFlUHJMak10OG9tdjlxSmJuWmV3VWFyajY2RFdmbERna1VJaytpODBldnRoNzBlSi9TL3RkM2Z4SXRkLzdFS1Y1dFpsaUFZa3ZjQT09PC9tZXJjaGFudF9zaWduPjwvZG9jdW1lbnQ+'
      @epay = KazkomEpay::Epay.setup({cert_id: '00C182B189', merchant_name: 'Autokupon', amount: 10, order_id: 242473, currency: 398, merchant_id: '92061101'})
      @epay.base64_encoded_signed_xml.should eql(xml_with_valid_signature)
    end
  end

  describe "Response from the bank" do
    it "should check XML response from the bank with valid signature" do
      @epay = KazkomEpay::Epay.setup({})
      xml_with_valid_signature = '<document><bank name="Kazkommertsbank JSC"><customer name="YO MAN" mail="test@test.kz" phone=""><merchant cert_id="00C182B189" name="Autokupon"><order order_id="345009" amount="500" currency="398"><department merchant_id="92061101" amount="500"/></order></merchant><merchant_sign type="RSA"/></customer><customer_sign type="RSA"/><results timestamp="2012-09-07 12:47:25"><payment merchant_id="92061101" card="440564-XX-XXXX-6150" amount="500" reference="120907124725" approval_code="124725" response_code="00" Secure="Yes" card_bin="KAZ"/></results></bank><bank_sign cert_id="00C18327E8" type="SHA/RSA">A/8NoZc1y82G/Fzkciy1bPg6/2J5GGfcQ15HvfdpTnyJVW2tm+fd3sYkpTC+3mfUj2C/dux9ZLsh3K1yV6ZFKm8/0TaMztdd5+KMto2YcOrplIml/7ICT4yUiiB2kCz6NbWOa/RlqowrABPbwdhb1aeJkHtNBkH79rfDM/AAWb0=</bank_sign></document>'
      @epay.check_signed_xml(xml_with_valid_signature).should be_true
    end

    it "should ban XML response from the bank with invalid signature" do
      @epay = KazkomEpay::Epay.setup({})
      xml_with_valid_signature = '<document><bank name="Hackbank JSC"><customer name="YO MAN" mail="test@test.kz" phone=""><merchant cert_id="00C182B189" name="Autokupon"><order order_id="345009" amount="500" currency="398"><department merchant_id="92061101" amount="500"/></order></merchant><merchant_sign type="RSA"/></customer><customer_sign type="RSA"/><results timestamp="2012-09-07 12:47:25"><payment merchant_id="92061101" card="440564-XX-XXXX-6150" amount="500" reference="120907124725" approval_code="124725" response_code="00" Secure="Yes" card_bin="KAZ"/></results></bank><bank_sign cert_id="00C18327E8" type="SHA/RSA">A/8NoZc1y82G/Fzkciy1bPg6/2J5GGfcQ15HvfdpTnyJVW2tm+fd3sYkpTC+3mfUj2C/dux9ZLsh3K1yV6ZFKm8/0TaMztdd5+KMto2YcOrplIml/7ICT4yUiiB2kCz6NbWOa/RlqowrABPbwdhb1aeJkHtNBkH79rfDM/AAWb0=</bank_sign></document>'
      @epay.check_signed_xml(xml_with_valid_signature).should be_false
    end
  end
end
