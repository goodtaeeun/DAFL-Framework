import sys, os


def remove_binutils_output(outdir, start, end):
    for f in os.listdir(outdir):
        path = os.path.join(outdir, f)
        tokens = path.split("-iter-")
        iter_n = int(tokens[1])
        if start <= iter_n and iter_n <= end: # Inclusive range.
            cmd = "rm -rf %s" % path
            print(cmd)
            os.system(cmd)


if len(sys.argv) != 4:
    print("Usage: python %s <experiment outdir> <start> <end>" % sys.argv[0])
    exit(1)

outdir = sys.argv[1]
start = int(sys.argv[2])
end = int(sys.argv[3])
remove_binutils_output(outdir, start, end)
