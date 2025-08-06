import chi_pkg::*;
module chi_home_node #(
  parameter logic [3:0] MY_NODE_ID = 4'd0
)(
  input logic clk, rst, flit_valid, flit_ready_out,
  input chi_flit flit_in,
  output logic flit_ready, flit_valid_out,
  output chi_flit flit_out
);

  typedef enum logic [1:0] {IDLE, SEND_RSP, SEND_DATA} state_t;
  state_t state;

  chi_flit saved_req;
  logic [31:0] mem [0:1023];
  logic [3:0] line_owner_id [0:1023];
  logic write_enable;
  logic [9:0] write_index;
  logic [31:0] write_data;
  logic [3:0] new_owner;
  logic [3:0] ownership_table [0:1023];
  
  
  always_ff @(posedge clk or negedge rst) begin
    if (!rst) begin
      state <= IDLE;
      flit_ready <= 1;
      flit_valid_out <= 0;
      flit_out <= '0;
      saved_req <= '0;
      write_enable <= 0;
    end else begin
      flit_valid_out <= 0;
      write_enable <= 0;

      case (state)
        IDLE: begin
          if (flit_valid && flit_ready && flit_in.tgt_id == MY_NODE_ID) begin
            saved_req <= flit_in;
            flit_ready <= 0;

            if ((flit_in.opcode == WriteUnique || flit_in.opcode == WriteBack) && flit_in.address[11:2] < 1024) begin
              write_enable <= 1;
              write_index <= flit_in.address[11:2];
              write_data <= flit_in.data;
              $display("[Responder] WRITE Addr=0x%08h Data=0x%08h SrcID=%0d", flit_in.address, flit_in.data, flit_in.src_id);
            end
            state <= SEND_RSP;
          end
        end

        SEND_RSP: begin
          if (flit_ready_out) begin
            flit_out <= '{
              flit_type: FLIT_RSP,
              txn_id: saved_req.txn_id,
              opcode: saved_req.opcode,
              address: saved_req.address,
              data: 32'h0,
              src_id: MY_NODE_ID,
              tgt_id: saved_req.src_id
            };
            flit_valid_out <= 1;
            state <= SEND_DATA;
          end
        end

        SEND_DATA: begin
          if (flit_ready_out) begin
            flit_out <= '{
              flit_type: FLIT_DATA,
              txn_id: saved_req.txn_id,
              opcode: saved_req.opcode,
              address: saved_req.address,
              data: (saved_req.opcode == ReadShared && saved_req.address[11:2] < 1024) ? mem[saved_req.address[11:2]] : saved_req.data,
              src_id: MY_NODE_ID,
              tgt_id: saved_req.src_id
            };
            flit_valid_out <= 1;
            flit_ready <= 1;
            state <= IDLE;
          end
        end
      endcase
    end
  end

  always_ff @(posedge clk or negedge rst) begin
  integer i;
  if (!rst) begin
    for (i = 0; i < 1024; i++) begin
      mem[i] <= 32'h0;
      line_owner_id[i] <= 4'd0;
    end
  end else if (write_enable) begin
    mem[write_index] <= write_data;

    if (saved_req.opcode == WriteUnique) begin
      new_owner = saved_req.txn_id[3:0];
      line_owner_id[write_index] <= new_owner;
      $display("[Ownership] Addr=0x%08h  Owner=%0d", saved_req.address, new_owner);
      ownership_status(saved_req.address, new_owner, 1'b1, write_data);

    end else if (saved_req.opcode == WriteBack) begin
      line_owner_id[write_index] <= 4'd0;
      $display("[Ownership] Addr=0x%08h  Released", saved_req.address);
      ownership_status(saved_req.address, 4'd0, 1'b1, write_data);
    end
  end
end

 task ownership_status(
  input logic [31:0] updated_addr,
  input logic [3:0]  updated_owner,
  input logic        write_en,
  input logic [31:0] override_data
);
  integer j;
  logic [9:0] updated_idx;
  begin
    updated_idx = updated_addr[11:2];

    $display("\n==============================");
    $display("=== Active Line Ownerships ===");
    $display("==============================");

    for (j = 0; j < 1024; j++) begin
      logic [3:0] display_owner;
      logic [31:0] display_data;

   
      display_owner = (j == updated_idx) ? updated_owner : line_owner_id[j];

      if (display_owner != 4'd0) begin
        
        if (write_en && j == updated_idx)
          display_data = override_data;
        else
          display_data = mem[j];

        $display("  Addr: 0x%08h  Owner ID: %0d  Data: 0x%08h", j << 2, display_owner, display_data);
      end
    end

    $display("==============================\n");
  end
endtask




endmodule