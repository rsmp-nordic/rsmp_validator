---
layout: page
title: About
nav_order: 1
---

# Automated RSMP Validation ✔︎

The RSMP Validator performs automated testing of RSMP implementations. It is packaged as the `rsmp-validator` gem, uses the sus test framework, and communicates with equipment via RSMP.

The validator includes a growing suite of tests and can report test results in several formats, so you can quickly assess RSMP compliance and pin-point any problems. It can be used on any platform that supports Ruby, including Linux, Mac and Windows.

```console
% bundle exec rsmp-validator run test/site
116 passed 13 skipped out of 129 total (58 assertions)
```

All tests green!

The RSMP Validator is maintained as open-source by [RSMP Nordic](https://rsmp-nordic.org), the partnership behind the RSMP protocol.

## Intended Use
Road authorities that purchase RSMP equipment or systems can use the validator to assess the quality and completeness of RSMP interfaces.

Suppliers can use the validator as an aid during development of RSMP interfaces.

## Benefits
* The validator will help you implement/use RSMP according to the RSMP specification.
* Automated testing is much faster than manual testing and can be run more often.
* With automated testing, more edge cases can be checked.
* Tests can be selected by path, and sus provides compact or verbose output depending on how much detail you need.

## What equipment can be tested?
The validator can be used to test all types of RSMP equipment.

Traffic Light Controllers have a standardized Signal Exchange List (SXL), and tests cover all messages in this SXL.

For other types of equipment, the tests cover only the RSMP Core specification. However, you can [add your own tests]({{ site.baseurl}}{% link pages/writing.md %}) if you want.

The validator also includes preliminary support for testing supervisor systems.

## Do I need to learn the Ruby language?
No. You can use the validator without writing any Ruby code. Ruby is only needed if you want to [modify or add tests]({{ site.baseurl}}{% link pages/writing.md %}), or you need more in-depth understanding of how specific tests work.

## Try It
Read more [about the validator]({{ site.baseurl}}{% link pages/architecture.md %}) or [get started now]({{ site.baseurl}}{% link pages/getting_started.md %}).
