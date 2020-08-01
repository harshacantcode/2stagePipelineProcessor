`timescale 1ns / 1ps

module ifu(
input clk,branch,jump,flag,
input [15:0]im,
input [25:0]ta,
output reg [31:0]instr,
output reg [31:0] pc
);

wire [15:0] imm;
assign imm = im;
wire [25:0] target;
assign target = ta;
reg [7:0] inst_mem[31:0];

initial begin

inst_mem[0] = 8'b00000000;
inst_mem[1] = 8'b10000110;
inst_mem[2] = 8'b01001000;
inst_mem[3] = 8'b00100111;
//R9 = R4 NOT R6 -> 11001

inst_mem[4] = 8'b00001000;
inst_mem[5] = 8'b00000000;
inst_mem[6] = 8'b00000000;
inst_mem[7] = 8'b00000101;
//jump forward three instructions

/*
inst_mem[4] = 8'b00000101;
inst_mem[5] = 8'b00100001;
inst_mem[6] = 8'b00000000;
inst_mem[7] = 8'b00000100;
//BGEZ R9
*/
inst_mem[8] = 8'b00000000;
inst_mem[9] = 8'b00000001;
inst_mem[10] = 8'b00001111;
inst_mem[11] = 8'b11000011;
//R1 = R1 >>> 31 SRA

//sthe branch seems to be taken but goes to a wrong value

/*
inst_mem[4] = 8'b00010100;
inst_mem[5] = 8'b10000110;
inst_mem[6] = 8'b00000000;
inst_mem[7] = 8'b00000100;
//bne R4 R6
*/

inst_mem[12] = 8'b00000000;
inst_mem[13] = 8'b01000010;
inst_mem[14] = 8'b00110000;
inst_mem[15] = 8'b00000111;
//r3 = R2 >> R2 (R10>>>2) SRAV

inst_mem[16] = 8'b00000000;
inst_mem[17] = 8'b00100010;
inst_mem[18] = 8'b11111000;
inst_mem[19] = 8'b00101010;
//SLT R31 = R1 < R2(true)

inst_mem[20] = 8'b00101000;
inst_mem[21] = 8'b10011110;
inst_mem[22] = 8'b01111111;
inst_mem[23] = 8'b11111111;
//SLTI R30 = R4 < ---- (true)

inst_mem[24] = 8'b00101111;
inst_mem[25] = 8'b11100010;
inst_mem[26] = 8'b01111111;
inst_mem[27] = 8'b01010101;
//SLTIU R31 = R2 < ---- (true)

pc = 32'b0;
end
reg [29:0] mux_bz,mux_j;
	wire [29:0] pc_add,pc_jump;
	assign pc_jump = {pc[31:28],target};
	assign pc_add = pc[31:2] + 1'b1;

	/*always@(pc_add, branch,flag,imm,instr,pc_jump,jump,mux_bz)
	begin
		if(branch == 1'b1 & flag == 1'b1)
		begin
			mux_bz = pc_add + {{14{imm[15]}},imm[15:0]};
		end
		else
		begin
			mux_bz = pc_add;
		end
		if(jump == 1'b1)
		begin
			mux_j = pc_jump;
		end
		else
		begin
			mux_j = mux_bz;
		end
	end*/
	
	always@(pc_add, branch,flag,imm,instr)
	begin
		if(branch == 1'b1 && flag == 1'b1)
		begin
			mux_bz = pc_add + {{14{imm[15]}},imm[15:0]};
		end
		else
		begin
			mux_bz = pc_add;
		end
		/*if(jump == 1'b1)
		begin
			mux_j = pc_jump;
		end
		else
		begin
			mux_j = mux_bz;
		end*/
	end
	
	always@(pc_jump or jump or mux_bz)
	begin
		/*if(branch == 1'b1 & flag == 1'b1)
		begin
			mux_bz = pc_add + {{14{imm[15]}},imm[15:0]};
		end
		else
		begin
			mux_bz = pc_add;
		end*/
		if(jump == 1'b1)
		begin
			mux_j = pc_jump;
		end
		else
		begin
			mux_j = mux_bz;
		end
	end
	
	
	always@(negedge clk)
	begin
		instr = {inst_mem[pc],inst_mem[pc+1],inst_mem[pc+2],inst_mem[pc+3]};
	   pc = {mux_j,2'b00};
	end

endmodule
module ALU(
	 input [31:0] A,
	 input [31:0] B,
	 input [3:0] ALUop,
	 input [4:0] sa,
	 input bs,sigop,
	 output reg [31:0] O,
	 output reg flag
	 );
	 always@(ALUop[0] or ALUop[1] or ALUop[2] or ALUop[3] or A or B or O or sa or bs or sigop)
	 begin
		flag = 0;
		O = 32'd0;
	if(ALUop == 4'b0000)
	begin
		//addition
		O = A + B;
	end
	else if(ALUop == 4'b0001)
	begin
		//subtraction
		//raising the zero flag
			if(A - B == 0)
			begin
				O = A - B;
				flag = 1;
			end
			else
			begin
				O = A - B;
			end
	 end
	 else if(ALUop == 4'b0010)
	 begin
	 	//logical AND
		O = A & B;
	 end
	 else if(ALUop == 4'b0011)
	 begin
		//logical OR
		O = A | B;
	 end
	 else if(ALUop == 4'b0100)
	 begin
	 	//logical XOR
		O = A ^ B;
	 end
	 else if(ALUop == 4'b0101)
	 begin
	 	  //Set on less than
		 if(sigop == 1)
		  begin
				if($signed(A) < $signed(B))
				begin
					O = 32'd1;
				end
		  end		 
		 else if(A < B)
			begin
				O = 32'd1;
			end
	 end
	 else if(ALUop == 4'b0110)
	 begin
	 	 // shift A left logical by B
		 if(bs == 0)
		 begin
			O = A << sa;
		 end
		 else
		 begin
			O  = A << B;
		 end
	 end
	 else if(ALUop == 4'b0111)
	 begin
	 	 //shift A right logical by B
		 O = A >> sa;
	 end
	 else if(ALUop == 4'b1000)
	 begin
		//NOR
		O = ~(A|B);
	 end
	 else if(ALUop == 4'b1001)
	 begin
		//SRA
		if(bs == 0)
		begin
			//using sa
			O = $signed(A) >>> sa;
		end
		else
		begin
			//using the second input
			O = $signed(A) >>> B;
		end
	 end
	 else if(ALUop == 4'b1010)
	 begin
	 //bne
		O = A - B;
		if(A - B == 0)
		begin
			flag = 0;
		end
		else
		begin
			flag = 1;
		end
	 end
	 else if(ALUop == 4'b1011)
	 begin
	 //bgtz
		if(A > 0)
		begin
			flag = 1;
		end
	 end
	 else if(ALUop == 4'b1100)
	 begin
	 //blez
		if($signed(A) < 0 | $signed(A) == 0)
		begin
			flag = 1;
		end
	 end
	 end
endmodule
module processor(
	input clk,
	output reg [25:0] target,
	output reg [15:0] imm,
	output reg branch,jump,
	output wire flg,
	input [31:0] inst,
	output reg bs,sigop,
	output reg [3:0] ALUop,
	output reg [31:0] busa,
	output reg [31:0] out1,busw,busc,
	output [31:0] O
	);
	reg reg_dest, reg_wr, alu_src, mem_wr, mem_to_reg;
	//wire [25:0] target;
	wire [4:0] rs,rt,rd,sa;
	wire [5:0] func;
	//wire [15:0] imm;
	wire [31:0] instr;
/*	assign imm = instr[15:0];
	assign target = instr[25:0];*/
	reg [31:0] reg_file[31:0];
	reg [7:0] data_mem[63:0];
	initial
	begin
	//as in the MIPS ISA the first reg file is has a zero value
	//giving dummy values for register files 1-6.
	reg_file[0] = 0;
	reg_file[1] = 1;
	reg_file[2] = 2;
	reg_file[3] = 3;
	reg_file[4] = 4;
	reg_file[5] = 5;
	reg_file[6] = 6;
	reg_file[7] = 7;
	reg_file[8] = 8;
	
	end
//	assign data_lo_store_ayye_lanja = data_mem[0]; //my edit to the function

	assign instr = inst;
	assign rs = instr[25:21];
	assign rt = instr[20:16];
	assign rd = instr[15:11];
	assign sa = instr[10:6];
	assign func = instr[5:0];
//as the if condition can only be declared inside an always loop.
	always@(instr)
		begin
			imm = instr[15:0];
			target = instr[25:0];
			assign jump = 0;
			if(instr[31:26] == 6'b000000)
				begin
				//R type instruction
				  reg_dest = 1;
				  reg_wr = 1;
				 alu_src = 0;
				 mem_wr = 0;
				 mem_to_reg = 0;
				 branch = 0;
				 jump = 0;
				 //addcomp = 26'bZ;
				 assign busw = O;
					if(func == 6'b100000)
						begin
							//add
							assign ALUop = 4'b0000;
							assign busa = reg_file[rs];
							assign busc = reg_file[rt];
							assign bs = 0;
							assign sigop = 0;
						end
					else if(func == 6'b100010)
						begin
							//sub
							assign ALUop = 4'b0001;
							assign busa = reg_file[rs];
							assign busc = reg_file[rt];
							assign bs = 0;
							assign sigop = 0;
						end
					else if(func == 6'b100100)
						begin
							//and
							assign ALUop = 4'b0010;
							assign busa = reg_file[rs];
							assign busc = reg_file[rt];
							assign bs = 0;
							assign sigop = 0;
						end
					else if(func == 6'b100101)
						begin
							//or
							assign ALUop = 4'b0011;
							assign busa = reg_file[rs];
							assign busc = reg_file[rt];
							assign bs = 0;
							assign sigop = 0;
						end
					else if(func == 6'b100110)
						begin
							//xor
							assign ALUop = 4'b0100;
							assign busa = reg_file[rs];
							assign busc = reg_file[rt];
							assign bs = 0;
							assign sigop = 0;
						end
					else if(func == 6'b100111)
						begin
							//nor
							assign ALUop = 4'b1000;
							assign busa = reg_file[rs];
							assign busc = reg_file[rt];
							assign bs = 0;
							assign sigop = 0;
						end
					else if(func == 6'b101010)
						begin
							//slt
							assign ALUop = 4'b0101;
							assign busa = reg_file[rs];
							assign busc = reg_file[rt];
							assign bs = 0;
							assign sigop = 0;
						end
					else if(func == 6'b101011)
						begin
							//sltu
							assign ALUop = 4'b0101;
							assign busa = reg_file[rs];
							assign busc = reg_file[rt];
							assign bs = 0;
						   assign sigop = 1;
						end
					else if(func == 6'b000000)
						begin
							//sll
							assign ALUop = 4'b0110;
							assign busa = reg_file[rt];
							assign busc = 32'bz;
							assign bs = 0;
							assign sigop = 0;
						end
					else if(func == 6'b000100)
						begin
							//SLLV
							assign ALUop = 4'b0110;
							assign busa = reg_file[rt];
							assign busc = reg_file[rs];
							assign bs = 1;
							assign sigop = 0;
						end
					else if(func == 6'b000010)
						begin
							//srl
							assign ALUop = 4'b0111;
							assign busa = reg_file[rt];
							assign busc = 32'bz;
							assign bs = 0;
							assign sigop = 0;
						end
					else if(func == 6'b000110)
						begin
							//SRLV
							assign ALUop = 4'b0111;
							assign busa = reg_file[rt];
							assign busc = reg_file[rs];
							assign bs = 1; 
							assign sigop = 0;
						end
					else if(func == 6'b000011)
						begin
							//SRA
							assign ALUop = 4'b1001;
							assign busa = reg_file[rt];
							assign busc = 32'bZ;
							assign bs = 0;
							assign sigop = 0;
						
						end
					else if(func == 6'b000111)
						begin
							//SRAV
							assign ALUop = 4'b1001;
							assign busa = reg_file[rt];
							assign busc = reg_file[rs];
							assign bs = 1;
							assign sigop = 0;
						end
				end
		else
			begin
				if(instr[31:26] == 6'b000100)
					begin
						//beq
						assign ALUop = 4'b0001;
						assign reg_dest = 1'bz;
						assign reg_wr = 0;
						assign alu_src = 0;
						assign mem_wr = 0;
						assign mem_to_reg = 1'bz;
						assign branch = 1;
						
						assign busa = reg_file[rs];
						assign busc = reg_file[rt];
						assign busw = O;
						assign bs = 0;
						assign sigop = 0;
						//assign addcomp = {{10'bZ},imm};
					end
				else if(instr[31:26] == 6'b000101)
					begin
						//bne
						assign ALUop = 4'b1010;
						assign reg_dest = 1'bz;
						assign reg_wr = 0;
						assign alu_src = 0;
						assign mem_wr = 0;
						assign mem_to_reg = 1'bz;
						assign branch = 1;
						
						assign busa = reg_file[rs];
						assign busc = reg_file[rt];		// i am not sure 
						assign busw = O;
						assign bs = 0;
						assign sigop = 0;
						//assign addcomp = {{10'bZ},imm};
					end
				else if(instr[31:26] == 6'b000010)
					begin
						//jump
						assign ALUop = 4'bz;
						assign reg_dest = 1'bz;
						assign reg_wr = 0;
						assign alu_src = 1'bz;
						assign mem_wr = 0;
						assign mem_to_reg = 1'bz;
						assign branch = 0;
						assign jump = 1;
						assign busa = 32'bz;
						assign busc = 32'bz;
						assign busw = O;
						assign bs = 0;
						assign sigop = 0;
						//assign addcomp = target;
					end
				else if(instr[31:26] == 6'b100011)
					begin
						//load word
						assign ALUop = 4'b0000;
						assign reg_dest = 0;
						assign reg_wr = 1;
						assign alu_src = 1;
						assign mem_wr = 0;
						assign mem_to_reg = 1;
						assign branch = 0;
						
						assign busa = reg_file[rs];
						assign busc = {{16{imm[15]}},imm[15:0]};
						assign busw = data_mem[O];
						assign bs = 0;
						assign sigop = 0;
						//assign addcomp = 26'bZ;
					end
				else if(instr[31:26] == 6'b101011)
					begin
						//store word
						assign ALUop = 4'b0000;
						assign reg_dest = 1'bz;
						assign reg_wr = 0;
						assign alu_src = 1;
						assign mem_wr = 1;
						assign mem_to_reg = 1'bz;
						assign branch = 0;
						
						assign busa = reg_file[rs];
						assign busc = {{16{imm[15]}},imm[15:0]};
						assign busw = O;
						assign bs = 0;
						assign sigop = 0;
						//assign addcomp = 26'bZ;
					end
				else if(instr[31:26] == 6'b001000)
					begin
						//addi
						assign ALUop = 4'b0000;
						assign reg_dest = 0;
						assign reg_wr = 1;
						assign alu_src = 1;
						assign mem_wr = 0;
						assign mem_to_reg = 0;
						assign branch = 0;
						
						assign busa = reg_file[rs];
						assign busc = {{16{imm[15]}},imm[15:0]};
						assign busw = O;
						assign bs = 0;
						assign sigop = 0;
						//assign addcomp = 26'bZ;
					end
				else if(instr[31:26] == 6'b001100)
					begin
						//andi
						assign ALUop = 4'b0010;
						assign reg_dest = 0;
						assign reg_wr = 1;
						assign alu_src = 1;
						assign mem_wr = 0;
						assign mem_to_reg = 0;
						assign branch = 0;
						
						assign busa = reg_file[rs];
						assign busc = {{16{1'b0}},imm[15:0]};
						assign busw = O;
						assign bs = 0;
						assign sigop = 0;
						//assign addcomp = 26'bZ;
					end
				else if(instr[31:26] == 6'b001101)
					begin
						//ori
						assign ALUop = 4'b0011;
						assign reg_dest = 0;
						assign reg_wr = 1;
						assign alu_src = 1;
						assign mem_wr = 0;
						assign mem_to_reg = 0;
						assign branch = 0;
					
						assign busa = reg_file[rs];
						assign busc = {{16{1'b0}},imm[15:0]};
						assign busw = O;
						assign bs = 0;
						assign sigop = 0;
						//assign addcomp = 26'bZ;
					end
				else if(instr[31:26] == 6'b001110)
					begin
						//xori
						assign ALUop = 4'b0100;
						assign reg_dest = 0;
						assign reg_wr = 1;
						assign alu_src = 1;
						assign mem_wr = 0;
						assign mem_to_reg = 0;
						assign branch = 0;
						
						assign busa = reg_file[rs];
						assign busc = {{16{1'b0}},imm[15:0]};
						assign busw = O; 
						assign bs = 0;
						assign sigop = 0;
						//assign addcomp = 26'bZ;
					end
				else if(instr[31:26] == 6'b001010)
					begin
						//slti
						assign ALUop = 4'b0101;
						assign reg_dest = 0;
						assign reg_wr = 1;
						assign alu_src = 1;
						assign mem_wr = 0;
						assign mem_to_reg = 0;
						assign branch = 0;
						
						assign busa = reg_file[rs];
						assign busc = {{16{imm[15]}},imm[15:0]};
						assign busw = O; 
						assign bs = 0;
						assign sigop = 1;
						//assign addcomp = 26'bZ;
					end
				else if(instr[31:26] == 6'b001011)
					begin
						//sltiu
						assign ALUop = 4'b0101;
						assign reg_dest = 0;
						assign reg_wr = 1;
						assign alu_src = 1;
						assign mem_wr = 0;
						assign mem_to_reg = 0;
						assign branch = 0;
						
						assign busa = reg_file[rs];
						assign busc = {{16{1'b0}},imm[15:0]};
						assign busw = O; 
						assign bs = 0;
						assign sigop = 0;
						//assign addcomp = 26'bZ;
					end
				else if(instr[31:26] == 6'b000001 & inst[20:16] == 5'b00001)
					begin
						//bgez
						assign ALUop = 4'b1011;
						assign reg_dest = 1'bz;
						assign reg_wr = 0;
						assign alu_src = 0;
						assign mem_wr = 0;
						assign mem_to_reg = 1'bz;
						assign branch = 1;
						
						assign busa = reg_file[rs];
						assign busc = 32'bZ;		
						assign busw = O;
						assign bs = 0;
						assign sigop = 0;
						//assign addcomp = {{10'bZ},imm};
					end
				else if(instr[31:26] == 6'b000111)
					begin
						//blez
						assign ALUop = 4'b1100;
						assign reg_dest = 1'bz;
						assign reg_wr = 0;
						assign alu_src = 0;
						assign mem_wr = 0;
						assign mem_to_reg = 1'bz;
						assign branch = 1;
					
						assign busa = reg_file[rs];
						assign busc = 32'bZ; 
						assign busw = O;
						assign bs = 0;
						assign sigop = 0;
						//assign addcomp = {{10'bZ},imm};
					end
			end
	end
   ALU par(busa, busc, ALUop,sa,bs,sigop,O,fl);
	assign flg = fl;
	always@(negedge clk)
	//writing to reg files and data memory at the falling edge of the clock cycles.
	begin
		if(mem_wr == 1'b1)
			begin
				data_mem[O] <= reg_file[rt];
				out1 <= reg_file[rt];
			end
		if(reg_wr == 1'b1)
			begin
				if(reg_dest == 1'b1)
				begin
					out1 <= busw;
					reg_file[rd] <= busw;
				end
				else
				begin
					out1 <= busw;
					reg_file[rt] <= busw;
				end
			end
	end

endmodule

module pipeline(input clk,output bs,output sigop,output wire [15:0]im1, output wire [25:0]ta1,output br, output ju, output fl1,output [31:0] pc, output [31:0] otp,output [31:0] bus_w,output [31:0] bus_o,output [3:0] aluo_p,output [31:0] ins,output [31:0] insd,output [31:0] out_1);

wire branch,jump,flag;
wire [31:0] instr,instr_dec;
wire [3:0] aluop;
wire [31:0] out1,busw,busc,O;
reg [31:0] inst,inst_dec;
//ifu h1(clk,branch,jump,flag,im1,ta1,instr,pc);
//processor h2(clk,ta1,imm,br,ju,fl1,instr_dec,bs,sigop,aluop,otp,out1,busw,busc,O);


ifu h1(clk,branch,ju,flag,im1,ta1,instr,pc);
processor h2(clk,ta1,im1,br,ju,fl1,instr_dec,bs,sigop,aluop,otp,out1,busw,busc,O);

assign instr_dec=inst_dec;
assign bus_w=busw;
assign bus_o=O;
assign aluo_p=aluop;
assign ins=instr;
assign insd=instr_dec;
assign out_1=out1;
assign branch = br;
assign jump = ju;
assign flag = fl1;
//assign im1 = imm;
//assign ta1 = target;

always @(negedge clk)
begin
inst=instr;
inst_dec=inst;
end
endmodule
