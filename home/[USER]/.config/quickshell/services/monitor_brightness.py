"""Serialized DDC/CI brightness adjustments for the first detected monitor."""
import fcntl
import re
import subprocess
from pathlib import Path

LOCK = Path.home() / '.cache/quickshell/ddc-brightness.lock'


def parse_vcp(output):
    match = re.search(r'VCP\s+10\s+C\s+(\d+)\s+(\d+)', output)
    if not match:
        raise ValueError('Monitor does not report DDC brightness')
    current, maximum = map(int, match.groups())
    if maximum <= 0:
        raise ValueError('Monitor reported invalid brightness maximum')
    return current, maximum


def change(delta, *, lock_path=None):
    if delta not in (-5, 5):
        return {'error': 'Brightness step must be -5 or 5'}
    try:
        lock = Path(lock_path) if lock_path else LOCK
        lock.parent.mkdir(parents=True, exist_ok=True)
        with lock.open('a+') as handle:
            fcntl.flock(handle, fcntl.LOCK_EX)
            result = subprocess.run(['ddcutil', 'getvcp', '10', '--brief'], capture_output=True, text=True, timeout=15, check=True)
            current, maximum = parse_vcp(result.stdout)
            target = max(0, min(maximum, current + round(maximum * delta / 100)))
            if target != current:
                subprocess.run(['ddcutil', 'setvcp', '10', str(target)], capture_output=True, text=True, timeout=15, check=True)
            return {'message': f'Brightness {round(target * 100 / maximum)}%', 'value': round(target * 100 / maximum)}
    except FileNotFoundError:
        return {'error': 'ddcutil unavailable; install ddcutil and enable I²C access'}
    except (OSError, ValueError, subprocess.TimeoutExpired, subprocess.CalledProcessError) as exc:
        return {'error': 'DDC brightness failed: ' + str(exc)}
