---
layout: page
title: Supervisor
parmalink: supervisor
has_children: true
has_toc: false
parent: Test Suite
---

# Supervisor
{: .no_toc}

Tests for RSMP supervisors.
Supervisor testing is still preliminary, and only a small set of tests are available,
covering just the core specification. No tests are available for specific equipment types, e.g.
Traffic Light Controllers.

When testing a supervisor the validator will run a local RSMP site. Because commands and status requests
are initiated by the supervisor, only a limited set of tests can be automated by the validator.

### Categories
{: .no_toc .text-delta }
- [Aggregated Status]({{ site.baseurl}}{% link tests/Specifications/Supervisor/Aggregated_20Status.md %})
- [Connection Sequence]({{ site.baseurl}}{% link tests/Specifications/Supervisor/Connection_20Sequence.md %})

