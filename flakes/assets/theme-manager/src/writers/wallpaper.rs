use crate::Theme;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::thread;
use std::time::Duration;

pub fn apply_wallpaper(theme: &Theme) {
    let path_str = match theme.vars.get("WALLPAPER") {
        Some(s) if !s.is_empty() && s != "none" => s,
        _ => {
            stop_awww();
            return;
        }
    };

    let path = Path::new(path_str);
    if !path.is_file() {
        eprintln!(
            "theme-manager: [wallpaper] '{}' not found — stopping awww.service",
            path.display()
        );
        stop_awww();
        return;
    }

    // Videos are played by mpvpaper, never by awww. awww only handles still
    // images, so kill it instead of converting the video into an animated
    // WebP overlay that would cover the real playback.
    if is_video(path) {
        stop_awww();
        return;
    }

    let wallpaper = match prepare_wallpaper(path) {
        Some(path) => path,
        None => return,
    };

    if awww_running() {
        set_wallpaper(&wallpaper);
    } else {
        start_awww_daemon();
        thread::sleep(Duration::from_millis(500));
        set_wallpaper(&wallpaper);
    }
}

fn prepare_wallpaper(path: &Path) -> Option<PathBuf> {
    Some(path.to_path_buf())
}

fn is_video(path: &Path) -> bool {
    matches!(
        path.extension()
            .and_then(|extension| extension.to_str())
            .map(|extension| extension.to_ascii_lowercase())
            .as_deref(),
        Some("mp4" | "m4v" | "mkv" | "mov" | "webm" | "avi" | "mpg" | "mpeg")
    )
}

fn awww_running() -> bool {
    Command::new("awww")
        .arg("query")
        .output()
        .map(|o| o.status.success())
        .unwrap_or(false)
}

fn stop_awww() {
    let _ = Command::new("systemctl")
        .args(["--user", "stop", "awww.service"])
        .status();
}

fn start_awww_daemon() {
    match Command::new("systemctl")
        .args(["--user", "start", "awww.service"])
        .status()
    {
        Ok(status) if status.success() => {
            eprintln!("theme-manager: [wallpaper] started awww.service");
        }
        Ok(status) => eprintln!("theme-manager: [wallpaper] awww.service failed: {status}"),
        Err(error) => eprintln!("theme-manager: [wallpaper] systemctl unavailable: {error}"),
    }
}

fn set_wallpaper(path: &Path) {
    let result = Command::new("awww").arg("img").arg(path).status();
    match result {
        Ok(s) if s.success() => eprintln!("theme-manager: [wallpaper] set to '{}'", path.display()),
        Ok(s) => eprintln!("theme-manager: [wallpaper] awww img failed with {s}"),
        Err(e) => eprintln!("theme-manager: [wallpaper] awww not found: {e}"),
    }
}

#[cfg(test)]
mod tests {
    use super::is_video;
    use std::path::Path;

    #[test]
    fn detects_common_video_extensions_case_insensitively() {
        for path in ["wall.mp4", "wall.WEBM", "wall.mkv", "wall.mov", "wall.avi"] {
            assert!(is_video(Path::new(path)), "{path} should be a video");
        }
    }

    #[test]
    fn leaves_awww_supported_images_untouched() {
        for path in ["wall.jpg", "wall.jpeg", "wall.png", "wall.gif", "wall.webp"] {
            assert!(
                !is_video(Path::new(path)),
                "{path} should go directly to awww"
            );
        }
    }
}
