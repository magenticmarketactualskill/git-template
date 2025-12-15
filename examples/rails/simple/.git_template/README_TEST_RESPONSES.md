# Test Responses Configuration

This file explains how to configure automatic responses for template testing.

## Overview

The `test_responses.yml` file allows templates to define automatic responses to interactive prompts during testing. This makes templates fully non-interactive while preserving their functionality.

## Configuration File Format

Create a `test_responses.yml` file in your template's `.git_template/` directory:

```yaml
# Simple string patterns (will be escaped)
"Add authentication with Devise? (y/n)": "n"
"Setup RSpec for testing? (y/n)": "n"

# Regex patterns (wrap in forward slashes)
"/Overwrite.*\\? \\(enter \"h\" for help\\) \\[Ynaqdhm\\]/": "y"
"/\\? \\(y\\/n\\)/": "n"
```

## Pattern Types

### 1. Simple String Patterns
- Exact text matching (case-insensitive)
- Automatically escaped for regex safety
- Best for specific, known prompts

```yaml
"Add authentication with Devise? (y/n)": "n"
"Initialize git repository? (y/n)": "n"
```

### 2. Regex Patterns
- Flexible pattern matching
- Wrap pattern in forward slashes: `/pattern/`
- Use double backslashes for escaping: `\\`

```yaml
"/Overwrite.*\\[Ynaqdhm\\]/": "y"
"/Setup.*\\? \\(y\\/n\\)/": "n"
```

## Response Format

- Responses should be the exact text you would type
- Don't include quotes around the response
- Newlines are automatically added
- Common responses: `"y"`, `"n"`, `"yes"`, `"no"`

## Default Responses

If no `test_responses.yml` is found, these defaults are used:

```yaml
# File overwrite prompts (always overwrite in tests)
"/Overwrite.*\\? \\(enter \"h\" for help\\) \\[Ynaqdhm\\]/": "y"
"/conflict.*Overwrite.*\\[Ynaqdhm\\]/": "y"

# Generic prompts (default to no for safety)
"/\\? \\(y\\/n\\)/": "n"
"/\\? \\(yes\\/no\\)/": "no"
```

## Testing Your Configuration

Run the test command to see your configuration in action:

```bash
bin/git-template test --templated_app_path examples/rails/simple
```

You'll see output like:
```
📋 Loading template responses from: .../test_responses.yml
  • Add authentication with Devise? (y/n) → "n"
  • Setup RSpec for testing? (y/n) → "n"
  • /Overwrite.*\? \(enter "h" for help\) \[Ynaqdhm\]/ → "y"
```

## Common Patterns

### File Overwrite Prompts
```yaml
"/Overwrite.*\\? \\(enter \"h\" for help\\) \\[Ynaqdhm\\]/": "y"
"/conflict.*Overwrite.*\\[Ynaqdhm\\]/": "y"
```

### Yes/No Questions
```yaml
"/.*authentication.*\\? \\(y\\/n\\)/": "n"
"/.*Bootstrap.*\\? \\(y\\/n\\)/": "n"
"/.*testing.*\\? \\(y\\/n\\)/": "n"
```

### Generic Fallbacks
```yaml
"/\\? \\(y\\/n\\)/": "n"
"/\\? \\(yes\\/no\\)/": "no"
```

## Best Practices

1. **Start specific, then general**: Define specific patterns first, then generic fallbacks
2. **Test thoroughly**: Run tests to ensure all prompts are handled
3. **Use safe defaults**: Default to "no" for destructive operations
4. **Document patterns**: Add comments explaining complex regex patterns
5. **Keep it simple**: Use string patterns when possible, regex only when needed

## Troubleshooting

### Pattern Not Matching
- Check the exact prompt text in the logs
- Ensure proper escaping for special characters
- Test regex patterns online before using

### Invalid Regex
- Use double backslashes for escaping: `\\`
- Wrap regex patterns in forward slashes: `/pattern/`
- Check logs for "Invalid pattern" warnings

### Missing Responses
- Add generic fallback patterns
- Check that the file is named `test_responses.yml`
- Ensure proper YAML syntax