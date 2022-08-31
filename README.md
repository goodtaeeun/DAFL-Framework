# Directed Fuzzing Benchmark

## Run smake and extract preprocessed files
Example:
```
./bin/run-smake.sh vorbis-2017-12-11
# see rundirs/RUNDIR-vorbis-2017-12-11/
```

## System configuration for docker

To run AFL, you should first fix core dump name pattern.
```
$ echo core | sudo tee /proc/sys/kernel/core_pattern
```

If your system has `/sys/devices/system/cpu/cpu*/cpufreq` directory, AFL may
also complain about the CPU frequency scaling configuration. Check the current
configuration and remember it if you want to restore it later. Then, set it to
`performance`, as requested by AFL.
```
$ cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
powersave
powersave
powersave
powersave
$ echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

