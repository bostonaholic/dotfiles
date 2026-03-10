# jq Built-in Function Reference

Complete reference for jq 1.8 built-in functions organized by category.

## String Functions

### Regex Operations

```bash
# test — returns true/false
.name | test("pattern")
.name | test("pattern"; "flags")   # flags: x (extended), i (case-insensitive), g (global), m (multiline), s (dotall), n (named captures)

# match — returns match object {offset, length, string, captures}
.text | match("(\\w+)@(\\w+)")
.text | match("(?<user>\\w+)@(?<host>\\w+)"; "i")

# capture — returns object of named captures
.text | capture("(?<year>\\d{4})-(?<month>\\d{2})-(?<day>\\d{2})")

# scan — returns all matches as arrays
.text | scan("\\d+")

# sub/gsub — replace first/all matches
.text | sub("old"; "new")
.text | sub("(?<x>\\w+)"; "prefix-\(.x)")
.text | gsub("\\s+"; " ")
```

### String Manipulation

```bash
# Split and join
"a,b,c" | split(",")                    # ["a","b","c"]
["a","b","c"] | join(",")               # "a,b,c"

# Trim
"  hello  " | trim                      # "hello"
"  hello  " | ltrim                     # "hello  "
"  hello  " | rtrim                     # "  hello"
"prefix-data" | ltrimstr("prefix-")     # "data"
"file.txt" | rtrimstr(".txt")           # "file"

# Case conversion
"Hello" | ascii_downcase                # "hello"
"Hello" | ascii_upcase                  # "HELLO"

# Testing
"foobar" | startswith("foo")            # true
"foobar" | endswith("bar")              # true

# Codepoint operations
"ABC" | explode                         # [65,66,67]
[65,66,67] | implode                    # "ABC"

# Length
"hello" | length                        # 5
"héllo" | utf8bytelength                # 6

# Conversion
42 | tostring                           # "42"
"42" | tonumber                         # 42
```

### String Interpolation

```bash
# Inside jq strings
"Name: \(.name), Age: \(.age)"

# With format strings
@uri "https://api.example.com/search?q=\(.query)"
@html "<p>\(.content)</p>"
```

## Array Functions

### Construction and Transformation

```bash
# range — generate numbers
range(5)                    # 0,1,2,3,4
range(2;5)                  # 2,3,4
range(0;10;2)               # 0,2,4,6,8

# map — apply filter to each element
[1,2,3] | map(. * 2)       # [2,4,6]

# map_values — apply to values (works on objects too)
{"a":1,"b":2} | map_values(. + 10)  # {"a":11,"b":12}

# flatten
[[1,[2]],[[3]]] | flatten   # [1,2,3]
[[1,[2]],[[3]]] | flatten(1) # [1,[2],[3]]

# reverse
[1,2,3] | reverse           # [3,2,1]

# transpose (matrix)
[[1,2],[3,4]] | transpose    # [[1,3],[2,4]]

# combinations
[0,1] | combinations(2)     # [0,0],[0,1],[1,0],[1,1]
[[1,2],[3,4]] | combinations # [1,3],[1,4],[2,3],[2,4]
```

### Sorting and Grouping

```bash
# sort
[3,1,2] | sort                                # [1,2,3]
[{"a":2},{"a":1}] | sort_by(.a)               # [{"a":1},{"a":2}]

# group_by — returns array of arrays
[{"t":"a","v":1},{"t":"b","v":2},{"t":"a","v":3}] | group_by(.t)
# [  [{"t":"a","v":1},{"t":"a","v":3}],  [{"t":"b","v":2}]  ]

# unique / unique_by
[1,2,1,3] | unique                             # [1,2,3]
[{"a":1,"b":2},{"a":1,"b":3}] | unique_by(.a)  # [{"a":1,"b":2}]
```

### Selection and Searching

```bash
# select — keep elements matching condition
.[] | select(.age > 18)
.[] | select(.name | test("^A"))

# empty — produce no output (filter out)
if .valid then . else empty end

# first / last / nth
first(.[] | select(.active))
last(range(10))
nth(2; range(10))           # 2

# limit — take at most n outputs
limit(3; .[] | select(.score > 50))

# any / all
[1,2,3] | any(. > 2)       # true
[1,2,3] | all(. > 0)       # true

# contains / inside
[1,2,3] | contains([2,3])  # true
[2,3] | inside([1,2,3])    # true

# indices / index / rindex
"abcabc" | indices("bc")   # [1,4]
[1,2,3,2] | index(2)       # 1
[1,2,3,2] | rindex(2)      # 3

# bsearch — binary search (array must be sorted)
[1,2,3,4] | bsearch(3)     # 2
```

### Aggregation

```bash
# add — sum numbers, concatenate strings/arrays, merge objects
[1,2,3] | add               # 6
["a","b"] | add              # "ab"
[{"a":1},{"b":2}] | add      # {"a":1,"b":2}

# length
[1,2,3] | length             # 3

# min / max / min_by / max_by
[3,1,2] | min                # 1
[{"a":3},{"a":1}] | min_by(.a)  # {"a":1}
```

## Object Functions

```bash
# keys / keys_unsorted
{"b":2,"a":1} | keys          # ["a","b"]  (sorted)
{"b":2,"a":1} | keys_unsorted # ["b","a"]  (insertion order)

# values
{"a":1,"b":2} | values        # [1,2]

# has — check key/index existence
{"a":1} | has("a")            # true
[1,2,3] | has(2)              # true

# in — check if input key exists in object
"a" | in({"a":1})             # true

# to_entries / from_entries / with_entries
{"a":1,"b":2} | to_entries    # [{"key":"a","value":1},{"key":"b","value":2}]
[{"key":"a","value":1}] | from_entries  # {"a":1}
{"a":1} | with_entries(.value |= . + 10)  # {"a":11}

# pick — project specific paths
{"a":1,"b":{"c":2,"d":3}} | pick(.a, .b.c)  # {"a":1,"b":{"c":2}}

# del — delete key
{"a":1,"b":2} | del(.b)      # {"a":1}
```

