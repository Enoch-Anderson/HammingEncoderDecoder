.data 0x10000000
## strToBinary necessary data ##
String: .space 16       # offset 0
Lsb: .word 0x1000000    # offset 16
Next: .word 0x10000     # offset 20
Next2: .word 0x100      # offset 24
Msb: .word 0x1          # offsset 28

## binaryToStringPrint necessary data ##
ElevenCharacters: .asciiz "aaaaaaaaaaa"         # offset 32
.align 1
SixteenCharacters: .asciiz "bbbbbbbbbbbbbbbb" #addres offset 44
.align 4
FiveCharacters: .asciiz "ccccc" #address offset 64 
.align 3

## Required for project ##
.space 4 #11 bits of data       offset 72
.space 4 #16 bits of hamming    offset 76
.space 4 #5 bit syndrome        offset 80

## Texts to print to console ##
FirstMessage: .asciiz "Please input a 1 to encode 11 bits, 2 to decode 16 bit Hamming encoded codeword " # offset 0x54
.align 4
SecondMessage: .asciiz "Please input the your data or codeword " # offset 0xb0
.align 4
EncodeSelected: .asciiz " You're hamming encoded code word is " # offset 0xe0
.align 4
Syndrome: .asciiz " Syndrome "  # offset 0x110
.align 4
InitialEXData: .asciiz " Initial extracted data "  # offset 0x120
.align 4
PassFail: .asciiz " Passed, No Bit Flips " # offset 0x140
.align 4
Fail: .asciiz " Failed, One bit flipped.  Corrected data " # offset 0x160
.align 4
FailCntFix: .asciiz " Failed, Two or more bits flipped.  Cannot return correct data " # offset 0x190
.align 4
ParityBitFlipped: .asciiz " Failed, but it was a parity bit that flipped.  Data was correct " # offset 0x1d0

.text 
main:
    addi $sp, $sp , -4 #make room in stack pointer
    sw $ra, ($sp) #preserve ra for use later
    or $zero, $zero, $zero #no op

    ###Bug fixer piece##
    add $t7, $zero, $ra #t7 stores the address for the end
    ###Bug fixer piece this will work for now##

    #Print first Message
    addi $v0, $zero, 4 #print string syscall
    add $a0, $zero, $zero #clear a0
    lui $a0, 0x1000 #load upper part of data address
    ori $a0, $a0, 0x54 #a0 now memory address for string
    syscall
    or $zero, $zero, $zero #no op

    #Read in first input
    addi $v0, $zero, 5 #read int syscall
    syscall
    add $t1, $v0, $zero #t1 = int read in

    #Print second Message
    addi $v0, $zero, 4 #print string syscall
    add $a0, $zero, $zero #clear a0
    lui $a0, 0x1000 #load upper part of data address
    ori $a0, $a0, 0xb0 #a0 now memory address for string
    syscall
    or $zero, $zero, $zero #no op

    #jump to appropraiate place
        #if t1 = 1 jump to read 11
    addi $t2, $zero, 1
    beq $t1, $t2, ReadIn11bits
    or $zero, $zero, $zero #no op

        #else jump to read in 16
    j ReadIn16bits
    or $zero, $zero, $zero #no op
    
EndOfMain:
    lw $ra, ($sp) #restore ra
    or $zero, $zero, $zero #no op
    addi $sp, $sp, 4 #put back where it was

    jr $ra
    or $zero, $zero, $zero #no op

ReadIn16bits: 
    add $a0, $zero, $zero #clear a0
    lui $a0, 0x1000 #a0 address of where the string data goes
    addi $a3, $zero, 16 #a3 is number of bits read in
    jal str_to_binary #v1 output, bits of data read in in binary
    or $zero, $zero, $zero #no op
    add $a1, $v1, $zero #a1 is parameter for decode
    jal Decode #decode and print appropriate things
    or $zero, $zero, $zero #no op
    j EndOfMain
    or $zero, $zero, $zero #no op


ReadIn11bits:
    add $a0, $zero, $zero #clear a0
    lui $a0, 0x1000 #a0 address of where the string data goes
    addi $a3, $zero, 11 #a3 is number of bits read in
    jal str_to_binary #v1 output, bits of data read in in binary
    or $zero, $zero, $zero #no op
    add $a1, $v1, $zero #a1 is parameter for Encode
    jal Encode #encode
    or $zero, $zero, $zero #no op
    jal PrintforEncode #print appropriate things
    or $zero, $zero, $zero #no op

    j EndOfMain
    or $zero, $zero, $zero #no op

















