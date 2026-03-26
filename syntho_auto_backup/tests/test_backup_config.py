from odoo.tests.common import TransactionCase
from unittest.mock import patch, mock_open

class TestBackupConfig(TransactionCase):

    def setUp(self):
        super(TestBackupConfig, self).setUp()
        self.BackupConfig = self.env['auto.backup.config']

        # We need to make sure we don't pick up other configs created in db
        self.env['auto.backup.config'].search([]).unlink()

        # Create a test backup configuration
        self.config = self.BackupConfig.create({
            'name': 'Test Config',
            'folder': '/tmp/test_backup_dir',
            'format': 'zip',
        })

    @patch('syntho_auto_backup.models.backup_config._logger')
    @patch('os.makedirs')
    @patch('builtins.open', new_callable=mock_open)
    @patch('odoo.service.db.dump_db')
    def test_schedule_backup_zip_dump_db_failure(self, mock_dump_db, mock_open_file, mock_makedirs, mock_logger):
        # Configure the mock dump_db to raise an exception
        mock_dump_db.side_effect = Exception("Test dump_db error")

        # Call the method
        self.BackupConfig.schedule_backup()

        # Check that dump_db was called
        mock_dump_db.assert_called_once()

        db_name = self.env.cr.dbname

        # Verify that _logger.error was called with the correct error message
        mock_logger.error.assert_called_with(f"Error during odoo dump_db for {db_name}: Test dump_db error")
