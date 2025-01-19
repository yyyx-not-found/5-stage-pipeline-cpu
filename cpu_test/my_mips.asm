.text
# To test the combination of load/use hazard and the control hazard (jr)

addi $v0, $zero, 20
sw $v0, $zero(0)
addi $ra, $zero, 16
lw $ra, $zero(0)
jr $ra

