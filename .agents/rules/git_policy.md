# Rule: Mandatory Git Policy (No Unrequested Git Operations)

Never execute any `git` shell commands (including `git add`, `git commit`, `git push`, `git checkout`, `git stash`, etc.) unless the user explicitly requests a git operation in their message.

1. **Explicit Request Required**: Only run git commands when the user explicitly instructs to "commit", "push", "stage", or run a specific git command.
2. **No Auto-Committing / Auto-Pushing**: Never automatically stage, commit, or push code or documentation changes at the end of a task or turn unless asked by the user.
