# Contributing

**interBTC** is an open-source software project, providing a 1:1 Bitcoin-backed asset - fully collateralized, interoperable, and censorship-resistant.

## Writing

### Key Words

When defining the specification use [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119) language.

### Structure

A specification file MUST have the following outline.
A good example is the [issue specification](docs/spec/issue.rst).

```rst
Title
=====

Overview
~~~~~~~~
Abstract of the module.

Step-by-step // Recommended
------------
A step-by-step of the implemented protocol.

Security // Optional
--------
Security-specific considerations.

Integrations with other modules // Optional
-------------------------------
Integration-specific considerations.

Data Model
~~~~~~~~~~

Constants
---------

.. _title_constant_const_a

ConstA
......

Scalars
-------

.. _title_scalar_scalar_a:

ScalarA
.......


Functions
~~~~~~~~~

.. _title_function_func_a:

func_a
------

Events
~~~~~~

.. _title_event_event_a:

EventA
------
```

### Naming Conventions

Since the specification is implemented in Rust, we adopt Rust [RFC 430](https://github.com/rust-lang/rfcs/blob/master/text/0430-finalizing-naming-conventions.md#general-naming-conventions) naming conventions. In particular:

Item | Convention | Example
---------|----------|---------
 Module title | text | Vault Nomination
 Constants | `SCREAMING_SNAKE_CASE` | `TARGET_TIMESPAN`
 Types | `UpperCamelCase` | `RawBlockHeader`
 Scalars, Map, Structs | `UpperCamelCase` | `PointHistory`
 Functions | `snake_case` | `request_issue`
 References | `snake_case` | `escrow_function_create_lock`

## Rules

There are a few basic ground-rules for contributors (including the maintainer(s) of the project):

- **Master** must have the latest changes and its history must never be re-written.
- **Non-master branches** must be prefixed with the *type* of ongoing work.
- **All modifications** must be made in a **pull-request** to solicit feedback from other contributors.
- **All commits** must be **signed**, have a clear commit message to better track changes, and must follow the [conventional commit](https://www.conventionalcommits.org/en/v1.0.0-beta.2/#summary) standard.
- **All tags** must follow [semantic versioning](https://semver.org/).

## Workflow

We use [Github Flow](https://guides.github.com/introduction/flow/index.html), so all code changes should happen through Pull Requests.

## Issues

We use GitHub issues to track feature requests and bugs.

### Bug Reports

Please provide as much detail as possible, see the GitHub templates if you are unsure.

## Releases

Declaring formal releases remains the prerogative of the project maintainer(s).

## License

By contributing, you agree that your contributions will be licensed under its Apache License 2.0.
