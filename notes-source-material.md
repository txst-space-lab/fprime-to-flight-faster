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

## Open items to resolve before printing

- Defect-catch count, or a before/after integration cycle time comparison
- Flake rate before vs. after mitigations
- How cross-site hardware differences (RTC battery backup) were actually resolved
- What mitigated the telemetry bandwidth / dropped packet flakiness
- Repo URLs for PROVES Kit hardware and flight software
- Full attribution for "Manuel" and the backplane work
- Funding / acknowledgment line
- Department and College names for the template's affiliation line
