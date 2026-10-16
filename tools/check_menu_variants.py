"""Reject menu APKs that accidentally contain different engines or game assets."""
import argparse
import re
import zipfile
from pathlib import Path


def verify(classic, console):
    with zipfile.ZipFile(classic) as left, zipfile.ZipFile(console) as right:
        names = set(left.namelist())
        if len(names) != len(left.namelist()) or len(set(right.namelist())) != len(right.namelist()):
            raise ValueError("Duplicate APK entries")
        if names != set(right.namelist()):
            raise ValueError("The menu APKs contain different files")
        libraries = {name for name in names if name.startswith("lib/") and name.endswith(".so")}
        abis = {name.split("/")[1] for name in libraries}
        if abis != {"armeabi-v7a", "arm64-v8a"}:
            raise ValueError("Both Android architectures must be present")
        if not any(name.startswith("assets/") for name in names):
            raise ValueError("Missing shared assets")
        dex_changed = False
        for name in sorted(names):
            if left.read(name) == right.read(name):
                continue
            if re.fullmatch(r"classes(?:[2-9]|[1-9][0-9]+)?\.dex", name):
                dex_changed = True
            else:
                raise ValueError(f"Unexpected difference between menu APKs: {name}")
        if not dex_changed:
            raise ValueError("Identical application code: verify the menu flavor configuration")
        print(f"PASS: {len(libraries)} identical native libraries; shared assets, resources and manifest")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--classic", type=Path, default=Path("app/build/outputs/apk/classic/release/app-classic-release-unsigned.apk"))
    parser.add_argument("--console", type=Path, default=Path("app/build/outputs/apk/normal/release/app-normal-release-unsigned.apk"))
    args = parser.parse_args()
    verify(args.classic, args.console)
