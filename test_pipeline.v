`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   07:39:10 02/19/2020
// Design Name:   pipeline
// Module Name:   /home/sreeharsha/ipa_project/test_pipeline.v
// Project Name:  ipa_project
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: pipeline
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module test_pipeline;

	// Inputs
	reg clk;

	// Outputs
	wire [31:0] otp;
	wire [31:0] bus_w;
	wire [31:0] bus_o;
	wire [31:0] ins;
	wire [2:0] aluo_p;
	wire [31:0] insd;
	wire [31:0] out_1;

	// Instantiate the Unit Under Test (UUT)
	pipeline uut (
		.clk(clk), 
		.otp(otp),
		.bus_w(bus_w),
		.bus_o(bus_o),
		.ins(ins),
		.insd(insd),
		.aluo_p(aluo_p),
		.out_1(out_1)
	);
initial clk=1;
always #50 clk=~clk;
	initial begin
		// Initialize Inputs
		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

	end
      
endmodule

