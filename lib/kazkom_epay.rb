require "kazkom_epay/version"

module KazkomEpay
  require 'base64'
  require 'openssl'
  require 'yaml'

  def self.root
    Pathname.new(File.expand_path '../..', __FILE__)
  end

  class Epay
    class << self
      def settings
        @@settings ||= {
          cert_id: "00C182B189", # test cert_id
          currency: 398, # KZT
          merchant_name: "Some Merchant",
          merchant_id: 92061101, # test merchant_id

          private_key_path: KazkomEpay::root.join('cert', 'test', "test_prv.pem"), # test private key path
          private_key_password: "nissan", # test private key password
          public_key_path: KazkomEpay::root.join('cert', 'test', "kkbca.pem")
        }
      end

      def setup with_params
        @@settings ||= settings
        with_params.each_pair do |key, value|
          @@settings[key.to_sym] = value
        end
        self
      end

      def key
        settings[:key]
      end

      def xml
        %Q|<merchant cert_id="#{cert_id}" name="#{merchant_name}"><order order_id="#{order_id}" amount="#{amount}" currency="#{currency}"><department merchant_id="#{merchant_id}" amount="#{amount}"/></order></merchant>|
      end

      def xml_sign
        pkey = OpenSSL::PKey::RSA.new(File.read(settings[:private_key_path]), settings[:private_key_password])

        signature = pkey.sign(OpenSSL::Digest::SHA1.new, xml)
        signature.reverse! if reverse_signature

        signature_base64_encoded_without_newlines = Base64.encode64(signature).gsub("\n", '')
        '<merchant_sign type="RSA">' + signature_base64_encoded_without_newlines + '</merchant_sign>'
      end

      def signed_xml
        "<document>" + xml + xml_sign + "</document>"
      end

      # КЛЮЧЕВОЙ МОМЕНТ при формировании запроса для банка
      def base64_encoded_signed_xml
        Base64.encode64(signed_xml).gsub("\n", '')
      end

      # КЛЮЧЕВОЙ МОМЕНТ при проверке ответа от банка
      def check_signed_xml xml
        # Hash.from_xml
        require 'active_support/core_ext/hash/conversions'

        bank_sign_raw_base64 = Hash.from_xml(xml)['document']['bank_sign']

        bank_part_regexp = /\A<document>(.+)<bank_sign.*\z/
        bank_sign_regexp = /(<bank_sign .+<\/bank_sign>)/

        check_this = bank_part_regexp.match(xml)[1]
        bank_sign_raw = Base64.decode64 bank_sign_raw_base64
        bank_sign_raw.reverse! if reverse_signature

        digest = OpenSSL::Digest::SHA1.new
        cert = OpenSSL::X509::Certificate.new File.read(settings[:public_key_path])
        public_key = cert.public_key

        check_result = public_key.verify digest, bank_sign_raw, check_this
      end

      alias_method :xml_correctly_signed?, :check_signed_xml

      def cert_id
        settings[:cert_id]
      end

      def merchant_name
        settings[:merchant_name]
      end

      def order_id
        settings[:order_id]
      end

      def amount
        settings[:amount]
      end

      def currency
        settings[:currency]
      end

      def merchant_id
        settings[:merchant_id]
      end

      def reverse_signature
        true
      end
    end
  end
end
