class Upload < ApplicationRecord
	validates :title, presence: true
	validates :body, presence: true, length: {minimum: 1}
end
