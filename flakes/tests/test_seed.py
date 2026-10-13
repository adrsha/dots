import importlib.util
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location("seed", Path(__file__).parents[1] / "home/seed.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class SeedTests(unittest.TestCase):
    def test_writable_and_preserves_edits(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "source"
            source.mkdir()
            (source / "hypr").mkdir()
            (source / "hypr/colors.lua").write_text("original")
            home = root / "home"
            module.seed(source, home)
            target = home / ".config/hypr/colors.lua"
            self.assertFalse(target.is_symlink())
            target.write_text("generated")
            module.seed(source, home)
            self.assertEqual(target.read_text(), "generated")

    def test_does_not_write_through_symlinks(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "source"
            (source / "hypr/nested").mkdir(parents=True)
            (source / "hypr/nested/colors.lua").write_text("original")
            home = root / "home"
            (home / ".config").mkdir(parents=True)
            outside = root / "old-dots"
            outside.mkdir()
            (home / ".config/hypr").symlink_to(outside, target_is_directory=True)
            module.seed(source, home)
            self.assertEqual(list(outside.iterdir()), [])


if __name__ == "__main__":
    unittest.main()
