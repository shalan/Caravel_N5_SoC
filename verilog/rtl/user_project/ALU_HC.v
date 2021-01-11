/*
	RV32I ALU optimized for SKY130A
	Size: ~550 cells (~1800 w/o optimization)
    Delay: ~ 8ns typ
*/

module ALU_HC(
	input   wire [31:0] a, b,
	input   wire [4:0]  shamt,
	output  reg  [31:0] r,
	output  wire        cf, zf, vf, sf,
	input   wire [3:0]  alufn
);

    wire [31:0] add, sub, op_b;
    wire cfa, cfs;
	
	wire alufn0_0, alufn0_1;
	sky130_fd_sc_hd__clkbuf_8 f0BUF0 (.X(alufn0_0), .A(alufn[0]) );
	sky130_fd_sc_hd__clkbuf_8 f0BUF1 (.X(alufn0_1), .A(alufn[0]) );

	sky130_fd_sc_hd__xor2_1 XOR0[15:0] ( .A(b[15:0]), .B(alufn0_0), .X(op_b[15:0]) );
	sky130_fd_sc_hd__xor2_1 XOR1[31:16] ( .A(b[31:16]), .B(alufn0_1), .X(op_b[31:16]) );
	
	csa32_8 CSA32 ( .a(a), .b(op_b), .ci(alufn[0]), .s(add), .co(cf) );
	
    //assign op_b = (~b);
    //assign {cf, add} = alufn[0] ? (a + op_b + 1'b1) : (a + b);

    assign zf = (add == 0);
    assign sf = add[31];
    assign vf = (a[31] ^ (op_b[31]) ^ add[31] ^ cf);

    wire[31:0] sh;
    shift shift0 ( .a(a), .shamt(shamt), .typ(alufn[1:0]), .r(sh) );

    always @ * begin
        //r = 0;

		(* parallel_case *)
        case (alufn)
            // arithmetic
            4'b00_00 : r = add;
            4'b00_01 : r = add;
            4'b00_11 : r = b;
            // logic
            4'b01_00:  r = a | b;
            4'b01_01:  r = a & b;
            4'b01_11:  r = a ^ b;
            // shift
            4'b10_00:  r=sh;
            4'b10_01:  r=sh;
            4'b10_10:  r=sh;
            // slt & sltu
            4'b11_01:  r = {31'b0,(sf != vf)};
            4'b11_11:  r = {31'b0,(~cf)};

			default:	r = add;
        endcase
    end
endmodule

// n-bit RCA using n FA instances
// 32-bit delay is 12.4 ns typ
module rca #(parameter n=32) ( 
	input [n-1:0] 	a, b,
	input 			ci,
	output [n-1:0]	s,
	output			co
);
	wire [n:0] c;
	
	assign c[0] = ci;
	assign co = c[n];
	
	generate 
		genvar i;
		for(i=0; i<n; i=i+1) 
			sky130_fd_sc_hd__fa_1 FA ( .COUT(c[i+1]), .CIN(c[i]), .A(a[i]), .B(b[i]), .SUM(s[i]) );
   	endgenerate

endmodule

// 32-bit Carry Select Adder 2x16
// 65 cells; <7ns typ
module csa32_16( 
	input [31:0] 	a, b,
	input 			ci,
	output [31:0]	s,
	output			co
);

	wire co0, co10, co11;
	wire [15:0] s10, s11;
	rca #(16) A0  (.a(a[15:0]), .b(b[15:0]), .ci(ci), .co(co0), .s(s[15:0]) );
	rca #(16) A10  (.a(a[31:16]), .b(b[31:16]), .ci(), .co(co10), .s(s10) );
	rca #(16) A11  (.a(a[31:16]), .b(b[31:16]), .ci(), .co(co10), .s(s11) );
	sky130_fd_sc_hd__mux2_1 SMUX [15:0] ( .X(s[31:16]), .A0(s10), .A1(s11), .S(co0) );
	sky130_fd_sc_hd__mux2_1 CMUX ( .X(co), .A0(co10), .A1(co11), .S(co0) );

endmodule

