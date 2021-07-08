"""
Builds a .love file and a fused game executable from the specified sources.
"""
import os
import pathlib
import zipfile
import shutil
import platform
import argparse
import tempfile
import typing


THIS_DIR = pathlib.Path(".")
ABSOLUTE_DIR = THIS_DIR.resolve()

ASSETS_PREFIX = THIS_DIR / "Assets"
SOURCE_PREFIX = THIS_DIR / "src"
MODULES_PREFIX = THIS_DIR / "modules"

OUTPUT_FILE = THIS_DIR / "dist" / "game.love"
DIST_FILE = THIS_DIR / "dist" / "game"


def iterative_filewrite(prefix: pathlib.Path, out: zipfile.ZipFile, file_filter: typing.Callable):
	stack = [p for p in prefix.iterdir()]
	while len(stack) > 0:
		path = stack.pop()

		if path.is_file() and file_filter(path):
			out.write(path)

		if path.is_dir():
			for path2 in path.iterdir():
				stack.append(path2)


if __name__ == "__main__":

	parser = argparse.ArgumentParser(description="builds distribution")
	parser.add_argument('-l', '--love2d', type=pathlib.Path, default=pathlib.Path(shutil.which('love')), help="path to the love2d executable")
	args = parser.parse_args()

	with zipfile.ZipFile(OUTPUT_FILE, mode='w', compresslevel=9) as zfout:
		lua_filter = lambda p: (p.suffix == ".lua" or "LICENSE" in p.name)
		asset_filter = lambda p: (p.suffix != ".aseprite" and p.suffix != ".tmx")

		iterative_filewrite(MODULES_PREFIX, zfout, lua_filter)
		iterative_filewrite(ASSETS_PREFIX, zfout, asset_filter)

		os.chdir(SOURCE_PREFIX)
		iterative_filewrite(pathlib.Path("."), zfout, lua_filter)
		os.chdir(ABSOLUTE_DIR)

		zfout.write("main.lua")

	# Taken from PATH
	lovepath = args.love2d

	if lovepath is None:
		raise ValueError("Could not infer love2d executable path")

	lovepath = pathlib.Path(lovepath)

	if platform.system() == "Windows" and DIST_FILE.suffix != ".exe":
		DIST_FILE = DIST_FILE.with_suffix(".exe")

	DIST_FILE.parent.mkdir(parents=True, exist_ok=True)
	with DIST_FILE.open('wb') as fout:
		for f in (lovepath, OUTPUT_FILE):
			with f.open('rb') as fd:
				shutil.copyfileobj(fd, fout)


