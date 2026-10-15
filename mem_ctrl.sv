//================================================================
// Controlador de memoria & Gerador de burst
//----------------------------------------------------------------
// Autor: Lucas Farias Martins
// Email: lucas.martins@ee.ufcg.edu.br
// Data:  15-10-2026
//================================================================

module memory_ctrl #(
    parameter int  ADDR_W      = 9,
    parameter int  DATA_W      = 32,
    parameter int  DEPTH       = 512,
    parameter time SYS_CLOCK   = 1ns,
    parameter time MEM_LATENCY = 10ns,
    parameter time V_TIME      = 2ns
)(
    input  logic              clk,
    input  logic              rstn,
    input  logic              enb,
    output logic [DATA_W-1:0] rdata_o
);

    localparam BANK = MEM_LATENCY / SYS_CLOCK;

    //==========================================================
    //  Internos
    //==========================================================
    typedef enum logic [1:0] {IDLE, SEND_REQ, GET_RESP} state_t;

    state_t          CS, NS; 
    logic            first_req;
    logic            enb_r;
    logic [BANK-1:0] req;
    logic [BANK-1:0] we;
    logic [BANK-1:0] valid;
    logic [BANK-1:0] busy;

    // logic [ADDR_W-1:0][0:BANK-1] addr;
    // logic [DATA_W-1:0][0:BANK-1] wdata;
    // logic [DATA_W-1:0][0:BANK-1] rdata;
    logic [ADDR_W-1:0] addr  [BANK];
    logic [DATA_W-1:0] wdata [BANK];
    logic [DATA_W-1:0] rdata [BANK];

    //===================================================
    //  First Requisition
    //===================================================
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) 
            first_req <= 0;
        else if (enb && CS==IDLE) 
            first_req <= 1;
        else
            first_req <= 0;
    end   

    //==========================================================
    //                   MAQUINA DE ESTADOS 
    //              Atual e Proximo desacoplados
    //==========================================================
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) CS <= IDLE;
        else        CS <= NS;
    end

    always_comb begin
        case (CS)
            IDLE:     NS = (enb) ? SEND_REQ : IDLE;
            SEND_REQ: NS = (req[BANK-1]) ? GET_RESP : SEND_REQ;
            GET_RESP: NS = (req[BANK-1]) ? SEND_REQ : GET_RESP;
            default:  NS = IDLE;
        endcase
    end

    //===================================================
    //  Requisition Shift Array
    //===================================================
    generate
    for (genvar i=1; i < BANK; i++) begin 
        always_ff @( posedge clk or negedge rstn ) begin
            if (!rstn)
                req[i] <= '0;
            else if (CS != IDLE) 
                req[i] <= req[i-1];
        end
    end
    endgenerate

    always_ff @( posedge clk or negedge rstn ) begin
        if (!rstn)           req[0] <= '0;
        else if (CS != IDLE) req[0] <= first_req;
    end

    //===================================================
    //  Memory Bank
    //===================================================
    generate
    for (genvar j=0; j<BANK; j++) begin
        memory_model #(
            .ADDR_W   ( 9        ),
            .DATA_W   ( 32       ),
            .DEPTH    ( 512      ),
            .LATENCY  ( 10ns     ),
            .V_TIME   ( 2ns      )
        ) u_mem (
            .clk      ( clk      ),
            .req      ( req[j]   ),
            .we       ( we[j]    ),    
            .addr     ( addr[j]  ),
            .wdata    ( wdata[j] ),
            .rdata    ( rdata[j] ),
            .valid    ( valid[j] ),
            .busy     ( busy[j]  )
        );
    end
    endgenerate

    //===================================================
    //  Valid Read Data 
    //===================================================
    always_comb begin
        case (req)
            10'b0000000001: rdata_o = rdata[0];
            10'b0000000010: rdata_o = rdata[1];
            10'b0000000100: rdata_o = rdata[2];
            10'b0000001000: rdata_o = rdata[3];
            10'b0000010000: rdata_o = rdata[4];
            10'b0000100000: rdata_o = rdata[5];
            10'b0001000000: rdata_o = rdata[6];
            10'b0010000000: rdata_o = rdata[7];
            10'b0100000000: rdata_o = rdata[8];
            10'b1000000000: rdata_o = rdata[9];
            default:        rdata_o = 'hFF;
        endcase
    end

endmodule
