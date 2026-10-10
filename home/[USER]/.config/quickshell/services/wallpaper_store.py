"""Validated local wallpaper inventory and atomic theme-file updates."""
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

HOME = Path.home()
WALLS = HOME / 'Pictures/walls'
THEMES = HOME / '.config/theme-manager/themes'
SNAPSHOT = HOME / '.local/state/theme/active.json'
IMAGES = {'.png', '.jpg', '.jpeg', '.webp'}
VIDEOS = {'.mp4', '.m4v', '.mkv', '.mov', '.webm'}
MEDIA = IMAGES | VIDEOS


def media_path(value):
    path = Path(value).expanduser().resolve(strict=True)
    if not path.is_file() or path.suffix.lower() not in MEDIA or not path.is_relative_to(WALLS.resolve()):
        raise ValueError('Wallpaper must be a local image or video under ~/Pictures/walls')
    if '\n' in str(path) or '\r' in str(path):
        raise ValueError('Invalid wallpaper path')
    return path


def theme_path(name):
    if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_-]{0,79}', name):
        raise ValueError('Invalid theme name')
    path = THEMES / name
    if name.endswith('-backup') or path.is_symlink() or not path.is_file():
        raise ValueError('Theme not installed')
    return path


def theme_wallpaper(name):
    lines = theme_path(name).read_text(encoding='utf-8').splitlines()
    return next((line.partition('=')[2].strip() for line in lines if re.match(r'^\s*WALLPAPER\s*=', line)), '')


def themes():
    if not THEMES.is_dir():
        return []
    try:
        active = json.loads(SNAPSHOT.read_text(encoding='utf-8')).get('name', '')
    except (OSError, ValueError):
        active = ''
    items = []
    for path in sorted(THEMES.iterdir()):
        if path.name.endswith('.wallpaper-backup') or path.name.startswith('.'):
            continue
        try:
            wall = theme_wallpaper(path.name)
            items.append({'name': path.name, 'wallpaper': wall, 'missing': bool(wall and not Path(wall).expanduser().is_file()), 'active': path.name == active})
        except (ValueError, OSError, UnicodeError):
            continue
    return items


def video_still(path):
    import hashlib
    digest = hashlib.sha256(str(path.resolve()).encode()).hexdigest()
    return HOME / '.cache/quickshell/video-stills' / (digest + '.jpg')


def ensure_video_still(value):
    path = media_path(value)
    if path.suffix.lower() not in VIDEOS:
        raise ValueError('Expected video file')
    still = video_still(path)
    if not still.is_file() or still.stat().st_mtime < path.stat().st_mtime:
        still.parent.mkdir(parents=True, exist_ok=True)
        result = subprocess.run(['ffmpeg', '-nostdin', '-loglevel', 'error', '-y', '-ss', '00:00:01', '-i', str(path), '-frames:v', '1', '-vf', 'scale=1280:-2', str(still)], capture_output=True, text=True, timeout=35)
        if result.returncode or not still.is_file():
            raise ValueError('Video preview extraction failed: ' + result.stderr[-180:])
    return still


def inventory():
    if not WALLS.is_dir():
        return {'categories': [], 'walls': [], 'themes': themes()}
    root = WALLS.resolve()
    categories = sorted(p.name for p in WALLS.iterdir() if p.is_dir() and not p.is_symlink() and not p.name.startswith('.'))
    items = []
    for p in sorted(WALLS.rglob('*')):
        if p.is_file() and p.suffix.lower() in MEDIA and p.resolve().is_relative_to(root) and not any(part.startswith('.') for part in p.relative_to(WALLS).parts):
            video = p.suffix.lower() in VIDEOS
            still = p.resolve()
            if video:
                try:
                    still = ensure_video_still(str(p))
                except (ValueError, OSError, subprocess.TimeoutExpired):
                    # Keep video available even when ffmpeg cannot extract a frame.
                    pass
            items.append({'name': p.stem, 'path': str(p.resolve()), 'category': p.parent.relative_to(WALLS).as_posix(), 'video': video,
                          'preview': str(still)})
    return {'categories': categories, 'walls': items[:1000], 'themes': themes()}


