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

    localparam int BANK = int'( MEM_LATENCY / SYS_CLOCK );
    initial $display("BANK = %0d", DUT.BANK);

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

    //==========================================================
    //  Address Generator
    //==========================================================
    generate
    for (genvar l = 0; l < BANK; l++) begin
        always_ff @(posedge clk or negedge rstn) begin
            if (!rstn) begin
                addr[l]  <= '0;
                wdata[l] <= '0;
            end else if (first_req) begin
                addr[l]  <= ADDR_W'(l);
                wdata[l] <= '0;
            end
        end
    end
    endgenerate

    assign we = '0;  // só leitura por enquanto

    //==========================================================
    //                   MAQUINA DE ESTADOS 
    //              Atual e Proximo desacoplados
    //==========================================================
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) CS <= IDLE;
        else       CS <= NS;
    end

    always_comb begin
        case (CS)
            IDLE:     NS = (enb) ? SEND_REQ : IDLE;
            SEND_REQ: NS = (req[BANK-1])   ? GET_RESP : SEND_REQ;
            GET_RESP: NS = (valid[BANK-1]) ? SEND_REQ : GET_RESP;
            default:  NS = IDLE;
        endcase
    end

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

    //===================================================
    //  Requisition Shift Array
    //===================================================
    // generate
    // for (genvar i=1; i < BANK; i++) begin : req_gen
    //     always_ff @( posedge clk or negedge rstn ) begin
    //         if (!rstn)
    //             req[i] <= '0;
    //         else if (CS != IDLE) 
    //             req[i] <= req[i-1];
    //     end
    // end
    // endgenerate

    // always_ff @( posedge clk or negedge rstn ) begin
    //     if (!rstn)           
    //         req[0] <= '0;
    //     else if (CS != IDLE) 
    //         req[0] <= first_req;
    // end

    // Sempre desloca, carrega start_pulse na entrada
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) req <= '0;
        else       req <= {req[BANK-2:0], first_req};
    end

    //===================================================
    //  Memory Bank
    //===================================================
    generate
    for (genvar j=0; j<BANK; j++) begin : mem_gen
        memory_model #(
            .ADDR_W   ( ADDR_W      ),
            .DATA_W   ( DATA_W      ),
            .DEPTH    ( DEPTH       ),
            .LATENCY  ( MEM_LATENCY ),
            .V_TIME   ( V_TIME      )
        ) u_mem (
            .clk      ( clk         ),
            .req      ( req[j]      ),
            .we       ( we[j]       ),    
            .addr     ( addr[j]     ),
            .wdata    ( wdata[j]    ),
            .rdata    ( rdata[j]    ),
            .valid    ( valid[j]    ),
            .busy     ( busy[j]     )
        );
    end
    endgenerate

    // stub para isolar o problema
    // generate
    // for (genvar j=0; j<BANK; j++) begin : mem_gen
    //     assign valid[j] = req[j];
    //     assign busy[j]  = 1'b0;
    //     assign rdata[j] = 32'hDEAD_0000 + j;
    // end
    // endgenerate

    //===================================================
    //  Valid Read Data 
    //===================================================
    always_comb begin
        case (valid)
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
            default:        rdata_o = '1;
        endcase
    end

endmodule
