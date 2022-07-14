;Name:Youssef Samuel Nachaat
;ATM MACHINE CHECKER
;The user enters in decimal his card number (16 bits) which means from 0 to 65535, and his password (4 bits), from 0 to 15.
;If the data of the user matches with one of the 20 customers in the database --> output 1 ELSE 0
org 100H
.DATA      
    MSG0 DB "Welcome to my ATM Machine!$" ;0AH --> NEW LINE, 0DH --> CREATE
    MSG1 DB 0AH,0DH,"Card Number:$"
    MSG2 DB 0AH,0DH,"Password:$" 
    MSG5 DB 0AH,0DH,"ALLOWED: 1$"
    MSG6 DB 0AH,0DH,"DENIED: 0$"
    MSG7 DB 0AH,0DH,"For a new customer press 1, else press 0: $"
    MSG8 DB 0AH,0DH,"Incorrect Card Number $" 
    MSG9 DB 0AH,0DH,"Incorrect Password $"  
    PASSWORD DB 0
    CARDNUM DW 0    
    INPUT DW 0   
    TST DW 0 ;TO CHECK FOR RANGE ALLOWED. 
    LASTDGT DW 06H 
    TENMUL DW 10 ;0AH
    MESSAGE2 DB 0AH,0DH,"Out of range! Please re-enter your input:$"
;##########################################################################
.CODE   
    ASSUME DS:DATA,CS:CODE   
START:      
;CONSTRUCT DATABASE:
    CALL CONST
;PRINT A WELCOME MESSAGE:    
    MOV AX,@DATA
    MOV DS,AX 
    LEA DX,MSG0
    MOV AH,09H ;WRITE STRING TO STDOUT
    INT 21H                            
GO:
;READ THE 16 BITS CARD NUMBER:0 --> 65535 DECIMAL. 0000H --> FFFFH HEXADECIMAL  
    MOV TST,1999H 
;INPUT MESSAGE FOR USER      
    LEA DX,MSG1
    MOV AH,09H 
    INT 21H
;GET THE CARD NUMBER     
    CALL READINPUT 
    MOV AX,INPUT
    MOV CARDNUM,AX 
;READ THE 4-BITS PASSWORD:0 --> 15 IN DECIMAL. 0H --> FH IN HEXADECIMAL      
    MOV TST,01H
;INPUT MESSAGE      
    LEA DX,MSG2
    MOV AH,09H 
    INT 21H 
;GET THE PASSWORD    
    CALL READINPUT
    MOV AX,INPUT
    MOV PASSWORD,AL                               
;STORE THE INPUTS IN AX AND DL    
    MOV AX,CARDNUM
    MOV DL,PASSWORD 
;VALIDATION CHECK      
    CALL CHECK  
    CMP AL,31H
    JE GO  ;TO CHECK ANOTHER CARD
    HLT
;##########################################################################
;PROCEDURES 
;CONSTRUCT THE DATABASE  
CONST PROC NEAR
    MOV AX,2000H 
    MOV DS,AX    ;DS = 2000H
    MOV DI,1000H ;PHYSICAL ADDRESS OF FIRST STORED WORD = 21000H
    MOV CX,20    ;20 CUSTOMERS
    MOV AX,8000H ;CARD NUMBER OF FIRST CUSTOMER = 8000H = 32768 IN DECIMAL (WILL BE DECREMENTED BY 1 FOR EACH NEXT CUSTOMER)
    MOV DL,00H   ;PASSWORD OF FIRST CUSTOMER = 0 (WILL BE INCREMENTED BY 1 FOR EACH NEXT CUSTOMER)
DATABASE:    
    MOV [DI],AX  ;STORE CARD NUMBER
    ADD DI,2
    MOV [DI],DL  ;STORE PASSWORD
    INC DI
    SUB AX,1
    INC DL
    CMP DL,10H   ;IF DL = 10H = 16DECIMAL (OUT OF RANGE) --> DL = 0
    JNZ DL4bits
    MOV DL,00H
DL4BITS:
    LOOP DATABASE
    RET
CONST ENDP 
;READ THE INPUT
READINPUT PROC NEAR
BGN:     
    MOV INPUT, 0  
