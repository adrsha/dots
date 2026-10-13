{ rustPlatform }:
rustPlatform.buildRustPackage {
  pname = "theme-manager";
  version = "0.1.0";
  src = ../assets/theme-manager;
  cargoLock.lockFile = ../assets/theme-manager/Cargo.lock;
  meta.description = "Personal runtime theme generator and watcher";
}
