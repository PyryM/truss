# compiles_shaders.py
#
# runs shaders in shaders/raw through shaderc to produce
# compiled shaders

from __future__ import print_function
import sys, os
from os.path import join, isfile, normpath
import errno
import subprocess

def make_sure_path_exists(path):
    try:
        os.makedirs(path)
    except OSError as exception:
        if exception.errno != errno.EEXIST:
            raise

def make_sure_shaderc_exists():
    filename = "shadercRelease"
    cp_cmd = "cp"
    if os.name != "posix":  # windows
        filename += ".exe"
        cp_cmd = "copy"
    if not isfile(filename):
        print("shaderc not present in directory; trying to copy from truss/bin")
        srcpath = join("..", "..", "bin", filename)
        cmd = "{} {} {}".format(cp_cmd, srcpath, filename)
        print("copy command: " + cmd)
        os.system(cmd)

def make_cmd(shader_type, platform, input_fn, output_fn):
    if platform == "linux":
        args = ["./shadercRelease"]
    else:
        args = ["shadercRelease"]
    args.extend(["-f", input_fn, "-o", output_fn])
    args.extend(["--type", shader_type])
    args.extend(["-i", normpath("common/")])
    args.extend(["--platform", platform])
    if platform == "linux":
        args.extend(["-p", "120"])
    elif platform == "windows":
        if shader_type == "f":
            args.extend(["-p", "ps_4_0"])
        elif shader_type == "v":
            args.extend(["-p", "vs_4_0"])
        else:
            print("Unknown shader_type {}".format(shader_type))
            return None
        args.extend(["-O", "3"])
    else:
        print("Unknown platform {}".format(platform))
        return None
    return args

if os.name == "posix":
    platforms = [("linux", "glsl")]
else:
    platforms = [("windows","dx11"), ("linux","glsl")] # compile gl even on windows

def make_directories():
    for platform, desttype in platforms:
        print("Making sure directory " + desttype + " exists.")
        make_sure_path_exists(join("..", desttype))

def process_file(prefix, dirname, filename, errdest, errlist):
    if prefix == "vs":
        shader_type = "v"
    elif prefix == "fs":
        shader_type = "f"
    else:
        print("Unknown prefix {}".format(prefix))
        return -1

    infile = join(dirname, filename)

    nerrors = 0
    for platform, desttype in platforms:
        outfile = join("..", desttype, filename[0:-3] + ".bin")
        cmdargs = make_cmd(shader_type, platform, infile, outfile)
        res = subprocess.call(cmdargs, stderr = errdest)
        if res > 0:
            errname = "{} | {}".format(infile, desttype)
            errlist.append(errname)
            errdest.write("^^^ Error in {}\n\n\n".format(errname))
            errdest.flush()
            nerrors = nerrors + 1

    return nerrors

def listdirs(dirname):
    allthings = [join(dirname, f) for f in os.listdir(dirname)]
    return [ f for f in allthings if not isfile(f) ]

def listfiles(dirname):
    allthings = os.listdir(dirname)
    return [ f for f in allthings if isfile(join(dirname, f)) ]

def pad(s, pad_to):
    padding = " " * max(0, pad_to - len(s))
    return "{}{}".format(s, padding)

def main():
    make_directories()
    make_sure_shaderc_exists()
    dirs = listdirs(".")
    errdest = open("shader_errors.txt", "wt")
    errlist = []
    for dirname in dirs:
        files = listfiles(dirname)
        print(pad(dirname, 30) + " | ", end="")
        for filename in files:
            prefix = filename[0:2]
            suffix = filename[-3:]
            if suffix == ".sc" and (prefix == "vs" or prefix == "fs"):
                nerrs = process_file(prefix, dirname, filename, errdest, errlist)
                if nerrs < 0:
                    print("?", end="")
                elif nerrs == 0:
                    print(".", end="")
                elif nerrs > 0:
                    print("x", end="")
        print("")
    errdest.close()
    if len(errlist) > 0:
        print("Some shaders had errors, see shader_errors.txt for details.")
        for errfn in errlist[0:10]:
            print(errfn)

if __name__ == '__main__':
    main()