READ:
    MOV AH,01H ;READ 1 CHARACTER
    INT 21H 
    
    CMP AL, 0DH ;CHECK IF ENTER KEY IS PRESSED
    JE OK  
    CMP AL, 08H ;CHECK IF BACKSPACE IS PRESSED
    JE DELETE
    CMP AL, 30H ;CHECK THAT THE INPUT IS 0-->9
    JB INVALID
    CMP AL,39H
    JA INVALID
    JMP H   
    
DELETE:
    MOV DL, 20H ;SPACE
    MOV AH,02H  ;WRITE CHARACTER TO STDOUT
    INT 21H 
    MOV DL, 08H ;BACKSPACE
    MOV AH,02H 
    INT 21H     
    MOV AX, INPUT
    MOV DX, 0000H ;DOUBLE WORD BY WORD DIVISION
    DIV TENMUL ;PUT RESULT IN AX
    MOV INPUT, AX
    JMP INVALID
H:    
    SUB AL,30H ;CONVERT FROM ASCII TO HEX
    MOV AH,00H
    MOV BX,AX 
    MOV AX,INPUT
    CMP AX,TST 
    JB  CONTINUE ;IF THE LAST INPUT < TST (1999H=6553 (CASE 1) OR 01H (CASE 2)): NO PROBLEM
    JE  CHECKLAST ;IF = TST , WE HAVE TO CHECK THE CURRENT INPUT DIGIT 
    JMP OUTRANGE ;IF > TST, OUT OF ALLOWED RANGE, IT WILL BE MULTUPLIED BY 10 THEN ADD THE NEXT DIGIT, SO IT IS SURELY OUT OF RANGE
CHECKLAST:
    CMP BX,LASTDGT ;WHEN LAST INPUT = TST (6553*10 = 65530 OR 1*10=10), MAX NEW DIGIT MUST BE LESS THAN OR EQUAL TO 5 IN BOTH CASES  
    JB  CONTINUE
    JMP OUTRANGE  ;STARTING FROM 65536 OR 16 --> OUT OF ALLOWED RANGE
CONTINUE:
    MUL TENMUL 
    ADD AX,BX
    MOV INPUT,AX ;STORE CURRENT INPUT IN INPUT  
INVALID:
    JMP READ
OUTRANGE:
    ;PRINT OUT OF RANGE TRY AGAIN 
    LEA DX,MESSAGE2
    MOV AH,09H  
    INT 21H
    JMP BGN  
OK:
    RET   
READINPUT ENDP
;CHECK   
CHECK PROC NEAR
    MOV BX,2000H
    MOV DS,BX
    MOV DI,1000H
    MOV CX,20 ;WE HAVE 20 CUSTOMERS
SEARCH:    
    CMP [DI],AX ;FIRST COMPARE THE CARD NUMBER
    JNE NOTCUST ;IF NOT THE SAME, SO INCREASE DI BY 3 TO GET THE NEXT CUSTOMER, ELSE CHECK THE PASSWORD
    ADD DI,2  ;INCREASE DI BY 2 TO GET THE PASSWORD
    CMP [DI],DL ;IF SAME PASSWORD --> ALLOWED, ELSE --> NOT ALLOWED.
    JE FOUND
    JNE DENIED        
NOTCUST:
    ADD DI, 3
    JMP K
NEXT:
    INC DI
K:                    
    LOOP SEARCH
;INCORRECT CARD NUMBER    
    MOV AX,@DATA
    MOV DS,AX  
    LEA DX,MSG8
    MOV AH,09H 
    INT 21H
    JMP NOTFOUND          
DENIED:
;INCORRECT PASSWORD 
    MOV AX,@DATA
    MOV DS,AX            
    LEA DX,MSG9
    MOV AH,09H 
    INT 21H    
NOTFOUND:      
    ;ACCESS DENIED 
    MOV AX,@DATA
    MOV DS,AX  
    LEA DX,MSG6
    MOV AH,09H 
    INT 21H 
    JMP FINISH    
FOUND:  
    ;ACCESS ALLOWED
    MOV AX,@DATA
    MOV DS,AX   
    LEA DX,MSG5
    MOV AH,09H 
    INT 21H  
FINISH: 
    LEA DX,MSG7
    MOV AH,09H 
    INT 21H
    MOV AH,01H
    INT 21H 
    RET 
CHECK ENDP   