"""Desktop capture and DDC behavior without capturing screen or changing hardware."""
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

import desktop_capture
import monitor_brightness

PNG = b'\x89PNG\r\n\x1a\nexample'


class CaptureTests(unittest.TestCase):
    def test_invalid_options_no_command(self):
        with patch('desktop_capture.subprocess.run') as run:
            self.assertIn('error', desktop_capture.capture('evil', 'save'))
            self.assertIn('error', desktop_capture.capture('region', 'evil'))
            run.assert_not_called()

    def test_missing_capture_program(self):
        with patch('desktop_capture.shutil.which', return_value=None):
            self.assertEqual(desktop_capture.capture('output', 'save')['error'], 'Install grim for screenshots')

    def test_region_cancelled_no_capture(self):
        with patch('desktop_capture.shutil.which', return_value='/usr/bin/mock'), patch('desktop_capture.subprocess.run', return_value=SimpleNamespace(returncode=1, stdout='', stderr='')) as run:
            self.assertEqual(desktop_capture.capture('region', 'save'), {'cancelled': True})
            self.assertEqual(run.call_count, 1)
            self.assertEqual(run.call_args.kwargs['stdin'], desktop_capture.subprocess.DEVNULL)

    def test_save_window_geometry_and_png(self):
        def fake_run(command, **kwargs):
            if command[:3] == ['hyprctl', '-j', 'clients']:
                return SimpleNamespace(stdout='[{"mapped": true, "workspace": {"id": 1}, "at": [12, 32], "size": [800, 600]}]')
            if command[:3] == ['hyprctl', '-j', 'monitors']:
                return SimpleNamespace(stdout='[{"activeWorkspace": {"id": 1}}]')
            if command[0] == 'slurp':
                self.assertEqual(command, ['slurp', '-r', '-w', '3'])
                self.assertEqual(kwargs['input'], '12,32 800x600\n')
                return SimpleNamespace(returncode=0, stdout='12,32 800x600\n')
            self.assertEqual(command, ['grim', '-g', '12,32 800x600', '-'])
            return SimpleNamespace(stdout=PNG)
        with tempfile.TemporaryDirectory() as temp, patch('desktop_capture.shutil.which', return_value='/usr/bin/mock'), patch('desktop_capture.subprocess.run', side_effect=fake_run):
            response = desktop_capture.capture('window', 'save', home=temp)
            self.assertEqual(Path(response['path']).read_bytes(), PNG)
            self.assertEqual(response['message'], 'Screenshot saved')

    def test_window_boxes_filter_workspaces_hidden_and_invalid(self):
        def client(workspace=1, **extra):
            return dict({'mapped': True, 'workspace': {'id': workspace}, 'at': [-100, 20], 'size': [400, 300]}, **extra)
        clients = [client(), client(2), client(hidden=True), client(mapped=False),
                   client(visible=False), client(size=[0, 20]), client(),
                   client(-99), client(2, pinned=True, at=[50, 60])]
        monitors = [{'activeWorkspace': {'id': 1}, 'specialWorkspace': {'id': 0}}]
        self.assertEqual(desktop_capture.window_boxes(clients, monitors), ['-100,20 400x300', '50,60 400x300'])
        monitors[0]['specialWorkspace']['id'] = -99
        self.assertEqual(len(desktop_capture.window_boxes([client(-99)], monitors)), 1)

    def test_window_cancelled_or_invalid_never_captures(self):
        for picked, expected in [(SimpleNamespace(returncode=1, stdout='', stderr=''), 'cancelled'),
                                 (SimpleNamespace(returncode=0, stdout='0,0 1x1', stderr=''), 'error')]:
            responses = [SimpleNamespace(stdout='[{"mapped": true, "workspace": {"id": 1}, "at": [12, 32], "size": [800, 600]}]'),
                         SimpleNamespace(stdout='[{"activeWorkspace": {"id": 1}}]'), picked]
            with patch('desktop_capture.shutil.which', return_value='/usr/bin/mock'), patch('desktop_capture.subprocess.run', side_effect=responses) as run:
                self.assertIn(expected, desktop_capture.capture('window', 'save'))
                self.assertEqual(run.call_count, 3)

    def test_window_no_visible_clients(self):
        responses = [SimpleNamespace(stdout='[]'), SimpleNamespace(stdout='[]')]
        with patch('desktop_capture.shutil.which', return_value='/usr/bin/mock'), patch('desktop_capture.subprocess.run', side_effect=responses) as run:
            self.assertIn('No visible windows', desktop_capture.capture('window', 'save')['error'])
            self.assertEqual(run.call_count, 2)

    def test_lens_copies_before_browser(self):
        calls = []
        def fake_run(command, **kwargs):
            calls.append(command)
            if command[0] == 'hyprctl':
                return SimpleNamespace(stdout='[{"focused": true, "name": "DP-1", "x": 0, "y": 0, "width": 1920, "height": 1080}]')
            return SimpleNamespace(stdout=PNG)
        with patch('desktop_capture.shutil.which', return_value='/usr/bin/mock'), patch('desktop_capture.subprocess.run', side_effect=fake_run), patch('desktop_capture.subprocess.Popen') as browser:
            response = desktop_capture.capture('output', 'lens')
            self.assertEqual([command[0] for command in calls], ['hyprctl', 'grim', 'wl-copy'])
            browser.assert_called_once()
            self.assertIn('paste or upload', response['message'])

    def test_invalid_png_not_saved(self):
        with patch('desktop_capture.shutil.which', return_value='/usr/bin/mock'), patch('desktop_capture.subprocess.run', return_value=SimpleNamespace(stdout=b'bad')):
            self.assertIn('error', desktop_capture.capture('output', 'save'))

    def test_scaled_rotated_output_uses_output_name(self):
        calls = []
        def fake_run(command, **kwargs):
            calls.append((command, kwargs))
            if command[0] == 'hyprctl':
                return SimpleNamespace(stdout='[{"focused": true, "name": "DP-2", "width": 3840, "height": 2160, "scale": 2, "transform": 1}]')
            return SimpleNamespace(stdout=PNG)
        with patch('desktop_capture.shutil.which', return_value='/usr/bin/mock'), patch('desktop_capture.subprocess.run', side_effect=fake_run):
            response = desktop_capture.capture('output', 'clipboard')
        self.assertEqual(response['message'], 'Screenshot copied')
        self.assertEqual(calls[1][0], ['grim', '-o', 'DP-2', '-'])
        self.assertNotIn('capture_output', calls[2][1])
        self.assertEqual(calls[2][1]['stdout'], desktop_capture.subprocess.DEVNULL)

    def test_output_without_name_is_reported(self):
        with patch('desktop_capture.shutil.which', return_value='/usr/bin/mock'), patch('desktop_capture.subprocess.run', return_value=SimpleNamespace(stdout='[{"focused": true}]')) as run:
            self.assertIn('output name', desktop_capture.capture('output', 'save')['error'])
            run.assert_called_once()


