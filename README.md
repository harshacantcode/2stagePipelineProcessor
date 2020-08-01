# Two staged pipeline processor based on the MIPS architecture
The aim of this project was to generate a simulate a working 2 staged pipeline processor based on the MIPS ISA. 
It follows the Princeton Architecture.
The processor is capable of performing the following operations:

1) ADD
2) ADDI
3) AND
4) ANDI
5) NOR
6) OR
7) ORI
8) SLL
9) SLLV
10) SRA
11) SRAV
12) SRL
13) SRLV
14) SUB
15) XOR
16) XORI
17) SLT
18) SLTU
19) SLTI
20) SLTIU
21) BEQ
22) BGTZ
23) BLEZ
24) BNE
25) J
26) JAL
27) LB
28) SB

To be executed, the MIPS instructions have to be loaded into inst_mem (instruction memory). The data memory, reg files can be initialised with custon values.
