---
layout: page
title: exchanges correct connection sequence of rsmp version 3.1.3
parent: Connection Sequence
---

# Connection Sequence exchanges correct connection sequence of rsmp version 3.1.3

Verify the connection sequence when using rsmp core 3.1.3

1. Given the site is connected and using core 3.1.3
2. Send and receive handshake messages
3. Expect the handshake messages to be in the specified sequence corresponding to version 3.1.3
4. Expect the connection sequence to be complete

```ruby
check_sequence '3.1.3'
```

