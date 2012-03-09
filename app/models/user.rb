class User < ActiveRecord::Base
  has_secure_password

  attr_accessible :email, :password, :password_confirmation

  EMAIL_REGEX = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i

#  validates_uniqueness_of :email
#  validates_format_of :email, with: EMAIL_REGEX
#  validates_length_of :password, minimum: 8

  validates :email,    uniqueness: true,
                           format: { with: EMAIL_REGEX }
  validates :password,     length: { minimum: 8 }
end
