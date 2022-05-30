*Autores: 
*Daniel Corrales Falco, b190410, 73129670
*Luis Arija Gonzalez, b190324, 02574652
*Inicializa el SP y el PC
**************************
        ORG     $0
        DC.L    $8000           *Valor inicial del puntero de pila
        DC.L    INICIO          *Direccion RTI de la interrupcion reset, etiqueta del programa principal

        ORG     $400

* DefiniciÃn de equivalencias
*********************************
SIZE	EQU	2001
	
MR1A	EQU	$EFFC01
MR2A	EQU	$EFFC01
SRA		EQU	$EFFC03
CSRA	EQU	$EFFC03
CRA		EQU	$EFFC05
TBA		EQU	$EFFC07
RBA		EQU	$EFFC07
ACR		EQU	$EFFC09
IMR		EQU	$EFFC0B
ISR		EQU	$EFFC0B
MR1B	EQU	$EFFC11
MR2B	EQU	$EFFC11
CRB     EQU $effc15       * de control A (escritura)
TBB     EQU $effc17       * buffer transmision B (escritura)
RBB     EQU $effc17       * buffer recepcion B (lectura)
SRB     EQU $effc13       * de estado B (lectura)
CSRB    EQU $effc13       * de seleccion de reloj B (escritura)
IVR		EQU $EFFC19

**************************** INIT *************************************************************
*Salvo la linea de ACR, esto lo que hace es activar la linea A y la B
INIT:
	*A*
	MOVE.B		#%00010000,CRA      * Reinicia el puntero MR1
    MOVE.B      #%00000011,MR1A     * 8 bits por caracter.
    MOVE.B      #%00000000,MR2A     * Eco desactivado.
    MOVE.B      #%11001100,CSRA     * Velocidad = 38400 bps.
    MOVE.B      #%00000000,ACR      * Velocidad = 38400 bps.
    MOVE.B      #%00000101,CRA      * Transmision y recepcion activados.
	*B*
	MOVE.B      #%00010000,CRB      * Reinicia el puntero MR1
    MOVE.B      #%00000011,MR1B     * 8 bits por caracter.
    MOVE.B      #%00000000,MR2B     * Eco desactivado.
    MOVE.B      #%11001100,CSRB     * Velocidad = 38400 bps.
    MOVE.B      #%00000101,CRB      * Transmision y recepcion activados.

	**TO DO: BUFFERS(4 DOS POR LETRA BUFFER RECEPCION Y TRANSMISION) Y PUNTEROS(8, DOS POR CADA BUFFER) (PRIMER HITO)**
	MOVE.B		#$40,IVR	    *Establecemos el vector de interrupcion a 40 (hex)

	MOVE.B		#%00100010,CPYIMR
	MOVE.B		#%00100010,IMR

	MOVE.L		#RTI,$100	    *Establecemos el valor de la RTI como $100 que es 4*$40

	MOVE.L		#BUFFER0,PTR0	    *Valor inicial del puntero 0 es la dirección de la etiqueta BUFFER0, que es donde empieza el buffer, sera asi para los otros 4 bufferes, el puntero 1 del BUFFER1... etc
	MOVE.L 		#BUFFER0,PRE0
	MOVE.L 		#BUFFER0,START0
	MOVE.L		#BUFFER0+SIZE,END0
	
	MOVE.L 		#BUFFER1,PTR1
	MOVE.L 		#BUFFER1,PRE1
	MOVE.L 		#BUFFER1,START1
	MOVE.L		#BUFFER1+SIZE,END1
	
	MOVE.L 		#BUFFER2,PTR2
	MOVE.L 		#BUFFER2,PRE2
	MOVE.L 		#BUFFER2,START2
	MOVE.L		#BUFFER2+SIZE,END2
	
	MOVE.L 		#BUFFER3,PTR3
	MOVE.L 		#BUFFER3,PRE3
	MOVE.L 		#BUFFER3,START3
	MOVE.L		#BUFFER3+SIZE,END3
	
	RTS
**************************** FIN INIT *********************************************************
*****************************SUBRUTINAS********************************************************


RTI:	MOVEM.L D0-D1,-(A7)

BUC1:	MOVE.B	ISR,D1
		AND.B	CPYIMR,D1
		BTST	#1,D1		*Recepción A, podemos alterar el orden en el que miramos la reccepcion
		BNE		RELA
		BTST	#5,D1		*Recepción B
		BNE		RELB
		BTST	#0,D1		*Transmision A
		BNE		TRLA
		BTST	#4,D1		*Transmision B
		BNE		TRLB
		BRA 	RTIFIN

