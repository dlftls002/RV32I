`timescale 1ns / 1ps

module instruction_mem (
    input  [31:0] instr_addr,
    output [31:0] instr_data
);

    // logic [31:0] rom[0:31];

    // // R type
    // initial begin
    //     rom[0] = 32'h0041_82B3;  // add X5 X3 X4
    //     rom[1] = 32'h4041_8333;  // sub X6 X3 X4
    //     rom[2] = 32'h40A4_03B3;  // sub X7 X8 X10
    //     rom[3] = 32'h01BF_95B3;  // sll X11 X31 X27
    //     rom[4] = 32'h0073_22B3;  // slt X5 X6 X7
    //     rom[5] = 32'h0063_A2B3;  // slt X5 X7 X6
    //     rom[6] = 32'h0073_32B3;  // sltu X5 X6 X7
    //     rom[7] = 32'h0063_B2B3;  // sltu X5 X7 X6
    //     rom[8] = 32'h0041_C2B3;  // xor X5 X3 X4
    //     rom[9] = 32'h01B5_D2B3;  // srl X5 X11 X27
    //     rom[10] = 32'h41B5_D2B3;  // sra X5 X11 X27
    //     rom[11] = 32'h00C1_E2B3;  // or X5 X3 X12
    //     rom[12] = 32'h00C1_F2B3;  // and X5 X3 X12
    // end


    // // I type
    // initial begin
    //     rom[0]  = 32'h00418293;  // addi x5, x3, 4 
    //     rom[1]  = 32'hffc18313;  // addi x6, x3, -4   
    //     rom[2]  = 32'h01bf9393;  // slli x7, x31, 27  
    //     rom[3]  = 32'hffe32293;  // slti x5, x6, -2    
    //     rom[4]  = 32'hffe33293;  // sltiu x5, x6, -2   
    //     rom[5]  = 32'h0041c293;  // xori x5, x3, 4   
    //     rom[6]  = 32'h01b3d293;  // srli x5, x7, 27   
    //     rom[7] = 32'h41b3d293;  // srai x5, x7, 27
    //     rom[8] = 32'h00c1e293;  // ori x5, x3, 12     
    //     rom[9] = 32'h00c1f293;  // andi x5, x3, 12   
    // end


    // // S + I_L type
    // initial begin
    //     rom[0] = 32'h 0011_2123;      // SW  x1, 2(x2)
    //     rom[1] = 32'h 0021_1123;      // SH  x2, 2(x2)
    //     rom[2] = 32'h 0021_91a3;      // SH  x2, 3(x3)
    //     rom[3] = 32'h 0031_0123;      // SB  x3, 2(x2)
    //     rom[4] = 32'h 0041_8123;      // SB  x4, 2(x3)
    //     rom[5] = 32'h 0052_0123;      // SB  x5, 2(x4)
    //     rom[6] = 32'h 0062_8123;      // SB  x6, 2(x5)
    //     rom[7] = 32'h 0021_0083;      // LB  x1, 2(x2)
    //     rom[8] = 32'h 0021_8083;      // LB  x1, 2(x3)
    //     rom[9] = 32'h 0022_0083;      // LB  x1, 2(x4)
    //     rom[10] = 32'h 0022_8083;      // LB  x1, 2(x5)
    //     rom[11] = 32'h 0021_1083;      // LH  x1, 2(x2)
    //     rom[12] = 32'h 0031_9083;      // LH  x1, 3(x3)
    //     rom[13] = 32'h 0021_2083;      // LW  x1, 2(x2)
    //     rom[14] = 32'h ffc1_8293;      // ADDI x5, x3, -4
    //     rom[15] = 32'h ffb1_8313;      // ADDI x6, x3, -5
    //     rom[16] = 32'h 0051_91a3;      // SH  x5, 3(x3)
    //     rom[17] = 32'h 0061_0123;      // SB  x6, 2(x2)
    //     rom[18] = 32'h 0032_4083;      // LBU x1, 3(x4)
    //     rom[19] = 32'h 0021_5083;      // LHU x1, 2(x2)
    // end


    // // B type
    // initial begin
    //     rom[0] = 32'h00628463;  // beq  x5, x6, 8
    //     rom[1]  = 32'h00000013;  // nop 
    //     rom[2] = 32'h00629463;  // bne  x5, x6, 8
    //     rom[3]  = 32'h00000013;  // nop 
    //     rom[4]  = 32'hfff00293;  // addi x5, x0, -1  
    //     rom[5]  = 32'hffe00313;  // addi x6, x0, -2
    //     rom[6]  = 32'h0062c463;  // blt  x5, x6, 8   
    //     rom[7]  = 32'h00000013;  // nop             
    //     rom[8]  = 32'h0062d463;  // bge  x5, x6, 8  
    //     rom[9]  = 32'h00000013;  // nop              
    //     rom[10]  = 32'h0062e463;  // bltu x5, x6, 8  
    //     rom[11]  = 32'h00000013;  // nop              
    //     rom[12] = 32'h0062f463;  // bgeu x5, x6, 8 
    //     rom[13] = 32'h00000013;  // nop            
    // end


    // // U type
    // initial begin
    //     rom[0] = 32'h123452b7;  // lui x5, 0x12345 
    //     rom[1] = 32'h01000317;  // auipc x6, 0x1000 
    //     rom[2] = 32'hfffff3b7;  // lui x7, 0xfffff 
    // end


    // // J type & JALR
    // initial begin
    //     rom[0] = 32'h00c002ef;  // jal  x5, 12   (Jump to rom[3], x5 = 0 + 4)
    //     rom[1] = 32'h00000013;  // nop 
    //     rom[2] = 32'h0000006f;  // jal  x0, 0    (Jump to rom[3], Infinite loop, simulation end)
    //     rom[3] = 32'h00428367;  // jalr x6, x5, 4 (Jump to rom[2](x5(4) + 4 = 8), x6 = 12 + 4)
    // end

    logic [31:0] rom[0:127];

    initial begin
        $readmemh("riscv_rv32i_rom.mem", rom);
    end 

    assign instr_data = rom[instr_addr[31:2]];

endmodule
