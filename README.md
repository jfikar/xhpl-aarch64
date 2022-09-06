# xhpl-aarch64 
## Compiled [HPL (High-Performance Linpack Benchmark)](https://netlib.org/benchmark/hpl/) for Linux on ARM64 (AARCH64)

[HPL](https://en.wikipedia.org/wiki/LINPACK_benchmarks) is used by [top500.org](https://www.top500.org/) to rank the world fastest supercomputers by [FLOPs](https://en.wikipedia.org/wiki/FLOPS) (floating points operations per second). It can also be used to test the stability of your CPU, CPU frequency throttling (you either observe the actual frequency or you can tell by lower FLOPs), CPU cache, RAM, and the power supply as the HPL is quite demanding and does also the result verification (see PASSED/FAILED below). On the other hand, HPL is not so good for testing the maximum temperature. The CPU gets really hot during the calculation phase, but it cools down a bit during the verification phase.

The best FLOPs for ARM64 (probably for other archs as well) are obtained using [OpenBLAS library](https://www.openblas.net/), but do not use the library compiled by your distribution. For better results compile it yourself or use the provided binaries. Alternatively one can use [BLIS libraries](https://github.com/flame/blis) or any other BLAS implementation, but it results in fewer FLOPs.

## How to compile yourself

### Compile OpenBLAS
```
wget https://github.com/xianyi/OpenBLAS/archive/refs/tags/v0.3.21.tar.gz
tar xvf v0.3.21.tar.gz
cd OpenBLAS-0.3.21
make -j$(nproc) TARGET=CORTEXA53
make PREFIX=/home/<username>/openblas install
rm ~/openblas/lib/*so*
```
The possible TARGETs are listed in file the `TargetList.txt`. For us are relevant: ARMV8, CORTEXA53, CORTEXA55, CORTEXA57, CORTEXA72, and CORTEXA73.

We deleted the shared libraries (so) in order to link the OpenBLAS statically to the final xhpl binary.

### Compile HPL
```
sudo apt install -y libopenmpi-dev
wget https://www.netlib.org/benchmark/hpl/hpl-2.3.tar.gz
tar xvf hpl-2.3.tar.gz
cd hpl-2.3
LDFLAGS=-L/home/<username>/openblas/lib ./configure
make -j$(nproc)
```

The resulting binary is `hpl-2.3/testing/xhpl`

It turns out that the binary for CORTEX-A53 and CORTEXA55 are the same. And CORTEX57 and CORTEX72 are identical as well. It is so because HPL uses just a few functions from OpenBLAS, which are for those targets identical.

## Using precompiled binaries

As said above, the CORTEX-A53 and CORTEX-A55 are the same as well as the CORTEX-A57 and CORTEX-A72 are the same.

You need an openmpi library, even though we will not run it in MPI mode but in OpenMP mode, which automatically will use all the cores. If you want to use MPI, then change P and Q in HPL.dat.
```
sudo apt install openmpi-bin
```
You need to create a text file `HPL.dat` file, for example like this:
```
HPLinpack benchmark input file
Innovative Computing Laboratory, University of Tennessee
HPL.out     output file name (if any)
6           device out (6=stdout,7=stderr,file)
1           # of problems sizes (N)
28000       Ns
12          # of NBs
32 48 64 80 96 112 128 144 160 176 192 208 NBs
0           PMAP process mapping (0=Row-,1=Column-major)
1           # of process grids (P x Q)
1           Ps
1           Qs
16.0        threshold
1           # of panel fact
1           PFACTs (0=left, 1=Crout, 2=Right)
1           # of recursive stopping criterium
4           NBMINs (>= 1)
1           # of panels in recursion
2           NDIVs
1           # of recursive panel fact.
2           RFACTs (0=left, 1=Crout, 2=Right)
1           # of broadcast
0           BCASTs (0=1rg,1=1rM,2=2rg,3=2rM,4=Lng,5=LnM)
1           # of lookahead depth
0           DEPTHs (>=0)
2           SWAP (0=bin-exch,1=long,2=mix)
8           swapping threshold
0           L1 in (0=transposed,1=no-transposed) form
0           U  in (0=transposed,1=no-transposed) form
1           Equilibration (0=no,1=yes)
8           memory alignment in double (> 0)
```

The parameter `Ns` is the size of the square matrix Ns x Ns. The memory consumption is thus proportional to Ns^2. Ns=20000 needs around 4GB RAM, for 8GB use 28000, for 2GB use 14000, and for 1GB 10000. Try to use all the RAM as it improves the FLOPs, but you should avoid swapping as it drastically decreased FLOPs.

| RAM (GB)  | optimal Ns |
| ------------- | ------------- |
| 0.5| 7000   |
| 1  | 10000  |
| 2  | 14000  |
| 4  | 20000  |
| 8  | 28000  |
| 16 | 40000  |
| 32 | 57000  |

There is [a formula](https://github.com/open-power/op-benchmark-recipes/blob/master/standard-benchmarks/HPL/Linpack_HPL.dat_tuning.md) to calculate the N.

The parameters NB determines, how big blocks are used for calculation. Its optimization is a bit of guesswork. It probably depends a lot on CPU caches and RAM speed. So in the example file you have 12 different NBs. The HPL will run for all of them and you can choose the one with the highest FLOPs.

Then just run `xhpl`. Sample output:
```
HPLinpack 2.3  --  High-Performance Linpack benchmark  --   December 2, 2018
Written by A. Petitet and R. Clint Whaley,  Innovative Computing Laboratory, UTK
Modified by Piotr Luszczek, Innovative Computing Laboratory, UTK
Modified by Julien Langou, University of Colorado Denver
================================================================================

An explanation of the input/output parameters follows:
T/V    : Wall time / encoded variant.
N      : The order of the coefficient matrix A.
NB     : The partitioning blocking factor.
P      : The number of process rows.
Q      : The number of process columns.
Time   : Time in seconds to solve the linear system.
Gflops : Rate of execution for solving the linear system.

The following parameter values will be used:

N      :   20000
NB     :      32       48       64       80       96      112      128      144
             160      176      192      208
PMAP   : Row-major process mapping
P      :       1
Q      :       1
PFACT  :   Crout
NBMIN  :       4
NDIV   :       2
RFACT  :   Right
BCAST  :   1ring
DEPTH  :       0
SWAP   : Mix (threshold = 8)
L1     : transposed form
U      : transposed form
EQUIL  : yes
ALIGN  : 8 double precision words

--------------------------------------------------------------------------------

- The matrix A is randomly generated for each test.
- The following scaled residual check will be computed:
      ||Ax-b||_oo / ( eps * ( || x ||_oo * || A ||_oo + || b ||_oo ) * N )
- The relative machine precision (eps) is taken to be               1.110223e-16
- Computational tests pass if scaled residuals are less than                16.0

================================================================================
T/V                N    NB     P     Q               Time                 Gflops
--------------------------------------------------------------------------------
WR00R2C4       20000    32     1     1             522.34             1.0212e+01
HPL_pdgesv() start time Fri Aug 26 12:45:04 2022
HPL_pdgesv() end time   Fri Aug 26 12:53:47 2022

--------------------------------------------------------------------------------
||Ax-b||_oo/(eps*(||A||_oo*||x||_oo+||b||_oo)*N)=   4.40719904e-03 ...... PASSED
...
```
Sometimes instead of PASSED you can see FAILED, which means that the residual sums are higher than expected and your CPU calculated the result wrongly. It can be due to too high CPU frequency, not enough CPU voltage, or due to overheating.
Often the computer may also crash or restart. Which is also a sign of instability.

### Huge Pages
The Huge Pages can improve your FLOPs by approximately 10%. The easiest is to enable the Transparent Huge Pages (THP), if they are supported by your kernel. E.g. Raspberry Pi for some reason has THP disabled.

```
echo always | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
echo always | sudo tee /sys/kernel/mm/transparent_hugepage/defrag
echo 1 | sudo tee /sys/kernel/mm/transparent_hugepage/use_zero_page
```

### FLOPs

The best FLOPs from 20 runs

| board | cpu | GHz | cores | RAM GB | Ns | optimal NB | binary | GFLOPs | THP | FLOPs/cycle/core |
|-------|-----|-----|-------|--------|---|------------|--------|--------|-----|------------------|
| Raspberry3B+| A53 | 1.4  | 4 | 1 |       |     |        |       |  no |      |
| Raspberry4  | A72 | 1.8  | 4 | 8 | 28000 | 128 | a57/72 | 16.02 |  no | 2.23 |
| Odroid-HC4  | A55 | 1.8  | 4 | 4 | 18000 | 144 | a53/55 | 14.29 | yes | 1.98 |
| Odroid-M1   | A55 | 1.992| 4 | 8 | 28000 | 144 | a53/55 | 15.08 | yes | 1.89 |
| VIM 3 big   | A73 | 2.4  | 4 | 4 |       |     |        |       | yes |      |
| VIM 3 LITTLE| A52 | 2.016| 2 | 4 |       |     |        |       | yes |      |
| OrangePi4 big   |A72|  1.8 | 2 | 4 |       |     |        |       | yes |      |
| OrangePi4 LITTLE|A53|1.416 | 4 | 4 |       |     |        |       | yes |      |

If you have more results, I can add them to the table.

According to [Wikiwand](https://www.wikiwand.com/en/FLOPS) Cortex-A53, A55, A72, and A73 should have 2 FLOPs/cycle/core. So you can check that your ARM is reaching the correct FLOPs as it should.

I'm not sure, how to handle big.LITTLE archs as HPL distributes the tasks equally, so the faster cores will wait for the slower ones. The easiest is to test separately the big and then the LITTLE cluster using `taskset` to target the needed cores. In this case we will get correct FLOPs for the clusters, but we will not maximally stress the CPU.

### Notes

#### Raspberry Pi 4

Uses the aluminium Armor Case with Dual Fan. To achieve 1.8GHz on newer boards, you need `arm_boost=1` in `/boot/config.txt`. You also should specify `hdmi_enable_4kp60=1`, which increases the core frequency from 500 to 550 MHz. The thermal throtling can be checked by `vcgencmd get_throttled`.

#### Odroid-M1

I used a large 10cm fan on the passive heatsink. Temperature was under 47C. Otherwise the results were lower and more scattered. It indicates thermal throttling with only the passiwe heatsink pointing up, even though the `/sys/devices/system/cpu/cpufreq/policy0/scaling_cur_freq` still reports the default frequency of 1.992GHz. The GFLOPs with the passive cooling were 13.3, so the frequency probably dropped to 1.757GHz.
