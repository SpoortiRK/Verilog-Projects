`timescale 1ns/1ps

module tb_rle_multitest;

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
    integer total_errors;
    integer comp_fd;
    integer test_num;
    integer NUM_TESTS;

    // ---- Test case definitions ----
    reg [7:0] test_data [0:63];   // up to 64 bytes total across all tests
    integer   test_len  [0:7];    // length of each test case (up to 8 tests)
    integer   test_start[0:7];    // starting index of each test case in test_data

    always @(posedge clk) begin
        if (comp_out_valid) begin
            compressed_mem[comp_count] = comp_out_byte;
            comp_count = comp_count + 1;
        end
    end

    always @(posedge clk) begin
        if (decomp_out_valid) begin
            recovered_mem[recv_len] = decomp_out_byte;
            recv_len = recv_len + 1;
        end
    end

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

    task run_one_test(input integer t_idx);
        integer k;
        real cr;
        begin
            orig_len = test_len[t_idx];

            // load this test's bytes into original_mem
            for (k = 0; k < orig_len; k = k + 1)
                original_mem[k] = test_data[test_start[t_idx] + k];

            // ---- reset before compression ----
            rst = 1'b1;
            comp_count = 0;
            recv_len   = 0;
            errors     = 0;
            repeat (3) @(posedge clk);
            rst = 1'b0;
            repeat (2) @(posedge clk);

            $display("");
            $display("================================================");
            $display("TEST %0d : %0d input bytes", t_idx, orig_len);
            $display("================================================");

            // ---- compression ----
            for (k = 0; k < orig_len; k = k + 1) begin
                if (k == orig_len - 1)
                    send_to_compressor(original_mem[k], 1'b1);
                else
                    send_to_compressor(original_mem[k], 1'b0);
            end

            wait (comp_done === 1'b1);
            repeat (3) @(posedge clk);

            saved_comp_len = comp_count;
            cr = orig_len / $itor(saved_comp_len);

            $display("Original bytes   : %0d", orig_len);
            $display("Compressed bytes : %0d", saved_comp_len);
            $display("Compression Ratio: %0.3f", cr);
            $write("Compressed stream : ");
            for (k = 0; k < saved_comp_len; k = k + 1)
                $write("%02h ", compressed_mem[k]);
            $display("");

            if (compressed_mem[0] !== 8'hFF) begin
                $display("ERROR: byte 0 should be FF, got %h", compressed_mem[0]);
                errors = errors + 1;
            end
            if (compressed_mem[saved_comp_len-1] !== 8'hFE) begin
                $display("ERROR: last byte should be FE, got %h", compressed_mem[saved_comp_len-1]);
                errors = errors + 1;
            end

            // ---- dump this test's compressed bytes to its own file ----
            comp_fd = $fopen($sformatf("compressed_test%0d.txt", t_idx), "w");
            for (k = 0; k < saved_comp_len; k = k + 1)
                $fwrite(comp_fd, "%02h\n", compressed_mem[k]);
            $fclose(comp_fd);

            // ---- reset before decompression ----
            rst = 1'b1;
            recv_len = 0;
            repeat (3) @(posedge clk);
            rst = 1'b0;
            repeat (2) @(posedge clk);

            // ---- decompression ----
            for (k = 0; k < saved_comp_len; k = k + 1)
                send_to_decompressor(compressed_mem[k]);

            wait (decomp_done === 1'b1);
            repeat (3) @(posedge clk);

            $display("Recovered bytes  : %0d", recv_len);

            if (recv_len !== orig_len) begin
                $display("ERROR: length mismatch orig=%0d recv=%0d", orig_len, recv_len);
                errors = errors + 1;
            end

            for (k = 0; k < orig_len; k = k + 1) begin
                if (k >= recv_len || recovered_mem[k] !== original_mem[k]) begin
                    $display("ERROR at byte %0d: expected %h got %h",
                             k, original_mem[k],
                             (k < recv_len) ? recovered_mem[k] : 8'hXX);
                    errors = errors + 1;
                end
            end

            if (errors == 0) begin
                $display("RESULT: TEST %0d PASSED  (CR = %0.3f)", t_idx, cr);
            end else begin
                $display("RESULT: TEST %0d FAILED (%0d errors)", t_idx, errors);
            end

            total_errors = total_errors + errors;
        end
    endtask

    initial begin
        comp_in_valid   = 1'b0;
        comp_in_byte    = 8'h00;
        comp_in_last    = 1'b0;
        decomp_in_valid = 1'b0;
        decomp_in_byte  = 8'h00;
        total_errors    = 0;
        NUM_TESTS       = 4;

        // ===========================================================
        // Define all test cases here.
        // Edit this section to add / change test inputs.
        // ===========================================================

        // ---- Test 0: "AAAABBBCC" (9 bytes) ----
        test_start[0] = 0;
        test_len[0]   = 9;
        test_data[0]  = 8'h41; // A
        test_data[1]  = 8'h41; // A
        test_data[2]  = 8'h41; // A
        test_data[3]  = 8'h41; // A
        test_data[4]  = 8'h42; // B
        test_data[5]  = 8'h42; // B
        test_data[6]  = 8'h42; // B
        test_data[7]  = 8'h43; // C
        test_data[8]  = 8'h43; // C

        // ---- Test 1: "AAAAAAAAAA" (10 bytes, all same) ----
        test_start[1] = 9;
        test_len[1]   = 10;
        test_data[9]  = 8'h41;
        test_data[10] = 8'h41;
        test_data[11] = 8'h41;
        test_data[12] = 8'h41;
        test_data[13] = 8'h41;
        test_data[14] = 8'h41;
        test_data[15] = 8'h41;
        test_data[16] = 8'h41;
        test_data[17] = 8'h41;
        test_data[18] = 8'h41;

        // ---- Test 2: "AABBCCDD" (8 bytes, low repetition) ----
        test_start[2] = 19;
        test_len[2]   = 8;
        test_data[19] = 8'h41; // A
        test_data[20] = 8'h41; // A
        test_data[21] = 8'h42; // B
        test_data[22] = 8'h42; // B
        test_data[23] = 8'h43; // C
        test_data[24] = 8'h43; // C
        test_data[25] = 8'h44; // D
        test_data[26] = 8'h44; // D

        // ---- Test 3: "AAAAAAAAAAAAAAAA" (16 bytes, all same) ----
        test_start[3] = 27;
        test_len[3]   = 16;
        for (i = 0; i < 16; i = i + 1)
            test_data[27 + i] = 8'h41;

        // ===========================================================
        // Run every test case automatically
        // ===========================================================
        for (test_num = 0; test_num < NUM_TESTS; test_num = test_num + 1)
            run_one_test(test_num);

        $display("");
        $display("================================================");
        if (total_errors == 0)
            $display("ALL %0d TESTS PASSED", NUM_TESTS);
        else
            $display("SOME TESTS FAILED (%0d total errors)", total_errors);
        $display("================================================");

        #100;
        $finish;
    end

endmodule
