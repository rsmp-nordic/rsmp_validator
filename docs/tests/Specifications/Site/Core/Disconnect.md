---
layout: page
title: Disconnect
parent: Core
---

# Disconnect

Test how the site responds to various incorrect behaviour.

The site object passed by Validator::Site a SiteProxy object. We can redefine methods
on this object to modify behaviour after the connection has been established.

Note that we use Validator::Site.isolate, rather than Validator::Site.connect,
to ensure we get a fresh SiteProxy object each time, so our deformed site proxy
is not reused later tests

