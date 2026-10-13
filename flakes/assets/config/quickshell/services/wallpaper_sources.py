"""Search documented wallpaper APIs; downloads resolve IDs again, never arbitrary URLs."""
import json
import os
from pathlib import Path
import re
import tempfile
import urllib.error
import urllib.parse
import urllib.request

from wallpaper_store import WALLS

AGENT = 'QuickshellWallpaperStudio/0.1 (personal wallpaper picker)'
MAX_IMAGE = 40 * 1024 * 1024


class SafeRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        allowed = {'wallhaven.cc', 'w.wallhaven.cc', 'api.unsplash.com', 'images.unsplash.com', 'api.pexels.com', 'images.pexels.com', 'videos.pexels.com'}
        parsed = urllib.parse.urlsplit(newurl)
        if parsed.scheme != 'https' or parsed.hostname not in allowed:
            raise ValueError('Provider redirected to untrusted host')
        return super().redirect_request(req, fp, code, msg, headers, newurl)


def get(url, headers=None, limit=2 * 1024 * 1024):
    allowed = {'wallhaven.cc', 'w.wallhaven.cc', 'api.unsplash.com', 'images.unsplash.com', 'api.pexels.com', 'images.pexels.com', 'videos.pexels.com'}
    parsed = urllib.parse.urlsplit(url)
    if parsed.scheme != 'https' or parsed.hostname not in allowed:
        raise ValueError('Unexpected provider host')
    request = urllib.request.Request(url, headers={'User-Agent': AGENT, **(headers or {})})
    with urllib.request.build_opener(SafeRedirect()).open(request, timeout=16) as response:
        if response.status != 200:
            raise ValueError('Provider returned HTTP ' + str(response.status))
        data = response.read(limit + 1)
        if len(data) > limit:
            raise ValueError('Provider response exceeds size limit')
        return data


def json_get(url, headers=None):
    return json.loads(get(url, headers))


def provider_data(provider, query, item_id=None):
    if provider == 'wallhaven':
        if item_id:
            if not re.fullmatch(r'[a-z0-9]{6}', item_id):
                raise ValueError('Invalid wallpaper ID')
            data = [json_get('https://wallhaven.cc/api/v1/w/' + item_id)['data']]
        else:
            params = urllib.parse.urlencode({'q': query[:90], 'atleast': '1920x1080', 'purity': '100', 'sorting': 'relevance'})
            data = json_get('https://wallhaven.cc/api/v1/search?' + params)['data']
        return [{'provider': provider, 'id': x['id'], 'title': 'Wallhaven ' + x['id'], 'preview': x['thumbs']['large'],
                 'source': x['url'], 'author': 'Wallhaven contributor', 'license': 'Creator retains rights; personal use only',
                 'width': x['dimension_x'], 'height': x['dimension_y'], 'video': False,
                 '_download': x['path']} for x in data if x.get('purity') == 'sfw' and x.get('dimension_x', 0) >= 1920 and x.get('dimension_y', 0) >= 1080]
    if provider == 'unsplash':
        key = os.environ.get('UNSPLASH_ACCESS_KEY', '')
        if not key:
            raise ValueError('Unsplash needs UNSPLASH_ACCESS_KEY in Quickshell environment')
        headers = {'Authorization': 'Client-ID ' + key, 'Accept-Version': 'v1'}
        if item_id:
            if not re.fullmatch(r'[A-Za-z0-9_-]{1,48}', item_id):
                raise ValueError('Invalid photo ID')
            data = [json_get('https://api.unsplash.com/photos/' + item_id, headers)]
        else:
            params = urllib.parse.urlencode({'query': query[:90], 'per_page': 24, 'orientation': 'landscape', 'content_filter': 'high'})
            data = json_get('https://api.unsplash.com/search/photos?' + params, headers)['results']
        return [{'provider': provider, 'id': x['id'], 'title': (x.get('description') or x.get('alt_description') or 'Unsplash photo')[:100],
                 'preview': x['urls']['regular'], 'source': x['links']['html'], 'author': x['user']['name'],
                 'license': 'Unsplash License', 'width': x['width'], 'height': x['height'], 'video': False,
                 '_download': x['links']['download_location']} for x in data if x.get('width', 0) >= 1920 and x.get('height', 0) >= 1080]
    if provider == 'pexels-video':
        key = os.environ.get('PEXELS_API_KEY', '')
        if not key:
            raise ValueError('Pexels videos need PEXELS_API_KEY in Quickshell environment')
        headers = {'Authorization': key}
        if item_id:
            if not re.fullmatch(r'[0-9]{1,14}', item_id):
                raise ValueError('Invalid media ID')
            data = [json_get('https://api.pexels.com/videos/videos/' + item_id, headers)]
        else:
            params = urllib.parse.urlencode({'query': query[:90], 'per_page': 20, 'orientation': 'landscape', 'size': 'large'})
            data = json_get('https://api.pexels.com/videos/search?' + params, headers)['videos']
        results = []
        for x in data:
            if x.get('width', 0) < 1920 or x.get('height', 0) < 1080:
                continue
            files = [f for f in x.get('video_files', []) if f.get('file_type') == 'video/mp4' and f.get('width', 0) >= 1920 and f.get('height', 0) >= 1080]
            if not files:
                continue
            best = min(files, key=lambda f: f['width'] * f['height'])
            results.append({'provider': provider, 'id': str(x['id']), 'title': 'Pexels video ' + str(x['id']),
                            'preview': x['image'], 'source': x['url'], 'author': x.get('user', {}).get('name', 'Pexels creator'),
                            'license': 'Pexels License', 'width': best['width'], 'height': best['height'], 'video': True,
                            '_download': best['link']})
        return results
    if provider == 'pexels':
        key = os.environ.get('PEXELS_API_KEY', '')
        if not key:
            raise ValueError('Pexels needs PEXELS_API_KEY in Quickshell environment')
        headers = {'Authorization': key}
        if item_id:
            if not re.fullmatch(r'[0-9]{1,14}', item_id):
                raise ValueError('Invalid media ID')
            data = [json_get('https://api.pexels.com/v1/photos/' + item_id, headers)]
        else:
            params = urllib.parse.urlencode({'query': query[:90], 'per_page': 24, 'orientation': 'landscape', 'size': 'large'})
            data = json_get('https://api.pexels.com/v1/search?' + params, headers)['photos']
        return [{'provider': provider, 'id': str(x['id']), 'title': (x.get('alt') or 'Pexels photo')[:100],
                 'preview': x['src']['large'], 'source': x['url'], 'author': x['photographer'], 'license': 'Pexels License',
                 'width': x['width'], 'height': x['height'], 'video': False, '_download': x['src']['original']}
                for x in data if x.get('width', 0) >= 1920 and x.get('height', 0) >= 1080]
    raise ValueError('Unknown provider')


