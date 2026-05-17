; ############################################################
; ===                   MEMBER 2                           ===
; ###       GIVE_HINT | READ_NUM | CHECK_ANSWER             ###
; ############################################################

; ============================================================
; GIVE_HINT  -  Show ±5 range around correct answer
; ============================================================
GIVE_HINT PROC
  CMP  HINTS_LEFT, 0
  JE   HINT_NONE
  DEC  HINTS_LEFT
  MOV  HINT_USED, 1
  LEA  DX, NEWLINE
  MOV  AH, 09h
  INT  21h
  LEA  DX, MSG_HINT_USE
  MOV  AH, 09h
  INT  21h
  MOV  AX, CORRECT_ANS
  CMP  AX, 5
  JGE  HINT_SUB
  MOV  AX, 0
  JMP  HINT_PRINT_LO
HINT_SUB:
  SUB  AX, 5
HINT_PRINT_LO:
  CALL PRINT_NUM
  LEA  DX, MSG_HINT_AND
  MOV  AH, 09h
  INT  21h
  MOV  AX, CORRECT_ANS
  ADD  AX, 5
  CALL PRINT_NUM
  LEA  DX, NEWLINE
  MOV  AH, 09h
  INT  21h
  JMP  HINT_DONE
HINT_NONE:
  LEA  DX, MSG_HINT_NO
  MOV  AH, 09h
  INT  21h
HINT_DONE:
  RET
GIVE_HINT ENDP

; ============================================================
; READ_NUM  -  Read player input (digits, backspace, H=hint)
; ============================================================
READ_NUM PROC
  MOV  BX, 0
RN_LOOP:
  MOV  AH, 01h
  INT  21h
  CMP  AL, 13
  JE   RN_DONE
  CMP  AL, 'H'
  JE   RN_HINT
  CMP  AL, 'h'
  JE   RN_HINT
  JMP  RN_NOT_HINT
RN_HINT:
  PUSH BX
  CALL GIVE_HINT
  POP  BX
  LEA  DX, MSG_PROMPT
  MOV  AH, 09h
  INT  21h
  JMP  RN_LOOP
RN_NOT_HINT:
  CMP  AL, 8
  JNE  RN_NOT_BS
  CMP  BX, 0
  JE   RN_LOOP
  MOV  AX, BX
  MOV  CX, 10
  MOV  DX, 0
  DIV  CX
  MOV  BX, AX
  MOV  AH, 02h
  MOV  DL, 8
  INT  21h
  MOV  DL, ' '
  INT  21h
  MOV  DL, 8
  INT  21h
  JMP  RN_LOOP
RN_NOT_BS:
  CMP  AL, '0'
  JL   RN_LOOP
  CMP  AL, '9'
  JG   RN_LOOP
  SUB  AL, '0'
  MOV  TEMP_DIGIT, AL
  MOV  AX, BX
  MOV  CX, 10
  MUL  CX
  MOV  BX, AX
  MOV  AL, TEMP_DIGIT
  MOV  AH, 0
  ADD  BX, AX
  JMP  RN_LOOP
RN_DONE:
  MOV  AX, BX
  MOV  USER_ANS, AX
  RET
READ_NUM ENDP

; ============================================================
; CHECK_ANSWER  -  Validate answer, update score/lives/streak
; ============================================================
CHECK_ANSWER PROC
  LEA  DX, NEWLINE
  MOV  AH, 09h
  INT  21h
  MOV  AX, USER_ANS
  CMP  AX, CORRECT_ANS
  JE   CA_RIGHT
  MOV  STREAK, 0
  DEC  LIVES
  LEA  DX, MSG_WRONG
  MOV  AH, 09h
  INT  21h
  MOV  AX, CORRECT_ANS
  CALL PRINT_NUM
  LEA  DX, NEWLINE
  MOV  AH, 09h
  INT  21h
  LEA  DX, MSG_LIFE_LOST
  MOV  AH, 09h
  INT  21h
  CMP  LIVES, 0
  JG   CA_DONE
  LEA  DX, MSG_NO_LIVES
  MOV  AH, 09h
  INT  21h
  JMP  SHOW_RESULT
CA_RIGHT:
  INC  SCORE
  INC  STREAK
  LEA  DX, MSG_CORRECT
  MOV  AH, 09h
  INT  21h
  MOV  AL, STREAK
  CMP  AL, 5
  JE   CA_STREAK5
  CMP  AL, 3
  JE   CA_STREAK3
  JMP  CA_DONE
CA_STREAK5:
  LEA  DX, MSG_STREAK5
  MOV  AH, 09h
  INT  21h
  JMP  CA_DONE
CA_STREAK3:
  LEA  DX, MSG_STREAK3
  MOV  AH, 09h
  INT  21h
CA_DONE:
  RET
CHECK_ANSWER ENDP