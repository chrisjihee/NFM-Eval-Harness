# GSMA leaderboard comparison: gemma3-4b

- Track detected: `ot-full`
- Public source: GSMA/leaderboard (datasets)
- Primary metric: `acc,none`

## Per-task deltas

| Public column | Local task | Public | Local | Delta (local-public) |
|---|---|---:|---:|---:|
| `teleqna` | `open_telco_full_teleqna` | 0.6523 | 0.4220 | -0.2303 |
| `teletables` | `open_telco_full_teletables` | 0.2733 | 0.2120 | -0.0613 |
| `oranbench` | `open_telco_full_oranbench` | 0.6600 | 0.3533 | -0.3067 |
| `srsranbench` | `open_telco_full_srsranbench` | 0.7400 | 0.5513 | -0.1887 |
| `telemath` | `open_telco_full_telemath` | 0.1367 | 0.0080 | -0.1287 |
| `telelogs` | `open_telco_full_telelogs` | 0.1167 | 0.1262 | +0.0095 |
| `three_gpp` | `open_telco_full_3gpp_tsg` | 0.2000 | 0.0865 | -0.1135 |

## Aggregates

| Aggregate | Value |
|---|---:|
| local group acc (sample-weighted) | 0.3540 |
| local unweighted task mean | 0.2513 |
| public average (reported) | 0.3970 |
| public unweighted mean (computed from tasks) | 0.3970 |
| delta unweighted (local mean - public computed mean) | -0.1457 |

## Caveat

CAVEAT:
- public avg is an UNWEIGHTED task mean, while the local group acc is SAMPLE-WEIGHTED. The honest like-for-like comparison is unweighted mean vs unweighted mean.
- The exact official GSMA extraction method and the public model variant are UNKNOWN, so each delta is a candidate gap, not a definitive conclusion.
- ot-lite uses a different split from ot-full / the public leaderboard; be careful comparing ot-lite directly against leaderboard numbers.
