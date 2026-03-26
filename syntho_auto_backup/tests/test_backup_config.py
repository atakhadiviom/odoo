import unittest
from unittest.mock import patch, MagicMock
import subprocess
import sys

# Mock odoo to prevent ModuleNotFoundError
mock_odoo = MagicMock()
# Specifically we need api.model to just be a pass-through decorator,
# and models.Model to be a base class.
mock_odoo.api.model = lambda func: func
mock_odoo.models.Model = object
sys.modules['odoo'] = mock_odoo

from syntho_auto_backup.models.backup_config import BackupConfig

class TestBackupConfig(unittest.TestCase):
    @patch('syntho_auto_backup.models.backup_config.os.makedirs')
    @patch('syntho_auto_backup.models.backup_config.subprocess.run')
    @patch('syntho_auto_backup.models.backup_config._logger.error')
    def test_schedule_backup_pg_dump_failure(self, mock_logger_error, mock_subprocess_run, mock_makedirs):
        # Arrange
        mock_config = MagicMock()
        mock_config.format = 'dump'
        mock_config.folder = '/tmp/backup'
        mock_config.name = 'Test Backup'

        mock_self = MagicMock()
        mock_self.search.return_value = [mock_config]
        mock_self.env.cr.dbname = 'test_db'

        # Set up subprocess.run to raise CalledProcessError
        error = subprocess.CalledProcessError(1, 'pg_dump')
        mock_subprocess_run.side_effect = error

        # Act
        BackupConfig.schedule_backup(mock_self)

        # Assert
        mock_makedirs.assert_called_once_with('/tmp/backup', exist_ok=True)
        mock_subprocess_run.assert_called_once()
        mock_logger_error.assert_called_once_with(f"Error during pg_dump for test_db: {error}")

if __name__ == '__main__':
    unittest.main()
