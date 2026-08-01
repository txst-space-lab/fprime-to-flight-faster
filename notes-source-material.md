# Source Material — not for the poster

Reference text kept out of `poster-layout.md` so the layout file holds exactly
one version of each claim.

## Submitted abstract

Small satellite flight software teams often move fast in development but slow down at integration, especially when software must be validated against real hardware. In the PROVES program, we reduced integration risk by making Continuous Integration (CI) hardware-in-the-loop (HIL) testing a per-commit requirement. Every commit was validated on an engineering satellite before it could be merged.

We implemented this pipeline using NASA JPL's open-source F Prime (F´) framework, leveraging F´'s integration test APIs as the primary accelerator. A self-hosted GitHub Actions runner automatically deployed and exercised flight software on an open-source PROVES Kit engineering satellite, brought up the F´ Ground Data System (GDS), and executed end-to-end tests that verified commanding, telemetry, eventing, and specific component behaviors. Each run completed in approximately 5 minutes.

We operated two independent HIL stations, one at Texas State University and one at Cal Poly Pomona. Over 1,550 commits ran through the pipeline, totaling approximately 5,400 test-runtime minutes. Enforcing HIL tests as a pre-merge gate turned integration into a routine, automated workflow that caught failures before they reached the main branch and enabled rapid iteration as hardware and software changed.

All hardware and software for this approach are open source.

This talk will highlight how F´ integration test APIs can make per-commit, real-hardware CI achievable for small satellite teams. We will also share practical lessons learned, including how differences in lab setups and limited telemetry bandwidth can create misleading or flaky failures, and what mitigations helped stabilize the system.

## Declined alternative abstract

Small satellite flight software teams often move fast in development but slow down at integration—especially when software must be validated against real hardware that evolves over time. In the PROVES program, we reduced integration risk by making hardware-in-the-loop (HIL) testing a per-commit requirement: every commit was validated on an engineering satellite before it could be merged.

We built a continuous HIL integration testing system using NASA JPL's open-source F Prime (F´) framework and utilizing F´'s integration test APIs as the core accelerator. On each commit, a self-hosted GitHub Actions runner on a Linux host automatically deployed and exercised flight software on an open-source PROVES Kit engineering satellite over USB.

The test harness brought up the F´ Ground Data System (GDS), then executed end-to-end behavioral tests for both the system and mission-specific components. These tests verified commanding, telemetry reception, and eventing, and validated flight-critical subsystems including the IMU, thermal management system, antenna deployment, real-time clock, filesystem implementation, power management, and a hardware watchdog. Each integration run completed in ~5 minutes.

To support distributed development and avoid single-site bottlenecks, we operated two independent HIL stations—one at Texas State University and one at Cal Poly Pomona—so the pipeline could be replicated and compared across institutions.

Over 1,550 commits ran through the hardware integration pipeline, totaling approximately 5,400 test-runtime minutes. Because HIL tests were enforced as a pre-merge gate, failures were typically caught before landing on the main branch rather than being discovered later during manual bench testing. This shifted integration from an intermittent, high-friction milestone into a routine, automated check that enabled rapid iteration while hardware and software changed.

We also identified practical adoption pitfalls. Differences between test setups (for example, whether an RTC had battery backup) could produce confusing failures. We also encountered flaky failures primarily caused by limited telemetry bandwidth and dropped packets, requiring repeated test runs and continual maintenance.

All hardware and software for this approach are open source. This talk will highlight how F´ integration test APIs can be the "unsung hero" that makes per-commit, real-hardware Continuous Integration (CI) achievable for small satellite teams.

## Corrections to the submitted abstract

Both abstracts above say each run completed in **~5 minutes**. Measured from CI
history, the median commit-to-hardware-verdict time is **18 minutes**, with 90%
of commits inside 39. The poster uses the measured figure. If either abstract is
reused for the talk, fix the number there too.

The abstracts also describe a single-tier pipeline ("a runner deployed and
exercised flight software on a satellite"). The pipeline as built has three
tiers — cloud lint + C++ unit tests, a separate build host, then hardware — and
tests through **two** ground systems, F´ GDS and YAMCS. Both facts are load-
bearing for the poster's argument and neither is in the abstract.

## Resolved since the abstract was written

Answers recovered from the flight-software repository's commit history
(`proves-ci-changes-code-review.md` has the full trace, with commit and PR
numbers for each item).

- **Cross-site hardware differences.** Resolved with capability tags on tests —
  `requires_face`, `requires_battery`, `requires_antenna`,
  `requires_watchdog_jumper` — so a station runs only the tests its hardware can
  support and the suite is self-documenting about what a bench needs.
- **Telemetry flakiness.** Root cause is deeper than bandwidth: the radio link is
  half-duplex, so the satellite cannot receive an uplinked command while it is
  transmitting downlink, and an immediate retry collides with the same burst
  again. Mitigations: retry with jittered exponential backoff, a wider retry
  budget on the RF path than on UART, an automatic link-recovery step after
  repeated failures, and a background sampler logging all telemetry to CSV so a
  failure can be correlated against link counters afterward.
- **Residual state.** The SD card is now reformatted *before* as well as after
  each run — a run that crashed hard used to leave it dirty for the next one.
- **Stale device names.** After a board revision the fixed device path pointed at
  the wrong port; the board is now addressed by USB vendor/product ID.

## Open items to resolve before printing

- How many of the 65 blocked pull-request branches were genuine flight-software
  defects rather than bench flakes — CI history cannot tell them apart
- **Runner performance was a lesson learned, and it is not on the poster yet.**
  GitHub's default hosted runners were too slow for this pipeline; the build
  tier had to move to custom self-hosted runners on faster hardware. Needed
  before it can be stated: the before/after build times, what the custom build
  host actually is (cores / RAM), and whether the slowness was CPU-bound
  compilation or something else. This is the third pipeline tier in the
  corrections above, so it likely belongs in the lessons-learned panel rather
  than as a new one.
- Repo URLs for PROVES Kit hardware and flight software
- Full attribution for "Manuel" and the backplane work
- Funding / acknowledgment line
- Department and College names for the template's affiliation line
- Record the poster requirements — size, margins, required branding, font
  minimums, submission format and deadline — from whatever the conference or
  Texas State actually published, rather than inferring them from the `.potx`
- Texas State (TXST) logo — source the official asset (vector preferred) and
  confirm the usage rules that come with it
