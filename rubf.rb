class Compiler
    def initialize
        @string_constants = {}
        @loopcount = 4 #4 functions, to be inc'd every new loop
    end

    def get_arg(a)
        seq = @string_constants[a]
        return seq if seq 
        seq = @seq
        @seq += 1
        @string_constants[a] = seq
        return seq
    end

    def output_constants
        puts "\t.section\t.rodata"
        @string_constants.each do |c,seq|
            puts ".LC#{seq}:"
            puts "\t.string \"#{c}\""
        end
    end
    
    PTR_SIZE=4
    def compile_exp(exp)
        exp.each_with_index do |a,i|
            if exp[i] == "["                #this will break on files with nested loops
                @loopcount += 2
                puts <<STARTLOOP
        jmp\t.L#{@loopcount}
   .L#{@loopcount+1}:
STARTLOOP

            elsif exp[i] == "]"
                puts <<ENDLOOP
    .L#{@loopcount}:
        movl\t$0, %eax
        call\tgetVal
        testl\t%eax, %eax
        jg\t.L#{@loopcount+1}
ENDLOOP
            elsif exp[i] == "+"
                puts <<ADDONE
        movl\t$0, %eax
        call\tgetVal
        addl\t$1, %eax
        movl\t%eax, %edi
        call\tsetVal
ADDONE

            elsif exp[i] == "-"
                puts <<SUBONE
        movl\t$0, %eax
        call\tgetVal
        subl\t$1, %eax
        movl\t%eax, %edi
        call\tsetVal

SUBONE
            elsif exp[i] == ">"
                puts <<MOVERIGHT
        movl\t$0, %eax
        call\tmoveRight

MOVERIGHT
            elsif exp[i] == "<"
                puts <<MOVELEFT
        movl\t$0, %eax
        call\tmoveLeft
MOVELEFT
            elsif exp[i] == "."
                puts <<PRINT
        movl\t$0, %eax
        call\tgetVal
        movl\t%eax, %edi
        call\tputchar
PRINT
            elsif exp[i] == ","
                puts <<INPUT
        movl\t$.LC0, %eax
        movl\t$c, %esi
        movq\t%rax, %rdi
        movl\t$0, %eax
        call\t__isoc99_scanf
        movzbl\tc(%rip), %eax
        movsbl\t%al, %eax
        movl\t%eax, i(%rip)
        movl\ti(%rip), %eax
        movl\t%eax, %edi
        call\tsetVal
INPUT
            end
        end
=begin
        call = exp[0].to_s
        args = exp[1..-1].collect {|a| get_arg(a)}

        stack_adjustment = PTR_SIZE + (((args.length+0.5)*PTR_SIZE/(4.0*PTR_SIZE)).round) * (4 * PTR_SIZE)
        #puts "\tsubl\t$#{stack_adjustment},%esp"
        

        args.each_with_index do |a,i|
            puts "\tmovl\t$.LC#{a},#{i>0 ? i*PTR_SIZE : ""} %eax"
        end

        puts "\tmovq\t%rax, %rdi"

        puts "\tmovl\t$0,%eax"

        puts "\tcall\t#{call}"
        #puts "\taddl\t$#{stack_adjustment}, %esp"
=end

    end

    def compile(exp)
	puts <<PROLOG
	.comm	tape,28,16
	.globl	pos
	.bss
	.align 4
	.type	pos, @object
	.size	pos, 4
pos:
	.zero	4
    .comm   c,100,32
    .comm   i,4,4
	.text
	.globl	getVal
	.type	getVal, @function
getVal:
.LFB0:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movl	pos(%rip), %eax
	cltq
	movl	tape(,%rax,4), %eax
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE0:
	.size	getVal, .-getVal
	.globl	setVal
	.type	setVal, @function
setVal:
.LFB1:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movl	%edi, -4(%rbp)
	movl	pos(%rip), %eax
	cltq
	movl	-4(%rbp), %edx
	movl	%edx, tape(,%rax,4)
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE1:
	.size	setVal, .-setVal
	.globl	moveRight
	.type	moveRight, @function
moveRight:
.LFB2:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movl	pos(%rip), %eax
	addl	$1, %eax
	movl	%eax, pos(%rip)
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE2:
	.size	moveRight, .-moveRight
	.globl	moveLeft
	.type	moveLeft, @function
moveLeft:
.LFB3:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movl	pos(%rip), %eax
	subl	$1, %eax
	movl	%eax, pos(%rip)
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE3:
	.size	moveLeft, .-moveLeft
	.globl	main
	.type	main, @function
.LC0:
    .string "%s"
    .text
    .globl  main
    .type   main, @function
main:
.LFB4:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
PROLOG

    compile_exp(exp)

    puts <<EPILOG
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE4:
	.size	main, .-main
	.ident	"GCC: (Ubuntu/Linaro 4.6.3-1ubuntu5) 4.6.3"
	.section	.note.GNU-stack,"",@progbits
EPILOG


    output_constants
  end
end

ARGV.each do|a|
    prog = ""
    file = File.open(a,"r") do |infile|
        while line = infile.gets
            prog << line
        end

        proglist = prog.split(//).select{|x| '+-<>[].,'.include?(x)}
        Compiler.new.compile(proglist)
    end
end
    


#prog = ["+","+","+","+","+","+","+","+","+","[",">","+","+","+","+","+","+","+","+","<","-","]",">","."]

