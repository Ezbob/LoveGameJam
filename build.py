import pathlib
import zipfile

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

OUTPUT_FILE = "game.love"

if __name__ == "__main__":

	with zipfile.ZipFile(OUTPUT_FILE, 'w') as zipfile:
		for p in ASSETS_FILES.iterdir():
			if p.suffix == ".png" or p.suffix == ".json" or p.suffix == ".ttf":
				zipfile.write(p)

		for module in MODULES:
			for d in module.iterdir():
				if d.suffix == ".lua" or "LICENSE" in d.name:
					zipfile.write(d)

		for a in THIS_DIR.iterdir():
			if a.suffix == ".lua":
				zipfile.write(a)

		for sd in SOURCE_DIRS:
			for src in sd.iterdir():
				if a.suffix == ".lua":
					zipfile.write(src)