class Food < ActiveRecord::Base
  belongs_to :food_category
  has_and_belongs_to_many :meals
end