def search(provider, query):
    if not query.strip():
        raise ValueError('Enter search terms')
    try:
        return [{k: v for k, v in x.items() if not k.startswith('_')} for x in provider_data(provider, query)]
    except (urllib.error.URLError, TimeoutError, KeyError, json.JSONDecodeError) as exc:
        raise ValueError('Provider unavailable: ' + str(exc)) from exc


def download(provider, item_id, category):
    # No URL supplied by caller; refetch item metadata and whitelist asset host.
    if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_-]{0,63}', category) or category.startswith('.'):
        raise ValueError('Invalid category')
    directory = WALLS / category
    if not directory.is_dir() or directory.is_symlink():
        raise ValueError('Choose existing category')
    try:
        item = provider_data(provider, '', item_id)[0]
        if item['id'] != item_id:
            raise ValueError('Provider returned unexpected media ID')
        url = item['_download']
        if provider == 'unsplash':
            key = os.environ.get('UNSPLASH_ACCESS_KEY', '')
            url = json_get(url, {'Authorization': 'Client-ID ' + key})['url']  # Unsplash required download tracking
        host = urllib.parse.urlsplit(url).hostname
        if host not in {'w.wallhaven.cc', 'images.unsplash.com', 'images.pexels.com', 'videos.pexels.com'} or urllib.parse.urlsplit(url).scheme != 'https':
            raise ValueError('Unexpected asset host')
        data = get(url, limit=400 * 1024 * 1024 if item['video'] else MAX_IMAGE)
        if item['video']:
            if len(data) < 16 or data[4:8] != b'ftyp':
                raise ValueError('Downloaded file is not MP4 video')
            ext = '.mp4'
        elif data.startswith(b'\xff\xd8\xff'):
            ext = '.jpg'
        elif data.startswith(b'\x89PNG\r\n\x1a\n'):
            ext = '.png'
        elif data.startswith(b'RIFF') and data[8:12] == b'WEBP':
            ext = '.webp'
        else:
            raise ValueError('Downloaded file is not a supported image')
        path = directory / (provider + '-' + item_id + ext)
        if path.exists():
            raise ValueError('Already downloaded')
        descriptor, temp = tempfile.mkstemp(prefix='.wall-download-', dir=directory)
        try:
            with os.fdopen(descriptor, 'wb') as stream:
                stream.write(data)
                stream.flush()
                os.fsync(stream.fileno())
            os.replace(temp, path)
        finally:
            if os.path.exists(temp):
                os.unlink(temp)
        # Attribution retained alongside imported file, without changing original theme syntax.
        metadata = {k: item[k] for k in ('provider', 'id', 'source', 'author', 'license', 'width', 'height')}
        (directory / (path.name + '.source.json')).write_text(json.dumps(metadata, ensure_ascii=False, indent=2), encoding='utf-8')
        return str(path)
    except (urllib.error.URLError, TimeoutError, KeyError, IndexError, json.JSONDecodeError) as exc:
        raise ValueError('Download unavailable: ' + str(exc)) from exc