##################################################################### Decode ##############################################################################################
#a1 is 16 bits of data to decode
Decode:#a1,s7 = codeword, s2 = pulled off syndrome, s3 = where the syndrome has errors, pulled off data stored in s5
    addi $sp, $sp , -4 #make room
    sw $ra, ($sp) #preserve ra
    or $zero, $zero, $zero #no op

    add $s7, $a1, $zero #originally entered data will be stored in s7 for use later (if there is only one data bit flipped)

    jal ExtractParityErrors #extract where the errors are 
    or $zero, $zero, $zero #no op
    add $a1, $s7, $zero #a1 = originally entered data again
    jal PullOffData #stores pulled off data in s5, a1 codeword
    or $zero, $zero, $zero #no op

    #Print initially extracted data
        #print string
    addi $v0, $zero, 4 #print string syscall
    add $a0, $zero, $zero #clear a0
    lui $a0, 0x1000 #load upper part of data address
    ori $a0, $a0, 0x120 #a0 now memory address for string
    syscall
    or $zero, $zero, $zero #no op
        #print data
    add $a1, $s5, $zero #a1 is data to print
    addi $a0, $zero, 11 #a0 is number of bits to print
    jal printString
    or $zero, $zero, $zero #no op

    or $zero, $zero, $zero #extra noop to set breakpoint for testing#######################################################################

    #Find if error or not, fix if possible
        #handle no errors
    beq $s3, $zero, NoError
    or $zero, $zero, $zero #no op


    

        #handle two or more bits flipped
    slti $t1, $s3, 17 #t1 is 1 if s3 <= 16
    addi $t2, $zero, 1 #t2 will be used for compaprison
    beq $t1, $t2, TwoFlips # Two or more bits flipped if t1 = 1
    or $zero, $zero, $zero #no op
        
        #handle only parity bit flipped
    addi $t2, $zero, 16 #set t2 = 16 for comparison
    beq $s3, $t2, OnlyParityFlipped #if s3 = 16 only p4 got flipped
    or $zero, $zero, $zero #no op
    andi $s3, $s3, 15 #only count the the number of ones in p0-p3
    add $a0, $s3, $zero #a0 input for setup_Count_1's
    jal Setup_Count_1s #v0 output
    or $zero, $zero, $zero #no op
    addi $t1, $zero, 1
    beq $t1, $v1, OnlyParityFlipped #if there is only one 1 in s6 then a parity bit flipped
    or $zero, $zero, $zero #no op


    
        #handle one bit flipped
    # andi $s3, $s3, 15 #s3 is only p0-p3 THIS INSTRUCTION IS ACTUALLLY DONE ALREADY
    j OneDataFlipped
    or $zero, $zero, $zero #no op


ExtractParityErrors: #s1 = codeword, s2 = pulled off syndrome, s3 = where the syndrome has errors
    addi $sp, $sp , -4 #make room
    sw $ra, ($sp) #preserve ra
    or $zero, $zero, $zero #no op

    add $s1, $a1, $zero #s1 = codeword
    add $a0, $zero, $zero #clear a0
    #find p0
    addi $t1, $zero, 0x5555 #t1 mask for p0
    and $a0, $t1, $s1 #a0 is just the bits checked by p0
    jal Setup_Count_1s #v1 output
    or $zero, $zero, $zero #no op
    add $a1, $v1, $zero #a1 = v1
    jal Check_even #v0 output
    or $zero, $zero, $zero #no op
    add $s3, $v0, $zero #s3 now contains p0

    #find p1
    addi $t1, $zero, 0x6666 #t1 mask for p1
    and $a0, $t1, $s1 #a0 is just the bits checked by p1
    jal Setup_Count_1s #v1 output
    or $zero, $zero, $zero #no op
    add $a1, $v1, $zero #a1 = v1
    jal Check_even #v0 output
    or $zero, $zero, $zero #no op
    sll $v0, $v0, 1 #p1 moved to correct position
    or $s3, $v0, $s3 #s3 now contains p1

    #find p2
    addi $t1, $zero, 0x7878 #t1 mask for p2
    and $a0, $t1, $s1 #a0 is just the bits checked by p2
    jal Setup_Count_1s #v1 output
    or $zero, $zero, $zero #no op
    add $a1, $v1, $zero #a1 = v1
    jal Check_even #v0 output
    or $zero, $zero, $zero #no op
    sll $v0, $v0, 2 #p1 moved to correct position
    or $s3, $v0, $s3 #s3 now contains p2

    #find p3
    addi $t1, $zero, 0x7f80 #t1 mask for p3
    and $a0, $t1, $s1 #a0 is just the bits checked by p3
    jal Setup_Count_1s #v1 output
    or $zero, $zero, $zero #no op
    add $a1, $v1, $zero #a1 = v1
    jal Check_even #v0 output
    or $zero, $zero, $zero #no op
    sll $v0, $v0, 3 #p1 moved to correct position
    or $s3, $v0, $s3 #s3 now contains p3

    #find p4
    addi $t1, $zero, 0x7fff
    addi $t1, $t1, 1
    addi, $t1, $t1, 0x7fff #t1 = mask for p4
    and $a0, $t1, $s1 #a0 is just the bits checked by p4
    jal Setup_Count_1s #v1 output
    or $zero, $zero, $zero #no op
    add $a1, $v1, $zero #a1 = v1
    jal Check_even #v0 output
    or $zero, $zero, $zero #no op
    sll $v0, $v0, 4 #p1 moved to correct position
    or $s3, $v0, $s3 #s3 now contains p4

    lw $ra, ($sp) #restore ra
    or $zero, $zero, $zero #no op
    addi $sp, $sp, 4 #put back where it was
    #End decode
    jr $ra
    or $zero, $zero, $zero #no op