## Type Functions

```bash
# type — returns type as string
null | type       # "null"
true | type       # "boolean"
1 | type          # "number"
"s" | type        # "string"
[] | type          # "array"
{} | type          # "object"

# Type selectors (pass through matching, reject others)
(1, "a", null, true, []) | numbers    # 1
(1, "a", null, true, []) | strings    # "a"
(1, "a", null, true, []) | arrays     # []
(1, "a", null, true, []) | booleans   # true
(1, "a", null, true, []) | nulls      # null
(1, "a", null, true, []) | objects    # (none)
(1, "a", null, true, []) | scalars    # 1, "a", null, true
(1, "a", null, true, []) | iterables  # []

# Conversion
.value | tostring
.count | tonumber
```

## Math Functions

```bash
# Rounding
3.7 | floor       # 3
3.2 | ceil         # 4
3.5 | round        # 4

# Absolute value
-5 | abs           # 5
-5.5 | fabs        # 5.5

# Powers and roots
4 | sqrt           # 2
pow(2; 10)         # 1024

# Logarithms
1 | exp            # 2.718281828...
10 | log           # 2.302585...
100 | log10        # 2
8 | log2           # 3

# Trigonometry
0 | sin            # 0
0 | cos            # 1
1 | atan           # 0.7853981...
atan(1; 1)         # 0.7853981... (atan2)

# Special values
infinite           # infinity
nan                # NaN
1e308 * 10 | isinfinite  # true
(0/0) | isnan            # true
```

## Date and Time Functions

```bash
# Current time
now                                      # Unix timestamp (float)

# ISO 8601 conversion
now | todateiso8601                      # "2026-03-06T..."
"2026-01-15T10:30:00Z" | fromdateiso8601 # Unix timestamp

# Aliases
now | todate                             # same as todateiso8601
"2026-01-15T10:30:00Z" | fromdate        # same as fromdateiso8601

# Custom formatting (strftime directives)
now | strftime("%Y-%m-%d")               # "2026-03-06"
now | strftime("%H:%M:%S")               # "03:45:12"
now | strflocaltime("%Y-%m-%d %H:%M %Z") # local timezone

# Parse custom formats
"2026-01-15" | strptime("%Y-%m-%d")      # broken-down time array

# Time breakdown
now | gmtime                             # [year,month0,day,hour,min,sec,weekday,yearday]
now | gmtime | mktime                    # back to Unix timestamp
```

## Path Functions

```bash
# path — get path to a value
{"a":{"b":1}} | path(.a.b)              # ["a","b"]

# paths — enumerate all paths
{"a":{"b":1},"c":2} | [paths]           # [["a"],["a","b"],["c"]]
{"a":{"b":1},"c":2} | [paths(scalars)]  # [["a","b"],["c"]]
{"a":{"b":1},"c":2} | [leaf_paths]      # [["a","b"],["c"]]

# getpath / setpath / delpaths
{"a":{"b":1}} | getpath(["a","b"])       # 1
{"a":1} | setpath(["b","c"]; 2)          # {"a":1,"b":{"c":2}}
{"a":1,"b":2} | delpaths([["b"]])        # {"a":1}
```

## Format Strings

```bash
# @csv — RFC 4180 CSV
["name","age"] | @csv                    # "\"name\",\"age\""

# @tsv — tab-separated
["name","age"] | @tsv                    # "name\tage"

# @json — JSON encode
{"a":1} | @json                          # "{\"a\":1}"

# @html — HTML entity escape
"<script>" | @html                       # "&lt;script&gt;"

# @uri / @urid — percent encoding
"hello world" | @uri                     # "hello%20world"
"hello%20world" | @urid                  # "hello world"

# @sh — shell escaping
"it's a file" | @sh                      # "'it'\\''s a file'"

# @base64 / @base64d
"hello" | @base64                        # "aGVsbG8="
"aGVsbG8=" | @base64d                    # "hello"

# @text — same as tostring
42 | @text                               # "42"

# Interpolation with format strings
@uri "https://example.com/search?q=\(.query)&page=\(.page)"
```

## I/O Functions

```bash
# input / inputs — read from remaining inputs
# (use with -n flag)
jq -n '[inputs | .name]' file1.json file2.json

# debug — print to stderr, pass value through
.data | debug | .field
.data | debug("label") | .field

# stderr — write to stderr
.warning | stderr | empty

# env / $ENV — environment variables
env.HOME                                 # "/Users/matthew"
$ENV.PATH                                # path string

# halt / halt_error
if .critical then halt_error(1) else . end
```

## SQL-Style Operators

```bash
# INDEX — build lookup table
[{"id":1,"name":"a"},{"id":2,"name":"b"}] | INDEX(.[]; .id)
# {"1":{"id":1,"name":"a"},"2":{"id":2,"name":"b"}}

# IN — membership test
2 | IN(1, 2, 3)              # true
.[] | select(IN(.id; 1, 2))  # items with id 1 or 2

# GROUP_BY
[{"t":"a","v":1},{"t":"b","v":2},{"t":"a","v":3}] | GROUP_BY(.t)

# UNIQUE_BY
[{"a":1,"b":1},{"a":1,"b":2}] | UNIQUE_BY(.a)

# JOIN
JOIN(INDEX(.[]; .id); .[]; .dept_id)
```
