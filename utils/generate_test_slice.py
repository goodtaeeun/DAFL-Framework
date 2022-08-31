import sys
import random
import os
import shutil

def main():
    if len(sys.argv) != 3:
        print("Usage: %s <sound slice> <unsound slice>" % \
                sys.argv[0])
        exit(1)

    sound_slice_file = sys.argv[1]
    unsound_slice_file = sys.argv[2]
    sound_funcs = open(sound_slice_file, 'r').read().splitlines()
    unsound_funcs = open(unsound_slice_file, 'r').read().splitlines()

    to_add_funcs = []
    for func in sound_funcs:
        if func not in unsound_funcs:
            to_add_funcs.append(func)

    n = len(to_add_funcs)
    print("Total %d functions to add to %s" % (n, unsound_slice_file))
    random.shuffle(to_add_funcs)

    first_test_set = unsound_funcs.copy()
    second_test_set = unsound_funcs.copy()
    idx = int(n / 2)
    first_test_set.extend(to_add_funcs[:idx])
    second_test_set.extend(to_add_funcs[idx:])

    print("Generating the first set (%d functions)" % len(first_test_set))
    f = open("%s-test-1" % unsound_slice_file, "w")
    for func in first_test_set:
        f.write("%s\n" % func)
    f.close()

    print("Generating the second set (%d functions)" % len(second_test_set))
    f = open("%s-test-2" % unsound_slice_file, "w")
    for func in second_test_set:
        f.write("%s\n" % func)
    f.close()

if __name__ == '__main__':
    main()
