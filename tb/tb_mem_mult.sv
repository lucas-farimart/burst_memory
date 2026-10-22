//================================================================
// TESTBENCH: Controlador de memoria & Gerador de burst
//----------------------------------------------------------------
// Autor: Lucas Farias Martins
// Email: lucas.martins@ee.ufcg.edu.br
// Data:  15-10-2026
//================================================================

module tb_memory_mult;

    parameter int  SIZE_A = 5;
    parameter int  SIZE_B = 5;
    parameter int  ADDR_W = 9;
    parameter int  DATA_W = 8;
    parameter int  DEPTH  = 512;

    parameter time SYS_CLOCK   = 2ns;
    parameter time MEM_LATENCY = 10ns;
    parameter time V_TIME      = 2ns;
    parameter time TIME_OUT    = 1us;

    logic clk, rstn;

    logic               enb_a,   enb_b;
    logic [3:0]         size_a,  size_b;
    logic [DATA_W-1:0]  rdata_a, rdata_b;
    logic               valid_a, valid_b;

    logic               mult_vld_i;
    logic               mult_vld_o;
    logic signed [15:0] mult_o;

    //====================================================
    //                  DUT instances
    //====================================================
    memory_ctrl #(
        .ADDR_W      ( ADDR_W      ),
        .DATA_W      ( DATA_W      ),
        .DEPTH       ( DEPTH       ),
        .SYS_CLOCK   ( SYS_CLOCK   ),
        .MEM_LATENCY ( MEM_LATENCY ),
        .V_TIME      ( V_TIME      )
    ) mem_ctrl_a (
        .clk         ( clk         ),
        .rstn        ( rstn        ),
        .enb_i       ( enb_a       ),
        .size_i      ( size_a      ),
        .valid_o     ( valid_a     ),
        .rdata_o     ( rdata_a     )
    );

    memory_ctrl #(
        .ADDR_W      ( ADDR_W      ),
        .DATA_W      ( DATA_W      ),
        .DEPTH       ( DEPTH       ),
        .SYS_CLOCK   ( SYS_CLOCK   ),
        .MEM_LATENCY ( MEM_LATENCY ),
        .V_TIME      ( V_TIME      )
    ) mem_ctrl_b (
        .clk         ( clk         ),
        .rstn        ( rstn        ),
        .enb_i       ( enb_b       ),
        .size_i      ( size_b      ),
        .valid_o     ( valid_b     ),
        .rdata_o     ( rdata_b     )
    );

    assign mult_vld_i = valid_a && valid_b;

    booth_radix4 u_booth (
        .clk         ( clk        ),
        .rst_n       ( rstn       ),
        .valid_in    ( mult_vld_i ),
        .valid_out   ( mult_vld_o ),
        .a           ( rdata_a    ),
        .b           ( rdata_b    ),
        .p           ( mult_o     )
    );

    //====================================================
    //  Effective Test
    //====================================================
    initial begin

        $display("\n");
        $display("===========================================================");
        $display("      ___             _       _     __  __      _ _        ");
        $display("     | _ )_  _ _ _ __| |_   _| |_  |  \\/  |_  _| | |_     ");
        $display("     | _ \\ || | '_(_-<  _| |_   _| | |\\/| | || | |  _|   ");
        $display("     |___/\\_,_|_| /__/\\__|   |_|   |_|  |_|\\_,_|_|\\__| ");
        $display("===========================================================");
        $display("\n");
                                                  
        repeat(2) @(negedge clk); 
        rstn = 1;

        repeat(5) @(negedge clk); 
        enb_a = 1;
        enb_b = 1;

        repeat(1) @(negedge clk); 
        enb_a = 0;
        enb_b = 0;

    end

    //====================================================
    //  Clock/Reset Generation 
    //====================================================
    initial begin 
        clk  = 0;
        rstn = 0;
        enb_a = 0; size_a = SIZE_A-1;
        enb_b = 0; size_b = SIZE_B-1;
    end

    always #(SYS_CLOCK/2) clk = ~clk;

    initial begin
        #(TIME_OUT) $finish(1);
    end

    // initial begin
    //     $monitor("t=%0t clk=%b rstn=%b enb_i=%b rdata_o=%h", $time, clk, rstn, enb_i, rdata_o);
    // end

endmodule