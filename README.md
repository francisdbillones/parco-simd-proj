## Benchmark Setup

| | |
| :--- | :--- |
| Machine | Google Cloud `c2-standard-4` |
| OS | Windows Server 2025 Datacenter |
| CPU | Intel Xeon @ 3.10 GHz (Cascade Lake), 4 vCPUs |
| RAM | 16 GB |
| Vector init | `A[i] = (i % 1000) - 500` |

## Program Output

## Analysis

#### Table 1: Release build

| N | C | x86-64 | XMM | YMM | YMM Unrolled |
| :--- | ---: | ---: | ---: | ---: | ---: |
| 2^20 | 1.3433 ms | 1.3448 ms (1.00x) | 0.7582 ms (1.77x) | 0.4740 ms (2.83x) | 0.3849 ms (3.49x) |
| 2^26 | 85.8962 ms | 86.7491 ms (0.99x) | 56.1109 ms (1.53x) | 47.2915 ms (1.82x) | 46.7091 ms (1.84x) |
| 2^30 | 1376.5255 ms | 1398.5386 ms (0.98x) | 911.7487 ms (1.51x) | 769.5211 ms (1.79x) | 760.3184 ms (1.81x) |
| **Geo. mean** | - | 0.99x | 1.60x | 2.10x | 2.26x |

#### Table 2: Debug build

| N | C | x86-64 | XMM | YMM | YMM Unrolled |
| :--- | ---: | ---: | ---: | ---: | ---: |
| 2^20 | 2.6660 ms | 1.3336 ms (2.00x) | 0.6873 ms (3.88x) | 0.4338 ms (6.15x) | 0.3395 ms (7.85x) |
| 2^26 | 169.7235 ms | 86.7881 ms (1.96x) | 56.1591 ms (3.02x) | 47.5828 ms (3.57x) | 46.5497 ms (3.65x) |
| 2^30 | 2717.8511 ms | 1394.3729 ms (1.95x) | 904.0435 ms (3.01x) | 760.3396 ms (3.57x) | 751.9602 ms (3.61x) |
| **Geo. mean** | - | 1.97x | 3.28x | 4.28x | 4.69x |


## Conclusion
