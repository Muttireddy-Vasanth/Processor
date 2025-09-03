`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.04.2025 10:51:11
// Design Name: 
// Module Name: processor
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

//Feilds of instruction register
`define oper_type 	IR[31:27]
`define rdst 		IR[26:22]
`define rsrc1 		IR[21:17]
`define imm_mode 	IR[16]
`define rsrc2 		IR[15:11]
`define isrc  		IR[10:0]


///Arithmetic operations
`define movsgpr		5'b0_0000
`define mov			5'b0_0001
`define add			5'b0_0010
`define sub			5'b0_0011
`define mul 		5'b0_0100


//Logical operations- added v to distinguish from macros
`define vor 		5'b0_0101
`define vand		5'b0_0110
`define vxor		5'b0_0111
`define vxnor		5'b0_1000
`define vnor		5'b0_1001
`define vnand		5'b0_1010
`define vnot		5'b0_1011

//Load and Store instruction
`define storereg 		5'b0_1101//store content of reg in data memory
`define storedin		5'b0_1110//store content of din bus in data memory
`define sendout 		5'b0_1111//send data from DM to dout bus
`define sendreg 		5'b1_0000//send data from DM to register


//Jump and branch instruction
`define jump 		5'b1_0001
`define jcarry 		5'b1_0010
`define jnocarry 	5'b1_0011
`define jsign 		5'b1_0100
`define jnosign 	5'b1_0101
`define jzero 		5'b1_0110
`define jnozero 	5'b1_0111
`define joverflow 	5'b1_1000
`define jnooverflow 5'b1_1001

//Halt
`define halt 		5'b1_1011

module top(
			input clk,sys_rst,
			input [15:0]din,
			output reg [15:0]dout
    );

//Adding Program and Data memory
reg [31:0]inst_mem[15:0];//Program memory
reg [31:0]data_mem[15:0];//Data memory
	
reg [31:0] IR;
 ////instruction register <-IR[31:27]-><-IR[26:22]-><-IR[21:17]-><-IR[16]-><-IR[15:11]-><-IR[10:0]->
 ////					  <-operation-><---rdst---><---rsrc1---><-modesel><---rsrc2---><--unused-->
  ////					  <-operation-><---rdst---><---rsrc1---><-modesel><-----immediate_data----->

reg [15:0] GPR [31:0]; ///General purpose registers GPR[0] to GPR[31]
reg [15:0] SGPR; 		//Special register to store multiplication MSB 16 BITS
reg [31:0] mul_res;		//Result of multiplication 

//Conditional flags
reg sign = 0, zero = 0, overflow = 0, carry = 0;
reg jump_flag = 0;
reg stop = 0;

reg [16:0]temp_sum;

task  

always@(*)
begin
case(`oper_type)
/////////////////////////////////
`movsgpr:begin
	
	GPR[`rdst] = SGPR;
	
end
/////////////////////////////////
`mov:begin

	if(`imm_mode)
		GPR[`rdst] = `isrc;
	else
		GPR[`rdst] = GPR[`rsrc1];

end		
/////////////////////////////////
`add:begin

	if(`imm_mode)
		GPR[`rdst] = GPR[`rsrc1] + `isrc;
	else
		GPR[`rdst] = GPR[`rsrc1] + GPR[`rsrc2];

end
/////////////////////////////////
`sub:begin
	if(`imm_mode)
		GPR[`rdst] = GPR[`rsrc1] - `isrc;
	else
		GPR[`rdst] = GPR[`rsrc1] - GPR[`rsrc2];

