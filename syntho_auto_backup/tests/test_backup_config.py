from odoo.tests.common import TransactionCase
from unittest.mock import patch

class TestBackupConfig(TransactionCase):

    def setUp(self):
        super(TestBackupConfig, self).setUp()
        self.BackupConfig = self.env['auto.backup.config']
        self.config = self.BackupConfig.create({
            'name': 'Test Config',
            'folder': '/tmp/test_backup',
            'format': 'zip'
        })

    @patch('odoo.addons.syntho_auto_backup.models.backup_config._logger.error')
    @patch('odoo.addons.syntho_auto_backup.models.backup_config.os.makedirs')
    def test_schedule_backup_unexpected_error(self, mock_makedirs, mock_logger_error):
        # Setup the mock to raise an exception
        mock_makedirs.side_effect = Exception("Simulated os.makedirs failure")

        # Call the method
        self.BackupConfig.schedule_backup()

        # Verify the exception was caught and logged appropriately at the top level
        mock_logger_error.assert_any_call(
            f"Unexpected error during backup execution for config {self.config.name}: Simulated os.makedirs failure"
        )
