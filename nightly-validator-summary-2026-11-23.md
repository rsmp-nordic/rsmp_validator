# Nightly validator summary — 2026-11-23 UTC

Investigate Kapsch priority activation and TMacs handshake order first, check the validator’s Cartesio buffer test, and restore the four TMacs combinations that produced no conformance result.

**Coverage at 2026-11-24 10:20:46 UTC.** All **9 expected workflows** ran and supplied reports. Of **303 expected matrix jobs**, Actions recorded **284 passed, 13 failed and 6 incomplete**. The 293 compliance reports give **284 passes and 9 failures**. Conformance is unknown for **10 jobs**, including four TMacs jobs without a report and six unfinished Swarco jobs. No scheduled run was missing, cancelled or retried this night.

| Scheduled workflow on `main` | Expected jobs | Passed | Failed | Incomplete | Reports |
|---|---:|---:|---:|---:|---:|
| [Gem TLC][gt] | 80 | 80 | 0 | 0 | 80 |
| [Gem supervisor][gs] | 80 | 80 | 0 | 0 | 80 |
| [Swarco ITC-3][sw] | 70 | 64 | 0 | 6 | 64 |
| [TECSEN TMacs][tm] | 42 | 35 | 7 | 0 | 38 |
| [Cartesio][ca] | 7 | 4 | 3 | 0 | 7 |
| [Kapsch ETX][ka] | 7 | 4 | 3 | 0 | 7 |
| [Cross RS4S][rs4] | 8 | 8 | 0 | 0 | 8 |
| [Cross RS5][rs5] | 1 | 1 | 0 | 0 | 1 |
| [Lightmotion Satellite][lm] | 8 | 8 | 0 | 0 | 8 |

The two gem matrices and Swarco were due at 18:48 UTC on November 23, the other six at 22:00. GitHub created all nine scheduled runs between 04:05 and 05:48 UTC on November 24 at commit `3b91046`. TMacs and gem supervisor ran `test/supervisor`, the other seven ran `test/site`. Comparisons below use the November 16–22 scheduled nights and match target, test, Core and TLC SXL. [Workflow definitions at the tested commit][workflows]

## New or worsened findings

**Kapsch ETX — priority requests stopped at activation.** On TLC 1.2.1, the uncancelled-request test failed on Core 3.2.0, 3.2.1 and 3.2.2. The cancellation test also failed on 3.2.1 and 3.2.2. Four of these five test/version pairs passed on all seven previous nights. The 3.2.1 uncancelled test passed six times, then failed last night *after* activation. This night all five failed while waiting for activation. On 3.2.1, M0022 message `9234` requested priority `4157` at 05:54:21.201. S0033 update `f0fb` showed it as `received`. The validator unsubscribed ten seconds later. The initial status list still included six requests marked active since the previous day. The matching gem simulator logged activation and cancellation of its own request `e06d`. **Undetermined.** SXL permits several outcomes after receipt, and the test config allows ten seconds. Check the controller’s priority queue for `4157` and compare its decision time with the S0033 trace to distinguish scheduling delay from a missing update. [Kapsch job][kap-job] · [Previous 3.2.1 job][kap-prev] · [Gem simulator comparison][gt-peer] · [Priority assertions][priority-test] · [Timeout][kap-config] · [SXL state transitions][states]

**TMacs — the Core 3.1.2 connection test now fails in two different places.** All six SXL combinations failed the same connection test on each of the three previous full-matrix nights, when the validator rejected `sOc` in an incoming subscription. The four earlier nights scheduled only Core 3.2.2, so their 3.1.2 baseline is unknown. [Previous full matrix][tm-prev]

