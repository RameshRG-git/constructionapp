<!-- Sync Impact Report
Version change: unversioned template -> 1.0.0
Modified principles: all placeholders -> Browser-First Delivery, Simple Stack, Test the Critical Path,
Secure by Default, Observable and Maintainable
Added sections: Web Application Requirements, Development and Release Rules
Removed sections: none
Templates requiring updates: ⚠ pending none
Deferred items: none
-->

# Web Application Constitution

## Core Principles

### I. Browser-First Delivery
The application MUST deliver its primary user experience through the web browser.
It MUST work on current versions of Chrome, Edge, Firefox, and Safari, and it
MUST remain usable on desktop and mobile viewports.

### II. Simple Stack
The implementation MUST stay as small as possible for the feature at hand.
Use one frontend application and one backend boundary only when the user need
requires it. New frameworks, services, and abstractions MUST be justified by a
clear product requirement.

### III. Test the Critical Path
Every change that affects a user-facing flow MUST have automated coverage for
the happy path and any important failure path. A change is not complete until
the relevant tests pass locally.

### IV. Secure by Default
All user input MUST be validated on the server or trusted backend boundary.
Secrets MUST stay out of browser code and client-side storage. Mutating actions
MUST enforce authorization before they change data.

### V. Observable and Maintainable
The application MUST expose actionable errors and logs for failed requests,
crashes, and external service failures. Code SHOULD favor readability over
cleverness, and changes SHOULD avoid unnecessary coupling.

## Web Application Requirements

The product MUST be responsive, accessible, and functional without relying on
browser-specific behavior. Interactive elements MUST have clear labels, focus
states, and keyboard support. Content updates MUST preserve page stability and
avoid blocking the main interaction path.

## Development and Release Rules

Changes MUST be reviewed for principle compliance before merge. A pull request
MUST include the tests or checks needed to validate the touched user flow.
Production releases MUST be based on a passing build and a known-good revision.

## Governance

This constitution supersedes informal practice when the two conflict. Any
amendment MUST update the version, ratification date, and last amended date.
Minor wording changes increment PATCH, new principles or sections increment
MINOR, and removals or redefinitions increment MAJOR. Reviews MUST confirm
compliance with these rules before approval.

**Version**: 1.0.0 | **Ratified**: 2026-05-18 | **Last Amended**: 2026-05-18
