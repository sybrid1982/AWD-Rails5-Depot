class CombineItemsInCart < ActiveRecord::Migration[5.0]
  def up
    #replace multiple items in cart of the same type for a single item in the cart with a quantity
    Cart.all.each do |cart|
      #group should return a hash where the key is whatever is what we are
      #grouping by and the members are each item that matches that key
      #so in this case we are going through the cart and collecting each
      #item that matches a product ID and adding it to a hash
      #where the key is the product id and the value is the total quantity
      sums = cart.line_items.group(:product_id).sum(:quantity)

      sums.each do |product_id, quantity|
        if quantity > 1
          #so for each member of the hash
          #(which is each kind of product_id in the cart and the quantity of each item)
          #if there was more than one of the item,
          #ie quantity > 1
          #then remove all the entries
          cart.line_items.where(product_id:product_id).delete_all
          item = cart.line_items.build(product_id: product_id)
          item.quantity = quantity
          item.save!
        end
      end
    end
  end

  def down
    #Split items with quantity > 1 into multiple items
    LineItem.where("quantity>1").each do |line_item|
      #add individual items
      line_item.quantity.times do
        LineItem.create(cart_id: line_item.cart_id, product_id: line_item.product_id, quantity: 1)
      end
      line_item.destroy
    end
  end
end
