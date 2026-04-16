from odoo.tests.common import TransactionCase
from unittest.mock import patch, mock_open

class TestBackupConfig(TransactionCase):
    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        cls.config_model = cls.env['auto.backup.config']
        cls.env['ir.config_parameter'].sudo().set_param('auto_backup.base_dir', '/tmp')
        cls.config_model.search([]).unlink() # Clear existing configs
        cls.config_model.create({
            'name': 'Test Zip',
            'folder': '/tmp/backup_zip',
            'format': 'zip'
        })
        cls.config_model.create({
            'name': 'Test Dump',
            'folder': '/tmp/backup_dump',
            'format': 'dump'
        })

    @patch('os.makedirs')
    @patch('odoo.service.db.dump_db')
    @patch('builtins.open', new_callable=mock_open)
    def test_schedule_backup(self, mock_file, mock_dump_db, mock_makedirs):
        self.config_model.schedule_backup()

        # Verify makedirs was called for both formats
        self.assertEqual(mock_makedirs.call_count, 2)

        # Verify odoo.service.db.dump_db was called for both formats
        self.assertEqual(mock_dump_db.call_count, 2)

        # Verify formats passed correctly
        formats_used = [call[0][2] for call in mock_dump_db.call_args_list]
        self.assertIn('zip', formats_used)
        self.assertIn('sql', formats_used)

        # Verify open was called for both file writings
        self.assertEqual(mock_file.call_count, 2)
