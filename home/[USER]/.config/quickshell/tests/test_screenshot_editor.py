"""Filename and staged screenshot editor delivery regression tests."""
import base64
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

import desktop_capture as capture

PNG = b'\x89PNG\r\n\x1a\nimage-data'


class ScreenshotEditorTests(unittest.TestCase):
    def test_filename_validation(self):
        self.assertEqual(capture.validate_filename(' notes.PNG '), 'notes')
        self.assertEqual(capture.validate_filename(''), '')
        for name in ('../escape', 'folder/file', 'folder\\file', '..', '.png', 'bad\nname', 'x' * 201):
            with self.subTest(name=name), self.assertRaises(ValueError):
                capture.validate_filename(name)

    def test_save_collision_does_not_overwrite(self):
        with tempfile.TemporaryDirectory() as home:
            first = capture.deliver(PNG, 'save', home=home, filename='notes.png')
            second = capture.deliver(PNG + b'new', 'save', home=home, filename='notes')
            self.assertEqual(Path(first['path']).name, 'notes.png')
            self.assertEqual(Path(second['path']).name, 'notes-1.png')
            self.assertEqual(Path(first['path']).read_bytes(), PNG)

    def test_capture_stages_without_delivery(self):
        with patch.object(capture.shutil, 'which', return_value='/usr/bin/tool'), patch.object(capture.subprocess, 'run', side_effect=[
                subprocess.CompletedProcess(['slurp'], 0, '0,0 10x10', ''),
                subprocess.CompletedProcess(['grim'], 0, PNG, b'')]), patch.object(capture, 'deliver') as delivery:
            result = capture.capture('region', 'clipboard', edit=True)
            self.assertTrue(result['editing'])
            self.assertEqual(Path(result['path']).read_bytes(), PNG)
            delivery.assert_not_called()
            self.assertEqual(capture.discard_edit(result['path']), {'cancelled': True})
            self.assertFalse(Path(result['path']).parent.exists())

    def test_finish_delivers_edited_png_and_cleans_up(self):
        directory = Path(tempfile.mkdtemp(prefix='quickshell-screenshot-'))
        path = directory / 'edited.png'
        (directory / 'original.png').write_bytes(PNG)
        data = 'data:image/png;base64,' + base64.b64encode(PNG).decode()
        try:
            with patch.object(capture, 'deliver', return_value={'message': 'Copied'}) as delivery:
                self.assertEqual(capture.finish_edit(str(path), 'clipboard', data=data), {'message': 'Copied'})
                delivery.assert_called_once_with(PNG, 'clipboard', filename='')
            self.assertFalse(directory.exists())
        finally:
            if directory.exists():
                capture.discard_edit(str(path))

    def test_failed_delivery_retains_edit_for_retry(self):
        directory = Path(tempfile.mkdtemp(prefix='quickshell-screenshot-'))
        path = directory / 'edited.png'
        path.write_bytes(PNG)
        try:
            with patch.object(capture, 'deliver', return_value={'error': 'Unavailable'}):
                self.assertIn('error', capture.finish_edit(str(path), 'clipboard'))
            self.assertTrue(path.exists())
        finally:
            capture.discard_edit(str(path))

    def test_rejects_unrelated_paths(self):
        self.assertIn('error', capture.finish_edit('/tmp/unrelated.png', 'save'))
        self.assertIn('error', capture.discard_edit('/tmp/unrelated.png'))
