class Book < ActiveRecord::Base

  belongs_to :author

  attr_readonly :id

end