TwoFlips: 
    #print Error Two or more flips
    addi $v0, $zero, 4 #print string syscall
    add $a0, $zero, $zero #clear a0
    lui $a0, 0x1000 #load upper part of data address
    ori $a0, $a0, 0x190 #a0 now memory address for string
    syscall
    or $zero, $zero, $zero #no op

    #return data again
    add $a1, $s5, $zero #a1 is data to print
    addi $a0, $zero, 11 #a0 is number of bits to print
    jal printString
    or $zero, $zero, $zero #no op

    #End Two Flips
    j EndDecode
    or $zero, $zero, $zero #no op

NoError: 
    #print No error pass
    addi $v0, $zero, 4 #print string syscall
    add $a0, $zero, $zero #clear a0
    lui $a0, 0x1000 #load upper part of data address
    ori $a0, $a0, 0x140 #a0 now memory address for string
    syscall
    or $zero, $zero, $zero #no op

    #return data again
    add $a1, $s5, $zero #a1 is data to print
    addi $a0, $zero, 11 #a0 is number of bits to print
    jal printString
    or $zero, $zero, $zero #no op

    #End NoError
    j EndDecode
    or $zero, $zero, $zero #no op

OnlyParityFlipped: 
    #print Only parity bit flipped
    addi $v0, $zero, 4 #print string syscall
    add $a0, $zero, $zero #clear a0
    lui $a0, 0x1000 #load upper part of data address
    ori $a0, $a0, 0x1d0 #a0 now memory address for string
    syscall
    or $zero, $zero, $zero #no op

    #return data again
    add $a1, $s5, $zero #a1 is data to print
    addi $a0, $zero, 11 #a0 is number of bits to print
    jal printString
    or $zero, $zero, $zero #no op

    #End OnlyParityFlipped
    j EndDecode
    or $zero, $zero, $zero #no op

OneDataFlipped:
    #print Error one bit flipped
    addi $v0, $zero, 4 #print string syscall
    add $a0, $zero, $zero #clear a0
    lui $a0, 0x1000 #load upper part of data address
    ori $a0, $a0, 0x160 #a0 now memory address for string
    syscall
    or $zero, $zero, $zero #no op

    #fix flipped bit
    add $a3, $s3, $zero #number of shifts needed is s3 minus 1
    jal Shifter #v0 output
    or $zero, $zero, $zero #no op
    xor $a1, $s7, $v0 #fix flipped bit
    jal PullOffData #stores pulled off data in s5, a1 codeword
    or $zero, $zero, $zero #no op

    #print fixed data
    add $a1, $s5, $zero #a1 is data to print
    addi $a0, $zero, 11 #a0 is number of bits to print
    jal printString
    or $zero, $zero, $zero #no op

    #End OnlyParityFlipped
    j EndDecode
    or $zero, $zero, $zero #no op


Shifter: #takes a3or $zero, $zero, $zero #no op as parameter: number of shifts needed, v0 output: 1 in idx of a3. (idx starts counting from 0)
    addi $v0, $zero, 1 #v0 initilized as 1
    addi $t6, $zero, 1 #t6 initilized as 1
    j Loop2 #jump to loop
    or $zero, $zero, $zero #no op

Loop2: #loops until a3 = 0
    beq $a3, $t6, ExitLoop2
    or $zero, $zero, $zero #no op
    addi $a3, $a3, -1 #a3--
    sll $v0, $v0, 1 #shift 1 over 1
    j Loop2
    or $zero, $zero, $zero #no op

ExitLoop2:
    jr $ra #return where came from
    or $zero, $zero, $zero #no op





PullOffSyndrome: #stores syndrome in s4, a1 codeword
    #Extract current syndrome Store in s4
        #p0
    addi $t1, $zero, 3 #t1 mask for p0, p1
    and $t1, $t1, $a1 #t1 now p0, p1
    add $s4, $t1, $zero #s2 now has p0 and p1
        #p2 next
    addi $t1, $zero, 8 #t1 mask for p2
    and $t1, $t1, $a1 #t1 now p2
    srl $t1, $t1, 1 #p2 in correct position
    or $s4, $s4, $t1 #p2 added
        #p3 next
    addi $t1, $zero, 128 #t1 mask for p3
    and $t1, $t1, $a1 #t1 = p3
    srl $t1, $t1, 4 #p3 in correct position
    or $s4, $s4, $t1 #p3 added
        #p4 next
    addi $t1, $zero, 1 #t1 will be mask for p2
    sll $t1, $t1, 15 #t1 now mask
    and $t1, $t1, $a1 # t1 now p4
    srl $t1, $t1, 11 # t1 now in correct position
    or $s4, $s4, $t1 # p4 added
    
    #End PullOffSyndrome
    jr $ra
    or $zero, $zero, $zero #no op

