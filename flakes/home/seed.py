"""Seed writable application configs without replacing existing files or links.

Nix owns the sources and activation; generated colors and UI state remain runtime
state. Existing files are deliberately preserved. See docs/MIGRATION.md.
"""
from pathlib import Path
import shutil
import sys


def seed(source, home):
    for item in sorted(source.rglob("*")):
        relative = item.relative_to(source)
        # Fish config is embedded into Home Manager's generated config.fish.
        if relative.parts[0] == "fish" and relative.name == "config.fish":
            continue
        if relative == Path("starship.toml"):
            continue
        target = home / ".config" / relative
        # Check ancestors before mkdir/copy, including broken symlinks.
        if any(p.is_symlink() for p in [target, *target.parents]):
            print(f"preserving symlink-managed config: {target}")
            continue
        if item.is_dir():
            if not target.exists():
                target.mkdir(parents=True)
            continue
        if not target.exists():
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(item, target)
            target.chmod(item.stat().st_mode & 0o777 | 0o600)


if __name__ == "__main__":
    seed(Path(sys.argv[1]), Path(sys.argv[2]))
