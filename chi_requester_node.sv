import chi_pkg::*;
module chi_requester_node #(
  parameter logic [3:0] LOCAL_SRC_ID = 4'd1,
  parameter logic [3:0] DEST_TGT_ID  = 4'd0
)(
  input logic clk, rst, tb_valid, flit_in_valid, flit_ready,
  input chi_flit tb_flit, flit_in,
  output logic tb_ready, flit_valid,
  output chi_flit flit_out
);

  typedef enum logic [1:0] {IDLE, SEND_REQ, WAIT_RSP, WAIT_DATA} state_t;
  state_t state;

  chi_flit req_buf;

  always_ff @(posedge clk or negedge rst) begin
    if (!rst) begin
      state <= IDLE;
      flit_out <= '0;
      flit_valid <= 0;
      tb_ready <= 1;
    end else begin
      flit_valid <= 0;
      tb_ready <= 0;

      case (state)
        IDLE: begin
          if (tb_valid) begin
            req_buf <= tb_flit;
            req_buf.src_id <= LOCAL_SRC_ID;
            req_buf.tgt_id <= DEST_TGT_ID;
            state <= SEND_REQ;
            tb_ready <= 1;
          end
        end

        SEND_REQ: begin
          if (flit_ready) begin
            flit_out <= req_buf;
            flit_valid <= 1;
            $display("[Requester] Sent: Addr=0x%08h SrcID=%0d TgtID=%0d", req_buf.address, req_buf.src_id, req_buf.tgt_id);
            state <= WAIT_RSP;
          end
        end

        WAIT_RSP: begin
          if (flit_in_valid && flit_in.flit_type == FLIT_RSP && flit_in.txn_id == req_buf.txn_id) begin
            state <= WAIT_DATA;
          end
        end

        WAIT_DATA: begin
          if (flit_in_valid && flit_in.flit_type == FLIT_DATA && flit_in.txn_id == req_buf.txn_id) begin
            $display("[Requester] Received DATA: Addr=%h Data=%h SrcID=%0d TgtID=%0d", flit_in.address, flit_in.data, flit_in.src_id, flit_in.tgt_id);
            state <= IDLE;
            tb_ready <= 1;
          end
        end
      endcase
    end
  end
endmodule