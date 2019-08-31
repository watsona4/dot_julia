# Greedy functions
  The greedy `BetweenFlags` functions are similar to regex pattern matching.
  The greedy `BetweenFlags` functions are useful for processing strings to, e.g., remove comments,
  where after opening a comment (e.g. triple `"`), the first instance of closing the comment must be recognized.

## Examples

```
  using BetweenFlags
  s = "Here is some text, and {THIS SHOULD BE GRABBED}, BetweenFlags offers a simple interface..."
  s = get_flat(s, ["{"], ["}"])
  print(s)
{THIS SHOULD BE GRABBED}

  s = "Here is some text, and {THIS SHOULD BE GRABBED), BetweenFlags} offers a simple interface..."
  s = get_flat(s, ["{"], ["}", ")"])
  print(s)
{THIS SHOULD BE GRABBED)
```

## Note
These functions are effectively replaceable by regex. They do, however,
provide a nice interface. The level-based functions are not, in general,
replaceable by regex.
