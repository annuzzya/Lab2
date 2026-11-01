# Lab 2. Performance Measurement and Analysis

Досліджувана програма: [`src/bench.c`](src/bench.c) — невеликий обчислювальний бенчмарк на C із п'яти етапів:

| функція | що робить | характер навантаження |
|---|---|---|
| `fill` | заповнює масиви псевдовипадковими числами (LCG) | послідовна залежність між ітераціями |
| `matmul` | множення матриць 512×512 (порядок циклів i-k-j) | обчислювальне (compute-bound) |
| `saxpy` | `y = a·x + y` для 4 млн елементів, 20 разів | обмежене пропускною здатністю пам'яті (memory-bound) |
| `dot` | скалярний добуток, 20 разів | редукція (сума з залежністю) |
| `sort_sample` | `qsort` 1 млн чисел із власним компаратором | бібліотечний код + виклики через вказівник |

Програма друкує час кожного етапу і контрольну суму (щоб компілятор не викинув обчислення).

Дві збірки (див. [`Makefile`](Makefile)):

* `bench_O0` — `gcc -O0 -g -fno-omit-frame-pointer` — без оптимізацій;
* `bench_O3` — `gcc -O3 -mavx2 -mfma -g -fno-omit-frame-pointer` — максимальна оптимізація + AVX2/FMA (SIMD).

Функції позначені `noinline`, щоб і після `-O3` їх було видно окремо на FlameGraph та в `perf report`.

## Як відтворити

Linux-частина (perf, FlameGraph, time) — у GitHub Codespaces (`Code → Codespaces → Create codespace`), середовище налаштовується автоматично з `.devcontainer/`:

```bash
bash scripts/run_all.sh
```

Скрипт збирає обидві версії, знімає статистику, будує FlameGraph-и та порівняння. Окремі кроки:

```bash
make all asm
bash scripts/stats.sh build/bench_O0
bash scripts/flamegraph.sh build/bench_O0
bash scripts/flamegraph_system.sh build/bench_O0
bash scripts/flamegraph_diff.sh
bash scripts/compare.sh
```

Енергоспоживання — на macOS (Apple Silicon), бо там є доступ до реальних датчиків потужності:

```bash
xcode-select --install
make
sudo python3 energy/measure_mac.py build/bench_O0 build/bench_O3
```

## 1. FlameGraph

Побудова (за інструкцією Brendan Gregg):

```bash
sudo perf record -F 999 --call-graph dwarf -o /tmp/bench_O0.data -- build/bench_O0
sudo perf script -i /tmp/bench_O0.data > /tmp/bench_O0.perf
./FlameGraph/stackcollapse-perf.pl /tmp/bench_O0.perf > out.folded
./FlameGraph/flamegraph.pl out.folded > flamegraph.svg
```

1. `perf record` 999 разів на секунду зупиняє програму і записує поточний стек викликів (`--call-graph dwarf` — розкручування стеку за налагоджувальною інформацією DWARF).
2. `perf script` перетворює бінарний `perf.data` на текстові стеки.
3. `stackcollapse-perf.pl` згортає однакові стеки в один рядок `main;matmul 2290` (стек;кількість семплів).
4. `flamegraph.pl` малює SVG.

![O0](results/bench_O0/flamegraph.png)

Інтерактивна версія: [results/bench_O0/flamegraph.svg](results/bench_O0/flamegraph.svg).

**Як читати:** вісь Y — глибина стеку (знизу `_start → main`, вище — викликані функції). Ширина прямокутника — частка часу CPU, коли ця функція була в стеку. Вісь X — це не час, а алфавітне сортування. Кольори випадкові (теплі відтінки = user-space код).

**Інтерпретація для `-O0`:**

* `matmul` займає ~37% — найбільше «плато», головний кандидат на оптимізацію;
* `dot` ~22%, `saxpy` ~20%;
* `sort_sample` ~20%: над ним висока «вежа» `qsort_r → [libc.so.6] → [libc.so.6] …` — це рекурсія сортування злиттям усередині glibc (глибина ≈ log₂(10⁶) ≈ 20), на верхівках — наш компаратор `cmp` (~11%);
* `fill` — вузька смужка (<1%), її оптимізувати немає сенсу.

