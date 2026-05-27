`timescale 1ns / 1ps

module rv32i_top (
    input clk,
    input rst
);

    logic d_we;
    logic [2:0] o_funct3;
    logic [31:0] instr_addr, instr_data, d_addr, d_wdata, d_rdata;

    instruction_mem U_INSTRUCTION_MEM (.*);

    rv32i_cpu U_RV32I (.*, .o_funct3(o_funct3));

    data_mem U_DATA_MEM (.*, .i_funct3(o_funct3));

endmodule
