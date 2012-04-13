Spree::Adjustment.class_eval do
  scope :positive_charge, where("amount > 0")
end