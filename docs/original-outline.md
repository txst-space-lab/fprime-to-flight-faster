# F Prime to Flight Faster: Hardware-in-the-Loop Continuous Integration for Accelerated CubeSat Development

**Nate Gay1**, Saidi Adams1, Michael Pham2  
1Texas State University Space Lab  
2Open Source Space Foundation

**Correspondence:** nategay@txstate.edu

## Abstract

Small satellite flight software teams often move fast in development but slow down at integration, especially when software must be validated against real hardware. In the PROVES program, we reduced integration risk by making Continuous Integration (CI) hardware-in-the-loop (HIL) testing a per-commit requirement. Every commit was validated on an engineering satellite before it could be merged.

We implemented this pipeline using NASA JPL’s open-source F Prime (F´) framework, leveraging F´’s integration test APIs as the primary accelerator. A self-hosted GitHub Actions runner automatically deployed and exercised flight software on an open-source PROVES Kit engineering satellite, brought up the F´ Ground Data System (GDS), and executed end-to-end tests that verified commanding, telemetry, eventing, and specific component behaviors. Each run completed in approximately 5 minutes.

We operated two independent HIL stations, one at Texas State University and one at Cal Poly Pomona. Over 1,550 commits ran through the pipeline, totaling approximately 5,400 test-runtime minutes. Enforcing HIL tests as a pre-merge gate turned integration into a routine, automated workflow that caught failures before they reached the main branch and enabled rapid iteration as hardware and software changed.

All hardware and software for this approach are open source.

This talk will highlight how F´ integration test APIs can make per-commit, real-hardware CI achievable for small satellite teams. We will also share practical lessons learned, including how differences in lab setups and limited telemetry bandwidth can create misleading or flaky failures, and what mitigations helped stabilize the system.

## Visuals

* Graph of passing tests/failing tests over time  
* Picture of current CI cube on standoffs  
* Picture of passing checkmarks in GitHub  
* Maybe: Picture of old “assembled cube” version  
* Maybe: Picture of initial integration test setup with Saidi and Aaron at my house?

## What we learned along the way

Things that made big improvements:

### Software preparation

* Separate build and integration machines

### Environment control

* Debug over SWD/GDB for programming the microcontroller  
  * No longer relying on potentially broken software to reprogram the board  
* Programmable power supply  
  * No longer having hardware watchdog trigger during software loading  
* Reformat SD card on every run to remove deviations from state

### Hardware control

* Switched from fully assembled cube to “skeleton” cube built with standoffs. This made it easier to modify the CI Cube.

### Flight-like conditions

* In addition to original commstack testing over UART, the team added testing over the radio

## Future improvements

### Hardware control

* making the thing flat, right now we kind of "build a cube" which is suboptimal when we need to change out parts  
* not using hand-built wire harnesses for each component so using a backplane like what Manuel is building and what the Oresat team has built.  
* Local bench setup instructions  
* Test categories based on what hardware is available on the machine  
* At one point in time part of our CI machine was unplugged and was inaccessible until a team member could access the lab. Physical access control?

### Software control

* Fully reproducible CI machine setup (build and integration) via nix, bootable images, or ansible playbook

## Additional Resources

### Declined Alternative Abstract

Small satellite flight software teams often move fast in development but slow down at integration—especially when software must be validated against real hardware that evolves over time. In the PROVES program, we reduced integration risk by making hardware-in-the-loop (HIL) testing a per-commit requirement: every commit was validated on an engineering satellite before it could be merged.

We built a continuous HIL integration testing system using NASA JPL’s open-source F Prime (F´) framework and utilizing F´’s integration test APIs as the core accelerator. On each commit, a self-hosted GitHub Actions runner on a Linux host automatically deployed and exercised flight software on an open-source PROVES Kit engineering satellite over USB.

The test harness brought up the F´ Ground Data System (GDS), then executed end-to-end behavioral tests for both the system and mission-specific components. These tests verified commanding, telemetry reception, and eventing, and validated flight-critical subsystems including the IMU, thermal management system, antenna deployment, real-time clock, filesystem implementation, power management, and a hardware watchdog. Each integration run completed in \~5 minutes.

To support distributed development and avoid single-site bottlenecks, we operated two independent HIL stations—one at Texas State University and one at Cal Poly Pomona—so the pipeline could be replicated and compared across institutions.

Over 1,550 commits ran through the hardware integration pipeline, totaling approximately 5,400 test-runtime minutes. Because HIL tests were enforced as a pre-merge gate, failures were typically caught before landing on the main branch rather than being discovered later during manual bench testing. This shifted integration from an intermittent, high-friction milestone into a routine, automated check that enabled rapid iteration while hardware and software changed.

We also identified practical adoption pitfalls. Differences between test setups (for example, whether an RTC had battery backup) could produce confusing failures. We also encountered flaky failures primarily caused by limited telemetry bandwidth and dropped packets, requiring repeated test runs and continual maintenance.

All hardware and software for this approach are open source. This talk will highlight how F´ integration test APIs can be the “unsung hero” that makes per-commit, real-hardware Continuous Integration (CI) achievable for small satellite teams.