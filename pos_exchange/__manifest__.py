{
    'name': 'POS Exchange',
    'version': '19.0.1.0.0',
    'summary': 'Allow adding products to refund receipts for in-place exchanges',
    'category': 'Point of Sale',
    'author': 'Smartek',
    'depends': ['point_of_sale'],
    'license': 'LGPL-3',
    'assets': {
        'point_of_sale._assets_pos': [
            'pos_exchange/static/src/js/patches/pos_order_patch.js',
        ],
    },
    'installable': True,
    'application': False,
}
