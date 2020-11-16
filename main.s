
.globl _start
_start:     		ldr pc,reset_handler_d		// Exception vector
					ldr pc,undefined_handler_d
					ldr pc,swi_handler_d
					ldr pc,prefetch_handler_d
					ldr pc,data_handler_d
					ldr pc,unused_handler_d
					ldr pc,irq_handler_d
					ldr pc,fiq_handler_d

reset_handler_d:    .word reset_handler
undefined_handler_d:.word hang
swi_handler_d:      .word swi_handler
prefetch_handler_d: .word hang
data_handler_d:     .word hang
unused_handler_d:   .word hang
irq_handler_d:      .word hang
fiq_handler_d:      .word hang

UARTDR:				.word 0x101f1000			// UART data register address
UARTFR:				.word 0x101f1018			// UART flag register address

reset_handler:		mov r0,#0x10000				// Copy exception vector
					mov r1,#0x00000
					ldmia r0!,{r2,r3,r4,r5,r6,r7,r8,r9}
					stmia r1!,{r2,r3,r4,r5,r6,r7,r8,r9}
					ldmia r0!,{r2,r3,r4,r5,r6,r7,r8,r9}
					stmia r1!,{r2,r3,r4,r5,r6,r7,r8,r9}
					msr cpsr_c,#0xD1			// FIQ 110 10001
					mov sp,#0x100000
					msr cpsr_c,#0xD2			// IRQ 110 10010
					mov sp,#0x200000
					msr cpsr_c,#0xD3			// SVC 110 10011
					mov sp,#0x300000
					msr cpsr_c,#0xD7			// ABT 110 10111
					mov sp,#0x400000
					msr cpsr_c,#0xDB			// UND 110 11011
					mov sp,#0x500000
					msr cpsr_c,#0xDF			// SYS 110 11111
					mov sp,#0x600000
					msr cpsr_c,#0xD0			// USER 110 10000
					mov sp,#0x700000
					b main						// start main
    
hang:				b hang				

str_swi:            .asciz      "swi "
mensaje_error:			.asciz "Parametro desconocido \n"
mensaje_hab:		.asciz "Habilitado"
mensaje_deshab:		.asciz "Deshabilitado"
mensaje_error_nom_variable:		.asciz "Solo puede contener numeros y letras."
					.align
