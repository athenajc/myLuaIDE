require("io")
require("wx")

s8051_debugger = {}

FLAG_C = 1
FLAG_AC = 2
FLAG_OV = 4
FLAG_C_AC_OV = 7
FLAG_C_OV = 3
FLAG_NONE = 0

-- operand type
OP_DATA = 0x100
OP_IRAM = 0x101
OP_BITADDR = 0x102
OP_RELADDR = 0x103
OP_CODE = 0x104
OP_ADDR = 0x105

OP_A = 0x110
OP_B = 0x111
OP_C = 0x112
OP_DPTR = 0x113

OP_R0 = 0x120
OP_R1 = 0x121
OP_R2 = 0x122
OP_R3 = 0x123
OP_R4 = 0x124
OP_R5 = 0x125
OP_R6 = 0x126
OP_R7 = 0x127
OP_ATR0 = 0x130
OP_ATR1 = 0x131
OP_ATA  = 0x132
OP_ATDPTR = 0x133
OP_PC = 0x140

I_ACALL = 0x11
I_ADD   = 0x24
I_ADDC  = 0x34
I_AJMP  = 0x01  
I_ANL   = 0x52   
I_CJNE  = 0xB4   
I_CLR   = 0xC2   
I_CPL   = 0xF4   
I_DA    = 0xD4   
I_DEC   = 0x15   
I_DIV   = 0x84   
I_DJNZ  = 0xD5   
I_INC   = 0x04   
I_JB    = 0x20   
I_JBC   = 0x10   
I_JC    = 0x40   
I_JMP   = 0x73   
I_JNB   = 0x30   
I_JNC   = 0x50   
I_JNZ   = 0x70   
I_JZ    = 0x60   
I_LCALL = 0x12   
I_LJMP  = 0x02   
I_MOV   = 0x76   
I_MOVC  = 0x93   
I_MOVX  = 0xF0   
I_MUL   = 0xA4   
I_NOP   = 0x00   
I_ORL   = 0x42   
I_POP   = 0xD0   
I_PUSH  = 0xC0   
I_RET   = 0x22  
I_RETI  = 0x32     
I_RL    = 0x23     
I_RLC   = 0x33     
I_RR    = 0x03     
I_RRC   = 0x13     
I_SETB  = 0xD3   
I_SJMP  = 0x80   
I_SUBB  = 0x94   
I_SWAP  = 0xC4
I_UNDEF  = 0xA5   
I_XCH   = 0xC6   
I_XCHD  = 0xD6   
I_XRL   = 0x62

local symbol_str = {
[I_ACALL] = "ACALL",-- Absolute Call
[I_ADD]   = "ADD  ",-- Add Accumulator
[I_ADDC]  = "ADDC ",-- Add Accumulator with Carry
[I_AJMP]  = "AJMP ",-- Absolute Jump
[I_ANL]   = "ANL  ",-- Bitwise AND
[I_CJNE]  = "CJNE ",-- Compare and Jump if Not Equal
[I_CLR]   = "CLR  ",-- Clear Register
[I_CPL]   = "CPL  ",-- Complement Register
[I_DA]    = "DA   ",-- Decimal Adjust
[I_DEC]   = "DEC  ",-- Decrement Register
[I_DIV]   = "DIV  ",-- Divide Accumulator by B
[I_DJNZ]  = "DJNZ ",-- Decrement Register and Jump if Not Zero
[I_INC]   = "INC  ",-- Increment Register
[I_JB]    = "JB   ",-- Jump if Bit Set
[I_JBC]   = "JBC  ",-- Jump if Bit Set and Clear Bit
[I_JC]    = "JC   ",-- Jump if Carry Set
[I_JMP]   = "JMP  ",-- Jump to Address
[I_JNB]   = "JNB  ",-- Jump if Bit Not Set
[I_JNC]   = "JNC  ",-- Jump if Carry Not Set
[I_JNZ]   = "JNZ  ",-- Jump if Accumulator Not Zero
[I_JZ]    = "JZ   ",-- Jump if Accumulator Zero
[I_LCALL] = "LCALL",-- Long Call
[I_LJMP]  = "LJMP ",-- Long Jump
[I_MOV]   = "MOV  ",-- Move Memory
[I_MOVC]  = "MOVC ",-- Move Code Memory
[I_MOVX]  = "MOVX ",-- Move Extended Memory
[I_MUL]   = "MUL  ",-- Multiply Accumulator by B
[I_NOP]   = "NOP  ",-- No Operation
[I_ORL]   = "ORL  ",-- Bitwise OR
[I_POP]   = "POP  ",-- Pop Value From Stack
[I_PUSH]  = "PUSH ",-- Push Value Onto Stack
[I_RET]   = "RET  ",-- Return From Subroutine
[I_RETI]  = "RETI ",-- Return From Interrupt
[I_RL]    = "RL   ",-- Rotate Accumulator Left
[I_RLC]   = "RLC  ",-- Rotate Accumulator Left Through Carry
[I_RR]    = "RR   ",-- Rotate Accumulator Right
[I_RRC]   = "RRC  ",-- Rotate Accumulator Right Through Carry
[I_SETB]  = "SETB ",-- Set Bit
[I_SJMP]  = "SJMP ",-- Short Jump
[I_SUBB]  = "SUBB ",-- Subtract From Accumulator With Borrow
[I_SWAP]  = "SWAP ",-- Swap Accumulator Nibbles
[I_XCH]   = "XCH  ",-- Exchange Bytes
[I_XCHD]  = "XCHD ",-- Exchange Digits
[I_XRL]   = "XRL  ",-- Bitwise Exclusive OR
[I_UNDEF] = "UNDEF",-- Undefined Instruction
}

local op_str = {
[OP_A] = "A",
[OP_B] = "B",
[OP_C] = "C",
[OP_DATA] = "#op",
[OP_IRAM] = "op",
[OP_DPTR] = "DTPR",
[OP_BITADDR] = "op",
[OP_RELADDR] = "op",
[OP_R0] = "R0",
[OP_R1] = "R1",
[OP_R2] = "R2",
[OP_R3] = "R3",
[OP_R4] = "R4",
[OP_R5] = "R5",
[OP_R6] = "R6",
[OP_R7] = "R7",
[OP_ATR0] = "@R0",
[OP_ATR1] = "@R1",
[OP_ATA]  = "@A",
[OP_ATDPTR] = "@DTPR",
[OP_PC] = "PC",
[OP_CODE] = "op",
[OP_ADDR] = "op",
}

local op_action = {
[OP_A] = "op = sim.a",
[OP_B] = "op = sim.b",
[OP_C] = "op = sim.c",
[OP_DATA] = "op = opvalue",
[OP_IRAM] = "op = sim.mem[opvalue]",
[OP_DPTR] = "op = sim.dptr",
[OP_BITADDR] = "op = opvalue",
[OP_RELADDR] = "op = opvalue",
[OP_R0] = "op = sim.r0",
[OP_R1] = "op = sim.r1",
[OP_R2] = "op = sim.r2",
[OP_R3] = "op = sim.r3",
[OP_R4] = "op = sim.r4",
[OP_R5] = "op = sim.r5",
[OP_R6] = "op = sim.r6",
[OP_R7] = "op = sim.r7",
[OP_ATR0] = "op = sim.mem[sim.r0]",
[OP_ATR1] = "op = sim.mem[sim.r0]",
[OP_ATA]  = "op = sim.mem[sim.a]",
[OP_ATDPTR] = "op = sim.mem[sim.dptr]",
[OP_PC] = "op = sim.pc",
[OP_CODE] = "op = opvalue",
[OP_ADDR] = "op = opvalue",
}

local symbol_map = {
I_NOP, 	 I_AJMP,  I_LJMP,  I_RR,    I_INC,   I_INC,   I_INC,   I_INC,   I_INC,   I_INC,   I_INC,   I_INC,   I_INC,   I_INC,   I_INC,   I_INC,
I_JBC,   I_ACALL, I_LCALL, I_RRC,   I_DEC,   I_DEC,   I_DEC,   I_DEC,   I_DEC,   I_DEC,   I_DEC,   I_DEC,   I_DEC,   I_DEC,   I_DEC,   I_DEC,  
I_JB,    I_AJMP,  I_RET,   I_RL,    I_ADD,   I_ADD,   I_ADD,   I_ADD,   I_ADD,   I_ADD,   I_ADD,   I_ADD,   I_ADD,   I_ADD,   I_ADD,   I_ADD,   
I_JNB,   I_ACALL, I_RETI,  I_RLC,   I_ADDC,  I_ADDC,  I_ADDC,  I_ADDC,  I_ADDC,  I_ADDC,  I_ADDC,  I_ADDC,  I_ADDC,  I_ADDC,  I_ADDC,  I_ADDC, 
 
I_JC,    I_AJMP,  I_ORL,   I_ORL,   I_ORL,   I_ORL,   I_ORL,   I_ORL,   I_ORL,   I_ORL,   I_ORL,   I_ORL,   I_ORL,   I_ORL,   I_ORL,   I_ORL,   
I_JNC,   I_ACALL, I_ANL,   I_ANL,   I_ANL,   I_ANL,   I_ANL,   I_ANL,   I_ANL,   I_ANL,   I_ANL,   I_ANL,   I_ANL,   I_ANL,   I_ANL,   I_ANL,   
I_JZ,    I_AJMP,  I_XRL,   I_XRL,   I_XRL,   I_XRL,   I_XRL,   I_XRL,   I_XRL,   I_XRL,   I_XRL,   I_XRL,   I_XRL,   I_XRL,   I_XRL,   I_XRL,   
I_JNZ,   I_ACALL, I_ORL,   I_JMP,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   I_MOV, 
  
I_SJMP,  I_AJMP,  I_ANL,   I_MOVC,  I_DIV,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   
I_MOV,   I_ACALL, I_MOV,   I_MOVC,  I_SUBB,  I_SUBB,  I_SUBB,  I_SUBB,  I_SUBB,  I_SUBB,  I_SUBB,  I_SUBB,  I_SUBB,  I_SUBB,  I_SUBB,  I_SUBB,  
I_ORL,   I_AJMP,  I_MOV,   I_INC,   I_MUL,   I_UNDEF, I_MOV,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   
I_ANL,   I_ACALL, I_CPL,   I_CPL,   I_CJNE,  I_CJNE,  I_CJNE,  I_CJNE,  I_CJNE,  I_CJNE,  I_CJNE,  I_CJNE,  I_CJNE,  I_CJNE,  I_CJNE,  I_CJNE,  

I_PUSH,  I_AJMP,  I_CLR,   I_CLR,   I_SWAP,  I_XCH,   I_XCH,   I_XCH,   I_XCH,   I_XCH,   I_XCH,   I_XCH,   I_XCH,   I_XCH,   I_XCH,   I_XCH,  
I_POP,   I_ACALL, I_SETB,  I_SETB,  I_DA,    I_DJNZ,  I_XCHD,  I_XCHD,  I_DJNZ,  I_DJNZ,  I_DJNZ,  I_DJNZ,  I_DJNZ,  I_DJNZ,  I_DJNZ,  I_DJNZ,  
I_MOVX,  I_AJMP,  I_MOVX,  I_MOVX,  I_CLR,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   
I_MOVX,  I_ACALL, I_MOVX,  I_MOVX,  I_CPL,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   I_MOV,   
}
symbol_map[0] = I_NOP




