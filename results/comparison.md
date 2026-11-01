| build | wall time | user, s | CPU | max RSS, KB | minor faults | invol. ctx sw | task-clock, ms |
|---|---|---|---|---|---|---|---|
| bench_O0 | 0:05.67 | 5.51 | 97% | 45708 | 12115 | 15 | 6131.86 |
| bench_O3 | 0:01.82 | 1.72 | 96% | 45832 | 12114 | 9 | 1882.68 |

```
O0:
fill        0.056 s
matmul      2.179 s
saxpy       0.991 s
dot         1.253 s
sort        1.192 s
total       5.672 s
checksum 774.984574
O3:
fill        0.031 s
matmul      0.060 s
saxpy       0.303 s
dot         0.590 s
sort        0.833 s
total       1.818 s
checksum 774.984559
```
