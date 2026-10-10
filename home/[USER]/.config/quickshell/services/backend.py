#!/usr/bin/env python3
"""Small, argument-only bridge between Quickshell and installed desktop tools."""
import configparser
import json
import os
import re
from pathlib import Path
import subprocess
import sys
import wallpaper_store
import wallpaper_sources
import desktop_capture
import monitor_brightness
import wallpaper_palette

HOME = Path.home()
WALLS = (HOME / 'Pictures/walls').resolve()


def run(*args, timeout=7):
    try:
        result = subprocess.run(args, capture_output=True, text=True, timeout=timeout)
        if result.returncode:
            return result.stderr.strip() or result.stdout.strip() or 'Command failed'
        return result.stdout.strip()
    except (OSError, subprocess.TimeoutExpired) as exc:
        return str(exc)


def apps():
    # Resolve icon names to real files; Quickshell's missing-icon provider can
    # report Ready while painting its purple/black placeholder.
    try:
        import gi
        gi.require_version('Gtk', '3.0')
        from gi.repository import Gtk
        icon_theme = Gtk.IconTheme.get_default()
    except (ImportError, ValueError):
        icon_theme = None

    def icon_file(name):
        if not name:
            return ''
        if Path(name).is_absolute():
            return name if Path(name).is_file() else ''
        if icon_theme is not None:
            found = icon_theme.lookup_icon(name, 48, 0)
            if found:
                return found.get_filename() or ''
        return ''

    paths = [HOME / '.local/share/applications', Path('/usr/local/share/applications'), Path('/usr/share/applications')]
    paths += [Path(p) / 'applications' for p in os.environ.get('XDG_DATA_DIRS', '').split(':') if p]
    result = {}
    for directory in paths:
        for file in directory.rglob('*.desktop') if directory.exists() else ():
            key = file.relative_to(directory).as_posix().replace('/', '-')
            if key in result:
                continue
            parser = configparser.ConfigParser(interpolation=None, strict=False)
            try:
                parser.read(file, encoding='utf-8')
                entry = parser['Desktop Entry']
                if entry.get('Type') != 'Application' or entry.getboolean('NoDisplay', fallback=False) or entry.getboolean('Hidden', fallback=False) or not entry.get('Exec'):
                    continue
                result[key] = {'id': key, 'name': entry.get('Name', key), 'icon': icon_file(entry.get('Icon', '')), 'description': entry.get('Comment', '')}
            except (OSError, UnicodeError, configparser.Error, ValueError, KeyError):
                continue
    return sorted(result.values(), key=lambda app: app['name'].casefold())


def walls():
    return wallpaper_store.inventory()


def big_thinker(url=None, api_key=None, timeout=10):
    """Mirror `curl -fsS $BIG_THINKER_URL -H "Authorization: Bearer ..." | jq`.

    Success means HTTP 2xx plus a body that parses as JSON. Anything else
    (HTTP error, network failure, missing env, invalid JSON) is ok=False.
    """
    import urllib.error
    import urllib.request
    target = (url or os.environ.get('BIG_THINKER_URL', '')).strip()
    token = api_key if api_key is not None else os.environ.get('BIG_THINKER_API_KEY', '')
    if not target:
        return {'ok': False, 'httpStatus': None, 'error': 'BIG_THINKER_URL not set'}
    if not token:
        return {'ok': False, 'httpStatus': None, 'error': 'BIG_THINKER_API_KEY not set'}
    request = urllib.request.Request(target, headers={'Authorization': 'Bearer ' + token, 'Accept': 'application/json'})
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            status_code = getattr(response, 'status', 200)
            raw = response.read().decode('utf-8', errors='replace')
    except urllib.error.HTTPError as exc:
        try:
            detail = exc.read().decode('utf-8', errors='replace')[:300]
        except (OSError, ValueError):
            detail = ''
        message = 'HTTP %s%s' % (exc.code, (': ' + detail.strip()) if detail.strip() else '')
        return {'ok': False, 'httpStatus': exc.code, 'error': message}
    except (urllib.error.URLError, OSError, ValueError) as exc:
        return {'ok': False, 'httpStatus': None, 'error': str(exc) or 'Request failed'}
    try:
        parsed = json.loads(raw)
    except ValueError as exc:
        preview = raw.strip()[:200]
        return {'ok': False, 'httpStatus': status_code, 'error': 'Invalid JSON: %s%s' % (exc, (': ' + preview) if preview else '')}
    if isinstance(parsed, dict):
        detail = parsed.get('status') or parsed.get('message') or ''
    else:
        detail = ''
    return {'ok': True, 'httpStatus': status_code, 'error': '', 'detail': str(detail)[:300]}