PullOffData: #stores pulled off data in s5, a1 is codeword
    #Extract data bits, s5 used to hold value
        #first data bit
    addi $t1, $zero, 4 #t1 mask for first data bit
    and $t1, $t1, $a1 #t1 = first data bit
    srl $t1, $t1, 2 #t1 in correct position
    add $s5, $zero, $t1 #first data bit added
        #next 3 data bits
    addi $t1, $zero, 112 #t1 mask for next 3 data bits
    and $t1, $t1, $a1 #t1 next 3 data bits
    srl $t1, $t1, 3 #bits now in correct position
    or $s5, $s5, $t1 #next 3 bits added
        #last block of 7 bits
    addi $t1, $zero, 32512 #t1 mask for last 7 bits
    and $t1, $t1, $a1 #t1 last 7 bits
    srl $t1, $t1, 4 #bits in correct position
    or $s5, $s5, $t1 #7 bits added
    #Move value from s5 to a1 for Encode
    add $a1, $s5, $zero

    #End PullOffData
    jr $ra
    or $zero, $zero, $zero #no op

EndDecode: 
    lw $ra, ($sp) #restore ra
    or $zero, $zero, $zero #no op
    addi $sp, $sp, 4 #put back where it was
    #End decode
    jr $ra
    or $zero, $zero, $zero #no op


##################################################################### End Decode ##############################################################################################




















##################################################################### Encode ##############################################################################################
#a1 will be the 11 bits of data, 
Encode: 
    #preserve ra 
    addi $sp, $sp -4 #make room
    sw $ra, ($sp) #preserve ra
    or $zero, $zero, $zero #no op

    jal addDataBits
    or $zero, $zero, $zero #no op

        #restore ra
    lw $ra, ($sp) #restore ra
    or $zero, $zero, $zero #no op
    addi $sp, $sp, 4 #restore sp
    #End Encode
    jr $ra
    or $zero, $zero, $zero #no op

addDataBits:
    #First must add all the data to the 16 bit hamming encoded codeword, t1 will be masks, s2 will hold the codeword, a1 is data which is moved to s1
    add $s1, $zero, $a1 #data preserved in s1
    addi $t1, $zero, 1 #t1 is mask to extract first bit
    and $t1, $a1, $t1 #t1 is now data bit
    sll $t1, $t1, 2 #bit now in correct position
    or $s2, $zero, $t1 #First data bit added
    #second third fourth bits
    addi $t1, $zero, 14 #t1 mask for 2nd 3rd 4th bits
    and $t1, $t1, $a1 #t1 now data bits
    sll $t1, $t1, 3 #t1 now bits moved to correct position
    or $s2, $t1, $s2 #Data bits added
    #last set of bits
    addi $t1, $zero, 2032 #t1 now mask
    and $t1, $a1, $t1 #t1 now data bits
    sll $t1, $t1, 4 #bits now in correct position
    or $s2, $t1, $s2 #bits added

CalculateAndAddParityBits:
    #This must calculate each parity bits and add them to the codeword, and the syndrome register
    #preserve ra 
    addi $sp, $sp -4 #make room
    sw $ra, ($sp) #preserve ra
    or $zero, $zero, $zero #no op

    #calc first parity bits p0 and add (s2 codeword, t1 mask, s3 syndrome)
    addi $t1, $zero, 21844 #t1 is mask
    and $a0, $t1, $s2 #a0 parameter for Setup_Count_1s
    jal Setup_Count_1s
    or $zero, $zero, $zero #no op
    add $a1, $zero, $v1 #a1 = v1, this is the parameter for Check_even
    jal Check_even #Get correect value for parity bit, output is v0
    or $zero, $zero, $zero #no op
    or $s2, $s2, $v0 #Don't need to shift p0, just add it
    add $s3, $zero, $v0 #add p0 to syndrome

    #calc and add p1
    addi $t1, $zero, 26212 #t1 is mask
    and $a0, $t1, $s2 #a0 parameter for Setup_Count_1s
    jal Setup_Count_1s
    or $zero, $zero, $zero #no op
    add $a1, $zero, $v1 #a1 = v1, this is the parameter for Check_even
    jal Check_even #Get correect value for parity bit, output is v0
    or $zero, $zero, $zero #no op
    sll $v0, $v0, 1 #shift parity bit to correct location
    or $s2, $s2, $v0 #Add parity bit p1
    or $s3, $s3, $v0 #add p1 to syndrome

    #calc and add p2
    addi $t1, $zero, 30832 #t1 is mask
    and $a0, $t1, $s2 #a0 parameter for Setup_Count_1s
    jal Setup_Count_1s
    or $zero, $zero, $zero #no op
    add $a1, $zero, $v1 #a1 = v1, this is the parameter for Check_even
    jal Check_even #Get correect value for parity bit, output is v0
    or $zero, $zero, $zero #no op
    sll $v0, $v0, 3 #shift parity bit to correct location
    or $s2, $s2, $v0 #Add parity bit p2 to codeword
    srl $v0, $v0, 1 #Shift to correct position for syndrome
    or $s3, $s3, $v0 #add p2 to syndrome

    #calc and add p3
    addi $t1, $zero, 32512 #t1 is mask
    and $a0, $t1, $s2 #a0 parameter for Setup_Count_1s
    jal Setup_Count_1s
    or $zero, $zero, $zero #no op
    add $a1, $zero, $v1 #a1 = v1, this is the parameter for Check_even
    jal Check_even #Get correect value for parity bit, output is v0
    or $zero, $zero, $zero #no op
    sll $v0, $v0, 7 #shift parity bit to correct location
    or $s2, $s2, $v0 #Add parity bit p3 to codeword
    srl $v0, $v0, 4 #Shift to correct position for syndrome
    or $s3, $s3, $v0 #add p3 to syndrome

    #calc and add p4
    addi $t1, $zero, 32767 #t1 is mask
    and $a0, $t1, $s2 #a0 parameter for Setup_Count_1s
    jal Setup_Count_1s
    or $zero, $zero, $zero #no op
    add $a1, $zero, $v1 #a1 = v1, this is the parameter for Check_even
    jal Check_even #Get correect value for parity bit, output is v0
    or $zero, $zero, $zero #no op
    sll $v0, $v0, 15 #shift parity bit to correct location
    or $s2, $s2, $v0 #Add parity bit p4 to codeword
    srl $v0, $v0, 11 #Shift to correct position for syndrome
    or $s3, $s3, $v0 #add p4 to syndrome

    #Storing in correct places in memeory
    add $t1, $zero, $zero #t0 = 0
    lui $t1, 0x1000 #t1 = data addresses
    sw $s1, 72($t1) #storing data in correct location
    or $zero, $zero, $zero #no op
    sw $s2, 76($t1) #storing codeword in correct location
    or $zero, $zero, $zero #no op
    sw $s3, 80($t1) #storing syndrome in correct location
    or $zero, $zero, $zero #no op

    #restore ra
    lw $ra, ($sp) #restore ra
    or $zero, $zero, $zero #no op
    addi $sp, $sp, 4 #restore sp
    #End Encode
    jr $ra
    or $zero, $zero, $zero #no op
