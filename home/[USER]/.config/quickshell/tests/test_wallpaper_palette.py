import colorsys
import unittest
from unittest.mock import patch
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'services'))
import wallpaper_palette


class WallpaperPaletteTests(unittest.TestCase):
    def test_complete_palette_and_wallpaper_hue(self):
        red = wallpaper_palette.palette_from_rgb(bytes([220, 30, 30]) * 100)
        blue = wallpaper_palette.palette_from_rgb(bytes([30, 30, 220]) * 100)
        self.assertEqual(len(red), 16)
        self.assertNotEqual(red['BASE01'], blue['BASE01'])
        self.assertTrue(all(len(c) == 7 and c.startswith('#') for c in red.values()))

    def test_variant_preserves_light_dark_ramps(self):
        pixels = bytes([50, 150, 80]) * 100
        def lightness(color):
            return colorsys.rgb_to_hls(*(int(color[i:i+2], 16) / 255 for i in (1, 3, 5)))[1]
        dark = wallpaper_palette.palette_from_rgb(pixels, 'dark')
        light = wallpaper_palette.palette_from_rgb(pixels, 'light')
        self.assertLess(lightness(dark['BASE01']), .2)
        self.assertGreater(lightness(light['BASE01']), .8)
        self.assertGreater(lightness(dark['BASE06']), .8)
        self.assertLess(lightness(light['BASE07']), .2)

    def test_invalid_input(self):
        for data, variant in [(b'', 'dark'), (b'x', 'dark'), (b'abc', 'invalid')]:
            with self.assertRaises(ValueError):
                wallpaper_palette.palette_from_rgb(data, variant)

    @patch('wallpaper_palette.subprocess.run')
    def test_missing_file_never_decodes(self, run):
        with self.assertRaises(OSError):
            wallpaper_palette.preview('/does/not/exist/qs-wall.png', 'dark')
        run.assert_not_called()

    def test_non_https_source_rejected(self):
        with self.assertRaises(ValueError):
            wallpaper_palette.preview('http://example.com/a.png', 'dark')
