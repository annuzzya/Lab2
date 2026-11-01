Idle power (baseline): **786 mW**, interval 250 ms, 3 runs each

| build | time, s | avg power, W | system energy, J | program energy (minus idle), J | program energy (CPU-time share), J | energy impact |
|---|---|---|---|---|---|---|
| bench_O0 | 2.39 | 5.25 | 12.60 | 11.07 | 5.75 | 9906.7 |
| bench_O3 | 0.83 | 4.44 | 3.71 | 3.10 | 1.02 | 1856.1 |

bench_O0 / bench_O3: time x2.86, system energy x3.40, program energy x3.57
