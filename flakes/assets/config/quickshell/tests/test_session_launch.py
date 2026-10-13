"""Desktop apps must leave the Quickshell cgroup via UWSM, not gtk-launch."""
import subprocess
import unittest
from unittest.mock import patch
from services import backend


class SessionLaunchTests(unittest.TestCase):
    def test_launch_uses_uwsm(self):
        with patch.object(backend, 'apps', return_value=[{'id': 'firefox.desktop'}]), patch.object(backend.subprocess, 'run') as run:
            self.assertEqual(backend.action(['launch', 'firefox.desktop']), 'Launched')
            self.assertEqual(run.call_args.args[0], ['uwsm', 'app', '--', 'firefox.desktop'])
            self.assertTrue(run.call_args.kwargs['check'])
            self.assertEqual(run.call_args.kwargs['timeout'], 10)

    def test_failed_launch_reports_failure(self):
        for error in [OSError('missing uwsm'), subprocess.CalledProcessError(1, ['uwsm']), subprocess.TimeoutExpired(['uwsm'], 10)]:
            with patch.object(backend, 'apps', return_value=[{'id': 'firefox.desktop'}]), patch.object(backend.subprocess, 'run', side_effect=error):
                self.assertNotEqual(backend.action(['launch', 'firefox.desktop']), 'Launched')

    def test_unknown_desktop_entry_is_not_launched(self):
        with patch.object(backend, 'apps', return_value=[]), patch.object(backend.subprocess, 'run') as run:
            backend.action(['launch', 'unknown.desktop'])
            run.assert_not_called()
