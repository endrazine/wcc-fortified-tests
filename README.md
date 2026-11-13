# Automated Vulnerability Testing of glibc `_FORTIFY_SOURCE` Functions

This repository contains the reproducible test suite and reference dataset
for the `_FORTIFY_SOURCE` validation experiment described in:

> J. Brossard, *Beyond Reachability: Cross-Architecture Binary Libification
> and Procedural Debugging for Vulnerability Assessment*, PhD thesis,
> CNAM/CEDRIC, 2026.

The experiment applies the `testfunc()` fault-based oracle from the
[Witchcraft Compiler Collection](https://github.com/endrazine/wcc) to the
complete Ubuntu 26.04 `coreutils` binary corpus - all binaries compiled with
`-fPIE`, `_FORTIFY_SOURCE=2`, and stack canaries - and automatically
identifies 54 unique crashes across 52 distinct functions, of which 33 carry
an injected marker in the faulting address, proving attacker control of a
pointer argument.

## Quick start

```bash
# Build the Docker image (pulls Ubuntu 26.04 + builds WCC from source)
make

# Run the full experiment (deterministic, ~4.3 h on a single core)
make run
```

Or in one shot:

```bash
make && make run
```

The `run` target executes both passes sequentially: PoC generation
(`mk_fortify_pocs.sh`) followed by verification and deduplication
(`verify_pocs.wsh`).  Results are bind-mounted to the host's `/tmp/`.

```bash
# Compare against the reference dataset
diff /tmp/witchcraft-verified-pocs.log results/witchcraft-verified-pocs.log
```

## Repository layout

```
.
├── Dockerfile                              # Reproducible build environment
├── Makefile                                # Build and run targets
├── mk_fortify_pocs.sh                     # Top-level experiment orchestrator
├── verify_pocs.wsh                        # Deduplication and classification script
├── results/
│   ├── witchcraft-verified-pocs.log       # Reference output: verified unique crashes
│   ├── witchcraft-pocs.log                # Raw crash log (all invocations)
│   ├── witchcraft-minimized-pocs.log      # Minimized PoC set
│   ├── witchcraft-pocs-aliases.log        # Function alias mappings
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
| **Controlled** (marker in faulting address) | **33** |
| Unverified (crash without marker match) | 18 |
| Untagged (pending classification) | 3 |
| Elapsed wall-clock time (single core) | 4.3 h |
| PRNG seed | deterministic (`-s` flag) |

### What "controlled" means

Each function is invoked with marker-laden pointer arguments:
`0x41414141...` for argument 1, `0x42424242...` for argument 2, etc.
A crash is **controlled** when the faulting address contains the marker,
proving that the attacker-chosen value propagated through the function
into a dereferenced pointer - a concrete proof of exploitable memory
corruption.

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
