"""Pass/fail/skip counters for host-side remote selftest modules."""


class Results:
    def __init__(self):
        self.passed = 0
        self.failed = 0
        self.skipped = 0

    def ok(self, msg):
        self.passed += 1
        print(f"  [PASS] {msg}")

    def bad(self, msg):
        self.failed += 1
        print(f"  [FAIL] {msg}")

    def skip(self, msg):
        self.skipped += 1
        print(f"  [SKIP] {msg}")

    def exit_code(self):
        return 1 if self.failed else 0

    def summary(self):
        print("------------------------------------------------------")
        print(
            f" summary: {self.passed} passed, {self.failed} failed, {self.skipped} skipped"
        )
        print("======================================================")
        return self.exit_code()