end
/////////////////////////////////
`mul:begin
	if(`imm_mode)
		mul_res = GPR[`rsrc1] * `isrc;
	else
		mul_res = GPR[`rsrc1] * GPR[`rsrc2];
		
		
	GPR[`rdst]  = mul_res[15:0];
	SGPR		= mul_res[31:16];
 end
/////////////////////////////////
`vor:begin
	if(`imm_mode)
		GPR[`rdst] = GPR[`rsrc1] | `isrc;
	else
		GPR[`rdst] = GPR[`rsrc1] | GPR[`rsrc2];

end

/////////////////////////////////
`vand:begin
	if(`imm_mode)
		GPR[`rdst] = GPR[`rsrc1] & `isrc;
	else
		GPR[`rdst] = GPR[`rsrc1] & GPR[`rsrc2];

end

/////////////////////////////////
`vxor:begin
	if(`imm_mode)
		GPR[`rdst] = GPR[`rsrc1] ^ `isrc;
	else
		GPR[`rdst] = GPR[`rsrc1] ^ GPR[`rsrc2];

end

/////////////////////////////////
`vxnor:begin
	if(`imm_mode)
		GPR[`rdst] = GPR[`rsrc1] ~^ `isrc;
	else
		GPR[`rdst] = GPR[`rsrc1] ~^ GPR[`rsrc2];

end

/////////////////////////////////
`vnor:begin
	if(`imm_mode)
		GPR[`rdst] = ~(GPR[`rsrc1] | `isrc);
	else
		GPR[`rdst] = ~(GPR[`rsrc1] | GPR[`rsrc2]);

end

/////////////////////////////////
`vnand:begin
	if(`imm_mode)
		GPR[`rdst] = ~(GPR[`rsrc1] & `isrc);
	else
		GPR[`rdst] = ~(GPR[`rsrc1] & GPR[`rsrc2]);

end

/////////////////////////////////
`vnot:begin
	if(`imm_mode)
		GPR[`rdst] = ~ (`isrc);
	else
		GPR[`rdst] = ~ (GPR[`rsrc1]) ;

end

endcase
end

//////logic for conditional flags
reg sign = 0, zero = 0, overflow = 0, carry = 0;
reg [16:0]temp_sum;

always@(*)
begin
///sign bit 
if(`oper_type==`mul)
	sign = SGPR[15];
else
	sign = GPR[`rdst][15];
	
///carry bit
if(`oper_type==`add)
	begin
	if(`imm_mode)
		begin
		temp_sum	= GPR[`rsrc1] + IR[15];
		carry 		= temp_sum[16];
		end
	else
		begin
		temp_sum	= GPR[`rsrc1] + GPR[`rsrc2];
		carry 		= temp_sum[16];
		end
	end
else
	begin
		carry = 1'b0;
	end

//zero bit
if(`oper_type==`mul)
	zero = ~((|SGPR)|(|GPR[`rdst]));
else
	zero = ~(|GPR[`rdst]);
	
///overflow bit

if(`oper_type == `add)
	begin
		if(`imm_mode)
			overflow =  ( (~GPR[`rsrc1][15] & ~IR[15] & GPR[`rdst][15]) | (GPR[`rsrc1][15] & IR[15] & ~GPR[`rdst][15]));
		else
			overflow =  ( (~GPR[`rsrc1][15] & ~GPR[`rsrc2][15] & GPR[`rdst][15]) | (GPR[`rsrc1][15] & GPR[`rsrc2][15] & ~GPR[`rdst][15]));
	end
else if(`oper_type == `sub)
	begin
		if(`imm_mode)
			overflow =  ( (~GPR[`rsrc1][15] & IR[15] & GPR[`rdst][15]) | (GPR[`rsrc1][15] & ~IR[15] & ~GPR[`rdst][15]));
		else
			overflow =  ( (~GPR[`rsrc1][15] & GPR[`rsrc2][15] & GPR[`rdst][15]) | (GPR[`rsrc1][15] & ~GPR[`rsrc2][15] & ~GPR[`rdst][15]));
	end
else
			overflow = 1'b0;
end	
endmodule



//FSM

always@(*)
begin
if(sys_rst ==1'b1)
	IR = 0;
else
	begin
	IR = inst_mem[PC};
	decode_inst();
	decode_condflag();
	end
end

reg State, next_state;

//FSM States
parameter 	idle = 0,// Check for reset State
			fetch_inst = 1,//Fetch and load instruction from program memory
			dec_exec_inst = 2,//Execute instruction and update conditioal flags
			next_inst = 3,//Find next instruction to be fetched
			sense_halt = 4,
			delay_next_inst = 5;
			
			
//Next state sequential logic
always@(posedge clk)
begin	
	if(sys_rst)
	state <= idle;
	else
	state <= next_state;
end

//Present state logic
always@(*)
begin
case(state)
	idle:begin
			IR = 32'h0;
			PC = 0;
			next_state = fetch_inst;
		end
	
	fetch_inst:begin
				IR = inst_mem[PC];
				next_state = dec_exec_inst;
				end
	dec_exec_inst:begin
					decode_inst();
					decode_condflag();
					next_state = delay_next_inst;
				   end
				   
	delay_next_inst:begin
					if(count<4)
					next_state = delay_next_inst;
					else
					next_state = next_inst;
					end
	next_inst:begin
				next_state = sense_halt;
				if(jump_flag == 1'b1)
					PC = `isrc;
				else
					PC = PC +1;
			   end

	sense_halt:begin
				if(stop == 1'b0)
				next_state = fetch_inst;
				else if (sys_rst == 1'b1)
				next_state = idle;
				else
				next_state = sense_halt;
			   end
			   
	default: next_state = idle;
endcase
end

always@(posedge clk)
begin
case(state)
	idle:begin
			count <= 0;
		end
	
	fetch_inst:begin
				count <= 0;
				end
	dec_exec_inst:begin
					count <= 0;
				   end
				   
	delay_next_inst:begin
					count <= count =1'b1;
					end
	next_inst:begin
				count <= 0;
			   end

	sense_halt:begin
				count <= 0;
			   end
			   
	default: next_state = idle;
endcase
end
