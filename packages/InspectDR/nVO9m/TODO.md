# TODO: Scales

The following lists various desired ways to display axis scales & labels.

## Lin scales

### Config: Display compact (maxdigits = M)
 - Only use scientific notation when # digits exceeds M.

### Config: Display scientific/engineering/SI
 - Ticks scientific: (1x10^6, 1x10^7, 1x10^8, 1x10^9)
 - Ticks engineering: (1x10^6, 10x10^6, 100x10^6, 1x10^9)
 - Ticks SI: (1M, 10M, 100M, 1G)

### Config: Display common axis factor, F
 - Ticks F native (F=1): (1x10^6, 5x10^7, 1x10^8, 1.5x10^8)
 - Ticks F user defined (F=10^9): (.001, .05, .1, .15) x10^9
 - Ticks F aligned low: (1, 50, 100, 150) x10^6
 - Ticks F aligned middle: (0.1, 5, 10, 15) x10^7
 - Ticks F aligned high: (0.01, 0.5, 1.0, 1.5) x10^8

## Log scales

### Config: Display C * N^EXP for user-selected C, N:
 - Ticks native (5, 10): (50, 500, 5000, 50000)
 - Ticks compact (5, 10): (5x10^1, 5x10^2, 5x10^3, 5x10^4)
 - Ticks native (1, 2): (2, 4, 8, 16)
 - Ticks compact (1.5, 2): (1.5x2^1, 1.5x2^2, 1.5x2^3, 1.5x2^4)
 - Ticks compact (2.5, e): (2.5xe^1, 2.5xe^2, 2.5xe^3, 2.5xe^4)

## Other scales

 - 1/x Scale

## Scale transformations

 - Provide a means to reverse axis direction.


# TODO: Other

...
