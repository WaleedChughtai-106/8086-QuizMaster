# Math Quiz Master v3.0
### CEN 323 — Computer Organization & Assembly Language (COAL)
**Instructor:** Adnan Jelani &nbsp;|&nbsp; **Phase 2 Deadline:** 17 May 2026 &nbsp;|&nbsp; **Bahria University, Islamabad**

---

## Project Description

Math Quiz Master is an interactive arithmetic quiz game written entirely in **8086 Assembly Language** and built to run in **emu8086**. The player answers 10 math questions under a live 16-second countdown timer. The game tracks lives, hints, answer streaks, per-category scores, and a top-3 leaderboard that persists across multiple rounds in the same session.

Everything — the random number generator, the timer, the leaderboard sort, the ring buffer, the player name input — is implemented using only 8086 ISA instructions and DOS/BIOS interrupts. No external libraries. No shortcuts.

---

## How to Run

1. Open **emu8086**
2. **File → Open** → navigate to the project folder and select **`Final_main.asm`**
3. Click **Compile**, then **Emulate**, then **Run**
4. Enter your name, pick a difficulty, and start playing

> `Final_main.asm` is the single compiled file for emu8086.  
> The `member1.asm`, `member2.asm`, `member3.asm` show the modular ownership structure documented below.

---

## File Structure

```
COAL Project/
│
├── Final_main.asm     ← open this in emu8086 to run the game
├── README.md             ← this file
│
├── member1.asm ← Waleed Ahmed's procedures
│
├──data.asm   ← Contains all the variables and messages + macros 
|  
├── Updated_member2.asm       ← Hassaan Raheel's procedures
│    
│
└── member3.asm       ← Dawood Bin Sajid's procedures
    
```

---

## Gameplay Features

| Feature | Detail |
|---|---|
| **3 Difficulty Levels** | Easy (1–15, +/−) · Medium (1–20, +/−/×) · Hard (1–30, +/−/×) |
| **16-Second Timer** | BIOS tick counter polled via INT 1Ah; timeout costs a life |
| **3 Lives** | Wrong answer or timeout deducts one life; 0 lives ends the game |
| **2 Hints Per Game** | Shows correct answer ± 5; timer resets during hint |
| **Streak Bonuses** | Special messages at 3 and 5 consecutive correct answers |
| **No-Repeat Questions** | Ring buffer of last 5 NUM1 values prevents duplicate questions |
| **Per-Category Scores** | Separate correct-answer count for +, − and × shown at end |
| **Top-3 Leaderboard** | Insertion sort; names and scores persist across replays |
| **Player Name Input** | Typed at start, stored in leaderboard, backspace supported |
| **Grade System** | A / B / C / F assigned based on final score |
| **Goodbye Screen** | Thank-you message displayed when the player exits |

---

## Assembly Concepts Covered

| # | Concept | Where Used |
|---|---|---|
| 1 | DOS Interrupts (INT 21h) | AH=01h, 02h, 08h, 09h, 0Bh, 4Ch throughout all procedures |
| 2 | BIOS Interrupts (INT 10h, 1Ah) | `clear_screen` macro (INT 10h), `get_timer` macro (INT 1Ah) |
| 3 | Macros | `print_str`, `print_nl`, `read_key`, `clear_screen`, `get_timer` |
| 4 | Procedures (PROC/ENDP) | 20+ procedures across all three modules |
| 5 | Conditional Jumps | JE, JNE, JGE, JL, JLE, JNZ, JCXZ throughout |
| 6 | Arithmetic Instructions | ADD, SUB, MUL, DIV in question generation and input handling |
| 7 | Stack (PUSH/POP) | Used in every procedure that must preserve registers |
| 8 | LOOP Instruction | Progress bar, digit printing, leaderboard name shifting |
| 9 | Shift Instructions (SHL/SHR) | LFSR feedback in `get_random`, DW offset in `update_history` |
| 10 | XOR / Logical Ops | LFSR tap bits in `get_random`, zero-flag trick in `check_history` |
| 11 | Arrays (DW/DB DUP) | `q_history` ring buffer, `lb_scores`, `lb_names` leaderboard |
| 12 | String I/O | `get_player_name`, all `print_str` macro calls |

---

## Team Contributions

| Member Name | Reg. Number | Module | Procedures Owned |
|---|---|---|---|
| **Waleed Ahmed** | 01-135232-106 | RNG · Question Generation · History · Player Name · Difficulty | `get_random` · `check_history` · `update_history` · `gen_question` · `get_player_name` · `select_difficulty` |
| **Hassaan Raheel** |01-135232-025 | Hint System · Timed Input · Answer Checking · Leaderboard Logic | `give_hint` · `read_num_timed` · `check_answer` · `update_leaderboard` · `lb_copy_name` · `lb_shift_names_*` |
| **Dawood Bin Sajid** | 01-135232-056 | All Display and UI · Result Screen · Leaderboard Display | `print_num` · `show_title` · `show_rules` · `show_status` · `show_progress` · `show_question` · `show_result` · `show_category_scores` · `show_leaderboard` · `print_lb_name` |


---

## GitHub Commit IDs

| Member | Commit IDs |
|---|---|
| Waleed Ahmed | WaleedChughtai-106|
| Hassaan Raheel | hassaan200416 |
| Dawood Bin Sajid | daudx |

---

## CCA Attribute Mapping

| Attribute | How This Project Satisfies It |
|---|---|
| **CCA1** Complex Problem-Solving | Multi-module program with non-linear flow: LFSR random number generation, BIOS timer polling loop, ring buffer history tracking, 3-element insertion sort leaderboard, and conditional state management across 20+ procedures |
| **CCA4** Design Constraints | Strictly within the 8086 ISA: 16-bit registers only, segmented memory model, DOS/BIOS interrupt conventions, no external libraries, no higher-level abstractions |
| **CCA8** Team Collaboration | Three members each own distinct, non-overlapping modules documented in this README and evidenced by individual GitHub commit history throughout the development period |

---

## AI Disclosure

Portions of this project were developed with assistance from Claude (Anthropic) for code structure, feature additions, macro integration, and bug fixing. All AI-assisted code has been reviewed, understood, and tested by each team member as required by Section 7.1 of the project brief.

---

## References

1. Intel Corporation. *8086 Family User's Manual*. Intel, 1979.
2. Irvine, K. R. *Assembly Language for x86 Processors*, 7th ed. Pearson, 2015.
3. Ralf Brown's Interrupt List — BIOS/DOS interrupt reference. [http://www.ctyme.com/rbrown.htm](http://www.ctyme.com/rbrown.htm)
4. Project GitHub Repository: https://github.com/WaleedChughtai-106/CEN323_G3_8086-QuizMaster
