# Design

## 1. Principles

1. **Two-second logging.** Action Button → amount → Save. Anything that slows this down is a bug.
2. **Thumb-first.** On a 6.9" display the top third is out of reach. The keypad, the category chips, and Save all sit in the bottom half.
3. **The number is the hero.** The amount is the largest element on screen at all times.
4. **Quiet by default.** System materials and semantic colors. Color is used only to encode category.
5. **Native feel.** Standard sheets, lists, and swipe actions. When built with the iOS 26 SDK, the system applies Liquid Glass to navigation bars, toolbars, and sheets automatically.

## 2. Target device

| Device | Points | Pixels (@3x) | Notes |
|---|---|---|---|
| iPhone 17 Pro Max (primary) | 440 × 956 | 1320 × 2868 | Dynamic Island, Action Button, 120 Hz |
| iPhone 17 / 17 Pro | 402 × 874 | 1206 × 2622 | |
| iPhone SE 3 (smallest supported) | 375 × 667 | 750 × 1334 | Layout must still fit without scrolling |

Layouts use flexible frames (`maxWidth: .infinity`, `minHeight`/`maxHeight` ranges, `Spacer(minLength: 0)`). No layout uses fixed screen sizes.

## 3. Color

| Token | Light | Dark | Use |
|---|---|---|---|
| `AccentColor` | `#0FA3A3` | `#2DD4BF` | Primary "Add Expense" button, links |
| Background | `systemGroupedBackground` | same (semantic) | Dashboard list |
| Card | `secondarySystemGroupedBackground` | same | Month summary card |
| Key fill | `primary @ 5%` (pressed 12%) | same | Keypad keys |
| Text | `.primary` / `.secondary` / `.tertiary` | same | |

**Category tints** (defined in `ExpenseCategory+Style.swift`, system colors so they adapt to dark mode and Increase Contrast):

| Category | Symbol | Tint |
|---|---|---|
| Food | `fork.knife` | orange |
| Groceries | `cart.fill` | green |
| Transport | `car.fill` | blue |
| Bills | `bolt.fill` | yellow |
| Shopping | `bag.fill` | pink |
| Entertainment | `gamecontroller.fill` | purple |
| Health | `cross.case.fill` | red |
| Travel | `airplane` | teal |
| Education | `book.fill` | indigo |
| Other | `square.grid.2x2.fill` | gray |

Category icons appear as tinted glyphs on a 15% tint rounded square, which keeps contrast readable in both themes.

## 4. Typography

All type uses SF, and numbers use **SF Rounded**.

| Role | Style |
|---|---|
| Amount entry | `.system(size: 80, weight: .bold, design: .rounded)`, `minimumScaleFactor(0.4)` |
| Currency symbol | `.system(size: 40, weight: .semibold, design: .rounded)`, secondary |
| Month total | `.system(size: 44, weight: .bold, design: .rounded)` |
| Keypad digits | `.system(.title, design: .rounded, weight: .medium)` |
| Row title | `.body.weight(.medium)` |
| Row amount | `.body.weight(.semibold)` + `monospacedDigit()` |
| Captions | `.caption.weight(.semibold)`, secondary |

## 5. Spacing & shape

- Spacing scale: 4 · 8 · 12 · 16 · 20 · 24 · 28
- Horizontal screen gutter: **20 pt**
- Corner radii (continuous): keys 20, cards 28, category icon = size × 0.3, buttons capsule
- Primary buttons: 56 pt tall, full width minus gutters

## 6. Screens

### 6.1 Dashboard

