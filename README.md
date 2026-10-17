# ASUM: Sum of Absolute Values

ASUM computes the sum of the absolute values of a vector of `n` double-precision floats:

$$\text{asum} = \sum_{i=0}^{n-1} |A_i|$$

It is implemented in C, non-SIMD x86-64 assembly, and x86 SIMD assembly using XMM (128-bit) and YMM (256-bit) registers.

We also added an extra kernel for experimentation: unrolled YMM that uses 4 independent YMM registers.

## Benchmark Setup

| | |
| :--- | :--- |
| Machine | Google Cloud `c2-standard-4` |
| OS | Windows Server 2025 Datacenter |
| CPU | Intel Xeon @ 3.10 GHz (Cascade Lake), 4 vCPUs |
| Cache | L2: 2 MB, L3: 24.75 MB (shared) |
| RAM | 16 GB |
| Vector init | `A[i] = (i % 1000) - 500` |
| # of runs | 30 |

## Program Output

### Debug

![Debug output](screenshots/debug.png)

### Release

![Release output](screenshots/release.png)

## Boundary Handling

Each SIMD loop processes full registers while `i + width - 1 < n`; the remaining elements (at most 1 for XMM, 3 for YMM) are added one at a time with a scalar load. The unrolled YMM kernel processes 16 elements per iteration, then falls back to 4-wide blocks, then finally back to one at a time.

To test that the boundaries are correctly respected, aside from comparing against the C answer, we also added 8 extra elements to the end of every vector with the value `1e300`. This means that if the kernel goes beyond the boundary, its answer will immediately blow up to `1e300` and we can easily spot the error.

## Analysis

#### Table 1: Debug build

| N | C | x86-64 | XMM | YMM | YMM Unrolled |
| :--- | ---: | ---: | ---: | ---: | ---: |
| 2^20 | 2.6660 ms | 1.3336 ms (2.00x) | 0.6873 ms (3.88x) | 0.4338 ms (6.15x) | 0.3395 ms (7.85x) |
| 2^26 | 169.7 ms | 86.8 ms (1.96x) | 56.2 ms (3.02x) | 47.6 ms (3.57x) | 46.5 ms (3.65x) |
| 2^30 | 2717.9 ms | 1394.4 ms (1.95x) | 904.0 ms (3.01x) | 760.3 ms (3.57x) | 752.0 ms (3.61x) |
| **Geo. mean** | - | 1.97x | 3.28x | 4.28x | 4.69x |

#### Table 2: Release build

| N | C | x86-64 | XMM | YMM | YMM Unrolled |
| :--- | ---: | ---: | ---: | ---: | ---: |
| 2^20 | 1.3433 ms | 1.3448 ms (1.00x) | 0.7582 ms (1.77x) | 0.4740 ms (2.83x) | 0.3849 ms (3.49x) |
| 2^26 | 85.9 ms | 86.7 ms (0.99x) | 56.1 ms (1.53x) | 47.3 ms (1.82x) | 46.7 ms (1.84x) |
| 2^30 | 1376.5 ms | 1398.5 ms (0.98x) | 911.7 ms (1.51x) | 769.5 ms (1.79x) | 760.3 ms (1.81x) |
| **Geo. mean** | - | 0.99x | 1.60x | 2.10x | 2.26x |

### Which kernel is fastest?

YMM Unrolled is the fastest kernel at every size, followed by YMM, XMM, and then C and x86-64, which are tied. Against Release C, it is 3.49x faster at 2^20 but plateaus to only about 1.8x faster at 2^26 and 2^30. 


The plain YMM also follows the same pattern; it is 2.83x faster at 2^20, but falls down to 1.8x at the larger sizes.

### C vs. x86-64

In Release, C and our hand-written x86-64 kernel are within 2% of each other at every size. 

According to Microsoft's official [documentation](https://learn.microsoft.com/en-us/cpp/error-messages/tool-errors/vectorizer-and-parallelizer-messages), `cl` has `/fp:precise` by default, which does not allow reordering floating-point additions, so it cannot vectorize the loop. Thus, the generated machine code only uses scalar instructions and should be very similar to our hand-written x86-64 code. The 0.99x geometric mean also shows that they perform exactly the same.

### Is ASUM memory-bound or compute-bound?

It depends on the kernel and on where the data lives.

Consider the following table:

#### Table 3: Effective bandwidth

| N | C | x86-64 | XMM | YMM | YMM Unrolled |
| :--- | ---: | ---: | ---: | ---: | ---: |
| 2^20 | 6.2 GB/s | 6.2 GB/s | 11.1 GB/s | 17.7 GB/s | 21.8 GB/s |
| 2^26 | 6.3 GB/s | 6.2 GB/s | 9.6 GB/s | 11.4 GB/s | 11.5 GB/s |
| 2^30 | 6.2 GB/s | 6.1 GB/s | 9.4 GB/s | 11.2 GB/s | 11.3 GB/s |

