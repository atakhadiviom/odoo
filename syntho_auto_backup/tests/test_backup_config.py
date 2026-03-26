from odoo.tests.common import TransactionCase
from unittest.mock import patch, mock_open
import logging

class TestBackupConfig(TransactionCase):

    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        cls.BackupConfig = cls.env['auto.backup.config']
        cls.config_zip = cls.BackupConfig.create({
            'name': 'Test Zip Backup',
            'folder': '/tmp/test_backup',
            'format': 'zip'
        })

    @patch('syntho_auto_backup.models.backup_config.os.makedirs')
    @patch('builtins.open', new_callable=mock_open)
    @patch('odoo.service.db.dump_db')
    @patch('syntho_auto_backup.models.backup_config._logger.error')
    def test_backup_zip_dump_db_exception(self, mock_logger_error, mock_dump_db, mock_file, mock_makedirs):
        # Setup the mock to raise an exception when dump_db is called
        mock_dump_db.side_effect = Exception("Mocked dump_db error")

        # We only want to test our specific config, so we can mock search to return just our config
        with patch.object(self.BackupConfig.__class__, 'search', return_value=self.config_zip):
            self.BackupConfig.schedule_backup()

        # Verify that the correct error was logged
        db_name = self.env.cr.dbname
        mock_logger_error.assert_any_call(f"Error during odoo dump_db for {db_name}: Mocked dump_db error")