def status():
    wifi = run('nmcli', '-t', '-f', 'ACTIVE,SSID', 'dev', 'wifi')
    wifi_radio = run('nmcli', 'radio', 'wifi')
    bluetooth = run('bluetoothctl', 'show')
    volume = run('wpctl', 'get-volume', '@DEFAULT_AUDIO_SINK@')
    track = run('playerctl', 'metadata', '--format', '{{artist}} — {{title}}')
    active = run('hyprctl', '-j', 'activewindow')
    try:
        active = json.loads(active)
    except ValueError:
        active = {}
    return {'wifi': next((line[4:] for line in wifi.splitlines() if line.startswith('yes:')), 'Disconnected'),
            'wifiEnabled': wifi_radio == 'enabled',
            'bluetooth': 'Powered: yes' in bluetooth,
            'volume': volume, 'track': track if 'No players' not in track else 'Nothing playing',
            'window': active.get('title', 'Desktop'), 'workspace': active.get('workspace', {}).get('name', '—')}


def themed_lock_config():
    """Theme a copy of the real locker config without altering the user's layout."""
    source = HOME / '.config/hypr/hyprlock.conf'
    snapshot = json.loads((HOME / '.local/state/theme/active.json').read_text(encoding='utf-8'))
    colors = snapshot.get('colors', {})
    light = snapshot.get('variant') == 'light'

    def color(key, fallback, alpha='ff'):
        value = colors.get(key, fallback)
        if not isinstance(value, str) or not re.fullmatch(r'#[0-9a-fA-F]{6}', value):
            value = fallback
        return 'rgba(' + value[1:] + alpha + ')'

    foreground = color('BASE00' if light else 'BASE06', '#f1eff5')
    muted = color('BASE03' if light else 'BASE04', '#bcb8c6')
    accent = color('BASE0D' if light else 'BASE0E', '#d4c4f4')
    background = color('BASE07' if light else 'BASE01', '#1c1b24')
    # Readable password field, matching the shell's local content cards.
    opacity = snapshot.get('opacity', 1)
    opacity = max(0.88, min(1.0, float(opacity)))
    inset = color('BASE06' if light else 'BASE02', '#292832', f'{round(opacity * 255):02x}')
    wall = snapshot.get('values', {}).get('WALLPAPER', '')
    wallpaper = Path(wall)
    if wallpaper.is_file() and wallpaper.suffix.lower() in wallpaper_store.VIDEOS:
        wall = str(wallpaper_store.ensure_video_still(wall))
        wallpaper = Path(wall)
    valid_wall = (wallpaper.is_file() and wallpaper.suffix.lower() in ('.jpg', '.jpeg', '.png', '.webp')
                  and not any(ch in wall for ch in '\n\r'))
    content = source.read_text(encoding='utf-8')
    label_index = 0

    def theme_block(match):
        nonlocal label_index
        kind, body = match.group(1), match.group(2)
        replacements = {}
        if kind == 'background':
            replacements['color'] = background
            if valid_wall:
                replacements['path'] = wall
        elif kind == 'label':
            replacements['color'] = foreground if label_index == 0 else muted
            replacements['font_family'] = 'Adwaita Sans'
            label_index += 1
        elif kind == 'input-field':
            replacements = {'inner_color': inset, 'outer_color': accent, 'font_color': foreground,
                            'check_color': color('BASE0B', '#87957f'), 'fail_color': color('BASE08', '#ea7c8b'),
                            'font_family': 'Adwaita Sans'}
        for key, value in replacements.items():
            pattern = r'(?m)^[ \t]*' + re.escape(key) + r'[ \t]*=.*$'
            body, count = re.subn(pattern, lambda _: '    ' + key + ' = ' + value, body)
            if not count:
                body = body.rstrip() + '\n    ' + key + ' = ' + value + '\n'
        return kind + ' {' + body + '}'

    content = re.sub(r'(?m)^(background|label|input-field)[ \t]*\{([^{}]*)\}', theme_block, content)
    target = HOME / '.cache/quickshell/hyprlock.conf'
    target.parent.mkdir(parents=True, exist_ok=True)
    temporary = target.with_suffix('.tmp')
    temporary.write_text(content, encoding='utf-8')
    temporary.replace(target)
    return target