local symbol_table = {
-- ACALL
[0x11] = {2, I_ACALL, {0}, FLAG_NONE, "ACALL page0	0x11	2	None"},
[0x31] = {2, I_ACALL, {1}, FLAG_NONE, "ACALL page1	0x31	2	None"},
[0x51] = {2, I_ACALL, {2}, FLAG_NONE, "ACALL page2	0x51	2	None"},
[0x71] = {2, I_ACALL, {3}, FLAG_NONE, "ACALL page3	0x71	2	None"},
[0x91] = {2, I_ACALL, {4}, FLAG_NONE, "ACALL page4	0x91	2	None"},
[0xB1] = {2, I_ACALL, {5}, FLAG_NONE, "ACALL page5	0xB1	2	None"},
[0xD1] = {2, I_ACALL, {6}, FLAG_NONE, "ACALL page6	0xD1	2	None"},
[0xF1] = {2, I_ACALL, {7}, FLAG_NONE, "ACALL page7	0xF1	2	None"},

-- ADD, ADD A,operand
[0x24] = {2, I_ADD, {OP_A, OP_DATA}, FLAG_C_AC_OV, "ADD A,#data	0x24	2	C, AC, OV"},
[0x25] = {2, I_ADD, {OP_A, OP_IRAM}, FLAG_C_AC_OV, "ADD A,iram_addr	0x25	2	C, AC, OV"},
[0x26] = {1, I_ADD, {OP_A, OP_ATR0}, FLAG_C_AC_OV, "ADD A,@R0	0x26	1	C, AC, OV"},
[0x27] = {1, I_ADD, {OP_A, OP_ATR1}, FLAG_C_AC_OV, "ADD A,@R1	0x27	1	C, AC, OV"},
[0x28] = {1, I_ADD, {OP_A, OP_R0},   FLAG_C_AC_OV, "ADD A,R0	0x28	1	C, AC, OV"},
[0x29] = {1, I_ADD, {OP_A, OP_R1},   FLAG_C_AC_OV, "ADD A,R1	0x29	1	C, AC, OV"},
[0x2A] = {1, I_ADD, {OP_A, OP_R2},   FLAG_C_AC_OV, "ADD A,R2	0x2A	1	C, AC, OV"},
[0x2B] = {1, I_ADD, {OP_A, OP_R3},   FLAG_C_AC_OV, "ADD A,R3	0x2B	1	C, AC, OV"},
[0x2C] = {1, I_ADD, {OP_A, OP_R4},   FLAG_C_AC_OV, "ADD A,R4	0x2C	1	C, AC, OV"},
[0x2D] = {1, I_ADD, {OP_A, OP_R5},   FLAG_C_AC_OV, "ADD A,R5	0x2D	1	C, AC, OV"},
[0x2E] = {1, I_ADD, {OP_A, OP_R6},   FLAG_C_AC_OV, "ADD A,R6	0x2E	1	C, AC, OV"},
[0x2F] = {1, I_ADD, {OP_A, OP_R7},   FLAG_C_AC_OV, "ADD A,R7	0x2F	1	C, AC, OV"},

-- ADDC
[0x34] = {2, I_ADDC, {OP_A, OP_DATA}, FLAG_C_AC_OV, "ADDC A,#data	0x34	2	C, AC, OV"},
[0x35] = {2, I_ADDC, {OP_A, OP_IRAM}, FLAG_C_AC_OV, "ADDC A,iram_addr	0x35	2	C, AC, OV"},
[0x36] = {1, I_ADDC, {OP_A, OP_ATR0}, FLAG_C_AC_OV, "ADDC A,@R0	0x36	1	C, AC, OV"},
[0x37] = {1, I_ADDC, {OP_A, OP_ATR1}, FLAG_C_AC_OV, "ADDC A,@R1	0x37	1	C, AC, OV"},
[0x38] = {1, I_ADDC, {OP_A, OP_R0},   FLAG_C_AC_OV, "ADDC A,R0	0x38	1	C, AC, OV"},
[0x39] = {1, I_ADDC, {OP_A, OP_R1},   FLAG_C_AC_OV, "ADDC A,R1	0x39	1	C, AC, OV"},
[0x3A] = {1, I_ADDC, {OP_A, OP_R2},   FLAG_C_AC_OV, "ADDC A,R2	0x3A	1	C, AC, OV"},
[0x3B] = {1, I_ADDC, {OP_A, OP_R3},   FLAG_C_AC_OV, "ADDC A,R3	0x3B	1	C, AC, OV"},
[0x3C] = {1, I_ADDC, {OP_A, OP_R4},   FLAG_C_AC_OV, "ADDC A,R4	0x3C	1	C, AC, OV"},
[0x3D] = {1, I_ADDC, {OP_A, OP_R5},   FLAG_C_AC_OV, "ADDC A,R5	0x3D	1	C, AC, OV"},
[0x3E] = {1, I_ADDC, {OP_A, OP_R6},   FLAG_C_AC_OV, "ADDC A,R6	0x3E	1	C, AC, OV"},
[0x3F] = {1, I_ADDC, {OP_A, OP_R7},   FLAG_C_AC_OV, "ADDC A,R7	0x3F	1	C, AC, OV"},

-- AJMP, AJMP code address
[0x01] = {2, I_AJMP, {0}, FLAG_NONE, "AJMP page0	0x01	2	None"},
[0x21] = {2, I_AJMP, {1}, FLAG_NONE, "AJMP page1	0x21	2	None"},
[0x41] = {2, I_AJMP, {2}, FLAG_NONE, "AJMP page2	0x41	2	None"},
[0x61] = {2, I_AJMP, {3}, FLAG_NONE, "AJMP page3	0x61	2	None"},
[0x81] = {2, I_AJMP, {4}, FLAG_NONE, "AJMP page4	0x81	2	None"},
[0xA1] = {2, I_AJMP, {5}, FLAG_NONE, "AJMP page5	0xA1	2	None"},
[0xC1] = {2, I_AJMP, {6}, FLAG_NONE, "AJMP page6	0xC1	2	None"},
[0xE1] = {2, I_AJMP, {7}, FLAG_NONE, "AJMP page7	0xE1	2	None"},

-- ANL, Bitwise AND, ANL operand1, operand2
[0x52] = {2, I_ANL, {OP_A,    OP_IRAM}, FLAG_NONE, "ANL iram_addr,A	0x52	2	None"},
[0x53] = {3, I_ANL, {OP_IRAM, OP_DATA}, FLAG_NONE, "ANL iram_addr,#data	0x53	3	None"},
[0x54] = {2, I_ANL, {OP_A,    OP_DATA}, FLAG_NONE, "ANL A,#data	0x54	2	None"},
[0x55] = {2, I_ANL, {OP_A,    OP_IRAM}, FLAG_NONE, "ANL A,iram_addr	0x55	2	None"},
[0x56] = {1, I_ANL, {OP_A,    OP_ATR0}, FLAG_NONE, "ANL A,@R0	0x56	1	None"},
[0x57] = {1, I_ANL, {OP_A,    OP_ATR1}, FLAG_NONE, "ANL A,@R1	0x57	1	None"},
[0x58] = {1, I_ANL, {OP_A,    OP_R0},   FLAG_NONE, "ANL A,R0	0x58	1	None"},
[0x59] = {1, I_ANL, {OP_A,    OP_R1},   FLAG_NONE, "ANL A,R1	0x59	1	None"},
[0x5A] = {1, I_ANL, {OP_A,    OP_R2},   FLAG_NONE, "ANL A,R2	0x5A	1	None"},
[0x5B] = {1, I_ANL, {OP_A,    OP_R3},   FLAG_NONE, "ANL A,R3	0x5B	1	None"},
[0x5C] = {1, I_ANL, {OP_A,    OP_R4},   FLAG_NONE, "ANL A,R4	0x5C	1	None"},
[0x5D] = {1, I_ANL, {OP_A,    OP_R5},   FLAG_NONE, "ANL A,R5	0x5D	1	None"},
[0x5E] = {1, I_ANL, {OP_A,    OP_R6},   FLAG_NONE, "ANL A,R6	0x5E	1	None"},
[0x5F] = {1, I_ANL, {OP_A,    OP_R7},   FLAG_NONE, "ANL A,R7	0x5F	1	None"},
[0x82] = {2, I_ANL, {OP_C,    OP_BITADDR},   FLAG_C, "ANL C,bit addr	0x82	2	C"},
[0xB0] = {2, I_ANL, {OP_C,    OP_BITADDR},   FLAG_C, "ANL C,/bit addr	0xB0	2	C"},

-- CJNE
-- Compare and Jump If Not Equal
-- Syntax:	CJNE operand1,operand2,reladdr
[0xB4] = {3, I_CJNE, {OP_A,    OP_DATA, OP_RELADDR}, FLAG_C, "CJNE A,#data,reladdr	    0xB4	3	C"},
[0xB5] = {3, I_CJNE, {OP_A,    OP_IRAM, OP_RELADDR}, FLAG_C, "CJNE A,iram_addr,reladdr	0xB5	3	C"},
[0xB6] = {3, I_CJNE, {OP_ATR0, OP_DATA, OP_RELADDR}, FLAG_C, "CJNE @R0,#data,reladdr	0xB6	3	C"},
[0xB7] = {3, I_CJNE, {OP_ATR1, OP_DATA, OP_RELADDR}, FLAG_C, "CJNE @R1,#data,reladdr	0xB7	3	C"},
[0xB8] = {3, I_CJNE, {OP_R0,   OP_DATA, OP_RELADDR}, FLAG_C, "CJNE R0,#data,reladdr	0xB8	3	C"},
[0xB9] = {3, I_CJNE, {OP_R1,   OP_DATA, OP_RELADDR}, FLAG_C, "CJNE R1,#data,reladdr	0xB9	3	C"},
[0xBA] = {3, I_CJNE, {OP_R2,   OP_DATA, OP_RELADDR}, FLAG_C, "CJNE R2,#data,reladdr	0xBA	3	C"},
[0xBB] = {3, I_CJNE, {OP_R3,   OP_DATA, OP_RELADDR}, FLAG_C, "CJNE R3,#data,reladdr	0xBB	3	C"},
[0xBC] = {3, I_CJNE, {OP_R4,   OP_DATA, OP_RELADDR}, FLAG_C, "CJNE R4,#data,reladdr	0xBC	3	C"},
[0xBD] = {3, I_CJNE, {OP_R5,   OP_DATA, OP_RELADDR}, FLAG_C, "CJNE R5,#data,reladdr	0xBD	3	C"},
[0xBE] = {3, I_CJNE, {OP_R6,   OP_DATA, OP_RELADDR}, FLAG_C, "CJNE R6,#data,reladdr	0xBE	3	C"},
[0xBF] = {3, I_CJNE, {OP_R7,   OP_DATA, OP_RELADDR}, FLAG_C, "CJNE R7,#data,reladdr	0xBF	3	C"},

--CLR :	Clear Register
--Syntax:	CLR register
[0xC2] = {2, I_CLR, {OP_BITADDR}, FLAG_NONE, "CLR bit addr	0xC2	2	None"},
[0xC3] = {1, I_CLR, {OP_C},       FLAG_C,    "CLR C	0xC3	1	C"},
[0xE4] = {1, I_CLR, {OP_A},       FLAG_NONE, "CLR A	0xE4	1	None"},

--CPL :	Complement Register
--Syntax:	CPL operand
[0xF4] = {1, I_CPL, {OP_A},       FLAG_NONE, "CPL A	0xF4	1	None"},
[0xB3] = {1, I_CPL, {OP_C},       FLAG_C,    "CPL C	0xB3	1	C"},
[0xB2] = {2, I_CPL, {OP_BITADDR}, FLAG_NONE, "CPL bit addr	0xB2	2	None"},

--DA :	Decimal Adjust Accumulator
--Syntax:	DA A
[0xD4] = {1, I_DA, {OP_A}, FLAG_C, "DA	0xD4	1	C"},

--DEC :	Decrement Register
--Syntax:	DEC register
[0x14] = {1, I_DEC, {OP_A},    FLAG_NONE, "DEC A	0x14	1	None"},
[0x15] = {2, I_DEC, {OP_IRAM}, FLAG_NONE, "DEC iram_addr	0x15	2	None"},
[0x16] = {1, I_DEC, {OP_ATR0}, FLAG_NONE, "DEC @R0	0x16	1	None"},
[0x17] = {1, I_DEC, {OP_ATR1}, FLAG_NONE, "DEC @R1	0x17	1	None"},
[0x18] = {1, I_DEC, {OP_R0}, FLAG_NONE, "DEC R0	0x18	1	None"},
[0x19] = {1, I_DEC, {OP_R1}, FLAG_NONE, "DEC R1	0x19	1	None"},
[0x1A] = {1, I_DEC, {OP_R2}, FLAG_NONE, "DEC R2	0x1A	1	None"},
[0x1B] = {1, I_DEC, {OP_R3}, FLAG_NONE, "DEC R3	0x1B	1	None"},
[0x1C] = {1, I_DEC, {OP_R4}, FLAG_NONE, "DEC R4	0x1C	1	None"},
[0x1D] = {1, I_DEC, {OP_R5}, FLAG_NONE, "DEC R5	0x1D	1	None"},
[0x1E] = {1, I_DEC, {OP_R6}, FLAG_NONE, "DEC R6	0x1E	1	None"},
[0x1F] = {1, I_DEC, {OP_R7}, FLAG_NONE, "DEC R7	0x1F	1	None"},

--DIV   :	Divide Accumulator by B
--Syntax:	DIV AB
[0x84] = {1, I_DIV, {OP_A, OP_B}, FLAG_OV, "DIV AB	0x84	1	C, OV"},

--DJNZ  :	Decrement and Jump if Not Zero
--Syntax:	DJNZ register,reladdr
[0xD5] = {3, I_DJNZ, {OP_IRAM, OP_RELADDR}, FLAG_NONE, "DJNZ iram_addr,reladdr	0xD5	3	None"},
[0xD8] = {2, I_DJNZ, {OP_R0,   OP_RELADDR}, FLAG_NONE, "DJNZ R0,reladdr	0xD8	2	None"},
[0xD9] = {2, I_DJNZ, {OP_R1,   OP_RELADDR}, FLAG_NONE, "DJNZ R1,reladdr	0xD9	2	None"},
[0xDA] = {2, I_DJNZ, {OP_R2,   OP_RELADDR}, FLAG_NONE, "DJNZ R2,reladdr	0xDA	2	None"},
[0xDB] = {2, I_DJNZ, {OP_R3,   OP_RELADDR}, FLAG_NONE, "DJNZ R3,reladdr	0xDB	2	None"},
[0xDC] = {2, I_DJNZ, {OP_R4,   OP_RELADDR}, FLAG_NONE, "DJNZ R4,reladdr	0xDC	2	None"},
[0xDD] = {2, I_DJNZ, {OP_R5,   OP_RELADDR}, FLAG_NONE, "DJNZ R5,reladdr	0xDD	2	None"},
[0xDE] = {2, I_DJNZ, {OP_R6,   OP_RELADDR}, FLAG_NONE, "DJNZ R6,reladdr	0xDE	2	None"},
[0xDF] = {2, I_DJNZ, {OP_R7,   OP_RELADDR}, FLAG_NONE, "DJNZ R7,reladdr	0xDF	2	None"},


--INC   :	Increment Register
--Syntax:	INC register
[0x04] = {1, I_INC, {OP_A},    FLAG_NONE, "INC A	0x04	1	None"},
[0x05] = {2, I_INC, {OP_IRAM}, FLAG_NONE, "INC iram_addr	0x05	2	None"},
[0x06] = {1, I_INC, {OP_ATR0}, FLAG_NONE, "INC @R0	0x06	1	None"},
[0x07] = {1, I_INC, {OP_ATR1}, FLAG_NONE, "INC @R1	0x07	1	None"},
[0x08] = {1, I_INC, {OP_R0}, FLAG_NONE, "INC R0	0x08	1	None"},
[0x09] = {1, I_INC, {OP_R1}, FLAG_NONE, "INC R1	0x09	1	None"},
[0x0A] = {1, I_INC, {OP_R2}, FLAG_NONE, "INC R2	0x0A	1	None"},
[0x0B] = {1, I_INC, {OP_R3}, FLAG_NONE, "INC R3	0x0B	1	None"},
[0x0C] = {1, I_INC, {OP_R4}, FLAG_NONE, "INC R4	0x0C	1	None"},
[0x0D] = {1, I_INC, {OP_R5}, FLAG_NONE, "INC R5	0x0D	1	None"},
[0x0E] = {1, I_INC, {OP_R6}, FLAG_NONE, "INC R6	0x0E	1	None"},
[0x0F] = {1, I_INC, {OP_R7}, FLAG_NONE, "INC R7	0x0F	1	None"},
[0xA3] = {1, I_INC, {OP_DPTR}, FLAG_NONE, "INC DPTR	0xA3	1	None"},

--JB    : Jump if Bit Set
--Syntax:	JB bit addr, reladdr
[0x20] = {3, I_JB, {OP_BITADDR, OP_RELADDR}, FLAG_NONE, "JB bit addr,reladdr	0x20	3	None"},

--JBC   :	Jump if Bit Set and Clear Bit
--Syntax:	JB bit addr, reladdr
[0x10] = {3, I_JBC, {OP_BITADDR, OP_RELADDR}, FLAG_NONE, "JBC bit addr,reladdr	0x10	3	None"},

--JC
--Function:	Jump if Carry Set
--Syntax:	JC reladdr
[0x40] = {2, I_JC, {OP_RELADDR}, FLAG_NONE, "JC reladdr	0x40	2	None"},

--JMP
--Function:	Jump to Data Pointer + Accumulator
--Syntax:	JMP @A+DPTR
[0x73] = {1, I_JMP, {OP_ATA, OP_DPTR}, FLAG_NONE, "JMP @A+DPTR	0x73	1	None"},

--JNB
--Function:	Jump if Bit Not Set
--Syntax:	JNB bit addr,reladdr
[0x30] = {3, I_JNB, {OP_BITADDR, OP_RELADDR}, FLAG_NONE, "JNB bit addr,reladdr	0x30	3	None"},

--JNC
--Function:	Jump if Carry Not Set
--Syntax:	JNC reladdr
[0x50] = {2, I_JNC, {OP_RELADDR}, FLAG_NONE, "JNC reladdr	0x50	2	None"},

--JNZ
--Function:	Jump if Accumulator Not Zero
--Syntax:	JNZ reladdr
[0x70] = {2, I_JNZ, {OP_RELADDR}, FLAG_NONE, "JNZ reladdr	0x70	2	None"},

--JZ    :	Jump if Accumulator Zero
--Syntax:	JNZ reladdr
[0x60] = {2, I_JZ, {OP_RELADDR}, FLAG_NONE, "JZ reladdr	0x60	2	None"},

--LCALL
--Function:	Long Call
--Syntax:	LCALL code addr
[0x12] = {3, I_LCALL, {OP_CODE, OP_ADDR}, FLAG_NONE, "LCALL code addr	0x12	3	None"},

--LJMP
--Function:	Long Jump
--Syntax:	LJMP code addr
[0x02] = {3, I_LJMP, {OP_CODE, OP_ADDR}, FLAG_NONE, "LJMP code addr	0x02	3	None"},

--MOV
--Function:	Move Memory
--Syntax:	MOV operand1,operand2
[0x76] = {2, I_MOV, {OP_ATR0, OP_DATA}, FLAG_NONE, "MOV @R0,#data	0x76	2	None"},
[0x77] = {2, I_MOV, {OP_ATR1, OP_DATA}, FLAG_NONE, "MOV @R1,#data	0x77	2	None"},
[0xF6] = {1, I_MOV, {OP_ATR0, OP_A}, FLAG_NONE, "MOV @R0,A	0xF6	1	None"},
[0xF7] = {1, I_MOV, {OP_ATR1, OP_A}, FLAG_NONE, "MOV @R1,A	0xF7	1	None"},
[0xA6] = {2, I_MOV, {OP_ATR0, OP_IRAM}, FLAG_NONE, "MOV @R0,iram_addr	0xA6	2	None"},
[0xA7] = {2, I_MOV, {OP_ATR1, OP_IRAM}, FLAG_NONE, "MOV @R1,iram_addr	0xA7	2	None"},
[0x74] = {2, I_MOV, {OP_A, OP_DATA}, FLAG_NONE, "MOV A,#data	0x74	2	None"},
[0xE6] = {1, I_MOV, {OP_A, OP_ATR0}, FLAG_NONE, "MOV A,@R0	0xE6	1	None"},
[0xE7] = {1, I_MOV, {OP_A, OP_ATR1}, FLAG_NONE, "MOV A,@R1	0xE7	1	None"},
[0xE8] = {1, I_MOV, {OP_A, OP_R0}, FLAG_NONE, "MOV A,R0	0xE8	1	None"},
[0xE9] = {1, I_MOV, {OP_A, OP_R1}, FLAG_NONE, "MOV A,R1	0xE9	1	None"},
[0xEA] = {1, I_MOV, {OP_A, OP_R2}, FLAG_NONE, "MOV A,R2	0xEA	1	None"},
[0xEB] = {1, I_MOV, {OP_A, OP_R3}, FLAG_NONE, "MOV A,R3	0xEB	1	None"},
[0xEC] = {1, I_MOV, {OP_A, OP_R4}, FLAG_NONE, "MOV A,R4	0xEC	1	None"},
[0xED] = {1, I_MOV, {OP_A, OP_R5}, FLAG_NONE, "MOV A,R5	0xED	1	None"},
[0xEE] = {1, I_MOV, {OP_A, OP_R6}, FLAG_NONE, "MOV A,R6	0xEE	1	None"},
[0xEF] = {1, I_MOV, {OP_A, OP_R7}, FLAG_NONE, "MOV A,R7	0xEF	1	None"},
[0xE5] = {2, I_MOV, {OP_A, OP_IRAM}, FLAG_NONE, "MOV A,iram_addr	0xE5	2	None"},
[0xA2] = {2, I_MOV, {OP_C, OP_BITADDR}, FLAG_C, "MOV C,bit addr	0xA2	2	C"},
[0x90] = {3, I_MOV, {OP_DPTR, OP_DATA}, FLAG_NONE, "MOV DPTR,#data16	0x90	3	None"},
[0x78] = {2, I_MOV, {OP_R0, OP_DATA}, FLAG_NONE, "MOV R0,#data	0x78	2	None"},
[0x79] = {2, I_MOV, {OP_R1, OP_DATA}, FLAG_NONE, "MOV R1,#data	0x79	2	None"},
[0x7A] = {2, I_MOV, {OP_R2, OP_DATA}, FLAG_NONE, "MOV R2,#data	0x7A	2	None"},
[0x7B] = {2, I_MOV, {OP_R3, OP_DATA}, FLAG_NONE, "MOV R3,#data	0x7B	2	None"},
[0x7C] = {2, I_MOV, {OP_R4, OP_DATA}, FLAG_NONE, "MOV R4,#data	0x7C	2	None"},
[0x7D] = {2, I_MOV, {OP_R5, OP_DATA}, FLAG_NONE, "MOV R5,#data	0x7D	2	None"},
[0x7E] = {2, I_MOV, {OP_R6, OP_DATA}, FLAG_NONE, "MOV R6,#data	0x7E	2	None"},
[0x7F] = {2, I_MOV, {OP_R7, OP_DATA}, FLAG_NONE, "MOV R7,#data	0x7F	2	None"},
[0xF8] = {1, I_MOV, {OP_R0, OP_A}, FLAG_NONE, "MOV R0,A	0xF8	1	None"},
[0xF9] = {1, I_MOV, {OP_R1, OP_A}, FLAG_NONE, "MOV R1,A	0xF9	1	None"},
[0xFA] = {1, I_MOV, {OP_R2, OP_A}, FLAG_NONE, "MOV R2,A	0xFA	1	None"},
[0xFB] = {1, I_MOV, {OP_R3, OP_A}, FLAG_NONE, "MOV R3,A	0xFB	1	None"},
[0xFC] = {1, I_MOV, {OP_R4, OP_A}, FLAG_NONE, "MOV R4,A	0xFC	1	None"},
[0xFD] = {1, I_MOV, {OP_R5, OP_A}, FLAG_NONE, "MOV R5,A	0xFD	1	None"},
[0xFE] = {1, I_MOV, {OP_R6, OP_A}, FLAG_NONE, "MOV R6,A	0xFE	1	None"},
[0xFF] = {1, I_MOV, {OP_R7, OP_A}, FLAG_NONE, "MOV R7,A	0xFF	1	None"},
[0xA8] = {2, I_MOV, {OP_R0, OP_IRAM}, FLAG_NONE, "MOV R0,iram_addr	0xA8	2	None"},
[0xA9] = {2, I_MOV, {OP_R1, OP_IRAM}, FLAG_NONE, "MOV R1,iram_addr	0xA9	2	None"},
[0xAA] = {2, I_MOV, {OP_R2, OP_IRAM}, FLAG_NONE, "MOV R2,iram_addr	0xAA	2	None"},
[0xAB] = {2, I_MOV, {OP_R3, OP_IRAM}, FLAG_NONE, "MOV R3,iram_addr	0xAB	2	None"},
[0xAC] = {2, I_MOV, {OP_R4, OP_IRAM}, FLAG_NONE, "MOV R4,iram_addr	0xAC	2	None"},
[0xAD] = {2, I_MOV, {OP_R5, OP_IRAM}, FLAG_NONE, "MOV R5,iram_addr	0xAD	2	None"},
[0xAE] = {2, I_MOV, {OP_R6, OP_IRAM}, FLAG_NONE, "MOV R6,iram_addr	0xAE	2	None"},
[0xAF] = {2, I_MOV, {OP_R7, OP_IRAM}, FLAG_NONE, "MOV R7,iram_addr	0xAF	2	None"},
[0x92] = {2, I_MOV, {OP_BITADDR, OP_C}, FLAG_NONE, "MOV bit addr,C	0x92	2	None"},
[0x75] = {3, I_MOV, {OP_IRAM, OP_DATA}, FLAG_NONE, "MOV iram_addr,#data	0x75	3	None"},
[0x86] = {2, I_MOV, {OP_IRAM, OP_ATR0}, FLAG_NONE, "MOV iram_addr,@R0	0x86	2	None"},
[0x87] = {2, I_MOV, {OP_IRAM, OP_ATR1}, FLAG_NONE, "MOV iram_addr,@R1	0x87	2	None"},
[0x88] = {2, I_MOV, {OP_IRAM, OP_R0}, FLAG_NONE, "MOV iram_addr,R0	0x88	2	None"},
[0x89] = {2, I_MOV, {OP_IRAM, OP_R1}, FLAG_NONE, "MOV iram_addr,R1	0x89	2	None"},
[0x8A] = {2, I_MOV, {OP_IRAM, OP_R2}, FLAG_NONE, "MOV iram_addr,R2	0x8A	2	None"},
[0x8B] = {2, I_MOV, {OP_IRAM, OP_R3}, FLAG_NONE, "MOV iram_addr,R3	0x8B	2	None"},
[0x8C] = {2, I_MOV, {OP_IRAM, OP_R4}, FLAG_NONE, "MOV iram_addr,R4	0x8C	2	None"},
[0x8D] = {2, I_MOV, {OP_IRAM, OP_R5}, FLAG_NONE, "MOV iram_addr,R5	0x8D	2	None"},
[0x8E] = {2, I_MOV, {OP_IRAM, OP_R6}, FLAG_NONE, "MOV iram_addr,R6	0x8E	2	None"},
[0x8F] = {2, I_MOV, {OP_IRAM, OP_R7}, FLAG_NONE, "MOV iram_addr,R7	0x8F	2	None"},
[0xF5] = {2, I_MOV, {OP_IRAM, OP_A}, FLAG_NONE, "MOV iram_addr,A	0xF5	2	None"},
[0x85] = {3, I_MOV, {OP_IRAM, OP_IRAM}, FLAG_NONE, "MOV iram_addr,iram_addr	0x85	3	None"},


--MOVC
--Function:	Move Code Byte to Accumulator
--Syntax:	MOVC A,@A+register
[0x93] = {1, I_MOVC, {OP_A, OP_ATA, OP_DPTR}, FLAG_NONE, "MOVC A,@A+DPTR	0x93	1	None"},
[0x83] = {1, I_MOVC, {OP_A, OP_ATA, OP_PC}, FLAG_NONE, "MOVC A,@A+PC	0x83	1	None"},

--MOVX
--Function:	Move Data To/From External Memory (XRAM)
--Syntax:	MOVX operand1,operand2
[0xF0] = {1, I_MOVX, {OP_ATDPTR, OP_A}, FLAG_NONE, "MOVX @DPTR,A	0xF0	1	None"},
[0xF2] = {1, I_MOVX, {OP_ATR0, OP_A}, FLAG_NONE, "MOVX @R0,A	0xF2	1	None"},
[0xF3] = {1, I_MOVX, {OP_ATR1, OP_A}, FLAG_NONE, "MOVX @R1,A	0xF3	1	None"},
[0xE0] = {1, I_MOVX, {OP_A, OP_ATDPTR}, FLAG_NONE, "MOVX A,@DPTR	0xE0	1	None"},
[0xE2] = {1, I_MOVX, {OP_A, OP_ATR0}, FLAG_NONE, "MOVX A,@R0	0xE2	1	None"},
[0xE3] = {1, I_MOVX, {OP_A, OP_ATR1}, FLAG_NONE, "MOVX A,@R1	0xE3	1	None"},

--MUL
--Function:	Multiply Accumulator by B
--Syntax:	MUL AB
[0xA4] = {1, I_MUL, {OP_A, OP_B}, FLAG_OV, "MUL AB	0xA4	1	C, OV"},

--NOP
--Function:	None"},, waste time
--Syntax:	No Operation
[0x00] = {1, I_NOP, {}, FLAG_NONE, "NOP	0x00	1	None"},

--ORL
--Function:	Bitwise OR
--Syntax:	ORL operand1,operand2
[0x42] = {2, I_ORL, {OP_IRAM, OP_A}, FLAG_NONE, "ORL iram_addr,A	0x42	2	None"},
[0x43] = {3, I_ORL, {OP_IRAM, OP_DATA}, FLAG_NONE, "ORL iram_addr,#data	0x43	3	None"},
[0x44] = {2, I_ORL, {OP_A, OP_DATA}, FLAG_NONE, "ORL A,#data	0x44	2	None"},
[0x45] = {2, I_ORL, {OP_A, OP_IRAM}, FLAG_NONE, "ORL A,iram_addr	0x45	2	None"},
[0x46] = {1, I_ORL, {OP_A, OP_ATR0}, FLAG_NONE, "ORL A,@R0	0x46	1	None"},
[0x47] = {1, I_ORL, {OP_A, OP_ATR1}, FLAG_NONE, "ORL A,@R1	0x47	1	None"},
[0x48] = {1, I_ORL, {OP_A, OP_R0}, FLAG_NONE, "ORL A,R0	0x48	1	None"},
[0x49] = {1, I_ORL, {OP_A, OP_R1}, FLAG_NONE, "ORL A,R1	0x49	1	None"},
[0x4A] = {1, I_ORL, {OP_A, OP_R2}, FLAG_NONE, "ORL A,R2	0x4A	1	None"},
[0x4B] = {1, I_ORL, {OP_A, OP_R3}, FLAG_NONE, "ORL A,R3	0x4B	1	None"},
[0x4C] = {1, I_ORL, {OP_A, OP_R4}, FLAG_NONE, "ORL A,R4	0x4C	1	None"},
[0x4D] = {1, I_ORL, {OP_A, OP_R5}, FLAG_NONE, "ORL A,R5	0x4D	1	None"},
[0x4E] = {1, I_ORL, {OP_A, OP_R6}, FLAG_NONE, "ORL A,R6	0x4E	1	None"},
[0x4F] = {1, I_ORL, {OP_A, OP_R7}, FLAG_NONE, "ORL A,R7	0x4F	1	None"},
[0x72] = {2, I_ORL, {OP_C, OP_BITADDR}, FLAG_NONE, "ORL C,bit addr	0x72	2	C"},
[0xA0] = {2, I_ORL, {OP_C, OP_BITADDR}, FLAG_NONE, "ORL C,/bit addr	0xA0	2	C"},

--POP
--Function:	Pop Value From Stack
--Syntax:	POP iram_addr
[0xD0] = {2, I_POP, {OP_IRAM}, FLAG_NONE, "POP iram_addr	0xD0	2	None"},

--PUSH
--Function:	Push Value Onto Stack
--Syntax:	PUSH
[0xC0] = {2, I_PUSH, {OP_IRAM}, FLAG_NONE, "PUSH iram_addr	0xC0	2	None"},

--RET
--Function:	Return From Subroutine
--Syntax:	RET
[0x22] = {1, I_RET, {}, FLAG_NONE, "RET	0x22	1	None"},


--RETI
--Function:	Return From Interrupt
--Syntax:	RETI
[0x32] = {1, I_RETI, {}, FLAG_NONE, "RETI	0x32	1	None"},

--RL
--Function:	Rotate Accumulator Left
--Syntax:	RL A
[0x23] = {1, I_RL, {OP_A}, FLAG_C, "RL A	0x23	1	C"},

--RLC
--Function:	Rotate Accumulator Left Through Carry
--Syntax:	RLC A
[0x33] = {1, I_RLC, {OP_A}, FLGA_C, "RLC A	0x33	1	C"},

--RR
--Function:	Rotate Accumulator Right
--Syntax:	RR A
[0x03] = {1, I_RR, {OP_A}, FLGA_NONE, "RR A	0x03	1	None"},

--RRC
--Function:	Rotate Accumulator Right Through Carry
--Syntax:	RRC A
[0x13] = {1, I_RRC, {OP_A}, FLGA_C, "RRC A	0x13	1	C"},

--Operation:	SETB
--Function:	Set Bit
--Syntax:	SETB bit addr
[0xD3] = {1, I_SETB, {OP_C},       FLGA_C, "SETB C	        0xD3	1	C"},
[0xD2] = {2, I_SETB, {OP_BITADDR}, FLGA_C, "SETB bit addr	0xD2	2	None"},

--Operation:	SJMP
--Function:	Short Jump
--Syntax:	SJMP reladdr  (-128 ~ +127)
[0x80] = {2, I_SJMP, {OP_RELADDR}, FLAG_NONE, "SJMP reladdr	0x80	2	None"},

--Operation:	SUBB
--Function:	Subtract from Accumulator With Borrow
--Syntax:	SUBB A,operand
[0x94] = {2, I_SUBB, {OP_A, OP_DATA}, FLAG_C_AC_OV, "SUBB A,#data	    0x94	2	C, AC, OV"},
[0x95] = {2, I_SUBB, {OP_A, OP_IRAM}, FLAG_C_AC_OV, "SUBB A,iram_addr	0x95	2	C, AC, OV"},
[0x96] = {1, I_SUBB, {OP_A, OP_ATR0}, FLAG_C_AC_OV, "SUBB A,@R0	    0x96	1	C, AC, OV"},
[0x97] = {1, I_SUBB, {OP_A, OP_ATR1}, FLAG_C_AC_OV, "SUBB A,@R1	    0x97	1	C, AC, OV"},
[0x98] = {1, I_SUBB, {OP_A, OP_R0}, FLAG_C_AC_OV, "SUBB A,R0	0x98	1	C, AC, OV"},
[0x99] = {1, I_SUBB, {OP_A, OP_R1}, FLAG_C_AC_OV, "SUBB A,R1	0x99	1	C, AC, OV"},
[0x9A] = {1, I_SUBB, {OP_A, OP_R2}, FLAG_C_AC_OV, "SUBB A,R2	0x9A	1	C, AC, OV"},
[0x9B] = {1, I_SUBB, {OP_A, OP_R3}, FLAG_C_AC_OV, "SUBB A,R3	0x9B	1	C, AC, OV"},
[0x9C] = {1, I_SUBB, {OP_A, OP_R4}, FLAG_C_AC_OV, "SUBB A,R4	0x9C	1	C, AC, OV"},
[0x9D] = {1, I_SUBB, {OP_A, OP_R5}, FLAG_C_AC_OV, "SUBB A,R5	0x9D	1	C, AC, OV"},
[0x9E] = {1, I_SUBB, {OP_A, OP_R6}, FLAG_C_AC_OV, "SUBB A,R6	0x9E	1	C, AC, OV"},
[0x9F] = {1, I_SUBB, {OP_A, OP_R7}, FLAG_C_AC_OV, "SUBB A,R7	0x9F	1	C, AC, OV"},

--Operation:	SWAP
--Function:	Swap Accumulator Nibbles
--Syntax:	SWAP A
[0xC4] = {1, I_SWAP, {OP_A}, FLAG_NONE, "SWAP A	0xC4	1	None"},

--Operation:	Undefined Instruction
--Function:	Undefined
--Syntax:	???
[0xA5] = {1, I_UNDEF, {}, FLAG_C, "???	0xA5	1	C"},

--Operation:	XCH
--Function:	Exchange Bytes
--Syntax:	XCH A,register
[0xC5] = {2, I_XCH, {OP_A, OP_IRAM}, FLAG_NONE, "XCH A,iram_addr	0xC5	2	None"},
[0xC6] = {1, I_XCH, {OP_A, OP_ATR0}, FLAG_NONE, "XCH A,@R0	0xC6	1	None"},
[0xC7] = {1, I_XCH, {OP_A, OP_ATR1}, FLAG_NONE, "XCH A,@R1	0xC7	1	None"},
[0xC8] = {1, I_XCH, {OP_A, OP_R0}, FLAG_NONE, "XCH A,R0	0xC8	1	None"},
[0xC9] = {1, I_XCH, {OP_A, OP_R1}, FLAG_NONE, "XCH A,R1	0xC9	1	None"},
[0xCA] = {1, I_XCH, {OP_A, OP_R2}, FLAG_NONE, "XCH A,R2	0xCA	1	None"},
[0xCB] = {1, I_XCH, {OP_A, OP_R3}, FLAG_NONE, "XCH A,R3	0xCB	1	None"},
[0xCC] = {1, I_XCH, {OP_A, OP_R4}, FLAG_NONE, "XCH A,R4	0xCC	1	None"},
[0xCD] = {1, I_XCH, {OP_A, OP_R5}, FLAG_NONE, "XCH A,R5	0xCD	1	None"},
[0xCE] = {1, I_XCH, {OP_A, OP_R6}, FLAG_NONE, "XCH A,R6	0xCE	1	None"},
[0xCF] = {1, I_XCH, {OP_A, OP_R7}, FLAG_NONE, "XCH A,R7	0xCF	1	None"},

--Operation:	XCHD
--Function:	Exchange Digit
--Syntax:	XCHD A,[@R0/@R1]
[0xD6] = {1, I_XCHD, {OP_A, OP_ATR0}, FLAG_NONE, "XCHD A,@R0	0xD6	1	None"},
[0xD7] = {1, I_XCHD, {OP_A, OP_ATR1}, FLAG_NONE, "XCHD A,@R1	0xD7	1	None"},

--Operation:	XRL
--Function:	Bitwise Exclusive OR
--Syntax:	XRL operand1,operand2
[0x62] = {2, I_XRL, {OP_IRAM, OP_A}, FLAG_NONE, "XRL iram_addr,A	0x62	2	None"},
[0x63] = {3, I_XRL, {OP_IRAM, OP_DATA}, FLAG_NONE, "XRL iram_addr,#data	0x63	3	None"},
[0x64] = {2, I_XRL, {OP_A, OP_DATA}, FLAG_NONE, "XRL A,#data	0x64	2	None"},
[0x65] = {2, I_XRL, {OP_A, OP_IRAM}, FLAG_NONE, "XRL A,iram_addr	0x65	2	None"},
[0x66] = {1, I_XRL, {OP_A, OP_ATR0}, FLAG_NONE, "XRL A,@R0	0x66	1	None"},
[0x67] = {1, I_XRL, {OP_A, OP_ATR1}, FLAG_NONE, "XRL A,@R1	0x67	1	None"},
[0x68] = {1, I_XRL, {OP_A, OP_R0}, FLAG_NONE, "XRL A,R0	0x68	1	None"},
[0x69] = {1, I_XRL, {OP_A, OP_R1}, FLAG_NONE, "XRL A,R1	0x69	1	None"},
[0x6A] = {1, I_XRL, {OP_A, OP_R2}, FLAG_NONE, "XRL A,R2	0x6A	1	None"},
[0x6B] = {1, I_XRL, {OP_A, OP_R3}, FLAG_NONE, "XRL A,R3	0x6B	1	None"},
[0x6C] = {1, I_XRL, {OP_A, OP_R4}, FLAG_NONE, "XRL A,R4	0x6C	1	None"},
[0x6D] = {1, I_XRL, {OP_A, OP_R5}, FLAG_NONE, "XRL A,R5	0x6D	1	None"},
[0x6E] = {1, I_XRL, {OP_A, OP_R6}, FLAG_NONE, "XRL A,R6	0x6E	1	None"},
[0x6F] = {1, I_XRL, {OP_A, OP_R7}, FLAG_NONE, "XRL A,R7	0x6F	1	None"},

}

