; Project 6: Designing low-level I/O procedures    (Project6_akkaryb.asm)

; Author: Bashar Akkary
; Last Modified: 5/24/2022
; OSU email address: akkaryb@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number:  6              Due Date: 6/5/2022
; Description: This program receives 10 integer inputs from the user up to numbers too large or too 
;	small to fit in 32 bits. It then displays the list of inputs, their sum, and their truncated average.
;	String inputs are converted to integers before being converted back to strings upon being displayed.

INCLUDE Irvine32.inc

; ---------------------------------------------------------------------------------
; Name: mGetString
;
; Displays a prompt for the user and then reads input and stores it in memory.
;
; Preconditions: none
;
; Postconditions: Stores user input in inputString array. Length of input in EDX.
;
; Receives:
;	prompt: String containing prompt to be prompted
;	strLoc: Offset of array in which user input will be stored
;	count: Maximum size of input string
;	bytesCount: Variable in which store length of input
;
; returns: Length of input in bytesCount
; ---------------------------------------------------------------------------------
mGetString	MACRO prompt, strLoc, count, bytesCount
	
	PUSH EAX
	PUSH ECX
	PUSH EDX
	
	;	 Takes user input, stores it in array at strLoc, stores length in bytesCount
	mDisplayString  prompt
	MOV  ECX, count
	MOV  EDX, strLoc
	CALL ReadString
	MOV  EDX, bytesCount
	MOV  [EDX], EAX

	POP  EAX
	POP  EDX
	POP  ECX

ENDM

; ---------------------------------------------------------------------------------
; Name: mDisplayString
;
; Prints string
;
; Preconditions: none
;
; Postconditions: none
;
; Receives:
;	string: Offset of string to be printed
;
; returns: none
; ---------------------------------------------------------------------------------
mDisplayString	MACRO string

	PUSH EDX

	MOV  EDX, string
	CALL WriteString

	POP  EDX

ENDM

COUNT = 12
INPUT_COUNT = 10

.data

	introString		BYTE	"Designing low-level I/O procedures by Bashar Akkary", 13, 10, 13, 10
					BYTE	"Please provide 10 signed decimal integers.", 13, 10
					BYTE	"Each number needs to be small enough to fit inside a 32 bit register. After you have finished inputting ", 13, 10
					BYTE	"the raw numbers, I will display a list of the integers, their sum, and their average value.", 13, 10, 13, 10, 0
	promptInp		BYTE	"Please enter a signed number: ", 0
	illegalInp		BYTE	"ERROR: Value too large or includes non-numeric values.", 13, 10, 0
	tryAgain		BYTE	"Please try again: ", 0
	valList			SDWORD	10 DUP(?)
	bytesCount		SDWORD	?
	sum				SDWORD	?
	inputString		BYTE	COUNT DUP(?)
	outputString	BYTE	COUNT DUP(?)
	enterFoll		BYTE	"You entered the following numbers:", 13, 10, 0
	commaSpace		BYTE	", ", 0
	totalSum		SDWORD	?
	sumMess			BYTE	"The sum of these numbers is: ", 0
	aveMess			BYTE	"The truncated average is: ", 0
	goodBye			BYTE	"Here's to never writing x86 Assembly code ever again!", 13, 10, 0

