class Mission < ApplicationRecord

  scope :active, ->{ where(hidden: 0) }
end