// 32-bit Carry Select Adder 4x8
// 84 cells ( <5ns Typ)
module csa32_8( 
	input [31:0] 	a, b,
	input 			ci,
	output [31:0]	s,
	output			co
);
	//parameter m = 8;
	wire 		co0, co1, co2, co3;
	wire [3:1] 	c0, c1;
	wire [7:0] 	s0[3:1], s1[3:1];
	wire		lo, hi; 

	sky130_fd_sc_hd__conb_1 TIE (.LO(lo), .HI(hi));

	rca #(8) A0  (.a(a[7:0]), .b(b[7:0]), .ci(ci), .co(co0), .s(s[7:0]) );
	
	rca #(8) A10  (.a(a[15:8]), .b(b[15:8]), .ci(lo), .co(c0[1]), .s(s0[1]) );
	rca #(8) A11  (.a(a[15:8]), .b(b[15:8]), .ci(hi), .co(c1[1]), .s(s1[1]) );
	sky130_fd_sc_hd__mux2_1 SMUX1 [7:0] ( .X(s[15:8]), .A0(s0[1]), .A1(s1[1]), .S(co0) );
	sky130_fd_sc_hd__mux2_1 CMUX1 ( .X(co1), .A0(c0[1]), .A1(c1[1]), .S(co0) );
	
	rca #(8) A20  (.a(a[23:16]), .b(b[23:16]), .ci(lo), .co(c0[2]), .s(s0[2]) );
	rca #(8) A21  (.a(a[23:16]), .b(b[23:16]), .ci(hi), .co(c1[2]), .s(s1[2]) );
	sky130_fd_sc_hd__mux2_1 SMUX2 [7:0] ( .X(s[23:16]), .A0(s0[2]), .A1(s1[2]), .S(co1) );
	sky130_fd_sc_hd__mux2_1 CMUX2 ( .X(co2), .A0(c0[2]), .A1(c1[2]), .S(co1) );

	rca #(8) A30  (.a(a[31:24]), .b(b[31:24]), .ci(lo), .co(c0[3]), .s(s0[3]) );
	rca #(8) A31  (.a(a[31:24]), .b(b[31:24]), .ci(hi), .co(c1[3]), .s(s1[3]) );
	sky130_fd_sc_hd__mux2_1 SMUX3 [7:0] ( .X(s[31:24]), .A0(s0[3]), .A1(s1[3]), .S(co2) );
	sky130_fd_sc_hd__mux2_1 CMUX3 ( .X(co), .A0(c0[2]), .A1(c1[2]), .S(co2) );
endmodule


// Shift Right Unit: 166 instances
module shr(input [31:0] a, output [31:0] r, input [4:0] shamt, input ar);
    wire 		fill_1, fill_2;
    wire [4:0]	shamt_buf;
    wire [31:0] r1, r2, r3, r4;
    wire [31:0]	sh1, sh2, sh4, sh8, sh16;
    
    // Buffer the shift amount
    sky130_fd_sc_hd__clkbuf_16 SBUF[4:0] (.X(shamt_buf), .A(shamt) );
    
	// Generat ethe fill bit
    sky130_fd_sc_hd__and2_4 F1 ( .X(fill_1), .A(ar), .B(a[31]) );
    sky130_fd_sc_hd__and2_4 F2 ( .X(fill_2), .A(ar), .B(a[31]) );
    
	assign sh1 = {fill_1, a[31:1]};
	assign sh2 = {{2{fill_1}}, r2[31:2]};
	assign sh4 = {{4{fill_1}}, r2[31:4]};
	assign sh8 = {{8{fill_1}}, r2[31:8]};
	assign sh16 = {{16{fill_2}}, r2[31:16]};

	sky130_fd_sc_hd__mux2_1 row0 [31:0] ( .X(r1), .A0(a), .A1(sh1), .S(shamt_buf[0]) );
	sky130_fd_sc_hd__mux2_1 row1 [31:0] ( .X(r2), .A0(r1), .A1(sh2), .S(shamt_buf[1]) );
	sky130_fd_sc_hd__mux2_1 row2 [31:0] ( .X(r3), .A0(r2), .A1(sh4), .S(shamt_buf[2]) );
	sky130_fd_sc_hd__mux2_1 row3 [31:0] ( .X(r4), .A0(r3), .A1(sh8), .S(shamt_buf[3]) );
	sky130_fd_sc_hd__mux2_1 row4 [31:0] ( .X(r), .A0(r4), .A1(sh16), .S(shamt_buf[4]) );
	
endmodule

// Mirioring Unit for the Shifter
module mirror (input [31:0] in, output reg [31:0] out);
    integer i;
    always @ *
        for(i=0; i<32; i=i+1)
            out[i] = in[31-i];
endmodule

// 32-bit Barrel Shifter!
// 224 cells, 7.5ns typ
module shift(
		input wire [31:0] a,
		input wire [4:0] shamt,
		input wire [1:0] typ,	// type[0] sll or srl - type[1] sra
								// 00 : srl, 10 : sra, 01 : sll
		output wire [31:0] r
	);
    wire [31 : 0] ma, my, y, x, sy;
    wire [1:0] sel;

    mirror m1(.in(a), .out(ma));
    mirror m2(.in(y), .out(my));

    //assign x = typ[0] ? ma : a;
    sky130_fd_sc_hd__clkbuf_16 SBUF[1:0] (.X(sel), .A(typ[0]) );
    sky130_fd_sc_hd__mux2_1 imux [31:0] ( .X(x), .A0(a), .A1(ma), .S(sel[0]) );
    sky130_fd_sc_hd__mux2_1 omux [31:0] ( .X(r), .A0(y), .A1(my), .S(sel[1]) );
    
    shr sh0(.a(x), .r(y), .shamt(shamt), .ar(typ[1]));
    //assign r = typ[0] ? my : y;
endmodule

