from odoo import fields, models


class MobileEcommerceDevice(models.Model):
    _name = 'mobile.ecommerce.device'
    _description = 'Mobile Ecommerce Device'
    _rec_name = 'token'

    partner_id = fields.Many2one('res.partner', string='Partner', ondelete='cascade')
    token = fields.Char(required=True, index=True, string='FCM Token')
    platform = fields.Selection(
        [
            ('ios', 'iOS'),
            ('android', 'Android'),
            ('web', 'Web'),
        ],
        required=True,
    )
    last_seen = fields.Datetime(default=fields.Datetime.now)

    _sql_constraints = [
        ('token_unique', 'unique(token)', 'The device token must be unique!'),
    ]

    def action_send_test_notification(self):
        self.ensure_one()
        api = self.env['mobile.ecommerce.api']
        api._send_push_notification(
            [self.partner_id.id] if self.partner_id else [],
            "Test Notification",
            "This is a test notification from your Odoo backend.",
            {'test': 'true'}
        )
        return {
            'type': 'ir.actions.client',
            'tag': 'display_notification',
            'params': {
                'title': 'Push Notification',
                'message': 'Test notification sent to device.',
                'type': 'success',
                'sticky': False,
            }
        }