def assign(name, value, apply_active=True):
    theme = theme_path(name)
    wall = media_path(value)
    if wall.suffix.lower() in VIDEOS:
        ensure_video_still(str(wall))
    original = theme.read_text(encoding='utf-8')
    if len(original) > 1024 * 1024:
        raise ValueError('Theme file too large')
    expression = re.compile(r'^\s*WALLPAPER\s*=.*$', re.M)
    if len(expression.findall(original)) != 1:
        raise ValueError('Theme needs exactly one WALLPAPER assignment')
    changed = expression.sub(lambda _: 'WALLPAPER=' + str(wall), original, count=1)
    if changed == original:
        return 'Already assigned'
    # Backup before replacement; temp file in same directory keeps os.replace atomic.
    backup_dir = THEMES / '.wallpaper-backups'
    if backup_dir.is_symlink():
        raise ValueError('Invalid backup directory')
    backup_dir.mkdir(mode=0o700, exist_ok=True)
    backup = backup_dir / name
    if not backup.exists():
        shutil.copy2(theme, backup)
    tmp = None
    try:
        with tempfile.NamedTemporaryFile(mode='w', encoding='utf-8', dir=THEMES, prefix='.wallpaper-', delete=False) as output:
            tmp = Path(output.name)
            output.write(changed)
            output.flush()
            os.fsync(output.fileno())
        tmp.chmod(theme.stat().st_mode & 0o777)
        os.replace(tmp, theme)
    finally:
        if tmp is not None:
            tmp.unlink(missing_ok=True)
    try:
        active_name = json.loads(SNAPSHOT.read_text(encoding='utf-8')).get('name', '')
    except (OSError, ValueError):
        active_name = ''
    if apply_active and active_name == name:
        result = subprocess.run(['theme-set', name], capture_output=True, text=True, timeout=45)
        if result.returncode:
            raise RuntimeError('Theme file updated, but theme-set failed: ' + (result.stderr.strip() or str(result.returncode)))
    return 'Assigned to ' + name


def move(value, category):
    source = media_path(value)
    if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_-]{0,63}', category):
        raise ValueError('Invalid category')
    destination_dir = WALLS / category
    if category.startswith('.') or destination_dir.is_symlink() or not destination_dir.is_dir():
        raise ValueError('Choose existing category directory')
    if source.parent == destination_dir:
        raise ValueError('Already in category')
    destination = destination_dir / source.name
    if destination.exists():
        raise ValueError('Destination already exists')
    if any(Path(item['wallpaper']).expanduser().resolve() == source for item in themes() if item['wallpaper']):
        raise ValueError('Wallpaper assigned to a theme; reassign theme before moving')
    sidecar = source.with_name(source.name + '.source.json')
    target_sidecar = destination.with_name(destination.name + '.source.json')
    if sidecar.exists() and target_sidecar.exists():
        raise ValueError('Attribution metadata already exists in destination')
    source.rename(destination)
    if sidecar.is_file():
        sidecar.rename(target_sidecar)
    return 'Moved to ' + category


def delete(value):
    source = media_path(value)
    if any(Path(item['wallpaper']).expanduser().resolve() == source for item in themes() if item['wallpaper']):
        raise ValueError('Wallpaper assigned to a theme; reassign theme before deleting')
    sidecar = source.with_name(source.name + '.source.json')
    source.unlink()
    if sidecar.is_file() and not sidecar.is_symlink():
        sidecar.unlink()
    return 'Deleted ' + source.name


def import_file(value, category):
    source = Path(value).expanduser().resolve(strict=True)
    if not source.is_file() or source.suffix.lower() not in MEDIA:
        raise ValueError('Unsupported image or video')
    if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_-]{0,63}', category):
        raise ValueError('Invalid category')
    destination_dir = WALLS / category
    if category.startswith('.') or destination_dir.is_symlink() or not destination_dir.is_dir():
        raise ValueError('Choose existing category directory')
    if source.stat().st_size > 1024 * 1024 * 1024:
        raise ValueError('File exceeds 1 GiB')
    destination = destination_dir / source.name
    if destination.exists():
        raise ValueError('Destination already exists')
    shutil.copy2(source, destination)
    return str(destination)
