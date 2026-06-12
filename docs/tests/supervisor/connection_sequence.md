---
layout: page
title: Connection Sequence
parmalink: connection_sequence
has_children: false
has_toc: false
parent: Supervisor
grand_parent: Test Suite
---

# Connection Sequence
{: .no_toc}

### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Connection Sequence exchanges correct connection sequence of rsmp version 3.1.1

Verify the connection sequence when using rsmp core 3.1.1

1. Given the site is connected and using core 3.1.1
2. Send and receive handshake messages
3. Expect the handshake messages to be in the specified sequence corresponding to version 3.1.1
4. Expect the connection sequence to be complete

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'exchanges correct connection sequence of rsmp version 3.1.1' do
  skip 'requires core == 3.1.1' unless RSMP::Validator.core_matches?('3.1.1')
  check_sequence '3.1.1'
end
```
</details>


## Connection Sequence exchanges correct connection sequence of rsmp version 3.1.2

Verify the connection sequence when using rsmp core 3.1.2

1. Given the site is connected and using core 3.1.2
2. Send and receive handshake messages
3. Expect the handshake messages to be in the specified sequence corresponding to version 3.1.2
4. Expect the connection sequence to be complete

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'exchanges correct connection sequence of rsmp version 3.1.2' do
  skip 'requires core == 3.1.2' unless RSMP::Validator.core_matches?('3.1.2')
  check_sequence '3.1.2'
end
```
</details>


## Connection Sequence exchanges correct connection sequence of rsmp version 3.1.3

Verify the connection sequence when using rsmp core 3.1.3

1. Given the site is connected and using core 3.1.3
2. Send and receive handshake messages
3. Expect the handshake messages to be in the specified sequence corresponding to version 3.1.3
4. Expect the connection sequence to be complete

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'exchanges correct connection sequence of rsmp version 3.1.3' do
  skip 'requires core == 3.1.3' unless RSMP::Validator.core_matches?('3.1.3')
  check_sequence '3.1.3'
end
```
</details>


## Connection Sequence exchanges correct connection sequence of rsmp version 3.1.4

Verify the connection sequence when using rsmp core 3.1.4

1. Given the site is connected and using core 3.1.4
2. Send and receive handshake messages
3. Expect the handshake messages to be in the specified sequence corresponding to version 3.1.4
4. Expect the connection sequence to be complete

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'exchanges correct connection sequence of rsmp version 3.1.4' do
  skip 'requires core == 3.1.4' unless RSMP::Validator.core_matches?('3.1.4')
  check_sequence '3.1.4'
end
```
</details>


## Connection Sequence exchanges correct connection sequence of rsmp version 3.1.5

Verify the connection sequence when using rsmp core 3.1.5

1. Given the site is connected and using core 3.1.5
2. Send and receive handshake messages
3. Expect the handshake messages to be in the specified sequence corresponding to version 3.1.5
4. Expect the connection sequence to be complete

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'exchanges correct connection sequence of rsmp version 3.1.5' do
  skip 'requires core == 3.1.5' unless RSMP::Validator.core_matches?('3.1.5')
  check_sequence '3.1.5'
end
```
</details>


## Connection Sequence exchanges correct connection sequence of rsmp version 3.2

Verify the connection sequence when using rsmp core 3.2

1. Given the site is connected and using core 3.2
2. Send and receive handshake messages
3. Expect the handshake messages to be in the specified sequence corresponding to version 3.1.5
4. Expect the connection sequence to be complete

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'exchanges correct connection sequence of rsmp version 3.2' do
  skip 'requires core == 3.2' unless RSMP::Validator.core_matches?('3.2')
  check_sequence '3.2'
end
```
</details>


## Connection Sequence exchanges correct connection sequence of rsmp version 3.2.1

Verify the connection sequence when using rsmp core 3.2.1

1. Given the site is connected and using core 3.2.1
2. Send and receive handshake messages
3. Expect the handshake messages to be in the specified sequence corresponding to version 3.1.5
4. Expect the connection sequence to be complete

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'exchanges correct connection sequence of rsmp version 3.2.1' do
  skip 'requires core == 3.2.1' unless RSMP::Validator.core_matches?('3.2.1')
  check_sequence '3.2.1'
end
```
</details>


## Connection Sequence exchanges correct connection sequence of rsmp version 3.2.2

Verify the connection sequence when using rsmp core 3.2.2

1. Given the site is connected and using core 3.2.2
2. Send and receive handshake messages
3. Expect the handshake messages to be in the specified sequence corresponding to version 3.1.5
4. Expect the connection sequence to be complete

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'exchanges correct connection sequence of rsmp version 3.2.2' do
  skip 'requires core == 3.2.2' unless RSMP::Validator.core_matches?('3.2.2')
  check_sequence '3.2.2'
end
```
</details>


## Connection Sequence exchanges correct connection sequence of rsmp version 3.3.0

Verify the connection sequence when using rsmp core 3.3.0

1. Given the site is connected and using core 3.3.0
2. Send and receive handshake messages
3. Expect the ComponentList before application traffic
4. Expect the connection sequence to be complete

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'exchanges correct connection sequence of rsmp version 3.3.0' do
  skip 'requires core == 3.3.0' unless RSMP::Validator.core_matches?('3.3.0')
  check_sequence '3.3.0'
end
```
</details>
