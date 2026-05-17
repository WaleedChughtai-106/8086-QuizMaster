; ============================================================
; member2\member2.asm
; owner: Hassaan Raheel
; procedures: give_hint, read_num_timed, check_answer,
;             update_leaderboard, lb_copy_name,
;             lb_shift_names_12, lb_shift_names_01,
;             lb_shift_names_02
; ============================================================


; ----------------------------------------------------------
; give_hint
; shows the player a range that contains the correct answer
; ----------------------------------------------------------
give_hint proc

  cmp  hints_left, 0
  je   hint_none

  dec  hints_left
  mov  hint_used, 1
  print_nl
  print_str msg_hint_use

  ; lower bound is correct_ans minus 5, but never below 0
  mov  ax, correct_ans
  cmp  ax, 5
  jge  hint_sub
  mov  ax, 0
  jmp  hint_print_lo
hint_sub:
  sub  ax, 5
hint_print_lo:
  call print_num

  print_str msg_hint_and
  mov  ax, correct_ans
  add  ax, 5
  call print_num
  print_nl
  jmp  hint_done

hint_none:
  print_str msg_hint_no
hint_done:
  ret

give_hint endp


; ----------------------------------------------------------
; read_num_timed
; reads the player's answer while watching the clock
;
; instead of blocking on a keypress (int 21h ah=01h) we poll
; the keyboard status (int 21h ah=0bh) in a tight loop.
; between each poll we also check how many bios ticks have
; passed since the question appeared. if the elapsed count
; reaches time_limit (~300 ticks = ~16 seconds) we bail out
; and set time_up=1 so check_answer knows what happened.
;
; digits are accumulated in bx using the formula:
;   bx = bx * 10 + new_digit
; backspace reverses this with integer division bx / 10.
; we read with ah=08h (no echo) and echo digits ourselves
; so we can silently ignore non-digit keys.
; ----------------------------------------------------------
read_num_timed proc

  mov  time_up, 0
  mov  bx, 0

  ; snapshot the clock right before we start waiting
  get_timer
  mov  time_start, dx        ; dx = low word, enough for a 16s window

rnt_loop:
  ; check if a key is waiting without blocking
  mov  ah, 0bh
  int  21h
  cmp  al, 0ffh
  je   rnt_key               ; key is ready

  ; no key yet - check elapsed ticks
  get_timer
  mov  ax, dx
  sub  ax, time_start        ; elapsed = now - start
  cmp  ax, time_limit
  jge  rnt_timeout
  jmp  rnt_loop

rnt_timeout:
  mov  time_up, 1
  mov  user_ans, 0ffffh      ; sentinel so check_answer knows it timed out
  print_nl
  print_str msg_timeout
  ret

rnt_key:
  mov  ah, 08h               ; read without auto-echo so we control output
  int  21h

  cmp  al, 13                ; enter = submit
  je   rnt_done
  cmp  al, 'H'
  je   rnt_hint
  cmp  al, 'h'
  je   rnt_hint
  jmp  rnt_not_hint

rnt_hint:
  push bx
  call give_hint
  pop  bx
  print_str msg_prompt
  ; reset the clock so hint time does not count against the player
  get_timer
  mov  time_start, dx
  jmp  rnt_loop

rnt_not_hint:
  cmp  al, 8                 ; backspace
  jne  rnt_not_bs
  cmp  bx, 0
  je   rnt_loop
  ; strip the last digit by dividing bx by 10
  mov  ax, bx
  mov  cx, 10
  mov  dx, 0
  div  cx
  mov  bx, ax
  mov  ah, 02h
  mov  dl, 8
  int  21h
  mov  dl, ' '
  int  21h
  mov  dl, 8
  int  21h
  jmp  rnt_loop

rnt_not_bs:
  cmp  al, '0'
  jl   rnt_loop
  cmp  al, '9'
  jg   rnt_loop
  ; echo the digit ourselves since we read with ah=08h
  mov  ah, 02h
  mov  dl, al
  int  21h
  ; shift bx left one decimal place and add the new digit
  sub  al, '0'
  mov  temp_digit, al
  mov  ax, bx
  mov  cx, 10
  mul  cx
  mov  bx, ax
  mov  al, temp_digit
  mov  ah, 0
  add  bx, ax
  jmp  rnt_loop

rnt_done:
  mov  ax, bx
  mov  user_ans, ax
  ret

read_num_timed endp


; ----------------------------------------------------------
; check_answer
; compares the player's answer to the correct one and updates
; score, lives, streak and per-category counters accordingly
; ----------------------------------------------------------
check_answer proc

  ; if the timer ran out we skip the comparison and go straight
  ; to the wrong-answer path since the player did not answer
  cmp  time_up, 1
  je   ca_wrong_common

  print_nl
  mov  ax, user_ans
  cmp  ax, correct_ans
  je   ca_right

