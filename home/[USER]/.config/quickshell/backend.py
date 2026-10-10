#!/usr/bin/env python3
"""Compatibility entry point for existing Hyprland bindings; implementation in services/."""
from pathlib import Path
import runpy
import sys

if __name__ == "__main__":
    services = Path(__file__).resolve().parent / "services"
    sys.path.insert(0, str(services))
    runpy.run_path(str(services / "backend.py"), run_name="__main__")
