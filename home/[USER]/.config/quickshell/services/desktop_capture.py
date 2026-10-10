"""Screenshot capture with explicit destination and no shell interpolation."""
import base64
import datetime
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

# Google Search image-upload UI; lens.google.com/ is an informational landing page.
LENS_URL = 'https://www.google.com/imghp'


def geometry(rect):
    x, y = rect['at']
    width, height = rect['size']
    if not all(isinstance(v, int) for v in (x, y, width, height)) or width <= 0 or height <= 0:
        raise ValueError('No visible capture geometry')
    return f'{x},{y} {width}x{height}'


def window_boxes(clients, monitors):
    """Only offer mapped windows on currently displayed workspaces."""
    workspaces = {m.get(key, {}).get('id') for m in monitors
                  for key in ('activeWorkspace', 'specialWorkspace')}
    workspaces.discard(None)
    workspaces.discard(0)  # An inactive special workspace uses id 0.
    boxes = []
    for client in clients:
        if not client.get('mapped') or client.get('hidden') or client.get('visible') is False:
            continue
        if not client.get('pinned') and client.get('workspace', {}).get('id') not in workspaces:
            continue
        try:
            box = geometry(client)
        except (ValueError, KeyError, TypeError):
            continue
        if box not in boxes:
            boxes.append(box)
    return boxes


def capture(scope, destination, *, home=None, filename="", edit=False):
    if scope not in ('region', 'window', 'output') or destination not in ('save', 'clipboard', 'lens'):
        return {'error': 'Invalid screenshot option'}
    try:
        validate_filename(filename)
    except ValueError as exc:
        return {'error': str(exc)}
    if not shutil.which('grim'):
        return {'error': 'Install grim for screenshots'}
    try:
        area = None
        output_name = None
        if scope == 'region':
            if not shutil.which('slurp'):
                return {'error': 'Install slurp to select a region'}
            # slurp reads rectangle presets from non-TTY stdin before showing its
            # overlay. Quickshell's inherited open pipe never reaches EOF.
            picked = subprocess.run(['slurp'], stdin=subprocess.DEVNULL, capture_output=True, text=True, timeout=120)
            if picked.returncode or not picked.stdout.strip():
                return {'cancelled': True} if picked.returncode in (1, 130) else {'error': picked.stderr.strip() or 'Region selection failed'}
            area = picked.stdout.strip()
            # slurp supplies coordinates, never pass arbitrary command options to grim.
            import re
            if not re.fullmatch(r'-?\d+,-?\d+ \d+x\d+', area):
                return {'error': 'Invalid region geometry'}
        elif scope == 'window':
            if not shutil.which('slurp'):
                return {'error': 'Install slurp to select a window'}
            clients = subprocess.run(['hyprctl', '-j', 'clients'], capture_output=True, text=True, timeout=5, check=True)
            monitors = subprocess.run(['hyprctl', '-j', 'monitors'], capture_output=True, text=True, timeout=5, check=True)
            boxes = window_boxes(json.loads(clients.stdout), json.loads(monitors.stdout))
            if not boxes:
                return {'error': 'No visible windows to capture'}
            # -r only permits predefined window rectangles, selected on click.
            # communicate closes the preset pipe before slurp displays its overlay.
            picked = subprocess.run(['slurp', '-r', '-w', '3'], input='\n'.join(boxes) + '\n', capture_output=True, text=True, timeout=120)
            if picked.returncode or not picked.stdout.strip():
                return {'cancelled': True} if picked.returncode in (1, 130) else {'error': picked.stderr.strip() or 'Window selection failed'}
            area = picked.stdout.strip()
            if area not in boxes:
                return {'error': 'Invalid window selection'}
        else:
            monitors = subprocess.run(['hyprctl', '-j', 'monitors'], capture_output=True, text=True, timeout=5, check=True)
            displays = json.loads(monitors.stdout)
            chosen = next((display for display in displays if display.get('focused')), None)
            if chosen is None:
                return {'error': 'No focused display'}
            # grim -o understands scale and rotation; physical sizes are not
            # compositor logical geometry on HiDPI or rotated displays.
            output_name = chosen.get('name')
            if not isinstance(output_name, str) or not output_name:
                return {'error': 'Focused display has no output name'}
        command = ['grim'] + (['-o', output_name] if output_name else ['-g', area] if area else []) + ['-']
        image = subprocess.run(command, capture_output=True, timeout=20, check=True).stdout
        if not image.startswith(b'\x89PNG\r\n\x1a\n'):
            return {'error': 'Capture produced no PNG image'}
        if edit:
            directory = Path(tempfile.mkdtemp(prefix='quickshell-screenshot-'))
            path = directory / 'original.png'
            path.write_bytes(image)
            return {'editing': True, 'path': str(path), 'output': str(directory / 'edited.png')}
        return deliver(image, destination, home=home, filename=filename)
    except (OSError, ValueError, KeyError, TypeError, subprocess.TimeoutExpired, subprocess.CalledProcessError) as exc:
        return {'error': 'Screenshot failed: ' + str(exc)}


