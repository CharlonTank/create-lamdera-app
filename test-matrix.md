# Test Matrix for create-lamdera-app

## Simplified Test Combinations

Since the `--cursor` flag only adds configuration files (`.cursorrules` and `openEditor.sh`) without affecting functionality, we can significantly reduce our test matrix.

### Essential Test Combinations (9 total)

| Test Name | Flags | Purpose |
|-----------|-------|---------|
| app-basic | None | Baseline Lamdera app |
| app-basic-cursor | `--cursor yes` | Verify cursor files are created |
| app-tailwind | `--tailwind` | Tailwind CSS integration |
| app-test | `--test` | lamdera-program-test setup |
| app-i18n | `--i18n` | i18n + dark mode |
| app-tailwind-test | `--tailwind --test` | Tailwind + Effect pattern |
| app-tailwind-i18n | `--tailwind --i18n` | Tailwind + i18n/dark mode |
| app-test-i18n | `--test --i18n` | Effect pattern + i18n |
| app-all-features | `--tailwind --test --i18n` | All features combined |

### Why This Reduction Works

1. **Cursor flag orthogonality**: The `--cursor` flag only adds:
   - `.cursorrules` - Editor configuration
   - `openEditor.sh` - Script to open editor
   - These don't interact with or affect other features

2. **Original matrix**: 16 combinations (2^4 for 4 boolean flags)
3. **Reduced matrix**: 9 combinations (focusing on functional differences)
4. **Reduction**: 44% fewer tests with same coverage

### Test Scripts

1. **Quick generation**: `./test-all-combinations-simplified.sh`
   - Creates only the 9 essential combinations
   - Faster to run, same functional coverage

2. **Full generation**: `./test-all-combinations.sh`
   - Creates all 16 combinations if needed
   - Useful for exhaustive testing

3. **Interactive testing**: `./test-manual-interactive.sh`
   - Automatically uses simplified set if available
   - Tests each app interactively with error capture

### Feature Interactions to Test

- **Tailwind + Test**: Ensure Effect pattern works with Tailwind build process
- **Tailwind + i18n**: Verify dark mode classes work with Tailwind
- **Test + i18n**: Confirm Effect-wrapped localStorage works correctly
- **All features**: Ultimate integration test

### What We Don't Need to Test

Combinations with cursor + other features, since cursor only adds files:
- ❌ app-cursor-tailwind (same as app-tailwind)
- ❌ app-cursor-test (same as app-test)
- ❌ app-cursor-i18n (same as app-i18n)
- ❌ app-cursor-tailwind-test (same as app-tailwind-test)
- ❌ app-cursor-tailwind-i18n (same as app-tailwind-i18n)
- ❌ app-cursor-test-i18n (same as app-test-i18n)
- ❌ app-cursor-tailwind-test-i18n (same as app-all-features)