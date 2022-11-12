OUTPUT_ARCH( "riscv" )

ENTRY( _start )

MEMORY
{
  itcm (rxai!w) : ORIGIN = 0x80000000, LENGTH = 64K
  ram (wxa!ri) : ORIGIN = 0x90000000, LENGTH = 64K
}


SECTIONS
{
  .text           :
  {
    *(.text .text.*)
    *(.gnu.linkonce.t.*)
  } >itcm AT>itcm 
}
