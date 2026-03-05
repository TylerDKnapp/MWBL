# MWBL

Basic git use:

Setup -

`*cd into wherever you'd like the MWBL folder to be*`

`git add`

`git clone https://github.com/TylerDKnapp/MWBL`

`cd MWBL`

`git pull`

`git config user.name "Your git username"`

`git config user.email "Your git username"`

**The following is much simpler and safer to do via VSCode!**


Pulling -

`git fetch`

`git pull`

Pushing -

`git push -a`

# CODING CONVENTIONS & STYLE GUIDE

1. PURPOSE

---

This document defines coding conventions to ensure:

* Consistent, readable, and maintainable code
* Reduced ambiguity across languages and contributors
* Clear representation of physical units
* Easier onboarding, debugging, and code review

These conventions apply to all new code and should be followed when modifying existing code when practical.

---

2. GENERAL PRINCIPLES

---

1. Clarity over brevity:
   Code must be understandable without external explanation.

2. Consistency is mandatory:
   If multiple styles exist, this document defines the required one.

3. Self-documenting code:
   Naming and structure should minimize the need for comments.

4. Explicitness over implicit behavior:
   Avoid assumptions, magic numbers, or hidden unit conversions.

---

3. NAMING CONVENTIONS

---

## 3.1 Variables

Style: camelCase
Applies to: All variables in all languages

Rules:

* Start with a lowercase letter
* Use descriptive, meaningful names
* Avoid abbreviations unless they are standard and unambiguous
* Do not encode type information unless required by the language

Examples:
pressure
maxVelocity
iterationCount
sensorOffset

---

## 3.2 Variables With Units (REQUIRED)

All variables representing physical quantities MUST include units in the name.

Format: <baseName>_<Unit>

Rules:

* Units use PascalCase
* Units must be explicit physical dimensions, not symbols
* Compound units use capitalization to separate dimensions
* Units are mandatory anywhere a quantity has dimensions

Examples:
pressure_LbsPIn2      (pressure in psi)
length_M              (meters)
time_S                (seconds)
velocity_MPS          (meters per second)
accel_MPS2             (meters per second squared)
force_N               (newtons)
temp_C                (degrees Celsius)

Rules:

* Never assume units
* Never mix units in the same variable
* Unit conversions must store results in new variables

Example:
pressure_LbsPIn2 = 120
pressure_Pa = pressure_LbsPIn2 * 6894.76

---

## 3.3 Constants

Style: UPPER_SNAKE_CASE

Rules:

* Constants must be immutable
* Constants with units MUST include units

Examples:
MAX_ITERATIONS
PI
GRAVITY_MPS2
STANDARD_PRESSURE_Pa

---

## 3.4 Functions

Style: snake_case
Applies to: ALL languages, without exception

Rules:

* Function names must be verbs or verb phrases
* Names must describe behavior clearly
* Avoid ambiguous or generic verbs

Examples:
calculate_pressure()
read_sensor_data()
update_state()
compute_fft()
validate_input()

---

## 3.5 Filenames

Style: Language-standard conventions

Rules:

* Filenames must be descriptive
* One primary responsibility per file
* Avoid generic names like "utils", "misc", or "helpers" unless unavoidable

Examples:
Python:      pressure_solver.py
MATLAB:      calculate_pressure.m (function name must match file)
C/C++:       pressure_solver.c / pressure_solver.h

---

4. FORMATTING & INDENTATION

---

## 4.1 Indentation

MATLAB:

* Exactly 2 spaces per indentation level

All other languages:

* Exactly 4 spaces per indentation level

Rules:

* Tabs are NOT allowed
* Spaces only
* Editors must be configured to insert spaces instead of tabs

---

## 4.2 Line Length

* Target maximum: 100 characters
* Absolute maximum: 120 characters
* Break long lines logically and clearly

---

## 4.3 Whitespace

Rules:

* One space around operators

Example:
a = b + c

* No trailing whitespace
* Blank lines used to separate logical sections of code

---

5. COMMENTS & DOCUMENTATION

---

## 5.1 Comments

Rules:

* Comments explain WHY, not WHAT
* Do not restate obvious code behavior
* Keep comments accurate and up to date

Correct:
Compensate for sensor drift at high temperatures

Incorrect:
Subtract correction from value

---

## 5.2 Function Documentation

All public or non-trivial functions must be documented.

Documentation must include:

* Purpose
* Inputs (with units if applicable)
* Outputs (with units if applicable)
* Side effects, if any

Example:

Calculates chamber pressure.

Inputs:

* volume_M3: Chamber volume in cubic meters
* temperature_K: Gas temperature in kelvin

Returns:

* pressure_Pa: Calculated pressure in pascals

---

6. CONTROL STRUCTURES

---

## 6.1 Conditionals

Rules:

* Always use braces where applicable
* Avoid deep nesting
* Prefer early returns to reduce complexity

---

## 6.2 Loops

Rules:

* Loop indices should be meaningful where possible
* Single-letter indices (i, j, k) allowed only for simple loops

---

7. ERROR HANDLING

---

Rules:

* Never silently ignore errors
* Fail fast when assumptions are violated
* Error messages must include context

Example:
pressure_Pa must be positive

---

8. NUMERICAL & SCIENTIFIC CODE GUIDELINES

---

* Avoid magic numbers
* Store constants with names and units
* Explicitly document assumptions
* Be explicit about coordinate frames and reference systems
* Do not mix unit systems implicitly

---

9. VERSION CONTROL & CODE REVIEWS

---

Rules:

* Code must comply with this document before merge
* Style violations are valid review blockers
* Automated formatting and linting tools should be used when available

---

10. DEVIATIONS

---

Any deviation from this guide must:

1. Be justified
2. Be documented
3. Be applied consistently throughout the project
