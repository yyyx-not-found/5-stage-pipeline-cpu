`include "cpu.v"

`timescale 1ns/1ps

module test_CPU();
    parameter T = 20;
    reg clock = 1'b0;
    reg [1:0] mode = RESET_MODE;
    reg [31:0] udaddr = 0;
    integer n_cycle = 0;
    wire [31:0] odata;
    wire [1:0] stat;
    integer file_out;

    localparam  // Define modes
        RUN_MODE = 0, // Normal operation
        RESET_MODE = 1, // Resetting processor;
        UPLOAD_MODE = 2, // Reading from memory
        STATUS_MODE = 3; // Uploading register & other status information

    localparam  // Status 
        STAT_ALLOK    = 2'b00,
        STAT_BUBBLE   = 2'b01,
        STAT_STALL    = 2'b10,
        STAT_STOP     = 2'b11;

    initial begin
        $dumpfile("test.vcd");
        $dumpvars;
    end

    initial begin
        file_out = $fopen("./data.bin","w");

        // initialize clock

        #(T/2)
        clock = ~clock;
        #(T/4)
        mode = RUN_MODE;
        #(T/4)
        clock = ~clock;
        while (stat != STAT_STOP) begin
            #(T/2)
            clock = ~clock;
            #(T/2)
            clock = ~clock;
            n_cycle = n_cycle + 1;
        end

        // dump memory
        #(T/2)
        mode = UPLOAD_MODE;
        clock = ~clock;
        $display("=========== Main Memory ===========");
        for (udaddr = 0; udaddr < 512; udaddr++) begin
            #(T/2)
            clock = ~clock;
            #1
            $display("%b", odata);
            $fwrite(file_out, "%b\n", odata);
            #(T/2 - 1)
            clock = ~clock;
        end

        /* DEBUG */
        #(T/2)
        mode = STATUS_MODE;
        clock = ~clock;
        $display("The execution take %3d clock cycles", n_cycle);
        $display("After execution, the register file:");
        for (udaddr = 0; udaddr < 128; udaddr += 4) begin
            #(T/2)
            clock = ~clock;
            $display("Register ID [%2d]: %b", udaddr / 4, odata);
        end

        #100 $stop;
    end

    CPU cpu(
        .mode(mode),
        .udaddr(udaddr),
        .odata(odata),
        .stat(stat),
        .clock(clock)
    );

endmodule
