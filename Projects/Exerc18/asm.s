        PUBLIC  __iar_program_start
        PUBLIC  __vector_table

        SECTION .text:CODE:REORDER(2)
        
        ;; Keep vector table even if it's not referenced
        REQUIRE __vector_table
        
        THUMB

; System Control definitions
SYSCTL_RCGCGPIO_R       EQU     0x400FE608
SYSCTL_PRGPIO_R		EQU     0x400FEA08
PORTF_BIT               EQU     0000000000100000b ; bit  5 = Port F
PORTJ_BIT               EQU     0000000100000000b ; bit  8 = Port J
PORTN_BIT               EQU     0001000000000000b ; bit 12 = Port N

; GPIO Port definitions
GPIO_PORTF_BASE    	EQU     0x4005D000
GPIO_PORTJ_BASE    	EQU     0x40060000
GPIO_PORTN_BASE    	EQU     0x40064000
GPIO_DIR                EQU     0x0400
GPIO_PUR                EQU     0x0510
GPIO_DEN                EQU     0x051C
GPIO_DAT                EQU     0x03FC


; PROGRAMA PRINCIPAL

__iar_program_start
        
main:   MOV R0, #(PORTN_BIT)
        ORR R0, #(PORTF_BIT)
        ORR R0, #(PORTJ_BIT)
	BL GPIO_enable ; habilita clock ao port N
        
	LDR R0, =GPIO_PORTN_BASE
        MOV R1, #00000011b ; bits 0 e 1 como saída (LEDs D1 e D2)
        BL GPIO_digital_output
        
        LDR R0, =GPIO_PORTF_BASE
        MOV R1, #00010001b ; bits 0 e 3 como saída (LEDs D3 e D4)
        BL GPIO_digital_output
        
        LDR R0, =GPIO_PORTJ_BASE
        MOV R1, #00000011b 
        BL GPIO_digital_input
        
        MOV R0 , #0
loop:   BL Set_Leds; aciona LEDs D1 e D2
        BL Sel_Operation
        PUSH {R0}
        MOVT R0, #0x000F
        BL SW_delay ; atraso (determina frequência de acionamento)
        POP {R0}
        
        //EOR R2, R2, #11b ; inverte o padrão de acionamento
        B loop


; SUB-ROTINAS

; GPIO_enable: habilita clock para os ports de GPIO selecionados em R0
; R0 = padrão de bits de habilitação dos ports
GPIO_enable:
        LDR R2, =SYSCTL_RCGCGPIO_R
	LDR R1, [R2]
	ORR R1, R0 ; habilita ports selecionados
	STR R1, [R2]

        LDR R2, =SYSCTL_PRGPIO_R
wait	LDR R0, [R2]
	TEQ R0, R1 ; clock dos ports habilitados?
	BNE wait

        BX LR