##################################################################### End Encode ##############################################################################################











############################################## Print for Encode ######################################################
PrintforEncode: 
    #preserve ra 
    addi $sp, $sp -4 #make room
    sw $ra, ($sp) #preserve ra
    or $zero, $zero, $zero #no op

    #printing appropriate things
        #print string "you're codeword is"
    addi $v0, $zero, 4 #print string syscall
    add $a0, $zero, $zero #clear a0
    lui $a0, 0x1000 #load upper part of data address
    ori $a0, $a0, 0xe0 #a0 now memory address for string
    syscall
    or $zero, $zero, $zero #no op
        #print Codeword
    add $a1, $s2, $zero #a1 is data to print
    addi $a0, $zero, 16 #a0 is number of bits to print
    jal printString
    or $zero, $zero, $zero #no op

        #print string "your syndrome is"
    addi $v0, $zero, 4 #print string syscall
    add $a0, $zero, $zero #clear a0
    lui $a0, 0x1000 #load upper part of data address
    ori $a0, $a0, 0x110 #a0 now memory address for string
    syscall
    or $zero, $zero, $zero #no op

        #print syndrome
    add $a1, $s3, $zero #a1 is data to print
    addi $a0, $zero, 5 #a0 is number of bits to print
    jal printString
    or $zero, $zero, $zero #no op



    #restore ra
    lw $ra, ($sp) #restore ra
    or $zero, $zero, $zero #no op
    addi $sp, $sp, 4 #restore sp
    #End Encode
    jr $ra
    or $zero, $zero, $zero #no op
############################################## End Print for Encode ######################################################


    















   
############################################################### strToBinary ###############################################################################################################
str_to_binary:
    #preserving some things 
    addi $sp, $sp, -4 #make room for ra
    sw $ra, ($sp) #store ra for use later
    or $zero, $zero, $zero #no op


    #####a0 will be the number of desired bits to be read in ###########
    addi $t4, $zero, 11 #t4 = 11 to compare
    beq $a3, $t4, Set_12 #if a0 = 11, set a1 = 12
    or $zero, $zero, $zero #no op
    addi $a1, $zero, 17 #else a1 = 17
    j Body
    or $zero, $zero, $zero #no op

Set_12:
    addi $a1, $zero, 12 #a1 = 12
    j Body
    or $zero, $zero, $zero #no op


