# Launch playbook

Internal notes for announcing Latcher.nvim. Do these in order, and don't post
the same thing everywhere on the same day.

**Positioning:** *“Fixed numbers for your windows.”* Latcher is for people who
want the same window to always answer to the same digit — not another fuzzy
picker.

---

## 0. Before posting anything

- [ ] Set the GitHub description:
      `Numbered window navigation for Neovim: show [1]-[9] on visible windows, type a digit to jump. Pure Lua, no dependencies.`
- [ ] Add repository topics:
      `neovim`, `neovim-plugin`, `nvim`, `lua`, `window-management`,
      `navigation`, `splits`, `floating-windows`
- [ ] Confirm `assets/demo.gif` plays in the README
- [ ] Tag a release: `git tag v0.1.0 && git push origin main --tags`
- [ ] Run `:checkhealth latcher` and `:help latcher` once
- [ ] Enable GitHub Sponsors if available, and fill in `.github/FUNDING.yml`
- [ ] Optional: enable GitHub Discussions
- [ ] Pin the repo on your GitHub profile for launch week

---

## 1. awesome-neovim (highest leverage)

Repo: <https://github.com/rockerBOO/awesome-neovim>

Add one line under **Split and Window** (read `CONTRIBUTING.md` first; append
at the end of the category):

```markdown
- [Dodoprospy3/Latcher.nvim](https://github.com/Dodoprospy3/Latcher.nvim) - Numbered window navigation: show `[1]`-`[9]` on visible windows and jump with one key. Pure Lua, supports floats, persistent assignments.
```

**PR title**

```
Add Latcher.nvim to Split and Window
```

**PR body**

```
Adds Latcher.nvim, a pure-Lua window switcher.

- :Latcher shows [1]-[9] on every eligible visible window (splits and floats)
- type a digit to jump, <Esc> cancels
- :LatcherReassign pins a number to the current window for the session
- no dependencies, never modifies buffer contents
- Neovim 0.10+, MIT, test suite included
```

---

## 2. This Week in Neovim

Submit through the contact form: <https://this-week-in-neovim.org/contact>

**Subject:** `Plugin submission: Latcher.nvim`

**Body**

```
Latcher.nvim — numbered window navigation for Neovim.

:Latcher puts [1]-[9] in the top-right corner of every visible window
(splits and floating windows). Type a digit to jump; <Esc> cancels.
:LatcherReassign pins a number to the current window for the session.

Pure Lua, no dependencies, Neovim 0.10+, MIT.
Repo: https://github.com/Dodoprospy3/Latcher.nvim
Demo GIF: https://github.com/Dodoprospy3/Latcher.nvim/blob/main/assets/demo.gif
```

---

## 3. r/neovim

**Title**

```
Latcher.nvim: type a number to jump to any visible window (splits + floats, no dependencies)
```

**Body**

```
I built a small window switcher that numbers every visible window and jumps
on a single digit.

Why another one: I wanted fixed numbers I could memorise, including for
floating windows, and I often re-pin numbers while working in the same layout.
Most pickers use letter labels or a search prompt.

What it does:
- :Latcher shows [1]-[9] in the top-right corner of every eligible window
  (splits and floats)
- type the number to jump; <Esc> cancels
- :LatcherReassign pins a number to the current window, and it persists for
  the session
- reassigning a number strips it from the previous owner; nothing shifts
- pure Lua, no dependencies, Neovim 0.10+
- hints are floating windows, so no buffer contents are ever modified

Demo: <link to the GIF in the README>
Repo: https://github.com/Dodoprospy3/Latcher.nvim

Install with lazy.nvim:

  { "Dodoprospy3/Latcher.nvim", lazy = false, opts = {} }

MIT licensed. Feedback welcome, especially on the numbering rules and float
handling.
```

Notes:
- Post the GIF natively (Reddit plays it inline) — do not only link the repo.
- Answer every comment for the first 48 hours.
- Don't ask for stars or cross-post to unrelated subreddits.

---

## 4. Neovim Discourse

Category: **Plugins**. Reuse the Reddit body, minus the “why another one”
apology, and include the GIF. Link the help file and `:checkhealth latcher`.

---

## 5. Social posts

**Mastodon / Bluesky / X**

```
Latcher.nvim — numbered window navigation for Neovim.

:Latcher puts [1]-[9] on every visible window (splits + floats). Type a digit
to jump. Reassign numbers that persist for the session. Pure Lua, zero
dependencies, Neovim 0.10+.

https://github.com/Dodoprospy3/Latcher.nvim

#neovim #lua #opensource
```

Attach the GIF with alt text:

> Three Neovim windows. Running :Latcher shows red [1], [2], and [3] badges
> in the top-right corner of each window; typing 1 jumps to the first window.

---

## 6. Timing

1. Merge the awesome-neovim PR first (drives long-term discovery).
2. Then submit to This Week in Neovim.
3. Post to r/neovim on a weekday morning that overlaps US and EU
   (roughly 14:00 UTC, Tuesday–Thursday).
4. Cross-post to Discourse and the Neovim Matrix/Discord plugins channel the
   same day.
5. Don't repost for at least a month.

Launching once, well, beats five half-hearted posts.

---

## 7. After launch

- Reply to every issue and comment for 48 hours.
- Turn feedback into issues and label a few `good first issue`.
- Cut `v0.2.0` after 2–3 real improvements; mention it in the next TWiN.
- Add a “Sponsors” section only when there are actual sponsors.
- Watch: stars, unique cloners (Insights → Traffic), issue quality, and
  dotfyle adoption.

Dotfyle indexes public Neovim plugins automatically; the topics above are what
it looks for. No separate submission is usually needed.

---

## 8. Monetization (honest version)

Latcher is MIT and already free. There is no realistic way to sell a
~700-line plugin directly. Revenue comes from attention and trust:

| Route | Effort | Realistic outcome |
|---|---|---|
| GitHub Sponsors | low | coffee money at first |
| Ko-fi / Polar one-offs | low | occasional donations |
| Consulting / custom plugins | medium | $75–150/h, the real opportunity |
| Paid Neovim course or config bundle | high | monetizes your expertise, not the plugin |
| Sponsorship tiers | medium | $3 supporter, $10 priority issues, $50+ consulting credit |

Rules:

- Never paywall code that is already MIT.
- No telemetry, ads, or crypto.
- Put the funding link in `.github/FUNDING.yml`, not in every issue reply.
- The plugin is a portfolio piece: the income is the work it leads to.
