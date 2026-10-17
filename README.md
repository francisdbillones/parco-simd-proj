## Benchmark Setup

## Program Output

## Analysis

#### Table 1: Release build

| N | C | x86-64 | XMM | YMM | YMM Unrolled |
| :--- | ---: | ---: | ---: | ---: | ---: |
| 2^20 | 2.0714 ms | 2.0792 ms (1.00x) | 1.0461 ms (1.98x) | 0.5527 ms (3.75x) | 0.5316 ms (3.90x) |
| 2^26 | 108.5706 ms | 95.5481 ms (1.14x) | 52.4896 ms (2.07x) | 33.3825 ms (3.25x) | 33.2905 ms (3.26x) |
| 2^30 | 1793.1905 ms | 1588.1247 ms (1.13x) | 866.4376 ms (2.07x) | 593.9906 ms (3.02x) | 545.8467 ms (3.29x) |

#### Table 2: Debug build

| N | C | x86-64 | XMM | YMM | YMM Unrolled |
| :--- | ---: | ---: | ---: | ---: | ---: |
| 2^20 | -- ms | -- ms (--x) | -- ms (--x) | -- ms (--x) | -- ms (--x) |
| 2^26 | -- ms | -- ms (--x) | -- ms (--x) | -- ms (--x) | -- ms (--x) |
| 2^30 | -- ms | -- ms (--x) | -- ms (--x) | -- ms (--x) | -- ms (--x) |


## Conclusion
