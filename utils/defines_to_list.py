import re
import sys

def translate_lines(lines):
    tokens = []
    for line in lines:
        sline = line.strip()
        if len(sline) > 0:
            tokens.append('"{}"'.format(sline))

    return "local defnames = {" + ",\n".join(tokens) + "}"

if __name__ == '__main__':
    with open(sys.argv[1], "rt") as src:
        newlines = translate_lines(src)

    with open(sys.argv[2], "wt") as dest:
        dest.write(newlines)