Body: 
    #reading in data
    addi $v0, $zero, 8 #v0 = 8
    and $a0, $a0, $zero #clear a0
    lui $a0, 0x1000 #a0 = mem address
    or $zero, $zero, $zero #no op
    syscall

    #a0 stays the same for the first block to process
    lw $a1, ($a0) #a1 = data for first block
    or $zero, $zero, $zero #no op
    jal ProcessBlock
    or $zero, $zero, $zero #no op

    add $t4, $v1, $zero #t4 temporary place to hold output until v1 no longer needed

    #move a0 to next block and process, then add to t4
    addi $a0, $a0, 4 #a0 = a0 + 4
    lw $a1, ($a0) #a1 data from next block
    or $zero, $zero, $zero #no op
    jal ProcessBlock
    or $zero, $zero, $zero #no op
    sll $t4, $t4, 4 #ready to input next 4 bits into t4
    or $t4, $t4, $v1 #next 4 bits added to t1

    #move a0 to next block and process, than add to t4
    addi $a0, $a0, 4 #a0 = a0 + 4
    lw $a1, ($a0) #a1 data from next block
    or $zero, $zero, $zero #no op
    jal ProcessBlock
    or $zero, $zero, $zero #no op
    sll $t4, $t4, 4 #ready to input next 4 bits into t4
    or $t4, $t4, $v1 #next 4 bits added to t1

    #move a0 to last block and process, than add to t4
    addi $a0, $a0, 4 #a0 = a0 + 4
    lw $a1, ($a0) #a1 data from next block
    or $zero, $zero, $zero #no op
    jal ProcessBlock
    or $zero, $zero, $zero #no op
    sll $t4, $t4, 4 #ready to input next 4 bits into t4
    or $t4, $t4, $v1 #next 4 bits added to t1

    #v1 is output
    add $v1, $t4, $zero

    #if a3 = 11, shift output right five bits
    addi $t4, $zero, 11 #t4 = 11 to compare
    beq $a3, $t4, Shift_5 #if a0 = 11, jump to shift 5
    or $zero, $zero, $zero #no op
    j End #else jump to end
    or $zero, $zero, $zero #no op

Shift_5: 
    srl $v1, $v1, 5 #shift five bits right for desired 11 bit output
    j End 
    or $zero, $zero, $zero #no op


End: 
    #restoring ra and sp, and other variables used
    lw $ra, ($sp) #restoring ra for use later
    or $zero, $zero, $zero #no op
    addi $sp, $sp, 4 #make room for ra

    #end
    jr $ra
    or $zero, $zero, $zero #no op

ProcessBlock: 
    #Preserving the values of everything used
    addi $sp, $sp, -16 #make room
    sw $s1, ($sp) #preserve s1
    or $zero, $zero, $zero #no op
    sw $s2, 4($sp) #preserve s2
    or $zero, $zero, $zero #no op
    sw $s3, 8($sp) #preserve s3
    or $zero, $zero, $zero #no op
    sw $s4, 12($sp) #preserve s4
    or $zero, $zero, $zero #no op

    #getting lsb 
    lui $a2, 0x1000 #loading a2 to address for mask
    ori $a2, 16 #a2 is now the address for first mask
    and $v0, $zero, $zero #v0 = 0, initializing v0 output
    lw $t1, ($a2) #t1 = first mask
    or $zero, $zero, $zero #no op
    and $s1, $t1, $a1 #s1 = lsb
    srl $s1, $s1, 24 #s1 now in correct position

    #Getting next bit
    addi $a2, 4 #a2 address for second mask
    lw $t1, ($a2) #t1 second mask
    or $zero, $zero, $zero #no op
    and $s2, $t1, $a1 #s2 = next bit
    srl $s2, $s2, 15 #s2 now in correct position

    #Getting next bit
    addi $a2, 4 #a2 address for third mask
    lw $t1, ($a2) #t1 third mask
    or $zero, $zero, $zero #no op
    and $s3, $t1, $a1 #s3 = next bit
    srl $s3, $s3, 6 #s3 now in correct position

    #Getting msb
    addi $a2, 4 #a2 address for msb
    lw $t1, ($a2) #t1 msb mask
    or $zero, $zero, $zero #no op
    and $s4, $t1, $a1 #s4 = msb
    sll $s4, $s4, 3 #s4 now in correct position

    #putting together for output
    add $v1, $zero, $zero #clear v0
    or $v1, $v1, $s4 #add s4
    or $v1, $v1, $s3 #add s3
    or $v1, $v1, $s2 #add s2
    or $v1, $v1, $s1 #add s1

    #restoring values of everything
    lw $s1, ($sp) #restore s1
    or $zero, $zero, $zero #no op
    lw $s2, 4($sp) #restore s2
    or $zero, $zero, $zero #no op
    lw $s3, 8($sp) #restore s3
    or $zero, $zero, $zero #no op
    lw $s4, 12($sp) #restore s4
    or $zero, $zero, $zero #no op
    addi $sp, $sp, 16 #remove space

    jr $ra #jump back to callee 
    or $zero, $zero, $zero #no op
############################################################### End strToBinary ###########################################################################################################






















############################################################### binaryToStringPrint #######################################################################################################
printString: #This was orriginally for testing and now is modified to work here
    #preserve ra
    addi $sp, $sp -4
    sw $ra, ($sp) 
    or $zero, $zero, $zero

    jal printString_next
    or $zero, $zero, $zero


    #restore ra
    lw $ra, ($sp)
    or $zero, $zero, $zero
    addi $sp, $sp 4

    #End
    jr $ra
    or $zero, $zero, $zero

