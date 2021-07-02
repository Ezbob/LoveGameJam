import pathlib
import zipfile
import shutil
import platform


THIS_DIR = pathlib.Path(".")

ASSETS_FILES = THIS_DIR / "Assets"

SOURCE_DIRS = (
	THIS_DIR / "char",
	THIS_DIR / "gamestates"
)

MODULES = (
	THIS_DIR / "modules" / "hump",
	THIS_DIR / "modules" / "anim8",
	THIS_DIR / "modules" / "bump",
	THIS_DIR / "modules" / "dkjson",
	THIS_DIR / "modules" / "inspect",
)

OUTPUT_FILE = THIS_DIR / "game.love"

DIST_FILE = THIS_DIR / "game"

if __name__ == "__main__":

	with zipfile.ZipFile(OUTPUT_FILE.as_posix(), mode='w', compresslevel=9) as zfout:
		for p in ASSETS_FILES.iterdir():
			if p.suffix != ".aseprite" and p.suffix != ".tmx":
				zfout.write(p)

		for module in MODULES:
			for d in module.iterdir():
				if d.suffix == ".lua" or "LICENSE" in d.name:
					zfout.write(d)

		for a in THIS_DIR.iterdir():
			if a.suffix == ".lua" or "LICENSE" in d.name:
				zfout.write(a)

		for sd in SOURCE_DIRS:
			for src in sd.iterdir():
				if a.suffix == ".lua":
					zfout.write(src)

	lovepath = pathlib.Path(shutil.which('love.exe'))

	with DIST_FILE.open('wb') as fout:
		for f in (lovepath, OUTPUT_FILE):
			with f.open('rb') as fd:
				shutil.copyfileobj(fd, fout)

	if platform.system() == "Windows" and ".exe" not in DIST_FILE.name:
		DIST_FILE.rename(DIST_FILE.name + ".exe")