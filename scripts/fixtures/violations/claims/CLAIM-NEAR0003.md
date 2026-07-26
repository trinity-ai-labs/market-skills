---
id: CLAIM-NEAR0003
type: claim
title: "The window closes when the first enforcement round lands"
status: current
confidence: M
confidence_own: M
created: "2026-03-16"
subject: "Timing_Window"
stale_after: "2099-12-31"
rests_on:
  - FACT-DANG0002
---

Violates: near-miss-subject

Step 3 of the resolution order: normalising both sides to lowercase
alphanumerics collapses `Timing_Window` onto `timing-window`. Case and separator
drift is the most common near-miss and never collides.
