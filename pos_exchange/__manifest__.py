{
    'name': 'POS Exchange',
    'version': '19.0.1.1.0',
    'summary': 'Process POS exchanges on refund receipts',
    'description': """
POS Exchange
============

Allow cashiers to add replacement products to an active refund receipt when
the order already contains refunded lines. The POS payment screen then settles
the net exchange amount in one receipt.
    """,
    'category': 'Point of Sale',
    'author': 'SynthoERP',
    'depends': ['point_of_sale'],
    'license': 'LGPL-3',
    'assets': {
        'point_of_sale._assets_pos': [
            'pos_exchange/static/src/js/patches/pos_order_patch.js',
        ],
    },
    'images': [
        'static/description/banner.png',
        'static/description/exchange_receipt.png',
        'static/description/net_payment.png',
    ],
    'installable': True,
    'application': False,
    'price': 0,
    'currency': 'USD',
}
