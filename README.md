## Benchmark Setup

## Program Output

## Analysis

#### Table 1: Release Build 

| Kernel Version | Data Size (N) | Machine F Time (ms) | Machine F Speedup | Machine R Time (ms) | Machine R Speedup |
| :--- | :--- | :---: | :---: | :---: | :---: |
| **C Baseline** | 2^20 | -- ms | -- | -- ms | -- |
| | 2^26 | -- ms | -- | -- ms | -- |
| | 2^30 | -- ms | -- | -- ms | -- |
| | **Geometric Mean** | -- | -- | **-- ms** | -- |
| **x86-64 Non-SIMD** | 2^20 | -- ms | -- | -- ms | -- |
| | 2^26 | -- ms | -- | -- ms | -- |
| | 2^30 | -- ms | -- | -- ms | -- |
| | **Geometric Mean** | **-- ms** | **--** | **-- ms** | **--** |
| **SIMD XMM (128-bit)** | 2^20 | -- ms | -- | -- ms | -- |
| | 2^26 | -- ms | -- | -- ms | -- |
| | 2^30 | -- ms | -- | -- ms | -- |
| | **Geometric Mean** | -- | -- | **-- ms** | **--** |
| **SIMD YMM (256-bit)** | 2^20 | -- ms | -- | -- ms | -- |
| | 2^26 | -- ms | -- | -- ms | -- |
| | 2^30 | -- ms | -- | -- ms | -- |
| | **Geometric Mean** | **-- ms** | **--** | **-- ms** | **--** |


## Conclusion
