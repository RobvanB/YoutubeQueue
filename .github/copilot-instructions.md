# Database safety

- Never modify the development database without first asking the user and receiving explicit approval. This includes changes caused indirectly by tests, fixtures, migrations, seeds, purges, restores, or database setup commands.
- Before running tests or database commands, inspect the active database configuration and verify the target is separate from the development database. If it is shared or ambiguous, do not run the command; ask the user first.
