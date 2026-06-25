# Food Delivery — Rider App Design System & Guidelines

This document details the visual design system, color tokens, and interface layout specifications implemented in the Rider App.

---

## 🎨 Design Theme & Colors

The rider app uses a specialized color palette tailored for logistic management and clear readability in outdoor/on-road environments. It uses a **Deep Teal** brand color to visually distinguish it from the **Bright Orange** customer application.

| Token Name | Hex Code | Visual Swatch | Intent & Usage |
| :--- | :--- | :--- | :--- |
| `primary` | `#0F766E` | ![#0F766E](https://placehold.co/15x15/0F766E/0F766E.png) | Teal 700. Main theme color, button backings, headers, active landmarks. |
| `primaryDark` | `#115E59` | ![#115E59](https://placehold.co/15x15/115E59/115E59.png) | Teal 800. Online status indicators, deep accents. |
| `background` | `#F8FAFC` | ![#F8FAFC](https://placehold.co/15x15/F8FAFC/F8FAFC.png) | Slate 50. Lightweight, clean canvas backing. |
| `text` | `#0F172A` | ![#0F172A](https://placehold.co/15x15/0F172A/0F172A.png) | Slate 900. High-contrast slate color for maximum reading legibility. |
| `textLight` | `#64748B` | ![#64748B](https://placehold.co/15x15/64748B/64748B.png) | Slate 500. Sub-labels, inactive lanes, distance details. |
| `success` | `#10B981` | ![#10B981](https://placehold.co/15x15/10B981/10B981.png) | Emerald 500. Earnings metrics, checkmarks, completed badge alerts. |

---

## 📐 Layout & Card Dimensions

* **Gaps & Spacing**: Standard vertical margins set to `8px` or `12px` between list cards.
* **Rounded Corners**: 
  * `20.0` border-radius for action cards to form comfortable visual panels.
  * `16.0` border-radius for input text fields and main buttons.
* **Card Borders**: Fitted with a 1px border of `#E2E8F0` (Slate 200) instead of default drop shadows, producing a flatter, cleaner outline dashboard feel.

---

## 📦 Redesigned Screen Elements

### 1. Curved Header (`rider_login_screen.dart`)
* Curved brand visual container with a linear gradient of deep teals (`#115E59` to `#0F766E`). Offers a modern first impression.

### 2. Job Dispatch lane (`available_orders_screen.dart`)
* Features a prominent **"Online & Accepting Jobs"** status header.
* Orders are rendered in styled cards containing a timeline diagram linking the pickup restaurant details and customer drop-off details.

### 3. Active Order Panel (`active_order_screen.dart`)
* Integrates a floating target alignment action key directly on the Google Map.
* Displays shipping items in a clean checklist format.
* Notes and courier instructions are highlighted within a specialized amber alert box to prevent the rider from overlooking critical details.

### 4. Earnings Dashboard Summary (`order_history_screen.dart`)
* A dynamic top metrics bar calculates total completed jobs and total revenue from delivery logs.
