"""Run controller shortcut regressions using a JDK, without an Android device."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
package = "com.ast.unreal" if (root / "source").is_dir() else "com.ast.ut99"
source = root / ("source/app" if package.endswith("unreal") else "app") / "src/main/java" / package.replace(".", "/")
suffix = ".exe" if os.name == "nt" else ""
java_home = os.environ.get("JAVA_HOME")
def executable(name):
    return str(Path(java_home) / "bin" / (name + suffix)) if java_home else shutil.which(name)

with tempfile.TemporaryDirectory(prefix="settings-chord-") as temp:
    subprocess.run([executable("javac"), "-encoding", "UTF-8", "-d", temp,
                    str(source / "SettingsChord.java"), str(root / "tools/tests/SettingsChordTest.java")], check=True)
    subprocess.run([executable("java"), "-cp", temp, package + ".SettingsChordTest"], check=True)
