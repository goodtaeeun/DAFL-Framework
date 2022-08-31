# Drected Fuzzing Benchmark

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

## Building the docker image

To build the docker image, run
```
./build_inter.sh
```
Then, you will have a intermediate docker image to work with.
Next, you must run the analyzer, `Sparrow`, in order to extract the data dependency of the program.
To do so, run
```
python3 ./scripts/run_sparrow.py [Target Program Name] [Experiment ID]
```
The results will be stored in the `outputs` directory, and also will be copied to `./docker-setup/DAFL-inputs`

Now you are ready to continue on building the docker image.
To finish, run
```
./build_final.sh
```

Or, you can pull the pre-built docker image from dockerhub when it is publicised (Coming Soon).

## Running the fuzzing experiments

In order to run the fuzzing sessions, run
```
python3 ./scripts/run-experiments.py [Experiment Id] [Tool] [Timeout] [Iteration]
```

The results will be stored in `outputs`

If you wish to examine the results, run
```
python3 ./scripts/parse-result.py [Output Dir] (Timeout)
```

The results will be summarized in an easy-to-view form.