def action(args):
    if not args:
        return 'Missing action'
    name = args[0]
    if name == 'launch' and len(args) == 2 and any(app['id'] == args[1] for app in apps()):
        try:
            subprocess.Popen(['gtk-launch', args[1]], start_new_session=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            return 'Launched'
        except OSError as exc:
            return str(exc)
    if name == 'wall' and len(args) == 3:
        try:
            return wallpaper_store.assign(args[1], args[2])
        except (ValueError, OSError, UnicodeError, RuntimeError, subprocess.TimeoutExpired) as exc:
            return str(exc)
    if name == 'wall-download' and len(args) == 4:
        try:
            return wallpaper_sources.download(args[1], args[2], args[3])
        except (ValueError, OSError) as exc:
            return str(exc)
    if name == 'wall-preview' and len(args) == 2:
        try:
            return str(wallpaper_store.ensure_video_still(args[1]))
        except (ValueError, OSError, subprocess.TimeoutExpired) as exc:
            return str(exc)
    if name == 'wall-move' and len(args) == 3:
        try:
            return wallpaper_store.move(args[1], args[2])
        except (ValueError, OSError) as exc:
            return str(exc)
    if name == 'wall-delete' and len(args) == 2:
        try:
            return wallpaper_store.delete(args[1])
        except (ValueError, OSError) as exc:
            return str(exc)
    if name == 'wall-import' and len(args) == 3:
        try:
            return wallpaper_store.import_file(args[1], args[2])
        except (ValueError, OSError) as exc:
            return str(exc)
    if name == 'wifi' and len(args) == 2:
        if args[1] == 'on':
            return run('nmcli', 'radio', 'wifi', 'on') or 'Wi-Fi enabled'
        if args[1] == 'off':
            return run('nmcli', 'radio', 'wifi', 'off') or 'Wi-Fi disabled'
    if name == 'bluetooth' and len(args) == 2 and args[1] in ('on', 'off'):
        return run('bluetoothctl', 'power', args[1]) or 'Bluetooth ' + args[1]
    if name == 'media' and len(args) == 2 and args[1] in ('play-pause', 'next', 'previous'):
        return run('playerctl', args[1]) or 'Done'
    if name == 'volume' and len(args) == 2 and args[1] in ('5%+', '5%-'):
        return run('wpctl', 'set-volume', '@DEFAULT_AUDIO_SINK@', args[1]) or 'Done'
    if name == 'lock':
        # Never present a dismissible QML window as an authentication lock.
        for executable in ('hyprlock', 'swaylock'):
            if any((Path(directory) / executable).is_file() for directory in os.environ.get('PATH', '').split(':')):
                try:
                    command = [executable]
                    if executable == 'hyprlock':
                        command += ['--grace', '0']
                        try:
                            command += ['--config', str(themed_lock_config())]
                        except (OSError, ValueError, TypeError, subprocess.TimeoutExpired):
                            # An unavailable snapshot must never prevent secure locking.
                            pass
                    subprocess.Popen(command, start_new_session=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    return 'Lock started'
                except OSError as exc:
                    return str(exc)
        return 'No secure locker installed (install hyprlock or swaylock)'
    return 'Unsupported action'


def main():
    cmd, *args = sys.argv[1:]
    if cmd == 'apps':
        print(json.dumps(apps()))
    elif cmd == 'walls':
        print(json.dumps(walls()))
    elif cmd == 'video-still' and len(args) == 1:
        try:
            print(json.dumps({'source': args[0], 'still': str(wallpaper_store.ensure_video_still(args[0]))}))
        except (ValueError, OSError, subprocess.TimeoutExpired) as exc:
            print('Error: ' + str(exc), file=sys.stderr)
    elif cmd == 'wall-search' and len(args) == 2:
        try:
            print(json.dumps({'results': wallpaper_sources.search(args[0], args[1]), 'error': ''}))
        except ValueError as exc:
            print(json.dumps({'results': [], 'error': str(exc)}))
    elif cmd == 'wall-palette' and len(args) == 2:
        try:
            print(json.dumps({'palette': wallpaper_palette.preview(*args)}))
        except (ValueError, OSError, subprocess.TimeoutExpired) as exc:
            print(json.dumps({'error': str(exc)}))
    elif cmd == 'status':
        print(json.dumps(status()))
    elif cmd == 'big-thinker':
        print(json.dumps(big_thinker()))
    elif cmd == 'screenshot' and len(args) in (2, 4):
        print(json.dumps(desktop_capture.capture(*args[:2], filename=args[2] if len(args) == 4 else '', edit=len(args) == 4 and args[3] == 'edit')))
    elif cmd == 'screenshot-finish' and len(args) == 3:
        print(json.dumps(desktop_capture.finish_edit(*args, data=sys.stdin.read())))
    elif cmd == 'screenshot-discard' and len(args) == 1:
        print(json.dumps(desktop_capture.discard_edit(args[0])))
    elif cmd == 'brightness' and len(args) == 1:
        print(json.dumps(monitor_brightness.change(int(args[0]) if args[0] in ('-5', '5') else 0)))
    elif cmd == 'volume' and len(args) == 1:
        if args[0] not in ('-5', '5'):
            print(json.dumps({'error': 'Invalid volume step'}))
        else:
            step = '5%-' if args[0] == '-5' else '5%+'
            response = subprocess.run(['wpctl', 'set-volume', '@DEFAULT_AUDIO_SINK@', step], capture_output=True, text=True)
            if response.returncode:
                print(json.dumps({'error': response.stderr.strip() or 'Volume change failed'}))
            else:
                level = subprocess.run(['wpctl', 'get-volume', '@DEFAULT_AUDIO_SINK@'], capture_output=True, text=True)
                match = re.search(r'Volume:\s*([0-9.]+)', level.stdout)
                value = round(float(match.group(1)) * 100) if level.returncode == 0 and match else -1
                print(json.dumps({'message': f'Volume {value}%' if value >= 0 else 'Volume changed', 'value': value}))
    elif cmd == 'action':
        print(action(args))
    else:
        raise SystemExit('Unknown command')


if __name__ == '__main__':
    main()
