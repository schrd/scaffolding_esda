require "openssl"
require "base64"

class Esda::Scaffolding::AccessToken
  class InvalidTokenFormat < StandardError
  end

  def self.data_for(instance, column)
    data = "#{instance.class.name}.#{instance.id}.#{column}"
  end
  def self.secret_token
    if Rails::VERSION::MAJOR >= 4 and Rails::VERSION::MINOR >= 1
      pwd = Rails.application.secrets.secret_token
    else
      pwd = Rails.application.config.secret_token
    end
    return pwd
  end
  def self.download_token_for(instance, column)
    data = data_for(instance, column)
    cipher = OpenSSL::Cipher.new 'AES-128-CBC'
    cipher.encrypt
    iv = cipher.random_iv
    pwd = secret_token()
    salt = OpenSSL::Random.random_bytes 8
    iter = 20000
    key_len = cipher.key_len
    digest = OpenSSL::Digest::SHA256.new

    key = OpenSSL::PKCS5.pbkdf2_hmac(pwd, salt, iter, key_len, digest)
    cipher.key = key

    #Now encrypt the data:

    encrypted = cipher.update(data)
    encrypted << cipher.final
    "%{salt}:%{encrypted}:%{iv}" % {
      :salt=>Base64.strict_encode64(salt),
      :encrypted=>Base64.strict_encode64(encrypted),
      :iv=>Base64.strict_encode64(iv)
    }
  end
  def self.verify_download_token_for(instance, column, token)
    salt, encrypted, iv = token.split(":").map{|v| Base64.strict_decode64 v}
    raise InvalidTokenFormat, "" if salt.nil? or encrypted.nil? or iv.nil?
    #pwd = Rails.application.config.secret_token
    pwd = secret_token()
    cipher = OpenSSL::Cipher.new 'AES-128-CBC'
    cipher.decrypt
    cipher.iv = iv # the one generated with #random_iv

    iter = 20000
    key_len = cipher.key_len
    digest = OpenSSL::Digest::SHA256.new

    key = OpenSSL::PKCS5.pbkdf2_hmac(pwd, salt, iter, key_len, digest)
    cipher.key = key

    #Now decrypt the data:

    decrypted = cipher.update encrypted
    decrypted << cipher.final
  end

  def self.is_valid_download_token_for?(instance, column, token)
    begin
      data_for(instance, column) == verify_download_token_for(instance, column, token)
    rescue OpenSSL::Cipher::CipherError=>e
      false
    rescue InvalidTokenFormat, ArgumentError=>e
      false
    end
  end
end
