from odoo.tests.common import TransactionCase
from unittest.mock import patch

class TestBackupConfig(TransactionCase):
    def setUp(self):
        super(TestBackupConfig, self).setUp()
        self.BackupConfig = self.env['auto.backup.config']

        # We need to set up the system parameter base_dir because
        # the syntho_auto_backup model might implement directory path validation
        # according to the memory context.
        self.env['ir.config_parameter'].sudo().set_param('syntho_auto_backup.base_dir', '/tmp/allowed_backup_dir')

        # Create a backup config record for testing
        self.config = self.BackupConfig.create({
            'name': 'Test Backup',
            'folder': '/tmp/allowed_backup_dir/test_folder',
            'format': 'zip'
        })

    @patch('odoo.addons.syntho_auto_backup.models.backup_config._logger.error')
    @patch('os.makedirs')
    def test_schedule_backup_unexpected_error(self, mock_makedirs, mock_logger_error):
        """
        Test that unexpected exceptions during the execution of a backup configuration
        are properly caught and logged.
        """
        # Mock os.makedirs to raise a generic Exception
        mock_makedirs.side_effect = Exception("Simulated unexpected error")

        # Run schedule_backup
        self.BackupConfig.schedule_backup()

        # Check that the logger error was called with the correct message
        mock_logger_error.assert_called_with(
            f"Unexpected error during backup execution for config {self.config.name}: Simulated unexpected error"
        )
