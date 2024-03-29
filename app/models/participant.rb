class Participant < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable, :authentication_keys => [:login]
  enum gender: [:male, :female, :other]
  has_many :food_diaries

  validates :pid, presence: true, uniqueness: true

  validates :gender, presence: true

  attr_accessor :login, :email

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions.to_h).where(["lower(pid) = :value", { :value => login.downcase }]).first
    else
      where(conditions.to_h).first
    end
  end
end
