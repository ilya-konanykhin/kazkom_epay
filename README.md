# gem для работы с КазКоммерцБанк ePay

Gem для работы с платежным шлюзом ККБ ePay для использования в проектах, использующих Ruby (Ruby On Rails, Sinatra и др.).

## Установка

Добавьте эту строку в ваш Gemfile:

    gem 'kazkom_epay'

Затем установите gem, используя bundler:

    $ bundle

Или выполните команду:

    $ gem install kazkom_epay

## Использование (примеры с использованием Ruby On Rails)

### Подпись XML-запроса к банку

```ruby
  # encoding: UTF-8
  class PayController < ApplicationController
    before_filter :authenticate_user!
    def epay
      # ...
      path_to_yaml = Rails.root.join('config', 'epay.yml')
      epay_credentials = YAML.load_file(path_to_yaml)
      amount = ...
      
      # здесь вы фиксируете Order_ID, который вы передадите банку
      # и по которому вы сможете в дальнейшем найти нужный платеж
      # и пользователя, чтобы зачислить деньги ему на счет
      payment_request = PaymentRequest.create! do |r|
        r.user = current_user
        r.amount = amount
      end

      order_id = payment_request.id

      epay_credentials.merge!({amount: amount, order_id: order_id})
      epay = KazkomEpay::Epay.setup(epay_credentials)

      @base64_encoded_xml = epay.base64_encoded_signed_xml
      # ...
    end
    # ...
  end
```

### Проверка XML-ответа от банка

```ruby
  # encoding: UTF-8
  class PaymentsEpayController < PaymentsController
    # ...
    def process_payment
      xml = params[:response]

      epay_response_is_okay = KazkomEpay::Epay.check_signed_xml xml
      if epay_response_is_okay
        epay_response = Hash.from_xml(xml)['document']['bank']

        begin
          ActiveRecord::Base.transaction do
            # Задача этого блока - увеличить счет пользователя

            # Нужно найти Order_ID, который вы создали на этапе формировани
            # XML для отправки в ePay.
            # Например так (при условии, что у вас есть модель PaymentRequest):
            payment_request = PaymentRequest.find epay_response['customer']['merchant']['order']['order_id']

            # из него вы можете выяснить, счет какого пользователя увеличить:
            user = payment_request.user
          end
        rescue => e
          # Что-то пошло не так, зафиксируйте это в логах и сделайте все, чтобы
          # вы об этом узнали (отошлите себе уведомление и пр.)
          Rails.logger.fatal "Что-то пошло не так при оплате через ePay. Данные: " + params.to_json

          # ...
        end
      else
        # Подпись оказалась неверной. Возможно, вас пытаются взломать
      end

      # Обязательно выведите "0" и ничего больше, это требование ePay
      render text: "0"
    end
  end
```

## Какой код я могу использовать для отсылки запроса на оплату в ePay?

### Пример с использованием ERB:

#### Пояснения

Для тестирования используется 3dsecure.kkb.kz, иначе используется epay.kkb.kz, потому что при тестировании вы можете использовать тестовый закрытый ключ и тестовые данные кредитной карты.

@base64_encoded_xml - это то, что отдал метод base64_encoded_signed_xml

```html
<% prefix_for_epay = Rails.env.development? ? '3dsecure' : 'epay' %>
<form id="pay-epay" method="post" action="https://<%= prefix_for_epay %>.kkb.kz/jsp/process/logon.jsp" target="_blank">
  <input type="hidden" name="Signed_Order_B64" value="<%= @base64_encoded_xml %>">
  <input type="hidden" name="email" value="<%= current_user.email %>">
  <input type="hidden" name="Language" value="rus">
  <input type="hidden" name="BackLink" value="<%= root_url %>">
  <input type="hidden" name="PostLink" value="<%= "обработчик_ответа_банка" %>">
  <input type="submit" value="Оплатить">
</form>
```

## Пример epay.yml

```yaml
  ---
  cert_id: abcd1234
  merchant_id: '1234567'
  private_key_path: 'your.prv.pem'
  private_key_password: "s0me_p@$$w0rd"
```

*Важное замечание*
В _private_key_path_ нужно указать либо полный путь к файлу ключа, либо обернуть Yaml в Erb:

epay.yml.erb
```yaml
  ---
  # ...
  private_key_path: <%= Rails.root.join('app', 'cert', 'your.prv.pem') %>
```

и в коде использовать

    epay_credentials = YAML.load(ERB.new(File.read(path_to_yaml)).result)

вместо

    epay_credentials = YAML.load_file(path_to_yaml)



## Пример

TODO: сделать Rails-приложение для примера

Для тестирования postlink (обработчика ответа банка) приложение должно быть доступно из интернета (имеется ввиду URL).

## Хотите помочь?

1. Fork'ните проект
2. Создайте ветку для вашей функции (`git checkout -b my-new-feature`)
3. Сделайте коммит для ваших изменений (`git commit -am 'Added some feature'`)
4. Загрузите ветку на GitHub (`git push origin my-new-feature`)
5. Сделайте Pull Request
