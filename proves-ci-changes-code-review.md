# PROVES Core Reference — CI / Test System Change Review

Repository: [`Open-Source-Space-Foundation/proves-core-reference`](https://github.com/Open-Source-Space-Foundation/proves-core-reference)
Range reviewed: initial commit → `c03b206` (2026-07-27, `main`)
Focus: CI system, GitHub Actions, integration tests, unit tests.

---

## 1. Executive summary

Over roughly one year the project went from *no CI* to a **three-tier hardware-in-the-loop pipeline**: cloud-hosted lint + unit tests, a self-hosted build runner (`deathstar`), and a physical satellite testbed (`integration` runner) that flashes real flight hardware, power-cycles it with a bench supply, and exercises the flight software over **both a wired UART link and a live LoRa RF link**, then again through a full **YAMCS** ground segment.

The dominant engineering theme is not "add tests" — it is **making hardware tests deterministic**. A very large fraction of the CI commits exist to remove a source of nondeterminism: stale USB device names, unsynchronized command sequence numbers, dirty flash filesystems, leaked GDS/Python processes holding a serial port, half-duplex radio collisions, and latent deframer state that survives between jobs.

Headline numbers:

| Metric | Value |
|---|---|
| Commits on `main` | ~200 |
| Commits touching `.github/` | 46 |
| Commits touching test code / `pytest.ini` / `tools/ci` | ~60 |
| CI workflow jobs today | 6 (`lint`, `unit-test`, `build`, `integration-uart`, `integration-radio`, `yamcs-build`) |
| Runner classes | `ubuntu-latest`, `deathstar` (self-hosted build), `integration` (self-hosted HIL) |
| Integration test modules | 19 |
| C++ unit test binaries | 7 |

---

## 2. Timeline of notable changes

### Phase 0 — Bootstrapping (Aug–Oct 2025)

| Commit | PR | Change |
|---|---|---|
| `4ee63e1` | — | **First CI pipeline** (`.github/workflows/ci.yaml`). |
| `9612439` | #7 | Lint job + pre-commit hooks (`make fmt`). |
| `ae67ae3` | #8 | **CodeQL configs added**, including three JPL-standard query packs (`jpl-standard-pack-1/2/3.yaml`) and `security.yaml`. Notable: these are config-only; no CodeQL workflow was ever added to `.github/workflows/`, so the JPL packs appear to be **dormant**. |
| `2acf608`, `50d297e` | #30, #35 | Zephyr manifest pruning and cache work — all `actions/cache` blocks were ultimately **commented out**, not deleted. |

### Phase 1 — Automated hardware-in-the-loop (Oct 2025)

| Commit | PR | Change |
|---|---|---|
| `4bbe9bc` | #33 | **Automated Integration Tests.** Introduced the `integration` job on a self-hosted runner. Adds `test/int/conftest.py` and the pattern of build → upload artifact → download on hardware runner → flash → test. |
| `5994446` | #46 | Bootloader check before flashing. |
| `60da0ec` | #38 | **Major restructure.** Build moves to the self-hosted `deathstar` runner. `make zephyr-setup` is split into `zephyr-workspace` / `zephyr-sdk` / `zephyr-export` / `zephyr-python-deps` so each phase is separately cacheable and separately debuggable. Makefile logic extracted into `lib/makelib/{build-tools,ci,zephyr}.mk`. Test-side reliability: `test/int/common.py` introduces `proves_send_and_assert_command()` with clear-histories + 3× retry, which becomes the **standard command primitive for every integration test thereafter**. |

> **Design note worth calling out for the poster:** `proves_send_and_assert_command` is the single most load-bearing abstraction in the test suite. It concedes up front that a command to real hardware over a real link is *probabilistic*, and encodes retry/clear-history semantics once rather than in 19 test modules.

### Phase 2 — Test breadth grows with the flight software (Nov–Dec 2025)

Integration tests were added essentially one-per-component as components landed: `imu_manager_test`, `rtc_test`, `watchdog_test`, `burnwire_test`, `antenna_deployer_test`, `power_monitor_test`, `load_switch_test`, `mode_manager_test` / `safe_mode_test`, `filesystem_test`, `drv2605/tmp112/veml6031` (face sensors), `camera_handler_test`, `reset_manager_test`.

Also in this phase:

- `7973ee0` (#213) **"Day in the Life"** tests — long-form scenario tests (`test_day_in_the_life.py`, `test_edge_cases_day_in_the_life.py`) distinct from per-component tests.
- `934a6d0` (#268), `0fed8f3` (#296), `0d775fe` (#298) — **stress / power-loss resilience tests** (`test/long/`, `manual_stress_test.py`). #298 explicitly moves to a *fire-and-forget* pattern because the test yanks power mid-write and cannot rely on an ack.
- `20064be` (#178) — watchdog tests that assert **boot counts**, i.e. verifying the reset actually happened rather than just that a command was accepted.
- `0219a55` (#217) — `make sync-sequence-number`, the beginning of a long-running theme.
- `4a68d97` (#218) — CI reworked for the authentication router; commands now require a matching sequence number, which is why sequence sync became a hard CI prerequisite.
- `b4aa988` (#199) — CI switched to flashing `bootable.uf2`.
- `86bcc55` (#264) — **image signing** added to CI; `88e0b0c` (#260) temporarily commented CI steps out around this work.

### Phase 3 — Unit tests appear (Dec 2025)

| Commit | PR | Change |
|---|---|---|
| `8bdf457` | #237 | **First `unit-test` job.** Adds `tests/` with GoogleTest (vendored via `lib/fprime/googletest`), `make test-unit` = `cmake -S tests -B build-gtest && ctest`. First test: `test_rtc_helper.cpp` (subsecond monotonicity). |
| `dc9ced5` | #79 | Detumble unit tests: `BDot`, `Magnetorquer`, `StrategySelector`. |

The unit-test strategy is deliberate and worth noting: rather than unit-testing F Prime components (which need the framework and a target), the team **extracts pure algorithmic logic into standalone helper classes** (`BDot.cpp`, `Magnetorquer.cpp`, `StrategySelector.cpp`, `RtcHelper.cpp`, `Parser.cpp`, `Validator.cpp`, `Authenticator.cpp`, `Bypasser.cpp`) that compile natively on `ubuntu-latest` with no Zephyr in the loop. This is what keeps the fast tier fast.

### Phase 4 — Consolidation and hygiene (Feb 2026)

| Commit | PR | Change |
|---|---|---|
| `bdf76ef` → `d418f81` | #320, #330 | Interactive test runner (`run_interactive_tests.py`) added for debugging intermittent failures; the CI-side key-copy hack was reverted a few days later. Good example of debug tooling landing then being pruned from CI. |
| `293a04b` | #331 | Repo-wide rename `FprimeZephyrReference` → `PROVESFlightControllerReference`; touches every test path. **Breaks naive `git log` path history** — analysis must account for this rename. |
| `bdbb906` | #321 | **"Fix integration tests"** — the integration job is *un-commented* and restored, GDS is now started explicitly (`nohup make gds-integration &` + `server.pid`) with an `if: always()` kill step. Unit tests relocated `tests/` → `PROVESFlightControllerReference/test/unit-tests/`, and the CMakeLists switches to **auto-discovery** (`file(GLOB test_*.cpp)`), so adding a test file no longer requires editing build config. |
| `0313eba` | #337 | **CI uses a non-default Spacecraft ID (67).** `make make-ci-spacecraft-id` runs before `make generate`, so CI traffic can never be confused with a real/default-ID spacecraft. Small change, real operational-safety value. |
| `b570059` | #312 | Signing keys auto-copied when absent. |
| `5f2ffde` | #301 | **Second workflow**: `deploy-docs.yml` — MkDocs + Material → GitHub Pages, with `concurrency: pages`, OIDC `id-token: write`, and no `cancel-in-progress`. |

### Phase 5 — The hardware gets serious (Mar–May 2026)

| Commit | PR | Change |
|---|---|---|
| `1721d15` | #359 | Export artifacts needed for **OpenOCD** flashing (moving away from `picotool`/UF2 drag-drop). |
| `cbb974e` | #390 | **Format the flash filesystem at the end of every integration run** (`if: always()`), and unconditionally power-cycle via the Korad bench supply (the `KORAD_CONTROL` env guard was removed). Also merges GDS-kill and power-off into one teardown step. |
| `92f7f21` | #385 | **V5e board becomes the dev default.** CI can no longer trust the `/dev/ttyBOARD` udev symlink, so the workflow gains **USB VID:PID-based TTY auto-detection** (`0028:000f`) walking `/sys/bus/usb/devices/`. A second heuristic finds the *ground-side* LoRa passthrough board (a repurposed v5d) by preferring CDC interfaces named `cdc2`/`data`, with a documented fallback. |
| `87824f9` | #377 | **YAMCS integration test in CI.** Adds `test/yamcs/{conftest.py,test_yamcs_noop.py}`, `tools/ci/restore-yamcs-mdb.sh`, and a `proves_adapter.py` rework. The test issues `CMD_NO_OP` through the YAMCS command processor and asserts a `NoOpReceived` event returns via the `fprime-yamcs-events` bridge — a genuine **end-to-end TC + TM + events** assertion, not a link check. |
| `15c6b80` | #389 | Docs workflow actions bumped to node24-compatible majors. |

### Phase 6 — Radio-in-the-loop (May 2026) — `d3df5c5` / PR #391

This is the single most significant CI commit in the repository. It splits `integration` into **`integration-uart`** and **`integration-radio`**, and adds the machinery to make RF testing survivable.

**Workflow changes**
- New **composite action** `.github/actions/flash-firmware/action.yml` — power-cycle → OpenOCD flash `mcuboot.elf` → OpenOCD flash `bootable.signed.hex` → power-cycle. De-duplicates flashing across both integration jobs.
- Radio job bootstraps over UART first (sequence-number sync + filesystem format), power-cycles, syncs again against the **LoRa deframer instance** (`--sync-deframer=lora`), then runs the suite entirely over RF.
- Telemetry sample CSVs (`tlm_sample_*.csv`) uploaded as artifacts.

**Test-framework changes (`test/int/conftest.py`, `common.py`, `pytest.ini`)**
- `--with-radio` and `--command-retries` pytest options. Retry budget auto-raises 3 → 5 on radio.
- **Fibonacci backoff with ±50% jitter** (`FIB_BACKOFF = [1,1,2,3,5,8,13]`) between retries, explicitly because **LoRa is half-duplex** — the satellite cannot hear an uplink while transmitting downlink, so unjittered retries collide with the same downlink burst repeatedly.
- **Link recovery callback**: after `RADIO_RECOVER_THRESHOLD = 3` consecutive failures, re-send `lora.TRANSMIT ENABLED` before continuing to retry.
- `RADIO_STABILIZE_S = 15` — wait for the boot-time event backlog to flush after first enabling TRANSMIT, then `clear_histories()`, so command-ack events aren't lost in the flood.
- Ordering hack via `pytest_collection_modifyitems`: on radio runs, **RTC tests are forced to the end** because they set the clock −12 h and the alphabetically-next module (TMP112) raced with the teardown.
- `recover_from_safe_mode` autouse fixture: after each radio test, query `GET_CURRENT_MODE` and issue `EXIT_SAFE_MODE` if the FSW slipped into safe mode (brownout from burnwire tests, partial file upload). Prevents one failing test from poisoning the rest of the run.
- Background **`tlm_sampler`** thread logging every telemetry update to CSV, so link degradation can be correlated against `cmdDisp.CommandsDispatched/Dropped`, `lora.BytesSent/LastRssi`, comQueue depth.
- `pytest.ini` markers reworked from `slow`/`flaky` to semantically meaningful ones: `uart_only`, `sync_sequence_number`, `format_filesystem`.
- Sequence-number sync and filesystem format converted from standalone scripts into **marked pytest tests** (`sync_sequence_number_test.py`, `format_filesystem_test.py`) selected via `make test-integration FILTER=...`.
- Adds `.claude/skills/debug-ci.md` — an AI-agent runbook for debugging this CI.

### Phase 7 — Stabilization (Jun–Jul 2026)

| Commit | PR | Change |
|---|---|---|
| `638f8e2` | #412 | **Radio job no longer depends on the UART job**; the aggregate `integration` gate job is deleted. Jobs now fail independently rather than the radio suite being blocked by a flaky UART run. |
| `8726bfe` | #433 | Two things of note. (a) **Hardware-capability markers** added to `pytest.ini`: `requires_face`, `requires_antenna`, `requires_battery`, `requires_watchdog_jumper` — the suite is now self-documenting about what physical hardware a given test needs, and runnable on a bare flight controller. (b) New build gate `make check-console-disabled` (`scripts/check_console_disabled.py`): the Zephyr console shares `cdc_acm_uart0` with the F′ downlink, so re-enabling it interleaves console text with CCSDS TM frames and desyncs the GDS deframer. CI now **fails the build** rather than discovering this at integration time. |
| `e5e0a1c` | #441 | Self-hosted runner hygiene: explicit `git clean -dfX` / `git reset --hard` on the repo **and recursively on all submodules** before building. Addresses state leaking between jobs on a persistent runner. |
| `65f8cb4` | #446 | **Format the filesystem *before* tests, not just after** — a run that crashed hard could leave the flash dirty and poison the next run. Also extracts the duplicated TTY-detection shell into `tools/ci/detect-board-tty.sh` (it had been copy-pasted into two jobs). |
| `1af2a0c`, `b2437a9` | #395, #447 | `Authenticate` → **`TcSecurityDeframer`** refactor. Adds four new unit test binaries (`Parser`, `Validator`, `Authenticator`, `ProvesRouter_Bypasser`) and makes the `unit-test` job install `libmbedtls-dev` for PSA crypto. Also **moves `${{ secrets.AUTH_KEY }}` out of inline `run:` interpolation into a step `env:` var** — a real secret-handling improvement (avoids the secret landing in the rendered shell script). |
| `606eb0a`, `3d761fc` | #421, #398 | Zephyr 4.4.1 and F Prime v4.2.2 upgrades; both required CI adjustments and small helper scripts (`tools/patch-zephyr-sdk-toolchain-download.py`, `tools/apply-yamcs-constants-order-fix.py`). |
| `24968fa` | #414 | **Regression test** for a repeated-`CONTINUOUS_WAVE`-call radio bug (original issue #207) — a bug fix that landed with a permanent HIL test. |
| `c222dd8` | #452 | Pre-commit hook keeping component docs in sync. |
| `e13330c` | #413 | `fprime-yamcs` → 0.1.3, `fprime-xtce` → 0.1.2. |

---

## 3. Current pipeline shape (`main`, `c03b206`)

```
                        ┌───────────────┐
  push / PR ────────────┤ lint          │ ubuntu-latest, make fmt
                        ├───────────────┤
                        │ unit-test     │ ubuntu-latest, GoogleTest + ctest (7 binaries)
                        ├───────────────┤
                        │ build         │ self-hosted "deathstar"
                        │               │  zephyr workspace/sdk/export/deps
                        │               │  make-ci-spacecraft-id (SCID 67)
                        │               │  generate → auth key → mcuboot → build
                        │               │  check-console-disabled  ← build gate
                        │               │  upload artifacts (elf, uf2, signed.hex, dict, xtce)
                        └───────┬───────┘
                 ┌──────────────┼──────────────┐
                 ▼              ▼              ▼
    ┌────────────────────┐ ┌──────────────┐ ┌────────────────┐
    │ integration-uart   │ │ integration- │ │ yamcs-build    │
    │ self-hosted HIL    │ │ radio        │ │ ubuntu-latest  │
    │                    │ │ self-hosted  │ │ docker compose │
    │ flash → sync seq   │ │ HIL          │ │ MDB boot check │
    │ → format fs        │ │ UART boot-   │ └────────────────┘
    │ → power cycle      │ │ strap → RF   │
    │ → sync → UART      │ │ suite        │
    │   suite → format   │ │ → format fs  │
    │ → power cycle      │ └──────────────┘
    │ → YAMCS stack      │
    │ → NO_OP round-trip │
    └────────────────────┘
```

`integration-uart` is now a **two-phase job**: after the GDS/UART suite it tears everything down, power-cycles, and re-runs the same board through a real **YAMCS** ground segment (Java 17 + docker, `setsid` process-group management, HTTP-API readiness gate, events-bridge subscription gate, and rich `if: failure()` diagnostics dumping YAMCS packets/parameters/links/events).

---

## 4. Notable engineering patterns

**Physical state is treated as a test fixture.** Power cycling via a Korad bench supply is a first-class CI step, appearing 5× in the current workflow with documented rationale (clearing a partially-consumed TC frame in the FrameAccumulator, ensuring power-monitor tests see a clean rail, re-enumerating `/dev/ttyBOARD`).

**Every nondeterminism fix is documented inline.** The workflow YAML is unusually heavily commented — the `Power-Cycle Satellite Before YAMCS` step carries a five-line explanation of the latent-deframer-state failure mode it exists to prevent. This is good practice for HIL CI where "why is this sleep here" is otherwise unanswerable six months later.

**Escalating isolation guarantees.** The progression is legible: kill GDS → `pkill -9 python` → `fuser -k /dev/ttyBOARD` → `lsof` before/after logging → `setsid` process groups → `git clean` on repo and submodules. Each step was added after a specific cross-job leak.

**Fast tier stays genuinely fast** by refactoring testable logic out of F Prime components into free-standing helpers, and by auto-globbing test sources so the barrier to adding a unit test is one file.

**Markers as a hardware contract.** `requires_face` / `requires_antenna` / `requires_battery` / `requires_watchdog_jumper` turn implicit testbed assumptions into machine-readable selectors — the same suite runs on the full CI cube or a bare board.

---

## 5. Observations / potential gaps

1. **CodeQL is configured but never run.** `.github/codeql/jpl-standard-pack-{1,2,3}.yaml` and `security.yaml` have existed since Aug 2025 (`ae67ae3`) with no workflow invoking them. Either wire up a `codeql-analysis.yml` or drop the configs.
2. **Caching is dead code.** Every `actions/cache` block was commented out in Oct 2025 and never removed, yet `if: steps.cache-bin.outputs.cache-hit != 'true'` guards remain on live steps — these conditions always evaluate truthy against a nonexistent step. Harmless but misleading; the guards should be deleted with the cache blocks or the caches restored.
3. **Action version drift within one file.** `ci.yaml` currently mixes `actions/download-artifact@v6` (integration jobs) and `@v8` (yamcs-build), and `upload-artifact@v4` throughout. Worth normalizing.
4. **`make fmt` as the lint gate** mutates the tree rather than checking it; the job passes as long as the formatter runs. A `--check` mode would actually gate formatting.
5. **UART bootstrap for the radio job is acknowledged tech debt** — commented in-workflow and tracked as issue #400 ("make radio bootstrap commands auth-exempt so this UART pre-step can go away"). Today `integration-radio` still cannot start from a cold board over RF alone.
6. **No timeouts on integration jobs.** Given `sleep`-heavy steps and 180 s readiness polls, a hung board can occupy the single physical testbed indefinitely. `timeout-minutes` on the HIL jobs would bound that.
7. **Single testbed, no concurrency control.** There is no `concurrency:` group on `ci.yaml`, so two PRs merging near-simultaneously could contend for the same physical satellite. (`deploy-docs.yml` does use a concurrency group.)
8. **Broad `pkill -9 python`** on a shared self-hosted runner will kill any unrelated Python process, including another workflow's. Scoping to the process group (as the YAMCS teardown already does via `setsid`) would be safer.

---

## 6. Source-material highlights for the poster

- Three-tier structure: **cloud lint/unit (seconds) → self-hosted build (minutes) → HIL on flight hardware (tens of minutes)**.
- The pipeline tests **the same binary over two physically different links** (USB CDC-ACM and LoRa RF) and through **two ground systems** (F Prime GDS and YAMCS).
- Concrete determinism techniques, all citable: VID:PID device detection, sequence-number synchronization, filesystem format before *and* after, bench-supply power cycling as a test step, Fibonacci+jitter backoff for half-duplex RF, autouse safe-mode recovery, telemetry sampling to CSV for post-hoc link forensics.
- Build-time gate catching an integration-level failure mode (`check-console-disabled`) — an example of pushing a HIL failure left into the fast tier.
- Hardware-capability pytest markers as a portable testbed contract.
