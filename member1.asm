; member 1 section
; random generation, question making, difficulty selection

get_random proc
  ; load previous seed value
  mov  ax, rand_seed

  ; start building new random bits using xor feedback (lfsr idea)
  ; we pick some bits and mix them

  mov  dx, ax
  and  dx, 8000h        ; gets highest bit

  mov  cx, ax
  and  cx, 2000h        ; takes another bit
  shl  cx, 2            ; shifts it left so positions match
  xor  dx, cx           ; mixes bits using xor

  mov  cx, ax
  and  cx, 1000h
  shl  cx, 3
  xor  dx, cx

  mov  cx, ax
  and  cx, 0400h
  shl  cx, 5
  xor  dx, cx

  ; shift number right and insert new calculated bit
  shr  ax, 1
  or   ax, dx

  ; save updated seed for next time
  mov  rand_seed, ax

  ; now limit number within range 1 to bx
  ; division gives remainder in dx
  mov  dx, 0
  div  bx
  mov  ax, dx           ; remainder is our random value
  inc  ax               ; make it 1-based instead of 0-based

  ret
get_random endp


gen_question proc
  ; reset hint flag for new question
  mov  hint_used, 0

  ; choose operator based on difficulty
  mov  bl, difficulty
  cmp  bl, 1
  jne  gq_not_easy

  mov  bx, 2        ; easy ? only + and -
  jmp  gq_get_op

gq_not_easy:
  mov  bx, 3        ; medium/hard ? +, -, *

gq_get_op:
  call get_random
  dec  ax           ; convert to 0-based (0,1,2)
  mov  operator, al

  ; generate first number
  mov  bx, num_range
  call get_random
  mov  num1, ax

  ; generate second number
  mov  bx, num_range
  call get_random
  mov  num2, ax

  ; if operator is subtraction, avoid negative answers
  cmp  operator, 1
  jne  gq_calc

  mov  ax, num1
  cmp  ax, num2
  jge  gq_calc

  ; swap numbers so num1 >= num2
  ; simple trick to keep answer positive
  mov  cx, num2
  mov  num2, ax
  mov  num1, cx

gq_calc:
  mov  ax, num1

  cmp  operator, 0
  je   gq_add

  cmp  operator, 1
  je   gq_sub

  ; multiplication case
  mul  num2          ; ax = num1 * num2
  jmp  gq_save

gq_add:
  add  ax, num2
  jmp  gq_save

gq_sub:
  sub  ax, num2

gq_save:
  ; store final correct answer
  mov  correct_ans, ax
  ret
gen_question endp


select_difficulty proc
  ; print difficulty options on screen
  lea  dx, msg_diff
  mov  ah, 09h
  int  21h

  lea  dx, msg_d1
  mov  ah, 09h
  int  21h

  lea  dx, msg_d2
  mov  ah, 09h
  int  21h

  lea  dx, msg_d3
  mov  ah, 09h
  int  21h

  lea  dx, msg_dchoice
  mov  ah, 09h
  int  21h

sd_read:
  ; read single key input from user
  mov  ah, 01h
  int  21h

  ; check what user entered
  cmp  al, '1'
  je   sd_easy

  cmp  al, '2'
  je   sd_med

  cmp  al, '3'
  je   sd_hard

  ; if input is wrong, show message and ask again
  lea  dx, newline
  mov  ah, 09h
  int  21h

  lea  dx, msg_dinvalid
  mov  ah, 09h
  int  21h

  lea  dx, msg_dchoice
  mov  ah, 09h
  int  21h

  jmp  sd_read

sd_easy:
  mov  difficulty, 1
  mov  num_range, 15   ; small numbers
  jmp  sd_done

sd_med:
  mov  difficulty, 2
  mov  num_range, 20   ; medium numbers
  jmp  sd_done

sd_hard:
  mov  difficulty, 3
  mov  num_range, 30   ; larger numbers

sd_done:
  ; just move to next line after selection
  lea  dx, newline
  mov  ah, 09h
  int  21h
  ret
select_difficulty endp