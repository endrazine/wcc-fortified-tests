# Automated Vulnerability Testing of glibc `_FORTIFY_SOURCE` Functions

This repository contains the reproducible test suite and reference dataset
for the `_FORTIFY_SOURCE` validation experiment described in:

> J. Brossard, *Beyond Reachability: Cross-Architecture Binary Libification
> and Procedural Debugging for Vulnerability Assessment*, PhD thesis,
> CNAM/CEDRIC, 2026.

The experiment applies the `testfunc()` fault-based oracle from the
[Witchcraft Compiler Collection](https://github.com/endrazine/wcc) to the
complete Ubuntu 26.04 `coreutils` binary corpus — all binaries compiled with
`-fPIE`, `_FORTIFY_SOURCE=2`, and stack canaries — and automatically
identifies 54 unique crashes across **52 distinct functions, all of which
carry an injected marker in the faulting address**, proving attacker control
of a pointer argument (100 % control rate).

## Quick start

```bash
# Build the Docker image (pulls Ubuntu 26.04 + builds WCC from source)
make

# Run the full experiment (deterministic, ~4.5 h on a single core)
make run
```

Or in one shot:

```bash
make && make run
```

The `run` target executes three passes sequentially:

1. **PoC generation** (`mk_fortify_pocs.sh`) — invokes every `_FORTIFY_SOURCE`
   function with marker-laden arguments across 6 PRNG seeds.
2. **Strict verification** (`verify_pocs.wsh`) — deduplicates crashes and
   classifies each by exact fault-mode matching.
3. **Relaxed verification** (`verify_remaining.wsh`) — re-tests the functions
   that strict verification could not confirm, using per-argument 32-bit
   markers (0x41414141–0x46464646) with fault-mode-independent matching.

Results are bind-mounted to the host's `/tmp/`.

```bash
# Compare against the reference datasets
diff /tmp/witchcraft-verified-pocs.log results/witchcraft-verified-pocs.log
diff /tmp/witchcraft-remaining-pocs.log results/witchcraft-remaining-pocs.log
```

## Repository layout

```
.
├── Dockerfile                              # Reproducible build environment
├── Makefile                                # Build and run targets
├── mk_fortify_pocs.sh                     # Top-level experiment orchestrator
├── verify_pocs.wsh                        # Pass 1: strict deduplication and classification
├── verify_remaining.wsh                   # Pass 2: relaxed verification of remaining functions
├── results/
│   ├── witchcraft-verified-pocs.log       # Reference output: pass 1 (strict verification)
│   ├── witchcraft-remaining-pocs.log      # Reference output: pass 2 (relaxed verification)
│   ├── witchcraft-pocs.log                # Raw crash log (all invocations)
│   ├── witchcraft-minimized-pocs.log      # Minimized PoC set
│   ├── witchcraft-pocs-aliases.log        # Function alias mappings (IFUNC resolution)
│   ├── witchcraft-reads.log               # Read-access fault log
│   ├── witchcraft-abrt.log                # SIGABRT-specific crashes
│   └── witchcraft-misc.log                # Miscellaneous signal log
├── CITATION.cff                           # Citation metadata (CFF format)
└── LICENSE                                # MIT
```

## Results summary

| Metric | Value |
|--------|-------|
| Total crash-producing invocations | 7,749 |
| Unique crashes (deduplicated) | 54 |
| Distinct crashing functions | 52 |
| **Controlled** (marker in faulting address) | **52** |
| Control rate | **100 %** |
| Elapsed wall-clock time (single core) | ~4.5 h |
| PRNG seed | deterministic (`-s` flag) |

### What "controlled" means

Each function is invoked with marker-laden pointer arguments:
`0x41414141...` for argument 1, `0x42424242...` for argument 2, etc.
A crash is **controlled** when the faulting address contains the marker,
proving that the attacker-chosen value propagated through the function
into a dereferenced pointer — a concrete proof of exploitable memory
corruption.

### Three-tier evidence

Verification proceeds in three tiers, from strongest to most inclusive:

| Tier | Functions | Method |
|------|-----------|--------|
| **Strict PoC** | 32 | `verify_pocs.wsh` — exact fault-mode match (WRITE/EXEC) between original crash and simplified replay |
| **Relaxed PoC** | 13 | `verify_remaining.wsh` — marker-controlled fault address with any signal match, independent of fault mode |
| **Raw log + IFUNC alias** | 7 | Confirmed CONTROLLED in `witchcraft-pocs.log` and `witchcraft-pocs-aliases.log` via glibc IFUNC resolution |
| **Total** | **52** | |

#### IFUNC aliasing

Seven functions — `memcpy`, `strcpy`, `strcat`, `strncat`, `strncpy`,
`stpncpy`, and `wmemset` — cannot be replayed in a simplified `testfunc()`
call because glibc resolves them at runtime through the
[IFUNC](https://sourceware.org/glibc/wiki/GNU_IFUNC) (indirect function)
mechanism to architecture-optimized implementations (e.g.,
`__memmove_avx_unaligned_erms` for `memcpy`).  The original PoC generation
phase calls them successfully (the IFUNC resolver runs once at process
startup), but the verification scripts' forked child process cannot
reproduce the dispatch.

These seven functions are nonetheless confirmed controlled:

- The raw crash log (`witchcraft-pocs.log`) contains hundreds of
  CONTROLLED entries for each (e.g., `memcpy`: 103 entries, `strcpy`:
  103 entries).
- The alias log (`witchcraft-pocs-aliases.log`) independently confirms
  the same crashes under their IFUNC-resolved symbol names with injected
  markers in the faulting address.

## Reproducing the experiment

The experiment is fully deterministic: given the same Docker base image,
WCC version, and PRNG seed, the output is bitwise identical.

### Requirements

- Docker 20.10+
- ~2 GB disk for the image
- ~4.5 hours of single-core CPU time

### Seed

The PRNG seed is passed via `wsh -s <seed>` and controls the argument
patterns supplied to each function.  The reference dataset was produced
with the seed recorded in the experiment environment.

## Citing this work

If you use this dataset or test suite, please cite both the thesis and
the Zenodo artifact:

```bibtex
@phdthesis{brossard2026beyond,
  author = {Brossard, Jonathan},
  title  = {Beyond Reachability: Cross-Architecture Binary Libification
            and Procedural Debugging for Vulnerability Assessment},
  school = {CNAM/CEDRIC},
  year   = {2026}
}

@misc{brossard2026fortified,
  author    = {Brossard, Jonathan},
  title     = {Automated Vulnerability Testing of glibc
               {\_FORTIFY\_SOURCE} Functions},
  year      = {2026},
  publisher = {Zenodo},
  doi       = {10.5281/zenodo.24201454}
}
```

## License

MIT.  See [LICENSE](LICENSE).
