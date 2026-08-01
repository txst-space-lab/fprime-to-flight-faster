Small satellite flight software teams often move fast in development but slow down at integration, especially when software must be validated against real hardware. In the PROVES program, we reduced integration risk by making Continuous Integration (CI) hardware-in-the-loop (HIL) testing a per-commit requirement. Every commit was validated on an engineering satellite before it could be merged.

We implemented this pipeline using NASA JPL's open-source F Prime (F´) framework, leveraging F´'s integration test APIs as the primary accelerator. A self-hosted GitHub Actions runner automatically deployed and exercised flight software on an open-source PROVES Kit engineering satellite, brought up the F´ Ground Data System (GDS), and executed end-to-end tests that verified commanding, telemetry, eventing, and specific component behaviors. Each run completed in approximately 5 minutes.

We operated two independent HIL runners, one at Texas State University and one at Cal Poly Pomona. Over 1,550 commits ran through the pipeline, totaling approximately 5,400 test-runtime minutes. Enforcing HIL tests as a pre-merge gate turned integration into a routine, automated workflow that caught failures before they reached the main branch and enabled rapid iteration as hardware and software changed.

All hardware and software for this approach are open source.

This talk will highlight how F´ integration test APIs can make per-commit, real-hardware CI achievable for small satellite teams. We will also share practical lessons learned, including how differences in lab setups and limited telemetry bandwidth can create misleading or flaky failures, and what mitigations helped stabilize the system.
