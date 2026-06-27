# GSMA leaderboard comparison (gsma profile): falcon3-10b

- Track detected: `ot-full`
- Public source: GSMA/leaderboard (datasets)
- Primary metric: `acc,none`

## Per-task deltas

| Public column | Local task | Public | Local | Delta (local-public) | Note |
|---|---|---:|---:|---:|---|
| `teleqna` | `open_telco_full_teleqna_mcgen` | 0.6866 | 0.6984 | +0.0118 | engine UNALIGNED (free gen vs constrained decode); dominant candidate-gap driver; measures gen-vs-constrained sensitivity |
| `teletables` | `open_telco_full_teletables_mcgen` | 0.2767 | 0.2900 | +0.0133 | engine UNALIGNED (free gen vs constrained decode); dominant candidate-gap driver; measures gen-vs-constrained sensitivity |
| `oranbench` | `open_telco_full_oranbench_mcgen` | 0.6369 | 0.6787 | +0.0418 | engine UNALIGNED (free gen vs constrained decode); dominant candidate-gap driver; measures gen-vs-constrained sensitivity |
| `srsranbench` | `open_telco_full_srsranbench_mcgen` | 0.7679 | 0.7756 | +0.0077 | engine UNALIGNED (free gen vs constrained decode); dominant candidate-gap driver; measures gen-vs-constrained sensitivity |
| `telemath` | `open_telco_full_telemath_gsma` | 0.3433 | 0.2820 | -0.0613 |  |
| `telelogs` | `open_telco_full_telelogs_gsma` | 0.1910 | 0.1852 | -0.0058 |  |
| `three_gpp` | `open_telco_full_3gpp_tsg_gsma` | 0.3093 | 0.3085 | -0.0008 |  |

## Leaderboard-convention unweighted mean (NOT computed by official GSMA code)

| Aggregate | Value |
|---|---:|
| local unweighted task mean | 0.4598 |
| public unweighted mean (computed from tasks) | 0.4588 |
| public average (reported) | 0.4588 |
| delta unweighted (local mean - public computed mean) | +0.0010 |
| local group acc (sample-weighted) | 0.4598 |

## Caveat

CAVEAT (gsma profile):
- For the 4 MC tasks (teleqna/teletables/oranbench/srsranbench) the engine -- official multiple_choice(cot=False)+choice() constrained decoding vs lm-eval generate_until + until:[\n] + max_gen_toks:8 free single-letter generation -- is the LARGEST UNALIGNED axis and the dominant candidate-gap driver; the MC delta primarily measures generation-vs-constrained-decoding sensitivity, NEVER official reproduction.
- The *_gsma generation scorer rules mirror the gsma-evals source, but the generation engine differs (lm-eval generate vs Inspect generate).
- The GSMA repo computes no cross-task average; the single unweighted task mean below is a leaderboard convention only, NOT computed by official GSMA code.
- No production runtime / provider / model-revision parity is claimed.