.code
main PROC

	;	 Prints introduction, initializes counter and integer array address
   mDisplayString OFFSET introString
	MOV  ECX, INPUT_COUNT
	MOV  EBX, OFFSET valList

	;	 Prints appropriate prompt depending on whether previous input was legal or not
   _inputLoop:
    PUSH OFFSET promptInp
	JMP  _promptMess
   _invalidInp:
    PUSH OFFSET tryAgain
   _promptMess:

	;	 Passes values for and calls ReadVal to receive user input
	PUSH OFFSET inputString
	PUSH COUNT
	PUSH OFFSET bytesCount
	PUSH EBX
	CALL ReadVal
	ADD  EBX, 4

	;	 Displays illegal input message and adjusts address counter
	CMP  EAX, 0
	JNE  _validInp
	SUB  EBX, 4
   mDisplayString OFFSET illegalInp
    JMP  _invalidInp
   _validInp:
	LOOP _inputLoop				;	Test: Gets user input

	;	 Displays message before valid inputs, initializes loop counters for valid inputs list
	CALL CrLf
   mDisplayString OFFSET enterFoll
	MOV  ECX, INPUT_COUNT
	MOV  ESI, 0
    MOV  EBX, OFFSET valList

	;	 Displays list of valid inputs
   _printLoop:
	MOV  EAX, [EBX + ESI]
	PUSH EAX
	PUSH OFFSET outputString
	CALL WriteVal
	CMP  ECX, 1
	JE   _lastVal
   mDisplayString OFFSET commaSpace
   _lastVal:
	ADD  ESI, 4
	LOOP _printLoop				;	Test: Prints list of values

	;	 Test: Displays sum
	CALL CrLf
	PUSH OFFSET valList
   mDisplayString OFFSET sumMess
    CALL calcSum
	MOV  totalSum, EAX
	PUSH EAX
	PUSH OFFSET outputString
	CALL WriteVal
	CALL CrLf

	;	 Test: Displays truncated average
   mDisplayString OFFSET aveMess
	MOV  EAX, totalSum
	PUSH EAX
	CALL calcAve
	PUSH EAX
	PUSH OFFSET outputString
	CALL WriteVal
	CALL CrLf

	;	 Displays farewell message
	CALL CrLf
   mDisplayString OFFSET goodBye

	Invoke ExitProcess,0	; exit to operating system
main ENDP

; ---------------------------------------------------------------------------------
; Name: ReadVal
;
; Receives input from user, converts to a signed integer, and stores it in an array
;
; Preconditions: none
;
; Postconditions: Array of integers corresponding to user input created.
;
; Receives:
;	[EBP + 32]: String containing prompt to be prompted
;	[EBP + 28]: Offset of array in which user input will be stored
;	[EBP + 24]: Maximum size of input string
;	[EBP + 20]: Variable in which store length of input
;	[EBP + 16]: Offset of array in which converted values are stored
;
; returns: none
; ---------------------------------------------------------------------------------
ReadVal PROC 	

	PUSH EBP
	PUSH ECX
	PUSH EBX
	MOV  EBP, ESP

	;	 Gets user input
   mGetString [EBP + 32], [EBP + 28], [EBP + 24], [EBP + 20]

    ;	 Pushes parameters for ConvertToInt subprocedure
	MOV  EBX, [EBP + 16]
	PUSH EBX
	MOV  EBX, [EBP + 28]
	PUSH EBX
	MOV  EBX, [EBP + 20]
	MOV  EBX, [EBX]
	PUSH EBX
	CALL ConvertToInt 

	POP EBX
	POP ECX
	POP EBP
	RET 20

ReadVal ENDP

