## Changes

This document describes the relevant changes between releases of the
_simple-websocket-vcr_ project.

### 0.0.8 (not released yet)

### 0.0.7
* new option `record: all`

### 0.0.6
* Reverse substitution for cassettes that have ERB. Basically, if we are recording and these options are passed: `erb: {some_key: some_value}, reverse_substitution: true`, then when the framework is about to store the `some_value` into cassette (JSON or YAML), the `<%= some_key =>` is stored instead of the value. So it allows to record the templates.
* increasing the code coverage

### 0.0.5
* Now, there can be ERB in the cassettes (templating)
* YAML cassettes support
* version is aligned with the VCR module so that coverall could do its job properly (https://travis-ci.org/Jiri-Kremser/simple-websocket-vcr/jobs/118142774#L215)

### 0.0.4
* if client waits for msg a therad is spawned and it checks the recording for consecutive read operations and translate it to the events, if write operation is on the top of the stack, the thread waits for the client to perform the write

### 0.0.3
* making it more robust

### 0.0.2
* bug fixes
* Rubocop
* actually, making it work with unseen scenarios

### 0.0.1

* First release
