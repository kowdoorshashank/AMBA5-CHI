package chi_pkg;

typedef enum logic [3:0] {
  ReadShared = 4'b0000,
  WriteBack = 4'b0001,
  WriteUnique = 4'b0010
} chi_req_opcode;

typedef enum logic [1:0] {
  FLIT_REQ = 2'b00,
  FLIT_RSP = 2'b01,
  FLIT_DATA = 2'b10
} flit_type;

typedef struct packed {
  flit_type flit_type;
  chi_req_opcode opcode;
  logic [31:0] address;
  logic [7:0] txn_id;
  logic [31:0] data;
  logic [3:0] src_id;
  logic [3:0] tgt_id;
} chi_flit;

endpackage