## Changes

This document describes the relevant changes between releases of the
_simple-websocket-vcr_ project.

### 0.0.5 (not released yet)
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
