from odoo import models


class SaleOrder(models.Model):
    _inherit = 'sale.order'

    def action_confirm(self):
        res = super(SaleOrder, self).action_confirm()
        for order in self:
            if order.website_id:
                title = "Order Confirmed"
                body = f"Your order {order.name} has been confirmed. Thank you for shopping with us!"
                self.env['mobile.ecommerce.api']._send_push_notification(
                    [order.partner_id.id],
                    title,
                    body,
                    {'order_id': order.id, 'action': 'open_order'}
                )
        return res