--[[
bit32.band(...)	-	returns the bitwise and of the input values
bit32.bnot(x)	-	returns the one's complement of x
bit32.bor(...)	-	returns the bitwise or of the input values
bit32.btest(···)	-	returns true if the and of the input values is not 0
bit32.bxor(...)	-	returns the bitwise exclusive or of the input values
bit32.extract(n, field [, width])	-	returns the number of bits set in n for the given 0-31 starting field to optionally field+width-1
bit32.replace(n, v, field [, width])	-	returns n with the bits in field to optionally field+width-1 replaced by the value v
bit32.lrotate(x, disp)	-	returns x rotated disp bits to the left
bit32.lshift(x, disp)	-	<< returns x shifted left disp places or right if negative
bit32.rrotate(x, disp)	-	returns x rotated disp bits to the right
bit32.rshift(x, disp)	-	>> returns x shifted right disp places or left if negative
]]

BIT0 = 0x0001
BIT1 = 0x0002
BIT2 = 0x0004
BIT3 = 0x0008
BIT4 = 0x0010
BIT5 = 0x0020
BIT6 = 0x0040
BIT7 = 0x0080
BIT8 = 0x0100

BIT31 = 0x8000

function sim_log(v0, v1, v2, v3, v4, v5, v6)
    log(v0, v1, v2, v3, v4, v5, v6)
    --print(v0, v1, v2, v3, v4, v5, v6)