RELA:	MOVE.B	RBA,D1		*Para escribir en el buffer de recepción, el del SCAN
		MOVE.L	#0,D0
		BSR		ESCCAR
		CMP.L	#-1,D0
		BEQ		RTIFIN
		BRA		BUC1

RELB:	MOVE.B	RBB,D1
		MOVE.L	#1,D0
		BSR		ESCCAR
		CMP.L	#-1,D0
		BEQ		RTIFIN		*Si está LLENO el buffer terminamos
		BRA		BUC1
		
		*Excepcion trans linea A
TRLA:	MOVE.L	#2,D0
		BSR		LEECAR
		CMP.L	#-1,D0
		BEQ		INIBA
		MOVE.B	D0,TBA
		BRA		BUC1

		*Inhibicion linea A
INIBA:	BCLR	#0,CPYIMR
		MOVE.B	CPYIMR,IMR
		BRA		BUC1

		*Excepcion trans linea B
TRLB:	MOVE.L	#3,D0
		BSR		LEECAR
		CMP.L	#-1,D0
		BEQ		INIBB
		MOVE.B	D0,TBB
		BRA		BUC1

		*Inhibicion linea b
INIBB:	BCLR	#4,CPYIMR
		MOVE.B	CPYIMR,IMR
		BRA		BUC1

RTIFIN:	MOVEM.L	(A7)+,D0-D1
		RTE
***********************************************************************************************************
LEECAR:	MOVEM.L A0-A2,-(A7)
		AND.L	#3,D0
		CMP.L	#0,D0
		BEQ		LEC0
		CMP.L 	#1,D0
		BEQ		LEC1
		CMP.L 	#2,D0
		BEQ		LEC2

LEC3:	MOVE.L 	#PTR3,A0	*Guardamos en A0 la dirección de la etiqueta del puntero de transmision respectivo al buffer adecuado en base a las comparaciones anteriores
		BRA		PASO 		*Pasamos a organizar los punteros para la trnasmision del dato

LEC0:	MOVE.L 	#PTR0,A0	*Repetimos el mismo proceso para los diferentes casos que podemos encontrarnos
		BRA		PASO 			

LEC1:	MOVE.L 	#PTR1,A0	
		BRA		PASO
		
LEC2:	MOVE.L 	#PTR2,A0

PASO:	MOVE.L 	(A0),A1		*Guardo en A1 el puntero de transmision del buffer seleccionado anteriormente
		MOVE.L 	4(A0),A2	*Guardo en A2 el puntero de recepcion del buffer seleccionado anteoriormente
     	EOR.L	D0,D0		*Como ya he usado buffer, puedo modificar el valor de D0
		CMP.L 	A1,A2		*Miro si los dos punteros miran al mismo sitio, si es el caso, el buffer esta vacio y he de devolver solamente un -1 (0xFFFFFFFF) en D0
		BEQ		VACIO
		MOVE.B 	(A1)+,D0	*Si no son iguales, leo el caracter y pongo el puntero en la siguiente posicion
		CMP.L 	12(A0),A1	
		BEQ		INI
		MOVE.L 	A1,(A0)		*Actualizo el valor del puntero de extracción en memoria
		BRA		FINLEC

INI:	MOVE.L 	8(A0),A1
		MOVE.L 	A1,(A0)		
		BRA		FINLEC

VACIO:	MOVE.L 	#-1,D0

FINLEC:	MOVEM.L (A7)+,A0-A2	
		RTS
************************************************************************************************************
************************************************************************************************************
ESCCAR:	MOVEM.L A0-A2,-(A7)	*Vamos predecrementando A7 para guardar A0, A1 y A2
		AND.L	#3,D0
		CMP.L	#0,D0
		BEQ		CAR0
		CMP.L 	#1,D0
		BEQ		CAR1
		CMP.L 	#2,D0
		BEQ		CAR2

CAR3:	MOVE.L 	#PTR3,A0	*Guardamos en A0 la dirección de la etiqueta del puntero de transmision respectivo al buffer adecuado en base a las comparaciones anteriores
		BRA		PASO1		*Pasamos a organizar los punteros para la insercion del dato

CAR0:	MOVE.L 	#PTR0,A0	*Repetimos el mismo proceso para los diferentes casos que podemos encontrarnos
		BRA		PASO1			

CAR1:	MOVE.L 	#PTR1,A0	
		BRA		PASO1

CAR2:	MOVE.L 	#PTR2,A0	

PASO1:	MOVE.L 	(A0),A1		*Guardo en A1 el puntero de transmision del buffer seleccionado anteriormente
		MOVE.L 	4(A0),A2	*Guardo en A2 el puntero de recepcion del buffer seleccionado anteriormente		 
		MOVE.B	D1,(A2)+
		CMP.L	12(A0),A2	*Si son iguales estamos al final del buffer y hay que inicializar el puntero de inserción
		BEQ		INI1

