from odoo import models, fields, api
import os
import datetime
import subprocess
import logging

_logger = logging.getLogger(__name__)

class BackupConfig(models.Model):
    _name = 'auto.backup.config'
    _description = 'Backup Configuration'

    name = fields.Char('Name', required=True)
    folder = fields.Char('Backup Directory', required=True)
    format = fields.Selection([
        ('zip', 'Zip'),
        ('dump', 'Dump')
    ], string='Format', default='zip')

    @api.model
    def schedule_backup(self):
        configs = self.search([])
        for config in configs:
            try:
                os.makedirs(config.folder, exist_ok=True)
                db_name = self.env.cr.dbname
                date_str = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
                filename = f"{db_name}_{date_str}.{config.format}"
                filepath = os.path.join(config.folder, filename)

                if config.format == 'dump':
                    # Use pg_dump for custom dump format
                    try:
                        subprocess.run(['pg_dump', '--format=c', f'--file={filepath}', db_name], check=True)
                        _logger.info(f"Successfully backed up {db_name} to {filepath}")
                    except subprocess.CalledProcessError as e:
                        _logger.error(f"Error during pg_dump for {db_name}: {e}")
                else:
                    # For zip format, use odoo built-in db dump_db
                    import odoo
                    try:
                        with open(filepath, 'wb') as f:
                            odoo.service.db.dump_db(db_name, f, 'zip')
                        _logger.info(f"Successfully backed up {db_name} to {filepath} in zip format")
                    except Exception as e:
                        _logger.error(f"Error during odoo dump_db for {db_name}: {e}")

            except Exception as e:
                _logger.error(f"Unexpected error during backup execution for config {config.name}: {e}")
