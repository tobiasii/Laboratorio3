        PUBLIC  __iar_program_start
        PUBLIC  __vector_table

        SECTION .text:CODE:REORDER(2)
        
        ;; Keep vector table even if it's not referenced
        REQUIRE __vector_table
        
        THUMB

SYSCTL_RCGCGPIO_R       EQU     0x400FE608
SYSCTL_PRGPIO_R		EQU     0x400FEA08
PORTN_BIT               EQU     1000000000000b ; bit 12 = Port N
PORTF_BIT               EQU     0000000100000b ;
PORTJ_BIT               EQU     0000100000000b ; 

GPIO_PORTN_BASE    	EQU     0x40064000
GPIO_PORTF_BASE    	EQU     0x4005D000
GPIO_PORTJ_BASE         EQU     0x40060000

GPIO_PORT_DATA_R         EQU     0x000
GPIO_PORT_DIR_R     	EQU     0x400
GPIO_PORT_DEN_R     	EQU     0x51C
__iar_program_start
        
main    MOV R2, #PORTN_BIT
        ORR R2, #PORTF_BIT
        ORR R2, #PORTJ_BIT
	LDR R0, =SYSCTL_RCGCGPIO_R
	LDR R1, [R0] ; leitura do estado anterior
	ORR R1, R2 ; habilita port N
	STR R1, [R0] ; escrita do novo estado

        LDR R0, =SYSCTL_PRGPIO_R
wait	LDR R2, [R0] ; leitura do estado atual
	TEQ R1, R2 ; clock do port N habilitado?
	BNE wait ; caso negativo, aguarda

        MOV R2, #00000001b ; bit 0
        
	LDR R0, =GPIO_PORTN_DIR_R
	LDR R1, [R0] ; leitura do estado anterior
	ORR R1, R2 ; bit de saída
	STR R1, [R0] ; escrita do novo estado

	LDR R0, =GPIO_PORTN_DEN_R
	LDR R1, [R0] ; leitura do estado anterior
	ORR R1, R2 ; habilita função digital
	STR R1, [R0] ; escrita do novo estado

        MOV R1, #000000001b ; estado inicial
 	LDR R0, = GPIO_PORTN_DATA_R
//        MOV R2, #0x3FC
//loop    LDR R4, [R0, R2]
//        EOR R4, R1
//        STR R4, [R0, R2]
loop	STR R1, [R0, R2, LSL #2] ; aciona LED com estado atual
        MOVT R3, #0x000F ; constante de atraso 
delay   CBZ R3, theend ; 1 clock
        SUB R3, R3, #1 ; 1 clock
        B delay ; 3 clocks
theend  EOR R1, R1, R2 ; troca o estado
        B loop

PortF_Output
        PUSH R1 , R2
	LDR	R1, =GPIO_PORTF_BASE   ;Carrega o valor do offset do data register
	;Read-Modify-Write para escrita
	LDR R2, [R1 , #GPIO_PORT_DATA_R ]
	BIC R2, #00010001b   ;Primeiro limpamos os dois bits do lido da porta R2 = R2 & 11101110
	ORR R0, R0, R2        ;Fazer o OR do lido pela porta com o par?metro de entrada
	STR R0, [R1 , #GPIO_PORT_DATA_R ];Escreve na porta F o barramento de dados dos pinos F4 e F0
	BX LR
									;Retorno
PortN_Output

	LDR	R1, =GPIO_PORTN_BASE		    ;Carrega o valor do offset do data register
	;Read-Modify-Write para escrita
	LDR R2, [R1, #GPIO_PORT_DATA_R]
	BIC R2, #00000011b                     
	ORR R0, R0, R2                          
	STR R0, [R1, #GPIO_PORT_DATA_R]                            
	BX LR									

Leds_ON
        
        PortN_Output 
        

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
