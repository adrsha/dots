import unittest
from unittest.mock import patch
from pathlib import Path
import tempfile
import json

import wallpaper_sources as sources


class ProviderTests(unittest.TestCase):
    def test_rejects_arbitrary_hosts(self):
        for url in ('http://images.unsplash.com/x.jpg', 'https://images.unsplash.com.evil/x', 'https://127.0.0.1/'):
            with self.subTest(url=url), self.assertRaises(ValueError):
                sources.get(url)

    def test_rejects_invalid_ids_before_network(self):
        with self.assertRaisesRegex(ValueError, 'Invalid wallpaper ID'):
            sources.provider_data('wallhaven', '', '../../bad')
        with self.assertRaisesRegex(ValueError, 'Invalid photo ID'):
            with patch.dict('os.environ', {'UNSPLASH_ACCESS_KEY': 'test'}):
                sources.provider_data('unsplash', '', '../bad')

    def test_redirect_rejects_untrusted_host(self):
        handler = sources.SafeRedirect()
        with self.assertRaisesRegex(ValueError, 'untrusted host'):
            handler.redirect_request(None, None, 302, 'Found', {}, 'https://internal.example/test')

    def test_video_results_require_hd_mp4(self):
        video = {'id': 42, 'width': 2560, 'height': 1440, 'image': 'https://images.pexels.com/image.jpg',
                 'url': 'https://www.pexels.com/video/42', 'user': {'name': 'Author'},
                 'video_files': [{'file_type': 'video/mp4', 'width': 1920, 'height': 1080, 'link': 'https://videos.pexels.com/a.mp4'}]}
        with patch.dict('os.environ', {'PEXELS_API_KEY': 'test'}), patch.object(sources, 'json_get', return_value={'videos': [video]}):
            results = sources.search('pexels-video', 'landscape')
        self.assertEqual(len(results), 1)
        self.assertTrue(results[0]['video'])
        self.assertNotIn('_download', results[0])

    def test_download_refetches_id_and_records_attribution(self):
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / 'warm'
            target.mkdir()
            item = {'id': 'ab1234', 'provider': 'wallhaven', 'source': 'https://wallhaven.cc/w/ab1234',
                    'author': 'Artist', 'license': 'Creator retains rights', 'width': 2560, 'height': 1440,
                    'video': False, '_download': 'https://w.wallhaven.cc/full/ab/wallhaven-ab1234.jpg'}
            with patch.object(sources, 'WALLS', Path(directory)), patch.object(sources, 'provider_data', return_value=[item]), patch.object(sources, 'get', return_value=b'\xff\xd8\xffimage'):
                result = Path(sources.download('wallhaven', 'ab1234', 'warm'))
                self.assertTrue(result.is_file())
                self.assertEqual(json.loads(result.with_name(result.name + '.source.json').read_text())['author'], 'Artist')
                with self.assertRaises(ValueError):
                    sources.download('wallhaven', 'ab1234', 'warm')

    def test_wallhaven_filters_to_sfw_hd(self):
        sample = {'id': 'ab1234', 'purity': 'sfw', 'dimension_x': 2560, 'dimension_y': 1440,
                  'thumbs': {'large': 'https://th.wallhaven.cc/lg/ab/ab1234.jpg'},
                  'url': 'https://wallhaven.cc/w/ab1234', 'path': 'https://w.wallhaven.cc/full/ab/wallhaven-ab1234.jpg'}
        with patch.object(sources, 'json_get', return_value={'data': [sample, {**sample, 'purity': 'nsfw'}]}):
            found = sources.search('wallhaven', 'landscape')
        self.assertEqual(len(found), 1)
        self.assertNotIn('_download', found[0])


if __name__ == '__main__':
    unittest.main()
