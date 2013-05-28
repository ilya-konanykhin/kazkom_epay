require "kazkom_epay/version"
require "base64"
require "openssl"

module KazkomEpay
  CONFIGURABLE_ATTRIBUTES = [:cert_id, :merchant_id, :merchant_name,
    :private_key_path, :private_key_password,
    :public_key_path]

  def self.gem_root_path
    Pathname.new(File.expand_path '../..', __FILE__)
  end

  DEFAULTS = {
    # test data
    cert_id: "00C182B189",
    merchant_name: "Some Merchant",
    merchant_id: 92061101,

    private_key_path: KazkomEpay.gem_root_path.join('cert', 'test', "test_prv.pem"),
    private_key_password: "nissan",
    public_key_path: KazkomEpay.gem_root_path.join('cert', 'test', "kkbca.pem")
  }

  # Выдача готового подписанного XML-документа для банка
  #
  # Пример использования:
  #
  #   signer = KazkomEpay::Signer.new(amount: 10, order_id: 242473)
  #
  #   # уже Base64-кодированного
  #   signer.base64_encoded_signed_xml
  #
  #   # сырого (сам XML)
  #   signer.signed_xml
  #
  class Signer
    def initialize(options = {})
      @amount, @order_id = options.fetch(:amount), options.fetch(:order_id)
    end

    def base64_encoded_signed_xml
      Base64.encode64(signed_xml).gsub("\n", '')
    end

    def signed_xml
      ["<document>", xml, xml_signature, "</document>"].join
    end

    private

      def xml
        %Q|<merchant cert_id="#{KazkomEpay.cert_id}" name="#{KazkomEpay.merchant_name}"><order order_id="#{@order_id}" amount="#{@amount}" currency="#{KazkomEpay.currency}"><department merchant_id="#{KazkomEpay.merchant_id}" amount="#{@amount}"/></order></merchant>|
      end

      def xml_signature
        pkey = OpenSSL::PKey::RSA.new(File.read(KazkomEpay.send(:settings)[:private_key_path]), KazkomEpay.send(:settings)[:private_key_password])

        signature = pkey.sign(OpenSSL::Digest::SHA1.new, xml)
        signature.reverse! if KazkomEpay.send(:reverse_signature)

        signature_base64_encoded_without_newlines = Base64.encode64(signature).gsub("\n", '')

        ['<merchant_sign type="RSA">', signature_base64_encoded_without_newlines, '</merchant_sign>'].join
      end
  end


  # Проверка аутентичности XML-документа, пришедшего от банка
  #
  # Пример использования:
  #
  #   unless KazkomEpay.valid_xml_signature? some_xml_string
  #     raise "Hack attempt!"
  #   end
  #
  def valid_xml_signature?(xml)
    # for `Hash.from_xml`
    require 'active_support/core_ext/hash/conversions'

    bank_sign_raw_base64 = Hash.from_xml(xml)['document']['bank_sign']

    bank_part_regexp = /\A<document>(.+)<bank_sign.*\z/

    data_to_validate = bank_part_regexp.match(xml)[1]
    bank_sign_raw = Base64.decode64 bank_sign_raw_base64
    bank_sign_raw.reverse! if reverse_signature

    digest = OpenSSL::Digest::SHA1.new
    cert = OpenSSL::X509::Certificate.new File.read(settings[:public_key_path])

    cert.public_key.verify digest, bank_sign_raw, data_to_validate
  end

  private

    def settings
      {
        cert_id: cert_id,
        currency: currency, # KZT
        merchant_name: merchant_name,
        merchant_id: merchant_id,

        private_key_path: private_key[:path],
        private_key_password: private_key[:password],
        public_key_path: public_key[:path]
      }
    end

    def reverse_signature
      true
    end

    # Memoizers
    def private_key
      @private_key ||= {path: private_key_path, password: private_key_password}
    end
    def public_key
      @public_key ||= {path: public_key_path}
    end

    module Configurator
      require 'active_support/core_ext/module/attribute_accessors'

      def configure_for_test
        configure(DEFAULTS)
      end
      
      def configure(attrs = {})
        attrs.each do |k, v|
          self.send(:"#{k}=", v) if CONFIGURABLE_ATTRIBUTES.include?(k.to_sym)
        end
        yield self if block_given?

        if (blank = CONFIGURABLE_ATTRIBUTES.map { |att| [att, self.send(att)] }.select{|_, val| val.nil?}).count > 0
          blank_attribute_names = blank.map { |attr, _| attr }.join(", ")
          raise "Some required attributes left blank: #{blank_attribute_names}"
        end

        self
      end

      CONFIGURABLE_ATTRIBUTES.each do |att|
        mattr_accessor att
      end

      mattr_accessor :currency
      @@currency = 398
    end


    extend Configurator
    extend self
end
