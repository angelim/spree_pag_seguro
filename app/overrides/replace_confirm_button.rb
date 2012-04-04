Deface::Override.new(
  virtual_path: "spree/checkout/_confirm",
  name: "replace_confirm_button",
  replace: "[data-hook='buttons']",
  partial: "spree/checkout/confirm/button"
)