printString_next: 
    addi $t1, $zero, 5 #t1 = 5
    beq $t1, $a0, printString5 #if a0 = 5 jump to printString5
    or $zero, $zero, $zero #no op
    addi $t1, $zero, 11 #t1 = 11
    beq $t1, $a0, printString11 #if a0 = 11 jump to printString11
    or $zero, $zero, $zero#no op
    addi $t1, $zero, 16 #t1 = 16
    beq $t1, $a0, printString16 #if a0 = 5 jump to printString16
    or $zero, $zero, $zero#no op
    #Exit, no need to jr ra here because each helper function does the jr ra already


printString5: #this will take in a0 as number of bits to print, a1 = data
    #preserve ra
    addi $sp, $sp -4
    sw $ra, ($sp) 
    or $zero, $zero, $zero

    lui $a3, 0x1000
    ori $a3, $a3, 64 #a3 is address of block
    sll $a1, $a1, 27 #move to correct position for first block
    jal Process_Block #v0 will contain 4 ascii characters
    or $zero, $zero, $zero    

    #store v0 in correct location
    sw $v0, ($a3) #storing first block of characters


    #need to take care of lsb still
    srl $t1, $t1, 1 #t1 mask for last bit
    and $t2, $a1, $t1 #t2 = fifth bit to check
    jal Get_Ascii #t4 will be the ascii character
    or $zero, $zero, $zero
    #need to preserve the null terminator
    ####without preserving null terminator this happens
    sw $t4, 4($a3)
    or $zero, $zero, $zero

    ##############The printing#######
    add $a0, $a3, $zero #a0 is now address of string to print
    add $v0, $zero, 4 #print string syscall
    syscall
    ##########End of the printing########

    #restore ra
    lw $ra, ($sp)
    or $zero, $zero, $zero
    addi $sp, $sp 4

    #End Print String
    jr $ra
    or $zero, $zero, $zero

Process_Block: #v0 will be the place block ascii characters will be stored
    #preserve ra
    addi $sp, $sp -4
    sw $ra, ($sp) 
    or $zero, $zero, $zero

    addi $t1, $zero, 1 #start of making t1 mask for first bit
    sll $t1, $t1, 31 #t1 now mask for first bit
    and $t2, $a1, $t1 #t2 = bit 
    jal Get_Ascii #t4 will be the ascii character
    or $zero, $zero, $zero
    add $v0, $zero, $t4 #v0 = first ascii character

    #get 2nd ascii character and add
    srl $t1, $t1, 1 #t1 location of second bit to check
    and $t2, $a1, $t1 #t2 is bit to check
    jal Get_Ascii
    or $zero, $zero, $zero
    sll $t4, $t4, 8 #second character is in the correct position
    or $v0, $v0, $t4 #Second character added to v0

    #get 3rd character to add
    srl $t1, $t1, 1 #t1 location of third bit to check
    and $t2, $a1, $t1 #t2 is bit to check
    jal Get_Ascii
    or $zero, $zero, $zero
    sll $t4, $t4, 16 #Third character is in the correct position
    or $v0, $v0, $t4 #Third character added to v0

    #get 4th character to add
    srl $t1, $t1, 1 #t1 location of fourth bit to check
    and $t2, $a1, $t1 #t2 is bit to check
    jal Get_Ascii
    or $zero, $zero, $zero
    sll $t4, $t4, 24 #Fourth character is in the correct position
    or $v0, $v0, $t4 #Fourth character added to v0


    #restore ra
    lw $ra, ($sp)
    or $zero, $zero, $zero
    addi $sp, $sp 4
    #End
    jr $ra
    or $zero, $zero, $zero

Get_Ascii: 
    beq $t2, $zero, Bit_Zero
    or $zero, $zero, $zero
    addi $t4, $zero, 49 #t4 = 1 in ascii
    j Get_Ascii_next
    or $zero, $zero, $zero


Get_Ascii_next:
    jr $ra
    or $zero, $zero, $zero



Bit_Zero: 
    addi $t4, $zero,  48 #t4 is ascii for 0
    j Get_Ascii_next
    or $zero, $zero, $zero

