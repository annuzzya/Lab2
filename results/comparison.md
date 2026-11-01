| build | wall time | user, s | CPU | max RSS, KB | minor faults | invol. ctx sw | task-clock, ms |
|---|---|---|---|---|---|---|---|
| bench_O0 | 0:05.19 | 5.12 | 99% | 45656 | 12111 | 415 | 5,106.77 |
| bench_O3 | 0:01.41 | 1.39 | 99% | 45460 | 12109 | 66 | 1,421.49 |

```
O0:
fill        0.041 s
matmul      1.927 s
saxpy       1.049 s
dot         1.122 s
sort        1.049 s
total       5.189 s
checksum 774.984574
O3:
fill        0.024 s
matmul      0.040 s
saxpy       0.157 s
dot         0.502 s
sort        0.689 s
total       1.412 s
checksum 774.984559
```
