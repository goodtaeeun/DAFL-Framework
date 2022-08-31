import sys, os

def try_clone(src, prefix_str, replace_str):
    if prefix_str in src:
        dst = src.replace(prefix_str, replace_str)
        cmd = "cp -r %s %s" % (src, dst)
        print(cmd)
        os.system(cmd)


def clone_output(outdir):
    for f in os.listdir(outdir):
        src = os.path.join(outdir, f)
        try_clone(src, "swftophp-4.7-2016-9827", "swftophp-4.7-2016-9829")
        try_clone(src, "swftophp-4.7-2016-9827", "swftophp-4.7-2016-9831")
        try_clone(src, "swftophp-4.7-2016-9827", "swftophp-4.7-2017-9988")
        try_clone(src, "swftophp-4.7-2016-9827", "swftophp-4.7-2017-11728")
        try_clone(src, "swftophp-4.7-2016-9827", "swftophp-4.7-2017-11729")
        try_clone(src, "swftophp-4.8-2018-7868", "swftophp-4.8-2018-8807")
        try_clone(src, "swftophp-4.8-2018-7868", "swftophp-4.8-2018-8962")
        try_clone(src, "swftophp-4.8-2018-7868", "swftophp-4.8-2018-11095")
        try_clone(src, "swftophp-4.8-2018-7868", "swftophp-4.8-2018-11225")
        try_clone(src, "swftophp-4.8-2018-7868", "swftophp-4.8-2018-20427")
        try_clone(src, "swftophp-4.8-2018-7868", "swftophp-4.8-2019-12982")
        try_clone(src, "cxxfilt-2016-4487", "cxxfilt-2016-4489")
        try_clone(src, "cxxfilt-2016-4487", "cxxfilt-2016-4490")
        try_clone(src, "cxxfilt-2016-4487", "cxxfilt-2016-4491")
        try_clone(src, "cxxfilt-2016-4487", "cxxfilt-2016-4492")
        try_clone(src, "cxxfilt-2016-4487", "cxxfilt-2016-6131")
        try_clone(src, "objdump-2017-8396", "objdump-2017-8397")
        try_clone(src, "objdump-2017-8396", "objdump-2017-8398")
        try_clone(src, "objcopy-2017-8393", "objcopy-2017-8395")
        try_clone(src, "xmllint-2017-9047", "xmllint-2017-9048")


if len(sys.argv) != 2:
    print("Usage: python %s <experiment output directory>" % sys.argv[0])
    exit(1)

outdir = sys.argv[1]
clone_output(outdir)

