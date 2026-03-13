Syntho Auto Backup
==================

**Version:** 19.0.1.0.0 | **License:** LGPL-3 | **Author:** SynthoERP

Automatically back up your Odoo database on a configurable schedule.

Features
--------

- Scheduled backups via Odoo cron job (any frequency)
- Configurable local storage path
- ``zip`` (full) or ``dump`` (SQL-only) backup formats
- Automatic retention / cleanup of old backups
- Manual on-demand backup from the Admin UI

Installation
------------

1. Copy ``syntho_auto_backup`` to your addons path
2. Restart Odoo and update the app list
3. Install **Syntho Auto Backup**
4. Configure your schedule and storage path under **Settings → Auto Backup**

Dependencies
------------

- ``base``

Credits
-------

**Author:** SynthoERP — https://www.synthoerp.com/
