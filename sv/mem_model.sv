//================================================================
// Modelo de memoria parametrizado
//  - Atraso de Leitura : 10ns
//  - Tempo de valid    : 2ns
//----------------------------------------------------------------
// Autor: Lucas Farias Martins
// Email: lucas.martins@ee.ufcg.edu.br
// Data:  15-10-2026
//================================================================

module memory_model #(
    parameter int  ADDR_W  = 9,
    parameter int  DATA_W  = 32,
    parameter int  DEPTH   = 512,
    parameter time LATENCY = 10ns,
    parameter time V_TIME  = 2ns
) (
    input  logic               clk,
    input  logic               req,
    input  logic               we,    
    input  logic [ADDR_W-1:0]  addr,
    input  logic [DATA_W-1:0]  wdata,
    output logic [DATA_W-1:0]  rdata,
    output logic               valid,
    output logic               busy
);

    timeunit 1ns;
    timeprecision 1ps;

    logic [DATA_W-1:0] mem [0:DEPTH-1];

    initial begin
        rdata = '0;
        valid = 1'b0;
        busy  = 1'b0;
        $readmemh("./data/exp1.hex", mem);
    end

    //===================================================
    //  Requisicao aceita com busy baixo
    //===================================================
    always @(posedge clk) begin
        if (req && !busy) begin
            busy = 1'b1;
            fork
                access_memory(we, addr, wdata);
            join_none
        end
    end

    //===================================================
    //  Task de acesso
    //===================================================
    task automatic access_memory(
        input logic              write_enable,
        input logic [ADDR_W-1:0] address,
        input logic [DATA_W-1:0] write_data
    );
        #LATENCY;

        if (write_enable)
            mem[address] = write_data;
        else
            rdata = mem[address];

        valid = 1'b1;
        #V_TIME;
        valid = 1'b0;
        busy  = 1'b0;
    endtask

endmodule
