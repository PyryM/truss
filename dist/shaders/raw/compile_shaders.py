# compiles_shaders.py
#
# runs shaders in shaders/raw through shaderc to produce
# compiled shaders

import sys, os
from os.path import join, isfile
import errno

def make_sure_path_exists(path):
    try:
        os.makedirs(path)
    except OSError as exception:
        if exception.errno != errno.EEXIST:
            raise

dx11cmd_fs = "shadercRelease -f {} -o {} --type f -i common\ --platform windows -p ps_4_0 -O 3"
dx11cmd_vs = "shadercRelease -f {} -o {} --type v -i common\ --platform windows -p vs_4_0 -O 3"

dx9cmd_fs = "shadercRelease -f {} -o {} --type f -i common\ --platform windows -p ps_3_0 -O 3"
dx9cmd_vs = "shadercRelease -f {} -o {} --type v -i common\ --platform windows -p vs_3_0 -O 3"

glcmd_fs = "shadercRelease -f {} -o {} --type f -i common\ --platform linux -p 120"
glcmd_vs = "shadercRelease -f {} -o {} --type v -i common\ --platform linux -p 120"

if os.name == "posix":
    cmds_vs = [("./" + glcmd_vs, "glsl")]
    cmds_fs = [("./" + glcmd_fs, "glsl")]
else:
    cmds_vs = [(dx11cmd_vs, "dx11"), (dx9cmd_vs, "dx9"), (glcmd_vs, "glsl")]
    cmds_fs = [(dx11cmd_fs, "dx11"), (dx9cmd_fs, "dx9"), (glcmd_fs, "glsl")]

def make_directories():
    for (cmd, desttype) in cmds_vs:
        print("Making sure directory " + desttype + " exists.")
        make_sure_path_exists(join("..", desttype))

def processFile(prefix, dirname, filename):
    print("Processing {}, {}, {}".format(prefix, dirname, filename))

    cmds = []
    if prefix == "vs":
        cmds = cmds_vs
    elif prefix == "fs":
        cmds = cmds_fs
    else:
        print("Unknown prefix {}".format(prefix))

    infile = join(dirname, filename)

    for (cmd, desttype) in cmds:
        outfile = join("..", desttype, filename[0:-3] + ".bin")
        fullcmd = cmd.format(infile, outfile)
        print(fullcmd)
        os.system(fullcmd)

def listdirs(dirname):
    allthings = [join(dirname, f) for f in os.listdir(dirname)]
    return [ f for f in allthings if not isfile(f) ]

def listfiles(dirname):
    allthings = os.listdir(dirname)
    return [ f for f in allthings if isfile(join(dirname, f)) ]

def main():
    make_directories()
    dirs = listdirs(".")
    for dirname in dirs:
        files = listfiles(dirname)
        print(files)
        for filename in files:
            prefix = filename[0:2]
            suffix = filename[-3:]
            if suffix == ".sc" and (prefix == "vs" or prefix == "fs"):
                processFile(prefix, dirname, filename)

if __name__ == '__main__':
    main()