end

function bit(p)
    return bit32.lshift(1, p)  -- 1-based indexing
end

-- Typical call:  if hasbit(x, bit(3)) then ...
function hasbit(x, p)
    return bit32.btest(x, bit(p))      
end

function testbit(x, p)
    return bit32.btest(x, bit(p))      
end

function getbit(x, p)
    --sim_log("getbit", x, p, bit(p))
    v = bit32.band(x, bit(p))     
    return v
end

function setbit(x, p)
    return bit32.bor(x, bit(p))
end

function clearbit(x, p)
    local v1 = bit32.bnot(bit(p)) 
    return bit32.band(x, v1)
end

function bits_test(x, p)
    return bit32.btest(x, p)      
end

function bits_and(x, p)
    return bit32.band(x, p)
end

function bits_or(x, p)
    return bit32.bor(x, p)
end

function bits_xor(x, p)
    return bit32.bxor(x, p)
end

function bits_not(x)
    return bit32.bnot(x)
end

function bits_lshift(x, n)  -- <<
    return bit32.lshift(x, n)
end

function bits_rshift(x, n)  -- >>
    return bit32.rshift(x, n)
end

function int_to_byte(v)   
    if (v < 0) then
        v = 0x100 + v;        
    end
    return v
end

function int_to_word(v)    
    if (v < 0) then
        v = 0x10000 + v;        
    end
    return v
end

function byte_to_int(v)   
    if (bits_test(v, 0x80)) then
        --sim_log(v, bits_and(v, 0x7f), bits_and(v, 0x7f) - 128)
        v = bits_and(v, 0x7f) - 128;    
        --sim_log(v)    
    end
    return v
end

function word_to_int(v)    
    if (v > 0x7fff) then
        v = bits_and(v, 0x7fff) - 0x10000;        
    end
    return v
end

sim = {
    a = 0, b = 0, dptr = 0, 
    pc = 0,
    mem = {},
    stack = {},
    r0 = 0, r1 = 0, r2 = 0, r3 = 0, r4 = 0, r5 = 0, r6 = 0, r7 = 0,
    c = 0,
    ac = 0,
    ov = 0,
    breaks = {},
    eof = 0,
    pause = 0,
    running = 0,
}

function sim:init(records)
    self.mem = {}
    for i = 0, 4096 do
        self.mem[i] = 0
    end

    self.code_space = {}
    for i = 0, 4096 do
        self.code_space[i] = 0
    end
end

function sim:check_overflow(v, v1, v2)
    self.c = 0
    self.ac = 0    
    self.ov = 0

    if (v > 0xff) then
        self.c = 1
    end  
    if (v > 0xf) then
        slef.ac = 1
    end  
    if (v < -127 or v > 128) then  -- check ov behavior
        self.ov = 1
    end
end

