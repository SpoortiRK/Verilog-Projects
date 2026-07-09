`timescale 1ns/1ps

module tb_rle_roundtrip;

    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    reg rst;

    reg        comp_in_valid;
    reg  [7:0] comp_in_byte;
    reg        comp_in_last;
    wire       comp_in_ready;
    wire       comp_out_valid;
    wire [7:0] comp_out_byte;
    wire       comp_done;

    reg        decomp_in_valid;
    reg  [7:0] decomp_in_byte;
    wire       decomp_in_ready;
    wire       decomp_out_valid;
    wire [7:0] decomp_out_byte;
    wire       decomp_done;

    rle_compress u_comp (
        .clk       (clk),
        .rst       (rst),
        .in_valid  (comp_in_valid),
        .in_byte   (comp_in_byte),
        .in_last   (comp_in_last),
        .in_ready  (comp_in_ready),
        .out_valid (comp_out_valid),
        .out_byte  (comp_out_byte),
        .done      (comp_done)
    );

    rle_decompress u_decomp (
        .clk       (clk),
        .rst       (rst),
        .in_valid  (decomp_in_valid),
        .in_byte   (decomp_in_byte),
        .in_ready  (decomp_in_ready),
        .out_valid (decomp_out_valid),
        .out_byte  (decomp_out_byte),
        .done      (decomp_done)
    );

    reg [7:0] compressed_mem [0:255];
    reg [7:0] original_mem   [0:255];
    reg [7:0] recovered_mem  [0:255];

    integer comp_count;
    integer saved_comp_len;
    integer orig_len;
    integer recv_len;
    integer i;
    integer errors;
    integer comp_fd;

    always @(posedge clk) begin
        if (comp_out_valid) begin
            compressed_mem[comp_count] = comp_out_byte;
            $display("[COMP OUT] %0d : %h", comp_count, comp_out_byte);
            comp_count = comp_count + 1;
        end
    end

    always @(posedge clk) begin
        if (decomp_out_valid) begin
            recovered_mem[recv_len] = decomp_out_byte;
            $display("[DECOMP OUT] %0d : %h", recv_len, decomp_out_byte);
            recv_len = recv_len + 1;
        end
    end

    // Drive a byte into the compressor and hold it until the compressor
    // is ready to accept it (in_ready=1). Proper valid/ready handshake
    // ensures no input byte is dropped while the compressor is busy
    // flushing FF/COUNT/DATA bytes.
    task send_to_compressor(input [7:0] data, input last);
        begin
            comp_in_valid <= 1'b1;
            comp_in_byte  <= data;
            comp_in_last  <= last;
            @(posedge clk);
            while (!comp_in_ready) @(posedge clk);
            comp_in_valid <= 1'b0;
            comp_in_last  <= 1'b0;
        end
    endtask

    task send_to_decompressor(input [7:0] data);
        begin
            decomp_in_valid <= 1'b1;
            decomp_in_byte  <= data;
            @(posedge clk);
            while (!decomp_in_ready) @(posedge clk);
            decomp_in_valid <= 1'b0;
        end
    endtask

    initial begin
        rst             = 1'b1;
        comp_in_valid   = 1'b0;
        comp_in_byte    = 8'h00;
        comp_in_last    = 1'b0;
        decomp_in_valid = 1'b0;
        decomp_in_byte  = 8'h00;
        comp_count      = 0;
        saved_comp_len  = 0;
        orig_len        = 9;
        recv_len        = 0;
        errors          = 0;

        // "AAAABBBCC"
        original_mem[0] = 8'h41;
        original_mem[1] = 8'h41;
        original_mem[2] = 8'h41;
        original_mem[3] = 8'h41;
        original_mem[4] = 8'h42;
        original_mem[5] = 8'h42;
        original_mem[6] = 8'h42;
        original_mem[7] = 8'h43;
        original_mem[8] = 8'h43;
	orig_len        = 10;
        recv_len        = 0;
        errors          = 0;

        // "AAAAAAAAAA" (10 A's)
        original_mem[0] = 8'h41;
        original_mem[1] = 8'h41;
        original_mem[2] = 8'h41;
        original_mem[3] = 8'h41;
        original_mem[4] = 8'h41;
        original_mem[5] = 8'h41;
        original_mem[6] = 8'h41;
        original_mem[7] = 8'h41;
        original_mem[8] = 8'h41;
        original_mem[9] = 8'h41;
	
	orig_len        = 8;
        recv_len        = 0;
        errors          = 0;

        // "AABBCCDD"
        original_mem[0] = 8'h41;  // A
        original_mem[1] = 8'h41;  // A
        original_mem[2] = 8'h42;  // B
        original_mem[3] = 8'h42;  // B
        original_mem[4] = 8'h43;  // C
        original_mem[5] = 8'h43;  // C
        original_mem[6] = 8'h44;  // D
        original_mem[7] = 8'h44;  // D

        repeat (3) @(posedge clk);
        rst = 1'b0;
        repeat (2) @(posedge clk);

        $display("=== COMPRESSION START ===");

        for (i = 0; i < orig_len; i = i + 1) begin
            if (i == orig_len - 1)
                send_to_compressor(original_mem[i], 1'b1);
            else
                send_to_compressor(original_mem[i], 1'b0);
        end

        wait (comp_done === 1'b1);
        repeat (3) @(posedge clk);

        saved_comp_len = comp_count;
        $display("=== COMPRESSION DONE (%0d bytes) ===", saved_comp_len);

        if (saved_comp_len !== 10) begin
            $display("ERROR: expected 8 compressed bytes, got %0d", saved_comp_len);
            errors = errors + 1;
        end

        if (compressed_mem[0] !== 8'hFF) begin
            $display("ERROR: byte 0 should be FF, got %h", compressed_mem[0]);
            errors = errors + 1;
        end

        if (compressed_mem[saved_comp_len-1] !== 8'hFE) begin
            $display("ERROR: last byte should be FE, got %h", compressed_mem[saved_comp_len-1]);
            errors = errors + 1;
        end

        // ---- Dump compressed bytes to a file for Python/MATLAB ----
        // One 2-digit hex byte per line, e.g.:
        //   ff
        //   04
        //   41
        //   ...
        comp_fd = $fopen("compressed_out.txt", "w");
        for (i = 0; i < saved_comp_len; i = i + 1)
            $fwrite(comp_fd, "%02h\n", compressed_mem[i]);
        $fclose(comp_fd);
        $display("=== compressed_out.txt written (%0d bytes) ===", saved_comp_len);

        // Reset before decompression
        rst = 1'b1;
        recv_len = 0;
        repeat (3) @(posedge clk);
        rst = 1'b0;
        repeat (2) @(posedge clk);

        $display("=== DECOMPRESSION START ===");

        for (i = 0; i < saved_comp_len; i = i + 1)
            send_to_decompressor(compressed_mem[i]);

        wait (decomp_done === 1'b1);
        repeat (3) @(posedge clk);

        $display("=== DECOMPRESSION DONE (%0d bytes) ===", recv_len);

        if (recv_len !== orig_len) begin
            $display("ERROR: length mismatch orig=%0d recv=%0d", orig_len, recv_len);
            errors = errors + 1;
        end

        for (i = 0; i < orig_len; i = i + 1) begin
            if (i >= recv_len || recovered_mem[i] !== original_mem[i]) begin
                $display("ERROR at %0d: expected %h got %h",
                         i, original_mem[i],
                         (i < recv_len) ? recovered_mem[i] : 8'hXX);
                errors = errors + 1;
            end
        end

        if (errors == 0)
            $display("=== TEST PASSED ===");
        else
            $display("=== TEST FAILED (%0d errors) ===", errors);

        #100;
        $finish;
    end

endmodule
