Spree::Adjustment.class_eval do
  scope :credit, where("amount > 0")
  scope :debit, where("amount < 0")
end