def validate_filename(filename):
    """Only a basename, never a path; all screenshot files are PNG."""
    if not isinstance(filename, str):
        raise ValueError('Invalid screenshot filename')
    name = filename.strip()
    if not name:
        return ''
    if name.lower().endswith('.png'):
        name = name[:-4]
    if not name or name in ('.', '..') or any(c in name for c in '/\\') or any(ord(c) < 32 for c in name) or len(name.encode()) > 200:
        raise ValueError('Use a filename without folders (up to 200 bytes)')
    return name


def deliver(image, destination, *, home=None, filename=''):
    if destination not in ('save', 'clipboard', 'lens'):
        return {'error': 'Invalid screenshot destination'}
    try:
        validate_filename(filename)
        if destination == 'save':
            directory = (Path(home) if home is not None else Path.home()) / 'Pictures/Screenshots'
            directory.mkdir(parents=True, exist_ok=True)
            # Exclusive create prevents collisions even across simultaneous requests.
            stem = validate_filename(filename) or datetime.datetime.now().strftime('Screenshot-%Y%m%d-%H%M%S-%f')
            for suffix in range(100):
                path = directory / (stem + (f'-{suffix}' if suffix else '') + '.png')
                try:
                    with path.open('xb') as output:
                        output.write(image)
                    return {'message': 'Screenshot saved', 'path': str(path)}
                except FileExistsError:
                    continue
            return {'error': 'Could not allocate screenshot filename'}
        if not shutil.which('wl-copy'):
            return {'error': 'Install wl-clipboard to copy screenshots'}
        # wl-copy forks a clipboard owner. Captured stdout/stderr pipes would
        # remain open in that child and make communicate() wait indefinitely.
        subprocess.run(['wl-copy', '--type', 'image/png'], input=image, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=10, check=True)
        if destination == 'lens':
            if not shutil.which('xdg-open'):
                return {'error': 'Screenshot copied; install xdg-open to open Lens'}
            subprocess.Popen(['xdg-open', LENS_URL], start_new_session=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            return {'message': 'Screenshot copied; click Google Lens camera, then paste or upload'}
        return {'message': 'Screenshot copied'}
    except (OSError, ValueError, subprocess.TimeoutExpired, subprocess.CalledProcessError) as exc:
        return {'error': 'Screenshot failed: ' + str(exc)}


def staged_path(path):
    path = Path(path)
    if (path.parent.parent != Path(tempfile.gettempdir()) or
            not path.parent.name.startswith('quickshell-screenshot-') or
            path.name not in ('original.png', 'edited.png') or path.is_symlink() or
            path.parent.is_symlink() or path.parent.stat().st_uid != __import__('os').getuid()):
        raise ValueError('Invalid screenshot editor file')
    return path


def finish_edit(path, destination, filename='', data=None):
    try:
        path = staged_path(path)
        if data is not None:
            prefix = 'data:image/png;base64,'
            if not data.startswith(prefix):
                raise ValueError('Editor produced no PNG image')
            image = base64.b64decode(data[len(prefix):], validate=True)
            if not image.startswith(b'\x89PNG\r\n\x1a\n'):
                raise ValueError('Editor produced no PNG image')
            path.write_bytes(image)
        else:
            image = path.read_bytes()
        if not image.startswith(b'\x89PNG\r\n\x1a\n'):
            return {'error': 'Editor produced no PNG image'}
        result = deliver(image, destination, filename=filename)
        if 'error' not in result:
            discard_edit(str(path))
        return result
    except (OSError, ValueError) as exc:
        return {'error': str(exc)}


def discard_edit(path):
    try:
        path = staged_path(path)
        for name in ('original.png', 'edited.png'):
            (path.parent / name).unlink(missing_ok=True)
        path.parent.rmdir()
        return {'cancelled': True}
    except (OSError, ValueError) as exc:
        return {'error': str(exc)}
