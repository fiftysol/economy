import os
import re
import sys
from typing import Dict, Set


github_link = (
	"https://raw.githubusercontent.com/"
	"{owner}/{repo}/{branch}/{file}.lua"
)
gist_link = (
	"https://gist.githubusercontent.com/"
	"{owner}/{repo}/raw/{branch}/{file}.lua"
)
require_exp = r"(require\s*\(?\s*[\"'])(.+?)([\"'])"


def scan(path: str, files: Dict[str, str]) -> Set[str]:
	if not os.path.isfile(path):
		raise FileNotFoundError(f"Could not find file {path}")

	dirname = os.path.dirname(path)
	with open(path, "r") as file:
		content = file.read()

	dependencies = set()
	for prefix, required, suffix in re.findall(require_exp, content):
		dependency = os.path.normpath(os.path.join(dirname, required))
		dep = dependency.replace("\\", "\\\\")
		content = content.replace(
			f"{prefix}{required}{suffix}",
			f"{prefix}{dep}{suffix}",
			1
		)

		dependencies.add(dependency)
		dependencies = dependencies.union(scan(dependency, files))

	files[path] = content
	return dependencies


def link(entry: str) -> str:
	entry = os.path.normpath(entry)
	output = ["--[[ COMPUTER GENERATED FILE: DO NOT MODIFY DIRECTLY ]]--"]

	# Append a require mockup, so we can use it inside the script
	with open("./mockup-require.lua", "r") as file:
		output.extend(line.rstrip() for line in file.readlines())

	files: Dict[str, str] = {}
	dependencies = scan(entry, files)
	dependencies.add(entry)
	for path in dependencies:
		# For every dependency, we append their file and use __registerFile()
		# from basic-require.lua; to be able to use it from require()
		output.append(
			'__registerFile("{}", {}, function()'
			.format(path.replace("\\", "\\\\"), len(output) + 1)
		)
		output.extend(files.pop(path).split("\n"))
		output.append('end)')

	# Add a call to run init.lua
	entry = entry.replace("\\", "\\\\")
	output.extend((
		f'local done, result = pcall(require, "{entry}")',
		'if not done then',
		'	error(__errorMessage(result))',
		'end'
	))
	# Remove trailing whitespace and join all lines
	return "\n".join(line.rstrip() for line in output)


entry, dest = "./release/init.lua", "./dist.lua"
for i in range(1, len(sys.argv), 2):
	if sys.argv[i] == "--src":
		entry = sys.argv[i + 1]
	elif sys.argv[i] == "--dest":
		dest = sys.argv[i + 1]

with open(dest, "w") as file:
	file.write(link(entry))
