{
    'name': 'Syntho Auto Backup',
    'version': '19.0.1.0.0',
    'summary': 'Automatic database backup',
    'description': """
Auto Backup
===========

Automatically backup your Odoo database on a schedule.
This is a very frequently requested feature on forums.
    """,
    'author': 'SynthoERP',
    'category': 'Administration',
    'website': 'https://www.synthoerp.com/',
    'depends': ['base'],
    'data': [
        'security/ir.model.access.csv',
        'data/cron_data.xml',
        'views/backup_config_views.xml',
    ],
    'installable': True,
    'auto_install': False,
    'license': 'LGPL-3',
}