- **TLC 1.0.13, 1.0.14 and 1.0.15 — likely equipment.** The Version exchange passed. With 1.0.13, TMacs sent Version `6e22` at 05:40:38.454 and StatusSubscribe `d55e` at 05:40:38.671. The validator’s simulated site answered with StatusUpdate `914c` and logged a missing peer watchdog five seconds later. The session became ready about 30 seconds after Version. The first eight messages failed the watchdog assertion. Core 3.1.2 puts watchdog exchange ahead of subscription restoration, and the gem supervisor passed the same assertion on 1.0.13. Check TMacs’ first outbound watchdog timestamp against `d55e` to confirm whether it waits for its periodic timer during connection setup. [TMacs job][tm-watch] · [Gem peer][gs-watch] · [Assertion][sequence] · [Core establishment order][order]
- **TLC 1.1.0, 1.2.0 and 1.2.1 — test infrastructure/configuration.** All three reached `Run tests` and exited before writing JSON. With 1.2.1, TMacs subscription `efe9` arrived at 05:50:22.201. The validator’s simulated site rejected its own outgoing update `5b2e` 18 ms later with `/sS/14/s, string`. Element 14 was S0033 `status: []`. The SXL defines an array, and the tested site suite gates this feature on Core ≥3.2.0. Check whether the TMacs subscription profile requests S0033 for a 3.1.2 session. A gem supervisor pass establishes the handshake. Exercising this subscription is the distinguishing check. [1.1.0 log][tm110] · [1.2.0 log][tm120] · [1.2.1 log][tm121] · [Matrix][tm-matrix] · [SXL array definition][array] · [Validator version gate][priority]

**TMacs — one new runner setup failure.** Core 3.2.0 / TLC 1.2.0 passed on all three previous full-matrix nights. At 06:13:26, Bundler 4.0.9 could not load `bundler/cli/install` during `Install Ruby and gems`. The test step was skipped. **Test infrastructure/configuration.** Check that the self-hosted runner’s Ruby 4.0.10 tool cache contains the complete Bundler installation. [Failed setup][setup] · [Previous passing job][setup-prev]

**Cartesio — S0207 occupancy missed its first update on Core 3.2.1 / TLC 1.2.1.** This exact pair passed the occupancy assertions on all seven previous nights. The same symptom occurred on 3.1.4 last night, which passed this morning. At 06:47:00.970 the validator subscribed to `start` and `occupancy` with `dc49`. Cartesio acknowledged it at 06:47:01.065. At 06:48:00.980 the validator unsubscribed with `Matched 0/2`. The gem TLC returned both fields after 44 ms on the same versions. **Undetermined.** Core calls for an immediate first update unless the subscription is already active. Check Cartesio’s active subscriptions at `dc49` and the first outbound S0207 timestamp. The configured timeout equals the 60-second periodic interval, so a periodic update could also miss the deadline. [Cartesio log][ca321] · [Previous 3.2.1 job][ca-prev321] · [Gem peer][gt-peer] · [Test][occupancy] · [Timeout selection][wait] · [Cartesio config][ca-config] · [Core rule][initial]

## Recurring finding

**Cartesio — the buffer test used an old sample to date the next outage. Likely validator.** On Core 3.2.0–3.2.2 / TLC 1.2.1, all three tests failed at line 121, before checking `q=old`. On 3.2.1, subscription `9560` received an already-old S0001 sample timestamped 06:37:35.199 at 06:37:58.215. The validator disconnected at 06:37:58.221, then searched for updates timestamped **06:37:35.699–36.699**. The other two logs show the same roughly 23-second gap. The same assertion failed on all seven prior nights for 3.2.1 and 3.2.2, and on six for 3.2.0. Ruby setup failed on the remaining night. Anchor the outage to a fresh S0001 sample, then check replay and quality against the Core buffering requirement. [3.2.1 trace][ca321] · [Window calculation][buffer] · [Failed assertion][buffer-assert] · [Core buffering rule][buffer-rule] · [Missing 3.2.0 baseline][ca-gap]

## Recoveries and remaining gaps

