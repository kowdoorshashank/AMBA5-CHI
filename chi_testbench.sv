// Code your testbench here
// or browse Examples
`include "chi_pkg.sv"
`include "chi_requester_node.sv"
`include "chi_home_node.sv"

module chi_testbench;

  import chi_pkg::*;

  logic clk, rst;
  initial clk = 0;
  always #5 clk = ~clk;

  chi_flit tb_flit;
  logic tb_valid, tb_ready;

  chi_flit rn_to_hn_flit;
  logic rn_to_hn_valid, rn_to_hn_ready;

  chi_flit hn_to_rn_flit;
  logic hn_to_rn_valid, hn_to_rn_ready;

  chi_home_node #(4'd0) hn (
    .clk(clk), .rst(rst), .flit_valid(rn_to_hn_valid),
    .flit_ready_out(hn_to_rn_ready), .flit_in(rn_to_hn_flit),
    .flit_ready(rn_to_hn_ready), .flit_valid_out(hn_to_rn_valid),
    .flit_out(hn_to_rn_flit)
  );

  chi_requester_node #(4'd1, 4'd0) rn (
    .clk(clk), .rst(rst), .tb_valid(tb_valid), .flit_in_valid(hn_to_rn_valid),
    .flit_ready(rn_to_hn_ready), .tb_flit(tb_flit), .flit_in(hn_to_rn_flit),
    .tb_ready(tb_ready), .flit_valid(rn_to_hn_valid),
    .flit_out(rn_to_hn_flit)
  );

  initial begin
    rst = 0;
    tb_flit = '0;
    tb_valid = 0;
    hn_to_rn_ready = 1;
    #20;
    rst = 1;
    #20;

   $display("\n[TB] -- WriteUnique to 0x100 --");
    send_flit(FLIT_REQ, WriteUnique, 32'h100, 8'h01, 32'hABCD1234);
    #30;

    $display("\n[TB] -- WriteUnique to 0x400 --");
    send_flit(FLIT_REQ, WriteUnique, 32'h400, 8'h09, 32'hABCD1000);
    #40;

    $display("\n[TB] -- ReadShared from 0x100 --");
    send_flit(FLIT_REQ, ReadShared, 32'h100, 8'h02, 32'h0);
    #60;

    $display("\n[TB] -- WriteBack to 0x100 --");
    send_flit(FLIT_REQ, WriteBack, 32'h100, 8'h03, 32'h2513B24F);
    #40;
    
    $display("\n[TB] -- WriteUnique to 0x200 --");
    send_flit(FLIT_REQ, WriteUnique, 32'h200, 8'h04, 32'hABCD1004);
    #40;

    $display("\n[TB] -- ReadShared from 0x100 --");
    send_flit(FLIT_REQ, ReadShared, 32'h100, 8'h05, 32'h0);
    #60;

    $display("\n[TB] -- WriteBack to 0x200 --");
    send_flit(FLIT_REQ, WriteBack, 32'h200, 8'h06, 32'h9205B98F);
    #40;

    $display("\n[TB] -- ReadShared from 0x400 --");
    send_flit(FLIT_REQ, ReadShared, 32'h400, 8'h07, 32'h0);
    #60; 
	

    $display("\n[TB] Simulation complete.");
    #100 $finish;
  end

  task send_flit(
    input flit_type t,
    input chi_req_opcode opc,
    input logic [31:0] addr,
    input logic [7:0] txn,
    input logic [31:0] dat
  );
    begin
      @(posedge clk);
      tb_flit.flit_type = t;
      tb_flit.opcode = opc;
      tb_flit.address = addr;
      tb_flit.txn_id = txn;
      tb_flit.data = dat;
      tb_flit.src_id = 4'd1; // match LOCAL_SRC_ID
      tb_flit.tgt_id = 4'd0; // match DEST_TGT_ID
      tb_valid = 1;
      wait (tb_ready == 1);
      @(posedge clk);
      tb_valid = 0;
    end
  endtask

  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, chi_testbench);
  end

endmodule