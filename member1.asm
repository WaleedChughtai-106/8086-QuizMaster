; ============================================================
; member1\member1.asm
; owner: Waleed Ahmed
; procedures: get_random, check_history, update_history,
;             gen_question, get_player_name, select_difficulty
; ============================================================


; ----------------------------------------------------------
; get_random
; returns a number between 1 and bx (inclusive)
; uses a 16-bit linear feedback shift register (lfsr)
; ----------------------------------------------------------
get_random proc

  mov  ax, rand_seed

  ; lfsr works by xoring specific bits together to produce
  ; a feedback bit, then shifting the whole register right.
  ; we tap bits 15, 13, 12 and 10 - this combination gives
  ; the longest possible sequence before it repeats (65535).
  mov  dx, ax
  and  dx, 8000h             ; isolate bit 15

  mov  cx, ax
  and  cx, 2000h             ; bit 13
  shl  cx, 2
  xor  dx, cx

  mov  cx, ax
  and  cx, 1000h             ; bit 12
  shl  cx, 3
  xor  dx, cx

  mov  cx, ax
  and  cx, 0400h             ; bit 10
  shl  cx, 5
  xor  dx, cx

  shr  ax, 1                 ; shift the register right by one
  or   ax, dx                ; put the feedback bit into the top
  mov  rand_seed, ax

  ; map the 16-bit result into the range 1..bx using remainder
  mov  dx, 0
  div  bx                    ; dx = ax mod bx  (gives 0 to bx-1)
  mov  ax, dx
  inc  ax                    ; shift up to 1-based
  ret

get_random endp


; ----------------------------------------------------------
; check_history
; checks if num1 was used in the last 5 questions
; returns: zero flag set (je) = it is a repeat
;          zero flag clear    = safe to use
; ----------------------------------------------------------
check_history proc

  push cx
  push si

  mov  si, 0
  mov  cx, 5
  mov  ax, num1

ch_loop:
  cmp  ax, q_history[si]
  je   ch_found
  add  si, 2                 ; each slot is a word (2 bytes)
  loop ch_loop

  ; not found - clear zero flag so caller knows it is safe
  or   ax, ax
  pop  si
  pop  cx
  ret

ch_found:
  ; set zero flag to signal a repeat to the caller
  xor  ax, ax
  cmp  ax, 0
  pop  si
  pop  cx
  ret

check_history endp


; ----------------------------------------------------------
; update_history
; saves the current num1 into the ring buffer
; ----------------------------------------------------------
update_history proc

  push ax
  push si

  ; the ring buffer stores words (2 bytes each), so we multiply
  ; the index by 2 to get the correct byte offset into q_history
  mov  al, hist_idx
  mov  ah, 0
  shl  ax, 1
  mov  si, ax

  mov  ax, num1
  mov  q_history[si], ax

  ; advance the index and wrap back to 0 after slot 4
  mov  al, hist_idx
  inc  al
  cmp  al, 5
  jl   uh_save
  mov  al, 0
uh_save:
  mov  hist_idx, al

  pop  si
  pop  ax
  ret

update_history endp


; ----------------------------------------------------------
; gen_question
; picks an operator, generates two numbers, calculates the
; correct answer, and checks history to avoid repeats
; ----------------------------------------------------------
gen_question proc

  mov  hint_used, 0

  ; pick how many operators to choose from based on difficulty
  ; easy only gets + and -, medium and hard also get multiply
  mov  bl, difficulty
  cmp  bl, 1
  jne  gq_not_easy
  mov  bx, 2
  jmp  gq_get_op
gq_not_easy:
  mov  bx, 3

gq_get_op:
  call get_random
  dec  ax                    ; make it 0-based (0=add, 1=sub, 2=mul)
  mov  operator, al

gq_try:
  mov  bx, num_range
  call get_random
  mov  num1, ax
  call check_history
  je   gq_repeat             ; this num1 was used recently, try again

  mov  bx, num_range
  call get_random
  mov  num2, ax

  ; for subtraction we swap if num1 < num2 so the answer stays positive
  cmp  operator, 1
  jne  gq_calc
  mov  ax, num1
  cmp  ax, num2
  jge  gq_calc
  mov  cx, num2
  mov  num2, ax
  mov  num1, cx
  jmp  gq_calc

gq_repeat:
  print_str msg_skip_rep
  jmp  gq_try

gq_calc:
  mov  ax, num1
  cmp  operator, 0
  je   gq_add
  cmp  operator, 1
  je   gq_sub
  mul  num2
  jmp  gq_save
gq_add:
  add  ax, num2
  jmp  gq_save
gq_sub:
  sub  ax, num2
gq_save:
  mov  correct_ans, ax
  call update_history
  ret

gen_question endp


; ----------------------------------------------------------
; New feature: get_player_name
; reads up to 8 characters from the keyboard
; handles backspace and enforces the length limit
; ----------------------------------------------------------
get_player_name proc

  print_str msg_name_p
  mov  si, 0
  mov  name_len, 0

gpn_loop:
  read_key
  cmp  al, 13                ; enter key ends input
  je   gpn_done
  cmp  al, 8                 ; backspace
  je   gpn_bs
  cmp  si, 8                 ; ignore input once 8 chars are stored
  jge  gpn_loop
  mov  player_name[si], al
  inc  si
  inc  name_len
  jmp  gpn_loop

gpn_bs:
  cmp  si, 0
  je   gpn_loop
  dec  si
  dec  name_len
  mov  player_name[si], '$'
  ; erase the character on screen: backspace, space, backspace
  mov  ah, 02h
  mov  dl, 8
  int  21h
  mov  dl, ' '
  int  21h
  mov  dl, 8
  int  21h
  jmp  gpn_loop

gpn_done:
  mov  player_name[si], '$'  ; dollar sign terminates the string for int 21h
  print_nl
  ret

get_player_name endp


; ----------------------------------------------------------
; select_difficulty
; shows the menu and sets difficulty and num_range
; ----------------------------------------------------------
select_difficulty proc

  print_str msg_diff
  print_str msg_d1
  print_str msg_d2
  print_str msg_d3
  print_str msg_dchoice

sd_read:
  read_key
  cmp  al, '1'
  je   sd_easy
  cmp  al, '2'
  je   sd_med
  cmp  al, '3'
  je   sd_hard
  print_nl
  print_str msg_dinvalid
  print_str msg_dchoice
  jmp  sd_read

sd_easy:
  mov  difficulty, 1
  mov  num_range, 15
  jmp  sd_done
sd_med:
  mov  difficulty, 2
  mov  num_range, 20
  jmp  sd_done
sd_hard:
  mov  difficulty, 3
  mov  num_range, 30
sd_done:
  print_nl
  ret

select_difficulty endp
