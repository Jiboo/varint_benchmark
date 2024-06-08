zig build test && zig build -Doptimize=ReleaseFast && taskset -c 2 ./zig-out/bin/vle_bench && gnuplot src/plot.p
