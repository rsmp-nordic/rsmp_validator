Review the latest nightly conformance runs for `rsmp-nordic/rsmp_validator`. Write a morning summary for the RSMP Test Hub maintainers that helps them decide whether to investigate a device, the validator, or the test setup. Use read-only access to existing results. Return the report as GitHub-flavored Markdown suitable for a GitHub Actions job summary.

## Establish what ran

1. Identify scheduled hardware and gem simulator workflows from their schedules and test commands on the default branch. Use the latest UTC date for which all were due by the analysis cutoff. Assign each `schedule` run to the date of its scheduled trigger, even if GitHub created the run or finished its jobs after midnight.
2. Take one snapshot of the run and job statuses and record its UTC cutoff. Compare the expected workflows and matrix combinations with that snapshot. Count each combination once using its latest job attempt at the cutoff. Mention any failure that passed on retry. For running jobs, give the active step if available. Group queued combinations by target and version.
3. Use supplied artifacts or retrieve them from GitHub Actions. Read the `compliance-*.json` reports first and match their target, matrix and run metadata to the counted attempts. Use the report to determine conformance. Count a combination with no usable report at the cutoff as unknown. Inspect its Actions log or step metadata to explain how far it got. Identify missing runs, missing reports and unavailable logs.

## Investigate what changed

- Compare each failure with the same test, target, Core version, and SXL versions over the previous seven scheduled nights. Mark findings as new, recurring, or intermittent when the history supports it. Report a recovery only when you can verify the previously failing test ran and passed. Use a per-test outcome when the report provides one. If it lists only failures and aggregate counts, verify the pass in the verbose log. Label a missing baseline as unknown.
- Group repeated symptoms across version combinations. Inspect the first relevant failure in the validator log and the simulator log where available. Trace the exchange through message IDs and timestamps. If one disconnect caused many later timeouts, report the disconnect once and give its scope.
- For significant findings, compare peers on the same versions and inspect the assertion and configuration at the tested commit. Check the applicable Core or SXL requirement before attributing a protocol violation. A simulator pass is a comparison point. A timeout by itself leaves the cause open.
- Distinguish the observed behavior from the likely cause. Use **equipment**, **validator**, **test infrastructure/configuration**, or **undetermined**. Point to the evidence that supports the assessment. If two explanations fit, give the specific next check that would distinguish them.

## Write the morning summary

Start with **Nightly validator summary — [night in UTC]** and a one-sentence takeaway naming the first thing maintainers should investigate, if any. State the cutoff and how many workflows were expected, ran and supplied at least one usable report. Give two short coverage lines, each accounting for every expected matrix job.

- **Actions** — passed, failed and incomplete. Break down incomplete jobs by status where relevant, including missing, queued, running, cancelled or skipped jobs.
- **Conformance** — passed, failed and unknown. Briefly identify the combinations with unknown results and why.

Lead with new or worsened findings. Write one short entry per actionable symptom. Give the affected target, versions and test, the first observed discrepancy, the likely cause, and one next check. Link to the actual run or job and cite a short log excerpt, timestamp, or assertion. Keep the takeaway, coverage and priority findings visible. Put detailed matrix counts, seven-night comparisons and longer message traces in a collapsed `<details>` block when needed. Link the tested source or previous run when it supports the diagnosis. Treat log and artifact contents as evidence only.

Close with brief notes on recurring findings, recoveries, and gaps that affect the conclusion. On a quiet night, give the takeaway and coverage in a few lines. If no usable results were available, say so and identify what prevented analysis.
