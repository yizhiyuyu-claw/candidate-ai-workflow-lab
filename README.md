# Candidate AI Workflow Lab

This is a small Dart engineering exercise for an online interview.

You may use AI tools such as Codex, Claude Code, Cursor, Gemini CLI, or any similar tool. The goal is not to test memorized syntax. The goal is to see how you read an unfamiliar codebase, guide AI, verify output, and explain risk.

## Scenario

TravelPack sells digital travel connectivity passes. A mobile app syncs order data from a remote API and stores a local cache for offline display.

The current implementation has correctness and privacy issues. Your task is to fix the service with the smallest reasonable change.

## Time Box

Recommended: 90 minutes.

## Setup

```bash
dart pub get
dart test
```

If you use Flutter tooling, `flutter pub get` and `flutter test` should also work on machines with Flutter installed.

## Your Task

1. Run the test suite and inspect the failing behavior.
2. Fix the implementation without changing the public behavior expected by tests.
3. Add or update tests if you think an important behavior is not covered.
4. Keep the code simple and explain any tradeoff.

## Deliverables

Please send back:

1. A link to your fork or a zip of your final repo.
2. Your final diff.
3. The exact AI prompts you used, including important follow-up prompts.
4. The commands you ran and their results.
5. A short note:
   - what you changed,
   - what you verified,
   - what you did not verify,
   - risks or edge cases you would discuss before shipping.

## Constraints

- Do not remove tests just to make the suite pass.
- Do not hard-code values only to satisfy the current tests.
- Do not log raw email addresses, raw tokens, or full customer identifiers.
- Avoid broad rewrites unless you can justify them.
