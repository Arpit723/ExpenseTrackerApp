---
name: swiftui-preview-validator
description: Validate SwiftUI #Preview blocks compile and render correctly. Use when adding or modifying preview blocks, checking for preview errors, or auditing preview coverage across the codebase.
---

# SwiftUI Preview Validator Skill

## Operating Rules

- Only validate `#Preview` macro blocks (iOS 17+ / Xcode 15+ syntax)
- Do not modify preview content — only flag issues and suggest fixes
- Check that all preview dependencies (mocks, sample data) compile
- Verify previews work in both light and dark mode
- Ensure previews don't rely on runtime-only state (network, Firebase, keychain)

## Task Workflow

### Validate a single preview

1. **Read the file** containing the `#Preview` block
2. **Check compilation**:
   - All types referenced in the preview exist and are accessible
   - Mock/sample data is valid (correct types, required fields)
   - Environment objects and dependencies are properly injected
   - No missing `@EnvironmentObject` that would crash at runtime
3. **Check preview structure**:
   - Preview has a display name for identification in Xcode Canvas
   - Nested in a `NavigationStack` if the view uses navigation
   - Wrapped in `.environmentObject()` for required dependencies
   - Size constraints set if the view is meant for a specific context (widgets, complications)
4. **Build the file** to verify no preview-specific compilation errors:
   ```bash
   xcodebuild build -scheme ExpenseTrackerApp \
     -destination 'platform=iOS Simulator,name=iPhone 16'
   ```

### Audit all preview coverage

1. **Find all view files** using Glob for `**/*View.swift`
2. **Check each file** for `#Preview` blocks
3. **Report coverage**: which views have previews, which don't
4. **Flag common issues**:
   - Missing `.environmentObject(DataService.shared)` injection
   - Missing `NavigationStack` wrapper for views with navigation
   - Hardcoded data that doesn't represent real use cases
   - Missing dark mode variant

### Generate missing previews

For views without `#Preview` blocks:

1. **Read the view** to understand its dependencies
2. **Create a preview** using the standard template:
   ```swift
   #Preview("ViewName") {
       ViewName()
           .environmentObject(DataService.shared)
   }
   ```
3. **Add dark mode variant** if the view uses custom colors:
   ```swift
   #Preview("ViewName — Dark") {
       ViewName()
           .environmentObject(DataService.shared)
           .preferredColorScheme(.dark)
   }
   ```

## Common Preview Issues

| Issue | Symptom | Fix |
|-------|---------|-----|
| Missing `@EnvironmentObject` | Crash: "No ObservableObject found" | Add `.environmentObject(DataService.shared)` |
| View needs navigation | Navigation bar missing or broken | Wrap in `NavigationStack { ... }` |
| Preview has no name | Hard to find in Canvas | Add string: `#Preview("Dashboard") { ... }` |
| Static date in sample data | Always shows "Today" | Use `Date()` or specific dates for variety |
| Missing color scheme | Dark mode broken | Add `.preferredColorScheme(.dark)` variant |
| Large list preview | Slow Canvas rendering | Limit sample data to 5-10 items |

## Preview Template

### Simple View

```swift
#Preview("TransactionRow") {
    List {
        TransactionRow(transaction: sampleTransaction)
    }
}
```

### View with Environment Objects

```swift
#Preview("DashboardView") {
    NavigationStack {
        DashboardView()
            .environmentObject(DataService.shared)
    }
}
```

### Multi-Variant Preview

```swift
#Preview("TransactionRow — Variants") {
    List {
        TransactionRow(transaction: incomeTransaction)
        TransactionRow(transaction: expenseTransaction)
        TransactionRow(transaction: longPayeeTransaction)
    }
}
```

## Validation Checklist

For each `#Preview` block:

- [ ] Has a descriptive display name
- [ ] All required `@EnvironmentObject` dependencies injected
- [ ] Wrapped in `NavigationStack` if view uses navigation
- [ ] Sample data is realistic (valid amounts, real category names)
- [ ] Dark mode variant exists if view uses custom theme colors
- [ ] No more than 10 sample items in list previews (performance)
- [ ] File compiles without errors after preview changes