printString11: 
    #preserve ra
    addi $sp, $sp -4
    sw $ra, ($sp) 
    or $zero, $zero, $zero

    lui $a3, 0x1000 #a3 is address of first block
    ori $a3, $a3, 32 #a3 address of 11 bit string
    sll $a1, $a1, 21 #move to correct position for first block
    jal Process_Block #v0 will contain 4 ascii characters
    or $zero, $zero, $zero 

    #storing first block of characters
    sw $v0, ($a3) #first 4 characters are stored
    or $zero, $zero, $zero 

    #get next block to process
    sll $a1, $a1, 4 #a1 now ready to process next 4
    jal Process_Block
    or $zero, $zero, $zero 

    #storing the second block
    sw $v0, 4($a3) #next 4 characters stored
    or $zero, $zero, $zero 

    #Must get last 3 bits, add them and not kill my null terminator for the string
    sll $a1, $a1, 4
    jal Process_Block
    or $zero, $zero, $zero

    #loading data with null terminator, making zero where the 3 bits go, and then ORing the two, Then returning the 32 bits where they came from
    lw $t4, 8($a3) #a3 now what is currently in where the block will go
    or $zero, $zero, $zero 
    addi $t5, $zero, 255 #getting t5 ready to be a mask
    srl $t5, $t5, 24 #t5 is now the mask
    and $t4, $t4, $t5 #t4 now has first 3 slots empty for data
    addi $t5, $zero, 255 #getting ready for t5 to be mask for v0
    sll $t5, $t5, 8 #move 1's over 8
    addi $t5, $t5, 255 #t5 now almost mask for v0
    sll $t5, $t5, 8 #move 1's over 8
    addi $t5, $t5, 255 #t5 now mask for v0
    and $v0, $v0, $t5 #v0 now bits to keep
    or $t4, $t4, $v0
    sw $t4, 8($a3) #last 3 characters stored
    or $zero, $zero, $zero 

    ##############The printing#######
    add $a0, $a3, $zero #a0 is now address of string to print
    add $v0, $zero, 4 #print string syscall
    syscall
    ##########End of the printing########
    
    #restore ra
    lw $ra, ($sp)
    or $zero, $zero, $zero
    addi $sp, $sp 4

    #End Print String 11
    jr $ra
    or $zero, $zero, $zero


printString16:
        #preserve ra
    addi $sp, $sp -4
    sw $ra, ($sp) 
    or $zero, $zero, $zero

    lui $a3, 0x1000 #a3 will be the address of the first block
    ori $a3, $a3, 44 #a3 is address of first block
    sll $a1, $a1, 16 #move to correct position for first block
    jal Process_Block #v0 will contain 4 ascii characters
    or $zero, $zero, $zero 

    #storing first block of characters
    sw $v0, ($a3) #first 4 characters are stored
    or $zero, $zero, $zero 

    #get next block to process
    sll $a1, $a1, 4 #a1 now ready to process next 4
    jal Process_Block
    or $zero, $zero, $zero 

    #storing the second block
    sw $v0, 4($a3) #next 4 characters stored
    or $zero, $zero, $zero 

    #get next block to process
    sll $a1, $a1, 4 #a1 now ready to process next 4
    jal Process_Block
    or $zero, $zero, $zero 

    #storing the second block
    sw $v0, 8($a3) #next 4 characters stored
    or $zero, $zero, $zero 

    #get last block to process
    sll $a1, $a1, 4 #a1 now ready to process next 4
    jal Process_Block
    or $zero, $zero, $zero 

    #storing the second block
    sw $v0, 12($a3) #next 4 characters stored
    or $zero, $zero, $zero 

    
    #restore ra
    lw $ra, ($sp)
    or $zero, $zero, $zero
    addi $sp, $sp 4

    ##############The printing#######
    add $a0, $a3, $zero #a0 is now address of string to print
    add $v0, $zero, 4 #print string syscall
    syscall
    ##########End of the printing########

    #End Print String 11
    jr $ra
    or $zero, $zero, $zero

############################################################### End binaryToStringPrint ###################################################################################################





















############################################################### Count 1's ###################################################################################################
Setup_Count_1s: 
    addi $t4, $zero, 16 #t4 = 16
    add $v1, $zero, $zero #v1 = 0 This will be the output
    addi $t2, $zero, 1 #t2 = 0x0000001
    and $t5, $t2, $a0 #t5 = 0 if first bit of a0 is 0, 1 if first bit of a0 is 1.
    beq $t5, $t2, Add_one
    or $zero, $zero, $zero #No op
    j Loop
    or $zero, $zero, $zero #No op


Loop:
    srl $a0, $a0, 1 #shift bits in a0 right one bit
    sub $t4, $t4, $t2 #t4--
    and $t5, $t2, $a0 ##t5 = 0 if first bit of a0 is 0, 1 if first bit of a0 is 1.
    beq $t4, $zero, Exit
    or $zero, $zero, $zero #No op
    beq $t5, $t2, Add_one
    or $zero, $zero, $zero #No op
    j Loop
    or $zero, $zero, $zero #No op


Add_one:
    add $v1, $v1, 1 #v1 ++
    j Loop
    or $zero, $zero, $zero #No op

Exit: 
    jr $ra
    or $zero, $zero, $zero #No op
############################################################### End Count 1's ###################################################################################################
















############################################################### Check Even ###################################################################################################

###v0 is 1 if odd(to make the bits even), 0 oherwise###
Check_even:
    addi $t4, $zero, 1 #t2 = 1
    and $t2, $t4, $a1 #if first bit 1 the t2 = 1(this means it was odd), zero otherwise
    beq $t2, $t4, Parity_one #if odd the parity bit should be 1
    or $zero, $zero, $zero #No op  
    add $v0, $zero, $zero #if it is even the parity bit is 0
    jr $ra #jump back
    or $zero, $zero, $zero #No op

Parity_one:
    addi $v0, $zero, 1 #v0 = 1
    jr $ra
    or $zero, $zero, $zero #No op
############################################################### Check Even ###################################################################################################