---
layout: page
title: is correct for rsmp version 3.1.1
parent: Connection Sequence
---

# Connection Sequence is correct for rsmp version 3.1.1

Verify the connection sequence when using rsmp core 3.1.1

1. Given the site is connected and using core 3.1.1
2. When handshake messages are sent and received
3. Then the handshake messages should be in the specified sequence corresponding to version 3.1.1
4. And the connection sequence should be complete

```ruby
check_sequence '3.1.1'
```

