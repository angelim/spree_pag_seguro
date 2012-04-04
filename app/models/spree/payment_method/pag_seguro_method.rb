module Spree
  class PaymentMethod::PagSeguroMethod < PaymentMethod
    preference :email, :string
    preference :token, :string
    
    def payment_profiles_supported?
      true
    end
    
    def process_before_confirm?
      true
    end
    
    def payment_source_class
      PagSeguroPayment
    end
  end
end