; ---------------------------------------------------------------------------------
; Name: ConvertToInt
;
; Converts string to integer. Validates that string represents an integer and that it is
;	the correct size, returns boolean of 1 if valid and 0 otherwise.
;
; Preconditions: User must have input a string
;
; Postconditions: Changes EAX
;
; Receives:
;	[EBP + 32]: Array address in which converted integer is stored
;	[EBP + 28]: Offset of array containing string to be converted
;	[EBP + 24]: Length of string to be converted
;
; returns: Boolean in EAX
; ---------------------------------------------------------------------------------
ConvertToInt PROC USES EBX ECX EDX ESI

	PUSH EBP
	MOV  EBP, ESP

	;	 Initializes counter, string address, accumulator, and divisor respectively
	MOV  ECX, [EBP + 24]
	MOV  ESI, [EBP + 28]
	MOV  EDX, 0
	MOV  EAX, 0
	MOV  EBX, 10

	;	 Checks to see if first byte is minus sign
	LODSB
	CMP  AL, 45
	JNE  _positiveVal
	DEC  ECX
	PUSH -1

	;	 Checks to see if first byte is plus sign
    JMP  _negativeValue
   _positiveVal:
	CMP  AL, 43
	JNE  _toLoop
	DEC  ECX
	JMP  _signedVal

	;	 Decrements loop back to address of first byte if it is not minus or plus
   _toLoop:
	DEC  ESI
   _signedVal:
	PUSH 1
   _negativeValue:

    ;	 Checks to see if character is legal
   _iterateStr:
	LODSB
	CMP  AL, 48
	JL   _notLegal
	CMP  AL, 57
	JG   _notLegal
	SUB  AL, 48

	;	 Jumps if result of accumulation exceeds 32 bits, skips multiplication of 10 in last iteration
	ADD  EAX, EDX
	JC   _notLegal
	CMP  ECX, 1
	JE   _lastLoop

	;	 Multiplies digit by 10
	MUL  EBX
	CMP  EDX, 0
	JNE  _notLegal

	;	 Saves multiplication result to accumulator
	MOV  EDX, EAX
	MOV  EAX, 0
   _lastLoop:
	LOOP _iterateStr
	
	;	 Checks popped boolean for whether converted value is negative
	POP  EBX
	CMP  EBX, -1
	JNE  _notNegative

	;	 Checks to see if value is too small, negates if not
	CMP  EAX, 4294967295
	JE   _tooSmall
	NEG  EAX
   _notNegative:

    ;	 Stores converted value in passed address and sets EAX to valid boolean for return
	MOV  EBX, [EBP + 32]
	MOV  [EBX], EAX
	MOV  EAX, 1
	JMP  _end

	;	 Pops EBX to reset stack if necessary and sets EAX invalid boolean for return
   _notLegal:
	POP  EBX
   _tooSmall:
    MOV  EAX, 0

   _end:
	POP  EBP
	RET  12

ConvertToInt ENDP

