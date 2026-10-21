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
    parameter time SYS_CLOCK   = 2ns,
    parameter time MEM_LATENCY = 20ns,
    parameter time V_TIME      = 2ns
)(
    input  logic              clk,
    input  logic              rstn,
    input  logic              enb_i,
    input  logic [3:0]        size_i,
    output logic              valid_o,
    output logic [DATA_W-1:0] rdata_o
);

    localparam int BANK = int'( MEM_LATENCY / SYS_CLOCK );
    initial $display("\nBANK = %0d", DUT.BANK);

    //==========================================================
    //  Internos
    //==========================================================
    typedef enum logic [1:0] {IDLE_REQ, SEND_REQ, WAIT_REQ} state_req;
    typedef enum logic [1:0] {IDLE_RSP, GET_RSP,  WAIT_RSP} state_rsp;

    state_req  CS_REQ, NS_REQ; 
    state_rsp  CS_RSP, NS_RSP; 
    logic      next_is_send;
    logic      curr_is_idle;
    logic      curr_is_wait;

    logic [BANK-1:0]   req;
    logic [BANK-1:0]   we;
    logic [BANK-1:0]   valid;
    logic [BANK-1:0]   busy;
    
    // logic [ADDR_W-1:0] addr  [BANK];
    logic [ADDR_W-1:0] addr;
    logic [DATA_W-1:0] wdata [BANK];
    logic [DATA_W-1:0] rdata [BANK];

    //==========================================================
    //  Write Data Assignment
    //==========================================================
    generate
    for (genvar l = 0; l < BANK; l++) begin
        always_ff @(posedge clk or negedge rstn) begin : wdata_gen
            if (!rstn)           wdata[l] <= '0;
            else if(req[size_i]) wdata[l] <= '0;
        end
    end
    endgenerate

    assign we = '0;  // só leitura por enquanto

    //==========================================================
    //  Address Generator
    //==========================================================
    always_ff @(posedge clk or negedge rstn) begin : addr_gen
        if (!rstn)           addr <= '0;
        else if(req[size_i]) addr <= addr + 1;
    end

    //==========================================================
    //  Maquina de estados para requisicao (req) 
    //==========================================================
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) CS_REQ <= IDLE_REQ;
        else       CS_REQ <= NS_REQ;
    end

    always_comb begin
        case (CS_REQ)
            IDLE_REQ: NS_REQ = (enb_i) ? SEND_REQ : IDLE_REQ;
            SEND_REQ: NS_REQ = (req[size_i]) ? WAIT_REQ : SEND_REQ;
            WAIT_REQ: NS_REQ = (valid[0])  ? SEND_REQ : WAIT_REQ;
            default:  NS_REQ = IDLE_REQ;
        endcase
    end

    always_comb next_is_send = (NS_REQ==SEND_REQ);
    always_comb curr_is_wait = (CS_REQ==WAIT_REQ);
    always_comb curr_is_idle = (CS_REQ==IDLE_REQ);

    //==========================================================
    //  Maquina de estados para resposta (rsp) 
    //==========================================================
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) CS_RSP <= IDLE_RSP;
        else       CS_RSP <= NS_RSP;
    end

    always_comb begin
        case (CS_RSP)
            IDLE_RSP: NS_RSP = (enb_i) ? WAIT_RSP : IDLE_RSP;
            WAIT_RSP: NS_RSP = (req[size_i])   ? GET_RSP : WAIT_RSP;
            GET_RSP:  NS_RSP = (valid[size_i]) ? WAIT_RSP : GET_RSP;
            default:  NS_RSP = IDLE_RSP;
        endcase
    end  

    //===================================================
    //  Requisition Shift Array
    //===================================================
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) 
            req[BANK-1:1] <= '0;
        else begin 
            if (NS_REQ==SEND_REQ) 
                req[BANK-1:1] <= {req[BANK-2:1], req[0]};
            else
                req[BANK-1:1] <= '0;
        end
    end

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) 
            req[0] <= 0;
        else begin 
            if ((enb_i && curr_is_idle) || (next_is_send && curr_is_wait))
                req[0] <= 1;
            else
                req[0] <= 0;
        end
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
            .addr     ( addr        ),
            .wdata    ( wdata[j]    ),
            .rdata    ( rdata[j]    ),
            .valid    ( valid[j]    ),
            .busy     ( busy[j]     )
        );
    end
    endgenerate

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

    always_comb valid_o = |valid; // qualquer valid vale

endmodule
