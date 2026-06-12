---
layout: page
title: Connection Sequence
parmalink: core_connection_sequence
has_children: false
has_toc: false
parent: Core
grand_parent: Site
---

# Connection Sequence
{: .no_toc}

### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Connection Sequence is correct for rsmp version 3.1.1

Verify the connection sequence when using rsmp core 3.1.1

1. Given the site is connected and using core 3.1.1
2. When handshake messages are sent and received
3. Then the handshake messages should be in the specified sequence corresponding to version 3.1.1
4. And the connection sequence should be complete

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'is correct for rsmp version 3.1.1' do
  skip 'requires core == 3.1.1' unless RSMP::Validator.core_matches?('3.1.1')
  check_sequence '3.1.1'
end
```
</details>


## Connection Sequence is correct for rsmp version 3.1.2

Verify the connection sequence when using rsmp core 3.1.2

1. Given the site is connected and using core 3.1.2
2. When handshake messages are sent and received
3. Then the handshake messages should be in the specified sequence corresponding to version 3.1.2
4. And the connection sequence should be complete

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'is correct for rsmp version 3.1.2' do
  skip 'requires core == 3.1.2' unless RSMP::Validator.core_matches?('3.1.2')
  check_sequence '3.1.2'
end
```
</details>


## Connection Sequence is correct for rsmp version 3.1.3

Verify the connection sequence when using rsmp core 3.1.3

1. Given the site is connected and using core 3.1.3
2. When handshake messages are sent and received
3. Then the handshake messages should be in the specified sequence corresponding to version 3.1.3
4. And the connection sequence should be complete

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'is correct for rsmp version 3.1.3' do
  skip 'requires core == 3.1.3' unless RSMP::Validator.core_matches?('3.1.3')
  check_sequence '3.1.3'
end
```
</details>


## Connection Sequence is correct for rsmp version 3.1.4

Verify the connection sequence when using rsmp core 3.1.4

1. Given the site is connected and using core 3.1.4
2. When handshake messages are sent and received
3. Then the handshake messages should be in the specified sequence corresponding to version 3.1.4
4. And the connection sequence should be complete

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'is correct for rsmp version 3.1.4' do
  skip 'requires core == 3.1.4' unless RSMP::Validator.core_matches?('3.1.4')
  check_sequence '3.1.4'
end
```
</details>


## Connection Sequence is correct for rsmp version 3.1.5

Verify the connection sequence when using rsmp core 3.1.5

1. Given the site is connected and using core 3.1.5
2. When handshake messages are sent and received
3. Then the handshake messages should be in the specified sequence corresponding to version 3.1.5
4. And the connection sequence should be complete

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'is correct for rsmp version 3.1.5' do
  skip 'requires core == 3.1.5' unless RSMP::Validator.core_matches?('3.1.5')
  check_sequence '3.1.5'
end
```
</details>


## Connection Sequence is correct for rsmp version 3.2

Verify the connection sequence when using rsmp core 3.2

1. Given the site is connected and using core 3.2
2. When handshake messages are sent and received
3. Then the handshake messages should be in the specified sequence corresponding to version 3.1.5
4. And the connection sequence should be complete

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'is correct for rsmp version 3.2' do
  skip 'requires core == 3.2' unless RSMP::Validator.core_matches?('3.2')
  check_sequence '3.2'
end
```
</details>


## Connection Sequence is correct for rsmp version 3.2.1

Verify the connection sequence when using rsmp core 3.2.1

1. Given the site is connected and using core 3.2.1
2. When handshake messages are sent and received
3. Then the handshake messages should be in the specified sequence corresponding to version 3.1.5
4. And the connection sequence should be complete

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'is correct for rsmp version 3.2.1' do
  skip 'requires core == 3.2.1' unless RSMP::Validator.core_matches?('3.2.1')
  check_sequence '3.2.1'
end
```
</details>


## Connection Sequence is correct for rsmp version 3.2.2

Verify the connection sequence when using rsmp core 3.2.2

1. Given the site is connected and using core 3.2.2
2. When handshake messages are sent and received
3. Then the handshake messages should be in the specified sequence corresponding to version 3.1.5
4. And the connection sequence should be complete

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'is correct for rsmp version 3.2.2' do
  skip 'requires core == 3.2.2' unless RSMP::Validator.core_matches?('3.2.2')
  check_sequence '3.2.2'
end
```
</details>


## Connection Sequence is correct for rsmp version 3.3.0

Verify the connection sequence when using rsmp core 3.3.0

1. Given the site is connected and using core 3.3.0
2. When handshake messages are sent and received
3. Then ComponentList should be exchanged before application traffic
4. And the connection sequence should be complete

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'is correct for rsmp version 3.3.0' do
  skip 'requires core == 3.3.0' unless RSMP::Validator.core_matches?('3.3.0')
  check_sequence '3.3.0'
end
```
</details>
