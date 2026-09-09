`timescale 1ns/1ps

module tb_password_lock_system;

    parameter PW0 = 4'd1;
    parameter PW1 = 4'd2;
    parameter PW2 = 4'd3;
    parameter PW3 = 4'd4;
    parameter MAX_ATTEMPTS = 3;
    parameter ERROR_TICKS  = 1;

    reg clk, rst;
    reg digit_valid;
    reg [3:0] digit;
    reg enter, clear, lock_cmd;

    wire unlocked, alarm, error;
    wire [2:0] state_dbg;
    integer pass_count;
    integer fail_count;
    password_lock_system #(
        .PW0(PW0), .PW1(PW1), .PW2(PW2), .PW3(PW3),
        .MAX_ATTEMPTS(MAX_ATTEMPTS), .ERROR_TICKS(ERROR_TICKS)
    ) dut (
        .clk(clk), .rst(rst),
        .digit_valid(digit_valid), .digit(digit),
        .enter(enter), .clear(clear), .lock_cmd(lock_cmd),
        .unlocked(unlocked), .alarm(alarm), .error(error),
        .state_dbg(state_dbg)
    );

    always #5 clk = ~clk;
    task check;
        input [40*8-1:0] name;
        input actual;
        input expected;
        begin
            if (actual === expected) begin
                pass_count = pass_count + 1;
                $display("PASS: %-45s exp=%b got=%b", name, expected, actual);
            end else begin
                fail_count = fail_count + 1;
                $display("FAIL: %-45s exp=%b got=%b", name, expected, actual);
            end
        end
    endtask

    task check3;
        input [40*8-1:0] name;
        input [2:0] actual;
        input [2:0] expected;
        begin
            if (actual === expected) begin
                pass_count = pass_count + 1;
                $display("PASS: %-45s exp=%b got=%b", name, expected, actual);
            end else begin
                fail_count = fail_count + 1;
                $display("FAIL: %-45s exp=%b got=%b", name, expected, actual);
            end
        end
    endtask

    task send_digit;
        input [3:0] d;
        begin
            @(negedge clk);
            digit_valid = 1;
            digit       = d;
            @(negedge clk);
            digit_valid = 0;
            digit       = 4'h0;
        end
    endtask

    task send_enter;
        begin
            @(negedge clk);
            enter = 1;
            @(negedge clk);
            enter = 0;
        end
    endtask

    task do_reset;
        begin
            rst = 1;
            digit_valid = 0;
            digit  = 0;
            enter  = 0;
            clear  = 0;
            lock_cmd = 0;
            @(negedge clk);
            @(negedge clk);
            rst = 0;
        end
    endtask

    task enter_password;
        input [3:0] p0, p1, p2, p3;
        begin
            send_digit(p0);
            send_digit(p1);
            send_digit(p2);
            send_digit(p3);
        end
    endtask
    initial begin
        pass_count = 0;
        fail_count = 0;

        $dumpfile("wave_password_lock_system.vcd");
        $dumpvars(0, tb_password_lock_system);

        clk = 0;
        do_reset();
        check3("Reset: state == S_LOCKED",   state_dbg, 3'b000);
        check ("Reset: unlocked == 0",       unlocked, 1'b0);
        check ("Reset: alarm == 0",          alarm,    1'b0);
        check ("Reset: error == 0",          error,    1'b0);

        enter_password(PW0, PW1, PW2, PW3);
        check3("Correct seq: state == S_WAIT_ENTER", state_dbg, 3'b100);

        send_enter();
        check("Correct seq + enter: unlocked == 1", unlocked, 1'b1);
        check("Correct seq + enter: alarm == 0",    alarm,    1'b0);

        @(negedge clk);
        lock_cmd = 1;
        @(negedge clk);
        lock_cmd = 0;
        check ("lock_cmd: unlocked == 0",     unlocked, 1'b0);
        check3("lock_cmd: state == S_LOCKED", state_dbg, 3'b000);

        send_digit(PW0);                 
        send_enter();                   
        check("Early enter: error == 1", error, 1'b1);

        repeat (ERROR_TICKS+1) @(negedge clk);
        check3("Early enter: timeout -> S_LOCKED", state_dbg, 3'b000);
        check ("Early enter: alarm == 0 (1 attempt)", alarm, 1'b0);

      
        send_digit(4'hF);                
        repeat (ERROR_TICKS+1) @(negedge clk);
        check3("Wrong attempt 2: back to S_LOCKED", state_dbg, 3'b000);
        check ("Wrong attempt 2: alarm == 0",       alarm, 1'b0);

        send_digit(4'hF);                
        repeat (ERROR_TICKS+1) @(negedge clk);
        check("Wrong attempt 3: alarm == 1", alarm, 1'b1);
        @(negedge clk);
        clear = 1;
        @(negedge clk);
        clear = 0;
        check ("clear: alarm == 0",        alarm, 1'b0);
        check3("clear: state == S_LOCKED", state_dbg, 3'b000);

        if (fail_count == 0)
            $display("SUMMARY: password_lock_system PASS (%0d checks)", pass_count);
        else
            $display("SUMMARY: password_lock_system FAIL (%0d passed, %0d failed)",
                       pass_count, fail_count);

        $finish;
    end

endmodule