Чому `[libc.so.6]`, а не ім'я функції: внутрішні (не експортовані) функції glibc, наприклад `msort_with_tmp`, не мають імен у таблиці символів бібліотеки в контейнері. Щоб perf їх підписав, потрібні налагоджувальні символи (`sudo apt install libc6-dbg`). На суть аналізу це не впливає — за формою видно рекурсію сортування.

**Вся система** (`perf record -a`, [results/system/flamegraph.svg](results/system/flamegraph.svg)): ~50% семплів — `bench_O0`, ~48% — idle-потік ядра (`:0`, тобто PID 0 / `swapper`: `do_idle → cpuidle_idle_call → pv_native_safe_halt`), решта ~2% — сервіси Codespaces (VS Code server, docker). Машина має 2 ядра, програма однопотокова, тому одне ядро зайняте, а друге простоює.

![system](results/system/flamegraph.png)

## 2. Статистика виконання

### 2.1 `/usr/bin/time --verbose`

Повний вивід: [O0](results/bench_O0/time_verbose.txt), [O3](results/bench_O3/time_verbose.txt).

| показник | O0 | O3 | що означає |
|---|---|---|---|
| Elapsed (wall clock) | 5.19 s | 1.41 s | реальний час від запуску до завершення |
| User time | 5.12 s | 1.39 s | час CPU у режимі користувача (наш код) |
| System time | 0.02 s | 0.01 s | час у ядрі (виділення пам'яті, page faults) |
| Percent of CPU | 99% | 99% | user+sys / wall — програма майже весь час працює на CPU |
| Maximum resident set size | 45.7 MB | 45.5 MB | пікова фізична пам'ять: 3 матриці по 1 МБ + 2 масиви по 16 МБ + 4 МБ ≈ 43 МБ + бібліотеки |
| Minor page faults | 12 111 | 12 109 | перше звернення до сторінок 4 КБ (≈45 МБ / 4 КБ) — без читання з диска |
| Major page faults | 0 | 0 | читання з диска не було |
| Voluntary / involuntary context switches | 0 / 415 | 0 / 66 | voluntary = 0: програма ніколи не чекає I/O; involuntary — планувальник витісняє її на користь інших процесів хмарної VM (VS Code server тощо); чим довше працює програма, тим більше таких витіснень |

Висновок: програма CPU-bound, пам'ять та page faults від оптимізації не залежать (ті самі масиви), змінюється тільки user time.

### 2.2 `perf stat -d`

[O0](results/bench_O0/perf_stat.txt), [O3](results/bench_O3/perf_stat.txt)

| подія | O0 | O3 |
|---|---|---|
| task-clock | 5 107 ms | 1 421 ms |
| CPUs utilized | 0.995 | 0.993 |
| context-switches | 286 | 295 |
| cpu-migrations | 19 | 6 |
| page-faults | 12 095 | 12 096 |

* `task-clock` — скільки часу CPU витратив на задачу; «CPUs utilized ≈ 1» підтверджує, що програма однопотокова.
* `context-switches` — перемикання процесора на інші задачі; `cpu-migrations` — скільки разів планувальник переносив програму на інше ядро (після переїзду кеш нового ядра «холодний»).
* `page-faults` ≈ 12 тис. — як і в `time`: перше звернення до кожної сторінки пам'яті.
* `-d` додає L1-dcache і LLC (last-level cache) події, а також `cycles`, `instructions`, `branches`, `branch-misses`. У віртуальній машині Codespaces/хмари апаратні лічильники (PMU) не прокинуті в гостьову систему, тому perf пише `<not supported>`. На «залізному» Linux тут було б видно, наприклад, IPC (instructions per cycle) і частку промахів кешу. Для нашої програми очікувано: після `-O3` кількість інструкцій падає в рази (одна AVX-інструкція замінює 8 скалярних), а частка cache misses для `saxpy` зростає, бо вона впирається в пам'ять.

### 2.3 `perf record` + `perf report`

```bash
sudo perf record -F 999 --call-graph dwarf -o /tmp/bench_O0.rec -- build/bench_O0
sudo perf report -i /tmp/bench_O0.rec --stdio --no-children
```

[O0 flat](results/bench_O0/perf_report_flat.txt) · [O0 з деревом викликів](results/bench_O0/perf_report.txt) · [O3 flat](results/bench_O3/perf_report_flat.txt) · [O3 з деревом](results/bench_O3/perf_report.txt)

| символ | O0, % | O3, % |
|---|---|---|
| `matmul` | 37.9 | 2.6 |
| `dot` | 21.9 | 35.6 |
| `saxpy` | 19.7 | 11.2 |
| `cmp` | 9.8 | 13.3 |
| внутрішні функції `qsort` (`libc.so.6`, адреси `0x4986x`) | ≈ 9 | ≈ 35 |
| `fill` | 0.6 | 1.0 |

* `Overhead` — частка семплів, коли інструкція саме цієї функції виконувалась (self time, `--no-children`).
* `Shared Object` — у якому файлі код: наш `bench_O*`, `libc.so.6` або `[kernel.kallsyms]`. Для libc замість імен показано адреси (`0x000000000004986f`) — немає символів, див. розділ 1.
* `[.]` — user space, `[k]` — ядро.
* Суфікс `.constprop.0` в O3 — компілятор створив спеціалізовану копію функції, підставивши відомі константні аргументи (адреси глобальних масивів, `n`).

`perf annotate` показує розподіл семплів по окремих інструкціях: [matmul O0](results/bench_O0/perf_annotate_matmul.txt), [matmul O3](results/bench_O3/perf_annotate_matmul.txt), [saxpy O3](results/bench_O3/perf_annotate_saxpy.txt). У `saxpy` O3 ~86% семплів припадає на `vfmadd213ps … [rax]` (33%) та наступну за нею `add rax, 0x20` (53%) — процесор чекає, поки з пам'яті прийдуть дані для FMA (семпл «зсувається» на наступну інструкцію — ефект skid).

## 3. Енергоспоживання

Скрипт [`energy/measure_mac.py`](energy/measure_mac.py) використовує `powermetrics` — системну утиліту macOS, яка читає апаратні датчики енергії Apple Silicon (аналог Intel RAPL на Linux, див. [energy/rapl_linux.sh](energy/rapl_linux.sh)).

Алгоритм:

1. 10 с вимірюємо **фонове** споживання (idle) — `P_idle`.
2. Запускаємо `powermetrics` (семпл кожні 250 мс), всередині — програму; кожна збірка 3 рази.
3. **3.1 Енергія системи:** `E_sys = Σ P_i · Δt_i` за час роботи програми (CPU+GPU+ANE, `combined_power`).
4. **3.2 Енергія лише програми**, двома незалежними способами:
   * віднімання фону: `E_prog = Σ (P_i − P_idle) · Δt_i`;
   * пропорційно частці CPU-часу процесу: `E_prog = Σ P_i · Δt_i · cpu_prog / cpu_all` (поле `cputime_ms_per_s` із семплера `tasks`).
   Додатково — `energy impact` процесу, яким macOS оцінює «енерговитратність» додатків в Activity Monitor.

Вимірювання на MacBook Air (Apple Silicon, збірка `clang -O0` / `clang -O3`, ARM NEON). Повний вивід: [results/energy_mac/summary.md](results/energy_mac/summary.md).

Фонова потужність (idle): **0.79 W**.

| збірка | час, s | середня потужність, W | 3.1 енергія системи, J | 3.2 програма (мінус фон), J | 3.2 програма (частка CPU), J |
|---|---|---|---|---|---|
| O0 | 2.39 | 5.25 | 12.60 | 11.07 | 5.75 |
| O3 | 0.83 | 4.44 | 3.71 | 3.10 | 1.02 |

* **3.1:** поки працює O0, система споживає ~5.3 W замість 0.8 W у простої; за 2.4 с це 12.6 J.
* **3.2:** два методи дають різні числа, і це очікувано. Віднімання фону приписує програмі все додаткове споживання: не лише її CPU-час, а й підвищені частоти, пам'ять і фонові процеси, які «прокинулися». Тому це верхня оцінка. Частка CPU-часу враховує лише час, коли виконувався саме наш процес, — нижня оцінка. Реальне значення між ними.
* Похибки: кожну збірку запускали 3 рази. Розкид між запусками (O0: 10.1–15.4 J системи) пов'язаний з відкритими програмами, турбо-частотами та температурою. Попередження `Second underflow occured` видає сам `powermetrics` (округлення таймера), на результат не впливає.
* У простої споживання на Apple Silicon дуже низьке, тому навіть невелика фонова активність помітна в результатах. Для точнішого вимірювання: ноутбук на зарядці, закрити всі програми, більше повторів.

## 4. Порівняння до та після оптимізації

### 4.1 Асемблерний код

Повні лістинги: [O0](results/asm/bench_O0.s) (602 рядки) і [O3](results/asm/bench_O3.s) (957 рядків). Те саме інтерактивно: [Compiler Explorer (godbolt)](https://godbolt.org/clientstate/eyJzZXNzaW9ucyI6W3siaWQiOjEsImxhbmd1YWdlIjoiYyIsInNvdXJjZSI6IiNpbmNsdWRlIDxzdGRpby5oPlxuI2luY2x1ZGUgPHN0ZGxpYi5oPlxuI2luY2x1ZGUgPHN0cmluZy5oPlxuI2luY2x1ZGUgPHRpbWUuaD5cblxuI2RlZmluZSBOIDUxMlxuI2RlZmluZSBWICgxIDw8IDIyKVxuI2RlZmluZSBTICgxIDw8IDIwKVxuXG5zdGF0aWMgZmxvYXQgQVtOICogTl0sIEJbTiAqIE5dLCBDW04gKiBOXTtcbnN0YXRpYyBmbG9hdCBYW1ZdLCBZW1ZdLCBaW1NdO1xuXG5zdGF0aWMgZG91YmxlIG5vdyh2b2lkKVxue1xuICAgIHN0cnVjdCB0aW1lc3BlYyB0O1xuICAgIGNsb2NrX2dldHRpbWUoQ0xPQ0tfTU9OT1RPTklDLCAmdCk7XG4gICAgcmV0dXJuIHQudHZfc2VjICsgdC50dl9uc2VjICogMWUtOTtcbn1cblxuX19hdHRyaWJ1dGVfXygobm9pbmxpbmUpKSB2b2lkIGZpbGwoZmxvYXQgKnAsIHNpemVfdCBuLCB1bnNpZ25lZCBzZWVkKVxue1xuICAgIGZvciAoc2l6ZV90IGkgPSAwOyBpIDwgbjsgaSsrKSB7XG4gICAgICAgIHNlZWQgPSBzZWVkICogMTY2NDUyNXUgKyAxMDEzOTA0MjIzdTtcbiAgICAgICAgcFtpXSA9IChmbG9hdCkoc2VlZCA-PiA4KSAvIDE2Nzc3MjE2LjBmO1xuICAgIH1cbn1cblxuX19hdHRyaWJ1dGVfXygobm9pbmxpbmUpKSB2b2lkIG1hdG11bChjb25zdCBmbG9hdCAqYSwgY29uc3QgZmxvYXQgKmIsIGZsb2F0ICpjLCBpbnQgbilcbntcbiAgICBtZW1zZXQoYywgMCwgc2l6ZW9mKGZsb2F0KSAqIG4gKiBuKTtcbiAgICBmb3IgKGludCBpID0gMDsgaSA8IG47IGkrKylcbiAgICAgICAgZm9yIChpbnQgayA9IDA7IGsgPCBuOyBrKyspIHtcbiAgICAgICAgICAgIGZsb2F0IHMgPSBhW2kgKiBuICsga107XG4gICAgICAgICAgICBmb3IgKGludCBqID0gMDsgaiA8IG47IGorKylcbiAgICAgICAgICAgICAgICBjW2kgKiBuICsgal0gKz0gcyAqIGJbayAqIG4gKyBqXTtcbiAgICAgICAgfVxufVxuXG5fX2F0dHJpYnV0ZV9fKChub2lubGluZSkpIHZvaWQgc2F4cHkoZmxvYXQgYSwgY29uc3QgZmxvYXQgKngsIGZsb2F0ICp5LCBzaXplX3QgbilcbntcbiAgICBmb3IgKHNpemVfdCBpID0gMDsgaSA8IG47IGkrKylcbiAgICAgICAgeVtpXSA9IGEgKiB4W2ldICsgeVtpXTtcbn1cblxuX19hdHRyaWJ1dGVfXygobm9pbmxpbmUpKSBmbG9hdCBkb3QoY29uc3QgZmxvYXQgKngsIGNvbnN0IGZsb2F0ICp5LCBzaXplX3QgbilcbntcbiAgICBmbG9hdCBzID0gMC4wZjtcbiAgICBmb3IgKHNpemVfdCBpID0gMDsgaSA8IG47IGkrKylcbiAgICAgICAgcyArPSB4W2ldICogeVtpXTtcbiAgICByZXR1cm4gcztcbn1cblxuc3RhdGljIGludCBjbXAoY29uc3Qgdm9pZCAqYSwgY29uc3Qgdm9pZCAqYilcbntcbiAgICBmbG9hdCB4ID0gKihjb25zdCBmbG9hdCAqKWEsIHkgPSAqKGNvbnN0IGZsb2F0ICopYjtcbiAgICByZXR1cm4gKHggPiB5KSAtICh4IDwgeSk7XG59XG5cbl9fYXR0cmlidXRlX18oKG5vaW5saW5lKSkgdm9pZCBzb3J0X3NhbXBsZShjb25zdCBmbG9hdCAqc3JjLCBmbG9hdCAqZHN0LCBzaXplX3QgbilcbntcbiAgICBtZW1jcHkoZHN0LCBzcmMsIHNpemVvZihmbG9hdCkgKiBuKTtcbiAgICBxc29ydChkc3QsIG4sIHNpemVvZihmbG9hdCksIGNtcCk7XG59XG5cbmludCBtYWluKGludCBhcmdjLCBjaGFyICoqYXJndilcbntcbiAgICBpbnQgcmVwcyA9IGFyZ2MgPiAxID8gYXRvaShhcmd2WzFdKSA6IDU7XG4gICAgZG91YmxlIHRbNV0gPSB7MH0sIHQwO1xuICAgIGRvdWJsZSBjaGVjayA9IDAuMDtcblxuICAgIHQwID0gbm93KCk7XG4gICAgZmlsbChBLCBOICogTiwgMSk7XG4gICAgZmlsbChCLCBOICogTiwgMik7XG4gICAgZmlsbChYLCBWLCAzKTtcbiAgICBmaWxsKFksIFYsIDQpO1xuICAgIHRbMF0gKz0gbm93KCkgLSB0MDtcblxuICAgIGZvciAoaW50IHIgPSAwOyByIDwgcmVwczsgcisrKSB7XG4gICAgICAgIHQwID0gbm93KCk7XG4gICAgICAgIG1hdG11bChBLCBCLCBDLCBOKTtcbiAgICAgICAgdFsxXSArPSBub3coKSAtIHQwO1xuXG4gICAgICAgIHQwID0gbm93KCk7XG4gICAgICAgIGZvciAoaW50IGsgPSAwOyBrIDwgMjA7IGsrKylcbiAgICAgICAgICAgIHNheHB5KDAuNWYsIFgsIFksIFYpO1xuICAgICAgICB0WzJdICs9IG5vdygpIC0gdDA7XG5cbiAgICAgICAgdDAgPSBub3coKTtcbiAgICAgICAgZm9yIChpbnQgayA9IDA7IGsgPCAyMDsgaysrKVxuICAgICAgICAgICAgY2hlY2sgKz0gZG90KFgsIFkgKyBrLCBWIC0gaykgKiAxZS05O1xuICAgICAgICB0WzNdICs9IG5vdygpIC0gdDA7XG5cbiAgICAgICAgdDAgPSBub3coKTtcbiAgICAgICAgc29ydF9zYW1wbGUoWSwgWiwgUyk7XG4gICAgICAgIHRbNF0gKz0gbm93KCkgLSB0MDtcblxuICAgICAgICBjaGVjayArPSBDW3JdICsgWltTIC8gMl07XG4gICAgfVxuXG4gICAgY29uc3QgY2hhciAqbmFtZXNbXSA9IHtcImZpbGxcIiwgXCJtYXRtdWxcIiwgXCJzYXhweVwiLCBcImRvdFwiLCBcInNvcnRcIn07XG4gICAgZG91YmxlIHRvdGFsID0gMDtcbiAgICBmb3IgKGludCBpID0gMDsgaSA8IDU7IGkrKykge1xuICAgICAgICBwcmludGYoXCIlLThzICU4LjNmIHNcXG5cIiwgbmFtZXNbaV0sIHRbaV0pO1xuICAgICAgICB0b3RhbCArPSB0W2ldO1xuICAgIH1cbiAgICBwcmludGYoXCIlLThzICU4LjNmIHNcXG5cIiwgXCJ0b3RhbFwiLCB0b3RhbCk7XG4gICAgcHJpbnRmKFwiY2hlY2tzdW0gJS42ZlxcblwiLCBjaGVjayk7XG4gICAgcmV0dXJuIDA7XG59XG4iLCJjb21waWxlcnMiOlt7ImlkIjoiY2cxMzIiLCJvcHRpb25zIjoiLU8wIC1tYXNtPWludGVsIn0seyJpZCI6ImNnMTMyIiwib3B0aW9ucyI6Ii1PMyAtbWF2eDIgLW1mbWEgLW1hc209aW50ZWwifV19XX0=) — зліва `-O0`, справа `-O3 -mavx2 -mfma`.

**`saxpy` при `-O0`** — на кожен елемент ~20 інструкцій, усі змінні (`i`, `x`, `y`, `a`) живуть у стеку (`[rbp-8]`, `[rbp-32]`…) і на кожній ітерації перечитуються з пам'яті; обробляється одне число (`movss`, `mulss`, `addss` — *scalar single*):

```asm
.L18:
	mov	rax, QWORD PTR -8[rbp]
	lea	rdx, 0[0+rax*4]
	mov	rax, QWORD PTR -32[rbp]
	add	rax, rdx
	movss	xmm0, DWORD PTR [rax]
	movaps	xmm1, xmm0
	mulss	xmm1, DWORD PTR -20[rbp]
	...
	addss	xmm0, xmm1
	movss	DWORD PTR [rax], xmm0
	add	QWORD PTR -8[rbp], 1
.L17:
	mov	rax, QWORD PTR -8[rbp]
	cmp	rax, QWORD PTR -48[rbp]
	jb	.L18
```

**`saxpy` при `-O3 -mavx2 -mfma`** — 7 інструкцій на **8** елементів:

```asm
	vbroadcastss	ymm1, DWORD PTR .LC2[rip]
.L25:
	vmovaps	ymm0, YMMWORD PTR [rdx]
	vfmadd213ps	ymm0, ymm1, YMMWORD PTR [rax]
	add	rax, 32
	add	rdx, 32
	vmovaps	YMMWORD PTR -32[rax], ymm0
	cmp	rax, rcx
	jne	.L25
	vzeroupper
```

Що змінилось:

* **регістри замість стеку** — покажчики та лічильник у `rax`, `rdx`, `rcx`;
* **векторизація (SIMD)** — замість `movss/mulss/addss` (1 float) використовуються 256-бітні регістри `ymm` по 8 float;
* **FMA** — множення і додавання злиті в одну інструкцію з одним округленням;
* **спрощення циклу** — індекс `i*4` замінено на прямий зсув покажчиків на 32 байти, адреси глобальних масивів підставлені як константи (`constprop`).

#### 4.1.1 AVX-інструкції

| інструкція | розширення | дія |
|---|---|---|
| `vbroadcastss ymm1, [a]` | AVX | копіює одне число `a` у всі 8 «доріжок» (lanes) регістра |
| `vmovaps ymm0, [x]` | AVX | завантажує 8 float (32 байти, вирівняно) |
| `vfmadd213ps ymm0, ymm1, [y]` | FMA3 | `ymm0 = ymm1·ymm0 + [y]` для 8 чисел за одну інструкцію. `ps` = packed single |
| `vfmadd231ps` | FMA3 | те саме з іншим порядком операндів (`dst += a·b`) |
| `vmulps` | AVX | 8 множень паралельно |
| `vaddss` | AVX (скалярна) | одне додавання; `ss` = scalar single |
| `vextractf128`, `vshufps`, `vunpckhps` | AVX | перестановки/витягування частин регістра для горизонтальної суми |
| `vzeroupper` | AVX | обнуляє верхні 128 біт регістрів перед поверненням, щоб уникнути штрафу при переході до старого SSE-коду |

**`matmul` O3** — внутрішній цикл `j` векторизований, а цикл `k` розгорнутий на 2: два `vbroadcastss` (`a[i][k]`, `a[i][k+1]`) і два `vfmadd` на кожні 8 елементів рядка `C`:

```asm
.L33:
	vbroadcastss	ymm2, DWORD PTR [rdi]
	vbroadcastss	ymm1, DWORD PTR 4[rdi]
	...
.L30:
	vmovaps	ymm0, YMMWORD PTR [rcx+rax]
	vfmadd213ps	ymm0, ymm2, YMMWORD PTR [rdx+rax]
	vfmadd231ps	ymm0, ymm1, YMMWORD PTR [rsi+rax]
	vmovaps	YMMWORD PTR [rdx+rax], ymm0
	add	rax, 32
	cmp	rax, 2048
	jne	.L30
```

**`dot` O3** — множення векторизоване (`vmulps ymm`), але 8 добутків потім додаються **послідовно** скалярними `vaddss`. Причина: додавання чисел з плаваючою комою не асоціативне (`(a+b)+c ≠ a+(b+c)` через округлення), і стандарт C забороняє компілятору змінювати порядок сумування. З `-ffast-math` (`make fast`) GCC дозволяє собі це і генерує `vaddps ymm` з 8 частковими сумами — `dot` прискорюється ще приблизно в 1.5 раза, але контрольна сума трохи змінюється (774.9846 → 774.9919), тобто ми платимо точністю.

На Apple Silicon (ARM) замість AVX ті самі ідеї реалізує NEON: регістри `v0.4s` по 4 float, інструкції `ld1`, `fmla` (fused multiply-add), `dup` (broadcast).

### 4.2 Час та показники

| етап | O0, s | O3, s | прискорення | чому |
|---|---|---|---|---|
| fill | 0.041 | 0.024 | ×1.7 | лише регістри; векторизація неможлива — кожне число залежить від попереднього seed |
| matmul | 1.927 | 0.040 | **×48** | compute-bound: AVX (×8) + FMA + регістри + розгортання циклу |
| saxpy | 1.049 | 0.157 | ×6.7 | memory-bound: одна FMA-інструкція рахує 8 чисел, але на кожні 8 чисел треба прочитати 64 байти і записати 32 байти. Виходить ~30 ГБ/с — швидкість впирається в пам'ять, а не в обчислення, тому до ×8+ не дотягує |
| dot | 1.122 | 0.502 | ×2.2 | множення векторизоване, сума — ні (див. 4.1.1) |
| sort | 1.049 | 0.689 | ×1.5 | `qsort` у libc вже скомпільований з оптимізацією, прискорився лише наш `cmp` |
| **total** | **5.19** | **1.41** | **×3.7** | |

Пам'ять (RSS, page faults) не змінилась — структура даних та сама. User time впав з 5.12 до 1.39 s, кількість примусових перемикань контексту — з 415 до 66, бо програма просто працює менше часу і планувальник рідше встигає її витіснити. Зведена таблиця: [results/comparison.md](results/comparison.md).

### 4.3 FlameGraph після оптимізації

![O3](results/bench_O3/flamegraph.png)

* «Плато» `matmul` майже зникло (37% → 4%) — найбільший виграш;
* `saxpy` теж звузився (20% → 12%);
* тепер найширші сортування `qsort_r` (47%, з них `cmp` 12%) і `dot` (34%) — **гаряча точка змістилась**: наступна оптимізація має стосуватися саме їх (наприклад, `-ffast-math`/ручні часткові суми для `dot`, сортування без виклику компаратора через вказівник);
* у стеку зник кадр `sort_sample`: при `-O3` виклик `qsort` став хвостовим (tail call, `jmp` замість `call`), тож `qsort_r` відображається одразу над `main`;
* функції отримали суфікс `.constprop` (у скриптах прибирається, щоб графіки можна було порівняти).

**Диференційний FlameGraph** ([svg](results/diff/diff_O0_to_O3.svg)), `difffolded.pl -n`: форма — профіль O3, колір — як змінилась частка функції порівняно з O0 (червоний — частка зросла, синій — зменшилась). Двома видами синього виділено функції, що найбільше виграли від векторизації: `matmul` (насичений синій, частка 37% → 4%) і `saxpy` (20% → 12%). `dot` і сортування червоні — не тому, що стали повільнішими (абсолютно вони теж прискорились), а тому, що їхня частка в загальному часі зросла: AVX їм допоміг менше, ніж `matmul`. Для коректного порівняння ім'я процесу (`bench_O0`/`bench_O3`) у стеках замінюється на спільне `bench`, інакше `difffolded.pl` не зіставив би однакові стеки.

![diff](results/diff/diff_O0_to_O3.png)

### 4.4 Енерговитрати після оптимізації

| показник | O0 | O3 | O0 / O3 |
|---|---|---|---|
| час, s | 2.39 | 0.83 | ×2.9 |
| середня потужність, W | 5.25 | 4.44 | ×1.2 |
| енергія системи, J | 12.60 | 3.71 | **×3.4** |
| енергія програми (мінус фон), J | 11.07 | 3.10 | **×3.6** |
| енергія програми (частка CPU), J | 5.75 | 1.02 | ×5.6 |

**Енергія = потужність × час.** Оптимізована версія виконує ту саму роботу значно меншою кількістю інструкцій (NEON/SIMD обробляє кілька чисел за раз, змінні в регістрах, а не в пам'яті), тому працює майже втричі коротше.

Енергії зекономлено навіть більше, ніж часу (×3.4–3.6 проти ×2.9), бо в O3 ще й **нижча середня потужність** (4.44 проти 5.25 W). Менше інструкцій означає менше роботи для блоків декодування й виконання та менше звернень до пам'яті (у O0 кожна змінна читається й пишеться в стек на кожній ітерації).

Висновок: оптимізація швидкодії тут одночасно є енергетичною оптимізацією («race to idle»: швидше закінчив — раніше процесор повернувся в енергоощадний стан).

## Структура репозиторію

```
src/bench.c                 досліджувана програма
Makefile                    збірки O0 / O3 / fast, асемблер
.devcontainer/              середовище Codespaces (Ubuntu 24.04 + perf)
scripts/setup.sh            встановлення perf, time, FlameGraph
scripts/stats.sh            time --verbose, perf stat -d, perf record/report/annotate
scripts/flamegraph*.sh      FlameGraph програми, системи та диференційний
scripts/compare.sh          зведена таблиця O0 vs O3
scripts/run_all.sh          все разом
energy/measure_mac.py       енергія через powermetrics (macOS)
energy/rapl_linux.sh        енергія через Intel RAPL (Linux на залізі)
results/                    отримані результати
```