PASO2:	CMP.L	A1,A2		*Si son iguales, es que el buffer está lleno, por lo que hemos de poner en D0 un -1 y salir
		BNE		VACIO1
		MOVE.L 	#-1,D0		*Si está lleno ponemos D0=-1 (D0<-0xFFFFFFFF)
		BRA		FINESC

INI1:	MOVE.L 	8(A0),A2	
		BRA 	PASO2

VACIO1:	MOVE.L 	A2,4(A0)	*Actualizamos el puntero de inserción en memoria
		MOVE.L 	#0,D0		*Ponemos D0 A 0 para indicar que hemos tenido éxito

FINESC:	MOVEM.L (A7)+,A0-A2	
		RTS
*******************************************************************************************************************************
*******************************************************************************************************************************
SCAN:	LINK 	A6,#0		*Inicializamos marco de pila (vacío), solo para referenciar datos en la pila
		MOVE.L	#0,D2		*Limpio registros
		MOVE.L	#0,D3		*Limpio registros
		MOVE.L	#0,D4		*Limpio registros
		MOVE.L	8(A6),A1	*Dirección de inicio del buffer --> A1
		MOVE.W	12(A6),D2	*Guardamos el desciptor
		MOVE.W	14(A6),D3	*Guardamos el tamaño
		CMP.W	#0,D2		*Comprobamos en que línea estamos
		BEQ		BUCSCA
		CMP.W	#1,D2
		BEQ		BUCSCB
		MOVE.L	#-1,D0	*Si en descriptor no hay un 0(Linea A) o un 1 (Linea B), da error
		BRA		FINSC2

BUCSCA:	MOVE.L	#0,D0		*Preparo D0 para la lamada a leecar (lee de la línea A)
		BSR 	LEECAR
		CMP.L	#-1,D0		*Si después de LEECAR en D0 tenemos un -1, no hay nada en el buffer interno, por lo que terminamos
		BEQ		FINSC
		MOVE.B	D0,(A1)+	*Copio el caracter a la dir del buffer que me pasan y hago un postincremento para ir a la siguiente posición del buffer
		ADD.L	#1,D4
		SUB.W	#1,D3
		CMP.W	#0,D3
		BNE		BUCSCA
		BRA		FINSC
	

BUCSCB: MOVE.L	#1,D0		*Preparo D0 para la lamada a leecar (lee del biffer de recepción de la linea B)
		BSR 	LEECAR
		CMP.L	#-1,D0		*Si después de LEECAR en D0 tenemos un -1, no hay nada en el buffer interno, por lo que terminamos
		BEQ		FINSC
		MOVE.B	D0,(A1)+	*Copio el caracter a la dir del buffer que me pasan y hago un postincremento para ir a la siguiente posición del buffer
		ADD.L	#1,D4
		SUB.W	#1,D3
		CMP.W	#0,D3
		BNE		BUCSCB
		BRA		FINSC
	
FINSC:	MOVE.L	D4,D0
FINSC2:	UNLK A6	
		RTS
**********************************************************************************************
**********************************************************************************************
PRINT:	LINK 	A6,#0		*Inicializo marco de pila vacío, referencia datos en pila
		MOVE.L	#0,D2		*Limpio registros de D2 a D4 para poder utilizarlos sin que haya basura
		MOVE.L	#0,D3
		MOVE.L	#0,D4		*Va a ser mi contador de caracteres
		MOVE.L	8(A6),A1	*La dirección del buffer la guardo en A1
		MOVE.W	12(A6),D2	*Meto en D2 el descriptor
		MOVE.W	14(A6),D3	*Pongo en D3 el tamaño
		CMP.W	#0,D2		*Miro que valor tengo en el desciptor, si es un 0, tengo que copiar en la linea A
		BEQ		PRLA
		CMP.W	#1,D2		*Miro si el valor del descriptor es 1, en tal caso, tengo que copiar en la linéa B
		BEQ		PRLB
		MOVE.L	#-1,D0		*Si en el descriptor no tengo ni un 1 ni un 0, doy mensaje de error
		BRA		FINPR