- **Cross RS4S and RS5.** The previously failing M0001 and M0104 response-timestamp tests ran and passed on all eight RS4S Core versions and on RS5 Core 3.2.0, all with TLC 1.2.1. The M0001 assertion measured a 2-second offset in one RS4S job and zero on RS5, within the 60-second tolerance. [RS4S job][rs4-job] · [Previous RS4S run][rs4-prev] · [RS5 job][rs5-job] · [Previous RS5 run][rs5-prev]
- **Kapsch and Cartesio.** Last night’s Kapsch 3.2.2 broken pipe affected 24 tests. This morning the S0012 read and M0001 dark-mode operation both completed on that pair. Cartesio’s separate outage-replay assertion at line 100 passed again on 3.1.5 and 3.2.1, and its 3.1.4 S0207 job checked the returned occupancy values. [Kapsch before][kap-pipe] · [Kapsch after][kap322] · [Cartesio 3.1.5][ca315] · [3.2.1][ca321] · [3.1.4][ca314]
- **Swarco ITC-3.** The previous seven runs had no compliance JSON. In a prior 3.1.2 / 1.0.9 job the validator aborted after 120 seconds waiting for the site, with zero assertions. This morning 64 pairs supplied passing reports. At cutoff, Core 3.2.2 / TLC 1.0.13 was in `Run tests`. The five jobs for 1.0.14, 1.0.15, 1.1.0, 1.2.0 and 1.2.1 were queued. GitHub returned HTTP 404 for all six unfinished job logs. Their conformance remains unknown. [Previous job][sw-prev] · [Current matrix][sw]
- **Retries and device logs.** The baseline uses the latest attempt per matrix job. For example, Cartesio 3.1.2 failed attempt 5 and passed attempt 6 on the November 17 scheduled night. The hardware workflows expose the validator’s end of the exchange. Independent controller and supervisor logs were unavailable. [Failed attempt][retry-fail] · [Passing retry][retry-pass]

