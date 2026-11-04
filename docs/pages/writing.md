---
layout: page
title: Writing Tests
permalink: /writing/
has_children: true
nav_order: 4
---

# Writing Tests
Tests are written using the [sus](https://github.com/socketry/sus) testing framework.

Here's an example of a test that verifies that a Traffic Light Controller responds with a NotAcknowledged if it receives a non-existing status request:

```ruby
describe "Traffic Light Controller" do
  include RSMP::Validator::Helpers::Status

  it 'responds with NotAck to invalid status request code' do
    with_site(:connected) do |site_proxy|
      # write to the validator log
      log "Requesting non-existing status S0000"

      # expect an error to be raised
      expect {
        # request a non-existing status
        status_list = convert_status_list( S0000:[:status] )
        site_proxy.request_status RSMP::Validator.get_config('main_component'), status_list, collect: {
          timeout: RSMP::Validator.get_config('timeouts','command_response')
        },
        # normally we can't send S0000 because JSON Schema validation
        # will prevent it, but we can disable it for testing purposes
        validate: false
      }.to raise_exception(RSMP::MessageRejected)
    end
  end
end
```

The `with_site` helper handles the connection to the site, and will pass a `site_proxy` argument (`RSMP::SiteProxy`) which can be used to communicate with the site.

For example, you can request statuses, subscribe to statuses and send commands. Many of the methods allow you to wait for responses.

See the `rsmp` [gem](https://github.com/rsmp-nordic/rsmp) for more documentation.

## Checking Prerequisites

Sus's `expect` records failures and continues running the test. Use the validator's
`expect_or_stop` when later steps depend on an expectation passing:

```ruby
expect_or_stop(items).to be_a(Array)
expect(items.size).to be == 3
```

On failure, `expect_or_stop` preserves Sus's diagnostic and stops the current test,
including code after `with_site` or `with_supervisor`. Ruby `ensure` blocks still
run, and subsequent tests continue normally. Ordinary `expect` is unchanged.

Negation (`expect_or_stop(items).not.to be_nil`), block expectations, and `.and`
chaining are supported. Deferred assertions, such as checking that a method will
be called later, require ordinary `expect`: their result is not yet available to
decide whether to continue. Using them with `expect_or_stop` reports an error.

## Working with Exceptions and Timeouts
Timeouts are essential when testing external systems. When you send a command or request, you expect a response within a certain amount of time. These timeouts must be defined in the test [configuration]({{ site.baseurl}}{% link pages/configuring.md %}).

The `rsmp` gem will raise exceptions if a timeout is reached. Normally, you will not need to do any specific exception handling in your test code. Your test will be aborted and sus will catch the error and report the test as failed.