swi_handler:         stmfd sp!,{r0-r9,lr}            // SWI handler routine
                    ldr r5,[lr,#-4]			//Carga la posici?n de memoria desde donde se llam?
                    bic r5,r5,#0xff000000   //Separa la instruccion swi del numero que nos interesa
					
activarIrq:			cmp r5,#100				//En el caso de que el numero sea un 100, activar? las irq
                    bne desactivarIrq
                    mrs r0,spsr				//Mueve el spsr a r0
                    bic r0,r0,#0x00000080	//Pone a 0 el bit 7 para activar las irq
                    msr spsr,r0				//Mueve r0 al spsr con el bit modificado
                    ldr r0,=mensaje_hab		//Imprime mensaje habilitado
                    bl printString
                    b fin

desactivarIrq:      cmp r5,#101			  	//En el caso de que el numero sea un 101, desactivar? las irq
                    bne activarFiq
                    mrs r0,spsr			  	//Mueve el spsr a r0
                    orr r0,r0,#0x00000080 	//Pone a 1 el bit 7 para desactivar las irq
                    msr spsr,r0			  	//Mueve r0 al spsr con el bit modificado
                    ldr r0,=mensaje_deshab 	//Imprime mensaje deshabilitado
                    bl printString
                    b fin

activarFiq:			cmp r5,#200				//En el caso de que el numero sea un 200, activar? las fiq
                    bne desactivarFiq		
                    mrs r0,spsr				//Mueve el spsr a r0
                    bic r0,r0,#0x00000040 	//Pone a 0 el bit 6 para activar las irq
                    msr spsr,r0				//Mueve r0 al spsr con el bit modificado
                    ldr r0,=mensaje_hab		//Imprime mensaje habilitado
                    bl printString
                    b fin

desactivarFiq:		cmp r5,#201				//En el caso de que el numero sea un 101, desactivar? las irq
                    bne imprime_registro
                    mrs r0,spsr				//Mueve el spsr a r0
                    orr r0,r0,#0x00000040 	//Pone a 1 el bit 6 para desactivar las irq
                    msr spsr,r0				//Mueve r0 al spsr con el bit modificado
                    ldr r0,=mensaje_deshab	//Imprime mensaje deshabilitado
                    bl printString
                    b fin

imprime_registro:   cmp r5,#0				//En el caso de que el n?mero no sea 100,101,200 o 201 imprime el contenido del registro que indica el numero
					bgt mensajeError		//Si el numero es menor que 0, mostrar? el mensaje de error y terminar?
					cmp r5,#9				
                    bgt mensajeError		//Si es mayor que 9, mostrar? el mensaje de error y terminar?
                    ldr r0,=str_swi			//Carga la etiqueta str_swi para mostrar el swi por pantalla
                    bl printString
                    mov r0,r5				//Mueve a r0 el contenido de r5(ya que es el numero del registro que queremos mostrar)
                    bl printInt				//Imprime por pantalla el numero del swi
                    mov r0,#'\n'			//Imprime un salto de linea
                    bl write_uart
                    mov r0,#'r'				//Imprime la r del registro
                    bl write_uart
                    mov r0,#'0'				//Mueve a r0 un '0' para poder mostrar correctamente el numero del registro
                    add r0,r0,r5			//Pasa a ascii el numero del registro sumando r0+r5
                    bl write_uart
                    mov r0,#':'				//Imprime :
                    bl write_uart
                    ldr r0,[sp,r5,lsl#2]	//Carga en r0 el contenido del registro que queremos multiplicando r5 por 4 para que sume en sp las posiciones necesarias para encontrar el contenido
                    bl printInt				//Imprime el contenido del registro
                    b fin

mensajeError:       ldr r0,=mensaje_error	//Carga el mensaje de error
                    bl printString			//Imprime el mensaje de error

fin:                mov r0,#'\n'			
                    bl write_uart			//Imprime un salto de linea
                    ldmfd sp!,{r0-r9,pc}^	//Al terminar la interrupcion, desapila todo lo que habiamos guardado para volver a donde fue llamado
					

.globl write_uart
write_uart:			stmdb sp!,{r4}
					ldr r4,UARTDR
					strb r0,[r4]
					ldmia sp!,{r4}
					bx lr			

.globl read_uart
read_uart:			stmdb sp!,{r4,r5}
					ldr r4,UARTFR
wait_data:			ldr r5,[r4]
 	 				and r5,r5,#0x00000040
 	 				cmp r5,#0
 					beq wait_data
					ldr r4,UARTDR
					ldrb r0,[r4]
					ldmia sp!,{r4,r5}
					bx lr


    
.globl main

main:		mov r6,#1
			ldr r0, =bienvenido   // Mostramos mensaje bienvenida (solo 1 vez)
			bl printString
			

bucle_ext:	ldr r0, =pregunta      // Mostramos simbolo de pregunta ' > '
            bl printString
            ldr r4, =buffer_comando   // Con r4 iremos rellenando el buffer del comando actual

bucle_intro:
			bl read_uart
			strb r0, [r4], #1    // Guardamos el caracter en el buffer
			bl write_uart
            cmp r0, #'\r'
            bne bucle_intro       // Mientras no pulse ENTER --> seguimos esperando
            
            mov r0, #'\n'
            bl write_uart         // Escribimos un retorno del carro para pasar a la 
                                  // linea siguiente
                                  
            mov r0, #0    // Sustituimos \r por el terminador
            strb r0, [r4, #-1]
            
            ldr r0, =buffer_comando
            bl interpreta
            // Comando no reconocido --> muestra mensaje error
            cmp r0, #ERR_NON_VALID
            ldreq r0, =error_comando
            bleq printString
            
			b bucle_ext

// Funcion que interpreta un comando
// In: r0 --> cadena a interpretar
// Devuelve: r0 == 0 --> comando ok
//  ERR_NON_VALID error en la instruccion
//  ERR_PARSE error en el parseo de una expresion
.equ ERR_NON_VALID, 1
.equ ERR_PARSE, 2
interpreta:
						stmdb sp!, {r4-r10, lr}  	// Guardamos en la pila registros para poder tenerlos como variables (al estilo C3)
						mov r10, #0     			// r10 contiene el codigo de error
						mov r4, r0     				// r4 tiene el comando a interpretar
            
						// Comparamos con los comandos llamando a starts with
						ldr r1, =cmd_help
						bl starts_with
						cmp r0, #1
						beq ejecuta_help
//ACTIVA IRQ	
activa_irq:				ldr r1, =cmd_act_irq 		//Carga la etiqueta del comando a comprobar
						mov r0,r4			 		//Mueve r4 a r0 ya que r4 contiene el comando que se ha introducido por teclado
						bl starts_with		 		//Va a la etiqueta starts_with para comprobar si el comando introducido se corresponde con el que esta en r1
						cmp r0,#1
						bne desactiva_irq			//En el caso de que no se correspondan salta a la siguiente etiqueta
						swi #100					//Si el comando es correcto, llama a swi #100 para activar las IRQ
						b f_interpr

//DESACTIVAR FIQ
desactiva_irq:  		ldr r1, =cmd_des_irq		//Carga la etiqueta del comando a comprobar
						mov r0,r4					//Mueve r4 a r0 ya que r4 contiene el comando que se ha introducido por teclado
						bl starts_with				//Va a la etiqueta starts_with para comprobar si el comando introducido se corresponde con el que esta en r1
						cmp r0,#1
						bne r						//En el caso de que no se correspondan salta a la siguiente etiqueta
						swi #101					//Si el comando es correcto, llama a swi #101 para desactivar las IRQ
						b f_interpr
//R			
r:                      ldr r1, =cmd_r 				//Carga la etiqueta del comando a comprobar
                        mov r0,r4					//Mueve r4 a r0 ya que r4 contiene el comando que se ha introducido por teclado
                        bl starts_with 				//Va a la etiqueta starts_with para comprobar si el comando introducido se corresponde con el que esta en r1
                        cmp r0,#1
                        bne set_r					//En el caso de que no se correspondan salta a la siguiente etiqueta
                        ldrb r0,[r4,#1]				//Si el comando es correcto, carga en r0 el numero del registro
                        sub r0,r0,#'0'				//Pasa el numero de codigo ASCII a entero
                        mov r5,r0					//Mueve el numero a r5
                        cmp r0,#9 					//Compara si el numero es valido
                        bgt error
                        cmp r0,#0
                        blt error
                        ldr r1,=registros_virtuales //Si es valido, carga en r1 los registros virtuales
                        mov r0,#'r'					//Imprime r
                        bl write_uart
                        mov r0,#'0'
                        add r0,r0,r5				//Imprime el numero del registro pasandolo antes a codigo ASCII
                        bl write_uart
                        mov r0,#':'					//Imprime :
                        bl write_uart				
                        ldr r0,[r1,r5, lsl #2] 		//Carga en r0 el contenido del registro virtual que queremos, multiplicando r5*4 para posicionarse en memoria en el registro correcto
                        bl printInt					//Imprime el contenido del registro			
                        mov r0,#'\n'				//Imprime un salto de linea
                        bl write_uart
						b f_interpr					//Termina el comando

//SETS

set_r:                  ldr r1,=cmd_set_r			//Carga la etiqueta del comando a comprobar
                        mov r0,r4					//Mueve r4 a r0 ya que r4 contiene el comando que se ha introducido por teclado
                        bl starts_with				//Va a la etiqueta starts_with para comprobar si el comando introducido se corresponde con el que esta en r1
                        cmp r0,#1					
                        bne set_int					//En el caso de que no se correspondan salta a la siguiente etiqueta
                        ldrb r0,[r4,#5] 			//Si es valido, salta 5 posiciones para coger el numero del registro
                        sub r0,r0,#'0' 				//Resta para pasar de codigo ASCII a entero
                        ldr r1,=registros_virtuales	//Carga en r1 los registros virtuales
                        mov r2,#0
                        ldrb r2,[r4,#7] 			//Salta 7 posiciones para cargar el numero de detras del igual para guardarlo en el registro que corresponda
                        sub r2,r2,#'0'				//Resta para pasar de codigo ASCII a entero
                        str r2,[r1,r0,lsl #2] 		//Guarda en el registro virtual el numero que se ha introducido por teclado 
                        b f_interpr					//Termina el comando

//SET INT
set_int:				ldr r1,=cmd_set_int			//Carga la etiqueta del comando a comprobar
						mov r0,r4					//Mueve r4 a r0 ya que r4 contiene el comando que se ha introducido por teclado
						bl starts_with				//Va a la etiqueta starts_with para comprobar si el comando introducido se corresponde con el que esta en r1
						cmp r0,#1
						bne set_string				//En el caso de que no se correspondan salta a la siguiente etiqueta
						ldr r1,=buffer_int 			//Carga en r1 la direccion de buffer_int que es donde se van a guardar las variables de tipo int
						ldr r6,=n_vars_int			//Carga en r7 la direccion de n_vars_int que es el contador de variables totales
						ldr r6,[r6]					//Carga el contenido de n_vars_int
						mov r8,#0					
						mov r9,#16 					//Para que en caso de que tengamos mas de una variable en el buffer saltarnos la otra.
						mul r8,r6,r9 				//Lo que hace es multiplicar el num de variables por 16(ya que es lo que ocupa una variable) para saber cuantas posiciobes nos tiene que saltar cuando 
						add r1,r1,r8 				//y se lo suma a r1, por ejemplo, si tenemos dos variables, sera 2*16 entonces sabemos que tenemos que saltarnos 32 posiciones para llegar a la segunda variable
						mov r5,r4					//Mueve la cadena introducida por teclado a r5 para trabajar con r5
						add r5,r5,#5				//Suma 5 posiciones para posicionar el puntero en la primera letra del nombre 
						mov r7,#0					//Contador para la longitud de la cadena
						
buc:					ldrb r0,[r5],#1 			//En el bucle se guarda el nombre de la variable
						cmp r0,#'=' 				//Si en r0 hay un = y la longitud es menor que 12, quiere decir que tiene que rellenar los huecos que faltan hasta llegar a 12
						beq rellena_hasta_doce
						cmp r0,#65
						blt error_nombre 			//Comprueba que este entre A y z en codigo ascii
						cmp r0,#122
						bgt error_nombre
						strb r0,[r1],#1				//Si est? entre A y z, guarda el caracter en el buffer
						add r7,r7,#1				//Incrementa la variable contadora
						cmp r7,#12 					//Si es mas de 12, tiene que saltarse todo lo que sobra de la cadena
						beq saltar_caracteres
						b buc
						
num:					ldrb r0,[r5],#1 			//Si es igual, entonces se salta el igual y guarda el numero con el bucle
						sub r0,r0,#'0'				//Resta para pasar el codigo ASCII
						str r0,[r1],#1				//Guarda el numero en el buffer_int 
						cmp r0,#0
						beq terminar				
						b num
						
terminar:				ldr r0,=n_vars_int			//Carga en r0 la direccion de n_vars_int
						ldr r7,[r0]					//Carga el contenido de n_vars_int
						add r7,r7,#1 				//Actualiza la cantidad de variables guardadas.
						str r7,[r0]					//Guarda el en n_vars_int la cantida actualizada
						b f_interpr

rellena_hasta_doce:		mov r0,#'*'					//Caracter que va a ocupar las posiciones que falten
buc_rellena:			strb r0,[r1],#1				//Guarda hasta que llegue a 12
						add r7,r7,#1
						cmp r7,#12
						beq num
						b buc_rellena

saltar_caracteres:		mov r0,#'\0'				//Guarda el terminador de cadenas	
						strb r0,[r1]	
						ldrb r0,[r5],#1 			//Ignora todos los caracteres que se han introducido ya que ha superado el maximo de caracteres
						cmp r0,#'='					//Si encuentra un igual termina
						beq num
						b saltar_caracteres

error_nombre:			ldr r0,=mensaje_error_nom_variable //Muestra el mensaje de error
						bl printString
						mov r0,#'\n'
						bl write_uart
						b f_interpr

//SET STRING					
set_string:				ldr r1,=cmd_set_string	
						mov r0,r4
						bl starts_with
						cmp r0,#1
						bne lista_reg
						ldr r1,=buffer_string 		//Carga en r1 la direccion del buffer_string
						ldr r7,=n_vars_string 		//Carga en r7 la direccion de n_vars_string
						ldr r7,[r7]					//Carga el contenido de n_vars_string
						mov r9,#256 				//Las siguientes instrucciones hacen lo mismo que en el set_int pero con 256
						mul r8,r7,r9 
						add r1,r1,r8 
						add r4,r4,#5 				//Suma 5 posiciones para posicionar el puntero en la primera letra del nombre
						mov r6,#0
buc1:					ldrb r0,[r4],#1 			//En el bucle se guarda el nombre de la variable
						cmp r0,#'=' 				//Si en r0 hay un = y la longitud es menor que 12, quiere decir que tiene que rellenar los huecos que faltan hasta llegar a 12
						beq rellena_hasta_doce_1	
						cmp r0,#65
						blt error_nombre 			//Comprueba que este entre A y z en codigo ASCII
						cmp r0,#122
						bgt error_nombre
						strb r0,[r1],#1				//Si esta entre A y z guarda el caracter en el buffer
						add r6,r6,#1				//Incrementa el contador de caracteres
						cmp r6,#12 					//Si es mas de 12 entonces, tiene que saltarse todo lo que sobra de la cadena
						beq saltar_caracteres1
						b buc1
	
string:					mov r7,#0 					//Contador de 244 caracteres
buc_string:				ldrb r0,[r4],#1 			//Si es igual, entonces se salta el igual y guarda el numero con el bucle
						add r7,r7,#1				//Incrementa la variable contador
						cmp r0,#'"'					//Si encuentra un " se lo salta
						beq string
						cmp r7,#244 				//Si llega a 244 termina
						beq terminar1
						strb r0,[r1],#1				//Guarda el caracter en el buffer
						b buc_string
						
terminar1:				ldr r0,=n_vars_string		//Carga en r0 la direccion de n_vars_int
						ldr r4,[r0]					//Carga el contenido de n_vars_int
						add r4,r4,#1 				//Actualiza el contador de variables guardadas.
						str r4,[r0]					//Guarda el contador actualizado
						b f_interpr

rellena_hasta_doce_1:	mov r0,#'*'					//Caracter que va a ocupar las posiciones que falten
buc_rellena1:			cmp r6,#12					//Rellena con el caracter hasta 12
						beq string
						strb r0,[r1],#1
						add r6,r6,#1
						b buc_rellena1
						
saltar_caracteres1:		mov r0,#'\0'				//Guarda el terminador de cadenas	
						strb r0,[r1]
						ldrb r0,[r4],#1 			//Ignora todos los caracteres que se han introducido ya que ha superado el maximo de caracteres
						cmp r0,#'='					//Si encuentra un igual termina
						beq string
						b saltar_caracteres1

//LISTAS_REG,INT Y STRING 

lista_reg:				ldr r1,=cmd_lista_reg
						mov r0,r4
						bl starts_with
						cmp r0,#1
						bne lista_int
						mov r4,#0					//Contador de registros
						
bucle_lista_reg:		ldr r1,=registros_virtuales //Carga en r1 la direccion de registros virtuales 
						mov r0,#'r'					//Imprime r
                        bl write_uart
                        mov r0,#'0' 				//Suma al numero para pasarlo a codigo ASCII 
                        add r0,r0,r4
                        bl write_uart
                        mov r0,#':'					//Imprime :
                        bl write_uart
						ldr r0,[r1,r4, lsl #2] 		//Carga en r0 el contenido del registro virtual que corresponde y lo imprime
						bl printInt				
						mov r0,#'\n'
                        bl write_uart				//Imprime un salto de linea
						add r4,r4,#1				//Incrementa r4 para mostrar el siguiente registro
						cmp r4,#9					//Si r4 vale 9, quiere decir que ya ha recorrido todos los registros y termina
						bgt f_interpr
						b bucle_lista_reg			//Vuelve al bucle para mostrar el contenido del siguiente registro

lista_int:				ldr r1,=cmd_lista_int		
						mov r0,r4
						bl starts_with
						cmp r0,#1
						bne lista_string
						mov r5,#0 					//Contador de caracteres
						ldr r6,=n_vars_int 			//Carga la direccion de n_vars_int
						ldr r6,[r6]					//Carga el contenido de n_vars_int
						mov r7,#0 					//Contador de variables recorridas
						ldr r1,=buffer_int			//Carga la direccion del buffer_int
						
bucle_lista_int:		ldrb r0,[r1],#1				//Este bucle sirve para imprimir los caracteres del nombre
						add r5,r5,#1 				//Incrementa el contador de caracteres
						cmp r5,#12
						beq mostrar_int 			//Si el contador es 12, quiere decir que ha mostrado todo y va a mostrar_int
						cmp r0,#'*'					
						beq bucle_lista_int 		//Si encuentra un *, se lo salta, ya que no tiene que imprimirlo por pantalla
						bl write_uart				//En el caso de que sea un caracter valido, lo imprime
						b bucle_lista_int

mostrar_int:			mov r0,#'=' 				//Imprime un igual despues del nombre
						bl write_uart
						ldrb r0,[r1]				//Carga el numero en r0 y lo imprime
						bl printInt
						mov r0,#'\n' 
						bl write_uart 				//Imprime salto de linea
						add r7,r7,#1 				//Incrementa el contador de variables recorridas ya que se ha mostrado la primera variable
						cmp r7,r6 	
						beq f_interpr				//Si el contador de variables recorridas es igual al contador de variables totales termina
						mov r5,#0					//Limpia el contador de caracteres
						b bucle_lista_int
						
						
						
lista_string:			ldr r1,=cmd_lista_string
						mov r0,r4
						bl starts_with
						cmp r0,#1
						bne activar_fiq
						mov r5,#0 					//Contador de caracteres
						ldr r6,=n_vars_string 		//Carga la direccion de n_vars_string
						ldr r6,[r6]					//Carga el contenido de n_vars_string
						mov r7,#0 					//Contador de variables recorridas
						ldr r1,=buffer_string		//Carga la direccion del buffer_string

bucle_lista_string:		ldrb r0,[r1],#1				//Este bucle sirve para imprimir los caracteres del nombre
						add r5,r5,#1 				//Incrementa el contador de caracteres
						cmp r5,#12
						beq mostrar_string 			//Si el contador es 12, quiere decir que ha mostrado todo y va a mostrar_string
						cmp r0,#'*'
						beq bucle_lista_string 		//Si encuentra un *, se lo salta, ya que no tiene que imprimirlo por pantalla
						bl write_uart				//En el caso de que sea un caracter valido, lo imprime
						b bucle_lista_string

mostrar_string:			mov r0,#'='					//Imprime un igual despues del nombre
						bl write_uart
buc_mostrar_string:		ldrb r0,[r1],#1				//Carga la primera posicion de la cadena y empieza a imprimir
						bl write_uart
						cmp r0,#0
						beq fin_string				//Si encuentra un 0, termina
						b buc_mostrar_string

fin_string:				mov r0,#'\n'				//Imprime salto de linea
						bl write_uart
						add r7,r7,#1				//Incrementa el contador de variables recorridas
						cmp r7,r6
						bne bucle_lista_string		//Si el contador de variables recorridas no es igual al numero de variables totales vuelve al bucle
						b f_interpr					//Termina el comando
//ACTIVAR FIQ
activar_fiq:			ldr r1,=cmd_act_fiq	
						mov r0,r4
						bl starts_with
						cmp r0,#1
						bne desactivar_fiq			
						swi #200					//Si el comando es correcto, llama a swi #200 para activar las FIQ
						b f_interpr					//Termina el comando

//DESACTIVAR FIQ
desactivar_fiq:			ldr r1,=cmd_des_fiq
						mov r0,r4
						bl starts_with
						cmp r0,#1
						bne print
						swi #201					//Si el comando es correcto, llama a swi #201 para desactivar las FIQ
						b f_interpr					//Termina el comando
						
//PRINT
print:					ldr r1,=cmd_print
						mov r0,r4
						bl starts_with
						cmp r0,#1
						bne if_
						ldrb r0,[r4,#6]				//Suma 4 para posicionarse en las ", la r, el % o el $
						cmp r0,#'"'					//Comprueba cual de los caracteres anteriores est? en r0 y salta a la etiqueta correspondiente
						beq imprimir_cadena			
						cmp r0,#'r'
						beq mostrar_registro
						cmp r0,#'%'
						//beq variable_entorno_int
						cmp r0,#'$'
						//beq variable_entorno_string
						b f_interpr
						
imprimir_cadena:		add r4,r4,#6				//Suma 6 posiciones para colocarse en las "
buc_cadena:				ldrb r0,[r4],#1				//Este bucle imprime la cadena que se introduce despues del print 
						cmp r0,#'"'					//Si encuentra " se las salta para no imprimirlo
						beq buc_cadena
						bl write_uart				//Imprime el caracter
						cmp r0,#0
						beq salto_linea				//Si encuentra un 0 termina
						b buc_cadena
						
salto_linea:			mov r0,#'\n'				//Imprime el salto de linea y termina el comando
						bl write_uart
						b f_interpr

mostrar_registro:		ldrb r0,[r4,#7]				//Suma 7 posiciones para coger el numero del registro
                        sub r0,r0,#'0'				//Resta para pasar de codigo ASCII a entero
                        mov r6,r0					//Mueve r0 a r6
                        cmp r0,#0					//Comprueba si es un registro valido
                        blt error
						cmp r0,#9 
                        bgt error
                        ldr r1,=registros_virtuales //Carga en r1 los registros virtuales
                        ldr r0,[r1,r6, lsl #2]		//Carga en r0 el contenido del registro virtual que corresponde
                        bl printInt					//Imprime el contenido
                        b salto_linea				//Termina
/*						
variable_entorno_int:	ldr r1,=buffer_int
						add r4,r4,#7
bucle_buffer_int:		cmp r5,#0
						sub r5,r5,#1
						ldrb r0,[r4],#1
						ldrb r2,[r1],#1
						cmp r0,r2
						beq bucle_buffer_int

variable_entorno_string:
*/						
						
						
//IF
if_:					ldr r1,=cmd_if
						mov r0,r4
						bl starts_with
						cmp r0,#1
						bne entrada
						mov r2,#0 					//Contador para el bucle, cuenta cuantas posiciones tiene que recorrer para encontrar >,< o =
bucle_enc_signo:		ldrb r6,[r4],#1				//Carga el contenido de r4 en r6
						add r2,r2,#1 				//Incrementamos el contador cada iteracion del bucle
						cmp r6,#'>'
						beq mayor_que				//En caso de que r6 sea un > salta a mayor_que
						cmp r6,#'<'
						beq menor_que				//En caso de que r6 sea un < salta a menor_que
						cmp r6,#'='
						beq igual_que				//En caso de que r6 sea un = salta a igual_que
						cmp r6,#0
						beq f_interpr				//En caso de que no encuentre ninguno de los anteriores termina
						b bucle_enc_signo

mayor_que:				b recoger_datos				//Salta a recoger_datos

menor_que:				b recoger_datos				//Salta a recoger_datos

igual_que:				b recoger_datos				//Salta a recoger_datos

recoger_datos:			sub r4,r4,r2				//Resta a r4 el contador para volver al principio de la cadena, ya que como puede ser numero_registro, registro_numero o registro_registro me es imposible saber con certeza donde van a estar los datos que necesito
						ldrb r0,[r4,#3]				//Carga en r0 la tercera posicion de la cadena
						cmp r0,#'r'					//Si en esa posicion no encuentra una r, quiere decir que hay un numero, por ejemplo if 7>r0 print "hola"
						bne numero_registro
						ldrb r0,[r4,#6]				//Carga en r0 la sexta posicion de la cadena
						cmp r0,#'r'					//Si en esa posicion hay una r, quiere decir que estamos en el caso registro_registro, ya que a esta linea no llegaremos en el caso de que haya un numero en la tercera posicion
						beq registro_registro
						b registro_numero			//Si no es ninguno de los casos anteriores, quiere decir que estamos en el caso registro_numero

registro_numero:		ldr r1,=registros_virtuales //En caso de que a la dcha del > hubiese un numero tipo--> if r0>9
						ldrb r0,[r4,#4] 			//Carga el numero del registro
						sub r0,r0,#'0'				//Resta para pasar de codigo ASCII a entero
						ldr r5,[r1,r0, lsl #2] 		//Carga en r5 el contenido del registro correspondiente
						add r0,r4,#6				//Suma a r4 6 posiciones para coger el numero de detras del >,< o =
						bl atoi 					//Llamamos a atoi para que calcule el numero.
						cmp r6,#'>'					//Si en r6 hay un >, quiere decir que tiene que saltar a mayor
						beq mayor
						cmp r6,#'<'					//Si en r6 hay un <, quiere decir que tiene que saltar a menor
						beq menor
						cmp r6,#'='					//Si en r6 hay un =, quiere decir que tiene que saltar a igual
						beq igual_
						
mayor:					cmp r5,r0					//Compara r5(contenido del registro) con r0(numero de detras del >)
						bgt elimina					//En el caso de que r5 sea mayor que r0, salta a elimina
						b f_interpr					//En el caso de que no lo sea, termina el comando
						
menor:					cmp r5,r0					//Compara r5(contenido del registro) con r0(numero de detras del <)
						blt elimina					//En el caso de que r5 sea menor que r0, salta a elimina
						b f_interpr					//En el caso de que no lo sea, termina el comando
						
igual_:					cmp r5,r0					//Compara r5(contenido del registro) con r0(numero de detras del =)
						beq elimina					//En el caso de que r5 sea igual que r0, salta a elimina
						b f_interpr					//En el caso de que no lo sea, termina el comando

numero_registro:		ldr r1,=registros_virtuales //En caso de que a la izq del < hubiese un numero tipo--> if 9<r0 
						ldrb r0,[r4,#6] 			//Carga el numero del registro
						sub r0,r0,#'0'				//Resta para pasar de codigo ASCII a entero
						ldr r5,[r1,r0, lsl #2]		//Carga en r5 el contenido del registro correspondiente
						add r0,r4,#3 				//Suma a r4 3 posiciones para coger el numero de delante del >,< o =
						bl atoi						//Llamamos a atoi para que calcule el numero.
						cmp r6,#'>'					//Si en r6 hay un >, quiere decir que tiene que saltar a mayor
						beq mayor1
						cmp r6,#'<'					//Si en r6 hay un <, quiere decir que tiene que saltar a menor
						beq menor1
						cmp r6,#'='					//Si en r6 hay un =, quiere decir que tiene que saltar a igual
						beq igual_1
						
mayor1:					cmp r0,r5					//Compara r0(numero de detras del >) con r5(contenido del registro)
						bgt elimina					//En el caso de que r0 sea mayor que r5, salta a elimina
						b f_interpr					//En el caso de que no lo sea, termina el comando
						
menor1:					cmp r0,r5					//Compara r0(numero de detras del <) con r5(contenido del registro)
						blt elimina					//En el caso de que r0 sea menor que r5, salta a elimina
						b f_interpr					//En el caso de que no lo sea, termina el comando
						
igual_1:				cmp r0,r5					//Compara r0(numero de detras del =) con r5(contenido del registro)
						beq elimina					//En el caso de que r0 sea igual que r5, salta a elimina
						b f_interpr					//En el caso de que no lo sea, termina el comando

registro_registro:		ldr r1,=registros_virtuales //En caso de que a la dcha del > hubiese otro registro--> if r0>r1
						ldrb r0,[r4,#4] 			//Carga el numero del primer registro
						sub r0,r0,#'0'				//Resta para pasar de codigo ASCII a entero
						ldr r0,[r1,r0, lsl #2]		//Carga en r0 el contenido del primer registro correspondiente
						ldrb r2,[r4,#7] 			//Carga el numero del segundo registro
						sub r2,r2,#'0'				//Resta para pasar de codigo ASCII a entero
						ldr r2,[r1,r2, lsl #2]		//Carga en r2 el contenido del segundo registro correspondiente
						cmp r6,#'>'					//Si en r6 hay un >, quiere decir que tiene que saltar a mayor
						beq mayor2
						cmp r6,#'<'					//Si en r6 hay un <, quiere decir que tiene que saltar a menor
						beq menor2
						cmp r6,#'='					//Si en r6 hay un =, quiere decir que tiene que saltar a igual
						beq igual_2
						
mayor2:					cmp r0,r2					//Compara r0(contenido del primer registro) con r2(contenido del segundo registro)
						bgt elimina_registro		//En el caso de que r0 sea mayor que r2, salta a elimina_registro
						b f_interpr					//En el caso de que no lo sea, termina el comando
						
menor2:					cmp r0,r2					//Compara r0(contenido del primer registro) con r2(contenido del segundo registro)
						blt elimina_registro		//En el caso de que r0 sea menor que r2, salta a elimina_registro
						b f_interpr					//En el caso de que no lo sea, termina el comando
						
igual_2:				cmp r0,r2					//Compara r0(contenido del primer registro) con r2(contenido del segundo registro)
						beq elimina_registro		//En el caso de que r0 sea igual que r2, salta a elimina_registro
						b f_interpr					//En el caso de que no lo sea, termina el comando
						
elimina:				add r4,r4,#8 				//Quita toda la parte del if
						ldr r1,=buffer_string 		//Carga en r1 el buffer_string, ya que vamos a hacer una llamada recursiva a la etiqueta interpreta para interpretar el comando que hemos introducido en el if
						b bucle

elimina_registro:		add r4,r4,#9 				//Quito toda la parte del if
						ldr r1,=buffer_string 		//Carga en r1 el buffer_string, ya que vamos a hacer una llamada recursiva a la etiqueta interpreta para interpretar el comando que hemos introducido en el if
						//mov r2,#0
						b bucle
						
bucle:					ldrb r0,[r4],#1 			//En el bucle carga la instruccion a ejecutar en el buffer_comando
						strb r0,[r1] 				//Guarda en el buffer la instruccion
						cmp r0,#0 					//Cuando encuentra un 0, termina ya que hemos terminado de recorrer la cadena
						beq interpreta_				//Salta a interpreta_
						add r1,r1,#1				//Incrementa r1 para seguir guardando la isntruccion en el buffer
						b bucle

interpreta_:			ldr r0,=buffer_string 		//Mueve a r0 el buffer_comando ya que a interpreta le llega como parametro r0 y su contenido tiene que ser ese buffer
						bl interpreta 				//Tiene que ser recursiva, si no, bucle infinito
						b f_interpr
						


//ENTRADA			    
entrada:				ldr r1,=cmd_entrada
						mov r0,r4
						bl starts_with
						cmp r0,#1
						bne pausa 
						ldrb r0,[r4,#8] 			//Carga en r0 el contenido de la octava posicion del comando
						cmp r0,#'r'
						beq entrada_r 				//Si en r0 hay una r, quiere decir que tendremos que guardar en un registro
						cmp r0,#'%'
						//beq entrada_var_int			//Si en r0 hay un %, quiere decir que tendremos que guardar en una variable de tipo int
						cmp r0,#'$'
						//beq entrada_var_string		//Si en r0 hay una r, quiere decir que tendremos que guardar en una variable de tipo string
						b f_interpr

entrada_r:				mov r5,#4 					//Mueve un 4 a r5 para poder guardar en la posicion correcta en los registros virtuales 
						ldrb r0,[r4,#9] 			//Carga en r0 el numero del registro donde correspondiente
						sub r4,r0,#'0' 				//Resta para pasar de codigo ASCII a entero y lo guarda en r4
						bl read_uart				//Llama a read_uart para detectar el caracter que se ha tecleado 
						sub r3,r0,#'0' 				//Pasa el numero que lee en la uart a entero y lo guarda en r3
						bl write_uart				//LLama a write_uart para mostrar el caracter que se ha introducido en la uart
						mov r0,#'\n'				//Imprime un salto de linea
						bl write_uart
						ldr r1,=registros_virtuales //Carga en r1 los registros_virtuales
						mul r4,r5,r4				//Multiplica r5*r4 para posicionarse en la posicion correcta
						add r1,r1,r4				//Suma r4 y r1 para posicionarse en la posicion correcta(estas dos instrucciones anteriores son similares a la instruccion ldr r2,[r1,r2, lsl #2])
						str r3,[r1]					//Guarda el caracter que se leyo en la uart en el registro virtual correspondiente
						b f_interpr


//PAUSA
pausa:					ldr r1,=cmd_pausa			
						mov r0,r4
						bl starts_with
						cmp r0,#1
						bne f_interpr
						ldr r0,=msg_tecla			//Imprime el mensaje de pausa
						bl printString			
						bl read_uart				//En el caso de que se pulse una tecla, continuar? el programa, si no se quedar? en pausa ya que read_uart esta implementada con una espera activa
						ldr r0,=msg_reanudar
						bl printString
						b f_interpr	
						
            // TODO: Implementa los demas comandos!!!
            
            // Comando no reconocido --> muestra mensaje error
error:
            mov r10, #ERR_NON_VALID
            b f_interpr

ejecuta_help:
            ldr r0, =mensaje_ayuda
            bl printString
            
f_interpr:  mov r0, r10        // Ponemos el codigo de error en el valor de retorno r0
            ldmia sp!, {r4-r10, pc}
			
// Funcion starts_with
// Param in : r0 --> cadena 1
//            r1 --> cadena 2
// Param out : 0 --> 1 si cadena 1 empieza por cadena 2
starts_with: ldrb r2, [r0],#1
             ldrb r3, [r1],#1
			 cmp r3,#0
             beq sw_yes
             cmp r2, r3
             beq starts_with
sw_no:      mov r0, #0
             b sw_fin
sw_yes:       mov r0, #1
sw_fin:      bx lr
             
.data

msg_tecla:	.asciz "Presione una tecla para continuar.\n"
msg_reanudar:	.asciz "Se reanudo el sistema\n"

bienvenido:   .asciz "Bienvenido a MiniOS (2020). Introduzca comandos a continuacion.\nUse el comando help para ayuda.\n"

pregunta: .asciz " > "

error_comando: .asciz "Comando no reconocido\n"

cmd_r: .asciz "r"
cmd_set_r: .asciz "set r"
cmd_set_int: .asciz "set %"
cmd_set_string: .asciz "set $"
cmd_act_irq: .asciz "activa_irq"
cmd_des_irq: .asciz "desactiva_irq"
cmd_act_fiq: .asciz "activa_fiq"
cmd_des_fiq: .asciz "desactiva_fiq"
cmd_help: .asciz "help"
cmd_lista: .asciz "lista"
cmd_lista_int: .asciz "lista_int"
cmd_lista_reg: .asciz "lista_reg"
cmd_lista_string: .asciz "lista_string"
cmd_print: .asciz "print"
cmd_ejecuta: .asciz "ejecuta"
cmd_goto: .asciz "goto"
cmd_end: .asciz "end"
cmd_if: .asciz "if"
cmd_load: .asciz "load"
cmd_entrada: .asciz "entrada "
cmd_pausa:	.asciz "pausa"
.align

// Reservamos partes de memoria que pueden ser de utilidad al interprete

registros_virtuales:
.space 40

buffer_comando:  // 
.space TAM_STRING

buffer_int:
.space TAM_BUFFER_VARS

buffer_string:
.space TAM_BUFFER_VARS

buffer_program:
.space TAM_BUFFER_VARS


n_vars_int:
.word 0
n_vars_string:
.word 0

aux_nombre:
.space TAM_STRING

.equ TAM_INT, 16
.equ TAM_STRING, 256
.equ TAM_BUFFER_VARS, 65536
.equ TAM_NOMBRE, 12
.equ ERROR_INT, 0x80000000
	
mensaje_ayuda:  .ascii "Lista de comandos:\n"

                .ascii "Comandos basicos: \n"
                .ascii "activa_irq\t\t-->\tActiva interrupciones IRQ. \n"
                .ascii "desactiva_irq\t\t-->\tDesactiva interrupciones IRQ. \n"
                .ascii "help\t\t\t-->\tMuestra esta lista de comandos.\n"
                .ascii "print <expresion>\t-->\tMuestra una expresion en pantalla. Ej: print r2 ; print \"Hola caracola\"\n"
                .ascii "r<n>\t\t\t-->\tMuestra el contenido del registro indicado (0-9) (ej: r1)\n"
                .ascii "set r<n>=<valor>\t-->\tModifica el contenido del registro indicado (0-9) (ej: set r1=r1+2)\n"
                .ascii "\n"
                .ascii "------------ Comandos de listado -------------------\n\n"
                .ascii "lista\t\t\t-->\tMuestra el contenido del buffer de programa\n"
                .ascii "lista_int\t\t-->\tMuestra una lista de variables enteras definidas.\n"
                .ascii "lista_reg\t\t-->\tMuestra una lista con los registros disponibles.\n"
                .ascii "lista_string\t\t-->\tMuestra una lista con las variables de cadena definidas.\n"
                .ascii "\n------------ Variables de entorno -------------------\n\n"
                
                .ascii "set %<var_name>=<valor>\t-->\tModifica o crea una variable entera. Ej: set %a=%a+2\n"
                .ascii "set $<var_name>=<valor>\t-->\tModifica o crea una variable de cadena. Ej: set $b=\"Hola mundo\"\n"
                .ascii "\n"
                .ascii "------------ Comandos de ejecucion -------------------\n\n"
                .ascii "ejecuta \t\t-->\tEjecuta un programa alojado en el buffer de programa\n"
                .ascii "goto <linea>\t\t-->\tAl ejecutar un programa, va al comando en la posicion indicada\n"
                .ascii "end \t\t\t-->\tFinaliza la ejecucion\n"
                .ascii "load\t\t\t-->\tCarga el programa en texto contenido en la posicion de memoria programa_texto\n"
                .ascii "if <cond.> <comando>\t-->\tEjecuta una instruccion si se cumple una condicion (ej if r1>0 goto 30)\n"
                .ascii "\n------------ PARA SALIR DE LA CONSOLA -------------------\n\n"
                .ascii "CTRL+A x\t\t-->\tSale de la emulacion (QEMU, Linux)\n"
                .asciz "CTRL+C\t\t\t-->\tSale de la emulacion (QEMU, Windows)\n"

                
.end