ca_wrong_common:
  mov  streak, 0
  dec  lives
  print_str msg_wrong
  mov  ax, correct_ans
  call print_num
  print_nl
  print_str msg_life_lost
  cmp  lives, 0
  jg   ca_done
  print_str msg_no_lives
  jmp  show_result

ca_right:
  inc  score
  inc  streak

  ; increment the counter for whichever operator was used
  cmp  operator, 0
  jne  ca_check_sub
  inc  score_add
  jmp  ca_cat_done
ca_check_sub:
  cmp  operator, 1
  jne  ca_inc_mul
  inc  score_sub
  jmp  ca_cat_done
ca_inc_mul:
  inc  score_mul
ca_cat_done:

  print_str msg_correct
  mov  al, streak
  cmp  al, 5
  je   ca_streak5
  cmp  al, 3
  je   ca_streak3
  jmp  ca_done
ca_streak5:
  print_str msg_streak5
  jmp  ca_done
ca_streak3:
  print_str msg_streak3
ca_done:
  ret

check_answer endp


; ----------------------------------------------------------
; update_leaderboard
; inserts the current score into the top-3 sorted array.
; this is a 3-element descending insertion sort.
; we compare against rank 0 first (the highest), then rank 1,
; then rank 2. when we find the right position we shift the
; lower entries down to make room and copy the player name
; into the matching name slot.
; ----------------------------------------------------------
update_leaderboard proc

  push ax
  push bx
  push cx
  push si
  push di

  mov  al, score

  cmp  al, lb_scores[0]
  jle  ul_check1

  ; new score is the best - push 0 down to 1, 1 down to 2
  mov  bl, lb_scores[1]
  mov  lb_scores[2], bl
  mov  bl, lb_scores[0]
  mov  lb_scores[1], bl
  mov  lb_scores[0], al
  call lb_shift_names_02
  call lb_shift_names_01
  mov  di, 0
  call lb_copy_name
  jmp  ul_done

ul_check1:
  cmp  al, lb_scores[1]
  jle  ul_check2

  ; second best - push 1 down to 2
  mov  bl, lb_scores[1]
  mov  lb_scores[2], bl
  mov  lb_scores[1], al
  call lb_shift_names_12
  mov  di, 8
  call lb_copy_name
  jmp  ul_done

ul_check2:
  cmp  al, lb_scores[2]
  jle  ul_done

  ; third best - just replace slot 2
  mov  lb_scores[2], al
  mov  di, 16
  call lb_copy_name

ul_done:
  pop  di
  pop  si
  pop  cx
  pop  bx
  pop  ax
  ret

update_leaderboard endp


; ----------------------------------------------------------
; lb_copy_name
; copies player_name into lb_names at byte offset di.
; always writes exactly 8 bytes, padding with '-' if the
; name is shorter than 8 characters.
; ----------------------------------------------------------
lb_copy_name proc

  push cx
  push si
  mov  si, 0
  mov  cx, 8

lcn_loop:
  mov  al, player_name[si]
  cmp  al, '$'
  je   lcn_pad
  mov  lb_names[di], al
  inc  si
  inc  di
  loop lcn_loop
  jmp  lcn_done

lcn_pad:
  mov  lb_names[di], '-'
  inc  di
  loop lcn_pad

lcn_done:
  pop  si
  pop  cx
  ret

lb_copy_name endp


; ----------------------------------------------------------
; lb_shift_names_12  - copies name slot 1 into slot 2
; lb_shift_names_01  - copies name slot 0 into slot 1
; lb_shift_names_02  - wrapper that calls lb_shift_names_12
;
; each name slot is 8 bytes inside lb_names.
; slot 0 starts at offset 0, slot 1 at offset 8, slot 2 at 16.
; ----------------------------------------------------------
lb_shift_names_12 proc
  push cx
  push si
  mov  si, 0
  mov  cx, 8
lb12_loop:
  mov  al, lb_names[si+8]
  mov  lb_names[si+16], al
  inc  si
  loop lb12_loop
  pop  si
  pop  cx
  ret
lb_shift_names_12 endp

lb_shift_names_01 proc
  push cx
  push si
  mov  si, 0
  mov  cx, 8
lb01_loop:
  mov  al, lb_names[si]
  mov  lb_names[si+8], al
  inc  si
  loop lb01_loop
  pop  si
  pop  cx
  ret
lb_shift_names_01 endp

lb_shift_names_02 proc
  call lb_shift_names_12
  ret
lb_shift_names_02 endp
