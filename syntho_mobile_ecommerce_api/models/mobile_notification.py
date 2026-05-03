import json

from odoo import fields, models


class MobileEcommerceNotification(models.Model):
    _name = 'mobile.ecommerce.notification'
    _description = 'Mobile Ecommerce Notification'
    _order = 'create_date desc, id desc'

    partner_id = fields.Many2one(
        'res.partner',
        string='Customer',
        required=True,
        index=True,
        ondelete='cascade',
    )
    website_id = fields.Many2one('website', string='Website', ondelete='set null')
    title = fields.Char(required=True)
    body = fields.Text(required=True)
    notification_type = fields.Selection(
        [
            ('info', 'Information'),
            ('order', 'Order'),
            ('promotion', 'Promotion'),
            ('system', 'System'),
        ],
        default='info',
        required=True,
    )
    data_json = fields.Text(string='Payload JSON', default='{}')
    is_read = fields.Boolean(default=False, index=True)
    read_date = fields.Datetime()
    push_sent = fields.Boolean(default=False)

    def data(self):
        self.ensure_one()
        try:
            return json.loads(self.data_json or '{}')
        except json.JSONDecodeError:
            return {}
