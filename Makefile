ARCH    := $(shell uname -m)
ifeq ($(ARCH),x86_64)
SIMD    := -mavx2 -mfma
ASMFLAGS := -masm=intel
else
SIMD    :=
ASMFLAGS :=
endif
COMMON  := -g -fno-omit-frame-pointer -Wall
BIN     := build

all: $(BIN)/bench_O0 $(BIN)/bench_O3

$(BIN):
	mkdir -p $(BIN)

$(BIN)/bench_O0: src/bench.c | $(BIN)
	$(CC) -O0 $(COMMON) $< -o $@

$(BIN)/bench_O3: src/bench.c | $(BIN)
	$(CC) -O3 $(SIMD) $(COMMON) $< -o $@

$(BIN)/bench_fast: src/bench.c | $(BIN)
	$(CC) -O3 -ffast-math $(SIMD) $(COMMON) $< -o $@

fast: $(BIN)/bench_fast

asm: | $(BIN)
	$(CC) -O0 -S $(ASMFLAGS) -fno-asynchronous-unwind-tables src/bench.c -o $(BIN)/bench_O0.s
	$(CC) -O3 $(SIMD) -S $(ASMFLAGS) -fno-asynchronous-unwind-tables src/bench.c -o $(BIN)/bench_O3.s

clean:
	rm -rf $(BIN) perf.data*

.PHONY: all asm fast clean
