import odoo
from odoo import models, fields, api
from odoo.exceptions import ValidationError
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

    @api.constrains('folder')
    def _check_folder_path(self):
        for record in self:
            if not record.folder:
                continue

            base_dir = self.env['ir.config_parameter'].sudo().get_param('auto_backup.base_dir', '/var/lib/odoo/backups')
            abs_base_dir = os.path.abspath(base_dir)
            abs_folder = os.path.abspath(record.folder)

            try:
                if os.path.commonpath([abs_base_dir, abs_folder]) != abs_base_dir:
                    raise ValidationError(f"Backup directory must be within {abs_base_dir}")
            except ValueError:
                raise ValidationError(f"Backup directory must be within {abs_base_dir}")

    @api.model
    def schedule_backup(self):
        configs = self.search([])
        for config in configs:
            try:
                config._check_folder_path()
                os.makedirs(config.folder, exist_ok=True)
                db_name = self.env.cr.dbname
                date_str = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
                filename = f"{db_name}_{date_str}.{config.format}"
                filepath = os.path.abspath(os.path.join(config.folder, filename))

                if config.format == 'dump':
                    # Use pg_dump for custom dump format
                    try:
                        subprocess.run(['pg_dump', '--format=c', f'--file={filepath}', '--', db_name], check=True)
                        _logger.info(f"Successfully backed up {db_name} to {filepath}")
                    except subprocess.CalledProcessError as e:
                        _logger.error(f"Error during pg_dump for {db_name}: {e}")
                else:
                    # For zip format, use odoo built-in db dump_db
                    try:
                        with open(filepath, 'wb') as f:
                            odoo.service.db.dump_db(db_name, f, 'zip')
                        _logger.info(f"Successfully backed up {db_name} to {filepath} in zip format")
                    except Exception as e:
                        _logger.error(f"Error during odoo dump_db for {db_name}: {e}")

            except Exception as e:
                _logger.error(f"Unexpected error during backup execution for config {config.name}: {e}")
