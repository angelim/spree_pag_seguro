# handle shipping errors gracefully during checkout
Spree::CheckoutController.class_eval do
  unless Rails.application.config.consider_all_requests_local
    rescue_from PagSeguro::Errors::InvalidData, :with => :handle_pagseguro_error
  end

  private
    def handle_pagseguro_error(e)
      flash[:error] = e.message
      redirect_to checkout_state_path(:address)
    end
end