*Values computed from the Release times as n * 8 bytes / time.*

- **Scalar kernels (C, x86-64)** are compute-bound at every size, fixed at ~6.2 GB/s.
- **SIMD, n=2^20**

At this size, the vector only takes up 8 MiB. This fits in our CPU's L3 cache, as mentioned in [Benchmark Setup](#benchmark-setup). Thus, the SIMD kernels are mostly compute-bound. We can see that stepping up width increases throughput: XMM 11.1 GB/s, YMM 17.7 GB/s, YMM Unrolled 21.8 GB/s.

- **SIMD, n=2^26, 2^30** 

At this size, the vector takes up 512 MiB and 8 GiB respectively. This means that the kernels have to read from DRAM.

We can see that the YMM kernels flatten at ~11.4 GB/s, and unrolling gains only 1%. This shows the memory latency bottleneck: no matter how fast the kernel can add, it cannot receive data faster than that. XMM (~9.5 GB/s) is a tad slower, but the slowdown is not as great as in 2^20 because compute throughput is less significant here.

In general, ASUM does very little work per byte: one AND and one add for every 8-byte element it loads. Once the computation is vectorized, the CPU can process data faster than memory can deliver it, so for large vectors ASUM is memory-bound.

### Why the speedup is far below the theoretical 4x

A 256-bit YMM register holds 4 doubles, so in theory YMM should be 4x faster than scalar code. That would only hold if the speed of the adds was the only limit.

As shown in [the previous section](#is-asum-memory-bound-or-compute-bound), at 2^26 and 2^30 the SIMD kernels are memory-bound: they plateau at ~11.4 GB/s no matter how fast they can add, so YMM only reaches ~1.8x over C.

At 2^20 the data comes from L3, so the kernels can go faster, and YMM Unrolled reaches 3.49x. Plain YMM falls short of that (2.83x) because its single accumulator still waits ~4 cycles between adds.

## Problems Encountered and AHA Moments

### Problems

**1. Unreliable timings on a laptop.** The first few times we ran the full benchmark were on a laptop with other applications open. The assembly kernels should not be affected by compiling in Debug or Release mode, yet their times differed by up to 25%. We hypothesized that this was because of background applications introducing noise, so we opted to benchmark in a cloud Windows Server machine, which runs significantly less background processes.

**2. Correct kernels reported as WRONG at 2^30.** The very first init we used was `A[i] = i`, which is the same one we used in the in-person group exercises. At n = 2^30 however, the sum is about 5.8 * 10^17 which is greater than 2^53, the point at which doubles can no longer represent integers accurately. Also, there were no negative values to actually test the absolute value capabilities.

As an alternative we picked `A[i] = (i % 1000) - 500`, which means every value is within the range `[-500, 500)`. The largest possible sum for this is below 2^53. 

**3. XMM kernel crashed on the benchmark machine but not on the personal laptop.** The mask is loaded with `vmodqa` which assumes 16-byte alignment. The mask already had `align 16`, but turns out NASM requires another `section .data align=16` to actually align the mask in memory.

### AHA Moments

**1. Wider registers only help if memory is not the bottleneck**


At n=2^20, the array is 8 MiB and fits comfortably in the L3 cache (mentioned in [Benchmark Setup](#benchmark-setup)). We can see that at this size, YMM is 1.6x faster than XMM, and unrolling the YMM into 4 independent accumulators gives another 1.23x speedup. At n=2^26 and n=2^30, however, data has to be read from DRAM, which is orders of magnitude slower than CPU cache. At this size, YMM is only 1.19x faster than XMM, and unrolling only gives another 1.01x speedup. The kernel is spending a lot more time waiting for memory compared to computing, so this is Amdahl's law in action.

**2. Unrolling also only helps with no memory bottleneck**


Each `vaddpd` must wait ~4 cycles for the previous one when there is a single accumulator. We added unrolling in the hopes that it would be a significant speedup, but as we saw earlier, YMM at just one accumulator is already bottlenecked by memory when we are processing n=2^26 and n=2^30 elements.

**3. Handling odd array sizes in XMM**


Since 128-bit XMM registers process 2 `double`s at a time, odd array sizes leave 1 leftover element. We handled this boundary by stopping the main vector loop early at N - 1 to look ahead and avoid reading past the array end. If there was a leftover element, we moved it into a register by itself (`.LEFTOVER`), applied our absolute value mask, and added it using scalar instructions (`vaddsd`) before combining the final total.


## Conclusion
