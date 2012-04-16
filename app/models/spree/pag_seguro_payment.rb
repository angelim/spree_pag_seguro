module Spree
  class PagSeguroPayment < ActiveRecord::Base
    
    attr_accessor :order_id
    has_one :payment, :as => :source
    
    def process!(payment)
      order = payment.order
      
      redirect_url = "#{Spree::Config[:site_url]}/orders/#{order.number}"

      pag_seguro_payment = ::PagSeguro::Payment.new(
        Order.pag_seguro_payment_method.preferred_email,
        Order.pag_seguro_payment_method.preferred_token,
        redirect_url: redirect_url,
        extra_amount: format("%.2f", payment.order.adjustments.credit.sum(:amount)),
        id: order.id)

      pag_seguro_payment.items = order_items + order_charges

      pag_seguro_payment.sender   = ::PagSeguro::Sender.new(
                                    name: order.name, 
                                    email: order.email, 
                                    phone_number: order.ship_address.phone, 
                                    phone_ddd: order.ship_address.ddd )
                                    
      pag_seguro_payment.shipping = ::PagSeguro::Shipping.new(
                                    type: ::PagSeguro::Shipping::UNIDENTIFIED, 
                                    state: order.ship_address.state.abbr, 
                                    city: order.ship_address.city, 
                                    postal_code: order.ship_address.zipcode, 
                                    street: order.ship_address.address1, 
                                    number: order.ship_address.number, 
                                    complement: order.ship_address.address2, 
                                    district: order.ship_address.neighborhood )
      self.code = pag_seguro_payment.code
      self.date = pag_seguro_payment.date
      self.save
    end
    
    def order_items
      payment.order.line_items.map do |item|
        pag_seguro_item = ::PagSeguro::Item.new
        pag_seguro_item.id = item.id
        pag_seguro_item.description = item.product.name
        pag_seguro_item.amount = format("%.2f", item.price.round(2))
        pag_seguro_item.quantity = item.quantity
        pag_seguro_item.weight = (item.product.weight * 1000).to_i if item.product.weight.present?
        pag_seguro_item.shipping_cost = "0.00"
        pag_seguro_item
      end
    end
    
    def order_charges
      payment.order.adjustments.positive_charge.map do |item|
        pag_seguro_item = ::PagSeguro::Item.new
        pag_seguro_item.id = item.id
        pag_seguro_item.description = item.label
        pag_seguro_item.amount = format("%.2f", item.amount.round(2))
        pag_seguro_item.quantity = 1
        pag_seguro_item.weight = 0
        pag_seguro_item.shipping_cost = "0.00"
        pag_seguro_item
      end
    end
    
    def actions
      %w{capture void}
    end

    # Indicates whether its possible to capture the payment
    def can_capture?(payment)
      ['processing', 'checkout', 'pending'].include?(payment.state)
    end

    # Indicates whether its possible to void the payment.
    def can_void?(payment)
      payment.state != 'void'
    end

    def capture(payment)
      payment.update_attribute(:state, 'pending') if payment.state == 'checkout'
      payment.complete
      true
    end

    def void(payment)
      payment.update_attribute(:state, 'pending') if payment.state == 'checkout'
      payment.void
      true
    end
  end
end