; GPIO_digital_output: habilita saídas digitais no port de GPIO desejado
; R0 = endereço base do port desejado
; R1 = padrão de bits (1) a serem habilitados como saídas digitais
GPIO_digital_output:
	LDR R2, [R0, #GPIO_DIR]
	ORR R2, R1 ; configura bits de saída
	STR R2, [R0, #GPIO_DIR]

	LDR R2, [R0, #GPIO_DEN]
	ORR R2, R1 ; habilita função digital
	STR R2, [R0, #GPIO_DEN]

        BX LR
        
; GPIO_digital_input: habilita entradas digitais no port de GPIO desejado
; R0 = endereço base do port desejado
; R1 = padrão de bits (1) a serem habilitados como entradas digitais
GPIO_digital_input:
	LDR R2, [R0, #GPIO_DIR]
	BIC R2, R1 ; configura bits de entrada
	STR R2, [R0, #GPIO_DIR]

	LDR R2, [R0, #GPIO_DEN]
	ORR R2, R1 ; habilita função digital
	STR R2, [R0, #GPIO_DEN]

	LDR R2, [R0, #GPIO_PUR]
	ORR R2, R1 ; habilita resitor de pull-up
	STR R2, [R0, #GPIO_PUR]

        BX LR

; -------------------------------------------------------------------------------
; Fun??o PortF_Output
; Par?metro de entrada: R0 --> se os BIT4 e BIT0 est?o ligado ou desligado
; Par?metro de sa?da: N?o tem
PortF_Output:
	LDR	R1, =GPIO_PORTF_BASE		    ;Carrega o valor do offset do data register
        ORR     R1 , #GPIO_DAT
	;Read-Modify-Write para escrita
	LDR R2, [R1]
	BIC R2, #00010001b                     ;Primeiro limpamos os dois bits do lido da porta R2 = R2 & 11101110b
	ORR R0, R0, R2                          ;Fazer o OR do lido pela porta com o par?metro de entrada
	STR R0, [R1]                            ;Escreve na porta F o barramento de dados dos pinos F4 e F0
	BX LR									;Retorno
; -------------------------------------------------------------------------------
; Fun??o PortN_Output
; Par?metro de entrada: R0 --> se os BIT1 e BIT0 est?o ligado ou desligado
; Par?metro de sa?da: N?o tem
PortN_Output:
	LDR	R1, =GPIO_PORTN_BASE		    ;Carrega o valor do offset do data register
        ORR     R1 , #GPIO_DAT
	;Read-Modify-Write para escrita
	LDR R2, [R1]
	BIC R2, #00000011b                     ;Primeiro limpamos os dois bits do lido da porta R2 = R2 & 11101110
	ORR R0, R0, R2                          ;Fazer o OR do lido pela porta com o par?metro de entrada
	STR R0, [R1]                            ;Escreve na porta N o barramento de dados dos pinos N1 e N0
	BX LR									;Retorno
	
; -------------------------------------------------------------------------------
; Fun??o PortJ_Input
; Par?metro de entrada: N?o tem
; Par?metro de sa?da: R0 --> o valor da leitura
PortJ_Input
	LDR	R1, =GPIO_PORTJ_BASE		    ;Carrega o valor do offset do data register
        ORR     R1, #GPIO_DAT
	LDR R0, [R1]                            ;L? no barramento de dados dos pinos [J1-J0]
        
	BX LR									;Retorno

; SW_delay: atraso de tempo por software
; R0 = valor do atraso
SW_delay:
        CBZ R0, out_delay
        SUB R0, R0, #1
        B SW_delay        
out_delay:
        BX LR
        
; -------------------------------------------------------------------------------
; Fun??o Set Leds
; Par?metro de entrada: R0 
; Par?metro de sa?da: N?o tem
Set_Leds:	
	; CLEAR LEDs
	PUSH {LR,R0}
	MOV R0 , #0
	BL PortF_Output
	MOV R0 , #0
	BL PortN_Output
	POP {LR,R0}	
Set_LEDs_1_2	
	AND R1 , R0 , #0x08
	AND R2 , R0 , #0x04
	ORR R1 , R1 , R2
	PUSH {LR,R0}
	MOV R0 , R1 , LSR  #2
	BL PortN_Output
	POP {LR,R0}	
Set_LEDs_3_4
	AND R1 , R0 , #0x02
	LSL R1 , #3
	AND R2 , R0 , #0x01
	ORR R1 , R1 , R2
	PUSH {LR,R0}
	MOV R0 , R1 
	BL PortF_Output
	POP {LR,R0}
	
	BX LR
        
; -------------------------------------------------------------------------------
; Fun??o Sel Operation
; Par?metro de entrada: R0 -> status
; Par?metro de sa?da: R0 -> new status
Sel_Operation:
        PUSH {R0,LR}
        BL PortJ_Input
        CMP R0 , #2
        BEQ SW1
        CMP R0 , #1
        BEQ SW2
        POP {R0,LR}
        BX LR
SW1     
        POP {R0,LR}
        ADD R0 , #1
        BX LR
SW2     
        POP {R0,LR}
        SUB R0 , #1
        BX LR
                

; TABELA DE VETORES DE INTERRUPÇÂO

        ;; Forward declaration of sections.
        SECTION CSTACK:DATA:NOROOT(3)
        SECTION .intvec:CODE:NOROOT(2)
        
        DATA

__vector_table
        DCD     sfe(CSTACK)
        DCD     __iar_program_start

        DCD     NMI_Handler
        DCD     HardFault_Handler
        DCD     MemManage_Handler
        DCD     BusFault_Handler
        DCD     UsageFault_Handler
        DCD     0
        DCD     0
        DCD     0
        DCD     0
        DCD     SVC_Handler
        DCD     DebugMon_Handler
        DCD     0
        DCD     PendSV_Handler
        DCD     SysTick_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Default interrupt handlers.
;;

        PUBWEAK NMI_Handler
        PUBWEAK HardFault_Handler
        PUBWEAK MemManage_Handler
        PUBWEAK BusFault_Handler
        PUBWEAK UsageFault_Handler
        PUBWEAK SVC_Handler
        PUBWEAK DebugMon_Handler
        PUBWEAK PendSV_Handler
        PUBWEAK SysTick_Handler

        SECTION .text:CODE:REORDER:NOROOT(1)
        THUMB

NMI_Handler
HardFault_Handler
MemManage_Handler
BusFault_Handler
UsageFault_Handler
SVC_Handler
DebugMon_Handler
PendSV_Handler
SysTick_Handler
Default_Handler
__default_handler
        CALL_GRAPH_ROOT __default_handler, "interrupt"
        NOCALL __default_handler
        B __default_handler

        END
