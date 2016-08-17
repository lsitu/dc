class Unit < ActiveRecord::Base
  has_many :memberships, dependent: :destroy
  has_many :members, through: :memberships, source: :user

  accepts_nested_attributes_for :memberships
  validates :name, :key, presence: true
end
