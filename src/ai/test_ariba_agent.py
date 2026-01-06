import unittest
from unittest.mock import patch, MagicMock
import sys
import os
import io

# Add parent directory to path to import ariba_agent
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from ariba_agent import AribaAI

class TestAribaAI(unittest.TestCase):
    def setUp(self):
        self.agent = AribaAI()

    @patch('shutil.disk_usage')
    @patch('os.getloadavg')
    def test_system_check_healthy(self, mock_load, mock_disk):
        # Mock healthy system
        mock_disk.return_value = (100, 20, 80) # total, used, free
        mock_load.return_value = (0.5, 0.5, 0.5)
        
        result = self.agent.system_check()
        self.assertEqual(result, ["System is healthy."])

    @patch('shutil.disk_usage')
    @patch('os.getloadavg')
    def test_system_check_issues(self, mock_load, mock_disk):
        # Mock unhealthy system
        mock_disk.return_value = (100, 95, 5) # 95% used
        mock_load.return_value = (5.0, 4.0, 4.0) # High load
        
        result = self.agent.system_check()
        self.assertTrue(len(result) == 2)
        self.assertIn("Critical", result[0])
        self.assertIn("Warning", result[1])

    @patch('subprocess.run')
    def test_suggest_optimization(self, mock_run):
        # Mock apt autoremove output
        mock_proc_apt = MagicMock()
        mock_proc_apt.stdout = "5 to remove"
        
        # Mock du output
        mock_proc_du = MagicMock()
        mock_proc_du.stdout = "500M\t/tmp"

        mock_run.side_effect = [mock_proc_apt, mock_proc_du]
        
        suggestions = self.agent.suggest_optimization()
        self.assertTrue(len(suggestions) >= 1)
        self.assertIn("autoremove", suggestions[0])

    def test_execute_command_help(self):
        response = self.agent.execute_command("help")
        self.assertIn("I can help with", response)

    def test_execute_command_unknown(self):
        response = self.agent.execute_command("foobar")
        self.assertIn("I'm sorry", response)

if __name__ == '__main__':
    unittest.main()
