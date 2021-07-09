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


def iterative_filewrite(prefix: pathlib.Path, out: zipfile.ZipFile, file_filter: typing.Callable = None):
	stack = [p for p in prefix.iterdir()]
	while len(stack) > 0:
		path = stack.pop()

		if path.is_file() and (file_filter is None or file_filter(path)):
			out.write(path)

		if path.is_dir():
			for path2 in path.iterdir():
				stack.append(path2)


def make_zipfile(love_file: pathlib.Path):
	love_file.parent.mkdir(parents=True, exist_ok=True)
	with zipfile.ZipFile(love_file, mode='w', compresslevel=9) as zip_file:
		lua_filter = lambda p: (p.suffix == ".lua" or "LICENSE" in p.name)
		asset_filter = lambda p: (p.suffix != ".aseprite" and p.suffix != ".tmx")

		iterative_filewrite(ASSETS_PREFIX, zip_file, asset_filter)
		iterative_filewrite(MODULES_PREFIX, zip_file, lua_filter)
		iterative_filewrite(SOURCE_PREFIX, zip_file, lua_filter)

		zip_file.write("main.lua")


def make_fused_game(love_exec_path: pathlib.Path, fused_executable_path: pathlib.Path, love_file: pathlib.Path):
	fused_executable_path.parent.mkdir(parents=True, exist_ok=True)
	
	if love_exec_path is None:
		raise ValueError("Could not infer love2d executable path")

	if platform.system() == "Windows" and fused_executable_path.suffix != ".exe":
		fused_executable_path = fused_executable_path.with_suffix(".exe")

	fused_executable_path.parent.mkdir(parents=True, exist_ok=True)
	with fused_executable_path.open('wb') as fout:
		for f in (love_exec_path, love_file):
			with f.open('rb') as fd:
				shutil.copyfileobj(fd, fout)


if __name__ == "__main__":

	parser = argparse.ArgumentParser(description="builds distribution")
	parser.add_argument('-l', '--love2d', type=pathlib.Path, default=pathlib.Path(shutil.which('love')), help="path to the love2d executable")
	args = parser.parse_args()

	make_zipfile(love_file=OUTPUT_FILE)
	make_fused_game(love_exec_path=args.love2d, fused_executable_path=DIST_FILE, love_file=OUTPUT_FILE)
