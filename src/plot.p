set terminal png size 800,450
set xlabel 'significant bits'
set xtics 8
set grid

set key right bottom
set output 'graphs/bytes.png'
set ylabel 'byte size (values shifted a bit to prevent overlapping)'
plot "results/fixed.txt" using 2:($3) with lines title "fixed",\
     "results/prefix.txt" using 2:($3) with lines title "prefix",\
     "results/sqlite4.txt" using 2:($3-0.20) with lines title "sqlite4",\
     "results/vint64.txt" using 2:($3-0.10) with lines title "vint64",\
     "results/vu128.txt" using 2:($3+0.10) with lines title "vu128",\
     "results/uleb128.txt" using 2:($3+0.20) with lines title "uleb128"

set key left top
set output 'graphs/encode.png'
set ylabel 'encode time avg (ns)'
plot "results/fixed.txt" using 2:6 with lines title "fixed",\
     "results/prefix.txt" using 2:6 with lines title "prefix",\
     "results/sqlite4.txt" using 2:6 with lines title "sqlite4",\
     "results/vint64.txt" using 2:6 with lines title "vint64",\
     "results/vu128.txt" using 2:6 with lines title "vu128",\
     "results/uleb128.txt" using 2:6 with lines title "uleb128"

set output 'graphs/encode2.png'
set ylabel 'encode time avg (ns), without uleb128'
plot "results/fixed.txt" using 2:6 with lines title "fixed",\
     "results/prefix.txt" using 2:6 with lines title "prefix",\
     "results/sqlite4.txt" using 2:6 with lines title "sqlite4",\
     "results/vint64.txt" using 2:6 with lines title "vint64",\
     "results/vu128.txt" using 2:6 with lines title "vu128"

set output 'graphs/decode.png'
set ylabel 'decode time avg (ns)'
plot "results/fixed.txt" using 2:11 with lines title "fixed",\
     "results/prefix.txt" using 2:11 with lines title "prefix",\
     "results/sqlite4.txt" using 2:11 with lines title "sqlite4",\
     "results/vint64.txt" using 2:11 with lines title "vint64",\
     "results/vu128.txt" using 2:11 with lines title "vu128",\
     "results/uleb128.txt" using 2:11 with lines title "uleb128"

set output 'graphs/decode2.png'
set ylabel 'decode time avg (ns), without uleb128'
plot "results/fixed.txt" using 2:11 with lines title "fixed",\
     "results/prefix.txt" using 2:11 with lines title "prefix",\
     "results/sqlite4.txt" using 2:11 with lines title "sqlite4",\
     "results/vint64.txt" using 2:11 with lines title "vint64",\
     "results/vu128.txt" using 2:11 with lines title "vu128"
