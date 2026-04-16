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
    @patch('subprocess.run')
    @patch('odoo.service.db.dump_db')
    @patch('builtins.open', new_callable=mock_open)
    def test_schedule_backup(self, mock_file, mock_dump_db, mock_run, mock_makedirs):
        self.config_model.schedule_backup()

        # Verify makedirs was called for both formats
        self.assertEqual(mock_makedirs.call_count, 2)

        # Verify subprocess.run was called for 'dump' format
        self.assertTrue(mock_run.called)
        args, kwargs = mock_run.call_args
        self.assertEqual(args[0][0], 'pg_dump')
        self.assertTrue(kwargs.get('check'))

        # Verify odoo.service.db.dump_db was called for 'zip' format
        self.assertTrue(mock_dump_db.called)
        self.assertEqual(mock_dump_db.call_args[0][2], 'zip')

        # Verify open was called for 'zip' format file writing
        self.assertTrue(mock_file.called)

    @patch('os.makedirs')
    @patch('subprocess.run')
    @patch('odoo.service.db.dump_db')
    @patch('builtins.open', new_callable=mock_open)
    @patch('syntho_auto_backup.models.backup_config._logger.error')
    def test_schedule_backup_pg_dump_error(self, mock_logger_error, mock_file, mock_dump_db, mock_run, mock_makedirs):
        import subprocess
        # Clear existing configs to test only the dump format
        self.config_model.search([]).unlink()
        self.config_model.create({
            'name': 'Test Dump Error',
            'folder': '/tmp/backup_dump_error',
            'format': 'dump'
        })

        # Make subprocess.run raise CalledProcessError when called for dump
        mock_run.side_effect = subprocess.CalledProcessError(1, ['pg_dump'])

        self.config_model.schedule_backup()

        # Verify that the logger was called with the error message
        db_name = self.env.cr.dbname
        mock_logger_error.assert_any_call(f"Error during pg_dump for {db_name}: Command '['pg_dump']' returned non-zero exit status 1.")