```
┌────────────────────────────────────────┐
│ Expenses                               │  large nav title
│ ┌────────────────────────────────────┐ │
│ │ SEPTEMBER 2026                     │ │  summary card
│ │ ₹18,450.00                         │ │  44 pt rounded
│ │ 23 transactions this month         │ │
│ │ ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▆▆▆▆▆▅▅▅▃▃▂          │ │  category share bar
│ │ ● Food 42%  ● Bills 25%  ● Travel… │ │  top-3 legend
│ └────────────────────────────────────┘ │
│ TODAY                        ₹1,250.00 │  day header with day total
│ ┌────────────────────────────────────┐ │
│ │ [🍴] Lunch with team      ₹850.00  │ │  swipe ← to delete
│ │      Food · 1:30 PM                │ │
│ │ [🚗] Transport            ₹400.00  │ │
│ └────────────────────────────────────┘ │
│ YESTERDAY …                            │
│                                        │
│ ( ＋  Add Expense )                    │  bottom capsule, accent, 56 pt
└────────────────────────────────────────┘
```

Empty state: `ContentUnavailableView` that says "No expenses yet" and points the user to the Action Button.

### 6.2 Add Expense (sheet)

```
┌────────────────────────────────────────┐
│ (✕)        New Expense       [27 Sep]  │  44 pt header
│                                        │
│               ₹ 1,250.5▍               │  amount + blinking caret (tint)
│          ( 💬 Add a note        )      │
│                                        │
│ [🍴 Food] [🛒 Groceries] [🚗 Transp…] →│  chips, selected = filled tint
│ ┌──────┐  ┌──────┐  ┌──────┐           │
│ │  1   │  │  2   │  │  3   │           │
│ ├──────┤  ├──────┤  ├──────┤           │  keys 56–72 pt, 12 pt gaps
│ │  4   │  │  5   │  │  6   │           │
│ │  7   │  │  8   │  │  9   │           │
│ │  .   │  │  0   │  │  ⌫   │           │  ⌫ long-press = clear
│ └──────┘  └──────┘  └──────┘           │
│ (        Save ₹1,250.50            )   │  category tint, disabled at 0
└────────────────────────────────────────┘
```

**Focus model:** the amount is always the active field when the sheet opens, and the caret blinks immediately. Tapping the note field brings up the system keyboard and hides the keypad. Tapping the amount (or pressing Return) switches back.

**Input rules:** at most 7 integer digits and 2 decimals. A leading `0` is replaced. A separator typed first becomes `0.`. The display uses the locale's grouping, so `en_IN` shows `12,34,567` and `en_US` shows `1,234,567`.

**Dismissal:** swipe-to-dismiss is disabled once an amount is typed. The ✕ button always dismisses.

**Defaults:** the category preset comes from the intent or URL if one was given, otherwise the last used category. The date is today and can't be in the future.

### 6.3 Siri / Action Button snippet (`LogExpenseIntent`)

```
┌────────────────────────────────────────┐
│ [🍴]  ₹250.00              This month  │
│       Food                 ₹18,700.00  │
└────────────────────────────────────────┘
Dialog: "Logged ₹250.00 for Food."
```

## 7. Motion

| Moment | Animation |
|---|---|
| Amount digits | `.contentTransition(.numericText())` + `.snappy(0.2)` |
| Month total change | `.numericText()` + `.snappy` |
| Key press | scale 0.96 + fill 5% → 12%, `.snappy(0.15)` |
| Caret | opacity 1 ↔ 0, 0.5 s ease (phaseAnimator) |
| Keypad show/hide | move from bottom + opacity, `.snappy` |

With Reduce Motion on, SwiftUI's built-in transitions degrade automatically. Custom scale effects are small enough to keep.

## 8. Haptics

| Event | Feedback |
|---|---|
| Keypad key | `.impact(weight: .light)` |
| Category change | `.selection` |
| Saved | `.success` (UINotificationFeedbackGenerator, fired before dismiss) |

## 9. Accessibility

- The amount display is one element: label "Amount", value = current text.
- Keys: "1"…"9", "Decimal point", and "Delete" with the hint "Double-tap and hold to clear".
- Rows combine into a single element, e.g. "Lunch with team, Food, 1:30 PM, ₹850.00".
- Category chips announce "selected" through `.isSelected`.
- Dynamic Type: all text except the amount hero scales. The hero is already 80 pt and uses scale-to-fit.
