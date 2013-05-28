# -*- encoding: utf-8 -*-
require File.expand_path('../lib/kazkom_epay/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Semenyuk Dmitriy"]
  gem.email         = ["mail@semenyukdmitriy.com"]
  gem.description   = %q{Модуль работы с платежным шлюзом KKB ePay}
  gem.summary       = %q{Модуль работы с платежным шлюзом KKB ePay}
  gem.homepage      = "http://semenyukdmitriy.com"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(spec|features)/})
  gem.name          = "kazkom_epay"
  gem.require_paths = ["lib"]
  gem.version       = KazkomEpay::VERSION
end