[gt]: https://github.com/rsmp-nordic/rsmp_validator/actions/runs/45323992714
[gs]: https://github.com/rsmp-nordic/rsmp_validator/actions/runs/45324022815
[sw]: https://github.com/rsmp-nordic/rsmp_validator/actions/runs/45324022683
[tm]: https://github.com/rsmp-nordic/rsmp_validator/actions/runs/45334910200
[ca]: https://github.com/rsmp-nordic/rsmp_validator/actions/runs/45334714193
[ka]: https://github.com/rsmp-nordic/rsmp_validator/actions/runs/45335554674
[rs4]: https://github.com/rsmp-nordic/rsmp_validator/actions/runs/45335060617
[rs5]: https://github.com/rsmp-nordic/rsmp_validator/actions/runs/45335197178
[lm]: https://github.com/rsmp-nordic/rsmp_validator/actions/runs/45335829328
[workflows]: https://github.com/rsmp-nordic/rsmp_validator/tree/3b91046cba295c5f2beca754719c05dae48e3a98/.github/workflows
[kap-job]: https://github.com/rsmp-nordic/rsmp_validator/actions/runs/45335554674/job/138246668231
[kap-prev]: https://github.com/rsmp-nordic/rsmp_validator/actions/runs/45099720597/job/137447512867
[gt-peer]: https://github.com/rsmp-nordic/rsmp_validator/actions/runs/45323992714/job/138209037822
[priority-test]: https://github.com/rsmp-nordic/rsmp_validator/blob/3b91046cba295c5f2beca754719c05dae48e3a98/test/site/tlc/signal_priority_spec.rb#L63-L137
[kap-config]: https://github.com/rsmp-nordic/rsmp_validator/blob/3b91046cba295c5f2beca754719c05dae48e3a98/config/sites/kapsch_etx.yaml#L20-L38
[states]: https://github.com/rsmp-nordic/rsmp_sxl_traffic_lights/blob/v1.2.1/source/sxl_traffic_light_controller.rst#L1518-L1554
[tm-prev]: https://github.com/rsmp-nordic/rsmp_validator/actions/runs/45098023994
[tm-watch]: https://github.com/rsmp-nordic/rsmp_validator/actions/runs/45334910200/job/138244610143
[gs-watch]: https://github.com/rsmp-nordic/rsmp_validator/actions/runs/45324022815/job/138209130832
[sequence]: https://github.com/rsmp-nordic/rsmp_validator/blob/3b91046cba295c5f2beca754719c05dae48e3a98/test/supervisor/connect_spec.rb#L34-L65
[order]: https://github.com/rsmp-nordic/rsmp_core/blob/v3.1.2/sphinx/source/applicability/transport_of_data.rst#L16-L36
[tm110]: https://github.com/rsmp-nordic/rsmp_validator/actions/runs/45334910200/job/138244609853
[tm120]: https://github.com/rsmp-nordic/rsmp_validator/actions/runs/45334910200/job/138244610041
[tm121]: https://github.com/rsmp-nordic/rsmp_validator/actions/runs/45334910200/job/138244609925
[tm-matrix]: https://github.com/rsmp-nordic/rsmp_validator/blob/3b91046cba295c5f2beca754719c05dae48e3a98/.github/workflows/tecsen_tmacs_full.yaml#L17-L28
[array]: https://github.com/rsmp-nordic/rsmp_sxl_traffic_lights/blob/v1.1/source/sxl_traffic_light_controller.rst#L1499-L1561
[priority]: https://github.com/rsmp-nordic/rsmp_validator/blob/3b91046cba295c5f2beca754719c05dae48e3a98/test/site/tlc/signal_priority_spec.rb#L4-L22
[setup]: https://github.com/rsmp-nordic/rsmp_validator/actions/runs/45334910200/job/138244613828
[setup-prev]: https://github.com/rsmp-nordic/rsmp_validator/actions/runs/45098023994/job/137442122527
[ca321]: https://github.com/rsmp-nordic/rsmp_validator/actions/runs/45334714193/job/138243960284
[ca-prev321]: https://github.com/rsmp-nordic/rsmp_validator/actions/runs/45097779896/job/137441339992
[occupancy]: https://github.com/rsmp-nordic/rsmp_validator/blob/3b91046cba295c5f2beca754719c05dae48e3a98/test/site/tlc/traffic_data_spec.rb#L81-L104
[wait]: https://github.com/rsmp-nordic/rsmp_validator/blob/3b91046cba295c5f2beca754719c05dae48e3a98/lib/rsmp/validator/helpers/status.rb#L6-L17
[ca-config]: https://github.com/rsmp-nordic/rsmp_validator/blob/3b91046cba295c5f2beca754719c05dae48e3a98/config/sites/semaforica_cartesio.yaml#L22-L30
[initial]: https://github.com/rsmp-nordic/rsmp_core/blob/v3.2.1/source/applicability/basic_structure.rst#L1064-L1074
[buffer]: https://github.com/rsmp-nordic/rsmp_validator/blob/3b91046cba295c5f2beca754719c05dae48e3a98/test/site/core/message_buffer_spec.rb#L15-L32
[buffer-assert]: https://github.com/rsmp-nordic/rsmp_validator/blob/3b91046cba295c5f2beca754719c05dae48e3a98/test/site/core/message_buffer_spec.rb#L114-L125
[buffer-rule]: https://github.com/rsmp-nordic/rsmp_core/blob/v3.2.1/source/applicability/transport_of_data.rst#L258-L267
[ca-gap]: https://github.com/rsmp-nordic/rsmp_validator/actions/runs/44972733023/job/137055825263
[rs4-job]: https://github.com/rsmp-nordic/rsmp_validator/actions/runs/45335060617/job/138245085123
[rs4-prev]: https://github.com/rsmp-nordic/rsmp_validator/actions/runs/45098162790
[rs5-job]: https://github.com/rsmp-nordic/rsmp_validator/actions/runs/45335197178/job/138245526293
[rs5-prev]: https://github.com/rsmp-nordic/rsmp_validator/actions/runs/45098450861
[kap-pipe]: https://github.com/rsmp-nordic/rsmp_validator/actions/runs/45099720597/job/137447512550
[kap322]: https://github.com/rsmp-nordic/rsmp_validator/actions/runs/45335554674/job/138246668283
[ca315]: https://github.com/rsmp-nordic/rsmp_validator/actions/runs/45334714193/job/138243960233
[ca314]: https://github.com/rsmp-nordic/rsmp_validator/actions/runs/45334714193/job/138243960033
[sw-prev]: https://github.com/rsmp-nordic/rsmp_validator/actions/runs/45085693865/job/137403671457
[retry-fail]: https://github.com/rsmp-nordic/rsmp_validator/actions/runs/44228496852/job/134770614758
[retry-pass]: https://github.com/rsmp-nordic/rsmp_validator/actions/runs/44228496852/job/134779140596
