from odoo.tests.common import TransactionCase
from unittest.mock import patch, mock_open
import logging

class TestBackupConfig(TransactionCase):

    def setUp(self):
        super(TestBackupConfig, self).setUp()
        self.BackupConfig = self.env['auto.backup.config']

        # We need a system parameter base_dir to pass the path validation constraints
        # as mentioned in the memory
        self.env['ir.config_parameter'].sudo().set_param('syntho_auto_backup.base_dir', '/tmp')

    @patch('syntho_auto_backup.models.backup_config._logger.error')
    @patch('odoo.service.db.dump_db')
    @patch('builtins.open', new_callable=mock_open)
    @patch('os.makedirs')
    def test_backup_schedule_zip_dump_db_exception(self, mock_makedirs, mock_file, mock_dump_db, mock_logger_error):
        """Test that an exception during odoo.service.db.dump_db is correctly caught and logged."""
        # Create a backup config
        config = self.BackupConfig.create({
            'name': 'Test Zip Backup Error',
            'folder': '/tmp/test_backup_dir',
            'format': 'zip',
        })

        # Configure dump_db to raise an exception
        mock_dump_db.side_effect = Exception('Simulated dump_db error')

        # Execute backup
        config.schedule_backup()

        # Assert that the error logger was called with the expected message
        db_name = self.env.cr.dbname
        mock_logger_error.assert_any_call(f"Error during odoo dump_db for {db_name}: Simulated dump_db error")