PRLA:	MOVE.L	#2,D0		*Pongo un 2 en D0 para la llamada a ESCCAR ya que necesito acceder al buffer de transmision de la línea A
		CMP.W	#0,D3		*Compruebo si tengo más caracteres que imprimir (Para saber si terminar el bucle)
		BEQ		FINPRLA
		MOVE.B	(A1)+,D1	*Preparo el primer caracter del buffer para la llamada a ESCCAR y realizo un post incremento para situarme en el siguiente caracter (si es que hubiera)
		BSR		ESCCAR
		CMP.L	#-1,D0		*Como ESCCAR me devolverá un -1 en D0 si el buffer está lleno, compruebo el valor de D0 y si es -1 termino por interrupción
		BEQ		FINPRLA
		ADD.L	#1,D4		*Sumo 1 al contador de caracteres copiados
		SUB.W	#1,D3		*Resto 1 al tamaño
		BRA 	PRLA

PRLB:	MOVE.L	#3,D0		*Pongo 3 en D0 para la llamda a ESCCAR, para acceder al buffer de transmision de la línea B
		CMP.W	#0,D3		*Compruebo si tengo más caracteres que imprimir (Para saber si terminar el bucle)
		BEQ		FINPRLB
		MOVE.B	(A1)+,D1	*Preparo el primer caracter del buffer para la llamada a ESCCAR y realizo un post incremento para situarme en el siguiente caracter (si es que hubiera)
		BSR		ESCCAR
		CMP.L	#-1,D0		*Como ESCCAR me devolverá un -1 en D0 si el buffer está lleno, compruebo el valor de D0 y si es -1 termino por interrupción
		BEQ		FINPRLB
		ADD.L	#1,D4		*Sumo 1 al contador de caracteres copiados
		SUB.W	#1,D3		*Resto 1 al tamaño
		BRA 	PRLB

FINPRLA:CMP.L	#0,D4		*Compruebo si se ha copiado algún caracter en el buffer interno
		BEQ		FINPR1		*Si no se ha copiado nada, no he de activar interrupciones de transmisión
		MOVE.W	SR,D5		*Protejo el valor del registro de estados en D5
		MOVE.W	#$2700,SR	*Inhibo interrupciones para poder habilitar las interrupciones de la línea A
		BSET	#0,CPYIMR
		MOVE.B	CPYIMR,IMR
		MOVE.W	D5,SR		*Restauro el registro de estado a como estaba antes de la interrupción
		BRA		FINPR1

FINPRLB:CMP.L	#0,D4		*Compruebo si se ha copiado algún caracter en el buffer interno
		BEQ		FINPR1		*Si no se ha copiado nada, no he de activar interrupciones de transmisión
		MOVE.W	SR,D5		*Protejo el valor del registro de estados en D5
		MOVE.W	#$2700,SR	*Inhibo interrupciones para poder habilitar las interrupciones de la línea B
		BSET	#4,CPYIMR
		MOVE.B	CPYIMR,IMR
		MOVE.W	D5,SR		*Restauro el registro de estado a como estaba antes de la interrupción
		BRA		FINPR1

FINPR1:	MOVE.L	D4,D0
	
FINPR:	UNLK	A6	
		RTS

**************************** PROGRAMA PRINCIPAL **********************************************
			*Datos
PARTAM:	DC.W	0				*Tamaño que pasaremos como parametro
CONTC:	DC.W	0				*Número de los caracteres que vamos a imprimir
BUFFER:	DS.B	2100			*Buffer de lectura y escritura de caracteres
PARDIR:	DC.L	0				*Dirección que se pasa por parametro
			
			*Manejadores de excepciones
INICIO:	MOVE.L	#BUS_ERROR,8	*Bus error handler
		MOVE.L	#ADDRESS_ER,12	*Address error handler
		MOVE.L	#ILLEGAL_IN,16	*Illegal instruction handler
		MOVE.L	#PRIV_VIOLT,32	*Privilege violation handler
		MOVE.L	#ILLEGAL_IN,40	*Illegal instruction handler
		MOVE.L	#ILLEGAL_IN,44	*Illegal instruction handler

		BSR		INIT
		MOVE.W 	#$2000,SR		*Permitimos interrupciones
******************PRUEBA ESCCAR Y LEECAR CON UN NÚMERO POR LA LÍNEA B************************
		MOVE.L	#1,D0		*Pruebo por la línea B
		MOVE.B	$37,D1		
		BSR		ESCCAR		*Supuestamente en la línea B tendría que tener un $37

		MOVE.L	#1,D0		*Voy a llamar a LEECAR por la línea B para ver que tengo
		BSR		LEECAR		*Si todo funciona correctamente, en D0 debería tener un $37

******************PRUEBA ESCCAR Y LEECAR CON UN NÚMERO POR LA LÍNEA A************************
		MOVE.L	#0,D0		*Pruebo por la línea A
		MOVE.B	$37,D1		
		BSR		ESCCAR		*Supuestamente en la línea A tendría que tener un $37

		MOVE.L	#0,D0		*Voy a llamar a LEECAR por la línea A para ver que tengo
		BSR		LEECAR		*Si todo funciona correctamente, en D0 debería tener un $37


