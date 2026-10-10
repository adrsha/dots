"""Theme generation tests: never start a locker or modify the live configuration."""
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from services import backend


class LockThemeTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.home = Path(self.temporary.name)
        self.config = self.home / '.config/hypr/hyprlock.conf'
        self.config.parent.mkdir(parents=True)
        self.source = '''general {
    grace = 0
}
background {
    path = /old/wall.png
    color = rgba(000000ff)
}
label {
    text = cmd[update:1000] date +"%H:%M"
    color = rgba(ffffff00)
}
input-field {
    size = 320, 58
    inner_color = rgba(000000ff)
    outer_color = rgba(ffffff00)
}
'''
        self.config.write_text(self.source)
        self.snapshot = self.home / '.local/state/theme/active.json'
        self.snapshot.parent.mkdir(parents=True)
        self.patcher = patch.object(backend, 'HOME', self.home)
        self.patcher.start()
        self.addCleanup(self.patcher.stop)

    def generate(self, **snapshot):
        self.snapshot.write_text(json.dumps(snapshot))
        return backend.themed_lock_config().read_text()

    def test_dark_palette_without_wallpaper(self):
        result = self.generate(variant='dark', opacity=0.4,
                               colors={'BASE02': '#171614', 'BASE06': '#ecece6', 'BASE0E': '#736a7d'})
        self.assertIn('inner_color = rgba(171614e0)', result)
        self.assertIn('outer_color = rgba(736a7dff)', result)
        self.assertIn('font_color = rgba(ecece6ff)', result)
        self.assertIn('path = /old/wall.png', result)
        self.assertIn('grace = 0', result)
        self.assertIn('size = 320, 58', result)
        self.assertEqual(self.config.read_text(), self.source)

    def test_light_palette_and_wallpaper(self):
        wall = self.home / 'wall.png'
        wall.touch()
        result = self.generate(variant='light', colors={'BASE00': '#111111', 'BASE06': '#eeeeee', 'BASE0D': '#123456'}, values={'WALLPAPER': str(wall)})
        self.assertIn('inner_color = rgba(eeeeeeff)', result)
        self.assertIn('font_color = rgba(111111ff)', result)
        self.assertIn('outer_color = rgba(123456ff)', result)
        self.assertIn('path = ' + str(wall), result)

    def test_invalid_color_is_not_injected(self):
        result = self.generate(colors={'BASE0E': '#ffffff\nmalicious = true'})
        self.assertIn('outer_color = rgba(d4c4f4ff)', result)
        self.assertNotIn('malicious', result)


if __name__ == '__main__':
    unittest.main()
