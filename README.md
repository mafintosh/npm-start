# npm-start-container

[npm start](https://www.npmjs.org/doc/cli/npm-start.html) written in bash that propagates kill to subprocesses

```
npm install npm-start-container -g
```

## Usage

Usage is exactly the same as [npm start](https://www.npmjs.org/doc/cli/npm-start.html)

```
$ cd some-folder-with-a-package-json
$ npm-start-container
```

The difference is that when it receives `SIGTERM` it will kill all subprocesses as well (which [npm start](https://www.npmjs.org/doc/cli/npm-start.html) doesn't do)
and wait for them to exit

```
$ kill pid-of-npm-start-container # this will actually kill the node process
```

Also memory usage for long running processes might be a bit lower since you do not need to spawn an additional node process to start npm

## Details

[npm start](https://www.npmjs.org/doc/cli/npm-start.html) doesn't currently send
signals to it's subprocesses. An
[issue was created](https://github.com/npm/npm/issues/4603) but the decision was
to not change the behavior.

This script intends to maintain similar functionality with bash. In addition to
propagating KILL signals to subprocesses and passing Docker's memory limits to
node, facilitating correct node garbage collection and memory constraints.

`max_old_space_size` is a memory management flag in V8
The amount for V8 and buffer memory is reserved separately as buffers exist
outside of the v8 heap.

The assigned memory value is determined from Docker's control group
(/sys/fs/cgroup/memory/memory.limit_in_bytes) and the flags are defined by a
percentage of the memory available. See the below table for example values:

```
Assigned  File/Buffer  Max
Memory    Memory       old_space
100%      12.5%        87.5%
128       16           112
256       32           224
384       48           336
512       64           448
640       80           560
768       96           672
896       112          784
1024      128          896
1152      144          1008
1280      160          1120
1408      176          1232
1536      192          1344
1664      208          1456
1792      224          1568
1920      240          1680
2048      256          1792
```

## License

MIT