; ---------------------------------------------------------------------------------
; Name: WriteVal
;
; Converts integer to string and displays it. Algorithm reverses order of integer when
;	converting to string, and thus ConvertToInt is called before the algorithm is run 
;	again in order to get the correct string. For example, if the integer is 100, it will be
;	converted to the string ‘001’. This will then be converted back to integer, resulting in
;	1. The leading zeros are counted and then reinserted in the proper place once 1 is
;	converted back into a string, resulting in the string ‘100’. Minus signs are also recorded
;	and stored for later insertion
;
; Preconditions: String writing destination initialized
;
; Postconditions: Integer value converted to string and printed. outputString contains
;	converted string.
;
; Receives:
;	[EBP + 48]: Integer value to be converted to a string and displayed
;	[EBP + 44]: Address of array destination in which converted integer will be stored
;
; returns: none
; ---------------------------------------------------------------------------------
WriteVal PROC USES EAX EBX ECX EDX ESI EDI

	;	 Makes space on stack for three local variables
	PUSH EBP
	SUB  ESP, 12
	MOV  EBP, ESP

	;	 Sets EAX to value being converted, EDI to address of array destination
	MOV  EAX, [EBP + 48]
	MOV  EBX, 10
	MOV  EDI, [EBP + 44]

	;	 Skips entire algorithm and stores 0 string if input is 0
	CMP  EAX, 0
	JNE  _valNotZero
	ADD  EAX, 48
	STOSB
	JMP  _valZero
   _valNotZero:

	;	 Checks if integer is negative, negates and stores boolean in ESI if it is
	CMP  EAX, 0
	JGE   _notNeg
	MOV  ESI, 1
	NEG  EAX
   _notNeg:

	;	 Sets ending zero flag and counter
	MOV  ECX, 0
	MOV  [EBP + 4], ECX
	MOV  ECX, 0
	MOV  [EBP+8], ECX

	;	 Starts first convert to string loop
   _quoNotZero1:
	MOV  EDX, 0
	IDIV EBX

	;	 Checks to see if ending zeros are done being checked
	MOV  ECX, [EBP + 4]
	CMP  ECX, 2
	JGE   _factorCheckDone
	CMP  EDX, 0					;	Check to see if remainder is zero
	JNE  _notZero

	;	 Checks to see whether zero remainder is an ending zero
	MOV  ECX, 1
	MOV  [EBP + 4], ECX
	MOV  ECX, [EBP + 8]
	INC  ECX
	MOV  [EBP + 8], ECX
	JMP  _factorCheckDone
	
	;	 Sets ending zero check flag to 2 if remainder is not zero
   _notZero:
	MOV  ECX, 2
	MOV  [EBP + 4], ECX
   _factorCheckDone:

	;	 Writes character to destination array
	ADD  EDX, 48
	MOV  ECX, EAX
	MOV  EAX, EDX
	STOSB
	MOV  EAX, ECX
	CMP  EAX, 0
	JNE  _quoNotZero1
  
	;	 Pushes appropriate values to stack for ConvertToInt
	MOV  EBX, EBP
	PUSH EBX					;	Creates space for local value
	MOV  EBX, [EBP + 44]		;	Pushes address of reversed string
	PUSH EBX
	SUB  EDI, EBX				;	Calculates size of string
	PUSH EDI					
	MOV  EDI, ESI
	CALL ConvertToInt
	MOV  ESI, EDI
	
	;	 Stores reversed integer to EAX, initializes EDI back to outputString address
	MOV  EAX, [EBP]
	MOV  EBX, 10
	MOV  EDI, [EBP + 44]

	;	 Adds minus sign to first character of string if original value is negative
	CMP  ESI, 1
	JNE  _notMinus
	MOV  EAX, 45
	STOSB
	MOV  EAX, [EBP]
   _notMinus:

	;	 Same algorithm as _quoNotZero loop, see above comments
   _quoNotZero2:
	MOV  EDX, 0
	IDIV EBX
	ADD  EDX, 48				;	Converts integer to ASCII character
	MOV  ECX, EAX
	MOV  EAX, EDX
	STOSB
	MOV  EAX, ECX
	CMP  EAX, 0					;	Checks to see if quotient is zero in order to end conversion
	JNE  _quoNotZero2

	;	 Adds ending zero to output string
	MOV  ECX, [EBP + 8]
	CMP  ECX, 0
	JE   _flagNotTwo
	MOV  ECX, [EBP + 8]
   _addZero:
	MOV  EAX, 48
	STOSB
	LOOP _addZero
   _flagNotTwo:

	;	 Terminate and display string
   _valZero:
	MOV  EAX, 0
	STOSB
   mDisplayString [EBP + 44]

	ADD  ESP, 12
	POP  EBP
	RET  8

WriteVal ENDP

; ---------------------------------------------------------------------------------
; Name: calcSum
;
; Calculates sum of inputted numbers
;
; Preconditions: Array of integers initialized
;
; Postconditions: Changes EAX
;
; Receives:
;	[EBP + 8]: Array of integer values user inputted
;
; returns: Sum in EAX
; ---------------------------------------------------------------------------------
calcSum PROC USES EBX ECX ESI

	PUSH EBP
	MOV  EBP, ESP

	;	 Initialize address of first element of array, accumulator, counters
	MOV  EBX, [EBP + 20]
	MOV  ESI, 0
	MOV  EAX, 0
	MOV  ECX, INPUT_COUNT

	;	 Loop that calculates the sum
   _sumLoop:
	ADD  EAX, [EBX + ESI]
	ADD  ESI, 4
	LOOP _sumLoop

	POP  EBP
	RET  4

calcSum ENDP

; ---------------------------------------------------------------------------------
; Name: calcAve
;
; Calculates the truncated average of the inputted values
;
; Preconditions: Sum calculated 
;
; Postconditions: EAX
;
; Receives:
;	[EBP + 8]: Sum of inputted integers
;
; returns: Truncated average in EAX
; ---------------------------------------------------------------------------------
calcAve PROC USES EBX EDX

	PUSH EBP
	MOV  EBP, ESP
	MOV  EAX, [EBP + 16]

	;	 Divides sum by number of user inputs
	MOV  EAX, totalSum
	MOV  EBX, INPUT_COUNT
	MOV  EDX, 0
	CDQ
	IDIV EBX

	POP  EBP
	RET  4

calcAve ENDP

END main
