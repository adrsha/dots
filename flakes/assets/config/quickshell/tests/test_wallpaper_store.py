import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import wallpaper_store as store


class WallpaperStoreTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.walls = self.root / 'walls'
        self.themes = self.root / 'themes'
        self.walls.mkdir()
        self.themes.mkdir()
        (self.walls / 'warm').mkdir()
        (self.walls / 'cold').mkdir()
        self.image = self.walls / 'warm' / 'scene.png'
        self.image.write_bytes(b'\x89PNG\r\n\x1a\n')
        self.theme = self.themes / 'test'
        self.theme.write_text('VARIANT=dark\nWALLPAPER=/old/missing.jpg\nBASE00=#abc123\n', encoding='utf-8')
        self.snapshot = self.root / 'active.json'
        self.snapshot.write_text(json.dumps({'name': 'other'}))
        self.patches = [patch.object(store, 'WALLS', self.walls), patch.object(store, 'THEMES', self.themes), patch.object(store, 'SNAPSHOT', self.snapshot)]
        for item in self.patches:
            item.start()

    def tearDown(self):
        for item in reversed(self.patches):
            item.stop()
        self.temp.cleanup()

    def test_assignment_preserves_theme_and_backs_up(self):
        self.assertEqual(store.assign('test', str(self.image)), 'Assigned to test')
        self.assertEqual(store.theme_wallpaper('test'), str(self.image))
        self.assertIn('BASE00=#abc123', self.theme.read_text())
        self.assertIn('WALLPAPER=/old/missing.jpg', (self.themes / '.wallpaper-backups' / 'test').read_text())
        self.assertEqual(len(store.themes()), 1)

    def test_rejects_theme_traversal_and_outside_media(self):
        with self.assertRaises(ValueError):
            store.assign('../test', str(self.image))
        outside = self.root / 'outside.png'
        outside.write_bytes(b'test')
        with self.assertRaises(ValueError):
            store.assign('test', str(outside))
        self.assertIn('/old/missing.jpg', self.theme.read_text())

    def test_move_refuses_theme_references_and_collisions(self):
        store.assign('test', str(self.image))
        with self.assertRaisesRegex(ValueError, 'assigned to a theme'):
            store.move(str(self.image), 'cold')
        self.assertTrue(self.image.exists())

    def test_delete_protects_theme_and_removes_sidecar(self):
        store.assign('test', str(self.image))
        with self.assertRaisesRegex(ValueError, 'assigned to a theme'):
            store.delete(str(self.image))
        self.assertTrue(self.image.exists())
        self.theme.write_text('WALLPAPER=none\n', encoding='utf-8')
        sidecar = self.image.with_name(self.image.name + '.source.json')
        sidecar.write_text('{}')
        store.delete(str(self.image))
        self.assertFalse(self.image.exists())
        self.assertFalse(sidecar.exists())

    def test_video_assignment_requires_still_before_edit(self):
        video = self.walls / 'warm' / 'loop.mp4'
        video.write_bytes(b'video')
        with patch.object(store, 'ensure_video_still', side_effect=ValueError('bad video')):
            with self.assertRaisesRegex(ValueError, 'bad video'):
                store.assign('test', str(video))
        self.assertIn('/old/missing.jpg', self.theme.read_text())
        with patch.object(store, 'ensure_video_still', return_value=self.root / 'still.jpg'):
            store.assign('test', str(video))
        self.assertEqual(store.theme_wallpaper('test'), str(video))

    def test_inventory_generates_video_stills_and_keeps_failed_videos(self):
        video = self.walls / 'warm' / 'loop.mp4'
        video.write_bytes(b'video')
        still = self.root / 'loop.jpg'
        still.write_bytes(b'still')
        with patch.object(store, 'ensure_video_still', return_value=still) as generate:
            item = next(w for w in store.inventory()['walls'] if w['video'])
        generate.assert_called_once_with(str(video))
        self.assertEqual(item['preview'], str(still))
        with patch.object(store, 'ensure_video_still', side_effect=ValueError('bad video')):
            item = next(w for w in store.inventory()['walls'] if w['video'])
        self.assertEqual(item['preview'], str(video))

    def test_move_preserves_attribution_and_import(self):
        sidecar = self.image.with_name(self.image.name + '.source.json')
        sidecar.write_text('{"source":"example"}')
        store.move(str(self.image), 'cold')
        self.assertTrue((self.walls / 'cold' / sidecar.name).exists())
        self.assertFalse(sidecar.exists())
        outside = self.root / 'new.jpg'
        outside.write_bytes(b'\xff\xd8\xff')
        self.assertEqual(store.import_file(str(outside), 'warm'), str(self.walls / 'warm' / 'new.jpg'))
        with self.assertRaises(ValueError):
            store.import_file(str(outside), '.git')

    def test_active_assignment_invokes_theme_set(self):
        self.snapshot.write_text(json.dumps({'name': 'test'}))
        with patch.object(store.subprocess, 'run') as run:
            run.return_value.returncode = 0
            store.assign('test', str(self.image))
            run.assert_called_once()
            self.assertEqual(run.call_args.args[0], ['theme-set', 'test'])


if __name__ == '__main__':
    unittest.main()