class BrightnessTests(unittest.TestCase):
    def test_parse_vcp(self):
        self.assertEqual(monitor_brightness.parse_vcp('VCP 10 C 40 100'), (40, 100))
        with self.assertRaises(ValueError):
            monitor_brightness.parse_vcp('unsupported')

    def test_invalid_step_no_hardware_call(self):
        with patch('monitor_brightness.subprocess.run') as run:
            self.assertIn('error', monitor_brightness.change(25))
            run.assert_not_called()

    def test_clamped_brightness_and_serialized_command(self):
        with tempfile.TemporaryDirectory() as temp, patch('monitor_brightness.subprocess.run') as run:
            run.return_value = SimpleNamespace(stdout='VCP 10 C 98 100')
            response = monitor_brightness.change(5, lock_path=Path(temp) / 'ddc.lock')
            self.assertEqual(response['value'], 100)
            self.assertEqual(run.call_args_list[0].args[0], ['ddcutil', 'getvcp', '10', '--brief'])
            self.assertEqual(run.call_args_list[1].args[0], ['ddcutil', 'setvcp', '10', '100'])

    def test_no_set_when_at_limit(self):
        with tempfile.TemporaryDirectory() as temp, patch('monitor_brightness.subprocess.run') as run:
            run.return_value = SimpleNamespace(stdout='VCP 10 C 100 100')
            self.assertEqual(monitor_brightness.change(5, lock_path=Path(temp) / 'ddc.lock')['value'], 100)
            run.assert_called_once()


if __name__ == '__main__':
    unittest.main()
