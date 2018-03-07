//------------------------------------------------------------------------
// FrontPanel Library Module Declarations (Verilog)
// XEM6001
//
// IDELAY and IODELAY fixed delays were determined empirically to meet
// timing for particular devices on particular products.
//
// Copyright (c) 2004-2011 Opal Kelly Incorporated
// $Rev$ $Date$
//------------------------------------------------------------------------

module okHost
	(
	input  wire [7:0]  hi_in,
	output wire [1:0]  hi_out,
	inout  wire [15:0] hi_inout,
	output wire        ti_clk,
	output wire [30:0] ok1,
	input  wire [16:0] ok2
	);
	
	wire [15:0] iobf0_hi_datain;
	wire [15:0] iodly0_datain;
	wire [15:0] hi_datain;
	wire [15:0] hi_dataout;
	wire [2:0]  hi_out_core;
	
	wire [15:0] fdreout0_hi_dataout;
	wire [15:0] fdreout1_hi_drive; 
	
	// Clock buffer for the Host Interface clock.
	wire dcm_clk0, rstin, rst1, rst2, rst3, rst4; 
	
	DCM_SP hi_dcm (.CLKIN     (hi_in[0]),
	               .CLKFB     (ti_clk),
	               .CLK0      (dcm_clk0),
	               .PSCLK     (1'b0),
	               .PSEN      (1'b0),
	               .PSINCDEC  (1'b0),
	               .RST       (rstin),
	               .DSSEN     (1'b0));
	BUFG clkout1_buf (.I(dcm_clk0), .O(ti_clk));
	FDS flop1(.D(1'b0), .C(hi_in[0]), .Q(rst1), .S(1'b0));
	FD flop2(.D(rst1), .C(hi_in[0]), .Q(rst2));
	FD flop3(.D(rst2), .C(hi_in[0]), .Q(rst3));
	FD flop4(.D(rst3), .C(hi_in[0]), .Q(rst4));
	assign rstin = (rst2 | rst3 | rst4);
	
	//IOBs for hi_inout
	genvar i;
	generate
		for (i=0; i<16; i=i+1) begin : delays
			
			IOBUF iobf0 (
				.IO(hi_inout[i]),
				.I(fdreout0_hi_dataout[i]), 
				.O(iobf0_hi_datain[i]), 
				.T(fdreout1_hi_drive[i]) 
			);

			// Input Delay and Registering
			IODELAY2 #(
				.IDELAY_TYPE("FIXED"),
				.IDELAY_VALUE(50),
				.DELAY_SRC("IDATAIN")
			) iodelay_inst (
				.IDATAIN(iobf0_hi_datain[i]),
				.DATAOUT(iodly0_datain[i]),
				.T(1'b1)
			);
  
			(* IOB = "true" *)
			FDRE fdrein0 (
				.D              (iodly0_datain[i]),
				.C              (ti_clk),
				.CE             (1'b1),
				.R              (1'b0),
				.Q              (hi_datain[i])
			);

			// Output Registering
			(* IOB = "true" *)
			FDRE fdreout0 (
				.D              (hi_dataout[i]),
				.C              (ti_clk),
				.CE             (1'b1),
				.R              (1'b0),
				.Q              (fdreout0_hi_dataout[i])
			);

			(* IOB = "true" *)
			FDRE fdreout1 (
				.D              (~hi_out_core[2]),
				.C              (ti_clk),
				.CE             (1'b1),
				.R              (1'b0),
				.Q              (fdreout1_hi_drive[i])
			);

		end
	endgenerate

	OBUF obuf0(.I(hi_out_core[0]), .O(hi_out[0]));
	OBUF obuf1(.I(hi_out_core[1]), .O(hi_out[1]));

	// Instantiate the core Host Interface.
	okCore hicore(.hi_in({hi_in[7:1], ti_clk}), .hi_out(hi_out_core),
	              .hi_datain(hi_datain), .hi_dataout(hi_dataout),
	              .ok1(ok1), .ok2(ok2));
endmodule


module okCore(hi_in, hi_out, hi_datain, hi_dataout, ok1, ok2);
	input  [7:0]  hi_in;
	output [2:0]  hi_out;
	input  [15:0] hi_datain;
	output [15:0] hi_dataout;
	output [30:0] ok1;
	input  [16:0] ok2;
// synthesis attribute box_type okCore "black_box"
endmodule


module okWireIn(ok1, ep_addr, ep_dataout);
	input  [30:0] ok1;
	input  [7:0]  ep_addr;
	output [15:0] ep_dataout;
// synthesis attribute box_type okWireIn "black_box"
endmodule


module okWireOut(ok1, ok2, ep_addr, ep_datain);
	input  [30:0] ok1;
	output [16:0] ok2;
	input  [7:0]  ep_addr;
	input  [15:0] ep_datain;
// synthesis attribute box_type okWireOut "black_box"
endmodule


module okTriggerIn(ok1, ep_addr, ep_clk, ep_trigger);
	input  [30:0] ok1;
	input  [7:0]  ep_addr;
	input         ep_clk;
	output [15:0] ep_trigger;
// synthesis attribute box_type okTriggerIn "black_box"
endmodule


module okTriggerOut(ok1, ok2, ep_addr, ep_clk, ep_trigger);
	input  [30:0] ok1;
	output [16:0] ok2;
	input  [7:0]  ep_addr;
	input         ep_clk;
	input  [15:0] ep_trigger;
// synthesis attribute box_type okTriggerOut "black_box"
endmodule


module okPipeIn(ok1, ok2, ep_addr, ep_write, ep_dataout);
	input  [30:0] ok1;
	output [16:0] ok2;
	input  [7:0]  ep_addr;
	output        ep_write;
	output [15:0] ep_dataout;
// synthesis attribute box_type okPipeIn "black_box"
endmodule


module okPipeOut(ok1, ok2, ep_addr, ep_read, ep_datain);
	input  [30:0] ok1;
	output [16:0] ok2;
	input  [7:0]  ep_addr;
	output        ep_read;
	input  [15:0] ep_datain;
// synthesis attribute box_type okPipeOut "black_box"
endmodule

module okBTPipeIn(ok1, ok2, ep_addr, ep_write, ep_blockstrobe, ep_dataout, ep_ready);
	input  [30:0] ok1;
	output [16:0] ok2;
	input  [7:0]  ep_addr;
	output        ep_write;
	output        ep_blockstrobe;
	output [15:0] ep_dataout;
	input         ep_ready;
// synthesis attribute box_type okBTPipeIn "black_box"
endmodule


module okBTPipeOut(ok1, ok2, ep_addr, ep_read, ep_blockstrobe, ep_datain, ep_ready);
	input  [30:0] ok1;
	output [16:0] ok2;
	input  [7:0]  ep_addr;
	output        ep_read;
	output        ep_blockstrobe;
	input  [15:0] ep_datain;
	input         ep_ready;
// synthesis attribute box_type okBTPipeOut "black_box"
endmodule


module okWireOR # (parameter N = 1)	(
	output reg  [16:0]     ok2,
	input  wire [N*17-1:0] ok2s
	);

	integer i;
	always @(ok2s)
	begin
		ok2 = 0;
		for (i=0; i<N; i=i+1) begin: wireOR
			ok2 = ok2 | ok2s[ i*17 +: 17 ];
		end
	end
endmodule
