"""Read-only wallpaper color preview, following theme-manager's dynamic HSL ramps."""
import colorsys
import subprocess
import tempfile
from pathlib import Path
from urllib.parse import urlparse
from urllib.request import Request, urlopen


def palette_from_rgb(data, variant='dark'):
    if variant not in ('light', 'dark') or not data or len(data) % 3:
        raise ValueError('Invalid palette input')
    buckets = {}
    for i in range(0, len(data), 3):
        rgb = tuple(data[i:i + 3])
        key = tuple(x >> 4 for x in rgb)
        count, sums = buckets.get(key, (0, (0, 0, 0)))
        buckets[key] = count + 1, tuple(a + b for a, b in zip(sums, rgb))
    ranked = []
    for count, sums in buckets.values():
        if count < 2:
            continue
        rgb = tuple(int(x / count) / 255 for x in sums)
        h, l, s = colorsys.rgb_to_hls(*rgb)
        score = count * (.35 + s) * (1 - min(abs(l - .5) * 1.6, .85))
        ranked.append((score, (h, l, s)))
    candidates = [hls for _, hls in sorted(ranked, reverse=True)[:24]]
    h, _, s = candidates[0] if candidates else (220 / 360, .5, .4)

    def hex_color(hue, lightness, saturation):
        return '#' + ''.join(f'{int(x * 255 + .5):02x}' for x in colorsys.hls_to_rgb(hue, lightness, saturation))

    dark = variant == 'dark'
    levels = [.08, .11, .17, .28, .48, .72, .82, .90] if dark else [.96, .92, .84, .66, .46, .28, .20, .12]
    result = {f'BASE{i:02X}': hex_color(h, level, min(s, .22 if i < 4 else .16)) for i, level in enumerate(levels)}
    for key, hue in zip(range(8, 16), [5, 30, 52, 125, 190, 220, 280, 330]):
        target = hue / 360
        def distance(value):
            d = abs(value - target) % 1
            return min(d, 1 - d) * 360
        usable = [c for c in candidates if c[2] >= .18]
        selected = min(usable, key=lambda c: distance(c[0]) - c[2] * 20) if usable else None
        ah, _, sat = selected if selected and distance(selected[0]) <= 70 else (target, .5, .68)
        result[f'BASE{key:02X}'] = hex_color(ah, .64 if dark else .42, max(.48, min(.82, sat)))
    return result


def preview(source, variant):
    """Decode a bounded thumbnail; never write theme files or apply wallpaper."""
    if variant not in ('dark', 'light'):
        raise ValueError('Invalid variant')
    url = urlparse(source)
    with tempfile.TemporaryDirectory(prefix='qs-palette-') as temp:
        if url.scheme == 'https':
            request = Request(source, headers={'User-Agent': 'Quickshell-WallpaperStudio/1.0'})
            with urlopen(request, timeout=10) as response:
                data = response.read(16 * 1024 * 1024 + 1)
            if len(data) > 16 * 1024 * 1024:
                raise ValueError('Preview image too large')
            path = Path(temp) / 'preview'
            path.write_bytes(data)
        elif not url.scheme:
            path = Path(source).expanduser().resolve(strict=True)
            if not path.is_file():
                raise ValueError('Invalid wallpaper')
        else:
            raise ValueError('Unsupported preview source')
        output = subprocess.run(['ffmpeg', '-v', 'error', '-threads', '1', '-i', str(path),
                                 '-frames:v', '1', '-vf', 'scale=96:96:force_original_aspect_ratio=increase,crop=96:96',
                                 '-f', 'rawvideo', '-pix_fmt', 'rgb24', 'pipe:1'], capture_output=True, timeout=15)
        if output.returncode or len(output.stdout) != 96 * 96 * 3:
            raise ValueError('Could not decode wallpaper preview')
        return palette_from_rgb(output.stdout, variant)