function sim:push(v)
    sim_log("     push "..tohex(v, 2))
    table.insert(self.stack, v)
    --sim_log("     #stack = "..tostring(#self.stack))
end

function sim:pop()
    local v = self.stack[1]
    table.remove(self.stack, 1)
    sim_log("     pop "..tohex(v, 2))
    return v
end

function sim:mem_get_bit(bitaddr)
    -- mem 0x20 - 0x2F
    --sim_log(bitaddr, bits_rshift(bitaddr, 3), bitaddr % 8) 
    local v = self:get_mem(0x20 + bits_rshift(bitaddr, 3))
    
    if (getbit(v, bitaddr % 8) ~= 0) then
        sim_log("     get bit "..tohex(bitaddr, 4), 1)
        return 1
    else
        sim_log("     get bit "..tohex(bitaddr, 4), 0)
        return 0
    end
end

function sim:mem_get_nbit(bitaddr)
    -- mem 0x20 - 0x2F
    local v = self:get_mem(0x20 + bits_rshift(bitaddr, 3))
    if (getbit(v, bitaddr % 8)) then
        return 0
    else
        return 1
    end
end

function sim:mem_set_bit(bitaddr, b)
    -- mem 0x20 - 0x2F
    local v = self:get_mem(0x20 + bits_rshift(bitaddr, 3))
    local n = bitaddr % 8
    if (b == 1) then
        v = setbit(v, n)    
    else
        v = clearbit(v, n)    
    end
end

function sim:get_mem(addr)
    local v = self.mem[addr]
    sim_log("     get mem "..tohex(addr,4).." = "..tohex(v))
    return v
end

function sim:set_mem(addr, v)
    sim_log("     set mem "..tohex(addr, 4).." = "..tohex(v))
    if (v > 0xff) then
        sim_log(v, "> 0xff")
        v = bits_and(v, 0xff)
    end

    self.mem[addr] = v
    return v
end

function sim:set_a(v)
    sim_log("     set a = "..tohex(v))
    self.a = (v)
end

function sim:set_b(v)
    sim_log("     set b = "..tohex(v))
    self.b = (v)
end

function sim:set_c(v)
    sim_log("     set c = "..tohex(v))
    if (v == 0) then
        self.c = 0
    else
        self.c = 1
    end
end

function sim:set_ov(v)
    sim_log("     set ov = "..tohex(v))
    if (v == 0) then
        self.ov = 0
    else
        self.ov = 1
    end
end

function sim:set_ac(v)
    sim_log("     set ac = "..tohex(v))
    if (v == 0) then
        self.ac = 0
    else
        self.ac = 1
    end
end

function sim:set_r(i, v)    
    sim_log("     set r"..tostring(i).." = "..tohex(v))
    if (i == 0) then self.r0 = v        
    elseif (i == 1) then self.r1 = v
    elseif (i == 2) then self.r2 = v
    elseif (i == 3) then self.r3 = v
    elseif (i == 4) then self.r4 = v
    elseif (i == 5) then self.r5 = v
    elseif (i == 6) then self.r6 = v
    elseif (i == 7) then self.r7 = v
    end    
    return v
end

function sim:set_dptr(v)
    sim_log("     set dptr = "..tohex(v))
    self.dptr = (v)
end

function sim:set_pc(v)
    sim_log("     set pc = "..tohex(v, 4))
    sim.pc = v
end

function sim:jump(addr)
    sim:set_pc(addr)
end

function sim:jump_rel(v)
    local offset = byte_to_int(v)
    sim_log("     jump_rel  "..tostring(offset) )
    sim:set_pc(sim.pc + offset)
end

function sim:call(addr)
    sim:push(sim.pc)
    sim:set_pc(addr)
end

function sim:ret()
    local addr = sim:pop()
    sim:set_pc(addr)
end

function get_real_op(optype, opvalue)
    
    if (op_type == OP_A) then return sim.a 
    elseif (op_type == OP_B) then return sim.b
    elseif (op_type == OP_C) then return sim.c
    elseif (op_type == OP_DATA) then return opvalue
    elseif (op_type == OP_IRAM) then return sim.mem[opvalue]
    elseif (op_type == OP_DPTR) then return sim.dptr
    elseif (op_type == OP_BITADDR) then return opvalue
    elseif (op_type == OP_RELADDR) then return opvalue
    elseif (op_type == OP_R0) then return sim.r0
    elseif (op_type == OP_R1) then return sim.r1
    elseif (op_type == OP_R2) then return sim.r2
    elseif (op_type == OP_R3) then return sim.r3
    elseif (op_type == OP_R4) then return sim.r4
    elseif (op_type == OP_R5) then return sim.r5
    elseif (op_type == OP_R6) then return sim.r6
    elseif (op_type == OP_R7) then return sim.r7
    elseif (op_type == OP_ATR0) then return sim.mem[sim.r0]
    elseif (op_type == OP_ATR1) then return sim.mem[sim.r1]
    elseif (op_type == OP_ATA) then return sim.mem[sim.a]
    elseif (op_type == OP_ATDPTR) then return sim.mem[sim.dptr]
    elseif (op_type == OP_PC) then return sim.pc
    end

    return opvalue
end

function get_arth_inst_op2(inst, op1)
    inst = inst % 16

    if (inst == 0x04) then     v2 = op1
    elseif (inst == 0x05) then v2 = sim.mem[op1]
    elseif (inst == 0x06) then v2 = sim.mem[sim.r0]
    elseif (inst == 0x07) then v2 = sim.mem[sim.r1]
    elseif (inst == 0x08) then v2 = sim.r0
    elseif (inst == 0x09) then v2 = sim.r1
    elseif (inst == 0x0A) then v2 = sim.r2
    elseif (inst == 0x0B) then v2 = sim.r3
    elseif (inst == 0x0C) then v2 = sim.r4
    elseif (inst == 0x0D) then v2 = sim.r5
    elseif (inst == 0x0E) then v2 = sim.r6
    elseif (inst == 0x0F) then v2 = sim.r7
    end

    return v2
end

function inst_acall(bytes, inst, op1)
    --[[
    Operation:	ACALL
    Function:	Absolute Call Within 2K Block
    Syntax:	ACALL code address
    Instructions	OpCode	Bytes	Flags
    ACALL page0	0x11	2	None
    ACALL page1	0x31	2	None
    ACALL page2	0x51	2	None
    ACALL page3	0x71	2	None
    ACALL page4	0x91	2	None
    ACALL page5	0xB1	2	None
    ACALL page6	0xD1	2	None
    ACALL page7	0xF1	2	None
    ]]--
    local addr = ((inst - 0x11) * 0x40) + op1
    sim:call(addr)
end

function inst_add(bytes, inst, op1, op2, op3)
    --[[
    ADD A,#data	0x24	2	1	C, AC, OV
    ADD A,iram_addr	0x25	2	1	C, AC, OV
    ADD A,@R0	0x26	1	1	C, AC, OV
    ADD A,@R1	0x27	1	1	C, AC, OV
    ADD A,R0	0x28	1	1	C, AC, OV
    ADD A,R1	0x29	1	1	C, AC, OV
    ADD A,R2	0x2A	1	1	C, AC, OV
    ADD A,R3	0x2B	1	1	C, AC, OV
    ADD A,R4	0x2C	1	1	C, AC, OV
    ADD A,R5	0x2D	1	1	C, AC, OV
    ADD A,R6	0x2E	1	1	C, AC, OV
    ADD A,R7	0x2F	1	1	C, AC, OV
    --]]
    local v1, v2
    v1 = bits8(sim.a)
    v2 = bits8(get_arth_inst_op2(inst, op1))
    sim:set_a(v1 + v2)
    sim:check_overflow(sim.a, v1, v2)
end

function inst_addc(bytes, inst, op1, op2, op3)
    --[[
    ADDC A,#data	0x34	2	C, AC, OV
    ADDC A,iram addr	0x35	2	C, AC, OV
    ADDC A,@R0	0x36	1	C, AC, OV
    ADDC A,@R1	0x37	1	C, AC, OV
    ADDC A,R0	0x38	1	C, AC, OV
    ADDC A,R1	0x39	1	C, AC, OV
    ADDC A,R2	0x3A	1	C, AC, OV
    ADDC A,R3	0x3B	1	C, AC, OV
    ADDC A,R4	0x3C	1	C, AC, OV
    ADDC A,R5	0x3D	1	C, AC, OV
    ADDC A,R6	0x3E	1	C, AC, OV
    ADDC A,R7	0x3F	1	C, AC, OV
    --]]
    local v1, v2
    v1 = bits8(sim.a)
    v2 = bits8(get_arth_inst_op2(inst, op1))

    sim:set_a(v1 + v2 + sim.cy)
    sim:check_overflow(sim.a, v1, v2)
end


function inst_ajmp(bytes, inst, op1, op2, op3)
    --[[
    Operation:	AJMP
    Function:	Absolute Jump Within 2K Block
    Syntax:	AJMP code address
    Instructions	OpCode	Bytes	Flags
    AJMP page0	0x01	2	None
    AJMP page1	0x21	2	None
    AJMP page2	0x41	2	None
    AJMP page3	0x61	2	None
    AJMP page4	0x81	2	None
    AJMP page5	0xA1	2	None
    AJMP page6	0xC1	2	None
    AJMP page7	0xE1	2	None
    ]]--
    local addr = ((inst - 0x01) * 0x40) + op1
    sim:jump(addr)
end

function inst_anl(bytes, inst, op1, op2, op3)
    -- ANL does a bitwise "AND" operation between operand1 and operand2, 
    -- leaving the resulting value in operand1.
    if     (inst == 0x52) then sim:set_mem(op1, bits_and(sim.mem[op1], sim.a))  -- ANL iram addr,A	0x52	2	None
    elseif (inst == 0x53) then sim:set_mem(op1, bits_and(sim.mem[op1], op2))    -- ANL iram addr,#data	0x53	3	None
    elseif (inst == 0x54) then sim:set_a(bits_and(sim.a, op1))             -- ANL A,#data	0x54	2	None
    elseif (inst == 0x55) then sim:set_a(bits_and(sim.a, sim.mem[op1]))    -- ANL A,iram addr	0x55	2	None
    elseif (inst == 0x56) then sim:set_a(bits_and(sim.a, sim.mem[sim.r0])) -- ANL A,@R0	0x56	1	None
    elseif (inst == 0x57) then sim:set_a(bits_and(sim.a, sim.mem[sim.r1])) -- ANL A,@R1	0x57	1	None
    elseif (inst == 0x58) then sim:set_a(bits_and(sim.a, sim.r0))  -- ANL A,R0	0x58	1	None
    elseif (inst == 0x59) then sim:set_a(bits_and(sim.a, sim.r1))  -- ANL A,R1	0x59	1	None
    elseif (inst == 0x5A) then sim:set_a(bits_and(sim.a, sim.r2))  -- ANL A,R2	0x5A	1	None
    elseif (inst == 0x5B) then sim:set_a(bits_and(sim.a, sim.r3))  -- ANL A,R3	0x5B	1	None
    elseif (inst == 0x5C) then sim:set_a(bits_and(sim.a, sim.r4))  -- ANL A,R4	0x5C	1	None
    elseif (inst == 0x5D) then sim:set_a(bits_and(sim.a, sim.r5))  -- ANL A,R5	0x5D	1	None
    elseif (inst == 0x5E) then sim:set_a(bits_and(sim.a, sim.r6))  -- ANL A,R6	0x5E	1	None
    elseif (inst == 0x5F) then sim:set_a(bits_and(sim.a, sim.r7))  -- ANL A,R7	0x5F	1	None
    elseif (inst == 0x82) then sim:set_c(bits_and(sim.c, sim:mem_get_bit(op1)))  -- ANL C,bit addr	0x82	2	C
    elseif (inst == 0xB0) then sim:set_c(bits_and(sim.c, sim:mem_get_nbit(op1)))  -- ANL C,/bit addr	0xB0	2	C
    end
end

function inst_cjne(bytes, inst, op1, op2, op3)
    --Operation:	CJNE
    --Function:	Compare and Jump If Not Equal
    --Syntax:	CJNE operand1,operand2,reladdr    

    if     (inst == 0xB4) then -- CJNE A,#data,reladdr	0xB4	3	C
        v1 = sim.a
        v2 = op1
    elseif (inst == 0xB5) then  -- CJNE A,iram addr,reladdr	0xB5	3	C
        v1 = sim.a
        v2 = sim.mem[op1]
    elseif (inst == 0xB6) then  -- CJNE @R0,#data,reladdr	0xB6	3	C
        v1 = sim.mem[sim.r0]
        v2 = op1
    elseif (inst == 0xB7) then -- CJNE @R1,#data,reladdr	0xB7	3	C
        v1 = sim.mem[sim.r1]
        v2 = op1
    elseif (inst == 0xB8) then -- CJNE R0,#data,reladdr	0xB8	3	C
        v1 = sim.r0 
        v2 = op1
    elseif (inst == 0xB9) then -- CJNE R1,#data,reladdr	0xB9	3	C
        v1 = sim.r1
        v2 = op1
    elseif (inst == 0xBA) then -- CJNE R2,#data,reladdr	0xBA	3	C
        v1 = sim.r2
        v2 = op1
    elseif (inst == 0xBB) then -- CJNE R3,#data,reladdr	0xBB	3	C
        v1 = sim.r3
        v2 = op1
    elseif (inst == 0xBC) then -- CJNE R4,#data,reladdr	0xBC	3	C
        v1 = sim.r4
        v2 = op1
    elseif (inst == 0xBD) then -- CJNE R5,#data,reladdr	0xBD	3	C
        v1 = sim.r5
        v2 = op1
    elseif (inst == 0xBE) then -- CJNE R6,#data,reladdr	0xBE	3	C
        v1 = sim.r6
        v2 = op1
    elseif (inst == 0xBF) then -- CJNE R7,#data,reladdr	0xBF	3	C
        v1 = sim.r7
        v2 = op1
    end
    
    -- The Carry bit (C) is set if operand1 is less than operand2, otherwise it is cleared.
    if (v1 < v2) then 
        sim:set_c(1) 
    else 
        sim:set_c(0)
    end
    --sim_log("cjne", v1, v2, op1, op2)
    -- compares the value of operand1 and operand2 and branches to the indicated relative address 
    -- if operand1 and operand2 are not equal. 
    -- If the two operands are equal program flow continues with the instruction following the CJNE instruction.
    if (v1 ~= v2) then
        sim:jump_rel(op2)
    end
end


function inst_clr(bytes, inst, op1, op2, op3)
    --[[
    CLR bit addr	0xC2	2	None
    CLR C	0xC3	1	C
    CLR A	0xE4	1	None
    ]]
    if (inst == 0xC2) then
        sim:mem_set_bit(op1, 0)
    elseif (inst == 0xC3) then
        sim:set_c(0)
    elseif (inst == 0xE4) then
        sim:set_a(0)
    end
end

function inst_cpl(bytes, inst, op1, op2, op3)
    --[[
    Operation:	CPL
    Function:	Complement Register
    Syntax:	CPL operand
    Instructions	OpCode	Bytes	Flags
    CPL A	0xF4	1	None
    CPL C	0xB3	1	C
    CPL bit addr	0xB2	2	None
    ]]
    if (inst == 0xF4) then
        sim:set_a(bits_not(sim.a))
    elseif (inst == 0xB3) then
        sim.c = bits_not(sim.c)
    elseif (inst == 0xB2) then
        sim:mem_set_bit(op1, sim:mem_get_nbit(op1))  -- op1 is bit addr
    end
end

function inst_da(bytes, inst, op1, op2, op3)
    --[[
    Operation:	DA
    Function:	Decimal Adjust Accumulator
    Syntax:	DA A
    Instructions	OpCode	Bytes	Flags
    DA	0xD4	1	C

    IF (A3-0 > 9) OR (AC = 1)
      A = A + 6
    IF (A7-4 > 9) OR (C = 1)
      A = A + 60h
    ]]
    
    local a3_0 = bits_and(sim.a, 0xf)
    local a7_4 = bits_and(bits_rshift(sim.a, 4), 0xf)
    
    if (a3_0 > 9 or sim.ac == 1) then
        sim:set_a(sim.a + 6)
    end

    if (a7_4 > 9 or sim.ac == 1) then
        sim:set_a(sim.a + 0x60)
    end
end

function dec(v)
    if (v == 0) then 
        return 0xff
    else 
        return v - 1
    end
end

function inst_dec(bytes, inst, op1, op2, op3)
    --[[
    Operation:	DEC
    Function:	Decrement Register
    Syntax:	DEC register
    Instructions	OpCode	Bytes	Flags
    DEC A	0x14	1	None
    DEC iram addr	0x15	2	None
    DEC @R0	0x16	1	None
    DEC @R1	0x17	1	None
    DEC R0	0x18	1	None
    DEC R1	0x19	1	None
    DEC R2	0x1A	1	None
    DEC R3	0x1B	1	None
    DEC R4	0x1C	1	None
    DEC R5	0x1D	1	None
    DEC R6	0x1E	1	None
    DEC R7	0x1F	1	None
    ]]
    if (inst == 0x14) then     sim:set_a(dec(sim.a))
    elseif (inst == 0x15) then sim:set_mem(op1, dec(sim.mem[op1]))
    elseif (inst == 0x16) then sim:set_mem(sim.r0, dec(sim.mem[sim.r0]))
    elseif (inst == 0x17) then sim:set_mem(sim.r1, dec(sim.mem[sim.r1]))
    elseif (inst == 0x18) then sim:set_r(0, dec(sim.r0))
    elseif (inst == 0x19) then sim:set_r(1, dec(sim.r1))
    elseif (inst == 0x1A) then sim:set_r(2, dec(sim.r2))
    elseif (inst == 0x1B) then sim:set_r(3, dec(sim.r3))
    elseif (inst == 0x1C) then sim:set_r(4, dec(sim.r4))
    elseif (inst == 0x1D) then sim:set_r(5, dec(sim.r5))
    elseif (inst == 0x1E) then sim:set_r(6, dec(sim.r6))
    elseif (inst == 0x1F) then sim:set_r(7, dec(sim.r7))
    end
end

function inst_div(bytes, inst, op1, op2, op3)
    --[[
    Operation:	DIV
    Function:	Divide Accumulator by B
    Syntax:	DIV AB
    Instructions	OpCode	Bytes	Flags
    DIV AB	0x84	1	C, OV
    ]]
    
    if (sim.b == 0) then
        sim:set_ov(1)
    else        
        local v1 = sim.a / sim.b
        local v2 = sim.a % sim.b
        sim:set_a(v1)
        sim:set_b(v2)

        sim:set_ov(0)
    end
end

function inst_djnz(bytes, inst, op1, op2, op3)
    --[[
    Operation:	DJNZ
    Function:	Decrement and Jump if Not Zero
    Syntax:	DJNZ register,reladdr
    Instructions	OpCode	Bytes	Flags
    DJNZ iram addr,reladdr	0xD5	3	None
    DJNZ R0,reladdr	0xD8	2	None
    DJNZ R1,reladdr	0xD9	2	None
    DJNZ R2,reladdr	0xDA	2	None
    DJNZ R3,reladdr	0xDB	2	None
    DJNZ R4,reladdr	0xDC	2	None
    DJNZ R5,reladdr	0xDD	2	None
    DJNZ R6,reladdr	0xDE	2	None
    DJNZ R7,reladdr	0xDF	2	None

    PC = PC + 2
    (direct) = (direct) - 1
    IF (direct) <> 0
      PC = PC + offset

    PC = PC + 2
    Rn = Rn - 1
    IF Rn <> 0
      PC = PC + offset
    ]]
    local v
    if (inst == 0xD5) then v = sim:set_mem(op1, dec(sim.mem[op1]))
    elseif (inst == 0xD8) then v = sim:set_r(0, dec(sim.r0))
    elseif (inst == 0xD9) then v = sim:set_r(1, dec(sim.r1))
    elseif (inst == 0xDA) then v = sim:set_r(2, dec(sim.r2))
    elseif (inst == 0xDB) then v = sim:set_r(3, dec(sim.r3))
    elseif (inst == 0xDC) then v = sim:set_r(4, dec(sim.r4))
    elseif (inst == 0xDD) then v = sim:set_r(5, dec(sim.r5))
    elseif (inst == 0xDE) then v = sim:set_r(6, dec(sim.r6))
    elseif (inst == 0xDF) then v = sim:set_r(7, dec(sim.r7))
    end
    --sim_log(v, op1, op2)
    if (v ~= 0) then
        if (inst == 0xD5) then
            sim:jump_rel(op2)
        else
            sim:jump_rel(op1)
        end
    end
end

function inc(v)
    if (v == 0xff) then 
        return 0
    else 
        return v + 1
    end
end

function inc16(v)
    if (v == 0xffff) then 
        return 0
    else 
        return v + 1
    end
end

function inst_inc(bytes, inst, op1, op2, op3)
    --[[
    Instructions	OpCode	Bytes	Flags
    INC A	0x04	1	None
    INC iram addr	0x05	2	None
    INC @R0	0x06	1	None
    INC @R1	0x07	1	None
    INC R0	0x08	1	None
    INC R1	0x09	1	None
    INC R2	0x0A	1	None
    INC R3	0x0B	1	None
    INC R4	0x0C	1	None
    INC R5	0x0D	1	None
    INC R6	0x0E	1	None
    INC R7	0x0F	1	None
    INC DPTR	0xA3	1	None
    ]]
    if (inst == 0x04) then     sim:set_a(inc(sim.a))
    elseif (inst == 0x05) then sim:set_mem(op1, inc(sim.mem[op1]))
    elseif (inst == 0x06) then sim:set_mem(sim.r0, inc(sim.mem[sim.r0]))
    elseif (inst == 0x07) then sim:set_mem(sim.r1, inc(sim.mem[sim.r1]))
    elseif (inst == 0x08) then sim:set_r(0, inc(sim.r0))
    elseif (inst == 0x09) then sim:set_r(1, inc(sim.r1))
    elseif (inst == 0x0A) then sim:set_r(2, inc(sim.r2))
    elseif (inst == 0x0B) then sim:set_r(3, inc(sim.r3))
    elseif (inst == 0x0C) then sim:set_r(4, inc(sim.r4))
    elseif (inst == 0x0D) then sim:set_r(5, inc(sim.r5))
    elseif (inst == 0x0E) then sim:set_r(6, inc(sim.r6))
    elseif (inst == 0x0F) then sim:set_r(7, inc(sim.r7))
    elseif (inst == 0xA3) then sim:set_dptr(inc16(sim.dptr))
    end
end

function inst_jb(bytes, inst, op1, op2, op3)
    --[[
    Operation:	JB
    Function:	Jump if Bit Set
    Syntax:	JB bit addr, reladdr
    Instructions	OpCode	Bytes	Flags
    JB bit addr,reladdr	0x20	3	None
    
    PC = PC + 3
    IF (bit) = 1
        PC = PC + offset
    ]]
    local bit = sim:mem_get_bit(op1)
    --sim_log("jb  - bit", op1, bit, sim.pc, op2, tohex(sim.pc + op2))
    if (bit) then
        sim:jump_rel(op2)
    end
end

function inst_jbc(bytes, inst, op1, op2, op3)
    --[[
    Operation:	JBC
    Function:	Jump if Bit Set and Clear Bit
    Syntax:	JB bit addr, reladdr
    Instructions	OpCode	Bytes	Flags
    JBC bit addr,reladdr	0x10	3	None

    PC = PC + 3
    IF (bit) = 1
      (bit) = 0
      PC = PC + offset
    ]]
    if (sim:mem_get_bit(op1)) then
        sim:mem_set_bit(op1, 0)
        sim:jump_rel(op2)
    end
end

function inst_jc(bytes, inst, op1, op2, op3)
    --[[
    Operation:	JC
    Function:	Jump if Carry Set
    Syntax:	JC reladdr
    Instructions	OpCode	Bytes	Flags
    JC reladdr	0x40	2	None

    PC = PC + 2
    IF C = 1
      PC = PC + offset
    ]]
    if (sim.c) then        
        sim:jump_rel(op1)
    end
end

function inst_jmp(bytes, inst, op1, op2, op3)
    --[[
    Operation:	JMP
    Function:	Jump to Data Pointer + Accumulator
    Syntax:	JMP @A+DPTR
    Instructions	OpCode	Bytes	Flags
    JMP @A+DPTR	0x73	1	None

    PC = PC + DPTR
    ]]
    sim:jump_rel(sim.a + sim.dptr)
end

function inst_jnb(bytes, inst, op1, op2, op3)
    --[[
    Operation:	JNB
    Function:	Jump if Bit Not Set
    Syntax:	JNB bit addr,reladdr
    Instructions	OpCode	Bytes	Flags
    JNB bit addr,reladdr	0x30	3	None
    ]]
    
    local bit = sim:mem_get_bit(op1)
    if (bit == 0) then
        sim:jump_rel(op2)
    end
end

function inst_jnc(bytes, inst, op1, op2, op3)
    --[[
    Operation:	JNC
    Function:	Jump if Carry Not Set
    Syntax:	JNC reladdr
    Instructions	OpCode	Bytes	Flags
    JNC reladdr	0x50	2	None
    ]]
    if (sim.c == 0) then        
        sim:jump_rel(op1)
    end
end

function inst_jnz(bytes, inst, op1, op2, op3)
    --[[
    Operation:	JNZ
    Function:	Jump if Accumulator Not Zero
    Syntax:	JNZ reladdr
    Instructions	OpCode	Bytes	Flags
    JNZ reladdr	0x70	2	None
    ]]
    if (sim.a ~= 0) then        
        sim:jump_rel(op1)
    end
end

function inst_jz(bytes, inst, op1, op2, op3)
    --[[
    Operation:	JZ
    Function:	Jump if Accumulator Zero
    Syntax:	JNZ reladdr
    Instructions	OpCode	Bytes	Flags
    JZ reladdr	0x60	2	None
    ]]
    if (sim.a == 0) then        
        sim:jump_rel(op1)
    end
end

function inst_lcall(bytes, inst, op1, op2, op3)
    --[[
    Operation:	LCALL
    Function:	Long Call
    Syntax:	LCALL code addr
    Instructions	OpCode	Bytes	Flags
    LCALL code addr	0x12	3	None
   
    PC = PC + 3
    SP = SP + 1
    (SP) = PC[7-0]
    SP = SP + 1
    (SP) = PC[15-8]
    PC = addr16
    ]]

    sim:call((op1 * 256) + op2)
end

function inst_ljmp(bytes, inst, op1, op2, op3)
    --[[
    Operation:	LJMP
    Function:	Long Jump
    Syntax:	LJMP code addr
    Instructions	OpCode	Bytes	Flags
    LJMP code addr	0x02	3	None

    PC = addr16
    ]]

    sim:jump((op1 * 256) + op2)
end



function inst_mov(bytes, inst, op1, op2, op3)
    -- Description: MOV copies the value of operand2 into operand1. 
    -- The value of operand2 is not affected. 
    -- Both operand1 and operand2 must be in Internal RAM. 
    -- No flags are affected unless the instruction is moving the value of a bit into the carry bit 
    -- in which case the carry bit is affected or unless the instruction is moving a value into the PSW register 
    -- (which contains all the program flags).

    -- ** Note: In the case of "MOV iram addr,iram addr", 
    -- the operand bytes of the instruction are stored in reverse order. 
    -- That is, the instruction consisting of the bytes 0x85, 0x20, 0x50 
    -- means "Move the contents of Internal RAM location 0x20 to 
    -- Internal RAM location 0x50" whereas the opposite would be generally presumed.

    -- sim_log("mov ", tohex(inst, 2), tohex(op1, 2), tohex(op2, 2))
    if     (inst == 0x76) then sim:set_mem(sim.r0, op1)       -- MOV @R0,#data	0x76	2	None        
    elseif (inst == 0x77) then sim:set_mem(sim.r1, op1)   -- MOV @R1,#data	0x77	2	None
    elseif (inst == 0xF6) then sim:set_mem(sim.r0, sim.a) -- MOV @R0,A	0xF6	1	None
    elseif (inst == 0xF7) then sim:set_mem(sim.r1, sim.a) -- MOV @R1,A	0xF7	1	None
    elseif (inst == 0xA6) then sim:set_mem(sim.r0, sim.mem[op1]) -- MOV @R0,iram addr	0xA6	2	None       
    elseif (inst == 0xA7) then sim:set_mem(sim.r1, sim.mem[op1]) -- MOV @R1,iram addr	0xA7	2	None
    elseif (inst == 0x74) then sim:set_a(op1) -- MOV A,#data	0x74	2	None
    elseif (inst == 0xE6) then sim:set_a(sim.mem[sim.r0]) -- MOV A,@R0	0xE6	1	None
    elseif (inst == 0xE7) then sim:set_a(sim.mem[sim.r1]) -- MOV A,@R1	0xE7	1	None
    elseif (inst == 0xE8) then sim:set_a(sim.r0) -- MOV A,R0	0xE8	1	None
    elseif (inst == 0xE9) then sim:set_a(sim.r1) -- MOV A,R1	0xE9	1	None
    elseif (inst == 0xEA) then sim:set_a(sim.r2) -- MOV A,R2	0xEA	1	None
    elseif (inst == 0xEB) then sim:set_a(sim.r3) -- MOV A,R3	0xEB	1	None
    elseif (inst == 0xEC) then sim:set_a(sim.r4) -- MOV A,R4	0xEC	1	None
    elseif (inst == 0xED) then sim:set_a(sim.r5) -- MOV A,R5	0xED	1	None
    elseif (inst == 0xEE) then sim:set_a(sim.r6) -- MOV A,R6	0xEE	1	None
    elseif (inst == 0xEF) then sim:set_a(sim.r7) -- MOV A,R7	0xEF	1	None
    elseif (inst == 0xE5) then sim:set_a(sim.mem[op1]) -- MOV A,iram addr	0xE5	2	None

    elseif (inst == 0x90) then sim:set_dptr((op1 * 256) + op2) -- MOV DPTR,#data16	0x90	3	None
    elseif (inst == 0x78) then sim:set_r(0, op1) -- MOV R0,#data	0x78	2	None
    elseif (inst == 0x79) then sim:set_r(1, op1) -- MOV R1,#data	0x79	2	None
    elseif (inst == 0x7A) then sim:set_r(2, op1) -- MOV R2,#data	0x7A	2	None
    elseif (inst == 0x7B) then sim:set_r(3, op1) -- MOV R3,#data	0x7B	2	None
    elseif (inst == 0x7C) then sim:set_r(4, op1) -- MOV R4,#data	0x7C	2	None
    elseif (inst == 0x7D) then sim:set_r(5, op1) -- MOV R5,#data	0x7D	2	None
    elseif (inst == 0x7E) then sim:set_r(6, op1) -- MOV R6,#data	0x7E	2	None
    elseif (inst == 0x7F) then sim:set_r(7, op1) -- MOV R7,#data	0x7F	2	None
    elseif (inst == 0xF8) then sim:set_r(0, sim.a) -- MOV R0,A	0xF8	1	None
    elseif (inst == 0xF9) then sim:set_r(1, sim.a) -- MOV R1,A	0xF9	1	None
    elseif (inst == 0xFA) then sim:set_r(2, sim.a) -- MOV R2,A	0xFA	1	None
    elseif (inst == 0xFB) then sim:set_r(3, sim.a) -- MOV R3,A	0xFB	1	None
    elseif (inst == 0xFC) then sim:set_r(4, sim.a) -- MOV R4,A	0xFC	1	None
    elseif (inst == 0xFD) then sim:set_r(5, sim.a) -- MOV R5,A	0xFD	1	None
    elseif (inst == 0xFE) then sim:set_r(6, sim.a) -- MOV R6,A	0xFE	1	None
    elseif (inst == 0xFF) then sim:set_r(7, sim.a) -- MOV R7,A	0xFF	1	None
    elseif (inst == 0xA8) then sim:set_r(0, sim.mem[op1]) -- MOV R0,iram addr	0xA8	2	None
    elseif (inst == 0xA9) then sim:set_r(1, sim.mem[op1]) -- MOV R1,iram addr	0xA9	2	None
    elseif (inst == 0xAA) then sim:set_r(2, sim.mem[op1]) -- MOV R2,iram addr	0xAA	2	None
    elseif (inst == 0xAB) then sim:set_r(3, sim.mem[op1]) -- MOV R3,iram addr	0xAB	2	None
    elseif (inst == 0xAC) then sim:set_r(4, sim.mem[op1]) -- MOV R4,iram addr	0xAC	2	None
    elseif (inst == 0xAD) then sim:set_r(5, sim.mem[op1]) -- MOV R5,iram addr	0xAD	2	None
    elseif (inst == 0xAE) then sim:set_r(6, sim.mem[op1]) -- MOV R6,iram addr	0xAE	2	None
    elseif (inst == 0xAF) then sim:set_r(7, sim.mem[op1]) -- MOV R7,iram addr	0xAF	2	None
    
    elseif (inst == 0x75) then sim:set_mem(op1, op2) -- MOV iram addr,#data	0x75	3	None
    elseif (inst == 0x86) then sim:set_mem(op1, sim.mem[sim.r0]) -- MOV iram addr,@R0	0x86	2	None
    elseif (inst == 0x87) then sim:set_mem(op1, sim.mem[sim.r1]) -- MOV iram addr,@R1	0x87	2	None
    elseif (inst == 0x88) then sim:set_mem(op1, sim.r0) -- MOV iram addr,R0	0x88	2	None
    elseif (inst == 0x89) then sim:set_mem(op1, sim.r1) -- MOV iram addr,R1	0x89	2	None
    elseif (inst == 0x8A) then sim:set_mem(op1, sim.r2) -- MOV iram addr,R2	0x8A	2	None
    elseif (inst == 0x8B) then sim:set_mem(op1, sim.r3) -- MOV iram addr,R3	0x8B	2	None
    elseif (inst == 0x8C) then sim:set_mem(op1, sim.r4) -- MOV iram addr,R4	0x8C	2	None
    elseif (inst == 0x8D) then sim:set_mem(op1, sim.r5) -- MOV iram addr,R5	0x8D	2	None
    elseif (inst == 0x8E) then sim:set_mem(op1, sim.r6) -- MOV iram addr,R6	0x8E	2	None
    elseif (inst == 0x8F) then sim:set_mem(op1, sim.r7) -- MOV iram addr,R7	0x8F	2	None
    elseif (inst == 0xF5) then sim:set_mem(op1, sim.a) -- MOV iram addr,A	0xF5	2	None
    elseif (inst == 0x85) then sim:set_mem(op2, sim.mem[op1]) -- MOV iram addr,iram addr	0x85	3	None

    elseif (inst == 0xA2) then 
        sim:set_c(sim:mem_get_bit(op1)) -- MOV C,bit addr	0xA2	2	C

    elseif (inst == 0x92) then 
        sim:mem_set_bit(op1, sim.c) -- MOV bit addr,C	0x92	2	None

    end
end

function inst_movc(bytes, inst, op1, op2, op3)
    --[[
    Operation:	MOVC
    Function:	Move Code Byte to Accumulator
    Syntax:	MOVC A,@A+register
    Instructions	OpCode	Bytes	Flags
    MOVC A,@A+DPTR	0x93	1	None
    MOVC A,@A+PC	0x83	1	None
    ]]
    if (inst == 0x93) then
        sim:set_a(sim.mem[sim.a + sim.dptr]) 
    elseif (inst == 0x83) then
        sim:set_a(sim.mem[sim.a + sim.pc]) 
    end
end

function inst_movx(bytes, inst, op1, op2, op3)
    --[[
    Operation:	MOVX
    Function:	Move Data To/From External Memory (XRAM)
    Syntax:	MOVX operand1,operand2
    Instructions	OpCode	Bytes	Flags
    MOVX @DPTR,A	0xF0	1	None
    MOVX @R0,A	0xF2	1	None
    MOVX @R1,A	0xF3	1	None
    MOVX A,@DPTR	0xE0	1	None
    MOVX A,@R0	0xE2	1	None
    MOVX A,@R1	0xE3	1	None
    ]]
    if (inst == 0xF0) then     sim:set_mem(sim.dptr, sim.a)
    elseif (inst == 0xF2) then sim:set_mem(sim.r0, sim.a)
    elseif (inst == 0xF3) then sim:set_mem(sim.r1, sim.a)
    elseif (inst == 0xE0) then sim:set_a(sim.mem[sim.dptr])
    elseif (inst == 0xE2) then sim:set_a(sim.mem[sim.r0])
    elseif (inst == 0xE3) then sim:set_a(sim.mem[sim.r1])
    end
end

function inst_mul(bytes, inst, op1, op2, op3)
    --[[
    Operation:	MUL
    Function:	Multiply Accumulator by B
    Syntax:	MUL AB
    MUL AB	0xA4	1	C, OV
    MUL AB
    BA = A * B
    ]]
    local v = sim.a * sim.b

    if (v > 0xff) then
        sim:set_ov(1)
    else
        sim:set_ov(0)
    end

    sim:set_b(bits_rshift(v, 8))
    sim:set_a(bits_and(v, 0xff))
end

function inst_orl(bytes, inst, op1, op2, op3)
    --[[
    Operation:	ORL
    Function:	Bitwise OR
    Syntax:	ORL operand1,operand2
    Instructions	OpCode	Bytes	Flags
    ORL iram addr,A	0x42	2	None
    ORL iram addr,#data	0x43	3	None
    ORL A,#data	0x44	2	None
    ORL A,iram addr	0x45	2	None
    ORL A,@R0	0x46	1	None
    ORL A,@R1	0x47	1	None
    ORL A,R0	0x48	1	None
    ORL A,R1	0x49	1	None
    ORL A,R2	0x4A	1	None
    ORL A,R3	0x4B	1	None
    ORL A,R4	0x4C	1	None
    ORL A,R5	0x4D	1	None
    ORL A,R6	0x4E	1	None
    ORL A,R7	0x4F	1	None
    ORL C,bit addr	0x72	2	C
    ORL C,/bit addr	0xA0	2	C
    ]]
    local v1, v2

    if (inst == 0x72) then
        sim:set_c(bits_or(sim.c, sim:mem_get_bit(op1)) )
        return
    end
    if (inst == 0xA0) then
        sim:set_c(bits_or(sim.c, sim:mem_get_nbit(op1)))
        return
    end
       
    if (inst == 0x42) then
        v1 = sim:get_mem(op1)
        v2 = sim.a
    elseif (inst == 0x43) then
        v1 = sim:get_mem(op1)
        v2 = op2

    elseif (inst >= 0x44 and inst <= 0x4F) then
        v1 = sim.a
        if (inst == 0x44) then v2 = op1
        elseif (inst == 0x45) then v2 = sim:get_mem(op1)
        elseif (inst == 0x46) then v2 = sim:get_mem(sim.r0)
        elseif (inst == 0x47) then v2 = sim:get_mem(sim.r1)
        elseif (inst == 0x48) then v2 = sim.r0
        elseif (inst == 0x49) then v2 = sim.r1
        elseif (inst == 0x4A) then v2 = sim.r2
        elseif (inst == 0x4B) then v2 = sim.r3
        elseif (inst == 0x4C) then v2 = sim.r4
        elseif (inst == 0x4D) then v2 = sim.r5
        elseif (inst == 0x4E) then v2 = sim.r6
        elseif (inst == 0x4F) then v2 = sim.r7
        end
    end
    --sim_log("bits_or", v1, v2)
    sim:set_a(bits_or(v1, v2))
end

function inst_pop(bytes, inst, op1, op2, op3)
    --[[
    Operation:	POP
    Function:	Pop Value From Stack
    Syntax:	POP
    Instructions	OpCode	Bytes	Flags
    POP iram addr	0xD0	2	None
    ]]
    sim:set_mem(op1, sim:pop())
end

function inst_push(bytes, inst, op1, op2, op3)
    --[[
    Operation:	PUSH
    Function:	Push Value Onto Stack
    Syntax:	PUSH
    Instructions	OpCode	Bytes	Flags
    PUSH iram addr	0xC0	2	None
    ]]
    sim:push(sim.mem[op1])
end

function inst_ret(bytes, inst, op1, op2, op3)
    --[[
    Operation:	RET
    Function:	Return From Subroutine
    Syntax:	RET
    Instructions	OpCode	Bytes	Flags
    RET	0x22	1	None

    PC15-8 = (SP)
    SP = SP - 1
    PC7-0 = (SP)
    SP = SP - 1
    ]]
    sim:ret()
end

function inst_reti(bytes, inst, op1, op2, op3)
    --[[
    Operation:	RETI
    Function:	Return From Interrupt
    Syntax:	RETI
    Instructions	OpCode	Bytes	Flags
    RETI	0x32	1	None

    PC15-8 = (SP)
    SP = SP - 1
    PC7-0 = (SP)
    SP = SP - 1
    ]]
    sim:ret()
end

function inst_nop(bytes, inst, op1, op2, op3)
    -- nop is no operation, so... nothing to do
end

function inst_rl(bytes, inst, op1, op2, op3)
    --[[
    Operation:	RL
    Function:	Rotate Accumulator Left
    Syntax:	RL A
    Instructions	OpCode	Bytes	Flags
    RL A	0x23	1	None

    An+1 = An WHERE n = 0 TO 6
    A0 = A7
    ]]

    -- get A7
    local a7 = getbit(sim.a, 7)
    
    -- do the rotation
    local v = bit32.lrotate(sim.a, 1)
    
    -- get bit 7-1, 0xfe = b'11111110
    v = bits_and(v, 0xfe)  
    
    -- A0 = A7
    if (a7) then
        v = bits_or(v, 1)    
    end
    
    -- store to A
    sim:set_a(v)
end

function inst_rlc(bytes, inst, op1, op2, op3)
    --[[
    Operation:	RLC
    Function:	Rotate Accumulator Left Through Carry
    Syntax:	RLC A
    Instructions	OpCode	Bytes	Flags
    RLC A	0x33	1	C

    An+1 = AN WHERE N = 0 TO 6
    A0 = C
    C = A7
    ]]

    -- do the rotate
    local v = bit32.lrotate(sim.a, 1)  
    
    -- A0 = C
    local a0 = sim.c
    
    -- C = A7, because rotated, now is A8
    sim:set_c(getbit(v, 8))

    -- store to A    
    sim:set_a(bits_and(v, 0xfe))    
end

function inst_rr(bytes, inst, op1, op2, op3)
    --[[
    Operation:	RR
    Function:	Rotate Accumulator Right
    Syntax:	RR A
    Instructions	OpCode	Bytes	Flags
    RR A	0x03	1	None

    An = An+1 where n = 0 to 6
    A7 = A0
    ]]    

    -- get A0
    local a0 = getbit(sim.a, 1)

    -- do the rotate
    local v = bit32.rrotate(sim.a, 1)    
    
    -- get bit 6-0 only      
    v = bits_and(v, 0x7f) 

    -- A7 = A0
    if (a0 ~= 0) then
        v = bits_or(v, 0x80)
    end

    -- store to A
    sim:set_a(v)
end

function inst_rrc(bytes, inst, op1, op2, op3)
    --[[
    Operation:	RRC
    Function:	Rotate Accumulator Right Through Carry
    Syntax:	RRC A
    Instructions	OpCode	Bytes	Flags
    RRC A	0x13	1	C

    An = An+1 where n = 0 to 6
    A7 = C
    C = A0
    ]]
    
    -- A7 = c
    local a7 = sim.c

    -- C = A0    
    sim:set_c(getbit(sim.a, 0))

    -- do the rotate
    local v = bit32.rrotate(sim.a, 1)  
    
    -- get bit 0-6
    v = bits_and(v, 0x7f)

    -- or with a7
    v = bits_or(v, a7)    

    -- store to A
    sim:set_a(v)
end

function inst_setb(bytes, inst, op1, op2, op3)
    --[[
    Operation:	SETB
    Function:	Set Bit
    Syntax:	SETB bit addr
    Instructions	OpCode	Bytes	Flags
    SETB C	0xD3	1	C
    SETB bit addr	0xD2	2	None
    ]]
    if (inst == 0xD2) then
        sim:mem_set_bit(op1, 1)
    elseif (inst == 0xD3) then
        sim:setc(1)
    end
end

function inst_sjmp(bytes, inst, op1, op2, op3)
    --[[
    Operation:	SJMP
    Function:	Short Jump
    Syntax:	SJMP reladdr
    Instructions	OpCode	Bytes	Flags
    SJMP reladdr	0x80	2	None

    PC = PC + 2
    PC = PC + offset
    ]]
    sim:jump_rel(op1)
end

function inst_subb(bytes, inst, op1, op2, op3)
    --[[
    Operation:	SUBB
    Function:	Subtract from Accumulator With Borrow
    Syntax:	SUBB A,operand
    Instructions	OpCode	Bytes	Flags
    SUBB A,#data	0x94	2	C, AC, OV
    SUBB A,iram addr	0x95	2	C, AC, OV
    SUBB A,@R0	0x96	1	C, AC, OV
    SUBB A,@R1	0x97	1	C, AC, OV
    SUBB A,R0	0x98	1	C, AC, OV
    SUBB A,R1	0x99	1	C, AC, OV
    SUBB A,R2	0x9A	1	C, AC, OV
    SUBB A,R3	0x9B	1	C, AC, OV
    SUBB A,R4	0x9C	1	C, AC, OV
    SUBB A,R5	0x9D	1	C, AC, OV
    SUBB A,R6	0x9E	1	C, AC, OV
    SUBB A,R7	0x9F	1	C, AC, OV
    ]]
    local v1, v2
    v1 = sim.a
    v2 = get_arth_inst_op2(inst, op1)
    sim:set_a(v1 - v2)
    sim:check_overflow(sim.a, v1, v2)
end

function inst_swap(bytes, inst, op1, op2, op3)
    --[[
    Operation:	SWAP
    Function:	Swap Accumulator Nibbles
    Syntax:	SWAP A
    Instructions	OpCode	Bytes	Flags
    SWAP A	0xC4	1	None
    A3-0 swap A7-4
    ]]
    local a = sim.a
    local a_3_0 = bits_and(a, 0x0f)
    local a_7_4 = bits_and(a, 0xf0)

    a_3_0 = bits_lshif(a_3_0, 4)
    a_7_4 = bits_rshif(a_7_4, 4)

    a = bits_or(a_3_0, a_7_4)

    sim_set_a(a)
end

function inst_xch(bytes, inst, op1, op2, op3)
    --[[
    Operation:	XCH
    Function:	Exchange Bytes
    Syntax:	XCH A,register
    Instructions	OpCode	Bytes	Flags
    XCH A,@R0	0xC6	1	None
    XCH A,@R1	0xC7	1	None
    XCH A,R0	0xC8	1	None
    XCH A,R1	0xC9	1	None
    XCH A,R2	0xCA	1	None
    XCH A,R3	0xCB	1	None
    XCH A,R4	0xCC	1	None
    XCH A,R5	0xCD	1	None
    XCH A,R6	0xCE	1	None
    XCH A,R7	0xCF	1	None
    XCH A,iram addr	0xC5	2	None

    A swap (Ri)
    ]]
    local v1, v2
    v1 = sim.a
    if     (inst == 0xC5) then v2 = sim.mem[op1]      sim:set_mem(op1, v1)
    elseif (inst == 0xC6) then v2 = sim.mem[sim.r0]   sim:set_mem(sim.r0, v1)
    elseif (inst == 0xC7) then v2 = sim.mem[sim.r1]   sim:set_mem(sim.r1, v1)
    elseif (inst == 0xC8) then v2 = sim.r0  sim:set_r(0, v1)
    elseif (inst == 0xC9) then v2 = sim.r1  sim:set_r(1, v1)
    elseif (inst == 0xCA) then v2 = sim.r2  sim:set_r(2, v1)
    elseif (inst == 0xCB) then v2 = sim.r3  sim:set_r(3, v1)
    elseif (inst == 0xCC) then v2 = sim.r4  sim:set_r(4, v1)
    elseif (inst == 0xCD) then v2 = sim.r5  sim:set_r(5, v1)
    elseif (inst == 0xCE) then v2 = sim.r6  sim:set_r(6, v1)
    elseif (inst == 0xCF) then v2 = sim.r7  sim:set_r(7, v1)    
    end

    sim:set_a(v2)
end

function inst_xchd(bytes, inst, op1, op2, op3)
    --[[
    Operation:	XCHD
    Function:	Exchange Digit
    Syntax:	XCHD A,[@R0/@R1]
    Instructions	OpCode	Bytes	Flags
    XCHD A,@R0	0xD6	1	None
    XCHD A,@R1	0xD7	1	None
    A3-0 swap (Ri)3-0
    ]]
    local a = sim.a    
    local a_3_0 = bits_and(sim.a, 0x0f)
    local a_7_4 = bits_and(sim.a, 0xf0)

    -- get address by instruction
    local addr
    if (inst == 0xD6) then        
        addr = sim.r0
    elseif (inst == 0xD7) then
        addr = sim.r1      
    end
    
    local r = sim.mem[addr]
    local r_3_0 = bits_and(v2, 0x0f)
    local r_7_4 = bits_and(v2, 0xf0)
    
    -- A3-0 swap (Ri)3-0
    a = bits_or(a_7_4, r_3_0)
    r = bits_or(r_7_4, a_3_0)  

    sim:set_a(a)
    sim:set_mem(addr, r)
end

function inst_xrl(bytes, inst, op1, op2, op3)
--[[
]]
end

function inst_undef(bytes, inst, op1, op2, op3)
--[[
]]
end 


local inst_handler = {
[I_ACALL] = inst_acall,
[I_ADD]   = inst_add,
[I_ADDC]  = inst_addc,
[I_AJMP]  = inst_ajmp,
[I_ANL]   = inst_anl,
[I_CJNE]  = inst_cjne, 
[I_CLR]   = inst_clr, 
[I_CPL]   = inst_cpl, 
[I_DA]    = inst_da, 
[I_DEC]   = inst_dec, 
[I_DIV]   = inst_div, 
[I_DJNZ]  = inst_djnz,
[I_INC]   = inst_inc,
[I_JB]    = inst_jb,
[I_JBC]   = inst_jbc,
[I_JC]    = inst_jc,
[I_JMP]   = inst_jmp,
[I_JNB]   = inst_jnb,
[I_JNC]   = inst_jnc,
[I_JNZ]   = inst_jnz, 
[I_JZ]    = inst_jz, 
[I_LCALL] = inst_lcall,
[I_LJMP]  = inst_ljmp,
[I_MOV]   = inst_mov, 
[I_MOVC]  = inst_movc, 
[I_MOVX]  = inst_movx, 
[I_MUL]   = inst_mul, 
[I_NOP]   = inst_nop, 
[I_ORL]   = inst_orl, 
[I_POP]   = inst_pop, 
[I_PUSH]  = inst_push, 
[I_RET]   = inst_ret, 
[I_RETI]  = inst_reti, 
[I_RL]    = inst_rl, 
[I_RLC]   = inst_rlc,
[I_RR]    = inst_rr,
[I_RRC]   = inst_rrc, 
[I_SETB]  = inst_setb, 
[I_SJMP]  = inst_sjmp, 
[I_SUBB]  = inst_subb, 
[I_SWAP]  = inst_swap, 
[I_XCH]   = inst_xch, 
[I_XCHD]  = inst_xchd, 
[I_XRL]   = inst_xrl, 
[I_UNDEF] = inst_undef,
}
function tohex(value, n)
    if (value == nil) then
        return "nil"
    end

    if (type(value) == "string") then
        return value
    end

    if (value < 0) then
        if (n == 2) then
           value = 0x100 + value
        elseif (n == 4) then
           value = 0x10000 + value
        elseif (value > -128) then
            value = 0x100 + value
        else 
            value = 0x10000000 + value
        end
    end

    if (n ~= nil) then
        return string.format("%0"..n.."X", value)        
    else 
        return string.format("%X", value) 
    end
end

function read_whole_file(file)
    local f = io.open(file, "r")
    local content = f:read("*all")
    f:close()
    return content
end

function print_table(t)
    for i = 1, #t do
        sim_log(i, t[i])
    end
end

function temp_convert()
    local text = read_whole_file("c:\\work\\8051\\inst.txt")
    
    for line in text:gmatch("[^\r\n]+") do 
        local tokens = {}
        local i = 1
        for token in string.gmatch(line, "[^%s]+") do    
            t = "I_"..token..",     "
            tokens[i] = t:sub(1, 9)
            i = i + 1
        end
        sim_log(table.concat(tokens))
    end
    
end

function get_lines(text)
    for line in text:gmatch("[^\r\n]+") do 
        sim_log(line)
        
    end
end

function get_tokens(line)
    local tokens = {}
    local i = 1
    for token in string.gmatch(line, "[^%s]+") do    
        tokens[i] = token
        i = i + 1
    end
    return tokens
end

function print_symbol_table()
    for i = 0, #symbol_table do
        sym = symbol_table[i]
        if (sym == nil) then
            sim_log(tohex(i), "nil")
        else
            t = get_tokens(sym[5])
            sim_log(tohex(i), t[1], t[2], t[3], t[4], t[5])
            --sim_log(tohex(i), sym[1], tohex(sym[2]), sym[5])
            v1, v2 = string.find(sym[5], tohex(i))
            if (v1 == nil) then
                sim_log(tohex(i), sym[1], tohex(sym[2]), sym[5])
            end
            --sim_log(v1, v2)
            if (tohex(i) ~= sym[5]:sub(v1, v2)) then
                sim_log(tohex(i), sym[5]:sub(v1, v2), tohex(i) == sym[5]:sub(v1, v2))
            end
        end
    end
    sim_log("total", #symbol_table)
end

--[[
:llaaaatt[dd...]cc
：    Record header 
LL    Data length
aaaa  Address
tt    Data type   
00 - data record
01 - end-of-file record
02 - extended segment address record
04 - extended linear address record
05 - start linear address record (MDK-ARM only) 

dd  Data，bytes = LL 
cc  Checksum。 
]]--
function get_op_str(optype, dd)
    local op = ""
    local optype_str = op_str[optype]

    if (type(dd) == "number") then
        dd = tohex(dd, 2)
    end

    if (optype_str == "#op") then
        op = "#"..dd
    elseif (optype_str == "op") then
        op = dd
    else
        op = optype_str
    end
    return op
end

function parse_dddd(dd, dd1, dd2, dd3)
            
    local inst_code = dd
    if (type(dd) == "string") then
        inst_code = tonumber(dd, 16)
    end

    local sym = symbol_table[inst_code]
    --sim_log(i, dd, r.data[i])
    --sim_log(dd, string.format("%02X", r.data[i])) 
    
    local bytes = sym[1]    
    local inst = symbol_str[sym[2]]    
    local op_types = sym[3]
    local op_n = #op_types
    local op1 = ""
    local op2 = ""
    local op3 = ""

    if (op_n == 0) then 
        op1 = ""
        op2 = ""
    elseif (op_n == 1) then                
        --sim_log(dd, tohex(op_types[1]), op_str[op_types[1]])        
        op1 = get_op_str(op_types[1], dd1)
        op2 = ""
    elseif (op_n == 2) then 
        --sim_log(dd, tohex(op_types[1]), tohex(op_types[2]), op_str[op_types[1]], op_str[op_types[2]])
        op1 = get_op_str(op_types[1], dd1)..","
        op2 = get_op_str(op_types[2], dd2)  
    elseif (op_n == 3) then 
        --sim_log(dd, tohex(op_types[1]), tohex(op_types[2]), op_str[op_types[1]], op_str[op_types[2]])
        op1 = get_op_str(op_types[1], dd1)..","
        op2 = get_op_str(op_types[2], dd2).."," 
        op3 = get_op_str(op_types[3], dd3)
    end    

    if (op_types[1] == OP_CODE and op_types[2] == OP_ADDR) then
        op1 = get_op_str(op_types[1], dd1)..op2
        op2 = ""
    end

    --sim_log(tohex(sim.pc, 4), tohex(inst_code, 2), inst, op1..op2..op3) -- , sym[5]
    local inst_str = inst.."  "..op1..op2..op3
    local inst_lst = {inst=sym[2], op1=op1, op2=op2, op3=op3}
    return bytes, inst_str, inst_lst
end



function sim:get_record_table(text, printout)
    local records = {}
    local index = 1
    local ll, aaaa, tt, dd
    local i, i1
    local line_index = 1

    -- for each line
    for line in text:gmatch("[^\r\n]+") do 
        local r = {}
        r.text = line

        ll   = line:sub(2,3)
        aaaa  = line:sub(4,7)
        tt = line:sub(8,9)

        r.ll = tonumber(ll, 16)
        r.aaaa = tonumber(aaaa, 16)
        r.tt = tonumber(tt, 16)
        r.insts = {}

        --sim_log(index, r.ll, r.aaaa, r.tt, line) 
        if (printout) then
            sim_log(aaaa, "; "..line)
        end
        -- dd start from position 10
        i1 = 10
        
        -- get all instruction data 
        i = 1
        local j = 1
        while (i <= r.ll) do 
            dd0 = line:sub(i1, i1 + 1)
            dd1 = line:sub(i1+2, i1 + 3)
            dd2 = line:sub(i1+4, i1 + 5)
            dd3 = line:sub(i1+6, i1 + 7)
            bytes, dddd, inst = parse_dddd(dd0, dd1, dd2, dd3)
            if (printout) then
                sim_log("      "..dddd)
            end
            
            r.insts[j] = inst
            j = j + 1

            line_index = line_index + 1
            i = i + bytes
            i1 = i1 + 2*bytes
        end

        -- add to records table
        records[index] = r        
        index = index + 1
    end
    return records
end

function sim:mem_fill(addr, len, ddstr)
    local i1 = 1
    local dd
    --sim_log(tohex(addr, 4), tohex(len, 2), ddstr)
    for i = 0, len-1 do
        dd = ddstr:sub(i1, i1 + 1)
        self.code_space[addr + i] = tonumber(dd, 16)             
        --sim_log(tohex(addr + i, 4), dd, tohex(self.mem[addr + i], 2))
        i1 = i1 + 2
    end
end

function sim:load_code(text)
    local ll, aaaa, tt, dd
    local len, addr, type

    -- for each line
    for line in text:gmatch("[^\r\n]+") do 
        ll   = line:sub(2,3)
        aaaa = line:sub(4,7)
        tt   = line:sub(8,9)

        len  = tonumber(ll, 16)
        addr = tonumber(aaaa, 16)
        type = tonumber(tt, 16)
        
        if (type == 0) then
            self:mem_fill(addr, len, line:sub(10, 10 + len*2))
        end
    end
    --sim_log("\n")
    j = 0
    for i = 1, 0x20 do
        local a = addr + j
        local m = {}
        for k = 0, 7 do
            m[k] = tohex(self.code_space[a+k], 2).."  "
        end
        --sim_log(table.concat(m))
        j = j + 8
    end
    --sim_log("\n")
end

function sim:next_inst()
    -- get current program counter 
    local addr = self.pc   

    local inst_code = self.code_space[addr]
    local dd1 = self.code_space[addr + 1]
    local dd2 = self.code_space[addr + 2]
    local dd3 = self.code_space[addr + 3]

    local sym = symbol_table[inst_code]
    local bytes = sym[1]    
    local inst = symbol_str[sym[2]]      
    local s = tohex(inst_code, 2).."    "..inst

    if (bytes == 1) then
        sim_log("     -- ", bytes, s  ) 
    elseif (bytes == 2) then
        sim_log("     -- ", bytes, s, tohex(dd1, 2)) 
    elseif (bytes == 3) then
        sim_log("     -- ", bytes, s, tohex(dd1, 2), tohex(dd2, 2)) 
    elseif (bytes == 4) then
        sim_log("     -- ", bytes, s, tohex(dd1, 2), tohex(dd2, 2), tohex(dd3, 2)) 
    end

    --parse_dddd(inst_code, dd1, dd2, dd3)

    -- move the program counter to the next instruction
    --self:set_pc(self.pc + bytes)
    self.pc = self.pc + bytes

    local f = inst_handler[sym[2]]
    f(sym[2], inst_code, dd1, dd2, dd3)
end

function sim:step(flag)    
    sim_log(tohex(self.pc, 4))
    self:next_inst()
    if (self.pc == nil) then
        sim_log("end of simulation")
        return false
    end
    return true
end

function sim:continue()    
    self.pause = false
    while (self.eof == false and self.pause == false) do 
        sim_log(tohex(self.pc, 4))
        if (self.breaks[self.pc] == 1) then
            self.pause = true
            return
        end
        if (self:step() == false) then
            return
        end
    end
end

function sim:simulation()    
    self.pc = 0x0
    self:continue()
end

function s8051_debugger:get_records_string(records)
    local count = #records
    local s = ""
    for i = 1, count do 
        local r = records[i]
        local s1 = string.format("%02x %04x %d\n", r.ll, r.aaaa, #r.insts)
        for j = 1, #r.insts do
            local dd = r.insts[j]
            local s2 = string.format("    "..tohex(dd.inst,2)..tohex(dd.op1,2)..tohex(dd.op2,2)..tohex(dd.op3,2))    
            s1 = s1..s2.."\n"
        end
        s = s..s1
    end
    return s
end

function s8051_debugger:set_break(addr)
    sim.breaks[addr] = 1
end

function s8051_debugger:Start(fileName, buffer)
    sim:init()
    -- sim.records = sim:get_record_table(text, true)
    sim:load_code(buffer)
    sim.pc = 0x0
    return true
end

function s8051_debugger:Run(fileName, buffer)
    log("s8051_debugger:Run", fileName)
    sim:init()
    -- sim.records = sim:get_record_table(text, true)
    sim:load_code(buffer)
    sim.pc = 0x0
    sim:simulation()
    return true
end

function s8051_debugger:Step()
    sim:step(0)
end

function s8051_debugger:StepOver()
    sim:step(1)
end 

function s8051_debugger:StepOut()
    sim:step(2)
end

function s8051_debugger:Continue()
    sim:continue()
end

function s8051_debugger:Stop( )
end

function s8051_debugger:AddBreakPoint(fileName, lineNumber)
end

function s8051_debugger:RemoveBreakPoint(fileName, lineNumber)
end

function s8051_debugger:ClearAllBreakPoints()
end


function s8051_debugger:Break()
end

function s8051_debugger:Reset()
end

function s8051_debugger:EvaluateExpr(exprRef, expr)
end

function s8051_debugger:KillDebuggee()
end

function s8051_debugger:ihx_scan(text)
    local records = sim:get_record_table(text, true)
    return records
end

function s8051_debugger:ihx_run_file(fn)
    local text = read_whole_file(fn)
    s8051:ihx_run(text)
end

function s8051_debugger:ihx_scan_file(fn)
    local text = read_whole_file(fn)
    return s8051_debugger:ihx_scan(text)
end

--temp_convert()
--print_symbol_table()
--scan_ihx("C:\\work\\8051\\t0\\t0.ihx")

