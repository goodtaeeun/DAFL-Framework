import sys

def main():
    if len(sys.argv) != 3:
        print("Usage: %s <executed function list> <sliced function list>" % sys.argv[0])
        exit(1)

    ex_functions = open(sys.argv[1], 'r').read().splitlines()
    slice_functions = open(sys.argv[2], 'r').read().splitlines()

    true_positive = [x for x in slice_functions if x in ex_functions]
    false_positive = [x for x in slice_functions if x not in ex_functions]
    false_negative = [x for x in ex_functions if x not in slice_functions]

    print("TP: %d" % len(true_positive))
    for tp in true_positive:
        print(tp)
    print("=====================================")
    print("FP: %d" % len(false_positive))
    for fp in false_positive:
        print(fp)
    print("=====================================")
    print("FN: %d" % len(false_negative))
    for fn in false_negative:
        print(fn)


if __name__ == '__main__':
    main()
