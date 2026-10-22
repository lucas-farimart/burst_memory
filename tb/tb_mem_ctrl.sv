//================================================================
// TESTBENCH: Controlador de memoria & Gerador de burst
//----------------------------------------------------------------
// Autor: Lucas Farias Martins
// Email: lucas.martins@ee.ufcg.edu.br
// Data:  15-10-2026
//================================================================

module tb_memory_ctrl;

    parameter int  ADDR_W = 9;
    parameter int  DATA_W = 32;
    parameter int  DEPTH  = 512;

    parameter time SYS_CLOCK   = 2ns;
    parameter time MEM_LATENCY = 10ns;
    parameter time V_TIME      = 2ns;
    parameter time TIME_OUT    = 1us;

    logic              clk;
    logic              rstn;
    logic              enb_i;
    logic [3:0]        size_i;
    logic [DATA_W-1:0] rdata_o;
    logic              valid_o;

    //====================================================
    //  DUT instance
    //====================================================
    memory_ctrl #(
        .ADDR_W      ( ADDR_W      ),
        .DATA_W      ( DATA_W      ),
        .DEPTH       ( DEPTH       ),
        .SYS_CLOCK   ( SYS_CLOCK   ),
        .MEM_LATENCY ( MEM_LATENCY ),
        .V_TIME      ( V_TIME      )
    ) DUT (
        .clk         ( clk         ),
        .rstn        ( rstn        ),
        .enb_i       ( enb_i       ),
        .size_i      ( size_i      ),
        .valid_o     ( valid_o     ),
        .rdata_o     ( rdata_o     )
    );

    //====================================================
    //  Effective Test
    //====================================================
    initial begin

        $display("\n");
        $display("===========================================================");
        $display("          ___             _     _____       _              ");
        $display("         | _ )_  _ _ _ __| |_  |_   _|__ __| |_            ");
        $display("         | _ \\ || | '_(_-<  _|   | |/ -_|_-<  _|          ");
        $display("         |___/\\_,_|_| /__/\\__|   |_|\\___/__/\\__|       ");
        $display("===========================================================");
        $display("\n");
                                        
        repeat(2) @(negedge clk); 
        rstn = 1;

        repeat(5) @(negedge clk); 
        enb_i  = 1;
        size_i = 2; // <---- mudar aqui pra ver

        repeat(1) @(negedge clk); 
        enb_i = 0;

    end

    //====================================================
    //  Clock/Reset Generation 
    //====================================================
    initial begin 
        clk    = 0;
        rstn   = 0;
        enb_i  = 0;
        size_i = 0;
    end

    always #(SYS_CLOCK/2) clk = ~clk;

    initial begin
        #(TIME_OUT) $finish(1);
    end

    // initial begin
    //     $monitor("t=%0t clk=%b rstn=%b enb_i=%b rdata_o=%h", $time, clk, rstn, enb_i, rdata_o);
    // end

endmodule