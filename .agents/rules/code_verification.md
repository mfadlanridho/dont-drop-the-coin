# Rule: Mandatory Code Verification for Roblox Luau

Whenever creating or modifying Luau scripts in the workspace:

1. **Static Analysis (`luau-analyze`)**:
   - Always run `luau-analyze <filepath>` in the terminal to verify zero syntax, type, or undefined global errors before finalizing changes.

2. **Runtime Verification (`execute_luau`)**:
   - If Roblox Studio is connected via MCP, execute a runtime test snippet using `execute_luau` to verify that `require()` calls succeed in live Roblox Studio without crashing.

3. **No Unverified Code**:
   - Never declare a task complete until both static analysis and runtime require checks pass clean.
