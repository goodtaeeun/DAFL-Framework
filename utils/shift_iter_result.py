import sys, os


def shift_binutils_output(outdir, delta):
    for f in os.listdir(outdir):
        src = os.path.join(outdir, f)
        tokens = src.split("-iter-")
        dst = "%s-iter-%d" % (tokens[0], int(tokens[1]) + delta)
        cmd = "mv %s %s" % (src, dst)
        print(cmd)
        os.system(cmd)


if len(sys.argv) != 3:
    print("Usage: python %s <experiment outdir> <delta>" % sys.argv[0])
    exit(1)

outdir = sys.argv[1]
delta = int(sys.argv[2])
shift_binutils_output(outdir, delta)