*************************PRUEBA ESCCAR LLENADO DE BUFFER LÍNEA B******************************
		MOVE.L	#2002,D3	*Ya que los buffers son de tamaño 2001 realizaré el bucle 2002 veces para ver si se llena correctamente
LOOP:	MOVE.L	#1,D0		*Me situo en la línea B
		MOVE.B	$23,D1		*En este bucle iré colocando el mismo número en el buffer hasta que este se llene
		BSR		ESCCAR
		SUB.L	#1,D3		*Decremento el contador
		CMP.L	#0,D3		*Si es 0, termino
		BNE		LOOP		*Al terminar el bucle el valor en D0 debería ser -1 ya que el buffer se ha llenado

************************************PRUEBA SCAN Y PRINT***************************************
		MOVE.L	#2000,D3	*Ya que los buffers son de tamaño 2001 realizaré el bucle 2002 veces para ver si se llena correctamente
LOOP1:	MOVE.L	#1,D0		*Me situo en la línea B
		MOVE.B	$23,D1		*En este bucle iré colocando el mismo número en el buffer hasta que este se llene
		BSR		ESCCAR	
		SUB.L	#1,D3		*Decremento el contador
		CMP.L	#0,D3		*Si es 0, termino
		BNE		LOOP1		*Al terminar el bucle el valor en D0 debería ser -1 ya que el buffer se ha llenado
		MOVE.L	#1,D0		*Me situo en la línea B
		MOVE.L	#2000,-(A7)	*Pongo el tamaño en la pila
		MOVE.W 	D0,-(A7) 	* Puerto A
		PEA		BUFFER
		BSR		SCAN
		ADD.L	#8,(A7)		*Recupero pila
		MOVE.L	#0,D0		*Me situo en la línea A
		MOVE.L	#2000,-(A7)	*Pongo el tamaño en la pila
		MOVE.W 	D0,-(A7) 	* Puerto A
		PEA		BUFFER
		BSR		PRINT
		ADD.L	#8,(A7)		*Recupero pila
*COMO RESULTADO TENDRÍAMOS QUE TENER LA LINEA DE RECEOCION DE B LLENO DE 23, EL BUFFER Y LA LÍNEA DE TRANSMISION DE A LLENO DE 23*

BUS_ERROR:	BREAK			*Bus error handler
			NOP

ADDRESS_ER:	BREAK			*Address error handler
			NOP

ILLEGAL_IN:	BREAK			*Illegal instruction handler
			NOP

PRIV_VIOLT:	BREAK			*Privilege violation handler
			NOP
**************************** FIN PROGRAMA PRINCIPAL ******************************************
****************************DECLARACION DE BUFFERS Y PUNTEROS*********************************
	ORG		$5000

BUFFER0:	DS.B	2001 		*Buffer recepción línea A
BUFFER1:	DS.B	2001		*Buffer recepción línea B
BUFFER2:	DS.B	2001		*Buffer transmisión línea A
BUFFER3:	DS.B	2001		*Buffer trnasmision línea B 

	
PTR0:		DC.L 	BUFFER0		*Puntero transmision buffer 0
PRE0:		DC.L 	BUFFER0		*Puntero recepcion buffer 0
START0:		DC.L	BUFFER0		*Posicion de inicio del buffer 0
END0:		DC.L 	BUFFER0+SIZE	*Posición final del buffer 0

PTR1:		DC.L 	BUFFER1		*Puntero transmision buffer 1
PRE1:		DC.L 	BUFFER1		*Puntero recepcion buffer 1
START1:		DC.L	BUFFER1		*Posición de inicio del buffer 1
END1:		DC.L 	BUFFER1+SIZE	*Posición final del buffer 1

PTR2:		DC.L 	BUFFER2		*Puntero  transmision  buffer 2
PRE2:		DC.L 	BUFFER2		*Puntero  recepcion  buffer 2
START2:		DC.L	BUFFER2		*Posición de inicio del buffer 2
END2:		DC.L 	BUFFER2+SIZE	*Posición final del buffer 2

PTR3:		DC.L 	BUFFER3		*Puntero  transmision  buffer 3
PRE3:		DC.L 	BUFFER3		*Puntero  recepcion  buffer 3
START3:		DC.L	BUFFER3		*Posición de inicio del buffer 3
END3:		DC.L 	BUFFER3+SIZE	*Posición final del buffer 3

CPYIMR:		DS.B 	1