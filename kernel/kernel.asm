
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	91013103          	ld	sp,-1776(sp) # 80008910 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	ff070713          	addi	a4,a4,-16 # 80009040 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	fee78793          	addi	a5,a5,-18 # 80006050 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dc678793          	addi	a5,a5,-570 # 80000e72 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	468080e7          	jalr	1128(ra) # 80002592 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	77e080e7          	jalr	1918(ra) # 800008b8 <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	ff650513          	addi	a0,a0,-10 # 80011180 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a3e080e7          	jalr	-1474(ra) # 80000bd0 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	fe648493          	addi	s1,s1,-26 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	07690913          	addi	s2,s2,118 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305863          	blez	s3,80000220 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71463          	bne	a4,a5,800001e4 <consoleread+0x80>
      if(myproc()->killed){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7d6080e7          	jalr	2006(ra) # 80001996 <myproc>
    800001c8:	551c                	lw	a5,40(a0)
    800001ca:	e7b5                	bnez	a5,80000236 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001cc:	85a6                	mv	a1,s1
    800001ce:	854a                	mv	a0,s2
    800001d0:	00002097          	auipc	ra,0x2
    800001d4:	f72080e7          	jalr	-142(ra) # 80002142 <sleep>
    while(cons.r == cons.w){
    800001d8:	0984a783          	lw	a5,152(s1)
    800001dc:	09c4a703          	lw	a4,156(s1)
    800001e0:	fef700e3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e4:	0017871b          	addiw	a4,a5,1
    800001e8:	08e4ac23          	sw	a4,152(s1)
    800001ec:	07f7f713          	andi	a4,a5,127
    800001f0:	9726                	add	a4,a4,s1
    800001f2:	01874703          	lbu	a4,24(a4)
    800001f6:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800001fa:	077d0563          	beq	s10,s7,80000264 <consoleread+0x100>
    cbuf = c;
    800001fe:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000202:	4685                	li	a3,1
    80000204:	f9f40613          	addi	a2,s0,-97
    80000208:	85d2                	mv	a1,s4
    8000020a:	8556                	mv	a0,s5
    8000020c:	00002097          	auipc	ra,0x2
    80000210:	330080e7          	jalr	816(ra) # 8000253c <either_copyout>
    80000214:	01850663          	beq	a0,s8,80000220 <consoleread+0xbc>
    dst++;
    80000218:	0a05                	addi	s4,s4,1
    --n;
    8000021a:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    8000021c:	f99d1ae3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000220:	00011517          	auipc	a0,0x11
    80000224:	f6050513          	addi	a0,a0,-160 # 80011180 <cons>
    80000228:	00001097          	auipc	ra,0x1
    8000022c:	a5c080e7          	jalr	-1444(ra) # 80000c84 <release>

  return target - n;
    80000230:	413b053b          	subw	a0,s6,s3
    80000234:	a811                	j	80000248 <consoleread+0xe4>
        release(&cons.lock);
    80000236:	00011517          	auipc	a0,0x11
    8000023a:	f4a50513          	addi	a0,a0,-182 # 80011180 <cons>
    8000023e:	00001097          	auipc	ra,0x1
    80000242:	a46080e7          	jalr	-1466(ra) # 80000c84 <release>
        return -1;
    80000246:	557d                	li	a0,-1
}
    80000248:	70a6                	ld	ra,104(sp)
    8000024a:	7406                	ld	s0,96(sp)
    8000024c:	64e6                	ld	s1,88(sp)
    8000024e:	6946                	ld	s2,80(sp)
    80000250:	69a6                	ld	s3,72(sp)
    80000252:	6a06                	ld	s4,64(sp)
    80000254:	7ae2                	ld	s5,56(sp)
    80000256:	7b42                	ld	s6,48(sp)
    80000258:	7ba2                	ld	s7,40(sp)
    8000025a:	7c02                	ld	s8,32(sp)
    8000025c:	6ce2                	ld	s9,24(sp)
    8000025e:	6d42                	ld	s10,16(sp)
    80000260:	6165                	addi	sp,sp,112
    80000262:	8082                	ret
      if(n < target){
    80000264:	0009871b          	sext.w	a4,s3
    80000268:	fb677ce3          	bgeu	a4,s6,80000220 <consoleread+0xbc>
        cons.r--;
    8000026c:	00011717          	auipc	a4,0x11
    80000270:	faf72623          	sw	a5,-84(a4) # 80011218 <cons+0x98>
    80000274:	b775                	j	80000220 <consoleread+0xbc>

0000000080000276 <consputc>:
{
    80000276:	1141                	addi	sp,sp,-16
    80000278:	e406                	sd	ra,8(sp)
    8000027a:	e022                	sd	s0,0(sp)
    8000027c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000027e:	10000793          	li	a5,256
    80000282:	00f50a63          	beq	a0,a5,80000296 <consputc+0x20>
    uartputc_sync(c);
    80000286:	00000097          	auipc	ra,0x0
    8000028a:	560080e7          	jalr	1376(ra) # 800007e6 <uartputc_sync>
}
    8000028e:	60a2                	ld	ra,8(sp)
    80000290:	6402                	ld	s0,0(sp)
    80000292:	0141                	addi	sp,sp,16
    80000294:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000296:	4521                	li	a0,8
    80000298:	00000097          	auipc	ra,0x0
    8000029c:	54e080e7          	jalr	1358(ra) # 800007e6 <uartputc_sync>
    800002a0:	02000513          	li	a0,32
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	542080e7          	jalr	1346(ra) # 800007e6 <uartputc_sync>
    800002ac:	4521                	li	a0,8
    800002ae:	00000097          	auipc	ra,0x0
    800002b2:	538080e7          	jalr	1336(ra) # 800007e6 <uartputc_sync>
    800002b6:	bfe1                	j	8000028e <consputc+0x18>

00000000800002b8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002b8:	1101                	addi	sp,sp,-32
    800002ba:	ec06                	sd	ra,24(sp)
    800002bc:	e822                	sd	s0,16(sp)
    800002be:	e426                	sd	s1,8(sp)
    800002c0:	e04a                	sd	s2,0(sp)
    800002c2:	1000                	addi	s0,sp,32
    800002c4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002c6:	00011517          	auipc	a0,0x11
    800002ca:	eba50513          	addi	a0,a0,-326 # 80011180 <cons>
    800002ce:	00001097          	auipc	ra,0x1
    800002d2:	902080e7          	jalr	-1790(ra) # 80000bd0 <acquire>

  switch(c){
    800002d6:	47d5                	li	a5,21
    800002d8:	0af48663          	beq	s1,a5,80000384 <consoleintr+0xcc>
    800002dc:	0297ca63          	blt	a5,s1,80000310 <consoleintr+0x58>
    800002e0:	47a1                	li	a5,8
    800002e2:	0ef48763          	beq	s1,a5,800003d0 <consoleintr+0x118>
    800002e6:	47c1                	li	a5,16
    800002e8:	10f49a63          	bne	s1,a5,800003fc <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002ec:	00002097          	auipc	ra,0x2
    800002f0:	2fc080e7          	jalr	764(ra) # 800025e8 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f4:	00011517          	auipc	a0,0x11
    800002f8:	e8c50513          	addi	a0,a0,-372 # 80011180 <cons>
    800002fc:	00001097          	auipc	ra,0x1
    80000300:	988080e7          	jalr	-1656(ra) # 80000c84 <release>
}
    80000304:	60e2                	ld	ra,24(sp)
    80000306:	6442                	ld	s0,16(sp)
    80000308:	64a2                	ld	s1,8(sp)
    8000030a:	6902                	ld	s2,0(sp)
    8000030c:	6105                	addi	sp,sp,32
    8000030e:	8082                	ret
  switch(c){
    80000310:	07f00793          	li	a5,127
    80000314:	0af48e63          	beq	s1,a5,800003d0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000318:	00011717          	auipc	a4,0x11
    8000031c:	e6870713          	addi	a4,a4,-408 # 80011180 <cons>
    80000320:	0a072783          	lw	a5,160(a4)
    80000324:	09872703          	lw	a4,152(a4)
    80000328:	9f99                	subw	a5,a5,a4
    8000032a:	07f00713          	li	a4,127
    8000032e:	fcf763e3          	bltu	a4,a5,800002f4 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000332:	47b5                	li	a5,13
    80000334:	0cf48763          	beq	s1,a5,80000402 <consoleintr+0x14a>
      consputc(c);
    80000338:	8526                	mv	a0,s1
    8000033a:	00000097          	auipc	ra,0x0
    8000033e:	f3c080e7          	jalr	-196(ra) # 80000276 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000342:	00011797          	auipc	a5,0x11
    80000346:	e3e78793          	addi	a5,a5,-450 # 80011180 <cons>
    8000034a:	0a07a703          	lw	a4,160(a5)
    8000034e:	0017069b          	addiw	a3,a4,1
    80000352:	0006861b          	sext.w	a2,a3
    80000356:	0ad7a023          	sw	a3,160(a5)
    8000035a:	07f77713          	andi	a4,a4,127
    8000035e:	97ba                	add	a5,a5,a4
    80000360:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000364:	47a9                	li	a5,10
    80000366:	0cf48563          	beq	s1,a5,80000430 <consoleintr+0x178>
    8000036a:	4791                	li	a5,4
    8000036c:	0cf48263          	beq	s1,a5,80000430 <consoleintr+0x178>
    80000370:	00011797          	auipc	a5,0x11
    80000374:	ea87a783          	lw	a5,-344(a5) # 80011218 <cons+0x98>
    80000378:	0807879b          	addiw	a5,a5,128
    8000037c:	f6f61ce3          	bne	a2,a5,800002f4 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000380:	863e                	mv	a2,a5
    80000382:	a07d                	j	80000430 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000384:	00011717          	auipc	a4,0x11
    80000388:	dfc70713          	addi	a4,a4,-516 # 80011180 <cons>
    8000038c:	0a072783          	lw	a5,160(a4)
    80000390:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000394:	00011497          	auipc	s1,0x11
    80000398:	dec48493          	addi	s1,s1,-532 # 80011180 <cons>
    while(cons.e != cons.w &&
    8000039c:	4929                	li	s2,10
    8000039e:	f4f70be3          	beq	a4,a5,800002f4 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a2:	37fd                	addiw	a5,a5,-1
    800003a4:	07f7f713          	andi	a4,a5,127
    800003a8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003aa:	01874703          	lbu	a4,24(a4)
    800003ae:	f52703e3          	beq	a4,s2,800002f4 <consoleintr+0x3c>
      cons.e--;
    800003b2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003b6:	10000513          	li	a0,256
    800003ba:	00000097          	auipc	ra,0x0
    800003be:	ebc080e7          	jalr	-324(ra) # 80000276 <consputc>
    while(cons.e != cons.w &&
    800003c2:	0a04a783          	lw	a5,160(s1)
    800003c6:	09c4a703          	lw	a4,156(s1)
    800003ca:	fcf71ce3          	bne	a4,a5,800003a2 <consoleintr+0xea>
    800003ce:	b71d                	j	800002f4 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d0:	00011717          	auipc	a4,0x11
    800003d4:	db070713          	addi	a4,a4,-592 # 80011180 <cons>
    800003d8:	0a072783          	lw	a5,160(a4)
    800003dc:	09c72703          	lw	a4,156(a4)
    800003e0:	f0f70ae3          	beq	a4,a5,800002f4 <consoleintr+0x3c>
      cons.e--;
    800003e4:	37fd                	addiw	a5,a5,-1
    800003e6:	00011717          	auipc	a4,0x11
    800003ea:	e2f72d23          	sw	a5,-454(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003ee:	10000513          	li	a0,256
    800003f2:	00000097          	auipc	ra,0x0
    800003f6:	e84080e7          	jalr	-380(ra) # 80000276 <consputc>
    800003fa:	bded                	j	800002f4 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003fc:	ee048ce3          	beqz	s1,800002f4 <consoleintr+0x3c>
    80000400:	bf21                	j	80000318 <consoleintr+0x60>
      consputc(c);
    80000402:	4529                	li	a0,10
    80000404:	00000097          	auipc	ra,0x0
    80000408:	e72080e7          	jalr	-398(ra) # 80000276 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000040c:	00011797          	auipc	a5,0x11
    80000410:	d7478793          	addi	a5,a5,-652 # 80011180 <cons>
    80000414:	0a07a703          	lw	a4,160(a5)
    80000418:	0017069b          	addiw	a3,a4,1
    8000041c:	0006861b          	sext.w	a2,a3
    80000420:	0ad7a023          	sw	a3,160(a5)
    80000424:	07f77713          	andi	a4,a4,127
    80000428:	97ba                	add	a5,a5,a4
    8000042a:	4729                	li	a4,10
    8000042c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000430:	00011797          	auipc	a5,0x11
    80000434:	dec7a623          	sw	a2,-532(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    80000438:	00011517          	auipc	a0,0x11
    8000043c:	de050513          	addi	a0,a0,-544 # 80011218 <cons+0x98>
    80000440:	00002097          	auipc	ra,0x2
    80000444:	e8e080e7          	jalr	-370(ra) # 800022ce <wakeup>
    80000448:	b575                	j	800002f4 <consoleintr+0x3c>

000000008000044a <consoleinit>:

void
consoleinit(void)
{
    8000044a:	1141                	addi	sp,sp,-16
    8000044c:	e406                	sd	ra,8(sp)
    8000044e:	e022                	sd	s0,0(sp)
    80000450:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000452:	00008597          	auipc	a1,0x8
    80000456:	bbe58593          	addi	a1,a1,-1090 # 80008010 <etext+0x10>
    8000045a:	00011517          	auipc	a0,0x11
    8000045e:	d2650513          	addi	a0,a0,-730 # 80011180 <cons>
    80000462:	00000097          	auipc	ra,0x0
    80000466:	6de080e7          	jalr	1758(ra) # 80000b40 <initlock>

  uartinit();
    8000046a:	00000097          	auipc	ra,0x0
    8000046e:	32c080e7          	jalr	812(ra) # 80000796 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000472:	00021797          	auipc	a5,0x21
    80000476:	2a678793          	addi	a5,a5,678 # 80021718 <devsw>
    8000047a:	00000717          	auipc	a4,0x0
    8000047e:	cea70713          	addi	a4,a4,-790 # 80000164 <consoleread>
    80000482:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000484:	00000717          	auipc	a4,0x0
    80000488:	c7c70713          	addi	a4,a4,-900 # 80000100 <consolewrite>
    8000048c:	ef98                	sd	a4,24(a5)
}
    8000048e:	60a2                	ld	ra,8(sp)
    80000490:	6402                	ld	s0,0(sp)
    80000492:	0141                	addi	sp,sp,16
    80000494:	8082                	ret

0000000080000496 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000496:	7179                	addi	sp,sp,-48
    80000498:	f406                	sd	ra,40(sp)
    8000049a:	f022                	sd	s0,32(sp)
    8000049c:	ec26                	sd	s1,24(sp)
    8000049e:	e84a                	sd	s2,16(sp)
    800004a0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a2:	c219                	beqz	a2,800004a8 <printint+0x12>
    800004a4:	08054763          	bltz	a0,80000532 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004a8:	2501                	sext.w	a0,a0
    800004aa:	4881                	li	a7,0
    800004ac:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b2:	2581                	sext.w	a1,a1
    800004b4:	00008617          	auipc	a2,0x8
    800004b8:	b8c60613          	addi	a2,a2,-1140 # 80008040 <digits>
    800004bc:	883a                	mv	a6,a4
    800004be:	2705                	addiw	a4,a4,1
    800004c0:	02b577bb          	remuw	a5,a0,a1
    800004c4:	1782                	slli	a5,a5,0x20
    800004c6:	9381                	srli	a5,a5,0x20
    800004c8:	97b2                	add	a5,a5,a2
    800004ca:	0007c783          	lbu	a5,0(a5)
    800004ce:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d2:	0005079b          	sext.w	a5,a0
    800004d6:	02b5553b          	divuw	a0,a0,a1
    800004da:	0685                	addi	a3,a3,1
    800004dc:	feb7f0e3          	bgeu	a5,a1,800004bc <printint+0x26>

  if(sign)
    800004e0:	00088c63          	beqz	a7,800004f8 <printint+0x62>
    buf[i++] = '-';
    800004e4:	fe070793          	addi	a5,a4,-32
    800004e8:	00878733          	add	a4,a5,s0
    800004ec:	02d00793          	li	a5,45
    800004f0:	fef70823          	sb	a5,-16(a4)
    800004f4:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004f8:	02e05763          	blez	a4,80000526 <printint+0x90>
    800004fc:	fd040793          	addi	a5,s0,-48
    80000500:	00e784b3          	add	s1,a5,a4
    80000504:	fff78913          	addi	s2,a5,-1
    80000508:	993a                	add	s2,s2,a4
    8000050a:	377d                	addiw	a4,a4,-1
    8000050c:	1702                	slli	a4,a4,0x20
    8000050e:	9301                	srli	a4,a4,0x20
    80000510:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000514:	fff4c503          	lbu	a0,-1(s1)
    80000518:	00000097          	auipc	ra,0x0
    8000051c:	d5e080e7          	jalr	-674(ra) # 80000276 <consputc>
  while(--i >= 0)
    80000520:	14fd                	addi	s1,s1,-1
    80000522:	ff2499e3          	bne	s1,s2,80000514 <printint+0x7e>
}
    80000526:	70a2                	ld	ra,40(sp)
    80000528:	7402                	ld	s0,32(sp)
    8000052a:	64e2                	ld	s1,24(sp)
    8000052c:	6942                	ld	s2,16(sp)
    8000052e:	6145                	addi	sp,sp,48
    80000530:	8082                	ret
    x = -xx;
    80000532:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000536:	4885                	li	a7,1
    x = -xx;
    80000538:	bf95                	j	800004ac <printint+0x16>

000000008000053a <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053a:	1101                	addi	sp,sp,-32
    8000053c:	ec06                	sd	ra,24(sp)
    8000053e:	e822                	sd	s0,16(sp)
    80000540:	e426                	sd	s1,8(sp)
    80000542:	1000                	addi	s0,sp,32
    80000544:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000546:	00011797          	auipc	a5,0x11
    8000054a:	ce07ad23          	sw	zero,-774(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    8000054e:	00008517          	auipc	a0,0x8
    80000552:	aca50513          	addi	a0,a0,-1334 # 80008018 <etext+0x18>
    80000556:	00000097          	auipc	ra,0x0
    8000055a:	02e080e7          	jalr	46(ra) # 80000584 <printf>
  printf(s);
    8000055e:	8526                	mv	a0,s1
    80000560:	00000097          	auipc	ra,0x0
    80000564:	024080e7          	jalr	36(ra) # 80000584 <printf>
  printf("\n");
    80000568:	00008517          	auipc	a0,0x8
    8000056c:	b6050513          	addi	a0,a0,-1184 # 800080c8 <digits+0x88>
    80000570:	00000097          	auipc	ra,0x0
    80000574:	014080e7          	jalr	20(ra) # 80000584 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000578:	4785                	li	a5,1
    8000057a:	00009717          	auipc	a4,0x9
    8000057e:	a8f72323          	sw	a5,-1402(a4) # 80009000 <panicked>
  for(;;)
    80000582:	a001                	j	80000582 <panic+0x48>

0000000080000584 <printf>:
{
    80000584:	7131                	addi	sp,sp,-192
    80000586:	fc86                	sd	ra,120(sp)
    80000588:	f8a2                	sd	s0,112(sp)
    8000058a:	f4a6                	sd	s1,104(sp)
    8000058c:	f0ca                	sd	s2,96(sp)
    8000058e:	ecce                	sd	s3,88(sp)
    80000590:	e8d2                	sd	s4,80(sp)
    80000592:	e4d6                	sd	s5,72(sp)
    80000594:	e0da                	sd	s6,64(sp)
    80000596:	fc5e                	sd	s7,56(sp)
    80000598:	f862                	sd	s8,48(sp)
    8000059a:	f466                	sd	s9,40(sp)
    8000059c:	f06a                	sd	s10,32(sp)
    8000059e:	ec6e                	sd	s11,24(sp)
    800005a0:	0100                	addi	s0,sp,128
    800005a2:	8a2a                	mv	s4,a0
    800005a4:	e40c                	sd	a1,8(s0)
    800005a6:	e810                	sd	a2,16(s0)
    800005a8:	ec14                	sd	a3,24(s0)
    800005aa:	f018                	sd	a4,32(s0)
    800005ac:	f41c                	sd	a5,40(s0)
    800005ae:	03043823          	sd	a6,48(s0)
    800005b2:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005b6:	00011d97          	auipc	s11,0x11
    800005ba:	c8adad83          	lw	s11,-886(s11) # 80011240 <pr+0x18>
  if(locking)
    800005be:	020d9b63          	bnez	s11,800005f4 <printf+0x70>
  if (fmt == 0)
    800005c2:	040a0263          	beqz	s4,80000606 <printf+0x82>
  va_start(ap, fmt);
    800005c6:	00840793          	addi	a5,s0,8
    800005ca:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005ce:	000a4503          	lbu	a0,0(s4)
    800005d2:	14050f63          	beqz	a0,80000730 <printf+0x1ac>
    800005d6:	4981                	li	s3,0
    if(c != '%'){
    800005d8:	02500a93          	li	s5,37
    switch(c){
    800005dc:	07000b93          	li	s7,112
  consputc('x');
    800005e0:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e2:	00008b17          	auipc	s6,0x8
    800005e6:	a5eb0b13          	addi	s6,s6,-1442 # 80008040 <digits>
    switch(c){
    800005ea:	07300c93          	li	s9,115
    800005ee:	06400c13          	li	s8,100
    800005f2:	a82d                	j	8000062c <printf+0xa8>
    acquire(&pr.lock);
    800005f4:	00011517          	auipc	a0,0x11
    800005f8:	c3450513          	addi	a0,a0,-972 # 80011228 <pr>
    800005fc:	00000097          	auipc	ra,0x0
    80000600:	5d4080e7          	jalr	1492(ra) # 80000bd0 <acquire>
    80000604:	bf7d                	j	800005c2 <printf+0x3e>
    panic("null fmt");
    80000606:	00008517          	auipc	a0,0x8
    8000060a:	a2250513          	addi	a0,a0,-1502 # 80008028 <etext+0x28>
    8000060e:	00000097          	auipc	ra,0x0
    80000612:	f2c080e7          	jalr	-212(ra) # 8000053a <panic>
      consputc(c);
    80000616:	00000097          	auipc	ra,0x0
    8000061a:	c60080e7          	jalr	-928(ra) # 80000276 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000061e:	2985                	addiw	s3,s3,1
    80000620:	013a07b3          	add	a5,s4,s3
    80000624:	0007c503          	lbu	a0,0(a5)
    80000628:	10050463          	beqz	a0,80000730 <printf+0x1ac>
    if(c != '%'){
    8000062c:	ff5515e3          	bne	a0,s5,80000616 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000630:	2985                	addiw	s3,s3,1
    80000632:	013a07b3          	add	a5,s4,s3
    80000636:	0007c783          	lbu	a5,0(a5)
    8000063a:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000063e:	cbed                	beqz	a5,80000730 <printf+0x1ac>
    switch(c){
    80000640:	05778a63          	beq	a5,s7,80000694 <printf+0x110>
    80000644:	02fbf663          	bgeu	s7,a5,80000670 <printf+0xec>
    80000648:	09978863          	beq	a5,s9,800006d8 <printf+0x154>
    8000064c:	07800713          	li	a4,120
    80000650:	0ce79563          	bne	a5,a4,8000071a <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000654:	f8843783          	ld	a5,-120(s0)
    80000658:	00878713          	addi	a4,a5,8
    8000065c:	f8e43423          	sd	a4,-120(s0)
    80000660:	4605                	li	a2,1
    80000662:	85ea                	mv	a1,s10
    80000664:	4388                	lw	a0,0(a5)
    80000666:	00000097          	auipc	ra,0x0
    8000066a:	e30080e7          	jalr	-464(ra) # 80000496 <printint>
      break;
    8000066e:	bf45                	j	8000061e <printf+0x9a>
    switch(c){
    80000670:	09578f63          	beq	a5,s5,8000070e <printf+0x18a>
    80000674:	0b879363          	bne	a5,s8,8000071a <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000678:	f8843783          	ld	a5,-120(s0)
    8000067c:	00878713          	addi	a4,a5,8
    80000680:	f8e43423          	sd	a4,-120(s0)
    80000684:	4605                	li	a2,1
    80000686:	45a9                	li	a1,10
    80000688:	4388                	lw	a0,0(a5)
    8000068a:	00000097          	auipc	ra,0x0
    8000068e:	e0c080e7          	jalr	-500(ra) # 80000496 <printint>
      break;
    80000692:	b771                	j	8000061e <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000694:	f8843783          	ld	a5,-120(s0)
    80000698:	00878713          	addi	a4,a5,8
    8000069c:	f8e43423          	sd	a4,-120(s0)
    800006a0:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a4:	03000513          	li	a0,48
    800006a8:	00000097          	auipc	ra,0x0
    800006ac:	bce080e7          	jalr	-1074(ra) # 80000276 <consputc>
  consputc('x');
    800006b0:	07800513          	li	a0,120
    800006b4:	00000097          	auipc	ra,0x0
    800006b8:	bc2080e7          	jalr	-1086(ra) # 80000276 <consputc>
    800006bc:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006be:	03c95793          	srli	a5,s2,0x3c
    800006c2:	97da                	add	a5,a5,s6
    800006c4:	0007c503          	lbu	a0,0(a5)
    800006c8:	00000097          	auipc	ra,0x0
    800006cc:	bae080e7          	jalr	-1106(ra) # 80000276 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d0:	0912                	slli	s2,s2,0x4
    800006d2:	34fd                	addiw	s1,s1,-1
    800006d4:	f4ed                	bnez	s1,800006be <printf+0x13a>
    800006d6:	b7a1                	j	8000061e <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006d8:	f8843783          	ld	a5,-120(s0)
    800006dc:	00878713          	addi	a4,a5,8
    800006e0:	f8e43423          	sd	a4,-120(s0)
    800006e4:	6384                	ld	s1,0(a5)
    800006e6:	cc89                	beqz	s1,80000700 <printf+0x17c>
      for(; *s; s++)
    800006e8:	0004c503          	lbu	a0,0(s1)
    800006ec:	d90d                	beqz	a0,8000061e <printf+0x9a>
        consputc(*s);
    800006ee:	00000097          	auipc	ra,0x0
    800006f2:	b88080e7          	jalr	-1144(ra) # 80000276 <consputc>
      for(; *s; s++)
    800006f6:	0485                	addi	s1,s1,1
    800006f8:	0004c503          	lbu	a0,0(s1)
    800006fc:	f96d                	bnez	a0,800006ee <printf+0x16a>
    800006fe:	b705                	j	8000061e <printf+0x9a>
        s = "(null)";
    80000700:	00008497          	auipc	s1,0x8
    80000704:	92048493          	addi	s1,s1,-1760 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000708:	02800513          	li	a0,40
    8000070c:	b7cd                	j	800006ee <printf+0x16a>
      consputc('%');
    8000070e:	8556                	mv	a0,s5
    80000710:	00000097          	auipc	ra,0x0
    80000714:	b66080e7          	jalr	-1178(ra) # 80000276 <consputc>
      break;
    80000718:	b719                	j	8000061e <printf+0x9a>
      consputc('%');
    8000071a:	8556                	mv	a0,s5
    8000071c:	00000097          	auipc	ra,0x0
    80000720:	b5a080e7          	jalr	-1190(ra) # 80000276 <consputc>
      consputc(c);
    80000724:	8526                	mv	a0,s1
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b50080e7          	jalr	-1200(ra) # 80000276 <consputc>
      break;
    8000072e:	bdc5                	j	8000061e <printf+0x9a>
  if(locking)
    80000730:	020d9163          	bnez	s11,80000752 <printf+0x1ce>
}
    80000734:	70e6                	ld	ra,120(sp)
    80000736:	7446                	ld	s0,112(sp)
    80000738:	74a6                	ld	s1,104(sp)
    8000073a:	7906                	ld	s2,96(sp)
    8000073c:	69e6                	ld	s3,88(sp)
    8000073e:	6a46                	ld	s4,80(sp)
    80000740:	6aa6                	ld	s5,72(sp)
    80000742:	6b06                	ld	s6,64(sp)
    80000744:	7be2                	ld	s7,56(sp)
    80000746:	7c42                	ld	s8,48(sp)
    80000748:	7ca2                	ld	s9,40(sp)
    8000074a:	7d02                	ld	s10,32(sp)
    8000074c:	6de2                	ld	s11,24(sp)
    8000074e:	6129                	addi	sp,sp,192
    80000750:	8082                	ret
    release(&pr.lock);
    80000752:	00011517          	auipc	a0,0x11
    80000756:	ad650513          	addi	a0,a0,-1322 # 80011228 <pr>
    8000075a:	00000097          	auipc	ra,0x0
    8000075e:	52a080e7          	jalr	1322(ra) # 80000c84 <release>
}
    80000762:	bfc9                	j	80000734 <printf+0x1b0>

0000000080000764 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000764:	1101                	addi	sp,sp,-32
    80000766:	ec06                	sd	ra,24(sp)
    80000768:	e822                	sd	s0,16(sp)
    8000076a:	e426                	sd	s1,8(sp)
    8000076c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000076e:	00011497          	auipc	s1,0x11
    80000772:	aba48493          	addi	s1,s1,-1350 # 80011228 <pr>
    80000776:	00008597          	auipc	a1,0x8
    8000077a:	8c258593          	addi	a1,a1,-1854 # 80008038 <etext+0x38>
    8000077e:	8526                	mv	a0,s1
    80000780:	00000097          	auipc	ra,0x0
    80000784:	3c0080e7          	jalr	960(ra) # 80000b40 <initlock>
  pr.locking = 1;
    80000788:	4785                	li	a5,1
    8000078a:	cc9c                	sw	a5,24(s1)
}
    8000078c:	60e2                	ld	ra,24(sp)
    8000078e:	6442                	ld	s0,16(sp)
    80000790:	64a2                	ld	s1,8(sp)
    80000792:	6105                	addi	sp,sp,32
    80000794:	8082                	ret

0000000080000796 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000796:	1141                	addi	sp,sp,-16
    80000798:	e406                	sd	ra,8(sp)
    8000079a:	e022                	sd	s0,0(sp)
    8000079c:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000079e:	100007b7          	lui	a5,0x10000
    800007a2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a6:	f8000713          	li	a4,-128
    800007aa:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007ae:	470d                	li	a4,3
    800007b0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007b8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007bc:	469d                	li	a3,7
    800007be:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c6:	00008597          	auipc	a1,0x8
    800007ca:	89258593          	addi	a1,a1,-1902 # 80008058 <digits+0x18>
    800007ce:	00011517          	auipc	a0,0x11
    800007d2:	a7a50513          	addi	a0,a0,-1414 # 80011248 <uart_tx_lock>
    800007d6:	00000097          	auipc	ra,0x0
    800007da:	36a080e7          	jalr	874(ra) # 80000b40 <initlock>
}
    800007de:	60a2                	ld	ra,8(sp)
    800007e0:	6402                	ld	s0,0(sp)
    800007e2:	0141                	addi	sp,sp,16
    800007e4:	8082                	ret

00000000800007e6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e6:	1101                	addi	sp,sp,-32
    800007e8:	ec06                	sd	ra,24(sp)
    800007ea:	e822                	sd	s0,16(sp)
    800007ec:	e426                	sd	s1,8(sp)
    800007ee:	1000                	addi	s0,sp,32
    800007f0:	84aa                	mv	s1,a0
  push_off();
    800007f2:	00000097          	auipc	ra,0x0
    800007f6:	392080e7          	jalr	914(ra) # 80000b84 <push_off>

  if(panicked){
    800007fa:	00009797          	auipc	a5,0x9
    800007fe:	8067a783          	lw	a5,-2042(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000802:	10000737          	lui	a4,0x10000
  if(panicked){
    80000806:	c391                	beqz	a5,8000080a <uartputc_sync+0x24>
    for(;;)
    80000808:	a001                	j	80000808 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000080e:	0207f793          	andi	a5,a5,32
    80000812:	dfe5                	beqz	a5,8000080a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000814:	0ff4f513          	zext.b	a0,s1
    80000818:	100007b7          	lui	a5,0x10000
    8000081c:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000820:	00000097          	auipc	ra,0x0
    80000824:	404080e7          	jalr	1028(ra) # 80000c24 <pop_off>
}
    80000828:	60e2                	ld	ra,24(sp)
    8000082a:	6442                	ld	s0,16(sp)
    8000082c:	64a2                	ld	s1,8(sp)
    8000082e:	6105                	addi	sp,sp,32
    80000830:	8082                	ret

0000000080000832 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000832:	00008797          	auipc	a5,0x8
    80000836:	7d67b783          	ld	a5,2006(a5) # 80009008 <uart_tx_r>
    8000083a:	00008717          	auipc	a4,0x8
    8000083e:	7d673703          	ld	a4,2006(a4) # 80009010 <uart_tx_w>
    80000842:	06f70a63          	beq	a4,a5,800008b6 <uartstart+0x84>
{
    80000846:	7139                	addi	sp,sp,-64
    80000848:	fc06                	sd	ra,56(sp)
    8000084a:	f822                	sd	s0,48(sp)
    8000084c:	f426                	sd	s1,40(sp)
    8000084e:	f04a                	sd	s2,32(sp)
    80000850:	ec4e                	sd	s3,24(sp)
    80000852:	e852                	sd	s4,16(sp)
    80000854:	e456                	sd	s5,8(sp)
    80000856:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000858:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085c:	00011a17          	auipc	s4,0x11
    80000860:	9eca0a13          	addi	s4,s4,-1556 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000864:	00008497          	auipc	s1,0x8
    80000868:	7a448493          	addi	s1,s1,1956 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086c:	00008997          	auipc	s3,0x8
    80000870:	7a498993          	addi	s3,s3,1956 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000874:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000878:	02077713          	andi	a4,a4,32
    8000087c:	c705                	beqz	a4,800008a4 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000087e:	01f7f713          	andi	a4,a5,31
    80000882:	9752                	add	a4,a4,s4
    80000884:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000888:	0785                	addi	a5,a5,1
    8000088a:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000088c:	8526                	mv	a0,s1
    8000088e:	00002097          	auipc	ra,0x2
    80000892:	a40080e7          	jalr	-1472(ra) # 800022ce <wakeup>
    
    WriteReg(THR, c);
    80000896:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089a:	609c                	ld	a5,0(s1)
    8000089c:	0009b703          	ld	a4,0(s3)
    800008a0:	fcf71ae3          	bne	a4,a5,80000874 <uartstart+0x42>
  }
}
    800008a4:	70e2                	ld	ra,56(sp)
    800008a6:	7442                	ld	s0,48(sp)
    800008a8:	74a2                	ld	s1,40(sp)
    800008aa:	7902                	ld	s2,32(sp)
    800008ac:	69e2                	ld	s3,24(sp)
    800008ae:	6a42                	ld	s4,16(sp)
    800008b0:	6aa2                	ld	s5,8(sp)
    800008b2:	6121                	addi	sp,sp,64
    800008b4:	8082                	ret
    800008b6:	8082                	ret

00000000800008b8 <uartputc>:
{
    800008b8:	7179                	addi	sp,sp,-48
    800008ba:	f406                	sd	ra,40(sp)
    800008bc:	f022                	sd	s0,32(sp)
    800008be:	ec26                	sd	s1,24(sp)
    800008c0:	e84a                	sd	s2,16(sp)
    800008c2:	e44e                	sd	s3,8(sp)
    800008c4:	e052                	sd	s4,0(sp)
    800008c6:	1800                	addi	s0,sp,48
    800008c8:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ca:	00011517          	auipc	a0,0x11
    800008ce:	97e50513          	addi	a0,a0,-1666 # 80011248 <uart_tx_lock>
    800008d2:	00000097          	auipc	ra,0x0
    800008d6:	2fe080e7          	jalr	766(ra) # 80000bd0 <acquire>
  if(panicked){
    800008da:	00008797          	auipc	a5,0x8
    800008de:	7267a783          	lw	a5,1830(a5) # 80009000 <panicked>
    800008e2:	c391                	beqz	a5,800008e6 <uartputc+0x2e>
    for(;;)
    800008e4:	a001                	j	800008e4 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	72a73703          	ld	a4,1834(a4) # 80009010 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	71a7b783          	ld	a5,1818(a5) # 80009008 <uart_tx_r>
    800008f6:	02078793          	addi	a5,a5,32
    800008fa:	02e79b63          	bne	a5,a4,80000930 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00011997          	auipc	s3,0x11
    80000902:	94a98993          	addi	s3,s3,-1718 # 80011248 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	70248493          	addi	s1,s1,1794 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	70290913          	addi	s2,s2,1794 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00002097          	auipc	ra,0x2
    8000091e:	828080e7          	jalr	-2008(ra) # 80002142 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	addi	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00011497          	auipc	s1,0x11
    80000934:	91848493          	addi	s1,s1,-1768 # 80011248 <uart_tx_lock>
    80000938:	01f77793          	andi	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
      uart_tx_w += 1;
    80000942:	0705                	addi	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	6ce7b623          	sd	a4,1740(a5) # 80009010 <uart_tx_w>
      uartstart();
    8000094c:	00000097          	auipc	ra,0x0
    80000950:	ee6080e7          	jalr	-282(ra) # 80000832 <uartstart>
      release(&uart_tx_lock);
    80000954:	8526                	mv	a0,s1
    80000956:	00000097          	auipc	ra,0x0
    8000095a:	32e080e7          	jalr	814(ra) # 80000c84 <release>
}
    8000095e:	70a2                	ld	ra,40(sp)
    80000960:	7402                	ld	s0,32(sp)
    80000962:	64e2                	ld	s1,24(sp)
    80000964:	6942                	ld	s2,16(sp)
    80000966:	69a2                	ld	s3,8(sp)
    80000968:	6a02                	ld	s4,0(sp)
    8000096a:	6145                	addi	sp,sp,48
    8000096c:	8082                	ret

000000008000096e <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000096e:	1141                	addi	sp,sp,-16
    80000970:	e422                	sd	s0,8(sp)
    80000972:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000974:	100007b7          	lui	a5,0x10000
    80000978:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000097c:	8b85                	andi	a5,a5,1
    8000097e:	cb81                	beqz	a5,8000098e <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000980:	100007b7          	lui	a5,0x10000
    80000984:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    80000988:	6422                	ld	s0,8(sp)
    8000098a:	0141                	addi	sp,sp,16
    8000098c:	8082                	ret
    return -1;
    8000098e:	557d                	li	a0,-1
    80000990:	bfe5                	j	80000988 <uartgetc+0x1a>

0000000080000992 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000992:	1101                	addi	sp,sp,-32
    80000994:	ec06                	sd	ra,24(sp)
    80000996:	e822                	sd	s0,16(sp)
    80000998:	e426                	sd	s1,8(sp)
    8000099a:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000099c:	54fd                	li	s1,-1
    8000099e:	a029                	j	800009a8 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a0:	00000097          	auipc	ra,0x0
    800009a4:	918080e7          	jalr	-1768(ra) # 800002b8 <consoleintr>
    int c = uartgetc();
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	fc6080e7          	jalr	-58(ra) # 8000096e <uartgetc>
    if(c == -1)
    800009b0:	fe9518e3          	bne	a0,s1,800009a0 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009b4:	00011497          	auipc	s1,0x11
    800009b8:	89448493          	addi	s1,s1,-1900 # 80011248 <uart_tx_lock>
    800009bc:	8526                	mv	a0,s1
    800009be:	00000097          	auipc	ra,0x0
    800009c2:	212080e7          	jalr	530(ra) # 80000bd0 <acquire>
  uartstart();
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	e6c080e7          	jalr	-404(ra) # 80000832 <uartstart>
  release(&uart_tx_lock);
    800009ce:	8526                	mv	a0,s1
    800009d0:	00000097          	auipc	ra,0x0
    800009d4:	2b4080e7          	jalr	692(ra) # 80000c84 <release>
}
    800009d8:	60e2                	ld	ra,24(sp)
    800009da:	6442                	ld	s0,16(sp)
    800009dc:	64a2                	ld	s1,8(sp)
    800009de:	6105                	addi	sp,sp,32
    800009e0:	8082                	ret

00000000800009e2 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e2:	1101                	addi	sp,sp,-32
    800009e4:	ec06                	sd	ra,24(sp)
    800009e6:	e822                	sd	s0,16(sp)
    800009e8:	e426                	sd	s1,8(sp)
    800009ea:	e04a                	sd	s2,0(sp)
    800009ec:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009ee:	03451793          	slli	a5,a0,0x34
    800009f2:	ebb9                	bnez	a5,80000a48 <kfree+0x66>
    800009f4:	84aa                	mv	s1,a0
    800009f6:	00025797          	auipc	a5,0x25
    800009fa:	60a78793          	addi	a5,a5,1546 # 80026000 <end>
    800009fe:	04f56563          	bltu	a0,a5,80000a48 <kfree+0x66>
    80000a02:	47c5                	li	a5,17
    80000a04:	07ee                	slli	a5,a5,0x1b
    80000a06:	04f57163          	bgeu	a0,a5,80000a48 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a0a:	6605                	lui	a2,0x1
    80000a0c:	4585                	li	a1,1
    80000a0e:	00000097          	auipc	ra,0x0
    80000a12:	2be080e7          	jalr	702(ra) # 80000ccc <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a16:	00011917          	auipc	s2,0x11
    80000a1a:	86a90913          	addi	s2,s2,-1942 # 80011280 <kmem>
    80000a1e:	854a                	mv	a0,s2
    80000a20:	00000097          	auipc	ra,0x0
    80000a24:	1b0080e7          	jalr	432(ra) # 80000bd0 <acquire>
  r->next = kmem.freelist;
    80000a28:	01893783          	ld	a5,24(s2)
    80000a2c:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a2e:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a32:	854a                	mv	a0,s2
    80000a34:	00000097          	auipc	ra,0x0
    80000a38:	250080e7          	jalr	592(ra) # 80000c84 <release>
}
    80000a3c:	60e2                	ld	ra,24(sp)
    80000a3e:	6442                	ld	s0,16(sp)
    80000a40:	64a2                	ld	s1,8(sp)
    80000a42:	6902                	ld	s2,0(sp)
    80000a44:	6105                	addi	sp,sp,32
    80000a46:	8082                	ret
    panic("kfree");
    80000a48:	00007517          	auipc	a0,0x7
    80000a4c:	61850513          	addi	a0,a0,1560 # 80008060 <digits+0x20>
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	aea080e7          	jalr	-1302(ra) # 8000053a <panic>

0000000080000a58 <freerange>:
{
    80000a58:	7179                	addi	sp,sp,-48
    80000a5a:	f406                	sd	ra,40(sp)
    80000a5c:	f022                	sd	s0,32(sp)
    80000a5e:	ec26                	sd	s1,24(sp)
    80000a60:	e84a                	sd	s2,16(sp)
    80000a62:	e44e                	sd	s3,8(sp)
    80000a64:	e052                	sd	s4,0(sp)
    80000a66:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a68:	6785                	lui	a5,0x1
    80000a6a:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a6e:	00e504b3          	add	s1,a0,a4
    80000a72:	777d                	lui	a4,0xfffff
    80000a74:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a76:	94be                	add	s1,s1,a5
    80000a78:	0095ee63          	bltu	a1,s1,80000a94 <freerange+0x3c>
    80000a7c:	892e                	mv	s2,a1
    kfree(p);
    80000a7e:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a80:	6985                	lui	s3,0x1
    kfree(p);
    80000a82:	01448533          	add	a0,s1,s4
    80000a86:	00000097          	auipc	ra,0x0
    80000a8a:	f5c080e7          	jalr	-164(ra) # 800009e2 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8e:	94ce                	add	s1,s1,s3
    80000a90:	fe9979e3          	bgeu	s2,s1,80000a82 <freerange+0x2a>
}
    80000a94:	70a2                	ld	ra,40(sp)
    80000a96:	7402                	ld	s0,32(sp)
    80000a98:	64e2                	ld	s1,24(sp)
    80000a9a:	6942                	ld	s2,16(sp)
    80000a9c:	69a2                	ld	s3,8(sp)
    80000a9e:	6a02                	ld	s4,0(sp)
    80000aa0:	6145                	addi	sp,sp,48
    80000aa2:	8082                	ret

0000000080000aa4 <kinit>:
{
    80000aa4:	1141                	addi	sp,sp,-16
    80000aa6:	e406                	sd	ra,8(sp)
    80000aa8:	e022                	sd	s0,0(sp)
    80000aaa:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aac:	00007597          	auipc	a1,0x7
    80000ab0:	5bc58593          	addi	a1,a1,1468 # 80008068 <digits+0x28>
    80000ab4:	00010517          	auipc	a0,0x10
    80000ab8:	7cc50513          	addi	a0,a0,1996 # 80011280 <kmem>
    80000abc:	00000097          	auipc	ra,0x0
    80000ac0:	084080e7          	jalr	132(ra) # 80000b40 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac4:	45c5                	li	a1,17
    80000ac6:	05ee                	slli	a1,a1,0x1b
    80000ac8:	00025517          	auipc	a0,0x25
    80000acc:	53850513          	addi	a0,a0,1336 # 80026000 <end>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	f88080e7          	jalr	-120(ra) # 80000a58 <freerange>
}
    80000ad8:	60a2                	ld	ra,8(sp)
    80000ada:	6402                	ld	s0,0(sp)
    80000adc:	0141                	addi	sp,sp,16
    80000ade:	8082                	ret

0000000080000ae0 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae0:	1101                	addi	sp,sp,-32
    80000ae2:	ec06                	sd	ra,24(sp)
    80000ae4:	e822                	sd	s0,16(sp)
    80000ae6:	e426                	sd	s1,8(sp)
    80000ae8:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000aea:	00010497          	auipc	s1,0x10
    80000aee:	79648493          	addi	s1,s1,1942 # 80011280 <kmem>
    80000af2:	8526                	mv	a0,s1
    80000af4:	00000097          	auipc	ra,0x0
    80000af8:	0dc080e7          	jalr	220(ra) # 80000bd0 <acquire>
  r = kmem.freelist;
    80000afc:	6c84                	ld	s1,24(s1)
  if(r)
    80000afe:	c885                	beqz	s1,80000b2e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b00:	609c                	ld	a5,0(s1)
    80000b02:	00010517          	auipc	a0,0x10
    80000b06:	77e50513          	addi	a0,a0,1918 # 80011280 <kmem>
    80000b0a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	178080e7          	jalr	376(ra) # 80000c84 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b14:	6605                	lui	a2,0x1
    80000b16:	4595                	li	a1,5
    80000b18:	8526                	mv	a0,s1
    80000b1a:	00000097          	auipc	ra,0x0
    80000b1e:	1b2080e7          	jalr	434(ra) # 80000ccc <memset>
  return (void*)r;
}
    80000b22:	8526                	mv	a0,s1
    80000b24:	60e2                	ld	ra,24(sp)
    80000b26:	6442                	ld	s0,16(sp)
    80000b28:	64a2                	ld	s1,8(sp)
    80000b2a:	6105                	addi	sp,sp,32
    80000b2c:	8082                	ret
  release(&kmem.lock);
    80000b2e:	00010517          	auipc	a0,0x10
    80000b32:	75250513          	addi	a0,a0,1874 # 80011280 <kmem>
    80000b36:	00000097          	auipc	ra,0x0
    80000b3a:	14e080e7          	jalr	334(ra) # 80000c84 <release>
  if(r)
    80000b3e:	b7d5                	j	80000b22 <kalloc+0x42>

0000000080000b40 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b40:	1141                	addi	sp,sp,-16
    80000b42:	e422                	sd	s0,8(sp)
    80000b44:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b46:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b48:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b4c:	00053823          	sd	zero,16(a0)
}
    80000b50:	6422                	ld	s0,8(sp)
    80000b52:	0141                	addi	sp,sp,16
    80000b54:	8082                	ret

0000000080000b56 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b56:	411c                	lw	a5,0(a0)
    80000b58:	e399                	bnez	a5,80000b5e <holding+0x8>
    80000b5a:	4501                	li	a0,0
  return r;
}
    80000b5c:	8082                	ret
{
    80000b5e:	1101                	addi	sp,sp,-32
    80000b60:	ec06                	sd	ra,24(sp)
    80000b62:	e822                	sd	s0,16(sp)
    80000b64:	e426                	sd	s1,8(sp)
    80000b66:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b68:	6904                	ld	s1,16(a0)
    80000b6a:	00001097          	auipc	ra,0x1
    80000b6e:	e10080e7          	jalr	-496(ra) # 8000197a <mycpu>
    80000b72:	40a48533          	sub	a0,s1,a0
    80000b76:	00153513          	seqz	a0,a0
}
    80000b7a:	60e2                	ld	ra,24(sp)
    80000b7c:	6442                	ld	s0,16(sp)
    80000b7e:	64a2                	ld	s1,8(sp)
    80000b80:	6105                	addi	sp,sp,32
    80000b82:	8082                	ret

0000000080000b84 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b84:	1101                	addi	sp,sp,-32
    80000b86:	ec06                	sd	ra,24(sp)
    80000b88:	e822                	sd	s0,16(sp)
    80000b8a:	e426                	sd	s1,8(sp)
    80000b8c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b8e:	100024f3          	csrr	s1,sstatus
    80000b92:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b96:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b98:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b9c:	00001097          	auipc	ra,0x1
    80000ba0:	dde080e7          	jalr	-546(ra) # 8000197a <mycpu>
    80000ba4:	5d3c                	lw	a5,120(a0)
    80000ba6:	cf89                	beqz	a5,80000bc0 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000ba8:	00001097          	auipc	ra,0x1
    80000bac:	dd2080e7          	jalr	-558(ra) # 8000197a <mycpu>
    80000bb0:	5d3c                	lw	a5,120(a0)
    80000bb2:	2785                	addiw	a5,a5,1
    80000bb4:	dd3c                	sw	a5,120(a0)
}
    80000bb6:	60e2                	ld	ra,24(sp)
    80000bb8:	6442                	ld	s0,16(sp)
    80000bba:	64a2                	ld	s1,8(sp)
    80000bbc:	6105                	addi	sp,sp,32
    80000bbe:	8082                	ret
    mycpu()->intena = old;
    80000bc0:	00001097          	auipc	ra,0x1
    80000bc4:	dba080e7          	jalr	-582(ra) # 8000197a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bc8:	8085                	srli	s1,s1,0x1
    80000bca:	8885                	andi	s1,s1,1
    80000bcc:	dd64                	sw	s1,124(a0)
    80000bce:	bfe9                	j	80000ba8 <push_off+0x24>

0000000080000bd0 <acquire>:
{
    80000bd0:	1101                	addi	sp,sp,-32
    80000bd2:	ec06                	sd	ra,24(sp)
    80000bd4:	e822                	sd	s0,16(sp)
    80000bd6:	e426                	sd	s1,8(sp)
    80000bd8:	1000                	addi	s0,sp,32
    80000bda:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bdc:	00000097          	auipc	ra,0x0
    80000be0:	fa8080e7          	jalr	-88(ra) # 80000b84 <push_off>
  if(holding(lk))
    80000be4:	8526                	mv	a0,s1
    80000be6:	00000097          	auipc	ra,0x0
    80000bea:	f70080e7          	jalr	-144(ra) # 80000b56 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bee:	4705                	li	a4,1
  if(holding(lk))
    80000bf0:	e115                	bnez	a0,80000c14 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf2:	87ba                	mv	a5,a4
    80000bf4:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bf8:	2781                	sext.w	a5,a5
    80000bfa:	ffe5                	bnez	a5,80000bf2 <acquire+0x22>
  __sync_synchronize();
    80000bfc:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c00:	00001097          	auipc	ra,0x1
    80000c04:	d7a080e7          	jalr	-646(ra) # 8000197a <mycpu>
    80000c08:	e888                	sd	a0,16(s1)
}
    80000c0a:	60e2                	ld	ra,24(sp)
    80000c0c:	6442                	ld	s0,16(sp)
    80000c0e:	64a2                	ld	s1,8(sp)
    80000c10:	6105                	addi	sp,sp,32
    80000c12:	8082                	ret
    panic("acquire");
    80000c14:	00007517          	auipc	a0,0x7
    80000c18:	45c50513          	addi	a0,a0,1116 # 80008070 <digits+0x30>
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	91e080e7          	jalr	-1762(ra) # 8000053a <panic>

0000000080000c24 <pop_off>:

void
pop_off(void)
{
    80000c24:	1141                	addi	sp,sp,-16
    80000c26:	e406                	sd	ra,8(sp)
    80000c28:	e022                	sd	s0,0(sp)
    80000c2a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c2c:	00001097          	auipc	ra,0x1
    80000c30:	d4e080e7          	jalr	-690(ra) # 8000197a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c34:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c38:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c3a:	e78d                	bnez	a5,80000c64 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c3c:	5d3c                	lw	a5,120(a0)
    80000c3e:	02f05b63          	blez	a5,80000c74 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c42:	37fd                	addiw	a5,a5,-1
    80000c44:	0007871b          	sext.w	a4,a5
    80000c48:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c4a:	eb09                	bnez	a4,80000c5c <pop_off+0x38>
    80000c4c:	5d7c                	lw	a5,124(a0)
    80000c4e:	c799                	beqz	a5,80000c5c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c50:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c54:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c58:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c5c:	60a2                	ld	ra,8(sp)
    80000c5e:	6402                	ld	s0,0(sp)
    80000c60:	0141                	addi	sp,sp,16
    80000c62:	8082                	ret
    panic("pop_off - interruptible");
    80000c64:	00007517          	auipc	a0,0x7
    80000c68:	41450513          	addi	a0,a0,1044 # 80008078 <digits+0x38>
    80000c6c:	00000097          	auipc	ra,0x0
    80000c70:	8ce080e7          	jalr	-1842(ra) # 8000053a <panic>
    panic("pop_off");
    80000c74:	00007517          	auipc	a0,0x7
    80000c78:	41c50513          	addi	a0,a0,1052 # 80008090 <digits+0x50>
    80000c7c:	00000097          	auipc	ra,0x0
    80000c80:	8be080e7          	jalr	-1858(ra) # 8000053a <panic>

0000000080000c84 <release>:
{
    80000c84:	1101                	addi	sp,sp,-32
    80000c86:	ec06                	sd	ra,24(sp)
    80000c88:	e822                	sd	s0,16(sp)
    80000c8a:	e426                	sd	s1,8(sp)
    80000c8c:	1000                	addi	s0,sp,32
    80000c8e:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	ec6080e7          	jalr	-314(ra) # 80000b56 <holding>
    80000c98:	c115                	beqz	a0,80000cbc <release+0x38>
  lk->cpu = 0;
    80000c9a:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c9e:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca2:	0f50000f          	fence	iorw,ow
    80000ca6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	f7a080e7          	jalr	-134(ra) # 80000c24 <pop_off>
}
    80000cb2:	60e2                	ld	ra,24(sp)
    80000cb4:	6442                	ld	s0,16(sp)
    80000cb6:	64a2                	ld	s1,8(sp)
    80000cb8:	6105                	addi	sp,sp,32
    80000cba:	8082                	ret
    panic("release");
    80000cbc:	00007517          	auipc	a0,0x7
    80000cc0:	3dc50513          	addi	a0,a0,988 # 80008098 <digits+0x58>
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	876080e7          	jalr	-1930(ra) # 8000053a <panic>

0000000080000ccc <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ccc:	1141                	addi	sp,sp,-16
    80000cce:	e422                	sd	s0,8(sp)
    80000cd0:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd2:	ca19                	beqz	a2,80000ce8 <memset+0x1c>
    80000cd4:	87aa                	mv	a5,a0
    80000cd6:	1602                	slli	a2,a2,0x20
    80000cd8:	9201                	srli	a2,a2,0x20
    80000cda:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cde:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce2:	0785                	addi	a5,a5,1
    80000ce4:	fee79de3          	bne	a5,a4,80000cde <memset+0x12>
  }
  return dst;
}
    80000ce8:	6422                	ld	s0,8(sp)
    80000cea:	0141                	addi	sp,sp,16
    80000cec:	8082                	ret

0000000080000cee <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cee:	1141                	addi	sp,sp,-16
    80000cf0:	e422                	sd	s0,8(sp)
    80000cf2:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cf4:	ca05                	beqz	a2,80000d24 <memcmp+0x36>
    80000cf6:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000cfa:	1682                	slli	a3,a3,0x20
    80000cfc:	9281                	srli	a3,a3,0x20
    80000cfe:	0685                	addi	a3,a3,1
    80000d00:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d02:	00054783          	lbu	a5,0(a0)
    80000d06:	0005c703          	lbu	a4,0(a1)
    80000d0a:	00e79863          	bne	a5,a4,80000d1a <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d0e:	0505                	addi	a0,a0,1
    80000d10:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d12:	fed518e3          	bne	a0,a3,80000d02 <memcmp+0x14>
  }

  return 0;
    80000d16:	4501                	li	a0,0
    80000d18:	a019                	j	80000d1e <memcmp+0x30>
      return *s1 - *s2;
    80000d1a:	40e7853b          	subw	a0,a5,a4
}
    80000d1e:	6422                	ld	s0,8(sp)
    80000d20:	0141                	addi	sp,sp,16
    80000d22:	8082                	ret
  return 0;
    80000d24:	4501                	li	a0,0
    80000d26:	bfe5                	j	80000d1e <memcmp+0x30>

0000000080000d28 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d28:	1141                	addi	sp,sp,-16
    80000d2a:	e422                	sd	s0,8(sp)
    80000d2c:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d2e:	c205                	beqz	a2,80000d4e <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d30:	02a5e263          	bltu	a1,a0,80000d54 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d34:	1602                	slli	a2,a2,0x20
    80000d36:	9201                	srli	a2,a2,0x20
    80000d38:	00c587b3          	add	a5,a1,a2
{
    80000d3c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d3e:	0585                	addi	a1,a1,1
    80000d40:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffd9001>
    80000d42:	fff5c683          	lbu	a3,-1(a1)
    80000d46:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d4a:	fef59ae3          	bne	a1,a5,80000d3e <memmove+0x16>

  return dst;
}
    80000d4e:	6422                	ld	s0,8(sp)
    80000d50:	0141                	addi	sp,sp,16
    80000d52:	8082                	ret
  if(s < d && s + n > d){
    80000d54:	02061693          	slli	a3,a2,0x20
    80000d58:	9281                	srli	a3,a3,0x20
    80000d5a:	00d58733          	add	a4,a1,a3
    80000d5e:	fce57be3          	bgeu	a0,a4,80000d34 <memmove+0xc>
    d += n;
    80000d62:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d64:	fff6079b          	addiw	a5,a2,-1
    80000d68:	1782                	slli	a5,a5,0x20
    80000d6a:	9381                	srli	a5,a5,0x20
    80000d6c:	fff7c793          	not	a5,a5
    80000d70:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d72:	177d                	addi	a4,a4,-1
    80000d74:	16fd                	addi	a3,a3,-1
    80000d76:	00074603          	lbu	a2,0(a4)
    80000d7a:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d7e:	fee79ae3          	bne	a5,a4,80000d72 <memmove+0x4a>
    80000d82:	b7f1                	j	80000d4e <memmove+0x26>

0000000080000d84 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d84:	1141                	addi	sp,sp,-16
    80000d86:	e406                	sd	ra,8(sp)
    80000d88:	e022                	sd	s0,0(sp)
    80000d8a:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d8c:	00000097          	auipc	ra,0x0
    80000d90:	f9c080e7          	jalr	-100(ra) # 80000d28 <memmove>
}
    80000d94:	60a2                	ld	ra,8(sp)
    80000d96:	6402                	ld	s0,0(sp)
    80000d98:	0141                	addi	sp,sp,16
    80000d9a:	8082                	ret

0000000080000d9c <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d9c:	1141                	addi	sp,sp,-16
    80000d9e:	e422                	sd	s0,8(sp)
    80000da0:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da2:	ce11                	beqz	a2,80000dbe <strncmp+0x22>
    80000da4:	00054783          	lbu	a5,0(a0)
    80000da8:	cf89                	beqz	a5,80000dc2 <strncmp+0x26>
    80000daa:	0005c703          	lbu	a4,0(a1)
    80000dae:	00f71a63          	bne	a4,a5,80000dc2 <strncmp+0x26>
    n--, p++, q++;
    80000db2:	367d                	addiw	a2,a2,-1
    80000db4:	0505                	addi	a0,a0,1
    80000db6:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000db8:	f675                	bnez	a2,80000da4 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dba:	4501                	li	a0,0
    80000dbc:	a809                	j	80000dce <strncmp+0x32>
    80000dbe:	4501                	li	a0,0
    80000dc0:	a039                	j	80000dce <strncmp+0x32>
  if(n == 0)
    80000dc2:	ca09                	beqz	a2,80000dd4 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dc4:	00054503          	lbu	a0,0(a0)
    80000dc8:	0005c783          	lbu	a5,0(a1)
    80000dcc:	9d1d                	subw	a0,a0,a5
}
    80000dce:	6422                	ld	s0,8(sp)
    80000dd0:	0141                	addi	sp,sp,16
    80000dd2:	8082                	ret
    return 0;
    80000dd4:	4501                	li	a0,0
    80000dd6:	bfe5                	j	80000dce <strncmp+0x32>

0000000080000dd8 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dd8:	1141                	addi	sp,sp,-16
    80000dda:	e422                	sd	s0,8(sp)
    80000ddc:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dde:	872a                	mv	a4,a0
    80000de0:	8832                	mv	a6,a2
    80000de2:	367d                	addiw	a2,a2,-1
    80000de4:	01005963          	blez	a6,80000df6 <strncpy+0x1e>
    80000de8:	0705                	addi	a4,a4,1
    80000dea:	0005c783          	lbu	a5,0(a1)
    80000dee:	fef70fa3          	sb	a5,-1(a4)
    80000df2:	0585                	addi	a1,a1,1
    80000df4:	f7f5                	bnez	a5,80000de0 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df6:	86ba                	mv	a3,a4
    80000df8:	00c05c63          	blez	a2,80000e10 <strncpy+0x38>
    *s++ = 0;
    80000dfc:	0685                	addi	a3,a3,1
    80000dfe:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e02:	40d707bb          	subw	a5,a4,a3
    80000e06:	37fd                	addiw	a5,a5,-1
    80000e08:	010787bb          	addw	a5,a5,a6
    80000e0c:	fef048e3          	bgtz	a5,80000dfc <strncpy+0x24>
  return os;
}
    80000e10:	6422                	ld	s0,8(sp)
    80000e12:	0141                	addi	sp,sp,16
    80000e14:	8082                	ret

0000000080000e16 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e16:	1141                	addi	sp,sp,-16
    80000e18:	e422                	sd	s0,8(sp)
    80000e1a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e1c:	02c05363          	blez	a2,80000e42 <safestrcpy+0x2c>
    80000e20:	fff6069b          	addiw	a3,a2,-1
    80000e24:	1682                	slli	a3,a3,0x20
    80000e26:	9281                	srli	a3,a3,0x20
    80000e28:	96ae                	add	a3,a3,a1
    80000e2a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e2c:	00d58963          	beq	a1,a3,80000e3e <safestrcpy+0x28>
    80000e30:	0585                	addi	a1,a1,1
    80000e32:	0785                	addi	a5,a5,1
    80000e34:	fff5c703          	lbu	a4,-1(a1)
    80000e38:	fee78fa3          	sb	a4,-1(a5)
    80000e3c:	fb65                	bnez	a4,80000e2c <safestrcpy+0x16>
    ;
  *s = 0;
    80000e3e:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e42:	6422                	ld	s0,8(sp)
    80000e44:	0141                	addi	sp,sp,16
    80000e46:	8082                	ret

0000000080000e48 <strlen>:

int
strlen(const char *s)
{
    80000e48:	1141                	addi	sp,sp,-16
    80000e4a:	e422                	sd	s0,8(sp)
    80000e4c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e4e:	00054783          	lbu	a5,0(a0)
    80000e52:	cf91                	beqz	a5,80000e6e <strlen+0x26>
    80000e54:	0505                	addi	a0,a0,1
    80000e56:	87aa                	mv	a5,a0
    80000e58:	4685                	li	a3,1
    80000e5a:	9e89                	subw	a3,a3,a0
    80000e5c:	00f6853b          	addw	a0,a3,a5
    80000e60:	0785                	addi	a5,a5,1
    80000e62:	fff7c703          	lbu	a4,-1(a5)
    80000e66:	fb7d                	bnez	a4,80000e5c <strlen+0x14>
    ;
  return n;
}
    80000e68:	6422                	ld	s0,8(sp)
    80000e6a:	0141                	addi	sp,sp,16
    80000e6c:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e6e:	4501                	li	a0,0
    80000e70:	bfe5                	j	80000e68 <strlen+0x20>

0000000080000e72 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e72:	1141                	addi	sp,sp,-16
    80000e74:	e406                	sd	ra,8(sp)
    80000e76:	e022                	sd	s0,0(sp)
    80000e78:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e7a:	00001097          	auipc	ra,0x1
    80000e7e:	af0080e7          	jalr	-1296(ra) # 8000196a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e82:	00008717          	auipc	a4,0x8
    80000e86:	19670713          	addi	a4,a4,406 # 80009018 <started>
  if(cpuid() == 0){
    80000e8a:	c139                	beqz	a0,80000ed0 <main+0x5e>
    while(started == 0)
    80000e8c:	431c                	lw	a5,0(a4)
    80000e8e:	2781                	sext.w	a5,a5
    80000e90:	dff5                	beqz	a5,80000e8c <main+0x1a>
      ;
    __sync_synchronize();
    80000e92:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	ad4080e7          	jalr	-1324(ra) # 8000196a <cpuid>
    80000e9e:	85aa                	mv	a1,a0
    80000ea0:	00007517          	auipc	a0,0x7
    80000ea4:	21850513          	addi	a0,a0,536 # 800080b8 <digits+0x78>
    80000ea8:	fffff097          	auipc	ra,0xfffff
    80000eac:	6dc080e7          	jalr	1756(ra) # 80000584 <printf>
    kvminithart();    // turn on paging
    80000eb0:	00000097          	auipc	ra,0x0
    80000eb4:	0d8080e7          	jalr	216(ra) # 80000f88 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb8:	00002097          	auipc	ra,0x2
    80000ebc:	b7a080e7          	jalr	-1158(ra) # 80002a32 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	1d0080e7          	jalr	464(ra) # 80006090 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	09a080e7          	jalr	154(ra) # 80001f62 <scheduler>
    consoleinit();
    80000ed0:	fffff097          	auipc	ra,0xfffff
    80000ed4:	57a080e7          	jalr	1402(ra) # 8000044a <consoleinit>
    printfinit();
    80000ed8:	00000097          	auipc	ra,0x0
    80000edc:	88c080e7          	jalr	-1908(ra) # 80000764 <printfinit>
    printf("\n");
    80000ee0:	00007517          	auipc	a0,0x7
    80000ee4:	1e850513          	addi	a0,a0,488 # 800080c8 <digits+0x88>
    80000ee8:	fffff097          	auipc	ra,0xfffff
    80000eec:	69c080e7          	jalr	1692(ra) # 80000584 <printf>
    printf("xv6 kernel is booting\n");
    80000ef0:	00007517          	auipc	a0,0x7
    80000ef4:	1b050513          	addi	a0,a0,432 # 800080a0 <digits+0x60>
    80000ef8:	fffff097          	auipc	ra,0xfffff
    80000efc:	68c080e7          	jalr	1676(ra) # 80000584 <printf>
    printf("\n");
    80000f00:	00007517          	auipc	a0,0x7
    80000f04:	1c850513          	addi	a0,a0,456 # 800080c8 <digits+0x88>
    80000f08:	fffff097          	auipc	ra,0xfffff
    80000f0c:	67c080e7          	jalr	1660(ra) # 80000584 <printf>
    kinit();         // physical page allocator
    80000f10:	00000097          	auipc	ra,0x0
    80000f14:	b94080e7          	jalr	-1132(ra) # 80000aa4 <kinit>
    kvminit();       // create kernel page table
    80000f18:	00000097          	auipc	ra,0x0
    80000f1c:	322080e7          	jalr	802(ra) # 8000123a <kvminit>
    kvminithart();   // turn on paging
    80000f20:	00000097          	auipc	ra,0x0
    80000f24:	068080e7          	jalr	104(ra) # 80000f88 <kvminithart>
    procinit();      // process table
    80000f28:	00001097          	auipc	ra,0x1
    80000f2c:	992080e7          	jalr	-1646(ra) # 800018ba <procinit>
    trapinit();      // trap vectors
    80000f30:	00002097          	auipc	ra,0x2
    80000f34:	ada080e7          	jalr	-1318(ra) # 80002a0a <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00002097          	auipc	ra,0x2
    80000f3c:	afa080e7          	jalr	-1286(ra) # 80002a32 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	13a080e7          	jalr	314(ra) # 8000607a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	148080e7          	jalr	328(ra) # 80006090 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	308080e7          	jalr	776(ra) # 80003258 <binit>
    iinit();         // inode table
    80000f58:	00003097          	auipc	ra,0x3
    80000f5c:	996080e7          	jalr	-1642(ra) # 800038ee <iinit>
    fileinit();      // file table
    80000f60:	00004097          	auipc	ra,0x4
    80000f64:	948080e7          	jalr	-1720(ra) # 800048a8 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	248080e7          	jalr	584(ra) # 800061b0 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	d34080e7          	jalr	-716(ra) # 80001ca4 <userinit>
    __sync_synchronize();
    80000f78:	0ff0000f          	fence
    started = 1;
    80000f7c:	4785                	li	a5,1
    80000f7e:	00008717          	auipc	a4,0x8
    80000f82:	08f72d23          	sw	a5,154(a4) # 80009018 <started>
    80000f86:	b789                	j	80000ec8 <main+0x56>

0000000080000f88 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f88:	1141                	addi	sp,sp,-16
    80000f8a:	e422                	sd	s0,8(sp)
    80000f8c:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000f8e:	00008797          	auipc	a5,0x8
    80000f92:	0927b783          	ld	a5,146(a5) # 80009020 <kernel_pagetable>
    80000f96:	83b1                	srli	a5,a5,0xc
    80000f98:	577d                	li	a4,-1
    80000f9a:	177e                	slli	a4,a4,0x3f
    80000f9c:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f9e:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fa2:	12000073          	sfence.vma
  sfence_vma();
}
    80000fa6:	6422                	ld	s0,8(sp)
    80000fa8:	0141                	addi	sp,sp,16
    80000faa:	8082                	ret

0000000080000fac <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fac:	7139                	addi	sp,sp,-64
    80000fae:	fc06                	sd	ra,56(sp)
    80000fb0:	f822                	sd	s0,48(sp)
    80000fb2:	f426                	sd	s1,40(sp)
    80000fb4:	f04a                	sd	s2,32(sp)
    80000fb6:	ec4e                	sd	s3,24(sp)
    80000fb8:	e852                	sd	s4,16(sp)
    80000fba:	e456                	sd	s5,8(sp)
    80000fbc:	e05a                	sd	s6,0(sp)
    80000fbe:	0080                	addi	s0,sp,64
    80000fc0:	84aa                	mv	s1,a0
    80000fc2:	89ae                	mv	s3,a1
    80000fc4:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fc6:	57fd                	li	a5,-1
    80000fc8:	83e9                	srli	a5,a5,0x1a
    80000fca:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fcc:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fce:	04b7f263          	bgeu	a5,a1,80001012 <walk+0x66>
    panic("walk");
    80000fd2:	00007517          	auipc	a0,0x7
    80000fd6:	0fe50513          	addi	a0,a0,254 # 800080d0 <digits+0x90>
    80000fda:	fffff097          	auipc	ra,0xfffff
    80000fde:	560080e7          	jalr	1376(ra) # 8000053a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fe2:	060a8663          	beqz	s5,8000104e <walk+0xa2>
    80000fe6:	00000097          	auipc	ra,0x0
    80000fea:	afa080e7          	jalr	-1286(ra) # 80000ae0 <kalloc>
    80000fee:	84aa                	mv	s1,a0
    80000ff0:	c529                	beqz	a0,8000103a <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ff2:	6605                	lui	a2,0x1
    80000ff4:	4581                	li	a1,0
    80000ff6:	00000097          	auipc	ra,0x0
    80000ffa:	cd6080e7          	jalr	-810(ra) # 80000ccc <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000ffe:	00c4d793          	srli	a5,s1,0xc
    80001002:	07aa                	slli	a5,a5,0xa
    80001004:	0017e793          	ori	a5,a5,1
    80001008:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000100c:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffd8ff7>
    8000100e:	036a0063          	beq	s4,s6,8000102e <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001012:	0149d933          	srl	s2,s3,s4
    80001016:	1ff97913          	andi	s2,s2,511
    8000101a:	090e                	slli	s2,s2,0x3
    8000101c:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000101e:	00093483          	ld	s1,0(s2)
    80001022:	0014f793          	andi	a5,s1,1
    80001026:	dfd5                	beqz	a5,80000fe2 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001028:	80a9                	srli	s1,s1,0xa
    8000102a:	04b2                	slli	s1,s1,0xc
    8000102c:	b7c5                	j	8000100c <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000102e:	00c9d513          	srli	a0,s3,0xc
    80001032:	1ff57513          	andi	a0,a0,511
    80001036:	050e                	slli	a0,a0,0x3
    80001038:	9526                	add	a0,a0,s1
}
    8000103a:	70e2                	ld	ra,56(sp)
    8000103c:	7442                	ld	s0,48(sp)
    8000103e:	74a2                	ld	s1,40(sp)
    80001040:	7902                	ld	s2,32(sp)
    80001042:	69e2                	ld	s3,24(sp)
    80001044:	6a42                	ld	s4,16(sp)
    80001046:	6aa2                	ld	s5,8(sp)
    80001048:	6b02                	ld	s6,0(sp)
    8000104a:	6121                	addi	sp,sp,64
    8000104c:	8082                	ret
        return 0;
    8000104e:	4501                	li	a0,0
    80001050:	b7ed                	j	8000103a <walk+0x8e>

0000000080001052 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001052:	57fd                	li	a5,-1
    80001054:	83e9                	srli	a5,a5,0x1a
    80001056:	00b7f463          	bgeu	a5,a1,8000105e <walkaddr+0xc>
    return 0;
    8000105a:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000105c:	8082                	ret
{
    8000105e:	1141                	addi	sp,sp,-16
    80001060:	e406                	sd	ra,8(sp)
    80001062:	e022                	sd	s0,0(sp)
    80001064:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001066:	4601                	li	a2,0
    80001068:	00000097          	auipc	ra,0x0
    8000106c:	f44080e7          	jalr	-188(ra) # 80000fac <walk>
  if(pte == 0)
    80001070:	c105                	beqz	a0,80001090 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001072:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001074:	0117f693          	andi	a3,a5,17
    80001078:	4745                	li	a4,17
    return 0;
    8000107a:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000107c:	00e68663          	beq	a3,a4,80001088 <walkaddr+0x36>
}
    80001080:	60a2                	ld	ra,8(sp)
    80001082:	6402                	ld	s0,0(sp)
    80001084:	0141                	addi	sp,sp,16
    80001086:	8082                	ret
  pa = PTE2PA(*pte);
    80001088:	83a9                	srli	a5,a5,0xa
    8000108a:	00c79513          	slli	a0,a5,0xc
  return pa;
    8000108e:	bfcd                	j	80001080 <walkaddr+0x2e>
    return 0;
    80001090:	4501                	li	a0,0
    80001092:	b7fd                	j	80001080 <walkaddr+0x2e>

0000000080001094 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001094:	715d                	addi	sp,sp,-80
    80001096:	e486                	sd	ra,72(sp)
    80001098:	e0a2                	sd	s0,64(sp)
    8000109a:	fc26                	sd	s1,56(sp)
    8000109c:	f84a                	sd	s2,48(sp)
    8000109e:	f44e                	sd	s3,40(sp)
    800010a0:	f052                	sd	s4,32(sp)
    800010a2:	ec56                	sd	s5,24(sp)
    800010a4:	e85a                	sd	s6,16(sp)
    800010a6:	e45e                	sd	s7,8(sp)
    800010a8:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010aa:	c639                	beqz	a2,800010f8 <mappages+0x64>
    800010ac:	8aaa                	mv	s5,a0
    800010ae:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010b0:	777d                	lui	a4,0xfffff
    800010b2:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010b6:	fff58993          	addi	s3,a1,-1
    800010ba:	99b2                	add	s3,s3,a2
    800010bc:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010c0:	893e                	mv	s2,a5
    800010c2:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010c6:	6b85                	lui	s7,0x1
    800010c8:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010cc:	4605                	li	a2,1
    800010ce:	85ca                	mv	a1,s2
    800010d0:	8556                	mv	a0,s5
    800010d2:	00000097          	auipc	ra,0x0
    800010d6:	eda080e7          	jalr	-294(ra) # 80000fac <walk>
    800010da:	cd1d                	beqz	a0,80001118 <mappages+0x84>
    if(*pte & PTE_V)
    800010dc:	611c                	ld	a5,0(a0)
    800010de:	8b85                	andi	a5,a5,1
    800010e0:	e785                	bnez	a5,80001108 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010e2:	80b1                	srli	s1,s1,0xc
    800010e4:	04aa                	slli	s1,s1,0xa
    800010e6:	0164e4b3          	or	s1,s1,s6
    800010ea:	0014e493          	ori	s1,s1,1
    800010ee:	e104                	sd	s1,0(a0)
    if(a == last)
    800010f0:	05390063          	beq	s2,s3,80001130 <mappages+0x9c>
    a += PGSIZE;
    800010f4:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010f6:	bfc9                	j	800010c8 <mappages+0x34>
    panic("mappages: size");
    800010f8:	00007517          	auipc	a0,0x7
    800010fc:	fe050513          	addi	a0,a0,-32 # 800080d8 <digits+0x98>
    80001100:	fffff097          	auipc	ra,0xfffff
    80001104:	43a080e7          	jalr	1082(ra) # 8000053a <panic>
      panic("mappages: remap");
    80001108:	00007517          	auipc	a0,0x7
    8000110c:	fe050513          	addi	a0,a0,-32 # 800080e8 <digits+0xa8>
    80001110:	fffff097          	auipc	ra,0xfffff
    80001114:	42a080e7          	jalr	1066(ra) # 8000053a <panic>
      return -1;
    80001118:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000111a:	60a6                	ld	ra,72(sp)
    8000111c:	6406                	ld	s0,64(sp)
    8000111e:	74e2                	ld	s1,56(sp)
    80001120:	7942                	ld	s2,48(sp)
    80001122:	79a2                	ld	s3,40(sp)
    80001124:	7a02                	ld	s4,32(sp)
    80001126:	6ae2                	ld	s5,24(sp)
    80001128:	6b42                	ld	s6,16(sp)
    8000112a:	6ba2                	ld	s7,8(sp)
    8000112c:	6161                	addi	sp,sp,80
    8000112e:	8082                	ret
  return 0;
    80001130:	4501                	li	a0,0
    80001132:	b7e5                	j	8000111a <mappages+0x86>

0000000080001134 <kvmmap>:
{
    80001134:	1141                	addi	sp,sp,-16
    80001136:	e406                	sd	ra,8(sp)
    80001138:	e022                	sd	s0,0(sp)
    8000113a:	0800                	addi	s0,sp,16
    8000113c:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000113e:	86b2                	mv	a3,a2
    80001140:	863e                	mv	a2,a5
    80001142:	00000097          	auipc	ra,0x0
    80001146:	f52080e7          	jalr	-174(ra) # 80001094 <mappages>
    8000114a:	e509                	bnez	a0,80001154 <kvmmap+0x20>
}
    8000114c:	60a2                	ld	ra,8(sp)
    8000114e:	6402                	ld	s0,0(sp)
    80001150:	0141                	addi	sp,sp,16
    80001152:	8082                	ret
    panic("kvmmap");
    80001154:	00007517          	auipc	a0,0x7
    80001158:	fa450513          	addi	a0,a0,-92 # 800080f8 <digits+0xb8>
    8000115c:	fffff097          	auipc	ra,0xfffff
    80001160:	3de080e7          	jalr	990(ra) # 8000053a <panic>

0000000080001164 <kvmmake>:
{
    80001164:	1101                	addi	sp,sp,-32
    80001166:	ec06                	sd	ra,24(sp)
    80001168:	e822                	sd	s0,16(sp)
    8000116a:	e426                	sd	s1,8(sp)
    8000116c:	e04a                	sd	s2,0(sp)
    8000116e:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001170:	00000097          	auipc	ra,0x0
    80001174:	970080e7          	jalr	-1680(ra) # 80000ae0 <kalloc>
    80001178:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000117a:	6605                	lui	a2,0x1
    8000117c:	4581                	li	a1,0
    8000117e:	00000097          	auipc	ra,0x0
    80001182:	b4e080e7          	jalr	-1202(ra) # 80000ccc <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001186:	4719                	li	a4,6
    80001188:	6685                	lui	a3,0x1
    8000118a:	10000637          	lui	a2,0x10000
    8000118e:	100005b7          	lui	a1,0x10000
    80001192:	8526                	mv	a0,s1
    80001194:	00000097          	auipc	ra,0x0
    80001198:	fa0080e7          	jalr	-96(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000119c:	4719                	li	a4,6
    8000119e:	6685                	lui	a3,0x1
    800011a0:	10001637          	lui	a2,0x10001
    800011a4:	100015b7          	lui	a1,0x10001
    800011a8:	8526                	mv	a0,s1
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	f8a080e7          	jalr	-118(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011b2:	4719                	li	a4,6
    800011b4:	004006b7          	lui	a3,0x400
    800011b8:	0c000637          	lui	a2,0xc000
    800011bc:	0c0005b7          	lui	a1,0xc000
    800011c0:	8526                	mv	a0,s1
    800011c2:	00000097          	auipc	ra,0x0
    800011c6:	f72080e7          	jalr	-142(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ca:	00007917          	auipc	s2,0x7
    800011ce:	e3690913          	addi	s2,s2,-458 # 80008000 <etext>
    800011d2:	4729                	li	a4,10
    800011d4:	80007697          	auipc	a3,0x80007
    800011d8:	e2c68693          	addi	a3,a3,-468 # 8000 <_entry-0x7fff8000>
    800011dc:	4605                	li	a2,1
    800011de:	067e                	slli	a2,a2,0x1f
    800011e0:	85b2                	mv	a1,a2
    800011e2:	8526                	mv	a0,s1
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	f50080e7          	jalr	-176(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011ec:	4719                	li	a4,6
    800011ee:	46c5                	li	a3,17
    800011f0:	06ee                	slli	a3,a3,0x1b
    800011f2:	412686b3          	sub	a3,a3,s2
    800011f6:	864a                	mv	a2,s2
    800011f8:	85ca                	mv	a1,s2
    800011fa:	8526                	mv	a0,s1
    800011fc:	00000097          	auipc	ra,0x0
    80001200:	f38080e7          	jalr	-200(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001204:	4729                	li	a4,10
    80001206:	6685                	lui	a3,0x1
    80001208:	00006617          	auipc	a2,0x6
    8000120c:	df860613          	addi	a2,a2,-520 # 80007000 <_trampoline>
    80001210:	040005b7          	lui	a1,0x4000
    80001214:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001216:	05b2                	slli	a1,a1,0xc
    80001218:	8526                	mv	a0,s1
    8000121a:	00000097          	auipc	ra,0x0
    8000121e:	f1a080e7          	jalr	-230(ra) # 80001134 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	600080e7          	jalr	1536(ra) # 80001824 <proc_mapstacks>
}
    8000122c:	8526                	mv	a0,s1
    8000122e:	60e2                	ld	ra,24(sp)
    80001230:	6442                	ld	s0,16(sp)
    80001232:	64a2                	ld	s1,8(sp)
    80001234:	6902                	ld	s2,0(sp)
    80001236:	6105                	addi	sp,sp,32
    80001238:	8082                	ret

000000008000123a <kvminit>:
{
    8000123a:	1141                	addi	sp,sp,-16
    8000123c:	e406                	sd	ra,8(sp)
    8000123e:	e022                	sd	s0,0(sp)
    80001240:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001242:	00000097          	auipc	ra,0x0
    80001246:	f22080e7          	jalr	-222(ra) # 80001164 <kvmmake>
    8000124a:	00008797          	auipc	a5,0x8
    8000124e:	dca7bb23          	sd	a0,-554(a5) # 80009020 <kernel_pagetable>
}
    80001252:	60a2                	ld	ra,8(sp)
    80001254:	6402                	ld	s0,0(sp)
    80001256:	0141                	addi	sp,sp,16
    80001258:	8082                	ret

000000008000125a <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000125a:	715d                	addi	sp,sp,-80
    8000125c:	e486                	sd	ra,72(sp)
    8000125e:	e0a2                	sd	s0,64(sp)
    80001260:	fc26                	sd	s1,56(sp)
    80001262:	f84a                	sd	s2,48(sp)
    80001264:	f44e                	sd	s3,40(sp)
    80001266:	f052                	sd	s4,32(sp)
    80001268:	ec56                	sd	s5,24(sp)
    8000126a:	e85a                	sd	s6,16(sp)
    8000126c:	e45e                	sd	s7,8(sp)
    8000126e:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001270:	03459793          	slli	a5,a1,0x34
    80001274:	e795                	bnez	a5,800012a0 <uvmunmap+0x46>
    80001276:	8a2a                	mv	s4,a0
    80001278:	892e                	mv	s2,a1
    8000127a:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000127c:	0632                	slli	a2,a2,0xc
    8000127e:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001282:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001284:	6b05                	lui	s6,0x1
    80001286:	0735e263          	bltu	a1,s3,800012ea <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000128a:	60a6                	ld	ra,72(sp)
    8000128c:	6406                	ld	s0,64(sp)
    8000128e:	74e2                	ld	s1,56(sp)
    80001290:	7942                	ld	s2,48(sp)
    80001292:	79a2                	ld	s3,40(sp)
    80001294:	7a02                	ld	s4,32(sp)
    80001296:	6ae2                	ld	s5,24(sp)
    80001298:	6b42                	ld	s6,16(sp)
    8000129a:	6ba2                	ld	s7,8(sp)
    8000129c:	6161                	addi	sp,sp,80
    8000129e:	8082                	ret
    panic("uvmunmap: not aligned");
    800012a0:	00007517          	auipc	a0,0x7
    800012a4:	e6050513          	addi	a0,a0,-416 # 80008100 <digits+0xc0>
    800012a8:	fffff097          	auipc	ra,0xfffff
    800012ac:	292080e7          	jalr	658(ra) # 8000053a <panic>
      panic("uvmunmap: walk");
    800012b0:	00007517          	auipc	a0,0x7
    800012b4:	e6850513          	addi	a0,a0,-408 # 80008118 <digits+0xd8>
    800012b8:	fffff097          	auipc	ra,0xfffff
    800012bc:	282080e7          	jalr	642(ra) # 8000053a <panic>
      panic("uvmunmap: not mapped");
    800012c0:	00007517          	auipc	a0,0x7
    800012c4:	e6850513          	addi	a0,a0,-408 # 80008128 <digits+0xe8>
    800012c8:	fffff097          	auipc	ra,0xfffff
    800012cc:	272080e7          	jalr	626(ra) # 8000053a <panic>
      panic("uvmunmap: not a leaf");
    800012d0:	00007517          	auipc	a0,0x7
    800012d4:	e7050513          	addi	a0,a0,-400 # 80008140 <digits+0x100>
    800012d8:	fffff097          	auipc	ra,0xfffff
    800012dc:	262080e7          	jalr	610(ra) # 8000053a <panic>
    *pte = 0;
    800012e0:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e4:	995a                	add	s2,s2,s6
    800012e6:	fb3972e3          	bgeu	s2,s3,8000128a <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012ea:	4601                	li	a2,0
    800012ec:	85ca                	mv	a1,s2
    800012ee:	8552                	mv	a0,s4
    800012f0:	00000097          	auipc	ra,0x0
    800012f4:	cbc080e7          	jalr	-836(ra) # 80000fac <walk>
    800012f8:	84aa                	mv	s1,a0
    800012fa:	d95d                	beqz	a0,800012b0 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800012fc:	6108                	ld	a0,0(a0)
    800012fe:	00157793          	andi	a5,a0,1
    80001302:	dfdd                	beqz	a5,800012c0 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001304:	3ff57793          	andi	a5,a0,1023
    80001308:	fd7784e3          	beq	a5,s7,800012d0 <uvmunmap+0x76>
    if(do_free){
    8000130c:	fc0a8ae3          	beqz	s5,800012e0 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001310:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001312:	0532                	slli	a0,a0,0xc
    80001314:	fffff097          	auipc	ra,0xfffff
    80001318:	6ce080e7          	jalr	1742(ra) # 800009e2 <kfree>
    8000131c:	b7d1                	j	800012e0 <uvmunmap+0x86>

000000008000131e <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000131e:	1101                	addi	sp,sp,-32
    80001320:	ec06                	sd	ra,24(sp)
    80001322:	e822                	sd	s0,16(sp)
    80001324:	e426                	sd	s1,8(sp)
    80001326:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001328:	fffff097          	auipc	ra,0xfffff
    8000132c:	7b8080e7          	jalr	1976(ra) # 80000ae0 <kalloc>
    80001330:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001332:	c519                	beqz	a0,80001340 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001334:	6605                	lui	a2,0x1
    80001336:	4581                	li	a1,0
    80001338:	00000097          	auipc	ra,0x0
    8000133c:	994080e7          	jalr	-1644(ra) # 80000ccc <memset>
  return pagetable;
}
    80001340:	8526                	mv	a0,s1
    80001342:	60e2                	ld	ra,24(sp)
    80001344:	6442                	ld	s0,16(sp)
    80001346:	64a2                	ld	s1,8(sp)
    80001348:	6105                	addi	sp,sp,32
    8000134a:	8082                	ret

000000008000134c <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000134c:	7179                	addi	sp,sp,-48
    8000134e:	f406                	sd	ra,40(sp)
    80001350:	f022                	sd	s0,32(sp)
    80001352:	ec26                	sd	s1,24(sp)
    80001354:	e84a                	sd	s2,16(sp)
    80001356:	e44e                	sd	s3,8(sp)
    80001358:	e052                	sd	s4,0(sp)
    8000135a:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000135c:	6785                	lui	a5,0x1
    8000135e:	04f67863          	bgeu	a2,a5,800013ae <uvminit+0x62>
    80001362:	8a2a                	mv	s4,a0
    80001364:	89ae                	mv	s3,a1
    80001366:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001368:	fffff097          	auipc	ra,0xfffff
    8000136c:	778080e7          	jalr	1912(ra) # 80000ae0 <kalloc>
    80001370:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001372:	6605                	lui	a2,0x1
    80001374:	4581                	li	a1,0
    80001376:	00000097          	auipc	ra,0x0
    8000137a:	956080e7          	jalr	-1706(ra) # 80000ccc <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000137e:	4779                	li	a4,30
    80001380:	86ca                	mv	a3,s2
    80001382:	6605                	lui	a2,0x1
    80001384:	4581                	li	a1,0
    80001386:	8552                	mv	a0,s4
    80001388:	00000097          	auipc	ra,0x0
    8000138c:	d0c080e7          	jalr	-756(ra) # 80001094 <mappages>
  memmove(mem, src, sz);
    80001390:	8626                	mv	a2,s1
    80001392:	85ce                	mv	a1,s3
    80001394:	854a                	mv	a0,s2
    80001396:	00000097          	auipc	ra,0x0
    8000139a:	992080e7          	jalr	-1646(ra) # 80000d28 <memmove>
}
    8000139e:	70a2                	ld	ra,40(sp)
    800013a0:	7402                	ld	s0,32(sp)
    800013a2:	64e2                	ld	s1,24(sp)
    800013a4:	6942                	ld	s2,16(sp)
    800013a6:	69a2                	ld	s3,8(sp)
    800013a8:	6a02                	ld	s4,0(sp)
    800013aa:	6145                	addi	sp,sp,48
    800013ac:	8082                	ret
    panic("inituvm: more than a page");
    800013ae:	00007517          	auipc	a0,0x7
    800013b2:	daa50513          	addi	a0,a0,-598 # 80008158 <digits+0x118>
    800013b6:	fffff097          	auipc	ra,0xfffff
    800013ba:	184080e7          	jalr	388(ra) # 8000053a <panic>

00000000800013be <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013be:	1101                	addi	sp,sp,-32
    800013c0:	ec06                	sd	ra,24(sp)
    800013c2:	e822                	sd	s0,16(sp)
    800013c4:	e426                	sd	s1,8(sp)
    800013c6:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013c8:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ca:	00b67d63          	bgeu	a2,a1,800013e4 <uvmdealloc+0x26>
    800013ce:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013d0:	6785                	lui	a5,0x1
    800013d2:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013d4:	00f60733          	add	a4,a2,a5
    800013d8:	76fd                	lui	a3,0xfffff
    800013da:	8f75                	and	a4,a4,a3
    800013dc:	97ae                	add	a5,a5,a1
    800013de:	8ff5                	and	a5,a5,a3
    800013e0:	00f76863          	bltu	a4,a5,800013f0 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013e4:	8526                	mv	a0,s1
    800013e6:	60e2                	ld	ra,24(sp)
    800013e8:	6442                	ld	s0,16(sp)
    800013ea:	64a2                	ld	s1,8(sp)
    800013ec:	6105                	addi	sp,sp,32
    800013ee:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013f0:	8f99                	sub	a5,a5,a4
    800013f2:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013f4:	4685                	li	a3,1
    800013f6:	0007861b          	sext.w	a2,a5
    800013fa:	85ba                	mv	a1,a4
    800013fc:	00000097          	auipc	ra,0x0
    80001400:	e5e080e7          	jalr	-418(ra) # 8000125a <uvmunmap>
    80001404:	b7c5                	j	800013e4 <uvmdealloc+0x26>

0000000080001406 <uvmalloc>:
  if(newsz < oldsz)
    80001406:	0ab66163          	bltu	a2,a1,800014a8 <uvmalloc+0xa2>
{
    8000140a:	7139                	addi	sp,sp,-64
    8000140c:	fc06                	sd	ra,56(sp)
    8000140e:	f822                	sd	s0,48(sp)
    80001410:	f426                	sd	s1,40(sp)
    80001412:	f04a                	sd	s2,32(sp)
    80001414:	ec4e                	sd	s3,24(sp)
    80001416:	e852                	sd	s4,16(sp)
    80001418:	e456                	sd	s5,8(sp)
    8000141a:	0080                	addi	s0,sp,64
    8000141c:	8aaa                	mv	s5,a0
    8000141e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001420:	6785                	lui	a5,0x1
    80001422:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001424:	95be                	add	a1,a1,a5
    80001426:	77fd                	lui	a5,0xfffff
    80001428:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000142c:	08c9f063          	bgeu	s3,a2,800014ac <uvmalloc+0xa6>
    80001430:	894e                	mv	s2,s3
    mem = kalloc();
    80001432:	fffff097          	auipc	ra,0xfffff
    80001436:	6ae080e7          	jalr	1710(ra) # 80000ae0 <kalloc>
    8000143a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000143c:	c51d                	beqz	a0,8000146a <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000143e:	6605                	lui	a2,0x1
    80001440:	4581                	li	a1,0
    80001442:	00000097          	auipc	ra,0x0
    80001446:	88a080e7          	jalr	-1910(ra) # 80000ccc <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000144a:	4779                	li	a4,30
    8000144c:	86a6                	mv	a3,s1
    8000144e:	6605                	lui	a2,0x1
    80001450:	85ca                	mv	a1,s2
    80001452:	8556                	mv	a0,s5
    80001454:	00000097          	auipc	ra,0x0
    80001458:	c40080e7          	jalr	-960(ra) # 80001094 <mappages>
    8000145c:	e905                	bnez	a0,8000148c <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000145e:	6785                	lui	a5,0x1
    80001460:	993e                	add	s2,s2,a5
    80001462:	fd4968e3          	bltu	s2,s4,80001432 <uvmalloc+0x2c>
  return newsz;
    80001466:	8552                	mv	a0,s4
    80001468:	a809                	j	8000147a <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000146a:	864e                	mv	a2,s3
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	f4e080e7          	jalr	-178(ra) # 800013be <uvmdealloc>
      return 0;
    80001478:	4501                	li	a0,0
}
    8000147a:	70e2                	ld	ra,56(sp)
    8000147c:	7442                	ld	s0,48(sp)
    8000147e:	74a2                	ld	s1,40(sp)
    80001480:	7902                	ld	s2,32(sp)
    80001482:	69e2                	ld	s3,24(sp)
    80001484:	6a42                	ld	s4,16(sp)
    80001486:	6aa2                	ld	s5,8(sp)
    80001488:	6121                	addi	sp,sp,64
    8000148a:	8082                	ret
      kfree(mem);
    8000148c:	8526                	mv	a0,s1
    8000148e:	fffff097          	auipc	ra,0xfffff
    80001492:	554080e7          	jalr	1364(ra) # 800009e2 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001496:	864e                	mv	a2,s3
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	f22080e7          	jalr	-222(ra) # 800013be <uvmdealloc>
      return 0;
    800014a4:	4501                	li	a0,0
    800014a6:	bfd1                	j	8000147a <uvmalloc+0x74>
    return oldsz;
    800014a8:	852e                	mv	a0,a1
}
    800014aa:	8082                	ret
  return newsz;
    800014ac:	8532                	mv	a0,a2
    800014ae:	b7f1                	j	8000147a <uvmalloc+0x74>

00000000800014b0 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014b0:	7179                	addi	sp,sp,-48
    800014b2:	f406                	sd	ra,40(sp)
    800014b4:	f022                	sd	s0,32(sp)
    800014b6:	ec26                	sd	s1,24(sp)
    800014b8:	e84a                	sd	s2,16(sp)
    800014ba:	e44e                	sd	s3,8(sp)
    800014bc:	e052                	sd	s4,0(sp)
    800014be:	1800                	addi	s0,sp,48
    800014c0:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014c2:	84aa                	mv	s1,a0
    800014c4:	6905                	lui	s2,0x1
    800014c6:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014c8:	4985                	li	s3,1
    800014ca:	a829                	j	800014e4 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014cc:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014ce:	00c79513          	slli	a0,a5,0xc
    800014d2:	00000097          	auipc	ra,0x0
    800014d6:	fde080e7          	jalr	-34(ra) # 800014b0 <freewalk>
      pagetable[i] = 0;
    800014da:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014de:	04a1                	addi	s1,s1,8
    800014e0:	03248163          	beq	s1,s2,80001502 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014e4:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e6:	00f7f713          	andi	a4,a5,15
    800014ea:	ff3701e3          	beq	a4,s3,800014cc <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014ee:	8b85                	andi	a5,a5,1
    800014f0:	d7fd                	beqz	a5,800014de <freewalk+0x2e>
      panic("freewalk: leaf");
    800014f2:	00007517          	auipc	a0,0x7
    800014f6:	c8650513          	addi	a0,a0,-890 # 80008178 <digits+0x138>
    800014fa:	fffff097          	auipc	ra,0xfffff
    800014fe:	040080e7          	jalr	64(ra) # 8000053a <panic>
    }
  }
  kfree((void*)pagetable);
    80001502:	8552                	mv	a0,s4
    80001504:	fffff097          	auipc	ra,0xfffff
    80001508:	4de080e7          	jalr	1246(ra) # 800009e2 <kfree>
}
    8000150c:	70a2                	ld	ra,40(sp)
    8000150e:	7402                	ld	s0,32(sp)
    80001510:	64e2                	ld	s1,24(sp)
    80001512:	6942                	ld	s2,16(sp)
    80001514:	69a2                	ld	s3,8(sp)
    80001516:	6a02                	ld	s4,0(sp)
    80001518:	6145                	addi	sp,sp,48
    8000151a:	8082                	ret

000000008000151c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000151c:	1101                	addi	sp,sp,-32
    8000151e:	ec06                	sd	ra,24(sp)
    80001520:	e822                	sd	s0,16(sp)
    80001522:	e426                	sd	s1,8(sp)
    80001524:	1000                	addi	s0,sp,32
    80001526:	84aa                	mv	s1,a0
  if(sz > 0)
    80001528:	e999                	bnez	a1,8000153e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000152a:	8526                	mv	a0,s1
    8000152c:	00000097          	auipc	ra,0x0
    80001530:	f84080e7          	jalr	-124(ra) # 800014b0 <freewalk>
}
    80001534:	60e2                	ld	ra,24(sp)
    80001536:	6442                	ld	s0,16(sp)
    80001538:	64a2                	ld	s1,8(sp)
    8000153a:	6105                	addi	sp,sp,32
    8000153c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000153e:	6785                	lui	a5,0x1
    80001540:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001542:	95be                	add	a1,a1,a5
    80001544:	4685                	li	a3,1
    80001546:	00c5d613          	srli	a2,a1,0xc
    8000154a:	4581                	li	a1,0
    8000154c:	00000097          	auipc	ra,0x0
    80001550:	d0e080e7          	jalr	-754(ra) # 8000125a <uvmunmap>
    80001554:	bfd9                	j	8000152a <uvmfree+0xe>

0000000080001556 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001556:	c679                	beqz	a2,80001624 <uvmcopy+0xce>
{
    80001558:	715d                	addi	sp,sp,-80
    8000155a:	e486                	sd	ra,72(sp)
    8000155c:	e0a2                	sd	s0,64(sp)
    8000155e:	fc26                	sd	s1,56(sp)
    80001560:	f84a                	sd	s2,48(sp)
    80001562:	f44e                	sd	s3,40(sp)
    80001564:	f052                	sd	s4,32(sp)
    80001566:	ec56                	sd	s5,24(sp)
    80001568:	e85a                	sd	s6,16(sp)
    8000156a:	e45e                	sd	s7,8(sp)
    8000156c:	0880                	addi	s0,sp,80
    8000156e:	8b2a                	mv	s6,a0
    80001570:	8aae                	mv	s5,a1
    80001572:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001574:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001576:	4601                	li	a2,0
    80001578:	85ce                	mv	a1,s3
    8000157a:	855a                	mv	a0,s6
    8000157c:	00000097          	auipc	ra,0x0
    80001580:	a30080e7          	jalr	-1488(ra) # 80000fac <walk>
    80001584:	c531                	beqz	a0,800015d0 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001586:	6118                	ld	a4,0(a0)
    80001588:	00177793          	andi	a5,a4,1
    8000158c:	cbb1                	beqz	a5,800015e0 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000158e:	00a75593          	srli	a1,a4,0xa
    80001592:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001596:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000159a:	fffff097          	auipc	ra,0xfffff
    8000159e:	546080e7          	jalr	1350(ra) # 80000ae0 <kalloc>
    800015a2:	892a                	mv	s2,a0
    800015a4:	c939                	beqz	a0,800015fa <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015a6:	6605                	lui	a2,0x1
    800015a8:	85de                	mv	a1,s7
    800015aa:	fffff097          	auipc	ra,0xfffff
    800015ae:	77e080e7          	jalr	1918(ra) # 80000d28 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015b2:	8726                	mv	a4,s1
    800015b4:	86ca                	mv	a3,s2
    800015b6:	6605                	lui	a2,0x1
    800015b8:	85ce                	mv	a1,s3
    800015ba:	8556                	mv	a0,s5
    800015bc:	00000097          	auipc	ra,0x0
    800015c0:	ad8080e7          	jalr	-1320(ra) # 80001094 <mappages>
    800015c4:	e515                	bnez	a0,800015f0 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015c6:	6785                	lui	a5,0x1
    800015c8:	99be                	add	s3,s3,a5
    800015ca:	fb49e6e3          	bltu	s3,s4,80001576 <uvmcopy+0x20>
    800015ce:	a081                	j	8000160e <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015d0:	00007517          	auipc	a0,0x7
    800015d4:	bb850513          	addi	a0,a0,-1096 # 80008188 <digits+0x148>
    800015d8:	fffff097          	auipc	ra,0xfffff
    800015dc:	f62080e7          	jalr	-158(ra) # 8000053a <panic>
      panic("uvmcopy: page not present");
    800015e0:	00007517          	auipc	a0,0x7
    800015e4:	bc850513          	addi	a0,a0,-1080 # 800081a8 <digits+0x168>
    800015e8:	fffff097          	auipc	ra,0xfffff
    800015ec:	f52080e7          	jalr	-174(ra) # 8000053a <panic>
      kfree(mem);
    800015f0:	854a                	mv	a0,s2
    800015f2:	fffff097          	auipc	ra,0xfffff
    800015f6:	3f0080e7          	jalr	1008(ra) # 800009e2 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015fa:	4685                	li	a3,1
    800015fc:	00c9d613          	srli	a2,s3,0xc
    80001600:	4581                	li	a1,0
    80001602:	8556                	mv	a0,s5
    80001604:	00000097          	auipc	ra,0x0
    80001608:	c56080e7          	jalr	-938(ra) # 8000125a <uvmunmap>
  return -1;
    8000160c:	557d                	li	a0,-1
}
    8000160e:	60a6                	ld	ra,72(sp)
    80001610:	6406                	ld	s0,64(sp)
    80001612:	74e2                	ld	s1,56(sp)
    80001614:	7942                	ld	s2,48(sp)
    80001616:	79a2                	ld	s3,40(sp)
    80001618:	7a02                	ld	s4,32(sp)
    8000161a:	6ae2                	ld	s5,24(sp)
    8000161c:	6b42                	ld	s6,16(sp)
    8000161e:	6ba2                	ld	s7,8(sp)
    80001620:	6161                	addi	sp,sp,80
    80001622:	8082                	ret
  return 0;
    80001624:	4501                	li	a0,0
}
    80001626:	8082                	ret

0000000080001628 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001628:	1141                	addi	sp,sp,-16
    8000162a:	e406                	sd	ra,8(sp)
    8000162c:	e022                	sd	s0,0(sp)
    8000162e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001630:	4601                	li	a2,0
    80001632:	00000097          	auipc	ra,0x0
    80001636:	97a080e7          	jalr	-1670(ra) # 80000fac <walk>
  if(pte == 0)
    8000163a:	c901                	beqz	a0,8000164a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000163c:	611c                	ld	a5,0(a0)
    8000163e:	9bbd                	andi	a5,a5,-17
    80001640:	e11c                	sd	a5,0(a0)
}
    80001642:	60a2                	ld	ra,8(sp)
    80001644:	6402                	ld	s0,0(sp)
    80001646:	0141                	addi	sp,sp,16
    80001648:	8082                	ret
    panic("uvmclear");
    8000164a:	00007517          	auipc	a0,0x7
    8000164e:	b7e50513          	addi	a0,a0,-1154 # 800081c8 <digits+0x188>
    80001652:	fffff097          	auipc	ra,0xfffff
    80001656:	ee8080e7          	jalr	-280(ra) # 8000053a <panic>

000000008000165a <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000165a:	c6bd                	beqz	a3,800016c8 <copyout+0x6e>
{
    8000165c:	715d                	addi	sp,sp,-80
    8000165e:	e486                	sd	ra,72(sp)
    80001660:	e0a2                	sd	s0,64(sp)
    80001662:	fc26                	sd	s1,56(sp)
    80001664:	f84a                	sd	s2,48(sp)
    80001666:	f44e                	sd	s3,40(sp)
    80001668:	f052                	sd	s4,32(sp)
    8000166a:	ec56                	sd	s5,24(sp)
    8000166c:	e85a                	sd	s6,16(sp)
    8000166e:	e45e                	sd	s7,8(sp)
    80001670:	e062                	sd	s8,0(sp)
    80001672:	0880                	addi	s0,sp,80
    80001674:	8b2a                	mv	s6,a0
    80001676:	8c2e                	mv	s8,a1
    80001678:	8a32                	mv	s4,a2
    8000167a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000167c:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000167e:	6a85                	lui	s5,0x1
    80001680:	a015                	j	800016a4 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001682:	9562                	add	a0,a0,s8
    80001684:	0004861b          	sext.w	a2,s1
    80001688:	85d2                	mv	a1,s4
    8000168a:	41250533          	sub	a0,a0,s2
    8000168e:	fffff097          	auipc	ra,0xfffff
    80001692:	69a080e7          	jalr	1690(ra) # 80000d28 <memmove>

    len -= n;
    80001696:	409989b3          	sub	s3,s3,s1
    src += n;
    8000169a:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000169c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016a0:	02098263          	beqz	s3,800016c4 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016a4:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016a8:	85ca                	mv	a1,s2
    800016aa:	855a                	mv	a0,s6
    800016ac:	00000097          	auipc	ra,0x0
    800016b0:	9a6080e7          	jalr	-1626(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    800016b4:	cd01                	beqz	a0,800016cc <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016b6:	418904b3          	sub	s1,s2,s8
    800016ba:	94d6                	add	s1,s1,s5
    800016bc:	fc99f3e3          	bgeu	s3,s1,80001682 <copyout+0x28>
    800016c0:	84ce                	mv	s1,s3
    800016c2:	b7c1                	j	80001682 <copyout+0x28>
  }
  return 0;
    800016c4:	4501                	li	a0,0
    800016c6:	a021                	j	800016ce <copyout+0x74>
    800016c8:	4501                	li	a0,0
}
    800016ca:	8082                	ret
      return -1;
    800016cc:	557d                	li	a0,-1
}
    800016ce:	60a6                	ld	ra,72(sp)
    800016d0:	6406                	ld	s0,64(sp)
    800016d2:	74e2                	ld	s1,56(sp)
    800016d4:	7942                	ld	s2,48(sp)
    800016d6:	79a2                	ld	s3,40(sp)
    800016d8:	7a02                	ld	s4,32(sp)
    800016da:	6ae2                	ld	s5,24(sp)
    800016dc:	6b42                	ld	s6,16(sp)
    800016de:	6ba2                	ld	s7,8(sp)
    800016e0:	6c02                	ld	s8,0(sp)
    800016e2:	6161                	addi	sp,sp,80
    800016e4:	8082                	ret

00000000800016e6 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016e6:	caa5                	beqz	a3,80001756 <copyin+0x70>
{
    800016e8:	715d                	addi	sp,sp,-80
    800016ea:	e486                	sd	ra,72(sp)
    800016ec:	e0a2                	sd	s0,64(sp)
    800016ee:	fc26                	sd	s1,56(sp)
    800016f0:	f84a                	sd	s2,48(sp)
    800016f2:	f44e                	sd	s3,40(sp)
    800016f4:	f052                	sd	s4,32(sp)
    800016f6:	ec56                	sd	s5,24(sp)
    800016f8:	e85a                	sd	s6,16(sp)
    800016fa:	e45e                	sd	s7,8(sp)
    800016fc:	e062                	sd	s8,0(sp)
    800016fe:	0880                	addi	s0,sp,80
    80001700:	8b2a                	mv	s6,a0
    80001702:	8a2e                	mv	s4,a1
    80001704:	8c32                	mv	s8,a2
    80001706:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001708:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000170a:	6a85                	lui	s5,0x1
    8000170c:	a01d                	j	80001732 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000170e:	018505b3          	add	a1,a0,s8
    80001712:	0004861b          	sext.w	a2,s1
    80001716:	412585b3          	sub	a1,a1,s2
    8000171a:	8552                	mv	a0,s4
    8000171c:	fffff097          	auipc	ra,0xfffff
    80001720:	60c080e7          	jalr	1548(ra) # 80000d28 <memmove>

    len -= n;
    80001724:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001728:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000172a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000172e:	02098263          	beqz	s3,80001752 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001732:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001736:	85ca                	mv	a1,s2
    80001738:	855a                	mv	a0,s6
    8000173a:	00000097          	auipc	ra,0x0
    8000173e:	918080e7          	jalr	-1768(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    80001742:	cd01                	beqz	a0,8000175a <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001744:	418904b3          	sub	s1,s2,s8
    80001748:	94d6                	add	s1,s1,s5
    8000174a:	fc99f2e3          	bgeu	s3,s1,8000170e <copyin+0x28>
    8000174e:	84ce                	mv	s1,s3
    80001750:	bf7d                	j	8000170e <copyin+0x28>
  }
  return 0;
    80001752:	4501                	li	a0,0
    80001754:	a021                	j	8000175c <copyin+0x76>
    80001756:	4501                	li	a0,0
}
    80001758:	8082                	ret
      return -1;
    8000175a:	557d                	li	a0,-1
}
    8000175c:	60a6                	ld	ra,72(sp)
    8000175e:	6406                	ld	s0,64(sp)
    80001760:	74e2                	ld	s1,56(sp)
    80001762:	7942                	ld	s2,48(sp)
    80001764:	79a2                	ld	s3,40(sp)
    80001766:	7a02                	ld	s4,32(sp)
    80001768:	6ae2                	ld	s5,24(sp)
    8000176a:	6b42                	ld	s6,16(sp)
    8000176c:	6ba2                	ld	s7,8(sp)
    8000176e:	6c02                	ld	s8,0(sp)
    80001770:	6161                	addi	sp,sp,80
    80001772:	8082                	ret

0000000080001774 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001774:	c2dd                	beqz	a3,8000181a <copyinstr+0xa6>
{
    80001776:	715d                	addi	sp,sp,-80
    80001778:	e486                	sd	ra,72(sp)
    8000177a:	e0a2                	sd	s0,64(sp)
    8000177c:	fc26                	sd	s1,56(sp)
    8000177e:	f84a                	sd	s2,48(sp)
    80001780:	f44e                	sd	s3,40(sp)
    80001782:	f052                	sd	s4,32(sp)
    80001784:	ec56                	sd	s5,24(sp)
    80001786:	e85a                	sd	s6,16(sp)
    80001788:	e45e                	sd	s7,8(sp)
    8000178a:	0880                	addi	s0,sp,80
    8000178c:	8a2a                	mv	s4,a0
    8000178e:	8b2e                	mv	s6,a1
    80001790:	8bb2                	mv	s7,a2
    80001792:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001794:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001796:	6985                	lui	s3,0x1
    80001798:	a02d                	j	800017c2 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000179a:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000179e:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017a0:	37fd                	addiw	a5,a5,-1
    800017a2:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017a6:	60a6                	ld	ra,72(sp)
    800017a8:	6406                	ld	s0,64(sp)
    800017aa:	74e2                	ld	s1,56(sp)
    800017ac:	7942                	ld	s2,48(sp)
    800017ae:	79a2                	ld	s3,40(sp)
    800017b0:	7a02                	ld	s4,32(sp)
    800017b2:	6ae2                	ld	s5,24(sp)
    800017b4:	6b42                	ld	s6,16(sp)
    800017b6:	6ba2                	ld	s7,8(sp)
    800017b8:	6161                	addi	sp,sp,80
    800017ba:	8082                	ret
    srcva = va0 + PGSIZE;
    800017bc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017c0:	c8a9                	beqz	s1,80001812 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017c2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017c6:	85ca                	mv	a1,s2
    800017c8:	8552                	mv	a0,s4
    800017ca:	00000097          	auipc	ra,0x0
    800017ce:	888080e7          	jalr	-1912(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    800017d2:	c131                	beqz	a0,80001816 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017d4:	417906b3          	sub	a3,s2,s7
    800017d8:	96ce                	add	a3,a3,s3
    800017da:	00d4f363          	bgeu	s1,a3,800017e0 <copyinstr+0x6c>
    800017de:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017e0:	955e                	add	a0,a0,s7
    800017e2:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017e6:	daf9                	beqz	a3,800017bc <copyinstr+0x48>
    800017e8:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017ea:	41650633          	sub	a2,a0,s6
    800017ee:	fff48593          	addi	a1,s1,-1
    800017f2:	95da                	add	a1,a1,s6
    while(n > 0){
    800017f4:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    800017f6:	00f60733          	add	a4,a2,a5
    800017fa:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    800017fe:	df51                	beqz	a4,8000179a <copyinstr+0x26>
        *dst = *p;
    80001800:	00e78023          	sb	a4,0(a5)
      --max;
    80001804:	40f584b3          	sub	s1,a1,a5
      dst++;
    80001808:	0785                	addi	a5,a5,1
    while(n > 0){
    8000180a:	fed796e3          	bne	a5,a3,800017f6 <copyinstr+0x82>
      dst++;
    8000180e:	8b3e                	mv	s6,a5
    80001810:	b775                	j	800017bc <copyinstr+0x48>
    80001812:	4781                	li	a5,0
    80001814:	b771                	j	800017a0 <copyinstr+0x2c>
      return -1;
    80001816:	557d                	li	a0,-1
    80001818:	b779                	j	800017a6 <copyinstr+0x32>
  int got_null = 0;
    8000181a:	4781                	li	a5,0
  if(got_null){
    8000181c:	37fd                	addiw	a5,a5,-1
    8000181e:	0007851b          	sext.w	a0,a5
}
    80001822:	8082                	ret

0000000080001824 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001824:	7139                	addi	sp,sp,-64
    80001826:	fc06                	sd	ra,56(sp)
    80001828:	f822                	sd	s0,48(sp)
    8000182a:	f426                	sd	s1,40(sp)
    8000182c:	f04a                	sd	s2,32(sp)
    8000182e:	ec4e                	sd	s3,24(sp)
    80001830:	e852                	sd	s4,16(sp)
    80001832:	e456                	sd	s5,8(sp)
    80001834:	e05a                	sd	s6,0(sp)
    80001836:	0080                	addi	s0,sp,64
    80001838:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000183a:	00010497          	auipc	s1,0x10
    8000183e:	e9648493          	addi	s1,s1,-362 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001842:	8b26                	mv	s6,s1
    80001844:	00006a97          	auipc	s5,0x6
    80001848:	7bca8a93          	addi	s5,s5,1980 # 80008000 <etext>
    8000184c:	04000937          	lui	s2,0x4000
    80001850:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001852:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001854:	00016a17          	auipc	s4,0x16
    80001858:	c7ca0a13          	addi	s4,s4,-900 # 800174d0 <tickslock>
    char *pa = kalloc();
    8000185c:	fffff097          	auipc	ra,0xfffff
    80001860:	284080e7          	jalr	644(ra) # 80000ae0 <kalloc>
    80001864:	862a                	mv	a2,a0
    if(pa == 0)
    80001866:	c131                	beqz	a0,800018aa <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001868:	416485b3          	sub	a1,s1,s6
    8000186c:	858d                	srai	a1,a1,0x3
    8000186e:	000ab783          	ld	a5,0(s5)
    80001872:	02f585b3          	mul	a1,a1,a5
    80001876:	2585                	addiw	a1,a1,1
    80001878:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000187c:	4719                	li	a4,6
    8000187e:	6685                	lui	a3,0x1
    80001880:	40b905b3          	sub	a1,s2,a1
    80001884:	854e                	mv	a0,s3
    80001886:	00000097          	auipc	ra,0x0
    8000188a:	8ae080e7          	jalr	-1874(ra) # 80001134 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000188e:	17848493          	addi	s1,s1,376
    80001892:	fd4495e3          	bne	s1,s4,8000185c <proc_mapstacks+0x38>
  }
}
    80001896:	70e2                	ld	ra,56(sp)
    80001898:	7442                	ld	s0,48(sp)
    8000189a:	74a2                	ld	s1,40(sp)
    8000189c:	7902                	ld	s2,32(sp)
    8000189e:	69e2                	ld	s3,24(sp)
    800018a0:	6a42                	ld	s4,16(sp)
    800018a2:	6aa2                	ld	s5,8(sp)
    800018a4:	6b02                	ld	s6,0(sp)
    800018a6:	6121                	addi	sp,sp,64
    800018a8:	8082                	ret
      panic("kalloc");
    800018aa:	00007517          	auipc	a0,0x7
    800018ae:	92e50513          	addi	a0,a0,-1746 # 800081d8 <digits+0x198>
    800018b2:	fffff097          	auipc	ra,0xfffff
    800018b6:	c88080e7          	jalr	-888(ra) # 8000053a <panic>

00000000800018ba <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018ba:	7139                	addi	sp,sp,-64
    800018bc:	fc06                	sd	ra,56(sp)
    800018be:	f822                	sd	s0,48(sp)
    800018c0:	f426                	sd	s1,40(sp)
    800018c2:	f04a                	sd	s2,32(sp)
    800018c4:	ec4e                	sd	s3,24(sp)
    800018c6:	e852                	sd	s4,16(sp)
    800018c8:	e456                	sd	s5,8(sp)
    800018ca:	e05a                	sd	s6,0(sp)
    800018cc:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018ce:	00007597          	auipc	a1,0x7
    800018d2:	91258593          	addi	a1,a1,-1774 # 800081e0 <digits+0x1a0>
    800018d6:	00010517          	auipc	a0,0x10
    800018da:	9ca50513          	addi	a0,a0,-1590 # 800112a0 <pid_lock>
    800018de:	fffff097          	auipc	ra,0xfffff
    800018e2:	262080e7          	jalr	610(ra) # 80000b40 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018e6:	00007597          	auipc	a1,0x7
    800018ea:	90258593          	addi	a1,a1,-1790 # 800081e8 <digits+0x1a8>
    800018ee:	00010517          	auipc	a0,0x10
    800018f2:	9ca50513          	addi	a0,a0,-1590 # 800112b8 <wait_lock>
    800018f6:	fffff097          	auipc	ra,0xfffff
    800018fa:	24a080e7          	jalr	586(ra) # 80000b40 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018fe:	00010497          	auipc	s1,0x10
    80001902:	dd248493          	addi	s1,s1,-558 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001906:	00007b17          	auipc	s6,0x7
    8000190a:	8f2b0b13          	addi	s6,s6,-1806 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    8000190e:	8aa6                	mv	s5,s1
    80001910:	00006a17          	auipc	s4,0x6
    80001914:	6f0a0a13          	addi	s4,s4,1776 # 80008000 <etext>
    80001918:	04000937          	lui	s2,0x4000
    8000191c:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    8000191e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001920:	00016997          	auipc	s3,0x16
    80001924:	bb098993          	addi	s3,s3,-1104 # 800174d0 <tickslock>
      initlock(&p->lock, "proc");
    80001928:	85da                	mv	a1,s6
    8000192a:	8526                	mv	a0,s1
    8000192c:	fffff097          	auipc	ra,0xfffff
    80001930:	214080e7          	jalr	532(ra) # 80000b40 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001934:	415487b3          	sub	a5,s1,s5
    80001938:	878d                	srai	a5,a5,0x3
    8000193a:	000a3703          	ld	a4,0(s4)
    8000193e:	02e787b3          	mul	a5,a5,a4
    80001942:	2785                	addiw	a5,a5,1
    80001944:	00d7979b          	slliw	a5,a5,0xd
    80001948:	40f907b3          	sub	a5,s2,a5
    8000194c:	e8bc                	sd	a5,80(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194e:	17848493          	addi	s1,s1,376
    80001952:	fd349be3          	bne	s1,s3,80001928 <procinit+0x6e>
  }
}
    80001956:	70e2                	ld	ra,56(sp)
    80001958:	7442                	ld	s0,48(sp)
    8000195a:	74a2                	ld	s1,40(sp)
    8000195c:	7902                	ld	s2,32(sp)
    8000195e:	69e2                	ld	s3,24(sp)
    80001960:	6a42                	ld	s4,16(sp)
    80001962:	6aa2                	ld	s5,8(sp)
    80001964:	6b02                	ld	s6,0(sp)
    80001966:	6121                	addi	sp,sp,64
    80001968:	8082                	ret

000000008000196a <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    8000196a:	1141                	addi	sp,sp,-16
    8000196c:	e422                	sd	s0,8(sp)
    8000196e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001970:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001972:	2501                	sext.w	a0,a0
    80001974:	6422                	ld	s0,8(sp)
    80001976:	0141                	addi	sp,sp,16
    80001978:	8082                	ret

000000008000197a <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    8000197a:	1141                	addi	sp,sp,-16
    8000197c:	e422                	sd	s0,8(sp)
    8000197e:	0800                	addi	s0,sp,16
    80001980:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001982:	2781                	sext.w	a5,a5
    80001984:	079e                	slli	a5,a5,0x7
  return c;
}
    80001986:	00010517          	auipc	a0,0x10
    8000198a:	94a50513          	addi	a0,a0,-1718 # 800112d0 <cpus>
    8000198e:	953e                	add	a0,a0,a5
    80001990:	6422                	ld	s0,8(sp)
    80001992:	0141                	addi	sp,sp,16
    80001994:	8082                	ret

0000000080001996 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001996:	1101                	addi	sp,sp,-32
    80001998:	ec06                	sd	ra,24(sp)
    8000199a:	e822                	sd	s0,16(sp)
    8000199c:	e426                	sd	s1,8(sp)
    8000199e:	1000                	addi	s0,sp,32
  push_off();
    800019a0:	fffff097          	auipc	ra,0xfffff
    800019a4:	1e4080e7          	jalr	484(ra) # 80000b84 <push_off>
    800019a8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019aa:	2781                	sext.w	a5,a5
    800019ac:	079e                	slli	a5,a5,0x7
    800019ae:	00010717          	auipc	a4,0x10
    800019b2:	8f270713          	addi	a4,a4,-1806 # 800112a0 <pid_lock>
    800019b6:	97ba                	add	a5,a5,a4
    800019b8:	7b84                	ld	s1,48(a5)
  pop_off();
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	26a080e7          	jalr	618(ra) # 80000c24 <pop_off>
  return p;
}
    800019c2:	8526                	mv	a0,s1
    800019c4:	60e2                	ld	ra,24(sp)
    800019c6:	6442                	ld	s0,16(sp)
    800019c8:	64a2                	ld	s1,8(sp)
    800019ca:	6105                	addi	sp,sp,32
    800019cc:	8082                	ret

00000000800019ce <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019ce:	1101                	addi	sp,sp,-32
    800019d0:	ec06                	sd	ra,24(sp)
    800019d2:	e822                	sd	s0,16(sp)
    800019d4:	e426                	sd	s1,8(sp)
    800019d6:	1000                	addi	s0,sp,32
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019d8:	00000097          	auipc	ra,0x0
    800019dc:	fbe080e7          	jalr	-66(ra) # 80001996 <myproc>
    800019e0:	fffff097          	auipc	ra,0xfffff
    800019e4:	2a4080e7          	jalr	676(ra) # 80000c84 <release>

  if (first) {
    800019e8:	00007797          	auipc	a5,0x7
    800019ec:	ed87a783          	lw	a5,-296(a5) # 800088c0 <first.2>
    800019f0:	eb91                	bnez	a5,80001a04 <forkret+0x36>
    release(&tickslock);

    fsinit(ROOTDEV);
  }

  usertrapret();
    800019f2:	00001097          	auipc	ra,0x1
    800019f6:	058080e7          	jalr	88(ra) # 80002a4a <usertrapret>
}
    800019fa:	60e2                	ld	ra,24(sp)
    800019fc:	6442                	ld	s0,16(sp)
    800019fe:	64a2                	ld	s1,8(sp)
    80001a00:	6105                	addi	sp,sp,32
    80001a02:	8082                	ret
    first = 0;
    80001a04:	00007797          	auipc	a5,0x7
    80001a08:	ea07ae23          	sw	zero,-324(a5) # 800088c0 <first.2>
    acquire(&tickslock);
    80001a0c:	00016517          	auipc	a0,0x16
    80001a10:	ac450513          	addi	a0,a0,-1340 # 800174d0 <tickslock>
    80001a14:	fffff097          	auipc	ra,0xfffff
    80001a18:	1bc080e7          	jalr	444(ra) # 80000bd0 <acquire>
    myproc()->stime = ticks;
    80001a1c:	00007497          	auipc	s1,0x7
    80001a20:	6144a483          	lw	s1,1556(s1) # 80009030 <ticks>
    80001a24:	00000097          	auipc	ra,0x0
    80001a28:	f72080e7          	jalr	-142(ra) # 80001996 <myproc>
    80001a2c:	c164                	sw	s1,68(a0)
    release(&tickslock);
    80001a2e:	00016517          	auipc	a0,0x16
    80001a32:	aa250513          	addi	a0,a0,-1374 # 800174d0 <tickslock>
    80001a36:	fffff097          	auipc	ra,0xfffff
    80001a3a:	24e080e7          	jalr	590(ra) # 80000c84 <release>
    fsinit(ROOTDEV);
    80001a3e:	4505                	li	a0,1
    80001a40:	00002097          	auipc	ra,0x2
    80001a44:	e2e080e7          	jalr	-466(ra) # 8000386e <fsinit>
    80001a48:	b76d                	j	800019f2 <forkret+0x24>

0000000080001a4a <allocpid>:
allocpid() {
    80001a4a:	1101                	addi	sp,sp,-32
    80001a4c:	ec06                	sd	ra,24(sp)
    80001a4e:	e822                	sd	s0,16(sp)
    80001a50:	e426                	sd	s1,8(sp)
    80001a52:	e04a                	sd	s2,0(sp)
    80001a54:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a56:	00010917          	auipc	s2,0x10
    80001a5a:	84a90913          	addi	s2,s2,-1974 # 800112a0 <pid_lock>
    80001a5e:	854a                	mv	a0,s2
    80001a60:	fffff097          	auipc	ra,0xfffff
    80001a64:	170080e7          	jalr	368(ra) # 80000bd0 <acquire>
  pid = nextpid;
    80001a68:	00007797          	auipc	a5,0x7
    80001a6c:	e5c78793          	addi	a5,a5,-420 # 800088c4 <nextpid>
    80001a70:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a72:	0014871b          	addiw	a4,s1,1
    80001a76:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a78:	854a                	mv	a0,s2
    80001a7a:	fffff097          	auipc	ra,0xfffff
    80001a7e:	20a080e7          	jalr	522(ra) # 80000c84 <release>
}
    80001a82:	8526                	mv	a0,s1
    80001a84:	60e2                	ld	ra,24(sp)
    80001a86:	6442                	ld	s0,16(sp)
    80001a88:	64a2                	ld	s1,8(sp)
    80001a8a:	6902                	ld	s2,0(sp)
    80001a8c:	6105                	addi	sp,sp,32
    80001a8e:	8082                	ret

0000000080001a90 <proc_pagetable>:
{
    80001a90:	1101                	addi	sp,sp,-32
    80001a92:	ec06                	sd	ra,24(sp)
    80001a94:	e822                	sd	s0,16(sp)
    80001a96:	e426                	sd	s1,8(sp)
    80001a98:	e04a                	sd	s2,0(sp)
    80001a9a:	1000                	addi	s0,sp,32
    80001a9c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a9e:	00000097          	auipc	ra,0x0
    80001aa2:	880080e7          	jalr	-1920(ra) # 8000131e <uvmcreate>
    80001aa6:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001aa8:	c121                	beqz	a0,80001ae8 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aaa:	4729                	li	a4,10
    80001aac:	00005697          	auipc	a3,0x5
    80001ab0:	55468693          	addi	a3,a3,1364 # 80007000 <_trampoline>
    80001ab4:	6605                	lui	a2,0x1
    80001ab6:	040005b7          	lui	a1,0x4000
    80001aba:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001abc:	05b2                	slli	a1,a1,0xc
    80001abe:	fffff097          	auipc	ra,0xfffff
    80001ac2:	5d6080e7          	jalr	1494(ra) # 80001094 <mappages>
    80001ac6:	02054863          	bltz	a0,80001af6 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aca:	4719                	li	a4,6
    80001acc:	06893683          	ld	a3,104(s2)
    80001ad0:	6605                	lui	a2,0x1
    80001ad2:	020005b7          	lui	a1,0x2000
    80001ad6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ad8:	05b6                	slli	a1,a1,0xd
    80001ada:	8526                	mv	a0,s1
    80001adc:	fffff097          	auipc	ra,0xfffff
    80001ae0:	5b8080e7          	jalr	1464(ra) # 80001094 <mappages>
    80001ae4:	02054163          	bltz	a0,80001b06 <proc_pagetable+0x76>
}
    80001ae8:	8526                	mv	a0,s1
    80001aea:	60e2                	ld	ra,24(sp)
    80001aec:	6442                	ld	s0,16(sp)
    80001aee:	64a2                	ld	s1,8(sp)
    80001af0:	6902                	ld	s2,0(sp)
    80001af2:	6105                	addi	sp,sp,32
    80001af4:	8082                	ret
    uvmfree(pagetable, 0);
    80001af6:	4581                	li	a1,0
    80001af8:	8526                	mv	a0,s1
    80001afa:	00000097          	auipc	ra,0x0
    80001afe:	a22080e7          	jalr	-1502(ra) # 8000151c <uvmfree>
    return 0;
    80001b02:	4481                	li	s1,0
    80001b04:	b7d5                	j	80001ae8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b06:	4681                	li	a3,0
    80001b08:	4605                	li	a2,1
    80001b0a:	040005b7          	lui	a1,0x4000
    80001b0e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b10:	05b2                	slli	a1,a1,0xc
    80001b12:	8526                	mv	a0,s1
    80001b14:	fffff097          	auipc	ra,0xfffff
    80001b18:	746080e7          	jalr	1862(ra) # 8000125a <uvmunmap>
    uvmfree(pagetable, 0);
    80001b1c:	4581                	li	a1,0
    80001b1e:	8526                	mv	a0,s1
    80001b20:	00000097          	auipc	ra,0x0
    80001b24:	9fc080e7          	jalr	-1540(ra) # 8000151c <uvmfree>
    return 0;
    80001b28:	4481                	li	s1,0
    80001b2a:	bf7d                	j	80001ae8 <proc_pagetable+0x58>

0000000080001b2c <proc_freepagetable>:
{
    80001b2c:	1101                	addi	sp,sp,-32
    80001b2e:	ec06                	sd	ra,24(sp)
    80001b30:	e822                	sd	s0,16(sp)
    80001b32:	e426                	sd	s1,8(sp)
    80001b34:	e04a                	sd	s2,0(sp)
    80001b36:	1000                	addi	s0,sp,32
    80001b38:	84aa                	mv	s1,a0
    80001b3a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b3c:	4681                	li	a3,0
    80001b3e:	4605                	li	a2,1
    80001b40:	040005b7          	lui	a1,0x4000
    80001b44:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b46:	05b2                	slli	a1,a1,0xc
    80001b48:	fffff097          	auipc	ra,0xfffff
    80001b4c:	712080e7          	jalr	1810(ra) # 8000125a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b50:	4681                	li	a3,0
    80001b52:	4605                	li	a2,1
    80001b54:	020005b7          	lui	a1,0x2000
    80001b58:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b5a:	05b6                	slli	a1,a1,0xd
    80001b5c:	8526                	mv	a0,s1
    80001b5e:	fffff097          	auipc	ra,0xfffff
    80001b62:	6fc080e7          	jalr	1788(ra) # 8000125a <uvmunmap>
  uvmfree(pagetable, sz);
    80001b66:	85ca                	mv	a1,s2
    80001b68:	8526                	mv	a0,s1
    80001b6a:	00000097          	auipc	ra,0x0
    80001b6e:	9b2080e7          	jalr	-1614(ra) # 8000151c <uvmfree>
}
    80001b72:	60e2                	ld	ra,24(sp)
    80001b74:	6442                	ld	s0,16(sp)
    80001b76:	64a2                	ld	s1,8(sp)
    80001b78:	6902                	ld	s2,0(sp)
    80001b7a:	6105                	addi	sp,sp,32
    80001b7c:	8082                	ret

0000000080001b7e <freeproc>:
{
    80001b7e:	1101                	addi	sp,sp,-32
    80001b80:	ec06                	sd	ra,24(sp)
    80001b82:	e822                	sd	s0,16(sp)
    80001b84:	e426                	sd	s1,8(sp)
    80001b86:	1000                	addi	s0,sp,32
    80001b88:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b8a:	7528                	ld	a0,104(a0)
    80001b8c:	c509                	beqz	a0,80001b96 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b8e:	fffff097          	auipc	ra,0xfffff
    80001b92:	e54080e7          	jalr	-428(ra) # 800009e2 <kfree>
  p->trapframe = 0;
    80001b96:	0604b423          	sd	zero,104(s1)
  if(p->pagetable)
    80001b9a:	70a8                	ld	a0,96(s1)
    80001b9c:	c511                	beqz	a0,80001ba8 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b9e:	6cac                	ld	a1,88(s1)
    80001ba0:	00000097          	auipc	ra,0x0
    80001ba4:	f8c080e7          	jalr	-116(ra) # 80001b2c <proc_freepagetable>
  p->pagetable = 0;
    80001ba8:	0604b023          	sd	zero,96(s1)
  p->sz = 0;
    80001bac:	0404bc23          	sd	zero,88(s1)
  p->pid = 0;
    80001bb0:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bb4:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bb8:	16048423          	sb	zero,360(s1)
  p->chan = 0;
    80001bbc:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bc0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bc4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bc8:	0004ac23          	sw	zero,24(s1)
}
    80001bcc:	60e2                	ld	ra,24(sp)
    80001bce:	6442                	ld	s0,16(sp)
    80001bd0:	64a2                	ld	s1,8(sp)
    80001bd2:	6105                	addi	sp,sp,32
    80001bd4:	8082                	ret

0000000080001bd6 <allocproc>:
{
    80001bd6:	1101                	addi	sp,sp,-32
    80001bd8:	ec06                	sd	ra,24(sp)
    80001bda:	e822                	sd	s0,16(sp)
    80001bdc:	e426                	sd	s1,8(sp)
    80001bde:	e04a                	sd	s2,0(sp)
    80001be0:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001be2:	00010497          	auipc	s1,0x10
    80001be6:	aee48493          	addi	s1,s1,-1298 # 800116d0 <proc>
    80001bea:	00016917          	auipc	s2,0x16
    80001bee:	8e690913          	addi	s2,s2,-1818 # 800174d0 <tickslock>
    acquire(&p->lock);
    80001bf2:	8526                	mv	a0,s1
    80001bf4:	fffff097          	auipc	ra,0xfffff
    80001bf8:	fdc080e7          	jalr	-36(ra) # 80000bd0 <acquire>
    if(p->state == UNUSED) {
    80001bfc:	4c9c                	lw	a5,24(s1)
    80001bfe:	cf81                	beqz	a5,80001c16 <allocproc+0x40>
      release(&p->lock);
    80001c00:	8526                	mv	a0,s1
    80001c02:	fffff097          	auipc	ra,0xfffff
    80001c06:	082080e7          	jalr	130(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c0a:	17848493          	addi	s1,s1,376
    80001c0e:	ff2492e3          	bne	s1,s2,80001bf2 <allocproc+0x1c>
  return 0;
    80001c12:	4481                	li	s1,0
    80001c14:	a889                	j	80001c66 <allocproc+0x90>
  p->pid = allocpid();
    80001c16:	00000097          	auipc	ra,0x0
    80001c1a:	e34080e7          	jalr	-460(ra) # 80001a4a <allocpid>
    80001c1e:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c20:	4785                	li	a5,1
    80001c22:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c24:	fffff097          	auipc	ra,0xfffff
    80001c28:	ebc080e7          	jalr	-324(ra) # 80000ae0 <kalloc>
    80001c2c:	892a                	mv	s2,a0
    80001c2e:	f4a8                	sd	a0,104(s1)
    80001c30:	c131                	beqz	a0,80001c74 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c32:	8526                	mv	a0,s1
    80001c34:	00000097          	auipc	ra,0x0
    80001c38:	e5c080e7          	jalr	-420(ra) # 80001a90 <proc_pagetable>
    80001c3c:	892a                	mv	s2,a0
    80001c3e:	f0a8                	sd	a0,96(s1)
  if(p->pagetable == 0){
    80001c40:	c531                	beqz	a0,80001c8c <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c42:	07000613          	li	a2,112
    80001c46:	4581                	li	a1,0
    80001c48:	07048513          	addi	a0,s1,112
    80001c4c:	fffff097          	auipc	ra,0xfffff
    80001c50:	080080e7          	jalr	128(ra) # 80000ccc <memset>
  p->context.ra = (uint64)forkret;
    80001c54:	00000797          	auipc	a5,0x0
    80001c58:	d7a78793          	addi	a5,a5,-646 # 800019ce <forkret>
    80001c5c:	f8bc                	sd	a5,112(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c5e:	68bc                	ld	a5,80(s1)
    80001c60:	6705                	lui	a4,0x1
    80001c62:	97ba                	add	a5,a5,a4
    80001c64:	fcbc                	sd	a5,120(s1)
}
    80001c66:	8526                	mv	a0,s1
    80001c68:	60e2                	ld	ra,24(sp)
    80001c6a:	6442                	ld	s0,16(sp)
    80001c6c:	64a2                	ld	s1,8(sp)
    80001c6e:	6902                	ld	s2,0(sp)
    80001c70:	6105                	addi	sp,sp,32
    80001c72:	8082                	ret
    freeproc(p);
    80001c74:	8526                	mv	a0,s1
    80001c76:	00000097          	auipc	ra,0x0
    80001c7a:	f08080e7          	jalr	-248(ra) # 80001b7e <freeproc>
    release(&p->lock);
    80001c7e:	8526                	mv	a0,s1
    80001c80:	fffff097          	auipc	ra,0xfffff
    80001c84:	004080e7          	jalr	4(ra) # 80000c84 <release>
    return 0;
    80001c88:	84ca                	mv	s1,s2
    80001c8a:	bff1                	j	80001c66 <allocproc+0x90>
    freeproc(p);
    80001c8c:	8526                	mv	a0,s1
    80001c8e:	00000097          	auipc	ra,0x0
    80001c92:	ef0080e7          	jalr	-272(ra) # 80001b7e <freeproc>
    release(&p->lock);
    80001c96:	8526                	mv	a0,s1
    80001c98:	fffff097          	auipc	ra,0xfffff
    80001c9c:	fec080e7          	jalr	-20(ra) # 80000c84 <release>
    return 0;
    80001ca0:	84ca                	mv	s1,s2
    80001ca2:	b7d1                	j	80001c66 <allocproc+0x90>

0000000080001ca4 <userinit>:
{
    80001ca4:	1101                	addi	sp,sp,-32
    80001ca6:	ec06                	sd	ra,24(sp)
    80001ca8:	e822                	sd	s0,16(sp)
    80001caa:	e426                	sd	s1,8(sp)
    80001cac:	e04a                	sd	s2,0(sp)
    80001cae:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cb0:	00000097          	auipc	ra,0x0
    80001cb4:	f26080e7          	jalr	-218(ra) # 80001bd6 <allocproc>
    80001cb8:	84aa                	mv	s1,a0
  initproc = p;
    80001cba:	00007797          	auipc	a5,0x7
    80001cbe:	36a7b723          	sd	a0,878(a5) # 80009028 <initproc>
  acquire(&tickslock);
    80001cc2:	00016517          	auipc	a0,0x16
    80001cc6:	80e50513          	addi	a0,a0,-2034 # 800174d0 <tickslock>
    80001cca:	fffff097          	auipc	ra,0xfffff
    80001cce:	f06080e7          	jalr	-250(ra) # 80000bd0 <acquire>
  p->ctime = ticks;
    80001cd2:	00007917          	auipc	s2,0x7
    80001cd6:	35e90913          	addi	s2,s2,862 # 80009030 <ticks>
    80001cda:	00092783          	lw	a5,0(s2)
    80001cde:	c0bc                	sw	a5,64(s1)
  release(&tickslock);
    80001ce0:	00015517          	auipc	a0,0x15
    80001ce4:	7f050513          	addi	a0,a0,2032 # 800174d0 <tickslock>
    80001ce8:	fffff097          	auipc	ra,0xfffff
    80001cec:	f9c080e7          	jalr	-100(ra) # 80000c84 <release>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cf0:	03400613          	li	a2,52
    80001cf4:	00007597          	auipc	a1,0x7
    80001cf8:	bdc58593          	addi	a1,a1,-1060 # 800088d0 <initcode>
    80001cfc:	70a8                	ld	a0,96(s1)
    80001cfe:	fffff097          	auipc	ra,0xfffff
    80001d02:	64e080e7          	jalr	1614(ra) # 8000134c <uvminit>
  p->sz = PGSIZE;
    80001d06:	6785                	lui	a5,0x1
    80001d08:	ecbc                	sd	a5,88(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d0a:	74b8                	ld	a4,104(s1)
    80001d0c:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d10:	74b8                	ld	a4,104(s1)
    80001d12:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d14:	4641                	li	a2,16
    80001d16:	00006597          	auipc	a1,0x6
    80001d1a:	4ea58593          	addi	a1,a1,1258 # 80008200 <digits+0x1c0>
    80001d1e:	16848513          	addi	a0,s1,360
    80001d22:	fffff097          	auipc	ra,0xfffff
    80001d26:	0f4080e7          	jalr	244(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001d2a:	00006517          	auipc	a0,0x6
    80001d2e:	4e650513          	addi	a0,a0,1254 # 80008210 <digits+0x1d0>
    80001d32:	00002097          	auipc	ra,0x2
    80001d36:	572080e7          	jalr	1394(ra) # 800042a4 <namei>
    80001d3a:	16a4b023          	sd	a0,352(s1)
  p->state = RUNNABLE;
    80001d3e:	478d                	li	a5,3
    80001d40:	cc9c                	sw	a5,24(s1)
  acquire(&tickslock);
    80001d42:	00015517          	auipc	a0,0x15
    80001d46:	78e50513          	addi	a0,a0,1934 # 800174d0 <tickslock>
    80001d4a:	fffff097          	auipc	ra,0xfffff
    80001d4e:	e86080e7          	jalr	-378(ra) # 80000bd0 <acquire>
  p->stime = ticks;
    80001d52:	00092783          	lw	a5,0(s2)
    80001d56:	c0fc                	sw	a5,68(s1)
  release(&tickslock);
    80001d58:	00015517          	auipc	a0,0x15
    80001d5c:	77850513          	addi	a0,a0,1912 # 800174d0 <tickslock>
    80001d60:	fffff097          	auipc	ra,0xfffff
    80001d64:	f24080e7          	jalr	-220(ra) # 80000c84 <release>
  release(&p->lock);
    80001d68:	8526                	mv	a0,s1
    80001d6a:	fffff097          	auipc	ra,0xfffff
    80001d6e:	f1a080e7          	jalr	-230(ra) # 80000c84 <release>
}
    80001d72:	60e2                	ld	ra,24(sp)
    80001d74:	6442                	ld	s0,16(sp)
    80001d76:	64a2                	ld	s1,8(sp)
    80001d78:	6902                	ld	s2,0(sp)
    80001d7a:	6105                	addi	sp,sp,32
    80001d7c:	8082                	ret

0000000080001d7e <growproc>:
{
    80001d7e:	1101                	addi	sp,sp,-32
    80001d80:	ec06                	sd	ra,24(sp)
    80001d82:	e822                	sd	s0,16(sp)
    80001d84:	e426                	sd	s1,8(sp)
    80001d86:	e04a                	sd	s2,0(sp)
    80001d88:	1000                	addi	s0,sp,32
    80001d8a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d8c:	00000097          	auipc	ra,0x0
    80001d90:	c0a080e7          	jalr	-1014(ra) # 80001996 <myproc>
    80001d94:	892a                	mv	s2,a0
  sz = p->sz;
    80001d96:	6d2c                	ld	a1,88(a0)
    80001d98:	0005879b          	sext.w	a5,a1
  if(n > 0){
    80001d9c:	00904f63          	bgtz	s1,80001dba <growproc+0x3c>
  } else if(n < 0){
    80001da0:	0204cd63          	bltz	s1,80001dda <growproc+0x5c>
  p->sz = sz;
    80001da4:	1782                	slli	a5,a5,0x20
    80001da6:	9381                	srli	a5,a5,0x20
    80001da8:	04f93c23          	sd	a5,88(s2)
  return 0;
    80001dac:	4501                	li	a0,0
}
    80001dae:	60e2                	ld	ra,24(sp)
    80001db0:	6442                	ld	s0,16(sp)
    80001db2:	64a2                	ld	s1,8(sp)
    80001db4:	6902                	ld	s2,0(sp)
    80001db6:	6105                	addi	sp,sp,32
    80001db8:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001dba:	00f4863b          	addw	a2,s1,a5
    80001dbe:	1602                	slli	a2,a2,0x20
    80001dc0:	9201                	srli	a2,a2,0x20
    80001dc2:	1582                	slli	a1,a1,0x20
    80001dc4:	9181                	srli	a1,a1,0x20
    80001dc6:	7128                	ld	a0,96(a0)
    80001dc8:	fffff097          	auipc	ra,0xfffff
    80001dcc:	63e080e7          	jalr	1598(ra) # 80001406 <uvmalloc>
    80001dd0:	0005079b          	sext.w	a5,a0
    80001dd4:	fbe1                	bnez	a5,80001da4 <growproc+0x26>
      return -1;
    80001dd6:	557d                	li	a0,-1
    80001dd8:	bfd9                	j	80001dae <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001dda:	00f4863b          	addw	a2,s1,a5
    80001dde:	1602                	slli	a2,a2,0x20
    80001de0:	9201                	srli	a2,a2,0x20
    80001de2:	1582                	slli	a1,a1,0x20
    80001de4:	9181                	srli	a1,a1,0x20
    80001de6:	7128                	ld	a0,96(a0)
    80001de8:	fffff097          	auipc	ra,0xfffff
    80001dec:	5d6080e7          	jalr	1494(ra) # 800013be <uvmdealloc>
    80001df0:	0005079b          	sext.w	a5,a0
    80001df4:	bf45                	j	80001da4 <growproc+0x26>

0000000080001df6 <fork>:
{
    80001df6:	7139                	addi	sp,sp,-64
    80001df8:	fc06                	sd	ra,56(sp)
    80001dfa:	f822                	sd	s0,48(sp)
    80001dfc:	f426                	sd	s1,40(sp)
    80001dfe:	f04a                	sd	s2,32(sp)
    80001e00:	ec4e                	sd	s3,24(sp)
    80001e02:	e852                	sd	s4,16(sp)
    80001e04:	e456                	sd	s5,8(sp)
    80001e06:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001e08:	00000097          	auipc	ra,0x0
    80001e0c:	b8e080e7          	jalr	-1138(ra) # 80001996 <myproc>
    80001e10:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001e12:	00000097          	auipc	ra,0x0
    80001e16:	dc4080e7          	jalr	-572(ra) # 80001bd6 <allocproc>
    80001e1a:	14050263          	beqz	a0,80001f5e <fork+0x168>
    80001e1e:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e20:	058ab603          	ld	a2,88(s5)
    80001e24:	712c                	ld	a1,96(a0)
    80001e26:	060ab503          	ld	a0,96(s5)
    80001e2a:	fffff097          	auipc	ra,0xfffff
    80001e2e:	72c080e7          	jalr	1836(ra) # 80001556 <uvmcopy>
    80001e32:	06054e63          	bltz	a0,80001eae <fork+0xb8>
  acquire(&tickslock);
    80001e36:	00015517          	auipc	a0,0x15
    80001e3a:	69a50513          	addi	a0,a0,1690 # 800174d0 <tickslock>
    80001e3e:	fffff097          	auipc	ra,0xfffff
    80001e42:	d92080e7          	jalr	-622(ra) # 80000bd0 <acquire>
  np->ctime = ticks;
    80001e46:	00007797          	auipc	a5,0x7
    80001e4a:	1ea7a783          	lw	a5,490(a5) # 80009030 <ticks>
    80001e4e:	04f9a023          	sw	a5,64(s3)
  release(&tickslock);
    80001e52:	00015517          	auipc	a0,0x15
    80001e56:	67e50513          	addi	a0,a0,1662 # 800174d0 <tickslock>
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	e2a080e7          	jalr	-470(ra) # 80000c84 <release>
  np->sz = p->sz;
    80001e62:	058ab783          	ld	a5,88(s5)
    80001e66:	04f9bc23          	sd	a5,88(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e6a:	068ab683          	ld	a3,104(s5)
    80001e6e:	87b6                	mv	a5,a3
    80001e70:	0689b703          	ld	a4,104(s3)
    80001e74:	12068693          	addi	a3,a3,288
    80001e78:	0007b803          	ld	a6,0(a5)
    80001e7c:	6788                	ld	a0,8(a5)
    80001e7e:	6b8c                	ld	a1,16(a5)
    80001e80:	6f90                	ld	a2,24(a5)
    80001e82:	01073023          	sd	a6,0(a4)
    80001e86:	e708                	sd	a0,8(a4)
    80001e88:	eb0c                	sd	a1,16(a4)
    80001e8a:	ef10                	sd	a2,24(a4)
    80001e8c:	02078793          	addi	a5,a5,32
    80001e90:	02070713          	addi	a4,a4,32
    80001e94:	fed792e3          	bne	a5,a3,80001e78 <fork+0x82>
  np->trapframe->a0 = 0;
    80001e98:	0689b783          	ld	a5,104(s3)
    80001e9c:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001ea0:	0e0a8493          	addi	s1,s5,224
    80001ea4:	0e098913          	addi	s2,s3,224
    80001ea8:	160a8a13          	addi	s4,s5,352
    80001eac:	a00d                	j	80001ece <fork+0xd8>
    freeproc(np);
    80001eae:	854e                	mv	a0,s3
    80001eb0:	00000097          	auipc	ra,0x0
    80001eb4:	cce080e7          	jalr	-818(ra) # 80001b7e <freeproc>
    release(&np->lock);
    80001eb8:	854e                	mv	a0,s3
    80001eba:	fffff097          	auipc	ra,0xfffff
    80001ebe:	dca080e7          	jalr	-566(ra) # 80000c84 <release>
    return -1;
    80001ec2:	597d                	li	s2,-1
    80001ec4:	a059                	j	80001f4a <fork+0x154>
  for(i = 0; i < NOFILE; i++)
    80001ec6:	04a1                	addi	s1,s1,8
    80001ec8:	0921                	addi	s2,s2,8
    80001eca:	01448b63          	beq	s1,s4,80001ee0 <fork+0xea>
    if(p->ofile[i])
    80001ece:	6088                	ld	a0,0(s1)
    80001ed0:	d97d                	beqz	a0,80001ec6 <fork+0xd0>
      np->ofile[i] = filedup(p->ofile[i]);
    80001ed2:	00003097          	auipc	ra,0x3
    80001ed6:	a68080e7          	jalr	-1432(ra) # 8000493a <filedup>
    80001eda:	00a93023          	sd	a0,0(s2)
    80001ede:	b7e5                	j	80001ec6 <fork+0xd0>
  np->cwd = idup(p->cwd);
    80001ee0:	160ab503          	ld	a0,352(s5)
    80001ee4:	00002097          	auipc	ra,0x2
    80001ee8:	bc6080e7          	jalr	-1082(ra) # 80003aaa <idup>
    80001eec:	16a9b023          	sd	a0,352(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ef0:	4641                	li	a2,16
    80001ef2:	168a8593          	addi	a1,s5,360
    80001ef6:	16898513          	addi	a0,s3,360
    80001efa:	fffff097          	auipc	ra,0xfffff
    80001efe:	f1c080e7          	jalr	-228(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    80001f02:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001f06:	854e                	mv	a0,s3
    80001f08:	fffff097          	auipc	ra,0xfffff
    80001f0c:	d7c080e7          	jalr	-644(ra) # 80000c84 <release>
  acquire(&wait_lock);
    80001f10:	0000f497          	auipc	s1,0xf
    80001f14:	3a848493          	addi	s1,s1,936 # 800112b8 <wait_lock>
    80001f18:	8526                	mv	a0,s1
    80001f1a:	fffff097          	auipc	ra,0xfffff
    80001f1e:	cb6080e7          	jalr	-842(ra) # 80000bd0 <acquire>
  np->parent = p;
    80001f22:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80001f26:	8526                	mv	a0,s1
    80001f28:	fffff097          	auipc	ra,0xfffff
    80001f2c:	d5c080e7          	jalr	-676(ra) # 80000c84 <release>
  acquire(&np->lock);
    80001f30:	854e                	mv	a0,s3
    80001f32:	fffff097          	auipc	ra,0xfffff
    80001f36:	c9e080e7          	jalr	-866(ra) # 80000bd0 <acquire>
  np->state = RUNNABLE;
    80001f3a:	478d                	li	a5,3
    80001f3c:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001f40:	854e                	mv	a0,s3
    80001f42:	fffff097          	auipc	ra,0xfffff
    80001f46:	d42080e7          	jalr	-702(ra) # 80000c84 <release>
}
    80001f4a:	854a                	mv	a0,s2
    80001f4c:	70e2                	ld	ra,56(sp)
    80001f4e:	7442                	ld	s0,48(sp)
    80001f50:	74a2                	ld	s1,40(sp)
    80001f52:	7902                	ld	s2,32(sp)
    80001f54:	69e2                	ld	s3,24(sp)
    80001f56:	6a42                	ld	s4,16(sp)
    80001f58:	6aa2                	ld	s5,8(sp)
    80001f5a:	6121                	addi	sp,sp,64
    80001f5c:	8082                	ret
    return -1;
    80001f5e:	597d                	li	s2,-1
    80001f60:	b7ed                	j	80001f4a <fork+0x154>

0000000080001f62 <scheduler>:
{
    80001f62:	715d                	addi	sp,sp,-80
    80001f64:	e486                	sd	ra,72(sp)
    80001f66:	e0a2                	sd	s0,64(sp)
    80001f68:	fc26                	sd	s1,56(sp)
    80001f6a:	f84a                	sd	s2,48(sp)
    80001f6c:	f44e                	sd	s3,40(sp)
    80001f6e:	f052                	sd	s4,32(sp)
    80001f70:	ec56                	sd	s5,24(sp)
    80001f72:	e85a                	sd	s6,16(sp)
    80001f74:	e45e                	sd	s7,8(sp)
    80001f76:	e062                	sd	s8,0(sp)
    80001f78:	0880                	addi	s0,sp,80
    80001f7a:	8792                	mv	a5,tp
  int id = r_tp();
    80001f7c:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f7e:	00779b93          	slli	s7,a5,0x7
    80001f82:	0000f717          	auipc	a4,0xf
    80001f86:	31e70713          	addi	a4,a4,798 # 800112a0 <pid_lock>
    80001f8a:	975e                	add	a4,a4,s7
    80001f8c:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f90:	0000f717          	auipc	a4,0xf
    80001f94:	34870713          	addi	a4,a4,840 # 800112d8 <cpus+0x8>
    80001f98:	9bba                	add	s7,s7,a4
        acquire(&tickslock);
    80001f9a:	00015a97          	auipc	s5,0x15
    80001f9e:	536a8a93          	addi	s5,s5,1334 # 800174d0 <tickslock>
        p->stime = ticks;
    80001fa2:	00007c17          	auipc	s8,0x7
    80001fa6:	08ec0c13          	addi	s8,s8,142 # 80009030 <ticks>
        c->proc = p;
    80001faa:	079e                	slli	a5,a5,0x7
    80001fac:	0000fa17          	auipc	s4,0xf
    80001fb0:	2f4a0a13          	addi	s4,s4,756 # 800112a0 <pid_lock>
    80001fb4:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fb6:	00015997          	auipc	s3,0x15
    80001fba:	51a98993          	addi	s3,s3,1306 # 800174d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fbe:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fc2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fc6:	10079073          	csrw	sstatus,a5
    80001fca:	0000f497          	auipc	s1,0xf
    80001fce:	70648493          	addi	s1,s1,1798 # 800116d0 <proc>
      if(p->state == RUNNABLE) {
    80001fd2:	490d                	li	s2,3
        p->state = RUNNING;
    80001fd4:	4b11                	li	s6,4
    80001fd6:	a811                	j	80001fea <scheduler+0x88>
      release(&p->lock);
    80001fd8:	8526                	mv	a0,s1
    80001fda:	fffff097          	auipc	ra,0xfffff
    80001fde:	caa080e7          	jalr	-854(ra) # 80000c84 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fe2:	17848493          	addi	s1,s1,376
    80001fe6:	fd348ce3          	beq	s1,s3,80001fbe <scheduler+0x5c>
      acquire(&p->lock);
    80001fea:	8526                	mv	a0,s1
    80001fec:	fffff097          	auipc	ra,0xfffff
    80001ff0:	be4080e7          	jalr	-1052(ra) # 80000bd0 <acquire>
      if(p->state == RUNNABLE) {
    80001ff4:	4c9c                	lw	a5,24(s1)
    80001ff6:	ff2791e3          	bne	a5,s2,80001fd8 <scheduler+0x76>
        p->state = RUNNING;
    80001ffa:	0164ac23          	sw	s6,24(s1)
        acquire(&tickslock);
    80001ffe:	8556                	mv	a0,s5
    80002000:	fffff097          	auipc	ra,0xfffff
    80002004:	bd0080e7          	jalr	-1072(ra) # 80000bd0 <acquire>
        p->stime = ticks;
    80002008:	000c2783          	lw	a5,0(s8)
    8000200c:	c0fc                	sw	a5,68(s1)
        release(&tickslock);
    8000200e:	8556                	mv	a0,s5
    80002010:	fffff097          	auipc	ra,0xfffff
    80002014:	c74080e7          	jalr	-908(ra) # 80000c84 <release>
        c->proc = p;
    80002018:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    8000201c:	07048593          	addi	a1,s1,112
    80002020:	855e                	mv	a0,s7
    80002022:	00001097          	auipc	ra,0x1
    80002026:	97e080e7          	jalr	-1666(ra) # 800029a0 <swtch>
        c->proc = 0;
    8000202a:	020a3823          	sd	zero,48(s4)
    8000202e:	b76d                	j	80001fd8 <scheduler+0x76>

0000000080002030 <sched>:
{
    80002030:	7179                	addi	sp,sp,-48
    80002032:	f406                	sd	ra,40(sp)
    80002034:	f022                	sd	s0,32(sp)
    80002036:	ec26                	sd	s1,24(sp)
    80002038:	e84a                	sd	s2,16(sp)
    8000203a:	e44e                	sd	s3,8(sp)
    8000203c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000203e:	00000097          	auipc	ra,0x0
    80002042:	958080e7          	jalr	-1704(ra) # 80001996 <myproc>
    80002046:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002048:	fffff097          	auipc	ra,0xfffff
    8000204c:	b0e080e7          	jalr	-1266(ra) # 80000b56 <holding>
    80002050:	c93d                	beqz	a0,800020c6 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002052:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002054:	2781                	sext.w	a5,a5
    80002056:	079e                	slli	a5,a5,0x7
    80002058:	0000f717          	auipc	a4,0xf
    8000205c:	24870713          	addi	a4,a4,584 # 800112a0 <pid_lock>
    80002060:	97ba                	add	a5,a5,a4
    80002062:	0a87a703          	lw	a4,168(a5)
    80002066:	4785                	li	a5,1
    80002068:	06f71763          	bne	a4,a5,800020d6 <sched+0xa6>
  if(p->state == RUNNING)
    8000206c:	4c98                	lw	a4,24(s1)
    8000206e:	4791                	li	a5,4
    80002070:	06f70b63          	beq	a4,a5,800020e6 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002074:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002078:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000207a:	efb5                	bnez	a5,800020f6 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000207c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000207e:	0000f917          	auipc	s2,0xf
    80002082:	22290913          	addi	s2,s2,546 # 800112a0 <pid_lock>
    80002086:	2781                	sext.w	a5,a5
    80002088:	079e                	slli	a5,a5,0x7
    8000208a:	97ca                	add	a5,a5,s2
    8000208c:	0ac7a983          	lw	s3,172(a5)
    80002090:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002092:	2781                	sext.w	a5,a5
    80002094:	079e                	slli	a5,a5,0x7
    80002096:	0000f597          	auipc	a1,0xf
    8000209a:	24258593          	addi	a1,a1,578 # 800112d8 <cpus+0x8>
    8000209e:	95be                	add	a1,a1,a5
    800020a0:	07048513          	addi	a0,s1,112
    800020a4:	00001097          	auipc	ra,0x1
    800020a8:	8fc080e7          	jalr	-1796(ra) # 800029a0 <swtch>
    800020ac:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020ae:	2781                	sext.w	a5,a5
    800020b0:	079e                	slli	a5,a5,0x7
    800020b2:	993e                	add	s2,s2,a5
    800020b4:	0b392623          	sw	s3,172(s2)
}
    800020b8:	70a2                	ld	ra,40(sp)
    800020ba:	7402                	ld	s0,32(sp)
    800020bc:	64e2                	ld	s1,24(sp)
    800020be:	6942                	ld	s2,16(sp)
    800020c0:	69a2                	ld	s3,8(sp)
    800020c2:	6145                	addi	sp,sp,48
    800020c4:	8082                	ret
    panic("sched p->lock");
    800020c6:	00006517          	auipc	a0,0x6
    800020ca:	15250513          	addi	a0,a0,338 # 80008218 <digits+0x1d8>
    800020ce:	ffffe097          	auipc	ra,0xffffe
    800020d2:	46c080e7          	jalr	1132(ra) # 8000053a <panic>
    panic("sched locks");
    800020d6:	00006517          	auipc	a0,0x6
    800020da:	15250513          	addi	a0,a0,338 # 80008228 <digits+0x1e8>
    800020de:	ffffe097          	auipc	ra,0xffffe
    800020e2:	45c080e7          	jalr	1116(ra) # 8000053a <panic>
    panic("sched running");
    800020e6:	00006517          	auipc	a0,0x6
    800020ea:	15250513          	addi	a0,a0,338 # 80008238 <digits+0x1f8>
    800020ee:	ffffe097          	auipc	ra,0xffffe
    800020f2:	44c080e7          	jalr	1100(ra) # 8000053a <panic>
    panic("sched interruptible");
    800020f6:	00006517          	auipc	a0,0x6
    800020fa:	15250513          	addi	a0,a0,338 # 80008248 <digits+0x208>
    800020fe:	ffffe097          	auipc	ra,0xffffe
    80002102:	43c080e7          	jalr	1084(ra) # 8000053a <panic>

0000000080002106 <yield>:
{
    80002106:	1101                	addi	sp,sp,-32
    80002108:	ec06                	sd	ra,24(sp)
    8000210a:	e822                	sd	s0,16(sp)
    8000210c:	e426                	sd	s1,8(sp)
    8000210e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002110:	00000097          	auipc	ra,0x0
    80002114:	886080e7          	jalr	-1914(ra) # 80001996 <myproc>
    80002118:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000211a:	fffff097          	auipc	ra,0xfffff
    8000211e:	ab6080e7          	jalr	-1354(ra) # 80000bd0 <acquire>
  p->state = RUNNABLE;
    80002122:	478d                	li	a5,3
    80002124:	cc9c                	sw	a5,24(s1)
  sched();
    80002126:	00000097          	auipc	ra,0x0
    8000212a:	f0a080e7          	jalr	-246(ra) # 80002030 <sched>
  release(&p->lock);
    8000212e:	8526                	mv	a0,s1
    80002130:	fffff097          	auipc	ra,0xfffff
    80002134:	b54080e7          	jalr	-1196(ra) # 80000c84 <release>
}
    80002138:	60e2                	ld	ra,24(sp)
    8000213a:	6442                	ld	s0,16(sp)
    8000213c:	64a2                	ld	s1,8(sp)
    8000213e:	6105                	addi	sp,sp,32
    80002140:	8082                	ret

0000000080002142 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002142:	7179                	addi	sp,sp,-48
    80002144:	f406                	sd	ra,40(sp)
    80002146:	f022                	sd	s0,32(sp)
    80002148:	ec26                	sd	s1,24(sp)
    8000214a:	e84a                	sd	s2,16(sp)
    8000214c:	e44e                	sd	s3,8(sp)
    8000214e:	1800                	addi	s0,sp,48
    80002150:	89aa                	mv	s3,a0
    80002152:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002154:	00000097          	auipc	ra,0x0
    80002158:	842080e7          	jalr	-1982(ra) # 80001996 <myproc>
    8000215c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000215e:	fffff097          	auipc	ra,0xfffff
    80002162:	a72080e7          	jalr	-1422(ra) # 80000bd0 <acquire>
  release(lk);
    80002166:	854a                	mv	a0,s2
    80002168:	fffff097          	auipc	ra,0xfffff
    8000216c:	b1c080e7          	jalr	-1252(ra) # 80000c84 <release>

  // Go to sleep.
  p->chan = chan;
    80002170:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002174:	4789                	li	a5,2
    80002176:	cc9c                	sw	a5,24(s1)

  sched();
    80002178:	00000097          	auipc	ra,0x0
    8000217c:	eb8080e7          	jalr	-328(ra) # 80002030 <sched>

  // Tidy up.
  p->chan = 0;
    80002180:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002184:	8526                	mv	a0,s1
    80002186:	fffff097          	auipc	ra,0xfffff
    8000218a:	afe080e7          	jalr	-1282(ra) # 80000c84 <release>
  acquire(lk);
    8000218e:	854a                	mv	a0,s2
    80002190:	fffff097          	auipc	ra,0xfffff
    80002194:	a40080e7          	jalr	-1472(ra) # 80000bd0 <acquire>
}
    80002198:	70a2                	ld	ra,40(sp)
    8000219a:	7402                	ld	s0,32(sp)
    8000219c:	64e2                	ld	s1,24(sp)
    8000219e:	6942                	ld	s2,16(sp)
    800021a0:	69a2                	ld	s3,8(sp)
    800021a2:	6145                	addi	sp,sp,48
    800021a4:	8082                	ret

00000000800021a6 <wait>:
{
    800021a6:	715d                	addi	sp,sp,-80
    800021a8:	e486                	sd	ra,72(sp)
    800021aa:	e0a2                	sd	s0,64(sp)
    800021ac:	fc26                	sd	s1,56(sp)
    800021ae:	f84a                	sd	s2,48(sp)
    800021b0:	f44e                	sd	s3,40(sp)
    800021b2:	f052                	sd	s4,32(sp)
    800021b4:	ec56                	sd	s5,24(sp)
    800021b6:	e85a                	sd	s6,16(sp)
    800021b8:	e45e                	sd	s7,8(sp)
    800021ba:	e062                	sd	s8,0(sp)
    800021bc:	0880                	addi	s0,sp,80
    800021be:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800021c0:	fffff097          	auipc	ra,0xfffff
    800021c4:	7d6080e7          	jalr	2006(ra) # 80001996 <myproc>
    800021c8:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800021ca:	0000f517          	auipc	a0,0xf
    800021ce:	0ee50513          	addi	a0,a0,238 # 800112b8 <wait_lock>
    800021d2:	fffff097          	auipc	ra,0xfffff
    800021d6:	9fe080e7          	jalr	-1538(ra) # 80000bd0 <acquire>
    havekids = 0;
    800021da:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800021dc:	4a15                	li	s4,5
        havekids = 1;
    800021de:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800021e0:	00015997          	auipc	s3,0x15
    800021e4:	2f098993          	addi	s3,s3,752 # 800174d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021e8:	0000fc17          	auipc	s8,0xf
    800021ec:	0d0c0c13          	addi	s8,s8,208 # 800112b8 <wait_lock>
    havekids = 0;
    800021f0:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800021f2:	0000f497          	auipc	s1,0xf
    800021f6:	4de48493          	addi	s1,s1,1246 # 800116d0 <proc>
    800021fa:	a0bd                	j	80002268 <wait+0xc2>
          pid = np->pid;
    800021fc:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002200:	000b0e63          	beqz	s6,8000221c <wait+0x76>
    80002204:	4691                	li	a3,4
    80002206:	02c48613          	addi	a2,s1,44
    8000220a:	85da                	mv	a1,s6
    8000220c:	06093503          	ld	a0,96(s2)
    80002210:	fffff097          	auipc	ra,0xfffff
    80002214:	44a080e7          	jalr	1098(ra) # 8000165a <copyout>
    80002218:	02054563          	bltz	a0,80002242 <wait+0x9c>
          freeproc(np);
    8000221c:	8526                	mv	a0,s1
    8000221e:	00000097          	auipc	ra,0x0
    80002222:	960080e7          	jalr	-1696(ra) # 80001b7e <freeproc>
          release(&np->lock);
    80002226:	8526                	mv	a0,s1
    80002228:	fffff097          	auipc	ra,0xfffff
    8000222c:	a5c080e7          	jalr	-1444(ra) # 80000c84 <release>
          release(&wait_lock);
    80002230:	0000f517          	auipc	a0,0xf
    80002234:	08850513          	addi	a0,a0,136 # 800112b8 <wait_lock>
    80002238:	fffff097          	auipc	ra,0xfffff
    8000223c:	a4c080e7          	jalr	-1460(ra) # 80000c84 <release>
          return pid;
    80002240:	a09d                	j	800022a6 <wait+0x100>
            release(&np->lock);
    80002242:	8526                	mv	a0,s1
    80002244:	fffff097          	auipc	ra,0xfffff
    80002248:	a40080e7          	jalr	-1472(ra) # 80000c84 <release>
            release(&wait_lock);
    8000224c:	0000f517          	auipc	a0,0xf
    80002250:	06c50513          	addi	a0,a0,108 # 800112b8 <wait_lock>
    80002254:	fffff097          	auipc	ra,0xfffff
    80002258:	a30080e7          	jalr	-1488(ra) # 80000c84 <release>
            return -1;
    8000225c:	59fd                	li	s3,-1
    8000225e:	a0a1                	j	800022a6 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002260:	17848493          	addi	s1,s1,376
    80002264:	03348463          	beq	s1,s3,8000228c <wait+0xe6>
      if(np->parent == p){
    80002268:	7c9c                	ld	a5,56(s1)
    8000226a:	ff279be3          	bne	a5,s2,80002260 <wait+0xba>
        acquire(&np->lock);
    8000226e:	8526                	mv	a0,s1
    80002270:	fffff097          	auipc	ra,0xfffff
    80002274:	960080e7          	jalr	-1696(ra) # 80000bd0 <acquire>
        if(np->state == ZOMBIE){
    80002278:	4c9c                	lw	a5,24(s1)
    8000227a:	f94781e3          	beq	a5,s4,800021fc <wait+0x56>
        release(&np->lock);
    8000227e:	8526                	mv	a0,s1
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	a04080e7          	jalr	-1532(ra) # 80000c84 <release>
        havekids = 1;
    80002288:	8756                	mv	a4,s5
    8000228a:	bfd9                	j	80002260 <wait+0xba>
    if(!havekids || p->killed){
    8000228c:	c701                	beqz	a4,80002294 <wait+0xee>
    8000228e:	02892783          	lw	a5,40(s2)
    80002292:	c79d                	beqz	a5,800022c0 <wait+0x11a>
      release(&wait_lock);
    80002294:	0000f517          	auipc	a0,0xf
    80002298:	02450513          	addi	a0,a0,36 # 800112b8 <wait_lock>
    8000229c:	fffff097          	auipc	ra,0xfffff
    800022a0:	9e8080e7          	jalr	-1560(ra) # 80000c84 <release>
      return -1;
    800022a4:	59fd                	li	s3,-1
}
    800022a6:	854e                	mv	a0,s3
    800022a8:	60a6                	ld	ra,72(sp)
    800022aa:	6406                	ld	s0,64(sp)
    800022ac:	74e2                	ld	s1,56(sp)
    800022ae:	7942                	ld	s2,48(sp)
    800022b0:	79a2                	ld	s3,40(sp)
    800022b2:	7a02                	ld	s4,32(sp)
    800022b4:	6ae2                	ld	s5,24(sp)
    800022b6:	6b42                	ld	s6,16(sp)
    800022b8:	6ba2                	ld	s7,8(sp)
    800022ba:	6c02                	ld	s8,0(sp)
    800022bc:	6161                	addi	sp,sp,80
    800022be:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022c0:	85e2                	mv	a1,s8
    800022c2:	854a                	mv	a0,s2
    800022c4:	00000097          	auipc	ra,0x0
    800022c8:	e7e080e7          	jalr	-386(ra) # 80002142 <sleep>
    havekids = 0;
    800022cc:	b715                	j	800021f0 <wait+0x4a>

00000000800022ce <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800022ce:	7139                	addi	sp,sp,-64
    800022d0:	fc06                	sd	ra,56(sp)
    800022d2:	f822                	sd	s0,48(sp)
    800022d4:	f426                	sd	s1,40(sp)
    800022d6:	f04a                	sd	s2,32(sp)
    800022d8:	ec4e                	sd	s3,24(sp)
    800022da:	e852                	sd	s4,16(sp)
    800022dc:	e456                	sd	s5,8(sp)
    800022de:	0080                	addi	s0,sp,64
    800022e0:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800022e2:	0000f497          	auipc	s1,0xf
    800022e6:	3ee48493          	addi	s1,s1,1006 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800022ea:	4989                	li	s3,2
        p->state = RUNNABLE;
    800022ec:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800022ee:	00015917          	auipc	s2,0x15
    800022f2:	1e290913          	addi	s2,s2,482 # 800174d0 <tickslock>
    800022f6:	a811                	j	8000230a <wakeup+0x3c>
      }
      release(&p->lock);
    800022f8:	8526                	mv	a0,s1
    800022fa:	fffff097          	auipc	ra,0xfffff
    800022fe:	98a080e7          	jalr	-1654(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002302:	17848493          	addi	s1,s1,376
    80002306:	03248663          	beq	s1,s2,80002332 <wakeup+0x64>
    if(p != myproc()){
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	68c080e7          	jalr	1676(ra) # 80001996 <myproc>
    80002312:	fea488e3          	beq	s1,a0,80002302 <wakeup+0x34>
      acquire(&p->lock);
    80002316:	8526                	mv	a0,s1
    80002318:	fffff097          	auipc	ra,0xfffff
    8000231c:	8b8080e7          	jalr	-1864(ra) # 80000bd0 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002320:	4c9c                	lw	a5,24(s1)
    80002322:	fd379be3          	bne	a5,s3,800022f8 <wakeup+0x2a>
    80002326:	709c                	ld	a5,32(s1)
    80002328:	fd4798e3          	bne	a5,s4,800022f8 <wakeup+0x2a>
        p->state = RUNNABLE;
    8000232c:	0154ac23          	sw	s5,24(s1)
    80002330:	b7e1                	j	800022f8 <wakeup+0x2a>
    }
  }
}
    80002332:	70e2                	ld	ra,56(sp)
    80002334:	7442                	ld	s0,48(sp)
    80002336:	74a2                	ld	s1,40(sp)
    80002338:	7902                	ld	s2,32(sp)
    8000233a:	69e2                	ld	s3,24(sp)
    8000233c:	6a42                	ld	s4,16(sp)
    8000233e:	6aa2                	ld	s5,8(sp)
    80002340:	6121                	addi	sp,sp,64
    80002342:	8082                	ret

0000000080002344 <reparent>:
{
    80002344:	7179                	addi	sp,sp,-48
    80002346:	f406                	sd	ra,40(sp)
    80002348:	f022                	sd	s0,32(sp)
    8000234a:	ec26                	sd	s1,24(sp)
    8000234c:	e84a                	sd	s2,16(sp)
    8000234e:	e44e                	sd	s3,8(sp)
    80002350:	e052                	sd	s4,0(sp)
    80002352:	1800                	addi	s0,sp,48
    80002354:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002356:	0000f497          	auipc	s1,0xf
    8000235a:	37a48493          	addi	s1,s1,890 # 800116d0 <proc>
      pp->parent = initproc;
    8000235e:	00007a17          	auipc	s4,0x7
    80002362:	ccaa0a13          	addi	s4,s4,-822 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002366:	00015997          	auipc	s3,0x15
    8000236a:	16a98993          	addi	s3,s3,362 # 800174d0 <tickslock>
    8000236e:	a029                	j	80002378 <reparent+0x34>
    80002370:	17848493          	addi	s1,s1,376
    80002374:	01348d63          	beq	s1,s3,8000238e <reparent+0x4a>
    if(pp->parent == p){
    80002378:	7c9c                	ld	a5,56(s1)
    8000237a:	ff279be3          	bne	a5,s2,80002370 <reparent+0x2c>
      pp->parent = initproc;
    8000237e:	000a3503          	ld	a0,0(s4)
    80002382:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002384:	00000097          	auipc	ra,0x0
    80002388:	f4a080e7          	jalr	-182(ra) # 800022ce <wakeup>
    8000238c:	b7d5                	j	80002370 <reparent+0x2c>
}
    8000238e:	70a2                	ld	ra,40(sp)
    80002390:	7402                	ld	s0,32(sp)
    80002392:	64e2                	ld	s1,24(sp)
    80002394:	6942                	ld	s2,16(sp)
    80002396:	69a2                	ld	s3,8(sp)
    80002398:	6a02                	ld	s4,0(sp)
    8000239a:	6145                	addi	sp,sp,48
    8000239c:	8082                	ret

000000008000239e <exit>:
{
    8000239e:	7179                	addi	sp,sp,-48
    800023a0:	f406                	sd	ra,40(sp)
    800023a2:	f022                	sd	s0,32(sp)
    800023a4:	ec26                	sd	s1,24(sp)
    800023a6:	e84a                	sd	s2,16(sp)
    800023a8:	e44e                	sd	s3,8(sp)
    800023aa:	e052                	sd	s4,0(sp)
    800023ac:	1800                	addi	s0,sp,48
    800023ae:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	5e6080e7          	jalr	1510(ra) # 80001996 <myproc>
    800023b8:	89aa                	mv	s3,a0
  if(p == initproc)
    800023ba:	00007797          	auipc	a5,0x7
    800023be:	c6e7b783          	ld	a5,-914(a5) # 80009028 <initproc>
    800023c2:	0e050493          	addi	s1,a0,224
    800023c6:	16050913          	addi	s2,a0,352
    800023ca:	02a79363          	bne	a5,a0,800023f0 <exit+0x52>
    panic("init exiting");
    800023ce:	00006517          	auipc	a0,0x6
    800023d2:	e9250513          	addi	a0,a0,-366 # 80008260 <digits+0x220>
    800023d6:	ffffe097          	auipc	ra,0xffffe
    800023da:	164080e7          	jalr	356(ra) # 8000053a <panic>
      fileclose(f);
    800023de:	00002097          	auipc	ra,0x2
    800023e2:	5ae080e7          	jalr	1454(ra) # 8000498c <fileclose>
      p->ofile[fd] = 0;
    800023e6:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800023ea:	04a1                	addi	s1,s1,8
    800023ec:	01248563          	beq	s1,s2,800023f6 <exit+0x58>
    if(p->ofile[fd]){
    800023f0:	6088                	ld	a0,0(s1)
    800023f2:	f575                	bnez	a0,800023de <exit+0x40>
    800023f4:	bfdd                	j	800023ea <exit+0x4c>
  begin_op();
    800023f6:	00002097          	auipc	ra,0x2
    800023fa:	0ce080e7          	jalr	206(ra) # 800044c4 <begin_op>
  iput(p->cwd);
    800023fe:	1609b503          	ld	a0,352(s3)
    80002402:	00002097          	auipc	ra,0x2
    80002406:	8a0080e7          	jalr	-1888(ra) # 80003ca2 <iput>
  end_op();
    8000240a:	00002097          	auipc	ra,0x2
    8000240e:	138080e7          	jalr	312(ra) # 80004542 <end_op>
  p->cwd = 0;
    80002412:	1609b023          	sd	zero,352(s3)
  acquire(&wait_lock);
    80002416:	0000f497          	auipc	s1,0xf
    8000241a:	ea248493          	addi	s1,s1,-350 # 800112b8 <wait_lock>
    8000241e:	8526                	mv	a0,s1
    80002420:	ffffe097          	auipc	ra,0xffffe
    80002424:	7b0080e7          	jalr	1968(ra) # 80000bd0 <acquire>
  reparent(p);
    80002428:	854e                	mv	a0,s3
    8000242a:	00000097          	auipc	ra,0x0
    8000242e:	f1a080e7          	jalr	-230(ra) # 80002344 <reparent>
  wakeup(p->parent);
    80002432:	0389b503          	ld	a0,56(s3)
    80002436:	00000097          	auipc	ra,0x0
    8000243a:	e98080e7          	jalr	-360(ra) # 800022ce <wakeup>
  acquire(&p->lock);
    8000243e:	854e                	mv	a0,s3
    80002440:	ffffe097          	auipc	ra,0xffffe
    80002444:	790080e7          	jalr	1936(ra) # 80000bd0 <acquire>
  p->xstate = status;
    80002448:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000244c:	4795                	li	a5,5
    8000244e:	00f9ac23          	sw	a5,24(s3)
  acquire(&tickslock);
    80002452:	00015517          	auipc	a0,0x15
    80002456:	07e50513          	addi	a0,a0,126 # 800174d0 <tickslock>
    8000245a:	ffffe097          	auipc	ra,0xffffe
    8000245e:	776080e7          	jalr	1910(ra) # 80000bd0 <acquire>
  p->etime = ticks;
    80002462:	00007797          	auipc	a5,0x7
    80002466:	bce7a783          	lw	a5,-1074(a5) # 80009030 <ticks>
    8000246a:	04f9a423          	sw	a5,72(s3)
  release(&tickslock);
    8000246e:	00015517          	auipc	a0,0x15
    80002472:	06250513          	addi	a0,a0,98 # 800174d0 <tickslock>
    80002476:	fffff097          	auipc	ra,0xfffff
    8000247a:	80e080e7          	jalr	-2034(ra) # 80000c84 <release>
  release(&wait_lock);
    8000247e:	8526                	mv	a0,s1
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	804080e7          	jalr	-2044(ra) # 80000c84 <release>
  sched();
    80002488:	00000097          	auipc	ra,0x0
    8000248c:	ba8080e7          	jalr	-1112(ra) # 80002030 <sched>
  panic("zombie exit");
    80002490:	00006517          	auipc	a0,0x6
    80002494:	de050513          	addi	a0,a0,-544 # 80008270 <digits+0x230>
    80002498:	ffffe097          	auipc	ra,0xffffe
    8000249c:	0a2080e7          	jalr	162(ra) # 8000053a <panic>

00000000800024a0 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800024a0:	7179                	addi	sp,sp,-48
    800024a2:	f406                	sd	ra,40(sp)
    800024a4:	f022                	sd	s0,32(sp)
    800024a6:	ec26                	sd	s1,24(sp)
    800024a8:	e84a                	sd	s2,16(sp)
    800024aa:	e44e                	sd	s3,8(sp)
    800024ac:	1800                	addi	s0,sp,48
    800024ae:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800024b0:	0000f497          	auipc	s1,0xf
    800024b4:	22048493          	addi	s1,s1,544 # 800116d0 <proc>
    800024b8:	00015997          	auipc	s3,0x15
    800024bc:	01898993          	addi	s3,s3,24 # 800174d0 <tickslock>
    acquire(&p->lock);
    800024c0:	8526                	mv	a0,s1
    800024c2:	ffffe097          	auipc	ra,0xffffe
    800024c6:	70e080e7          	jalr	1806(ra) # 80000bd0 <acquire>
    if(p->pid == pid){
    800024ca:	589c                	lw	a5,48(s1)
    800024cc:	01278d63          	beq	a5,s2,800024e6 <kill+0x46>
        release(&tickslock);
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800024d0:	8526                	mv	a0,s1
    800024d2:	ffffe097          	auipc	ra,0xffffe
    800024d6:	7b2080e7          	jalr	1970(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800024da:	17848493          	addi	s1,s1,376
    800024de:	ff3491e3          	bne	s1,s3,800024c0 <kill+0x20>
  }
  return -1;
    800024e2:	557d                	li	a0,-1
    800024e4:	a829                	j	800024fe <kill+0x5e>
      p->killed = 1;
    800024e6:	4785                	li	a5,1
    800024e8:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800024ea:	4c98                	lw	a4,24(s1)
    800024ec:	4789                	li	a5,2
    800024ee:	00f70f63          	beq	a4,a5,8000250c <kill+0x6c>
      release(&p->lock);
    800024f2:	8526                	mv	a0,s1
    800024f4:	ffffe097          	auipc	ra,0xffffe
    800024f8:	790080e7          	jalr	1936(ra) # 80000c84 <release>
      return 0;
    800024fc:	4501                	li	a0,0
}
    800024fe:	70a2                	ld	ra,40(sp)
    80002500:	7402                	ld	s0,32(sp)
    80002502:	64e2                	ld	s1,24(sp)
    80002504:	6942                	ld	s2,16(sp)
    80002506:	69a2                	ld	s3,8(sp)
    80002508:	6145                	addi	sp,sp,48
    8000250a:	8082                	ret
        p->state = RUNNABLE;
    8000250c:	478d                	li	a5,3
    8000250e:	cc9c                	sw	a5,24(s1)
        acquire(&tickslock);
    80002510:	00015517          	auipc	a0,0x15
    80002514:	fc050513          	addi	a0,a0,-64 # 800174d0 <tickslock>
    80002518:	ffffe097          	auipc	ra,0xffffe
    8000251c:	6b8080e7          	jalr	1720(ra) # 80000bd0 <acquire>
        p->etime = ticks;
    80002520:	00007797          	auipc	a5,0x7
    80002524:	b107a783          	lw	a5,-1264(a5) # 80009030 <ticks>
    80002528:	c4bc                	sw	a5,72(s1)
        release(&tickslock);
    8000252a:	00015517          	auipc	a0,0x15
    8000252e:	fa650513          	addi	a0,a0,-90 # 800174d0 <tickslock>
    80002532:	ffffe097          	auipc	ra,0xffffe
    80002536:	752080e7          	jalr	1874(ra) # 80000c84 <release>
    8000253a:	bf65                	j	800024f2 <kill+0x52>

000000008000253c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000253c:	7179                	addi	sp,sp,-48
    8000253e:	f406                	sd	ra,40(sp)
    80002540:	f022                	sd	s0,32(sp)
    80002542:	ec26                	sd	s1,24(sp)
    80002544:	e84a                	sd	s2,16(sp)
    80002546:	e44e                	sd	s3,8(sp)
    80002548:	e052                	sd	s4,0(sp)
    8000254a:	1800                	addi	s0,sp,48
    8000254c:	84aa                	mv	s1,a0
    8000254e:	892e                	mv	s2,a1
    80002550:	89b2                	mv	s3,a2
    80002552:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002554:	fffff097          	auipc	ra,0xfffff
    80002558:	442080e7          	jalr	1090(ra) # 80001996 <myproc>
  if(user_dst){
    8000255c:	c08d                	beqz	s1,8000257e <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000255e:	86d2                	mv	a3,s4
    80002560:	864e                	mv	a2,s3
    80002562:	85ca                	mv	a1,s2
    80002564:	7128                	ld	a0,96(a0)
    80002566:	fffff097          	auipc	ra,0xfffff
    8000256a:	0f4080e7          	jalr	244(ra) # 8000165a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000256e:	70a2                	ld	ra,40(sp)
    80002570:	7402                	ld	s0,32(sp)
    80002572:	64e2                	ld	s1,24(sp)
    80002574:	6942                	ld	s2,16(sp)
    80002576:	69a2                	ld	s3,8(sp)
    80002578:	6a02                	ld	s4,0(sp)
    8000257a:	6145                	addi	sp,sp,48
    8000257c:	8082                	ret
    memmove((char *)dst, src, len);
    8000257e:	000a061b          	sext.w	a2,s4
    80002582:	85ce                	mv	a1,s3
    80002584:	854a                	mv	a0,s2
    80002586:	ffffe097          	auipc	ra,0xffffe
    8000258a:	7a2080e7          	jalr	1954(ra) # 80000d28 <memmove>
    return 0;
    8000258e:	8526                	mv	a0,s1
    80002590:	bff9                	j	8000256e <either_copyout+0x32>

0000000080002592 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002592:	7179                	addi	sp,sp,-48
    80002594:	f406                	sd	ra,40(sp)
    80002596:	f022                	sd	s0,32(sp)
    80002598:	ec26                	sd	s1,24(sp)
    8000259a:	e84a                	sd	s2,16(sp)
    8000259c:	e44e                	sd	s3,8(sp)
    8000259e:	e052                	sd	s4,0(sp)
    800025a0:	1800                	addi	s0,sp,48
    800025a2:	892a                	mv	s2,a0
    800025a4:	84ae                	mv	s1,a1
    800025a6:	89b2                	mv	s3,a2
    800025a8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025aa:	fffff097          	auipc	ra,0xfffff
    800025ae:	3ec080e7          	jalr	1004(ra) # 80001996 <myproc>
  if(user_src){
    800025b2:	c08d                	beqz	s1,800025d4 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800025b4:	86d2                	mv	a3,s4
    800025b6:	864e                	mv	a2,s3
    800025b8:	85ca                	mv	a1,s2
    800025ba:	7128                	ld	a0,96(a0)
    800025bc:	fffff097          	auipc	ra,0xfffff
    800025c0:	12a080e7          	jalr	298(ra) # 800016e6 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800025c4:	70a2                	ld	ra,40(sp)
    800025c6:	7402                	ld	s0,32(sp)
    800025c8:	64e2                	ld	s1,24(sp)
    800025ca:	6942                	ld	s2,16(sp)
    800025cc:	69a2                	ld	s3,8(sp)
    800025ce:	6a02                	ld	s4,0(sp)
    800025d0:	6145                	addi	sp,sp,48
    800025d2:	8082                	ret
    memmove(dst, (char*)src, len);
    800025d4:	000a061b          	sext.w	a2,s4
    800025d8:	85ce                	mv	a1,s3
    800025da:	854a                	mv	a0,s2
    800025dc:	ffffe097          	auipc	ra,0xffffe
    800025e0:	74c080e7          	jalr	1868(ra) # 80000d28 <memmove>
    return 0;
    800025e4:	8526                	mv	a0,s1
    800025e6:	bff9                	j	800025c4 <either_copyin+0x32>

00000000800025e8 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025e8:	715d                	addi	sp,sp,-80
    800025ea:	e486                	sd	ra,72(sp)
    800025ec:	e0a2                	sd	s0,64(sp)
    800025ee:	fc26                	sd	s1,56(sp)
    800025f0:	f84a                	sd	s2,48(sp)
    800025f2:	f44e                	sd	s3,40(sp)
    800025f4:	f052                	sd	s4,32(sp)
    800025f6:	ec56                	sd	s5,24(sp)
    800025f8:	e85a                	sd	s6,16(sp)
    800025fa:	e45e                	sd	s7,8(sp)
    800025fc:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025fe:	00006517          	auipc	a0,0x6
    80002602:	aca50513          	addi	a0,a0,-1334 # 800080c8 <digits+0x88>
    80002606:	ffffe097          	auipc	ra,0xffffe
    8000260a:	f7e080e7          	jalr	-130(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000260e:	0000f497          	auipc	s1,0xf
    80002612:	22a48493          	addi	s1,s1,554 # 80011838 <proc+0x168>
    80002616:	00015917          	auipc	s2,0x15
    8000261a:	02290913          	addi	s2,s2,34 # 80017638 <bcache+0x150>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000261e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002620:	00006997          	auipc	s3,0x6
    80002624:	c6098993          	addi	s3,s3,-928 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002628:	00006a97          	auipc	s5,0x6
    8000262c:	c60a8a93          	addi	s5,s5,-928 # 80008288 <digits+0x248>
    printf("\n");
    80002630:	00006a17          	auipc	s4,0x6
    80002634:	a98a0a13          	addi	s4,s4,-1384 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002638:	00006b97          	auipc	s7,0x6
    8000263c:	cd8b8b93          	addi	s7,s7,-808 # 80008310 <states.1>
    80002640:	a00d                	j	80002662 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002642:	ec86a583          	lw	a1,-312(a3)
    80002646:	8556                	mv	a0,s5
    80002648:	ffffe097          	auipc	ra,0xffffe
    8000264c:	f3c080e7          	jalr	-196(ra) # 80000584 <printf>
    printf("\n");
    80002650:	8552                	mv	a0,s4
    80002652:	ffffe097          	auipc	ra,0xffffe
    80002656:	f32080e7          	jalr	-206(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000265a:	17848493          	addi	s1,s1,376
    8000265e:	03248263          	beq	s1,s2,80002682 <procdump+0x9a>
    if(p->state == UNUSED)
    80002662:	86a6                	mv	a3,s1
    80002664:	eb04a783          	lw	a5,-336(s1)
    80002668:	dbed                	beqz	a5,8000265a <procdump+0x72>
      state = "???";
    8000266a:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000266c:	fcfb6be3          	bltu	s6,a5,80002642 <procdump+0x5a>
    80002670:	02079713          	slli	a4,a5,0x20
    80002674:	01d75793          	srli	a5,a4,0x1d
    80002678:	97de                	add	a5,a5,s7
    8000267a:	6390                	ld	a2,0(a5)
    8000267c:	f279                	bnez	a2,80002642 <procdump+0x5a>
      state = "???";
    8000267e:	864e                	mv	a2,s3
    80002680:	b7c9                	j	80002642 <procdump+0x5a>
  }
}
    80002682:	60a6                	ld	ra,72(sp)
    80002684:	6406                	ld	s0,64(sp)
    80002686:	74e2                	ld	s1,56(sp)
    80002688:	7942                	ld	s2,48(sp)
    8000268a:	79a2                	ld	s3,40(sp)
    8000268c:	7a02                	ld	s4,32(sp)
    8000268e:	6ae2                	ld	s5,24(sp)
    80002690:	6b42                	ld	s6,16(sp)
    80002692:	6ba2                	ld	s7,8(sp)
    80002694:	6161                	addi	sp,sp,80
    80002696:	8082                	ret

0000000080002698 <getppid>:


//------------------Assignment 1(b)-------------------
int
getppid(void)
{
    80002698:	1101                	addi	sp,sp,-32
    8000269a:	ec06                	sd	ra,24(sp)
    8000269c:	e822                	sd	s0,16(sp)
    8000269e:	e426                	sd	s1,8(sp)
    800026a0:	e04a                	sd	s2,0(sp)
    800026a2:	1000                	addi	s0,sp,32
  int ppid;
  struct proc* p = myproc();
    800026a4:	fffff097          	auipc	ra,0xfffff
    800026a8:	2f2080e7          	jalr	754(ra) # 80001996 <myproc>
    800026ac:	84aa                	mv	s1,a0

  acquire(&wait_lock);
    800026ae:	0000f517          	auipc	a0,0xf
    800026b2:	c0a50513          	addi	a0,a0,-1014 # 800112b8 <wait_lock>
    800026b6:	ffffe097          	auipc	ra,0xffffe
    800026ba:	51a080e7          	jalr	1306(ra) # 80000bd0 <acquire>
  struct proc* par = p->parent;
    800026be:	7c84                	ld	s1,56(s1)


  int killed = 0;
  acquire(&par->lock);
    800026c0:	8526                	mv	a0,s1
    800026c2:	ffffe097          	auipc	ra,0xffffe
    800026c6:	50e080e7          	jalr	1294(ra) # 80000bd0 <acquire>
  killed = par->killed;
    800026ca:	0284a903          	lw	s2,40(s1)
  release(&par->lock);
    800026ce:	8526                	mv	a0,s1
    800026d0:	ffffe097          	auipc	ra,0xffffe
    800026d4:	5b4080e7          	jalr	1460(ra) # 80000c84 <release>


  if(killed!=0){
    800026d8:	02091d63          	bnez	s2,80002712 <getppid+0x7a>
    release(&wait_lock);
    return -1;
  }

  acquire(&par->lock);
    800026dc:	8526                	mv	a0,s1
    800026de:	ffffe097          	auipc	ra,0xffffe
    800026e2:	4f2080e7          	jalr	1266(ra) # 80000bd0 <acquire>
  ppid = par->pid;
    800026e6:	0304a903          	lw	s2,48(s1)
  release(&par->lock);
    800026ea:	8526                	mv	a0,s1
    800026ec:	ffffe097          	auipc	ra,0xffffe
    800026f0:	598080e7          	jalr	1432(ra) # 80000c84 <release>

  release(&wait_lock);
    800026f4:	0000f517          	auipc	a0,0xf
    800026f8:	bc450513          	addi	a0,a0,-1084 # 800112b8 <wait_lock>
    800026fc:	ffffe097          	auipc	ra,0xffffe
    80002700:	588080e7          	jalr	1416(ra) # 80000c84 <release>

  return ppid;
}
    80002704:	854a                	mv	a0,s2
    80002706:	60e2                	ld	ra,24(sp)
    80002708:	6442                	ld	s0,16(sp)
    8000270a:	64a2                	ld	s1,8(sp)
    8000270c:	6902                	ld	s2,0(sp)
    8000270e:	6105                	addi	sp,sp,32
    80002710:	8082                	ret
    release(&wait_lock);
    80002712:	0000f517          	auipc	a0,0xf
    80002716:	ba650513          	addi	a0,a0,-1114 # 800112b8 <wait_lock>
    8000271a:	ffffe097          	auipc	ra,0xffffe
    8000271e:	56a080e7          	jalr	1386(ra) # 80000c84 <release>
    return -1;
    80002722:	597d                	li	s2,-1
    80002724:	b7c5                	j	80002704 <getppid+0x6c>

0000000080002726 <waitpid>:


int
waitpid(int givenPid, uint64 addr)
{
    80002726:	711d                	addi	sp,sp,-96
    80002728:	ec86                	sd	ra,88(sp)
    8000272a:	e8a2                	sd	s0,80(sp)
    8000272c:	e4a6                	sd	s1,72(sp)
    8000272e:	e0ca                	sd	s2,64(sp)
    80002730:	fc4e                	sd	s3,56(sp)
    80002732:	f852                	sd	s4,48(sp)
    80002734:	f456                	sd	s5,40(sp)
    80002736:	f05a                	sd	s6,32(sp)
    80002738:	ec5e                	sd	s7,24(sp)
    8000273a:	e862                	sd	s8,16(sp)
    8000273c:	e466                	sd	s9,8(sp)
    8000273e:	e06a                	sd	s10,0(sp)
    80002740:	1080                	addi	s0,sp,96
    80002742:	8a2a                	mv	s4,a0
    80002744:	8cae                	mv	s9,a1
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002746:	fffff097          	auipc	ra,0xfffff
    8000274a:	250080e7          	jalr	592(ra) # 80001996 <myproc>
    8000274e:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002750:	0000f517          	auipc	a0,0xf
    80002754:	b6850513          	addi	a0,a0,-1176 # 800112b8 <wait_lock>
    80002758:	ffffe097          	auipc	ra,0xffffe
    8000275c:	478080e7          	jalr	1144(ra) # 80000bd0 <acquire>
  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    for(np = proc; np < &proc[NPROC]; np++){
      acquire(&np->lock);
      if(np->parent == p && (givenPid == -1 || givenPid == np->pid)){
    80002760:	5afd                	li	s5,-1
        // make sure the child isn't still in exit() or swtch().
        // acquire(&np->lock);

        havekids = 1;
        if(np->state == ZOMBIE){
    80002762:	4b95                	li	s7,5
        havekids = 1;
    80002764:	4c05                	li	s8,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002766:	00015997          	auipc	s3,0x15
    8000276a:	d6a98993          	addi	s3,s3,-662 # 800174d0 <tickslock>
      release(&wait_lock);
      return -1;
    }
    
    // Wait for a child to exit.
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000276e:	0000fd17          	auipc	s10,0xf
    80002772:	b4ad0d13          	addi	s10,s10,-1206 # 800112b8 <wait_lock>
    havekids = 0;
    80002776:	4b01                	li	s6,0
    for(np = proc; np < &proc[NPROC]; np++){
    80002778:	0000f497          	auipc	s1,0xf
    8000277c:	f5848493          	addi	s1,s1,-168 # 800116d0 <proc>
    80002780:	a831                	j	8000279c <waitpid+0x76>
        if(np->state == ZOMBIE){
    80002782:	4c9c                	lw	a5,24(s1)
    80002784:	03778a63          	beq	a5,s7,800027b8 <waitpid+0x92>
        havekids = 1;
    80002788:	8b62                	mv	s6,s8
      release(&np->lock);
    8000278a:	8526                	mv	a0,s1
    8000278c:	ffffe097          	auipc	ra,0xffffe
    80002790:	4f8080e7          	jalr	1272(ra) # 80000c84 <release>
    for(np = proc; np < &proc[NPROC]; np++){
    80002794:	17848493          	addi	s1,s1,376
    80002798:	0b348063          	beq	s1,s3,80002838 <waitpid+0x112>
      acquire(&np->lock);
    8000279c:	8526                	mv	a0,s1
    8000279e:	ffffe097          	auipc	ra,0xffffe
    800027a2:	432080e7          	jalr	1074(ra) # 80000bd0 <acquire>
      if(np->parent == p && (givenPid == -1 || givenPid == np->pid)){
    800027a6:	7c9c                	ld	a5,56(s1)
    800027a8:	ff2791e3          	bne	a5,s2,8000278a <waitpid+0x64>
    800027ac:	fd5a0be3          	beq	s4,s5,80002782 <waitpid+0x5c>
    800027b0:	589c                	lw	a5,48(s1)
    800027b2:	fd479ce3          	bne	a5,s4,8000278a <waitpid+0x64>
    800027b6:	b7f1                	j	80002782 <waitpid+0x5c>
          pid = np->pid;
    800027b8:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800027bc:	000c8e63          	beqz	s9,800027d8 <waitpid+0xb2>
    800027c0:	4691                	li	a3,4
    800027c2:	02c48613          	addi	a2,s1,44
    800027c6:	85e6                	mv	a1,s9
    800027c8:	06093503          	ld	a0,96(s2)
    800027cc:	fffff097          	auipc	ra,0xfffff
    800027d0:	e8e080e7          	jalr	-370(ra) # 8000165a <copyout>
    800027d4:	04054363          	bltz	a0,8000281a <waitpid+0xf4>
          freeproc(np);
    800027d8:	8526                	mv	a0,s1
    800027da:	fffff097          	auipc	ra,0xfffff
    800027de:	3a4080e7          	jalr	932(ra) # 80001b7e <freeproc>
          release(&np->lock);
    800027e2:	8526                	mv	a0,s1
    800027e4:	ffffe097          	auipc	ra,0xffffe
    800027e8:	4a0080e7          	jalr	1184(ra) # 80000c84 <release>
          release(&wait_lock);
    800027ec:	0000f517          	auipc	a0,0xf
    800027f0:	acc50513          	addi	a0,a0,-1332 # 800112b8 <wait_lock>
    800027f4:	ffffe097          	auipc	ra,0xffffe
    800027f8:	490080e7          	jalr	1168(ra) # 80000c84 <release>
  }
}
    800027fc:	854e                	mv	a0,s3
    800027fe:	60e6                	ld	ra,88(sp)
    80002800:	6446                	ld	s0,80(sp)
    80002802:	64a6                	ld	s1,72(sp)
    80002804:	6906                	ld	s2,64(sp)
    80002806:	79e2                	ld	s3,56(sp)
    80002808:	7a42                	ld	s4,48(sp)
    8000280a:	7aa2                	ld	s5,40(sp)
    8000280c:	7b02                	ld	s6,32(sp)
    8000280e:	6be2                	ld	s7,24(sp)
    80002810:	6c42                	ld	s8,16(sp)
    80002812:	6ca2                	ld	s9,8(sp)
    80002814:	6d02                	ld	s10,0(sp)
    80002816:	6125                	addi	sp,sp,96
    80002818:	8082                	ret
            release(&np->lock);
    8000281a:	8526                	mv	a0,s1
    8000281c:	ffffe097          	auipc	ra,0xffffe
    80002820:	468080e7          	jalr	1128(ra) # 80000c84 <release>
            release(&wait_lock);
    80002824:	0000f517          	auipc	a0,0xf
    80002828:	a9450513          	addi	a0,a0,-1388 # 800112b8 <wait_lock>
    8000282c:	ffffe097          	auipc	ra,0xffffe
    80002830:	458080e7          	jalr	1112(ra) # 80000c84 <release>
            return -1;
    80002834:	59fd                	li	s3,-1
    80002836:	b7d9                	j	800027fc <waitpid+0xd6>
    if(!havekids || p->killed){
    80002838:	000b0563          	beqz	s6,80002842 <waitpid+0x11c>
    8000283c:	02892783          	lw	a5,40(s2)
    80002840:	cb99                	beqz	a5,80002856 <waitpid+0x130>
      release(&wait_lock);
    80002842:	0000f517          	auipc	a0,0xf
    80002846:	a7650513          	addi	a0,a0,-1418 # 800112b8 <wait_lock>
    8000284a:	ffffe097          	auipc	ra,0xffffe
    8000284e:	43a080e7          	jalr	1082(ra) # 80000c84 <release>
      return -1;
    80002852:	59fd                	li	s3,-1
    80002854:	b765                	j	800027fc <waitpid+0xd6>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002856:	85ea                	mv	a1,s10
    80002858:	854a                	mv	a0,s2
    8000285a:	00000097          	auipc	ra,0x0
    8000285e:	8e8080e7          	jalr	-1816(ra) # 80002142 <sleep>
    havekids = 0;
    80002862:	bf11                	j	80002776 <waitpid+0x50>

0000000080002864 <ps>:

void ps(void){
    80002864:	7119                	addi	sp,sp,-128
    80002866:	fc86                	sd	ra,120(sp)
    80002868:	f8a2                	sd	s0,112(sp)
    8000286a:	f4a6                	sd	s1,104(sp)
    8000286c:	f0ca                	sd	s2,96(sp)
    8000286e:	ecce                	sd	s3,88(sp)
    80002870:	e8d2                	sd	s4,80(sp)
    80002872:	e4d6                	sd	s5,72(sp)
    80002874:	e0da                	sd	s6,64(sp)
    80002876:	fc5e                	sd	s7,56(sp)
    80002878:	f862                	sd	s8,48(sp)
    8000287a:	f466                	sd	s9,40(sp)
    8000287c:	f06a                	sd	s10,32(sp)
    8000287e:	ec6e                	sd	s11,24(sp)
    80002880:	0100                	addi	s0,sp,128
  struct proc *p;
  char *state;

  int etime=0;

  printf("\n");
    80002882:	00006517          	auipc	a0,0x6
    80002886:	84650513          	addi	a0,a0,-1978 # 800080c8 <digits+0x88>
    8000288a:	ffffe097          	auipc	ra,0xffffe
    8000288e:	cfa080e7          	jalr	-774(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002892:	0000f497          	auipc	s1,0xf
    80002896:	e3e48493          	addi	s1,s1,-450 # 800116d0 <proc>

    if(p->state == UNUSED){
      release(&p->lock);
      continue;
    }
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000289a:	4b15                	li	s6,5
      release(&tickslock);
    }

    release(&p->lock);

    printf("pid=%d, ppid=%d, state=%s, cmd=%s, ctime=%d, stime=%d, etime=%d, size=%p", p->pid, getppid(), state, p->name, p->ctime, p->stime, etime, p->sz);
    8000289c:	00006c97          	auipc	s9,0x6
    800028a0:	9fcc8c93          	addi	s9,s9,-1540 # 80008298 <digits+0x258>
    printf("\n");
    800028a4:	00006c17          	auipc	s8,0x6
    800028a8:	824c0c13          	addi	s8,s8,-2012 # 800080c8 <digits+0x88>
      acquire(&tickslock);
    800028ac:	00015d17          	auipc	s10,0x15
    800028b0:	c24d0d13          	addi	s10,s10,-988 # 800174d0 <tickslock>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028b4:	00006d97          	auipc	s11,0x6
    800028b8:	a5cd8d93          	addi	s11,s11,-1444 # 80008310 <states.1>
  for(p = proc; p < &proc[NPROC]; p++){
    800028bc:	00015b97          	auipc	s7,0x15
    800028c0:	c14b8b93          	addi	s7,s7,-1004 # 800174d0 <tickslock>
    800028c4:	a8b9                	j	80002922 <ps+0xbe>
      release(&p->lock);
    800028c6:	8526                	mv	a0,s1
    800028c8:	ffffe097          	auipc	ra,0xffffe
    800028cc:	3bc080e7          	jalr	956(ra) # 80000c84 <release>
      continue;
    800028d0:	a0a9                	j	8000291a <ps+0xb6>
    if(p->state == 5){
    800028d2:	09679463          	bne	a5,s6,8000295a <ps+0xf6>
      etime = p->etime;
    800028d6:	0484a903          	lw	s2,72(s1)
    release(&p->lock);
    800028da:	8526                	mv	a0,s1
    800028dc:	ffffe097          	auipc	ra,0xffffe
    800028e0:	3a8080e7          	jalr	936(ra) # 80000c84 <release>
    printf("pid=%d, ppid=%d, state=%s, cmd=%s, ctime=%d, stime=%d, etime=%d, size=%p", p->pid, getppid(), state, p->name, p->ctime, p->stime, etime, p->sz);
    800028e4:	0304aa83          	lw	s5,48(s1)
    800028e8:	00000097          	auipc	ra,0x0
    800028ec:	db0080e7          	jalr	-592(ra) # 80002698 <getppid>
    800028f0:	862a                	mv	a2,a0
    800028f2:	6cbc                	ld	a5,88(s1)
    800028f4:	e03e                	sd	a5,0(sp)
    800028f6:	88ca                	mv	a7,s2
    800028f8:	0444a803          	lw	a6,68(s1)
    800028fc:	40bc                	lw	a5,64(s1)
    800028fe:	168a0713          	addi	a4,s4,360
    80002902:	86ce                	mv	a3,s3
    80002904:	85d6                	mv	a1,s5
    80002906:	8566                	mv	a0,s9
    80002908:	ffffe097          	auipc	ra,0xffffe
    8000290c:	c7c080e7          	jalr	-900(ra) # 80000584 <printf>
    printf("\n");
    80002910:	8562                	mv	a0,s8
    80002912:	ffffe097          	auipc	ra,0xffffe
    80002916:	c72080e7          	jalr	-910(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000291a:	17848493          	addi	s1,s1,376
    8000291e:	07748263          	beq	s1,s7,80002982 <ps+0x11e>
    acquire(&p->lock);
    80002922:	8a26                	mv	s4,s1
    80002924:	8526                	mv	a0,s1
    80002926:	ffffe097          	auipc	ra,0xffffe
    8000292a:	2aa080e7          	jalr	682(ra) # 80000bd0 <acquire>
    if(p->state == UNUSED){
    8000292e:	4c9c                	lw	a5,24(s1)
    80002930:	dbd9                	beqz	a5,800028c6 <ps+0x62>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002932:	02fb6063          	bltu	s6,a5,80002952 <ps+0xee>
    80002936:	02079693          	slli	a3,a5,0x20
    8000293a:	01d6d713          	srli	a4,a3,0x1d
    8000293e:	976e                	add	a4,a4,s11
    80002940:	03073983          	ld	s3,48(a4)
    80002944:	f80997e3          	bnez	s3,800028d2 <ps+0x6e>
      state = "???";
    80002948:	00006997          	auipc	s3,0x6
    8000294c:	93898993          	addi	s3,s3,-1736 # 80008280 <digits+0x240>
    80002950:	b749                	j	800028d2 <ps+0x6e>
    80002952:	00006997          	auipc	s3,0x6
    80002956:	92e98993          	addi	s3,s3,-1746 # 80008280 <digits+0x240>
      acquire(&tickslock);
    8000295a:	856a                	mv	a0,s10
    8000295c:	ffffe097          	auipc	ra,0xffffe
    80002960:	274080e7          	jalr	628(ra) # 80000bd0 <acquire>
      etime = ticks-p->stime;
    80002964:	00006797          	auipc	a5,0x6
    80002968:	6cc78793          	addi	a5,a5,1740 # 80009030 <ticks>
    8000296c:	0007a903          	lw	s2,0(a5)
    80002970:	40fc                	lw	a5,68(s1)
    80002972:	40f9093b          	subw	s2,s2,a5
      release(&tickslock);
    80002976:	856a                	mv	a0,s10
    80002978:	ffffe097          	auipc	ra,0xffffe
    8000297c:	30c080e7          	jalr	780(ra) # 80000c84 <release>
    80002980:	bfa9                	j	800028da <ps+0x76>
  }
  return;
    80002982:	70e6                	ld	ra,120(sp)
    80002984:	7446                	ld	s0,112(sp)
    80002986:	74a6                	ld	s1,104(sp)
    80002988:	7906                	ld	s2,96(sp)
    8000298a:	69e6                	ld	s3,88(sp)
    8000298c:	6a46                	ld	s4,80(sp)
    8000298e:	6aa6                	ld	s5,72(sp)
    80002990:	6b06                	ld	s6,64(sp)
    80002992:	7be2                	ld	s7,56(sp)
    80002994:	7c42                	ld	s8,48(sp)
    80002996:	7ca2                	ld	s9,40(sp)
    80002998:	7d02                	ld	s10,32(sp)
    8000299a:	6de2                	ld	s11,24(sp)
    8000299c:	6109                	addi	sp,sp,128
    8000299e:	8082                	ret

00000000800029a0 <swtch>:
    800029a0:	00153023          	sd	ra,0(a0)
    800029a4:	00253423          	sd	sp,8(a0)
    800029a8:	e900                	sd	s0,16(a0)
    800029aa:	ed04                	sd	s1,24(a0)
    800029ac:	03253023          	sd	s2,32(a0)
    800029b0:	03353423          	sd	s3,40(a0)
    800029b4:	03453823          	sd	s4,48(a0)
    800029b8:	03553c23          	sd	s5,56(a0)
    800029bc:	05653023          	sd	s6,64(a0)
    800029c0:	05753423          	sd	s7,72(a0)
    800029c4:	05853823          	sd	s8,80(a0)
    800029c8:	05953c23          	sd	s9,88(a0)
    800029cc:	07a53023          	sd	s10,96(a0)
    800029d0:	07b53423          	sd	s11,104(a0)
    800029d4:	0005b083          	ld	ra,0(a1)
    800029d8:	0085b103          	ld	sp,8(a1)
    800029dc:	6980                	ld	s0,16(a1)
    800029de:	6d84                	ld	s1,24(a1)
    800029e0:	0205b903          	ld	s2,32(a1)
    800029e4:	0285b983          	ld	s3,40(a1)
    800029e8:	0305ba03          	ld	s4,48(a1)
    800029ec:	0385ba83          	ld	s5,56(a1)
    800029f0:	0405bb03          	ld	s6,64(a1)
    800029f4:	0485bb83          	ld	s7,72(a1)
    800029f8:	0505bc03          	ld	s8,80(a1)
    800029fc:	0585bc83          	ld	s9,88(a1)
    80002a00:	0605bd03          	ld	s10,96(a1)
    80002a04:	0685bd83          	ld	s11,104(a1)
    80002a08:	8082                	ret

0000000080002a0a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002a0a:	1141                	addi	sp,sp,-16
    80002a0c:	e406                	sd	ra,8(sp)
    80002a0e:	e022                	sd	s0,0(sp)
    80002a10:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002a12:	00006597          	auipc	a1,0x6
    80002a16:	95e58593          	addi	a1,a1,-1698 # 80008370 <states.0+0x30>
    80002a1a:	00015517          	auipc	a0,0x15
    80002a1e:	ab650513          	addi	a0,a0,-1354 # 800174d0 <tickslock>
    80002a22:	ffffe097          	auipc	ra,0xffffe
    80002a26:	11e080e7          	jalr	286(ra) # 80000b40 <initlock>
}
    80002a2a:	60a2                	ld	ra,8(sp)
    80002a2c:	6402                	ld	s0,0(sp)
    80002a2e:	0141                	addi	sp,sp,16
    80002a30:	8082                	ret

0000000080002a32 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002a32:	1141                	addi	sp,sp,-16
    80002a34:	e422                	sd	s0,8(sp)
    80002a36:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a38:	00003797          	auipc	a5,0x3
    80002a3c:	58878793          	addi	a5,a5,1416 # 80005fc0 <kernelvec>
    80002a40:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002a44:	6422                	ld	s0,8(sp)
    80002a46:	0141                	addi	sp,sp,16
    80002a48:	8082                	ret

0000000080002a4a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002a4a:	1141                	addi	sp,sp,-16
    80002a4c:	e406                	sd	ra,8(sp)
    80002a4e:	e022                	sd	s0,0(sp)
    80002a50:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002a52:	fffff097          	auipc	ra,0xfffff
    80002a56:	f44080e7          	jalr	-188(ra) # 80001996 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a5a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002a5e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a60:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002a64:	00004697          	auipc	a3,0x4
    80002a68:	59c68693          	addi	a3,a3,1436 # 80007000 <_trampoline>
    80002a6c:	00004717          	auipc	a4,0x4
    80002a70:	59470713          	addi	a4,a4,1428 # 80007000 <_trampoline>
    80002a74:	8f15                	sub	a4,a4,a3
    80002a76:	040007b7          	lui	a5,0x4000
    80002a7a:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002a7c:	07b2                	slli	a5,a5,0xc
    80002a7e:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a80:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002a84:	7538                	ld	a4,104(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002a86:	18002673          	csrr	a2,satp
    80002a8a:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002a8c:	7530                	ld	a2,104(a0)
    80002a8e:	6938                	ld	a4,80(a0)
    80002a90:	6585                	lui	a1,0x1
    80002a92:	972e                	add	a4,a4,a1
    80002a94:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a96:	7538                	ld	a4,104(a0)
    80002a98:	00000617          	auipc	a2,0x0
    80002a9c:	13860613          	addi	a2,a2,312 # 80002bd0 <usertrap>
    80002aa0:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002aa2:	7538                	ld	a4,104(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002aa4:	8612                	mv	a2,tp
    80002aa6:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aa8:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002aac:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002ab0:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ab4:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002ab8:	7538                	ld	a4,104(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002aba:	6f18                	ld	a4,24(a4)
    80002abc:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002ac0:	712c                	ld	a1,96(a0)
    80002ac2:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002ac4:	00004717          	auipc	a4,0x4
    80002ac8:	5cc70713          	addi	a4,a4,1484 # 80007090 <userret>
    80002acc:	8f15                	sub	a4,a4,a3
    80002ace:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002ad0:	577d                	li	a4,-1
    80002ad2:	177e                	slli	a4,a4,0x3f
    80002ad4:	8dd9                	or	a1,a1,a4
    80002ad6:	02000537          	lui	a0,0x2000
    80002ada:	157d                	addi	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    80002adc:	0536                	slli	a0,a0,0xd
    80002ade:	9782                	jalr	a5
}
    80002ae0:	60a2                	ld	ra,8(sp)
    80002ae2:	6402                	ld	s0,0(sp)
    80002ae4:	0141                	addi	sp,sp,16
    80002ae6:	8082                	ret

0000000080002ae8 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002ae8:	1101                	addi	sp,sp,-32
    80002aea:	ec06                	sd	ra,24(sp)
    80002aec:	e822                	sd	s0,16(sp)
    80002aee:	e426                	sd	s1,8(sp)
    80002af0:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002af2:	00015497          	auipc	s1,0x15
    80002af6:	9de48493          	addi	s1,s1,-1570 # 800174d0 <tickslock>
    80002afa:	8526                	mv	a0,s1
    80002afc:	ffffe097          	auipc	ra,0xffffe
    80002b00:	0d4080e7          	jalr	212(ra) # 80000bd0 <acquire>
  ticks++;
    80002b04:	00006517          	auipc	a0,0x6
    80002b08:	52c50513          	addi	a0,a0,1324 # 80009030 <ticks>
    80002b0c:	411c                	lw	a5,0(a0)
    80002b0e:	2785                	addiw	a5,a5,1
    80002b10:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002b12:	fffff097          	auipc	ra,0xfffff
    80002b16:	7bc080e7          	jalr	1980(ra) # 800022ce <wakeup>
  release(&tickslock);
    80002b1a:	8526                	mv	a0,s1
    80002b1c:	ffffe097          	auipc	ra,0xffffe
    80002b20:	168080e7          	jalr	360(ra) # 80000c84 <release>
}
    80002b24:	60e2                	ld	ra,24(sp)
    80002b26:	6442                	ld	s0,16(sp)
    80002b28:	64a2                	ld	s1,8(sp)
    80002b2a:	6105                	addi	sp,sp,32
    80002b2c:	8082                	ret

0000000080002b2e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002b2e:	1101                	addi	sp,sp,-32
    80002b30:	ec06                	sd	ra,24(sp)
    80002b32:	e822                	sd	s0,16(sp)
    80002b34:	e426                	sd	s1,8(sp)
    80002b36:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b38:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002b3c:	00074d63          	bltz	a4,80002b56 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002b40:	57fd                	li	a5,-1
    80002b42:	17fe                	slli	a5,a5,0x3f
    80002b44:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002b46:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002b48:	06f70363          	beq	a4,a5,80002bae <devintr+0x80>
  }
}
    80002b4c:	60e2                	ld	ra,24(sp)
    80002b4e:	6442                	ld	s0,16(sp)
    80002b50:	64a2                	ld	s1,8(sp)
    80002b52:	6105                	addi	sp,sp,32
    80002b54:	8082                	ret
     (scause & 0xff) == 9){
    80002b56:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002b5a:	46a5                	li	a3,9
    80002b5c:	fed792e3          	bne	a5,a3,80002b40 <devintr+0x12>
    int irq = plic_claim();
    80002b60:	00003097          	auipc	ra,0x3
    80002b64:	568080e7          	jalr	1384(ra) # 800060c8 <plic_claim>
    80002b68:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002b6a:	47a9                	li	a5,10
    80002b6c:	02f50763          	beq	a0,a5,80002b9a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002b70:	4785                	li	a5,1
    80002b72:	02f50963          	beq	a0,a5,80002ba4 <devintr+0x76>
    return 1;
    80002b76:	4505                	li	a0,1
    } else if(irq){
    80002b78:	d8f1                	beqz	s1,80002b4c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002b7a:	85a6                	mv	a1,s1
    80002b7c:	00005517          	auipc	a0,0x5
    80002b80:	7fc50513          	addi	a0,a0,2044 # 80008378 <states.0+0x38>
    80002b84:	ffffe097          	auipc	ra,0xffffe
    80002b88:	a00080e7          	jalr	-1536(ra) # 80000584 <printf>
      plic_complete(irq);
    80002b8c:	8526                	mv	a0,s1
    80002b8e:	00003097          	auipc	ra,0x3
    80002b92:	55e080e7          	jalr	1374(ra) # 800060ec <plic_complete>
    return 1;
    80002b96:	4505                	li	a0,1
    80002b98:	bf55                	j	80002b4c <devintr+0x1e>
      uartintr();
    80002b9a:	ffffe097          	auipc	ra,0xffffe
    80002b9e:	df8080e7          	jalr	-520(ra) # 80000992 <uartintr>
    80002ba2:	b7ed                	j	80002b8c <devintr+0x5e>
      virtio_disk_intr();
    80002ba4:	00004097          	auipc	ra,0x4
    80002ba8:	9d4080e7          	jalr	-1580(ra) # 80006578 <virtio_disk_intr>
    80002bac:	b7c5                	j	80002b8c <devintr+0x5e>
    if(cpuid() == 0){
    80002bae:	fffff097          	auipc	ra,0xfffff
    80002bb2:	dbc080e7          	jalr	-580(ra) # 8000196a <cpuid>
    80002bb6:	c901                	beqz	a0,80002bc6 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002bb8:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002bbc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002bbe:	14479073          	csrw	sip,a5
    return 2;
    80002bc2:	4509                	li	a0,2
    80002bc4:	b761                	j	80002b4c <devintr+0x1e>
      clockintr();
    80002bc6:	00000097          	auipc	ra,0x0
    80002bca:	f22080e7          	jalr	-222(ra) # 80002ae8 <clockintr>
    80002bce:	b7ed                	j	80002bb8 <devintr+0x8a>

0000000080002bd0 <usertrap>:
{
    80002bd0:	1101                	addi	sp,sp,-32
    80002bd2:	ec06                	sd	ra,24(sp)
    80002bd4:	e822                	sd	s0,16(sp)
    80002bd6:	e426                	sd	s1,8(sp)
    80002bd8:	e04a                	sd	s2,0(sp)
    80002bda:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bdc:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002be0:	1007f793          	andi	a5,a5,256
    80002be4:	e3ad                	bnez	a5,80002c46 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002be6:	00003797          	auipc	a5,0x3
    80002bea:	3da78793          	addi	a5,a5,986 # 80005fc0 <kernelvec>
    80002bee:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002bf2:	fffff097          	auipc	ra,0xfffff
    80002bf6:	da4080e7          	jalr	-604(ra) # 80001996 <myproc>
    80002bfa:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002bfc:	753c                	ld	a5,104(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bfe:	14102773          	csrr	a4,sepc
    80002c02:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c04:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002c08:	47a1                	li	a5,8
    80002c0a:	04f71c63          	bne	a4,a5,80002c62 <usertrap+0x92>
    if(p->killed)
    80002c0e:	551c                	lw	a5,40(a0)
    80002c10:	e3b9                	bnez	a5,80002c56 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002c12:	74b8                	ld	a4,104(s1)
    80002c14:	6f1c                	ld	a5,24(a4)
    80002c16:	0791                	addi	a5,a5,4
    80002c18:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c1a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002c1e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c22:	10079073          	csrw	sstatus,a5
    syscall();
    80002c26:	00000097          	auipc	ra,0x0
    80002c2a:	2e0080e7          	jalr	736(ra) # 80002f06 <syscall>
  if(p->killed)
    80002c2e:	549c                	lw	a5,40(s1)
    80002c30:	ebc1                	bnez	a5,80002cc0 <usertrap+0xf0>
  usertrapret();
    80002c32:	00000097          	auipc	ra,0x0
    80002c36:	e18080e7          	jalr	-488(ra) # 80002a4a <usertrapret>
}
    80002c3a:	60e2                	ld	ra,24(sp)
    80002c3c:	6442                	ld	s0,16(sp)
    80002c3e:	64a2                	ld	s1,8(sp)
    80002c40:	6902                	ld	s2,0(sp)
    80002c42:	6105                	addi	sp,sp,32
    80002c44:	8082                	ret
    panic("usertrap: not from user mode");
    80002c46:	00005517          	auipc	a0,0x5
    80002c4a:	75250513          	addi	a0,a0,1874 # 80008398 <states.0+0x58>
    80002c4e:	ffffe097          	auipc	ra,0xffffe
    80002c52:	8ec080e7          	jalr	-1812(ra) # 8000053a <panic>
      exit(-1);
    80002c56:	557d                	li	a0,-1
    80002c58:	fffff097          	auipc	ra,0xfffff
    80002c5c:	746080e7          	jalr	1862(ra) # 8000239e <exit>
    80002c60:	bf4d                	j	80002c12 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002c62:	00000097          	auipc	ra,0x0
    80002c66:	ecc080e7          	jalr	-308(ra) # 80002b2e <devintr>
    80002c6a:	892a                	mv	s2,a0
    80002c6c:	c501                	beqz	a0,80002c74 <usertrap+0xa4>
  if(p->killed)
    80002c6e:	549c                	lw	a5,40(s1)
    80002c70:	c3a1                	beqz	a5,80002cb0 <usertrap+0xe0>
    80002c72:	a815                	j	80002ca6 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c74:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c78:	5890                	lw	a2,48(s1)
    80002c7a:	00005517          	auipc	a0,0x5
    80002c7e:	73e50513          	addi	a0,a0,1854 # 800083b8 <states.0+0x78>
    80002c82:	ffffe097          	auipc	ra,0xffffe
    80002c86:	902080e7          	jalr	-1790(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c8a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c8e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c92:	00005517          	auipc	a0,0x5
    80002c96:	75650513          	addi	a0,a0,1878 # 800083e8 <states.0+0xa8>
    80002c9a:	ffffe097          	auipc	ra,0xffffe
    80002c9e:	8ea080e7          	jalr	-1814(ra) # 80000584 <printf>
    p->killed = 1;
    80002ca2:	4785                	li	a5,1
    80002ca4:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002ca6:	557d                	li	a0,-1
    80002ca8:	fffff097          	auipc	ra,0xfffff
    80002cac:	6f6080e7          	jalr	1782(ra) # 8000239e <exit>
  if(which_dev == 2)
    80002cb0:	4789                	li	a5,2
    80002cb2:	f8f910e3          	bne	s2,a5,80002c32 <usertrap+0x62>
    yield();
    80002cb6:	fffff097          	auipc	ra,0xfffff
    80002cba:	450080e7          	jalr	1104(ra) # 80002106 <yield>
    80002cbe:	bf95                	j	80002c32 <usertrap+0x62>
  int which_dev = 0;
    80002cc0:	4901                	li	s2,0
    80002cc2:	b7d5                	j	80002ca6 <usertrap+0xd6>

0000000080002cc4 <kerneltrap>:
{
    80002cc4:	7179                	addi	sp,sp,-48
    80002cc6:	f406                	sd	ra,40(sp)
    80002cc8:	f022                	sd	s0,32(sp)
    80002cca:	ec26                	sd	s1,24(sp)
    80002ccc:	e84a                	sd	s2,16(sp)
    80002cce:	e44e                	sd	s3,8(sp)
    80002cd0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cd2:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cd6:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cda:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002cde:	1004f793          	andi	a5,s1,256
    80002ce2:	cb85                	beqz	a5,80002d12 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ce4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002ce8:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002cea:	ef85                	bnez	a5,80002d22 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002cec:	00000097          	auipc	ra,0x0
    80002cf0:	e42080e7          	jalr	-446(ra) # 80002b2e <devintr>
    80002cf4:	cd1d                	beqz	a0,80002d32 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cf6:	4789                	li	a5,2
    80002cf8:	06f50a63          	beq	a0,a5,80002d6c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002cfc:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d00:	10049073          	csrw	sstatus,s1
}
    80002d04:	70a2                	ld	ra,40(sp)
    80002d06:	7402                	ld	s0,32(sp)
    80002d08:	64e2                	ld	s1,24(sp)
    80002d0a:	6942                	ld	s2,16(sp)
    80002d0c:	69a2                	ld	s3,8(sp)
    80002d0e:	6145                	addi	sp,sp,48
    80002d10:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002d12:	00005517          	auipc	a0,0x5
    80002d16:	6f650513          	addi	a0,a0,1782 # 80008408 <states.0+0xc8>
    80002d1a:	ffffe097          	auipc	ra,0xffffe
    80002d1e:	820080e7          	jalr	-2016(ra) # 8000053a <panic>
    panic("kerneltrap: interrupts enabled");
    80002d22:	00005517          	auipc	a0,0x5
    80002d26:	70e50513          	addi	a0,a0,1806 # 80008430 <states.0+0xf0>
    80002d2a:	ffffe097          	auipc	ra,0xffffe
    80002d2e:	810080e7          	jalr	-2032(ra) # 8000053a <panic>
    printf("scause %p\n", scause);
    80002d32:	85ce                	mv	a1,s3
    80002d34:	00005517          	auipc	a0,0x5
    80002d38:	71c50513          	addi	a0,a0,1820 # 80008450 <states.0+0x110>
    80002d3c:	ffffe097          	auipc	ra,0xffffe
    80002d40:	848080e7          	jalr	-1976(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d44:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d48:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d4c:	00005517          	auipc	a0,0x5
    80002d50:	71450513          	addi	a0,a0,1812 # 80008460 <states.0+0x120>
    80002d54:	ffffe097          	auipc	ra,0xffffe
    80002d58:	830080e7          	jalr	-2000(ra) # 80000584 <printf>
    panic("kerneltrap");
    80002d5c:	00005517          	auipc	a0,0x5
    80002d60:	71c50513          	addi	a0,a0,1820 # 80008478 <states.0+0x138>
    80002d64:	ffffd097          	auipc	ra,0xffffd
    80002d68:	7d6080e7          	jalr	2006(ra) # 8000053a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d6c:	fffff097          	auipc	ra,0xfffff
    80002d70:	c2a080e7          	jalr	-982(ra) # 80001996 <myproc>
    80002d74:	d541                	beqz	a0,80002cfc <kerneltrap+0x38>
    80002d76:	fffff097          	auipc	ra,0xfffff
    80002d7a:	c20080e7          	jalr	-992(ra) # 80001996 <myproc>
    80002d7e:	4d18                	lw	a4,24(a0)
    80002d80:	4791                	li	a5,4
    80002d82:	f6f71de3          	bne	a4,a5,80002cfc <kerneltrap+0x38>
    yield();
    80002d86:	fffff097          	auipc	ra,0xfffff
    80002d8a:	380080e7          	jalr	896(ra) # 80002106 <yield>
    80002d8e:	b7bd                	j	80002cfc <kerneltrap+0x38>

0000000080002d90 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d90:	1101                	addi	sp,sp,-32
    80002d92:	ec06                	sd	ra,24(sp)
    80002d94:	e822                	sd	s0,16(sp)
    80002d96:	e426                	sd	s1,8(sp)
    80002d98:	1000                	addi	s0,sp,32
    80002d9a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d9c:	fffff097          	auipc	ra,0xfffff
    80002da0:	bfa080e7          	jalr	-1030(ra) # 80001996 <myproc>
  switch (n) {
    80002da4:	4795                	li	a5,5
    80002da6:	0497e163          	bltu	a5,s1,80002de8 <argraw+0x58>
    80002daa:	048a                	slli	s1,s1,0x2
    80002dac:	00005717          	auipc	a4,0x5
    80002db0:	70470713          	addi	a4,a4,1796 # 800084b0 <states.0+0x170>
    80002db4:	94ba                	add	s1,s1,a4
    80002db6:	409c                	lw	a5,0(s1)
    80002db8:	97ba                	add	a5,a5,a4
    80002dba:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002dbc:	753c                	ld	a5,104(a0)
    80002dbe:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002dc0:	60e2                	ld	ra,24(sp)
    80002dc2:	6442                	ld	s0,16(sp)
    80002dc4:	64a2                	ld	s1,8(sp)
    80002dc6:	6105                	addi	sp,sp,32
    80002dc8:	8082                	ret
    return p->trapframe->a1;
    80002dca:	753c                	ld	a5,104(a0)
    80002dcc:	7fa8                	ld	a0,120(a5)
    80002dce:	bfcd                	j	80002dc0 <argraw+0x30>
    return p->trapframe->a2;
    80002dd0:	753c                	ld	a5,104(a0)
    80002dd2:	63c8                	ld	a0,128(a5)
    80002dd4:	b7f5                	j	80002dc0 <argraw+0x30>
    return p->trapframe->a3;
    80002dd6:	753c                	ld	a5,104(a0)
    80002dd8:	67c8                	ld	a0,136(a5)
    80002dda:	b7dd                	j	80002dc0 <argraw+0x30>
    return p->trapframe->a4;
    80002ddc:	753c                	ld	a5,104(a0)
    80002dde:	6bc8                	ld	a0,144(a5)
    80002de0:	b7c5                	j	80002dc0 <argraw+0x30>
    return p->trapframe->a5;
    80002de2:	753c                	ld	a5,104(a0)
    80002de4:	6fc8                	ld	a0,152(a5)
    80002de6:	bfe9                	j	80002dc0 <argraw+0x30>
  panic("argraw");
    80002de8:	00005517          	auipc	a0,0x5
    80002dec:	6a050513          	addi	a0,a0,1696 # 80008488 <states.0+0x148>
    80002df0:	ffffd097          	auipc	ra,0xffffd
    80002df4:	74a080e7          	jalr	1866(ra) # 8000053a <panic>

0000000080002df8 <fetchaddr>:
{
    80002df8:	1101                	addi	sp,sp,-32
    80002dfa:	ec06                	sd	ra,24(sp)
    80002dfc:	e822                	sd	s0,16(sp)
    80002dfe:	e426                	sd	s1,8(sp)
    80002e00:	e04a                	sd	s2,0(sp)
    80002e02:	1000                	addi	s0,sp,32
    80002e04:	84aa                	mv	s1,a0
    80002e06:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002e08:	fffff097          	auipc	ra,0xfffff
    80002e0c:	b8e080e7          	jalr	-1138(ra) # 80001996 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002e10:	6d3c                	ld	a5,88(a0)
    80002e12:	02f4f863          	bgeu	s1,a5,80002e42 <fetchaddr+0x4a>
    80002e16:	00848713          	addi	a4,s1,8
    80002e1a:	02e7e663          	bltu	a5,a4,80002e46 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002e1e:	46a1                	li	a3,8
    80002e20:	8626                	mv	a2,s1
    80002e22:	85ca                	mv	a1,s2
    80002e24:	7128                	ld	a0,96(a0)
    80002e26:	fffff097          	auipc	ra,0xfffff
    80002e2a:	8c0080e7          	jalr	-1856(ra) # 800016e6 <copyin>
    80002e2e:	00a03533          	snez	a0,a0
    80002e32:	40a00533          	neg	a0,a0
}
    80002e36:	60e2                	ld	ra,24(sp)
    80002e38:	6442                	ld	s0,16(sp)
    80002e3a:	64a2                	ld	s1,8(sp)
    80002e3c:	6902                	ld	s2,0(sp)
    80002e3e:	6105                	addi	sp,sp,32
    80002e40:	8082                	ret
    return -1;
    80002e42:	557d                	li	a0,-1
    80002e44:	bfcd                	j	80002e36 <fetchaddr+0x3e>
    80002e46:	557d                	li	a0,-1
    80002e48:	b7fd                	j	80002e36 <fetchaddr+0x3e>

0000000080002e4a <fetchstr>:
{
    80002e4a:	7179                	addi	sp,sp,-48
    80002e4c:	f406                	sd	ra,40(sp)
    80002e4e:	f022                	sd	s0,32(sp)
    80002e50:	ec26                	sd	s1,24(sp)
    80002e52:	e84a                	sd	s2,16(sp)
    80002e54:	e44e                	sd	s3,8(sp)
    80002e56:	1800                	addi	s0,sp,48
    80002e58:	892a                	mv	s2,a0
    80002e5a:	84ae                	mv	s1,a1
    80002e5c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002e5e:	fffff097          	auipc	ra,0xfffff
    80002e62:	b38080e7          	jalr	-1224(ra) # 80001996 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002e66:	86ce                	mv	a3,s3
    80002e68:	864a                	mv	a2,s2
    80002e6a:	85a6                	mv	a1,s1
    80002e6c:	7128                	ld	a0,96(a0)
    80002e6e:	fffff097          	auipc	ra,0xfffff
    80002e72:	906080e7          	jalr	-1786(ra) # 80001774 <copyinstr>
  if(err < 0)
    80002e76:	00054763          	bltz	a0,80002e84 <fetchstr+0x3a>
  return strlen(buf);
    80002e7a:	8526                	mv	a0,s1
    80002e7c:	ffffe097          	auipc	ra,0xffffe
    80002e80:	fcc080e7          	jalr	-52(ra) # 80000e48 <strlen>
}
    80002e84:	70a2                	ld	ra,40(sp)
    80002e86:	7402                	ld	s0,32(sp)
    80002e88:	64e2                	ld	s1,24(sp)
    80002e8a:	6942                	ld	s2,16(sp)
    80002e8c:	69a2                	ld	s3,8(sp)
    80002e8e:	6145                	addi	sp,sp,48
    80002e90:	8082                	ret

0000000080002e92 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002e92:	1101                	addi	sp,sp,-32
    80002e94:	ec06                	sd	ra,24(sp)
    80002e96:	e822                	sd	s0,16(sp)
    80002e98:	e426                	sd	s1,8(sp)
    80002e9a:	1000                	addi	s0,sp,32
    80002e9c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e9e:	00000097          	auipc	ra,0x0
    80002ea2:	ef2080e7          	jalr	-270(ra) # 80002d90 <argraw>
    80002ea6:	c088                	sw	a0,0(s1)
  return 0;
}
    80002ea8:	4501                	li	a0,0
    80002eaa:	60e2                	ld	ra,24(sp)
    80002eac:	6442                	ld	s0,16(sp)
    80002eae:	64a2                	ld	s1,8(sp)
    80002eb0:	6105                	addi	sp,sp,32
    80002eb2:	8082                	ret

0000000080002eb4 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002eb4:	1101                	addi	sp,sp,-32
    80002eb6:	ec06                	sd	ra,24(sp)
    80002eb8:	e822                	sd	s0,16(sp)
    80002eba:	e426                	sd	s1,8(sp)
    80002ebc:	1000                	addi	s0,sp,32
    80002ebe:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ec0:	00000097          	auipc	ra,0x0
    80002ec4:	ed0080e7          	jalr	-304(ra) # 80002d90 <argraw>
    80002ec8:	e088                	sd	a0,0(s1)
  return 0;
}
    80002eca:	4501                	li	a0,0
    80002ecc:	60e2                	ld	ra,24(sp)
    80002ece:	6442                	ld	s0,16(sp)
    80002ed0:	64a2                	ld	s1,8(sp)
    80002ed2:	6105                	addi	sp,sp,32
    80002ed4:	8082                	ret

0000000080002ed6 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ed6:	1101                	addi	sp,sp,-32
    80002ed8:	ec06                	sd	ra,24(sp)
    80002eda:	e822                	sd	s0,16(sp)
    80002edc:	e426                	sd	s1,8(sp)
    80002ede:	e04a                	sd	s2,0(sp)
    80002ee0:	1000                	addi	s0,sp,32
    80002ee2:	84ae                	mv	s1,a1
    80002ee4:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002ee6:	00000097          	auipc	ra,0x0
    80002eea:	eaa080e7          	jalr	-342(ra) # 80002d90 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002eee:	864a                	mv	a2,s2
    80002ef0:	85a6                	mv	a1,s1
    80002ef2:	00000097          	auipc	ra,0x0
    80002ef6:	f58080e7          	jalr	-168(ra) # 80002e4a <fetchstr>
}
    80002efa:	60e2                	ld	ra,24(sp)
    80002efc:	6442                	ld	s0,16(sp)
    80002efe:	64a2                	ld	s1,8(sp)
    80002f00:	6902                	ld	s2,0(sp)
    80002f02:	6105                	addi	sp,sp,32
    80002f04:	8082                	ret

0000000080002f06 <syscall>:
[SYS_ps] sys_ps
};

void
syscall(void)
{
    80002f06:	1101                	addi	sp,sp,-32
    80002f08:	ec06                	sd	ra,24(sp)
    80002f0a:	e822                	sd	s0,16(sp)
    80002f0c:	e426                	sd	s1,8(sp)
    80002f0e:	e04a                	sd	s2,0(sp)
    80002f10:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002f12:	fffff097          	auipc	ra,0xfffff
    80002f16:	a84080e7          	jalr	-1404(ra) # 80001996 <myproc>
    80002f1a:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002f1c:	06853903          	ld	s2,104(a0)
    80002f20:	0a893783          	ld	a5,168(s2)
    80002f24:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002f28:	37fd                	addiw	a5,a5,-1
    80002f2a:	4769                	li	a4,26
    80002f2c:	00f76f63          	bltu	a4,a5,80002f4a <syscall+0x44>
    80002f30:	00369713          	slli	a4,a3,0x3
    80002f34:	00005797          	auipc	a5,0x5
    80002f38:	59478793          	addi	a5,a5,1428 # 800084c8 <syscalls>
    80002f3c:	97ba                	add	a5,a5,a4
    80002f3e:	639c                	ld	a5,0(a5)
    80002f40:	c789                	beqz	a5,80002f4a <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002f42:	9782                	jalr	a5
    80002f44:	06a93823          	sd	a0,112(s2)
    80002f48:	a839                	j	80002f66 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002f4a:	16848613          	addi	a2,s1,360
    80002f4e:	588c                	lw	a1,48(s1)
    80002f50:	00005517          	auipc	a0,0x5
    80002f54:	54050513          	addi	a0,a0,1344 # 80008490 <states.0+0x150>
    80002f58:	ffffd097          	auipc	ra,0xffffd
    80002f5c:	62c080e7          	jalr	1580(ra) # 80000584 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002f60:	74bc                	ld	a5,104(s1)
    80002f62:	577d                	li	a4,-1
    80002f64:	fbb8                	sd	a4,112(a5)
  }
}
    80002f66:	60e2                	ld	ra,24(sp)
    80002f68:	6442                	ld	s0,16(sp)
    80002f6a:	64a2                	ld	s1,8(sp)
    80002f6c:	6902                	ld	s2,0(sp)
    80002f6e:	6105                	addi	sp,sp,32
    80002f70:	8082                	ret

0000000080002f72 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002f72:	1101                	addi	sp,sp,-32
    80002f74:	ec06                	sd	ra,24(sp)
    80002f76:	e822                	sd	s0,16(sp)
    80002f78:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002f7a:	fec40593          	addi	a1,s0,-20
    80002f7e:	4501                	li	a0,0
    80002f80:	00000097          	auipc	ra,0x0
    80002f84:	f12080e7          	jalr	-238(ra) # 80002e92 <argint>
    return -1;
    80002f88:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f8a:	00054963          	bltz	a0,80002f9c <sys_exit+0x2a>
  exit(n);
    80002f8e:	fec42503          	lw	a0,-20(s0)
    80002f92:	fffff097          	auipc	ra,0xfffff
    80002f96:	40c080e7          	jalr	1036(ra) # 8000239e <exit>
  return 0;  // not reached
    80002f9a:	4781                	li	a5,0
}
    80002f9c:	853e                	mv	a0,a5
    80002f9e:	60e2                	ld	ra,24(sp)
    80002fa0:	6442                	ld	s0,16(sp)
    80002fa2:	6105                	addi	sp,sp,32
    80002fa4:	8082                	ret

0000000080002fa6 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002fa6:	1141                	addi	sp,sp,-16
    80002fa8:	e406                	sd	ra,8(sp)
    80002faa:	e022                	sd	s0,0(sp)
    80002fac:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002fae:	fffff097          	auipc	ra,0xfffff
    80002fb2:	9e8080e7          	jalr	-1560(ra) # 80001996 <myproc>
}
    80002fb6:	5908                	lw	a0,48(a0)
    80002fb8:	60a2                	ld	ra,8(sp)
    80002fba:	6402                	ld	s0,0(sp)
    80002fbc:	0141                	addi	sp,sp,16
    80002fbe:	8082                	ret

0000000080002fc0 <sys_fork>:

uint64
sys_fork(void)
{
    80002fc0:	1141                	addi	sp,sp,-16
    80002fc2:	e406                	sd	ra,8(sp)
    80002fc4:	e022                	sd	s0,0(sp)
    80002fc6:	0800                	addi	s0,sp,16
  return fork();
    80002fc8:	fffff097          	auipc	ra,0xfffff
    80002fcc:	e2e080e7          	jalr	-466(ra) # 80001df6 <fork>
}
    80002fd0:	60a2                	ld	ra,8(sp)
    80002fd2:	6402                	ld	s0,0(sp)
    80002fd4:	0141                	addi	sp,sp,16
    80002fd6:	8082                	ret

0000000080002fd8 <sys_wait>:

uint64
sys_wait(void)
{
    80002fd8:	1101                	addi	sp,sp,-32
    80002fda:	ec06                	sd	ra,24(sp)
    80002fdc:	e822                	sd	s0,16(sp)
    80002fde:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002fe0:	fe840593          	addi	a1,s0,-24
    80002fe4:	4501                	li	a0,0
    80002fe6:	00000097          	auipc	ra,0x0
    80002fea:	ece080e7          	jalr	-306(ra) # 80002eb4 <argaddr>
    80002fee:	87aa                	mv	a5,a0
    return -1;
    80002ff0:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002ff2:	0007c863          	bltz	a5,80003002 <sys_wait+0x2a>
  return wait(p);
    80002ff6:	fe843503          	ld	a0,-24(s0)
    80002ffa:	fffff097          	auipc	ra,0xfffff
    80002ffe:	1ac080e7          	jalr	428(ra) # 800021a6 <wait>
}
    80003002:	60e2                	ld	ra,24(sp)
    80003004:	6442                	ld	s0,16(sp)
    80003006:	6105                	addi	sp,sp,32
    80003008:	8082                	ret

000000008000300a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000300a:	7179                	addi	sp,sp,-48
    8000300c:	f406                	sd	ra,40(sp)
    8000300e:	f022                	sd	s0,32(sp)
    80003010:	ec26                	sd	s1,24(sp)
    80003012:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003014:	fdc40593          	addi	a1,s0,-36
    80003018:	4501                	li	a0,0
    8000301a:	00000097          	auipc	ra,0x0
    8000301e:	e78080e7          	jalr	-392(ra) # 80002e92 <argint>
    80003022:	87aa                	mv	a5,a0
    return -1;
    80003024:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003026:	0207c063          	bltz	a5,80003046 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    8000302a:	fffff097          	auipc	ra,0xfffff
    8000302e:	96c080e7          	jalr	-1684(ra) # 80001996 <myproc>
    80003032:	4d24                	lw	s1,88(a0)
  if(growproc(n) < 0)
    80003034:	fdc42503          	lw	a0,-36(s0)
    80003038:	fffff097          	auipc	ra,0xfffff
    8000303c:	d46080e7          	jalr	-698(ra) # 80001d7e <growproc>
    80003040:	00054863          	bltz	a0,80003050 <sys_sbrk+0x46>
    return -1;
  return addr;
    80003044:	8526                	mv	a0,s1
}
    80003046:	70a2                	ld	ra,40(sp)
    80003048:	7402                	ld	s0,32(sp)
    8000304a:	64e2                	ld	s1,24(sp)
    8000304c:	6145                	addi	sp,sp,48
    8000304e:	8082                	ret
    return -1;
    80003050:	557d                	li	a0,-1
    80003052:	bfd5                	j	80003046 <sys_sbrk+0x3c>

0000000080003054 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003054:	7139                	addi	sp,sp,-64
    80003056:	fc06                	sd	ra,56(sp)
    80003058:	f822                	sd	s0,48(sp)
    8000305a:	f426                	sd	s1,40(sp)
    8000305c:	f04a                	sd	s2,32(sp)
    8000305e:	ec4e                	sd	s3,24(sp)
    80003060:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003062:	fcc40593          	addi	a1,s0,-52
    80003066:	4501                	li	a0,0
    80003068:	00000097          	auipc	ra,0x0
    8000306c:	e2a080e7          	jalr	-470(ra) # 80002e92 <argint>
    return -1;
    80003070:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003072:	06054563          	bltz	a0,800030dc <sys_sleep+0x88>
  acquire(&tickslock);
    80003076:	00014517          	auipc	a0,0x14
    8000307a:	45a50513          	addi	a0,a0,1114 # 800174d0 <tickslock>
    8000307e:	ffffe097          	auipc	ra,0xffffe
    80003082:	b52080e7          	jalr	-1198(ra) # 80000bd0 <acquire>
  ticks0 = ticks;
    80003086:	00006917          	auipc	s2,0x6
    8000308a:	faa92903          	lw	s2,-86(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    8000308e:	fcc42783          	lw	a5,-52(s0)
    80003092:	cf85                	beqz	a5,800030ca <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003094:	00014997          	auipc	s3,0x14
    80003098:	43c98993          	addi	s3,s3,1084 # 800174d0 <tickslock>
    8000309c:	00006497          	auipc	s1,0x6
    800030a0:	f9448493          	addi	s1,s1,-108 # 80009030 <ticks>
    if(myproc()->killed){
    800030a4:	fffff097          	auipc	ra,0xfffff
    800030a8:	8f2080e7          	jalr	-1806(ra) # 80001996 <myproc>
    800030ac:	551c                	lw	a5,40(a0)
    800030ae:	ef9d                	bnez	a5,800030ec <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800030b0:	85ce                	mv	a1,s3
    800030b2:	8526                	mv	a0,s1
    800030b4:	fffff097          	auipc	ra,0xfffff
    800030b8:	08e080e7          	jalr	142(ra) # 80002142 <sleep>
  while(ticks - ticks0 < n){
    800030bc:	409c                	lw	a5,0(s1)
    800030be:	412787bb          	subw	a5,a5,s2
    800030c2:	fcc42703          	lw	a4,-52(s0)
    800030c6:	fce7efe3          	bltu	a5,a4,800030a4 <sys_sleep+0x50>
  }
  release(&tickslock);
    800030ca:	00014517          	auipc	a0,0x14
    800030ce:	40650513          	addi	a0,a0,1030 # 800174d0 <tickslock>
    800030d2:	ffffe097          	auipc	ra,0xffffe
    800030d6:	bb2080e7          	jalr	-1102(ra) # 80000c84 <release>
  return 0;
    800030da:	4781                	li	a5,0
}
    800030dc:	853e                	mv	a0,a5
    800030de:	70e2                	ld	ra,56(sp)
    800030e0:	7442                	ld	s0,48(sp)
    800030e2:	74a2                	ld	s1,40(sp)
    800030e4:	7902                	ld	s2,32(sp)
    800030e6:	69e2                	ld	s3,24(sp)
    800030e8:	6121                	addi	sp,sp,64
    800030ea:	8082                	ret
      release(&tickslock);
    800030ec:	00014517          	auipc	a0,0x14
    800030f0:	3e450513          	addi	a0,a0,996 # 800174d0 <tickslock>
    800030f4:	ffffe097          	auipc	ra,0xffffe
    800030f8:	b90080e7          	jalr	-1136(ra) # 80000c84 <release>
      return -1;
    800030fc:	57fd                	li	a5,-1
    800030fe:	bff9                	j	800030dc <sys_sleep+0x88>

0000000080003100 <sys_kill>:

uint64
sys_kill(void)
{
    80003100:	1101                	addi	sp,sp,-32
    80003102:	ec06                	sd	ra,24(sp)
    80003104:	e822                	sd	s0,16(sp)
    80003106:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003108:	fec40593          	addi	a1,s0,-20
    8000310c:	4501                	li	a0,0
    8000310e:	00000097          	auipc	ra,0x0
    80003112:	d84080e7          	jalr	-636(ra) # 80002e92 <argint>
    80003116:	87aa                	mv	a5,a0
    return -1;
    80003118:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000311a:	0007c863          	bltz	a5,8000312a <sys_kill+0x2a>
  return kill(pid);
    8000311e:	fec42503          	lw	a0,-20(s0)
    80003122:	fffff097          	auipc	ra,0xfffff
    80003126:	37e080e7          	jalr	894(ra) # 800024a0 <kill>
}
    8000312a:	60e2                	ld	ra,24(sp)
    8000312c:	6442                	ld	s0,16(sp)
    8000312e:	6105                	addi	sp,sp,32
    80003130:	8082                	ret

0000000080003132 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003132:	1101                	addi	sp,sp,-32
    80003134:	ec06                	sd	ra,24(sp)
    80003136:	e822                	sd	s0,16(sp)
    80003138:	e426                	sd	s1,8(sp)
    8000313a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000313c:	00014517          	auipc	a0,0x14
    80003140:	39450513          	addi	a0,a0,916 # 800174d0 <tickslock>
    80003144:	ffffe097          	auipc	ra,0xffffe
    80003148:	a8c080e7          	jalr	-1396(ra) # 80000bd0 <acquire>
  xticks = ticks;
    8000314c:	00006497          	auipc	s1,0x6
    80003150:	ee44a483          	lw	s1,-284(s1) # 80009030 <ticks>
  release(&tickslock);
    80003154:	00014517          	auipc	a0,0x14
    80003158:	37c50513          	addi	a0,a0,892 # 800174d0 <tickslock>
    8000315c:	ffffe097          	auipc	ra,0xffffe
    80003160:	b28080e7          	jalr	-1240(ra) # 80000c84 <release>
  return xticks;
}
    80003164:	02049513          	slli	a0,s1,0x20
    80003168:	9101                	srli	a0,a0,0x20
    8000316a:	60e2                	ld	ra,24(sp)
    8000316c:	6442                	ld	s0,16(sp)
    8000316e:	64a2                	ld	s1,8(sp)
    80003170:	6105                	addi	sp,sp,32
    80003172:	8082                	ret

0000000080003174 <sys_getppid>:

//---------------Assignment 1(b) -------------------
uint64
sys_getppid(void)
{
    80003174:	1141                	addi	sp,sp,-16
    80003176:	e406                	sd	ra,8(sp)
    80003178:	e022                	sd	s0,0(sp)
    8000317a:	0800                	addi	s0,sp,16
  return getppid();
    8000317c:	fffff097          	auipc	ra,0xfffff
    80003180:	51c080e7          	jalr	1308(ra) # 80002698 <getppid>
}
    80003184:	60a2                	ld	ra,8(sp)
    80003186:	6402                	ld	s0,0(sp)
    80003188:	0141                	addi	sp,sp,16
    8000318a:	8082                	ret

000000008000318c <sys_yield>:

uint64
sys_yield(void)
{
    8000318c:	1141                	addi	sp,sp,-16
    8000318e:	e406                	sd	ra,8(sp)
    80003190:	e022                	sd	s0,0(sp)
    80003192:	0800                	addi	s0,sp,16
  yield();
    80003194:	fffff097          	auipc	ra,0xfffff
    80003198:	f72080e7          	jalr	-142(ra) # 80002106 <yield>
  return 0;
}
    8000319c:	4501                	li	a0,0
    8000319e:	60a2                	ld	ra,8(sp)
    800031a0:	6402                	ld	s0,0(sp)
    800031a2:	0141                	addi	sp,sp,16
    800031a4:	8082                	ret

00000000800031a6 <sys_getpa>:

uint64
sys_getpa(void){
    800031a6:	7179                	addi	sp,sp,-48
    800031a8:	f406                	sd	ra,40(sp)
    800031aa:	f022                	sd	s0,32(sp)
    800031ac:	ec26                	sd	s1,24(sp)
    800031ae:	1800                	addi	s0,sp,48
  struct proc* p = myproc();
    800031b0:	ffffe097          	auipc	ra,0xffffe
    800031b4:	7e6080e7          	jalr	2022(ra) # 80001996 <myproc>
    800031b8:	84aa                	mv	s1,a0
  uint64 va;
  if(argaddr(0, &va) < 0)
    800031ba:	fd840593          	addi	a1,s0,-40
    800031be:	4501                	li	a0,0
    800031c0:	00000097          	auipc	ra,0x0
    800031c4:	cf4080e7          	jalr	-780(ra) # 80002eb4 <argaddr>
    return -1;
    800031c8:	57fd                	li	a5,-1
  if(argaddr(0, &va) < 0)
    800031ca:	00054e63          	bltz	a0,800031e6 <sys_getpa+0x40>
  return walkaddr(p->pagetable, va) + (va &(PGSIZE-1));
    800031ce:	fd843583          	ld	a1,-40(s0)
    800031d2:	70a8                	ld	a0,96(s1)
    800031d4:	ffffe097          	auipc	ra,0xffffe
    800031d8:	e7e080e7          	jalr	-386(ra) # 80001052 <walkaddr>
    800031dc:	fd843783          	ld	a5,-40(s0)
    800031e0:	17d2                	slli	a5,a5,0x34
    800031e2:	93d1                	srli	a5,a5,0x34
    800031e4:	97aa                	add	a5,a5,a0
}
    800031e6:	853e                	mv	a0,a5
    800031e8:	70a2                	ld	ra,40(sp)
    800031ea:	7402                	ld	s0,32(sp)
    800031ec:	64e2                	ld	s1,24(sp)
    800031ee:	6145                	addi	sp,sp,48
    800031f0:	8082                	ret

00000000800031f2 <sys_waitpid>:

uint64
sys_waitpid(void)
{
    800031f2:	1101                	addi	sp,sp,-32
    800031f4:	ec06                	sd	ra,24(sp)
    800031f6:	e822                	sd	s0,16(sp)
    800031f8:	1000                	addi	s0,sp,32
  int pid;
  uint64 p;

  if(argint(0, &pid) < 0)
    800031fa:	fec40593          	addi	a1,s0,-20
    800031fe:	4501                	li	a0,0
    80003200:	00000097          	auipc	ra,0x0
    80003204:	c92080e7          	jalr	-878(ra) # 80002e92 <argint>
    return -1;
    80003208:	57fd                	li	a5,-1
  if(argint(0, &pid) < 0)
    8000320a:	02054563          	bltz	a0,80003234 <sys_waitpid+0x42>
  
  if(argaddr(0, &p) < 0)
    8000320e:	fe040593          	addi	a1,s0,-32
    80003212:	4501                	li	a0,0
    80003214:	00000097          	auipc	ra,0x0
    80003218:	ca0080e7          	jalr	-864(ra) # 80002eb4 <argaddr>
    return -1;
    8000321c:	57fd                	li	a5,-1
  if(argaddr(0, &p) < 0)
    8000321e:	00054b63          	bltz	a0,80003234 <sys_waitpid+0x42>
  
  return waitpid(pid, p);
    80003222:	fe043583          	ld	a1,-32(s0)
    80003226:	fec42503          	lw	a0,-20(s0)
    8000322a:	fffff097          	auipc	ra,0xfffff
    8000322e:	4fc080e7          	jalr	1276(ra) # 80002726 <waitpid>
    80003232:	87aa                	mv	a5,a0
}
    80003234:	853e                	mv	a0,a5
    80003236:	60e2                	ld	ra,24(sp)
    80003238:	6442                	ld	s0,16(sp)
    8000323a:	6105                	addi	sp,sp,32
    8000323c:	8082                	ret

000000008000323e <sys_ps>:

uint64
sys_ps(void)
{
    8000323e:	1141                	addi	sp,sp,-16
    80003240:	e406                	sd	ra,8(sp)
    80003242:	e022                	sd	s0,0(sp)
    80003244:	0800                	addi	s0,sp,16
  ps();
    80003246:	fffff097          	auipc	ra,0xfffff
    8000324a:	61e080e7          	jalr	1566(ra) # 80002864 <ps>
  return 0;
    8000324e:	4501                	li	a0,0
    80003250:	60a2                	ld	ra,8(sp)
    80003252:	6402                	ld	s0,0(sp)
    80003254:	0141                	addi	sp,sp,16
    80003256:	8082                	ret

0000000080003258 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003258:	7179                	addi	sp,sp,-48
    8000325a:	f406                	sd	ra,40(sp)
    8000325c:	f022                	sd	s0,32(sp)
    8000325e:	ec26                	sd	s1,24(sp)
    80003260:	e84a                	sd	s2,16(sp)
    80003262:	e44e                	sd	s3,8(sp)
    80003264:	e052                	sd	s4,0(sp)
    80003266:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003268:	00005597          	auipc	a1,0x5
    8000326c:	34058593          	addi	a1,a1,832 # 800085a8 <syscalls+0xe0>
    80003270:	00014517          	auipc	a0,0x14
    80003274:	27850513          	addi	a0,a0,632 # 800174e8 <bcache>
    80003278:	ffffe097          	auipc	ra,0xffffe
    8000327c:	8c8080e7          	jalr	-1848(ra) # 80000b40 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003280:	0001c797          	auipc	a5,0x1c
    80003284:	26878793          	addi	a5,a5,616 # 8001f4e8 <bcache+0x8000>
    80003288:	0001c717          	auipc	a4,0x1c
    8000328c:	4c870713          	addi	a4,a4,1224 # 8001f750 <bcache+0x8268>
    80003290:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003294:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003298:	00014497          	auipc	s1,0x14
    8000329c:	26848493          	addi	s1,s1,616 # 80017500 <bcache+0x18>
    b->next = bcache.head.next;
    800032a0:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800032a2:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800032a4:	00005a17          	auipc	s4,0x5
    800032a8:	30ca0a13          	addi	s4,s4,780 # 800085b0 <syscalls+0xe8>
    b->next = bcache.head.next;
    800032ac:	2b893783          	ld	a5,696(s2)
    800032b0:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800032b2:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800032b6:	85d2                	mv	a1,s4
    800032b8:	01048513          	addi	a0,s1,16
    800032bc:	00001097          	auipc	ra,0x1
    800032c0:	4c2080e7          	jalr	1218(ra) # 8000477e <initsleeplock>
    bcache.head.next->prev = b;
    800032c4:	2b893783          	ld	a5,696(s2)
    800032c8:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800032ca:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800032ce:	45848493          	addi	s1,s1,1112
    800032d2:	fd349de3          	bne	s1,s3,800032ac <binit+0x54>
  }
}
    800032d6:	70a2                	ld	ra,40(sp)
    800032d8:	7402                	ld	s0,32(sp)
    800032da:	64e2                	ld	s1,24(sp)
    800032dc:	6942                	ld	s2,16(sp)
    800032de:	69a2                	ld	s3,8(sp)
    800032e0:	6a02                	ld	s4,0(sp)
    800032e2:	6145                	addi	sp,sp,48
    800032e4:	8082                	ret

00000000800032e6 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800032e6:	7179                	addi	sp,sp,-48
    800032e8:	f406                	sd	ra,40(sp)
    800032ea:	f022                	sd	s0,32(sp)
    800032ec:	ec26                	sd	s1,24(sp)
    800032ee:	e84a                	sd	s2,16(sp)
    800032f0:	e44e                	sd	s3,8(sp)
    800032f2:	1800                	addi	s0,sp,48
    800032f4:	892a                	mv	s2,a0
    800032f6:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800032f8:	00014517          	auipc	a0,0x14
    800032fc:	1f050513          	addi	a0,a0,496 # 800174e8 <bcache>
    80003300:	ffffe097          	auipc	ra,0xffffe
    80003304:	8d0080e7          	jalr	-1840(ra) # 80000bd0 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003308:	0001c497          	auipc	s1,0x1c
    8000330c:	4984b483          	ld	s1,1176(s1) # 8001f7a0 <bcache+0x82b8>
    80003310:	0001c797          	auipc	a5,0x1c
    80003314:	44078793          	addi	a5,a5,1088 # 8001f750 <bcache+0x8268>
    80003318:	02f48f63          	beq	s1,a5,80003356 <bread+0x70>
    8000331c:	873e                	mv	a4,a5
    8000331e:	a021                	j	80003326 <bread+0x40>
    80003320:	68a4                	ld	s1,80(s1)
    80003322:	02e48a63          	beq	s1,a4,80003356 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003326:	449c                	lw	a5,8(s1)
    80003328:	ff279ce3          	bne	a5,s2,80003320 <bread+0x3a>
    8000332c:	44dc                	lw	a5,12(s1)
    8000332e:	ff3799e3          	bne	a5,s3,80003320 <bread+0x3a>
      b->refcnt++;
    80003332:	40bc                	lw	a5,64(s1)
    80003334:	2785                	addiw	a5,a5,1
    80003336:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003338:	00014517          	auipc	a0,0x14
    8000333c:	1b050513          	addi	a0,a0,432 # 800174e8 <bcache>
    80003340:	ffffe097          	auipc	ra,0xffffe
    80003344:	944080e7          	jalr	-1724(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    80003348:	01048513          	addi	a0,s1,16
    8000334c:	00001097          	auipc	ra,0x1
    80003350:	46c080e7          	jalr	1132(ra) # 800047b8 <acquiresleep>
      return b;
    80003354:	a8b9                	j	800033b2 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003356:	0001c497          	auipc	s1,0x1c
    8000335a:	4424b483          	ld	s1,1090(s1) # 8001f798 <bcache+0x82b0>
    8000335e:	0001c797          	auipc	a5,0x1c
    80003362:	3f278793          	addi	a5,a5,1010 # 8001f750 <bcache+0x8268>
    80003366:	00f48863          	beq	s1,a5,80003376 <bread+0x90>
    8000336a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000336c:	40bc                	lw	a5,64(s1)
    8000336e:	cf81                	beqz	a5,80003386 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003370:	64a4                	ld	s1,72(s1)
    80003372:	fee49de3          	bne	s1,a4,8000336c <bread+0x86>
  panic("bget: no buffers");
    80003376:	00005517          	auipc	a0,0x5
    8000337a:	24250513          	addi	a0,a0,578 # 800085b8 <syscalls+0xf0>
    8000337e:	ffffd097          	auipc	ra,0xffffd
    80003382:	1bc080e7          	jalr	444(ra) # 8000053a <panic>
      b->dev = dev;
    80003386:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000338a:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000338e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003392:	4785                	li	a5,1
    80003394:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003396:	00014517          	auipc	a0,0x14
    8000339a:	15250513          	addi	a0,a0,338 # 800174e8 <bcache>
    8000339e:	ffffe097          	auipc	ra,0xffffe
    800033a2:	8e6080e7          	jalr	-1818(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    800033a6:	01048513          	addi	a0,s1,16
    800033aa:	00001097          	auipc	ra,0x1
    800033ae:	40e080e7          	jalr	1038(ra) # 800047b8 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800033b2:	409c                	lw	a5,0(s1)
    800033b4:	cb89                	beqz	a5,800033c6 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800033b6:	8526                	mv	a0,s1
    800033b8:	70a2                	ld	ra,40(sp)
    800033ba:	7402                	ld	s0,32(sp)
    800033bc:	64e2                	ld	s1,24(sp)
    800033be:	6942                	ld	s2,16(sp)
    800033c0:	69a2                	ld	s3,8(sp)
    800033c2:	6145                	addi	sp,sp,48
    800033c4:	8082                	ret
    virtio_disk_rw(b, 0);
    800033c6:	4581                	li	a1,0
    800033c8:	8526                	mv	a0,s1
    800033ca:	00003097          	auipc	ra,0x3
    800033ce:	f28080e7          	jalr	-216(ra) # 800062f2 <virtio_disk_rw>
    b->valid = 1;
    800033d2:	4785                	li	a5,1
    800033d4:	c09c                	sw	a5,0(s1)
  return b;
    800033d6:	b7c5                	j	800033b6 <bread+0xd0>

00000000800033d8 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800033d8:	1101                	addi	sp,sp,-32
    800033da:	ec06                	sd	ra,24(sp)
    800033dc:	e822                	sd	s0,16(sp)
    800033de:	e426                	sd	s1,8(sp)
    800033e0:	1000                	addi	s0,sp,32
    800033e2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800033e4:	0541                	addi	a0,a0,16
    800033e6:	00001097          	auipc	ra,0x1
    800033ea:	46c080e7          	jalr	1132(ra) # 80004852 <holdingsleep>
    800033ee:	cd01                	beqz	a0,80003406 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800033f0:	4585                	li	a1,1
    800033f2:	8526                	mv	a0,s1
    800033f4:	00003097          	auipc	ra,0x3
    800033f8:	efe080e7          	jalr	-258(ra) # 800062f2 <virtio_disk_rw>
}
    800033fc:	60e2                	ld	ra,24(sp)
    800033fe:	6442                	ld	s0,16(sp)
    80003400:	64a2                	ld	s1,8(sp)
    80003402:	6105                	addi	sp,sp,32
    80003404:	8082                	ret
    panic("bwrite");
    80003406:	00005517          	auipc	a0,0x5
    8000340a:	1ca50513          	addi	a0,a0,458 # 800085d0 <syscalls+0x108>
    8000340e:	ffffd097          	auipc	ra,0xffffd
    80003412:	12c080e7          	jalr	300(ra) # 8000053a <panic>

0000000080003416 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003416:	1101                	addi	sp,sp,-32
    80003418:	ec06                	sd	ra,24(sp)
    8000341a:	e822                	sd	s0,16(sp)
    8000341c:	e426                	sd	s1,8(sp)
    8000341e:	e04a                	sd	s2,0(sp)
    80003420:	1000                	addi	s0,sp,32
    80003422:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003424:	01050913          	addi	s2,a0,16
    80003428:	854a                	mv	a0,s2
    8000342a:	00001097          	auipc	ra,0x1
    8000342e:	428080e7          	jalr	1064(ra) # 80004852 <holdingsleep>
    80003432:	c92d                	beqz	a0,800034a4 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003434:	854a                	mv	a0,s2
    80003436:	00001097          	auipc	ra,0x1
    8000343a:	3d8080e7          	jalr	984(ra) # 8000480e <releasesleep>

  acquire(&bcache.lock);
    8000343e:	00014517          	auipc	a0,0x14
    80003442:	0aa50513          	addi	a0,a0,170 # 800174e8 <bcache>
    80003446:	ffffd097          	auipc	ra,0xffffd
    8000344a:	78a080e7          	jalr	1930(ra) # 80000bd0 <acquire>
  b->refcnt--;
    8000344e:	40bc                	lw	a5,64(s1)
    80003450:	37fd                	addiw	a5,a5,-1
    80003452:	0007871b          	sext.w	a4,a5
    80003456:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003458:	eb05                	bnez	a4,80003488 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000345a:	68bc                	ld	a5,80(s1)
    8000345c:	64b8                	ld	a4,72(s1)
    8000345e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003460:	64bc                	ld	a5,72(s1)
    80003462:	68b8                	ld	a4,80(s1)
    80003464:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003466:	0001c797          	auipc	a5,0x1c
    8000346a:	08278793          	addi	a5,a5,130 # 8001f4e8 <bcache+0x8000>
    8000346e:	2b87b703          	ld	a4,696(a5)
    80003472:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003474:	0001c717          	auipc	a4,0x1c
    80003478:	2dc70713          	addi	a4,a4,732 # 8001f750 <bcache+0x8268>
    8000347c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000347e:	2b87b703          	ld	a4,696(a5)
    80003482:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003484:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003488:	00014517          	auipc	a0,0x14
    8000348c:	06050513          	addi	a0,a0,96 # 800174e8 <bcache>
    80003490:	ffffd097          	auipc	ra,0xffffd
    80003494:	7f4080e7          	jalr	2036(ra) # 80000c84 <release>
}
    80003498:	60e2                	ld	ra,24(sp)
    8000349a:	6442                	ld	s0,16(sp)
    8000349c:	64a2                	ld	s1,8(sp)
    8000349e:	6902                	ld	s2,0(sp)
    800034a0:	6105                	addi	sp,sp,32
    800034a2:	8082                	ret
    panic("brelse");
    800034a4:	00005517          	auipc	a0,0x5
    800034a8:	13450513          	addi	a0,a0,308 # 800085d8 <syscalls+0x110>
    800034ac:	ffffd097          	auipc	ra,0xffffd
    800034b0:	08e080e7          	jalr	142(ra) # 8000053a <panic>

00000000800034b4 <bpin>:

void
bpin(struct buf *b) {
    800034b4:	1101                	addi	sp,sp,-32
    800034b6:	ec06                	sd	ra,24(sp)
    800034b8:	e822                	sd	s0,16(sp)
    800034ba:	e426                	sd	s1,8(sp)
    800034bc:	1000                	addi	s0,sp,32
    800034be:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800034c0:	00014517          	auipc	a0,0x14
    800034c4:	02850513          	addi	a0,a0,40 # 800174e8 <bcache>
    800034c8:	ffffd097          	auipc	ra,0xffffd
    800034cc:	708080e7          	jalr	1800(ra) # 80000bd0 <acquire>
  b->refcnt++;
    800034d0:	40bc                	lw	a5,64(s1)
    800034d2:	2785                	addiw	a5,a5,1
    800034d4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800034d6:	00014517          	auipc	a0,0x14
    800034da:	01250513          	addi	a0,a0,18 # 800174e8 <bcache>
    800034de:	ffffd097          	auipc	ra,0xffffd
    800034e2:	7a6080e7          	jalr	1958(ra) # 80000c84 <release>
}
    800034e6:	60e2                	ld	ra,24(sp)
    800034e8:	6442                	ld	s0,16(sp)
    800034ea:	64a2                	ld	s1,8(sp)
    800034ec:	6105                	addi	sp,sp,32
    800034ee:	8082                	ret

00000000800034f0 <bunpin>:

void
bunpin(struct buf *b) {
    800034f0:	1101                	addi	sp,sp,-32
    800034f2:	ec06                	sd	ra,24(sp)
    800034f4:	e822                	sd	s0,16(sp)
    800034f6:	e426                	sd	s1,8(sp)
    800034f8:	1000                	addi	s0,sp,32
    800034fa:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800034fc:	00014517          	auipc	a0,0x14
    80003500:	fec50513          	addi	a0,a0,-20 # 800174e8 <bcache>
    80003504:	ffffd097          	auipc	ra,0xffffd
    80003508:	6cc080e7          	jalr	1740(ra) # 80000bd0 <acquire>
  b->refcnt--;
    8000350c:	40bc                	lw	a5,64(s1)
    8000350e:	37fd                	addiw	a5,a5,-1
    80003510:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003512:	00014517          	auipc	a0,0x14
    80003516:	fd650513          	addi	a0,a0,-42 # 800174e8 <bcache>
    8000351a:	ffffd097          	auipc	ra,0xffffd
    8000351e:	76a080e7          	jalr	1898(ra) # 80000c84 <release>
}
    80003522:	60e2                	ld	ra,24(sp)
    80003524:	6442                	ld	s0,16(sp)
    80003526:	64a2                	ld	s1,8(sp)
    80003528:	6105                	addi	sp,sp,32
    8000352a:	8082                	ret

000000008000352c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000352c:	1101                	addi	sp,sp,-32
    8000352e:	ec06                	sd	ra,24(sp)
    80003530:	e822                	sd	s0,16(sp)
    80003532:	e426                	sd	s1,8(sp)
    80003534:	e04a                	sd	s2,0(sp)
    80003536:	1000                	addi	s0,sp,32
    80003538:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000353a:	00d5d59b          	srliw	a1,a1,0xd
    8000353e:	0001c797          	auipc	a5,0x1c
    80003542:	6867a783          	lw	a5,1670(a5) # 8001fbc4 <sb+0x1c>
    80003546:	9dbd                	addw	a1,a1,a5
    80003548:	00000097          	auipc	ra,0x0
    8000354c:	d9e080e7          	jalr	-610(ra) # 800032e6 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003550:	0074f713          	andi	a4,s1,7
    80003554:	4785                	li	a5,1
    80003556:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000355a:	14ce                	slli	s1,s1,0x33
    8000355c:	90d9                	srli	s1,s1,0x36
    8000355e:	00950733          	add	a4,a0,s1
    80003562:	05874703          	lbu	a4,88(a4)
    80003566:	00e7f6b3          	and	a3,a5,a4
    8000356a:	c69d                	beqz	a3,80003598 <bfree+0x6c>
    8000356c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000356e:	94aa                	add	s1,s1,a0
    80003570:	fff7c793          	not	a5,a5
    80003574:	8f7d                	and	a4,a4,a5
    80003576:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    8000357a:	00001097          	auipc	ra,0x1
    8000357e:	120080e7          	jalr	288(ra) # 8000469a <log_write>
  brelse(bp);
    80003582:	854a                	mv	a0,s2
    80003584:	00000097          	auipc	ra,0x0
    80003588:	e92080e7          	jalr	-366(ra) # 80003416 <brelse>
}
    8000358c:	60e2                	ld	ra,24(sp)
    8000358e:	6442                	ld	s0,16(sp)
    80003590:	64a2                	ld	s1,8(sp)
    80003592:	6902                	ld	s2,0(sp)
    80003594:	6105                	addi	sp,sp,32
    80003596:	8082                	ret
    panic("freeing free block");
    80003598:	00005517          	auipc	a0,0x5
    8000359c:	04850513          	addi	a0,a0,72 # 800085e0 <syscalls+0x118>
    800035a0:	ffffd097          	auipc	ra,0xffffd
    800035a4:	f9a080e7          	jalr	-102(ra) # 8000053a <panic>

00000000800035a8 <balloc>:
{
    800035a8:	711d                	addi	sp,sp,-96
    800035aa:	ec86                	sd	ra,88(sp)
    800035ac:	e8a2                	sd	s0,80(sp)
    800035ae:	e4a6                	sd	s1,72(sp)
    800035b0:	e0ca                	sd	s2,64(sp)
    800035b2:	fc4e                	sd	s3,56(sp)
    800035b4:	f852                	sd	s4,48(sp)
    800035b6:	f456                	sd	s5,40(sp)
    800035b8:	f05a                	sd	s6,32(sp)
    800035ba:	ec5e                	sd	s7,24(sp)
    800035bc:	e862                	sd	s8,16(sp)
    800035be:	e466                	sd	s9,8(sp)
    800035c0:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800035c2:	0001c797          	auipc	a5,0x1c
    800035c6:	5ea7a783          	lw	a5,1514(a5) # 8001fbac <sb+0x4>
    800035ca:	cbc1                	beqz	a5,8000365a <balloc+0xb2>
    800035cc:	8baa                	mv	s7,a0
    800035ce:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800035d0:	0001cb17          	auipc	s6,0x1c
    800035d4:	5d8b0b13          	addi	s6,s6,1496 # 8001fba8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035d8:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800035da:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035dc:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800035de:	6c89                	lui	s9,0x2
    800035e0:	a831                	j	800035fc <balloc+0x54>
    brelse(bp);
    800035e2:	854a                	mv	a0,s2
    800035e4:	00000097          	auipc	ra,0x0
    800035e8:	e32080e7          	jalr	-462(ra) # 80003416 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800035ec:	015c87bb          	addw	a5,s9,s5
    800035f0:	00078a9b          	sext.w	s5,a5
    800035f4:	004b2703          	lw	a4,4(s6)
    800035f8:	06eaf163          	bgeu	s5,a4,8000365a <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    800035fc:	41fad79b          	sraiw	a5,s5,0x1f
    80003600:	0137d79b          	srliw	a5,a5,0x13
    80003604:	015787bb          	addw	a5,a5,s5
    80003608:	40d7d79b          	sraiw	a5,a5,0xd
    8000360c:	01cb2583          	lw	a1,28(s6)
    80003610:	9dbd                	addw	a1,a1,a5
    80003612:	855e                	mv	a0,s7
    80003614:	00000097          	auipc	ra,0x0
    80003618:	cd2080e7          	jalr	-814(ra) # 800032e6 <bread>
    8000361c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000361e:	004b2503          	lw	a0,4(s6)
    80003622:	000a849b          	sext.w	s1,s5
    80003626:	8762                	mv	a4,s8
    80003628:	faa4fde3          	bgeu	s1,a0,800035e2 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000362c:	00777693          	andi	a3,a4,7
    80003630:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003634:	41f7579b          	sraiw	a5,a4,0x1f
    80003638:	01d7d79b          	srliw	a5,a5,0x1d
    8000363c:	9fb9                	addw	a5,a5,a4
    8000363e:	4037d79b          	sraiw	a5,a5,0x3
    80003642:	00f90633          	add	a2,s2,a5
    80003646:	05864603          	lbu	a2,88(a2)
    8000364a:	00c6f5b3          	and	a1,a3,a2
    8000364e:	cd91                	beqz	a1,8000366a <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003650:	2705                	addiw	a4,a4,1
    80003652:	2485                	addiw	s1,s1,1
    80003654:	fd471ae3          	bne	a4,s4,80003628 <balloc+0x80>
    80003658:	b769                	j	800035e2 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000365a:	00005517          	auipc	a0,0x5
    8000365e:	f9e50513          	addi	a0,a0,-98 # 800085f8 <syscalls+0x130>
    80003662:	ffffd097          	auipc	ra,0xffffd
    80003666:	ed8080e7          	jalr	-296(ra) # 8000053a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000366a:	97ca                	add	a5,a5,s2
    8000366c:	8e55                	or	a2,a2,a3
    8000366e:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003672:	854a                	mv	a0,s2
    80003674:	00001097          	auipc	ra,0x1
    80003678:	026080e7          	jalr	38(ra) # 8000469a <log_write>
        brelse(bp);
    8000367c:	854a                	mv	a0,s2
    8000367e:	00000097          	auipc	ra,0x0
    80003682:	d98080e7          	jalr	-616(ra) # 80003416 <brelse>
  bp = bread(dev, bno);
    80003686:	85a6                	mv	a1,s1
    80003688:	855e                	mv	a0,s7
    8000368a:	00000097          	auipc	ra,0x0
    8000368e:	c5c080e7          	jalr	-932(ra) # 800032e6 <bread>
    80003692:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003694:	40000613          	li	a2,1024
    80003698:	4581                	li	a1,0
    8000369a:	05850513          	addi	a0,a0,88
    8000369e:	ffffd097          	auipc	ra,0xffffd
    800036a2:	62e080e7          	jalr	1582(ra) # 80000ccc <memset>
  log_write(bp);
    800036a6:	854a                	mv	a0,s2
    800036a8:	00001097          	auipc	ra,0x1
    800036ac:	ff2080e7          	jalr	-14(ra) # 8000469a <log_write>
  brelse(bp);
    800036b0:	854a                	mv	a0,s2
    800036b2:	00000097          	auipc	ra,0x0
    800036b6:	d64080e7          	jalr	-668(ra) # 80003416 <brelse>
}
    800036ba:	8526                	mv	a0,s1
    800036bc:	60e6                	ld	ra,88(sp)
    800036be:	6446                	ld	s0,80(sp)
    800036c0:	64a6                	ld	s1,72(sp)
    800036c2:	6906                	ld	s2,64(sp)
    800036c4:	79e2                	ld	s3,56(sp)
    800036c6:	7a42                	ld	s4,48(sp)
    800036c8:	7aa2                	ld	s5,40(sp)
    800036ca:	7b02                	ld	s6,32(sp)
    800036cc:	6be2                	ld	s7,24(sp)
    800036ce:	6c42                	ld	s8,16(sp)
    800036d0:	6ca2                	ld	s9,8(sp)
    800036d2:	6125                	addi	sp,sp,96
    800036d4:	8082                	ret

00000000800036d6 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800036d6:	7179                	addi	sp,sp,-48
    800036d8:	f406                	sd	ra,40(sp)
    800036da:	f022                	sd	s0,32(sp)
    800036dc:	ec26                	sd	s1,24(sp)
    800036de:	e84a                	sd	s2,16(sp)
    800036e0:	e44e                	sd	s3,8(sp)
    800036e2:	e052                	sd	s4,0(sp)
    800036e4:	1800                	addi	s0,sp,48
    800036e6:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800036e8:	47ad                	li	a5,11
    800036ea:	04b7fe63          	bgeu	a5,a1,80003746 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800036ee:	ff45849b          	addiw	s1,a1,-12
    800036f2:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800036f6:	0ff00793          	li	a5,255
    800036fa:	0ae7e463          	bltu	a5,a4,800037a2 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800036fe:	08052583          	lw	a1,128(a0)
    80003702:	c5b5                	beqz	a1,8000376e <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003704:	00092503          	lw	a0,0(s2)
    80003708:	00000097          	auipc	ra,0x0
    8000370c:	bde080e7          	jalr	-1058(ra) # 800032e6 <bread>
    80003710:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003712:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003716:	02049713          	slli	a4,s1,0x20
    8000371a:	01e75593          	srli	a1,a4,0x1e
    8000371e:	00b784b3          	add	s1,a5,a1
    80003722:	0004a983          	lw	s3,0(s1)
    80003726:	04098e63          	beqz	s3,80003782 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000372a:	8552                	mv	a0,s4
    8000372c:	00000097          	auipc	ra,0x0
    80003730:	cea080e7          	jalr	-790(ra) # 80003416 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003734:	854e                	mv	a0,s3
    80003736:	70a2                	ld	ra,40(sp)
    80003738:	7402                	ld	s0,32(sp)
    8000373a:	64e2                	ld	s1,24(sp)
    8000373c:	6942                	ld	s2,16(sp)
    8000373e:	69a2                	ld	s3,8(sp)
    80003740:	6a02                	ld	s4,0(sp)
    80003742:	6145                	addi	sp,sp,48
    80003744:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003746:	02059793          	slli	a5,a1,0x20
    8000374a:	01e7d593          	srli	a1,a5,0x1e
    8000374e:	00b504b3          	add	s1,a0,a1
    80003752:	0504a983          	lw	s3,80(s1)
    80003756:	fc099fe3          	bnez	s3,80003734 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000375a:	4108                	lw	a0,0(a0)
    8000375c:	00000097          	auipc	ra,0x0
    80003760:	e4c080e7          	jalr	-436(ra) # 800035a8 <balloc>
    80003764:	0005099b          	sext.w	s3,a0
    80003768:	0534a823          	sw	s3,80(s1)
    8000376c:	b7e1                	j	80003734 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000376e:	4108                	lw	a0,0(a0)
    80003770:	00000097          	auipc	ra,0x0
    80003774:	e38080e7          	jalr	-456(ra) # 800035a8 <balloc>
    80003778:	0005059b          	sext.w	a1,a0
    8000377c:	08b92023          	sw	a1,128(s2)
    80003780:	b751                	j	80003704 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003782:	00092503          	lw	a0,0(s2)
    80003786:	00000097          	auipc	ra,0x0
    8000378a:	e22080e7          	jalr	-478(ra) # 800035a8 <balloc>
    8000378e:	0005099b          	sext.w	s3,a0
    80003792:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003796:	8552                	mv	a0,s4
    80003798:	00001097          	auipc	ra,0x1
    8000379c:	f02080e7          	jalr	-254(ra) # 8000469a <log_write>
    800037a0:	b769                	j	8000372a <bmap+0x54>
  panic("bmap: out of range");
    800037a2:	00005517          	auipc	a0,0x5
    800037a6:	e6e50513          	addi	a0,a0,-402 # 80008610 <syscalls+0x148>
    800037aa:	ffffd097          	auipc	ra,0xffffd
    800037ae:	d90080e7          	jalr	-624(ra) # 8000053a <panic>

00000000800037b2 <iget>:
{
    800037b2:	7179                	addi	sp,sp,-48
    800037b4:	f406                	sd	ra,40(sp)
    800037b6:	f022                	sd	s0,32(sp)
    800037b8:	ec26                	sd	s1,24(sp)
    800037ba:	e84a                	sd	s2,16(sp)
    800037bc:	e44e                	sd	s3,8(sp)
    800037be:	e052                	sd	s4,0(sp)
    800037c0:	1800                	addi	s0,sp,48
    800037c2:	89aa                	mv	s3,a0
    800037c4:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800037c6:	0001c517          	auipc	a0,0x1c
    800037ca:	40250513          	addi	a0,a0,1026 # 8001fbc8 <itable>
    800037ce:	ffffd097          	auipc	ra,0xffffd
    800037d2:	402080e7          	jalr	1026(ra) # 80000bd0 <acquire>
  empty = 0;
    800037d6:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800037d8:	0001c497          	auipc	s1,0x1c
    800037dc:	40848493          	addi	s1,s1,1032 # 8001fbe0 <itable+0x18>
    800037e0:	0001e697          	auipc	a3,0x1e
    800037e4:	e9068693          	addi	a3,a3,-368 # 80021670 <log>
    800037e8:	a039                	j	800037f6 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800037ea:	02090b63          	beqz	s2,80003820 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800037ee:	08848493          	addi	s1,s1,136
    800037f2:	02d48a63          	beq	s1,a3,80003826 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800037f6:	449c                	lw	a5,8(s1)
    800037f8:	fef059e3          	blez	a5,800037ea <iget+0x38>
    800037fc:	4098                	lw	a4,0(s1)
    800037fe:	ff3716e3          	bne	a4,s3,800037ea <iget+0x38>
    80003802:	40d8                	lw	a4,4(s1)
    80003804:	ff4713e3          	bne	a4,s4,800037ea <iget+0x38>
      ip->ref++;
    80003808:	2785                	addiw	a5,a5,1
    8000380a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000380c:	0001c517          	auipc	a0,0x1c
    80003810:	3bc50513          	addi	a0,a0,956 # 8001fbc8 <itable>
    80003814:	ffffd097          	auipc	ra,0xffffd
    80003818:	470080e7          	jalr	1136(ra) # 80000c84 <release>
      return ip;
    8000381c:	8926                	mv	s2,s1
    8000381e:	a03d                	j	8000384c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003820:	f7f9                	bnez	a5,800037ee <iget+0x3c>
    80003822:	8926                	mv	s2,s1
    80003824:	b7e9                	j	800037ee <iget+0x3c>
  if(empty == 0)
    80003826:	02090c63          	beqz	s2,8000385e <iget+0xac>
  ip->dev = dev;
    8000382a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000382e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003832:	4785                	li	a5,1
    80003834:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003838:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000383c:	0001c517          	auipc	a0,0x1c
    80003840:	38c50513          	addi	a0,a0,908 # 8001fbc8 <itable>
    80003844:	ffffd097          	auipc	ra,0xffffd
    80003848:	440080e7          	jalr	1088(ra) # 80000c84 <release>
}
    8000384c:	854a                	mv	a0,s2
    8000384e:	70a2                	ld	ra,40(sp)
    80003850:	7402                	ld	s0,32(sp)
    80003852:	64e2                	ld	s1,24(sp)
    80003854:	6942                	ld	s2,16(sp)
    80003856:	69a2                	ld	s3,8(sp)
    80003858:	6a02                	ld	s4,0(sp)
    8000385a:	6145                	addi	sp,sp,48
    8000385c:	8082                	ret
    panic("iget: no inodes");
    8000385e:	00005517          	auipc	a0,0x5
    80003862:	dca50513          	addi	a0,a0,-566 # 80008628 <syscalls+0x160>
    80003866:	ffffd097          	auipc	ra,0xffffd
    8000386a:	cd4080e7          	jalr	-812(ra) # 8000053a <panic>

000000008000386e <fsinit>:
fsinit(int dev) {
    8000386e:	7179                	addi	sp,sp,-48
    80003870:	f406                	sd	ra,40(sp)
    80003872:	f022                	sd	s0,32(sp)
    80003874:	ec26                	sd	s1,24(sp)
    80003876:	e84a                	sd	s2,16(sp)
    80003878:	e44e                	sd	s3,8(sp)
    8000387a:	1800                	addi	s0,sp,48
    8000387c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000387e:	4585                	li	a1,1
    80003880:	00000097          	auipc	ra,0x0
    80003884:	a66080e7          	jalr	-1434(ra) # 800032e6 <bread>
    80003888:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000388a:	0001c997          	auipc	s3,0x1c
    8000388e:	31e98993          	addi	s3,s3,798 # 8001fba8 <sb>
    80003892:	02000613          	li	a2,32
    80003896:	05850593          	addi	a1,a0,88
    8000389a:	854e                	mv	a0,s3
    8000389c:	ffffd097          	auipc	ra,0xffffd
    800038a0:	48c080e7          	jalr	1164(ra) # 80000d28 <memmove>
  brelse(bp);
    800038a4:	8526                	mv	a0,s1
    800038a6:	00000097          	auipc	ra,0x0
    800038aa:	b70080e7          	jalr	-1168(ra) # 80003416 <brelse>
  if(sb.magic != FSMAGIC)
    800038ae:	0009a703          	lw	a4,0(s3)
    800038b2:	102037b7          	lui	a5,0x10203
    800038b6:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800038ba:	02f71263          	bne	a4,a5,800038de <fsinit+0x70>
  initlog(dev, &sb);
    800038be:	0001c597          	auipc	a1,0x1c
    800038c2:	2ea58593          	addi	a1,a1,746 # 8001fba8 <sb>
    800038c6:	854a                	mv	a0,s2
    800038c8:	00001097          	auipc	ra,0x1
    800038cc:	b56080e7          	jalr	-1194(ra) # 8000441e <initlog>
}
    800038d0:	70a2                	ld	ra,40(sp)
    800038d2:	7402                	ld	s0,32(sp)
    800038d4:	64e2                	ld	s1,24(sp)
    800038d6:	6942                	ld	s2,16(sp)
    800038d8:	69a2                	ld	s3,8(sp)
    800038da:	6145                	addi	sp,sp,48
    800038dc:	8082                	ret
    panic("invalid file system");
    800038de:	00005517          	auipc	a0,0x5
    800038e2:	d5a50513          	addi	a0,a0,-678 # 80008638 <syscalls+0x170>
    800038e6:	ffffd097          	auipc	ra,0xffffd
    800038ea:	c54080e7          	jalr	-940(ra) # 8000053a <panic>

00000000800038ee <iinit>:
{
    800038ee:	7179                	addi	sp,sp,-48
    800038f0:	f406                	sd	ra,40(sp)
    800038f2:	f022                	sd	s0,32(sp)
    800038f4:	ec26                	sd	s1,24(sp)
    800038f6:	e84a                	sd	s2,16(sp)
    800038f8:	e44e                	sd	s3,8(sp)
    800038fa:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800038fc:	00005597          	auipc	a1,0x5
    80003900:	d5458593          	addi	a1,a1,-684 # 80008650 <syscalls+0x188>
    80003904:	0001c517          	auipc	a0,0x1c
    80003908:	2c450513          	addi	a0,a0,708 # 8001fbc8 <itable>
    8000390c:	ffffd097          	auipc	ra,0xffffd
    80003910:	234080e7          	jalr	564(ra) # 80000b40 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003914:	0001c497          	auipc	s1,0x1c
    80003918:	2dc48493          	addi	s1,s1,732 # 8001fbf0 <itable+0x28>
    8000391c:	0001e997          	auipc	s3,0x1e
    80003920:	d6498993          	addi	s3,s3,-668 # 80021680 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003924:	00005917          	auipc	s2,0x5
    80003928:	d3490913          	addi	s2,s2,-716 # 80008658 <syscalls+0x190>
    8000392c:	85ca                	mv	a1,s2
    8000392e:	8526                	mv	a0,s1
    80003930:	00001097          	auipc	ra,0x1
    80003934:	e4e080e7          	jalr	-434(ra) # 8000477e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003938:	08848493          	addi	s1,s1,136
    8000393c:	ff3498e3          	bne	s1,s3,8000392c <iinit+0x3e>
}
    80003940:	70a2                	ld	ra,40(sp)
    80003942:	7402                	ld	s0,32(sp)
    80003944:	64e2                	ld	s1,24(sp)
    80003946:	6942                	ld	s2,16(sp)
    80003948:	69a2                	ld	s3,8(sp)
    8000394a:	6145                	addi	sp,sp,48
    8000394c:	8082                	ret

000000008000394e <ialloc>:
{
    8000394e:	715d                	addi	sp,sp,-80
    80003950:	e486                	sd	ra,72(sp)
    80003952:	e0a2                	sd	s0,64(sp)
    80003954:	fc26                	sd	s1,56(sp)
    80003956:	f84a                	sd	s2,48(sp)
    80003958:	f44e                	sd	s3,40(sp)
    8000395a:	f052                	sd	s4,32(sp)
    8000395c:	ec56                	sd	s5,24(sp)
    8000395e:	e85a                	sd	s6,16(sp)
    80003960:	e45e                	sd	s7,8(sp)
    80003962:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003964:	0001c717          	auipc	a4,0x1c
    80003968:	25072703          	lw	a4,592(a4) # 8001fbb4 <sb+0xc>
    8000396c:	4785                	li	a5,1
    8000396e:	04e7fa63          	bgeu	a5,a4,800039c2 <ialloc+0x74>
    80003972:	8aaa                	mv	s5,a0
    80003974:	8bae                	mv	s7,a1
    80003976:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003978:	0001ca17          	auipc	s4,0x1c
    8000397c:	230a0a13          	addi	s4,s4,560 # 8001fba8 <sb>
    80003980:	00048b1b          	sext.w	s6,s1
    80003984:	0044d593          	srli	a1,s1,0x4
    80003988:	018a2783          	lw	a5,24(s4)
    8000398c:	9dbd                	addw	a1,a1,a5
    8000398e:	8556                	mv	a0,s5
    80003990:	00000097          	auipc	ra,0x0
    80003994:	956080e7          	jalr	-1706(ra) # 800032e6 <bread>
    80003998:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000399a:	05850993          	addi	s3,a0,88
    8000399e:	00f4f793          	andi	a5,s1,15
    800039a2:	079a                	slli	a5,a5,0x6
    800039a4:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800039a6:	00099783          	lh	a5,0(s3)
    800039aa:	c785                	beqz	a5,800039d2 <ialloc+0x84>
    brelse(bp);
    800039ac:	00000097          	auipc	ra,0x0
    800039b0:	a6a080e7          	jalr	-1430(ra) # 80003416 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800039b4:	0485                	addi	s1,s1,1
    800039b6:	00ca2703          	lw	a4,12(s4)
    800039ba:	0004879b          	sext.w	a5,s1
    800039be:	fce7e1e3          	bltu	a5,a4,80003980 <ialloc+0x32>
  panic("ialloc: no inodes");
    800039c2:	00005517          	auipc	a0,0x5
    800039c6:	c9e50513          	addi	a0,a0,-866 # 80008660 <syscalls+0x198>
    800039ca:	ffffd097          	auipc	ra,0xffffd
    800039ce:	b70080e7          	jalr	-1168(ra) # 8000053a <panic>
      memset(dip, 0, sizeof(*dip));
    800039d2:	04000613          	li	a2,64
    800039d6:	4581                	li	a1,0
    800039d8:	854e                	mv	a0,s3
    800039da:	ffffd097          	auipc	ra,0xffffd
    800039de:	2f2080e7          	jalr	754(ra) # 80000ccc <memset>
      dip->type = type;
    800039e2:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800039e6:	854a                	mv	a0,s2
    800039e8:	00001097          	auipc	ra,0x1
    800039ec:	cb2080e7          	jalr	-846(ra) # 8000469a <log_write>
      brelse(bp);
    800039f0:	854a                	mv	a0,s2
    800039f2:	00000097          	auipc	ra,0x0
    800039f6:	a24080e7          	jalr	-1500(ra) # 80003416 <brelse>
      return iget(dev, inum);
    800039fa:	85da                	mv	a1,s6
    800039fc:	8556                	mv	a0,s5
    800039fe:	00000097          	auipc	ra,0x0
    80003a02:	db4080e7          	jalr	-588(ra) # 800037b2 <iget>
}
    80003a06:	60a6                	ld	ra,72(sp)
    80003a08:	6406                	ld	s0,64(sp)
    80003a0a:	74e2                	ld	s1,56(sp)
    80003a0c:	7942                	ld	s2,48(sp)
    80003a0e:	79a2                	ld	s3,40(sp)
    80003a10:	7a02                	ld	s4,32(sp)
    80003a12:	6ae2                	ld	s5,24(sp)
    80003a14:	6b42                	ld	s6,16(sp)
    80003a16:	6ba2                	ld	s7,8(sp)
    80003a18:	6161                	addi	sp,sp,80
    80003a1a:	8082                	ret

0000000080003a1c <iupdate>:
{
    80003a1c:	1101                	addi	sp,sp,-32
    80003a1e:	ec06                	sd	ra,24(sp)
    80003a20:	e822                	sd	s0,16(sp)
    80003a22:	e426                	sd	s1,8(sp)
    80003a24:	e04a                	sd	s2,0(sp)
    80003a26:	1000                	addi	s0,sp,32
    80003a28:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a2a:	415c                	lw	a5,4(a0)
    80003a2c:	0047d79b          	srliw	a5,a5,0x4
    80003a30:	0001c597          	auipc	a1,0x1c
    80003a34:	1905a583          	lw	a1,400(a1) # 8001fbc0 <sb+0x18>
    80003a38:	9dbd                	addw	a1,a1,a5
    80003a3a:	4108                	lw	a0,0(a0)
    80003a3c:	00000097          	auipc	ra,0x0
    80003a40:	8aa080e7          	jalr	-1878(ra) # 800032e6 <bread>
    80003a44:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a46:	05850793          	addi	a5,a0,88
    80003a4a:	40d8                	lw	a4,4(s1)
    80003a4c:	8b3d                	andi	a4,a4,15
    80003a4e:	071a                	slli	a4,a4,0x6
    80003a50:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003a52:	04449703          	lh	a4,68(s1)
    80003a56:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003a5a:	04649703          	lh	a4,70(s1)
    80003a5e:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003a62:	04849703          	lh	a4,72(s1)
    80003a66:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003a6a:	04a49703          	lh	a4,74(s1)
    80003a6e:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003a72:	44f8                	lw	a4,76(s1)
    80003a74:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003a76:	03400613          	li	a2,52
    80003a7a:	05048593          	addi	a1,s1,80
    80003a7e:	00c78513          	addi	a0,a5,12
    80003a82:	ffffd097          	auipc	ra,0xffffd
    80003a86:	2a6080e7          	jalr	678(ra) # 80000d28 <memmove>
  log_write(bp);
    80003a8a:	854a                	mv	a0,s2
    80003a8c:	00001097          	auipc	ra,0x1
    80003a90:	c0e080e7          	jalr	-1010(ra) # 8000469a <log_write>
  brelse(bp);
    80003a94:	854a                	mv	a0,s2
    80003a96:	00000097          	auipc	ra,0x0
    80003a9a:	980080e7          	jalr	-1664(ra) # 80003416 <brelse>
}
    80003a9e:	60e2                	ld	ra,24(sp)
    80003aa0:	6442                	ld	s0,16(sp)
    80003aa2:	64a2                	ld	s1,8(sp)
    80003aa4:	6902                	ld	s2,0(sp)
    80003aa6:	6105                	addi	sp,sp,32
    80003aa8:	8082                	ret

0000000080003aaa <idup>:
{
    80003aaa:	1101                	addi	sp,sp,-32
    80003aac:	ec06                	sd	ra,24(sp)
    80003aae:	e822                	sd	s0,16(sp)
    80003ab0:	e426                	sd	s1,8(sp)
    80003ab2:	1000                	addi	s0,sp,32
    80003ab4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ab6:	0001c517          	auipc	a0,0x1c
    80003aba:	11250513          	addi	a0,a0,274 # 8001fbc8 <itable>
    80003abe:	ffffd097          	auipc	ra,0xffffd
    80003ac2:	112080e7          	jalr	274(ra) # 80000bd0 <acquire>
  ip->ref++;
    80003ac6:	449c                	lw	a5,8(s1)
    80003ac8:	2785                	addiw	a5,a5,1
    80003aca:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003acc:	0001c517          	auipc	a0,0x1c
    80003ad0:	0fc50513          	addi	a0,a0,252 # 8001fbc8 <itable>
    80003ad4:	ffffd097          	auipc	ra,0xffffd
    80003ad8:	1b0080e7          	jalr	432(ra) # 80000c84 <release>
}
    80003adc:	8526                	mv	a0,s1
    80003ade:	60e2                	ld	ra,24(sp)
    80003ae0:	6442                	ld	s0,16(sp)
    80003ae2:	64a2                	ld	s1,8(sp)
    80003ae4:	6105                	addi	sp,sp,32
    80003ae6:	8082                	ret

0000000080003ae8 <ilock>:
{
    80003ae8:	1101                	addi	sp,sp,-32
    80003aea:	ec06                	sd	ra,24(sp)
    80003aec:	e822                	sd	s0,16(sp)
    80003aee:	e426                	sd	s1,8(sp)
    80003af0:	e04a                	sd	s2,0(sp)
    80003af2:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003af4:	c115                	beqz	a0,80003b18 <ilock+0x30>
    80003af6:	84aa                	mv	s1,a0
    80003af8:	451c                	lw	a5,8(a0)
    80003afa:	00f05f63          	blez	a5,80003b18 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003afe:	0541                	addi	a0,a0,16
    80003b00:	00001097          	auipc	ra,0x1
    80003b04:	cb8080e7          	jalr	-840(ra) # 800047b8 <acquiresleep>
  if(ip->valid == 0){
    80003b08:	40bc                	lw	a5,64(s1)
    80003b0a:	cf99                	beqz	a5,80003b28 <ilock+0x40>
}
    80003b0c:	60e2                	ld	ra,24(sp)
    80003b0e:	6442                	ld	s0,16(sp)
    80003b10:	64a2                	ld	s1,8(sp)
    80003b12:	6902                	ld	s2,0(sp)
    80003b14:	6105                	addi	sp,sp,32
    80003b16:	8082                	ret
    panic("ilock");
    80003b18:	00005517          	auipc	a0,0x5
    80003b1c:	b6050513          	addi	a0,a0,-1184 # 80008678 <syscalls+0x1b0>
    80003b20:	ffffd097          	auipc	ra,0xffffd
    80003b24:	a1a080e7          	jalr	-1510(ra) # 8000053a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b28:	40dc                	lw	a5,4(s1)
    80003b2a:	0047d79b          	srliw	a5,a5,0x4
    80003b2e:	0001c597          	auipc	a1,0x1c
    80003b32:	0925a583          	lw	a1,146(a1) # 8001fbc0 <sb+0x18>
    80003b36:	9dbd                	addw	a1,a1,a5
    80003b38:	4088                	lw	a0,0(s1)
    80003b3a:	fffff097          	auipc	ra,0xfffff
    80003b3e:	7ac080e7          	jalr	1964(ra) # 800032e6 <bread>
    80003b42:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b44:	05850593          	addi	a1,a0,88
    80003b48:	40dc                	lw	a5,4(s1)
    80003b4a:	8bbd                	andi	a5,a5,15
    80003b4c:	079a                	slli	a5,a5,0x6
    80003b4e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003b50:	00059783          	lh	a5,0(a1)
    80003b54:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003b58:	00259783          	lh	a5,2(a1)
    80003b5c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003b60:	00459783          	lh	a5,4(a1)
    80003b64:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003b68:	00659783          	lh	a5,6(a1)
    80003b6c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003b70:	459c                	lw	a5,8(a1)
    80003b72:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003b74:	03400613          	li	a2,52
    80003b78:	05b1                	addi	a1,a1,12
    80003b7a:	05048513          	addi	a0,s1,80
    80003b7e:	ffffd097          	auipc	ra,0xffffd
    80003b82:	1aa080e7          	jalr	426(ra) # 80000d28 <memmove>
    brelse(bp);
    80003b86:	854a                	mv	a0,s2
    80003b88:	00000097          	auipc	ra,0x0
    80003b8c:	88e080e7          	jalr	-1906(ra) # 80003416 <brelse>
    ip->valid = 1;
    80003b90:	4785                	li	a5,1
    80003b92:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003b94:	04449783          	lh	a5,68(s1)
    80003b98:	fbb5                	bnez	a5,80003b0c <ilock+0x24>
      panic("ilock: no type");
    80003b9a:	00005517          	auipc	a0,0x5
    80003b9e:	ae650513          	addi	a0,a0,-1306 # 80008680 <syscalls+0x1b8>
    80003ba2:	ffffd097          	auipc	ra,0xffffd
    80003ba6:	998080e7          	jalr	-1640(ra) # 8000053a <panic>

0000000080003baa <iunlock>:
{
    80003baa:	1101                	addi	sp,sp,-32
    80003bac:	ec06                	sd	ra,24(sp)
    80003bae:	e822                	sd	s0,16(sp)
    80003bb0:	e426                	sd	s1,8(sp)
    80003bb2:	e04a                	sd	s2,0(sp)
    80003bb4:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003bb6:	c905                	beqz	a0,80003be6 <iunlock+0x3c>
    80003bb8:	84aa                	mv	s1,a0
    80003bba:	01050913          	addi	s2,a0,16
    80003bbe:	854a                	mv	a0,s2
    80003bc0:	00001097          	auipc	ra,0x1
    80003bc4:	c92080e7          	jalr	-878(ra) # 80004852 <holdingsleep>
    80003bc8:	cd19                	beqz	a0,80003be6 <iunlock+0x3c>
    80003bca:	449c                	lw	a5,8(s1)
    80003bcc:	00f05d63          	blez	a5,80003be6 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003bd0:	854a                	mv	a0,s2
    80003bd2:	00001097          	auipc	ra,0x1
    80003bd6:	c3c080e7          	jalr	-964(ra) # 8000480e <releasesleep>
}
    80003bda:	60e2                	ld	ra,24(sp)
    80003bdc:	6442                	ld	s0,16(sp)
    80003bde:	64a2                	ld	s1,8(sp)
    80003be0:	6902                	ld	s2,0(sp)
    80003be2:	6105                	addi	sp,sp,32
    80003be4:	8082                	ret
    panic("iunlock");
    80003be6:	00005517          	auipc	a0,0x5
    80003bea:	aaa50513          	addi	a0,a0,-1366 # 80008690 <syscalls+0x1c8>
    80003bee:	ffffd097          	auipc	ra,0xffffd
    80003bf2:	94c080e7          	jalr	-1716(ra) # 8000053a <panic>

0000000080003bf6 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003bf6:	7179                	addi	sp,sp,-48
    80003bf8:	f406                	sd	ra,40(sp)
    80003bfa:	f022                	sd	s0,32(sp)
    80003bfc:	ec26                	sd	s1,24(sp)
    80003bfe:	e84a                	sd	s2,16(sp)
    80003c00:	e44e                	sd	s3,8(sp)
    80003c02:	e052                	sd	s4,0(sp)
    80003c04:	1800                	addi	s0,sp,48
    80003c06:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003c08:	05050493          	addi	s1,a0,80
    80003c0c:	08050913          	addi	s2,a0,128
    80003c10:	a021                	j	80003c18 <itrunc+0x22>
    80003c12:	0491                	addi	s1,s1,4
    80003c14:	01248d63          	beq	s1,s2,80003c2e <itrunc+0x38>
    if(ip->addrs[i]){
    80003c18:	408c                	lw	a1,0(s1)
    80003c1a:	dde5                	beqz	a1,80003c12 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003c1c:	0009a503          	lw	a0,0(s3)
    80003c20:	00000097          	auipc	ra,0x0
    80003c24:	90c080e7          	jalr	-1780(ra) # 8000352c <bfree>
      ip->addrs[i] = 0;
    80003c28:	0004a023          	sw	zero,0(s1)
    80003c2c:	b7dd                	j	80003c12 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003c2e:	0809a583          	lw	a1,128(s3)
    80003c32:	e185                	bnez	a1,80003c52 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003c34:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003c38:	854e                	mv	a0,s3
    80003c3a:	00000097          	auipc	ra,0x0
    80003c3e:	de2080e7          	jalr	-542(ra) # 80003a1c <iupdate>
}
    80003c42:	70a2                	ld	ra,40(sp)
    80003c44:	7402                	ld	s0,32(sp)
    80003c46:	64e2                	ld	s1,24(sp)
    80003c48:	6942                	ld	s2,16(sp)
    80003c4a:	69a2                	ld	s3,8(sp)
    80003c4c:	6a02                	ld	s4,0(sp)
    80003c4e:	6145                	addi	sp,sp,48
    80003c50:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003c52:	0009a503          	lw	a0,0(s3)
    80003c56:	fffff097          	auipc	ra,0xfffff
    80003c5a:	690080e7          	jalr	1680(ra) # 800032e6 <bread>
    80003c5e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003c60:	05850493          	addi	s1,a0,88
    80003c64:	45850913          	addi	s2,a0,1112
    80003c68:	a021                	j	80003c70 <itrunc+0x7a>
    80003c6a:	0491                	addi	s1,s1,4
    80003c6c:	01248b63          	beq	s1,s2,80003c82 <itrunc+0x8c>
      if(a[j])
    80003c70:	408c                	lw	a1,0(s1)
    80003c72:	dde5                	beqz	a1,80003c6a <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003c74:	0009a503          	lw	a0,0(s3)
    80003c78:	00000097          	auipc	ra,0x0
    80003c7c:	8b4080e7          	jalr	-1868(ra) # 8000352c <bfree>
    80003c80:	b7ed                	j	80003c6a <itrunc+0x74>
    brelse(bp);
    80003c82:	8552                	mv	a0,s4
    80003c84:	fffff097          	auipc	ra,0xfffff
    80003c88:	792080e7          	jalr	1938(ra) # 80003416 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003c8c:	0809a583          	lw	a1,128(s3)
    80003c90:	0009a503          	lw	a0,0(s3)
    80003c94:	00000097          	auipc	ra,0x0
    80003c98:	898080e7          	jalr	-1896(ra) # 8000352c <bfree>
    ip->addrs[NDIRECT] = 0;
    80003c9c:	0809a023          	sw	zero,128(s3)
    80003ca0:	bf51                	j	80003c34 <itrunc+0x3e>

0000000080003ca2 <iput>:
{
    80003ca2:	1101                	addi	sp,sp,-32
    80003ca4:	ec06                	sd	ra,24(sp)
    80003ca6:	e822                	sd	s0,16(sp)
    80003ca8:	e426                	sd	s1,8(sp)
    80003caa:	e04a                	sd	s2,0(sp)
    80003cac:	1000                	addi	s0,sp,32
    80003cae:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003cb0:	0001c517          	auipc	a0,0x1c
    80003cb4:	f1850513          	addi	a0,a0,-232 # 8001fbc8 <itable>
    80003cb8:	ffffd097          	auipc	ra,0xffffd
    80003cbc:	f18080e7          	jalr	-232(ra) # 80000bd0 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003cc0:	4498                	lw	a4,8(s1)
    80003cc2:	4785                	li	a5,1
    80003cc4:	02f70363          	beq	a4,a5,80003cea <iput+0x48>
  ip->ref--;
    80003cc8:	449c                	lw	a5,8(s1)
    80003cca:	37fd                	addiw	a5,a5,-1
    80003ccc:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003cce:	0001c517          	auipc	a0,0x1c
    80003cd2:	efa50513          	addi	a0,a0,-262 # 8001fbc8 <itable>
    80003cd6:	ffffd097          	auipc	ra,0xffffd
    80003cda:	fae080e7          	jalr	-82(ra) # 80000c84 <release>
}
    80003cde:	60e2                	ld	ra,24(sp)
    80003ce0:	6442                	ld	s0,16(sp)
    80003ce2:	64a2                	ld	s1,8(sp)
    80003ce4:	6902                	ld	s2,0(sp)
    80003ce6:	6105                	addi	sp,sp,32
    80003ce8:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003cea:	40bc                	lw	a5,64(s1)
    80003cec:	dff1                	beqz	a5,80003cc8 <iput+0x26>
    80003cee:	04a49783          	lh	a5,74(s1)
    80003cf2:	fbf9                	bnez	a5,80003cc8 <iput+0x26>
    acquiresleep(&ip->lock);
    80003cf4:	01048913          	addi	s2,s1,16
    80003cf8:	854a                	mv	a0,s2
    80003cfa:	00001097          	auipc	ra,0x1
    80003cfe:	abe080e7          	jalr	-1346(ra) # 800047b8 <acquiresleep>
    release(&itable.lock);
    80003d02:	0001c517          	auipc	a0,0x1c
    80003d06:	ec650513          	addi	a0,a0,-314 # 8001fbc8 <itable>
    80003d0a:	ffffd097          	auipc	ra,0xffffd
    80003d0e:	f7a080e7          	jalr	-134(ra) # 80000c84 <release>
    itrunc(ip);
    80003d12:	8526                	mv	a0,s1
    80003d14:	00000097          	auipc	ra,0x0
    80003d18:	ee2080e7          	jalr	-286(ra) # 80003bf6 <itrunc>
    ip->type = 0;
    80003d1c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003d20:	8526                	mv	a0,s1
    80003d22:	00000097          	auipc	ra,0x0
    80003d26:	cfa080e7          	jalr	-774(ra) # 80003a1c <iupdate>
    ip->valid = 0;
    80003d2a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003d2e:	854a                	mv	a0,s2
    80003d30:	00001097          	auipc	ra,0x1
    80003d34:	ade080e7          	jalr	-1314(ra) # 8000480e <releasesleep>
    acquire(&itable.lock);
    80003d38:	0001c517          	auipc	a0,0x1c
    80003d3c:	e9050513          	addi	a0,a0,-368 # 8001fbc8 <itable>
    80003d40:	ffffd097          	auipc	ra,0xffffd
    80003d44:	e90080e7          	jalr	-368(ra) # 80000bd0 <acquire>
    80003d48:	b741                	j	80003cc8 <iput+0x26>

0000000080003d4a <iunlockput>:
{
    80003d4a:	1101                	addi	sp,sp,-32
    80003d4c:	ec06                	sd	ra,24(sp)
    80003d4e:	e822                	sd	s0,16(sp)
    80003d50:	e426                	sd	s1,8(sp)
    80003d52:	1000                	addi	s0,sp,32
    80003d54:	84aa                	mv	s1,a0
  iunlock(ip);
    80003d56:	00000097          	auipc	ra,0x0
    80003d5a:	e54080e7          	jalr	-428(ra) # 80003baa <iunlock>
  iput(ip);
    80003d5e:	8526                	mv	a0,s1
    80003d60:	00000097          	auipc	ra,0x0
    80003d64:	f42080e7          	jalr	-190(ra) # 80003ca2 <iput>
}
    80003d68:	60e2                	ld	ra,24(sp)
    80003d6a:	6442                	ld	s0,16(sp)
    80003d6c:	64a2                	ld	s1,8(sp)
    80003d6e:	6105                	addi	sp,sp,32
    80003d70:	8082                	ret

0000000080003d72 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003d72:	1141                	addi	sp,sp,-16
    80003d74:	e422                	sd	s0,8(sp)
    80003d76:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003d78:	411c                	lw	a5,0(a0)
    80003d7a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003d7c:	415c                	lw	a5,4(a0)
    80003d7e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003d80:	04451783          	lh	a5,68(a0)
    80003d84:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003d88:	04a51783          	lh	a5,74(a0)
    80003d8c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003d90:	04c56783          	lwu	a5,76(a0)
    80003d94:	e99c                	sd	a5,16(a1)
}
    80003d96:	6422                	ld	s0,8(sp)
    80003d98:	0141                	addi	sp,sp,16
    80003d9a:	8082                	ret

0000000080003d9c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d9c:	457c                	lw	a5,76(a0)
    80003d9e:	0ed7e963          	bltu	a5,a3,80003e90 <readi+0xf4>
{
    80003da2:	7159                	addi	sp,sp,-112
    80003da4:	f486                	sd	ra,104(sp)
    80003da6:	f0a2                	sd	s0,96(sp)
    80003da8:	eca6                	sd	s1,88(sp)
    80003daa:	e8ca                	sd	s2,80(sp)
    80003dac:	e4ce                	sd	s3,72(sp)
    80003dae:	e0d2                	sd	s4,64(sp)
    80003db0:	fc56                	sd	s5,56(sp)
    80003db2:	f85a                	sd	s6,48(sp)
    80003db4:	f45e                	sd	s7,40(sp)
    80003db6:	f062                	sd	s8,32(sp)
    80003db8:	ec66                	sd	s9,24(sp)
    80003dba:	e86a                	sd	s10,16(sp)
    80003dbc:	e46e                	sd	s11,8(sp)
    80003dbe:	1880                	addi	s0,sp,112
    80003dc0:	8baa                	mv	s7,a0
    80003dc2:	8c2e                	mv	s8,a1
    80003dc4:	8ab2                	mv	s5,a2
    80003dc6:	84b6                	mv	s1,a3
    80003dc8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003dca:	9f35                	addw	a4,a4,a3
    return 0;
    80003dcc:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003dce:	0ad76063          	bltu	a4,a3,80003e6e <readi+0xd2>
  if(off + n > ip->size)
    80003dd2:	00e7f463          	bgeu	a5,a4,80003dda <readi+0x3e>
    n = ip->size - off;
    80003dd6:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003dda:	0a0b0963          	beqz	s6,80003e8c <readi+0xf0>
    80003dde:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003de0:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003de4:	5cfd                	li	s9,-1
    80003de6:	a82d                	j	80003e20 <readi+0x84>
    80003de8:	020a1d93          	slli	s11,s4,0x20
    80003dec:	020ddd93          	srli	s11,s11,0x20
    80003df0:	05890613          	addi	a2,s2,88
    80003df4:	86ee                	mv	a3,s11
    80003df6:	963a                	add	a2,a2,a4
    80003df8:	85d6                	mv	a1,s5
    80003dfa:	8562                	mv	a0,s8
    80003dfc:	ffffe097          	auipc	ra,0xffffe
    80003e00:	740080e7          	jalr	1856(ra) # 8000253c <either_copyout>
    80003e04:	05950d63          	beq	a0,s9,80003e5e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003e08:	854a                	mv	a0,s2
    80003e0a:	fffff097          	auipc	ra,0xfffff
    80003e0e:	60c080e7          	jalr	1548(ra) # 80003416 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e12:	013a09bb          	addw	s3,s4,s3
    80003e16:	009a04bb          	addw	s1,s4,s1
    80003e1a:	9aee                	add	s5,s5,s11
    80003e1c:	0569f763          	bgeu	s3,s6,80003e6a <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003e20:	000ba903          	lw	s2,0(s7)
    80003e24:	00a4d59b          	srliw	a1,s1,0xa
    80003e28:	855e                	mv	a0,s7
    80003e2a:	00000097          	auipc	ra,0x0
    80003e2e:	8ac080e7          	jalr	-1876(ra) # 800036d6 <bmap>
    80003e32:	0005059b          	sext.w	a1,a0
    80003e36:	854a                	mv	a0,s2
    80003e38:	fffff097          	auipc	ra,0xfffff
    80003e3c:	4ae080e7          	jalr	1198(ra) # 800032e6 <bread>
    80003e40:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e42:	3ff4f713          	andi	a4,s1,1023
    80003e46:	40ed07bb          	subw	a5,s10,a4
    80003e4a:	413b06bb          	subw	a3,s6,s3
    80003e4e:	8a3e                	mv	s4,a5
    80003e50:	2781                	sext.w	a5,a5
    80003e52:	0006861b          	sext.w	a2,a3
    80003e56:	f8f679e3          	bgeu	a2,a5,80003de8 <readi+0x4c>
    80003e5a:	8a36                	mv	s4,a3
    80003e5c:	b771                	j	80003de8 <readi+0x4c>
      brelse(bp);
    80003e5e:	854a                	mv	a0,s2
    80003e60:	fffff097          	auipc	ra,0xfffff
    80003e64:	5b6080e7          	jalr	1462(ra) # 80003416 <brelse>
      tot = -1;
    80003e68:	59fd                	li	s3,-1
  }
  return tot;
    80003e6a:	0009851b          	sext.w	a0,s3
}
    80003e6e:	70a6                	ld	ra,104(sp)
    80003e70:	7406                	ld	s0,96(sp)
    80003e72:	64e6                	ld	s1,88(sp)
    80003e74:	6946                	ld	s2,80(sp)
    80003e76:	69a6                	ld	s3,72(sp)
    80003e78:	6a06                	ld	s4,64(sp)
    80003e7a:	7ae2                	ld	s5,56(sp)
    80003e7c:	7b42                	ld	s6,48(sp)
    80003e7e:	7ba2                	ld	s7,40(sp)
    80003e80:	7c02                	ld	s8,32(sp)
    80003e82:	6ce2                	ld	s9,24(sp)
    80003e84:	6d42                	ld	s10,16(sp)
    80003e86:	6da2                	ld	s11,8(sp)
    80003e88:	6165                	addi	sp,sp,112
    80003e8a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e8c:	89da                	mv	s3,s6
    80003e8e:	bff1                	j	80003e6a <readi+0xce>
    return 0;
    80003e90:	4501                	li	a0,0
}
    80003e92:	8082                	ret

0000000080003e94 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e94:	457c                	lw	a5,76(a0)
    80003e96:	10d7e863          	bltu	a5,a3,80003fa6 <writei+0x112>
{
    80003e9a:	7159                	addi	sp,sp,-112
    80003e9c:	f486                	sd	ra,104(sp)
    80003e9e:	f0a2                	sd	s0,96(sp)
    80003ea0:	eca6                	sd	s1,88(sp)
    80003ea2:	e8ca                	sd	s2,80(sp)
    80003ea4:	e4ce                	sd	s3,72(sp)
    80003ea6:	e0d2                	sd	s4,64(sp)
    80003ea8:	fc56                	sd	s5,56(sp)
    80003eaa:	f85a                	sd	s6,48(sp)
    80003eac:	f45e                	sd	s7,40(sp)
    80003eae:	f062                	sd	s8,32(sp)
    80003eb0:	ec66                	sd	s9,24(sp)
    80003eb2:	e86a                	sd	s10,16(sp)
    80003eb4:	e46e                	sd	s11,8(sp)
    80003eb6:	1880                	addi	s0,sp,112
    80003eb8:	8b2a                	mv	s6,a0
    80003eba:	8c2e                	mv	s8,a1
    80003ebc:	8ab2                	mv	s5,a2
    80003ebe:	8936                	mv	s2,a3
    80003ec0:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003ec2:	00e687bb          	addw	a5,a3,a4
    80003ec6:	0ed7e263          	bltu	a5,a3,80003faa <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003eca:	00043737          	lui	a4,0x43
    80003ece:	0ef76063          	bltu	a4,a5,80003fae <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ed2:	0c0b8863          	beqz	s7,80003fa2 <writei+0x10e>
    80003ed6:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ed8:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003edc:	5cfd                	li	s9,-1
    80003ede:	a091                	j	80003f22 <writei+0x8e>
    80003ee0:	02099d93          	slli	s11,s3,0x20
    80003ee4:	020ddd93          	srli	s11,s11,0x20
    80003ee8:	05848513          	addi	a0,s1,88
    80003eec:	86ee                	mv	a3,s11
    80003eee:	8656                	mv	a2,s5
    80003ef0:	85e2                	mv	a1,s8
    80003ef2:	953a                	add	a0,a0,a4
    80003ef4:	ffffe097          	auipc	ra,0xffffe
    80003ef8:	69e080e7          	jalr	1694(ra) # 80002592 <either_copyin>
    80003efc:	07950263          	beq	a0,s9,80003f60 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003f00:	8526                	mv	a0,s1
    80003f02:	00000097          	auipc	ra,0x0
    80003f06:	798080e7          	jalr	1944(ra) # 8000469a <log_write>
    brelse(bp);
    80003f0a:	8526                	mv	a0,s1
    80003f0c:	fffff097          	auipc	ra,0xfffff
    80003f10:	50a080e7          	jalr	1290(ra) # 80003416 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f14:	01498a3b          	addw	s4,s3,s4
    80003f18:	0129893b          	addw	s2,s3,s2
    80003f1c:	9aee                	add	s5,s5,s11
    80003f1e:	057a7663          	bgeu	s4,s7,80003f6a <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003f22:	000b2483          	lw	s1,0(s6)
    80003f26:	00a9559b          	srliw	a1,s2,0xa
    80003f2a:	855a                	mv	a0,s6
    80003f2c:	fffff097          	auipc	ra,0xfffff
    80003f30:	7aa080e7          	jalr	1962(ra) # 800036d6 <bmap>
    80003f34:	0005059b          	sext.w	a1,a0
    80003f38:	8526                	mv	a0,s1
    80003f3a:	fffff097          	auipc	ra,0xfffff
    80003f3e:	3ac080e7          	jalr	940(ra) # 800032e6 <bread>
    80003f42:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f44:	3ff97713          	andi	a4,s2,1023
    80003f48:	40ed07bb          	subw	a5,s10,a4
    80003f4c:	414b86bb          	subw	a3,s7,s4
    80003f50:	89be                	mv	s3,a5
    80003f52:	2781                	sext.w	a5,a5
    80003f54:	0006861b          	sext.w	a2,a3
    80003f58:	f8f674e3          	bgeu	a2,a5,80003ee0 <writei+0x4c>
    80003f5c:	89b6                	mv	s3,a3
    80003f5e:	b749                	j	80003ee0 <writei+0x4c>
      brelse(bp);
    80003f60:	8526                	mv	a0,s1
    80003f62:	fffff097          	auipc	ra,0xfffff
    80003f66:	4b4080e7          	jalr	1204(ra) # 80003416 <brelse>
  }

  if(off > ip->size)
    80003f6a:	04cb2783          	lw	a5,76(s6)
    80003f6e:	0127f463          	bgeu	a5,s2,80003f76 <writei+0xe2>
    ip->size = off;
    80003f72:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003f76:	855a                	mv	a0,s6
    80003f78:	00000097          	auipc	ra,0x0
    80003f7c:	aa4080e7          	jalr	-1372(ra) # 80003a1c <iupdate>

  return tot;
    80003f80:	000a051b          	sext.w	a0,s4
}
    80003f84:	70a6                	ld	ra,104(sp)
    80003f86:	7406                	ld	s0,96(sp)
    80003f88:	64e6                	ld	s1,88(sp)
    80003f8a:	6946                	ld	s2,80(sp)
    80003f8c:	69a6                	ld	s3,72(sp)
    80003f8e:	6a06                	ld	s4,64(sp)
    80003f90:	7ae2                	ld	s5,56(sp)
    80003f92:	7b42                	ld	s6,48(sp)
    80003f94:	7ba2                	ld	s7,40(sp)
    80003f96:	7c02                	ld	s8,32(sp)
    80003f98:	6ce2                	ld	s9,24(sp)
    80003f9a:	6d42                	ld	s10,16(sp)
    80003f9c:	6da2                	ld	s11,8(sp)
    80003f9e:	6165                	addi	sp,sp,112
    80003fa0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fa2:	8a5e                	mv	s4,s7
    80003fa4:	bfc9                	j	80003f76 <writei+0xe2>
    return -1;
    80003fa6:	557d                	li	a0,-1
}
    80003fa8:	8082                	ret
    return -1;
    80003faa:	557d                	li	a0,-1
    80003fac:	bfe1                	j	80003f84 <writei+0xf0>
    return -1;
    80003fae:	557d                	li	a0,-1
    80003fb0:	bfd1                	j	80003f84 <writei+0xf0>

0000000080003fb2 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003fb2:	1141                	addi	sp,sp,-16
    80003fb4:	e406                	sd	ra,8(sp)
    80003fb6:	e022                	sd	s0,0(sp)
    80003fb8:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003fba:	4639                	li	a2,14
    80003fbc:	ffffd097          	auipc	ra,0xffffd
    80003fc0:	de0080e7          	jalr	-544(ra) # 80000d9c <strncmp>
}
    80003fc4:	60a2                	ld	ra,8(sp)
    80003fc6:	6402                	ld	s0,0(sp)
    80003fc8:	0141                	addi	sp,sp,16
    80003fca:	8082                	ret

0000000080003fcc <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003fcc:	7139                	addi	sp,sp,-64
    80003fce:	fc06                	sd	ra,56(sp)
    80003fd0:	f822                	sd	s0,48(sp)
    80003fd2:	f426                	sd	s1,40(sp)
    80003fd4:	f04a                	sd	s2,32(sp)
    80003fd6:	ec4e                	sd	s3,24(sp)
    80003fd8:	e852                	sd	s4,16(sp)
    80003fda:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003fdc:	04451703          	lh	a4,68(a0)
    80003fe0:	4785                	li	a5,1
    80003fe2:	00f71a63          	bne	a4,a5,80003ff6 <dirlookup+0x2a>
    80003fe6:	892a                	mv	s2,a0
    80003fe8:	89ae                	mv	s3,a1
    80003fea:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fec:	457c                	lw	a5,76(a0)
    80003fee:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003ff0:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ff2:	e79d                	bnez	a5,80004020 <dirlookup+0x54>
    80003ff4:	a8a5                	j	8000406c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003ff6:	00004517          	auipc	a0,0x4
    80003ffa:	6a250513          	addi	a0,a0,1698 # 80008698 <syscalls+0x1d0>
    80003ffe:	ffffc097          	auipc	ra,0xffffc
    80004002:	53c080e7          	jalr	1340(ra) # 8000053a <panic>
      panic("dirlookup read");
    80004006:	00004517          	auipc	a0,0x4
    8000400a:	6aa50513          	addi	a0,a0,1706 # 800086b0 <syscalls+0x1e8>
    8000400e:	ffffc097          	auipc	ra,0xffffc
    80004012:	52c080e7          	jalr	1324(ra) # 8000053a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004016:	24c1                	addiw	s1,s1,16
    80004018:	04c92783          	lw	a5,76(s2)
    8000401c:	04f4f763          	bgeu	s1,a5,8000406a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004020:	4741                	li	a4,16
    80004022:	86a6                	mv	a3,s1
    80004024:	fc040613          	addi	a2,s0,-64
    80004028:	4581                	li	a1,0
    8000402a:	854a                	mv	a0,s2
    8000402c:	00000097          	auipc	ra,0x0
    80004030:	d70080e7          	jalr	-656(ra) # 80003d9c <readi>
    80004034:	47c1                	li	a5,16
    80004036:	fcf518e3          	bne	a0,a5,80004006 <dirlookup+0x3a>
    if(de.inum == 0)
    8000403a:	fc045783          	lhu	a5,-64(s0)
    8000403e:	dfe1                	beqz	a5,80004016 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004040:	fc240593          	addi	a1,s0,-62
    80004044:	854e                	mv	a0,s3
    80004046:	00000097          	auipc	ra,0x0
    8000404a:	f6c080e7          	jalr	-148(ra) # 80003fb2 <namecmp>
    8000404e:	f561                	bnez	a0,80004016 <dirlookup+0x4a>
      if(poff)
    80004050:	000a0463          	beqz	s4,80004058 <dirlookup+0x8c>
        *poff = off;
    80004054:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004058:	fc045583          	lhu	a1,-64(s0)
    8000405c:	00092503          	lw	a0,0(s2)
    80004060:	fffff097          	auipc	ra,0xfffff
    80004064:	752080e7          	jalr	1874(ra) # 800037b2 <iget>
    80004068:	a011                	j	8000406c <dirlookup+0xa0>
  return 0;
    8000406a:	4501                	li	a0,0
}
    8000406c:	70e2                	ld	ra,56(sp)
    8000406e:	7442                	ld	s0,48(sp)
    80004070:	74a2                	ld	s1,40(sp)
    80004072:	7902                	ld	s2,32(sp)
    80004074:	69e2                	ld	s3,24(sp)
    80004076:	6a42                	ld	s4,16(sp)
    80004078:	6121                	addi	sp,sp,64
    8000407a:	8082                	ret

000000008000407c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000407c:	711d                	addi	sp,sp,-96
    8000407e:	ec86                	sd	ra,88(sp)
    80004080:	e8a2                	sd	s0,80(sp)
    80004082:	e4a6                	sd	s1,72(sp)
    80004084:	e0ca                	sd	s2,64(sp)
    80004086:	fc4e                	sd	s3,56(sp)
    80004088:	f852                	sd	s4,48(sp)
    8000408a:	f456                	sd	s5,40(sp)
    8000408c:	f05a                	sd	s6,32(sp)
    8000408e:	ec5e                	sd	s7,24(sp)
    80004090:	e862                	sd	s8,16(sp)
    80004092:	e466                	sd	s9,8(sp)
    80004094:	e06a                	sd	s10,0(sp)
    80004096:	1080                	addi	s0,sp,96
    80004098:	84aa                	mv	s1,a0
    8000409a:	8b2e                	mv	s6,a1
    8000409c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000409e:	00054703          	lbu	a4,0(a0)
    800040a2:	02f00793          	li	a5,47
    800040a6:	02f70363          	beq	a4,a5,800040cc <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800040aa:	ffffe097          	auipc	ra,0xffffe
    800040ae:	8ec080e7          	jalr	-1812(ra) # 80001996 <myproc>
    800040b2:	16053503          	ld	a0,352(a0)
    800040b6:	00000097          	auipc	ra,0x0
    800040ba:	9f4080e7          	jalr	-1548(ra) # 80003aaa <idup>
    800040be:	8a2a                	mv	s4,a0
  while(*path == '/')
    800040c0:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800040c4:	4cb5                	li	s9,13
  len = path - s;
    800040c6:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800040c8:	4c05                	li	s8,1
    800040ca:	a87d                	j	80004188 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    800040cc:	4585                	li	a1,1
    800040ce:	4505                	li	a0,1
    800040d0:	fffff097          	auipc	ra,0xfffff
    800040d4:	6e2080e7          	jalr	1762(ra) # 800037b2 <iget>
    800040d8:	8a2a                	mv	s4,a0
    800040da:	b7dd                	j	800040c0 <namex+0x44>
      iunlockput(ip);
    800040dc:	8552                	mv	a0,s4
    800040de:	00000097          	auipc	ra,0x0
    800040e2:	c6c080e7          	jalr	-916(ra) # 80003d4a <iunlockput>
      return 0;
    800040e6:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800040e8:	8552                	mv	a0,s4
    800040ea:	60e6                	ld	ra,88(sp)
    800040ec:	6446                	ld	s0,80(sp)
    800040ee:	64a6                	ld	s1,72(sp)
    800040f0:	6906                	ld	s2,64(sp)
    800040f2:	79e2                	ld	s3,56(sp)
    800040f4:	7a42                	ld	s4,48(sp)
    800040f6:	7aa2                	ld	s5,40(sp)
    800040f8:	7b02                	ld	s6,32(sp)
    800040fa:	6be2                	ld	s7,24(sp)
    800040fc:	6c42                	ld	s8,16(sp)
    800040fe:	6ca2                	ld	s9,8(sp)
    80004100:	6d02                	ld	s10,0(sp)
    80004102:	6125                	addi	sp,sp,96
    80004104:	8082                	ret
      iunlock(ip);
    80004106:	8552                	mv	a0,s4
    80004108:	00000097          	auipc	ra,0x0
    8000410c:	aa2080e7          	jalr	-1374(ra) # 80003baa <iunlock>
      return ip;
    80004110:	bfe1                	j	800040e8 <namex+0x6c>
      iunlockput(ip);
    80004112:	8552                	mv	a0,s4
    80004114:	00000097          	auipc	ra,0x0
    80004118:	c36080e7          	jalr	-970(ra) # 80003d4a <iunlockput>
      return 0;
    8000411c:	8a4e                	mv	s4,s3
    8000411e:	b7e9                	j	800040e8 <namex+0x6c>
  len = path - s;
    80004120:	40998633          	sub	a2,s3,s1
    80004124:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80004128:	09acd863          	bge	s9,s10,800041b8 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    8000412c:	4639                	li	a2,14
    8000412e:	85a6                	mv	a1,s1
    80004130:	8556                	mv	a0,s5
    80004132:	ffffd097          	auipc	ra,0xffffd
    80004136:	bf6080e7          	jalr	-1034(ra) # 80000d28 <memmove>
    8000413a:	84ce                	mv	s1,s3
  while(*path == '/')
    8000413c:	0004c783          	lbu	a5,0(s1)
    80004140:	01279763          	bne	a5,s2,8000414e <namex+0xd2>
    path++;
    80004144:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004146:	0004c783          	lbu	a5,0(s1)
    8000414a:	ff278de3          	beq	a5,s2,80004144 <namex+0xc8>
    ilock(ip);
    8000414e:	8552                	mv	a0,s4
    80004150:	00000097          	auipc	ra,0x0
    80004154:	998080e7          	jalr	-1640(ra) # 80003ae8 <ilock>
    if(ip->type != T_DIR){
    80004158:	044a1783          	lh	a5,68(s4)
    8000415c:	f98790e3          	bne	a5,s8,800040dc <namex+0x60>
    if(nameiparent && *path == '\0'){
    80004160:	000b0563          	beqz	s6,8000416a <namex+0xee>
    80004164:	0004c783          	lbu	a5,0(s1)
    80004168:	dfd9                	beqz	a5,80004106 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000416a:	865e                	mv	a2,s7
    8000416c:	85d6                	mv	a1,s5
    8000416e:	8552                	mv	a0,s4
    80004170:	00000097          	auipc	ra,0x0
    80004174:	e5c080e7          	jalr	-420(ra) # 80003fcc <dirlookup>
    80004178:	89aa                	mv	s3,a0
    8000417a:	dd41                	beqz	a0,80004112 <namex+0x96>
    iunlockput(ip);
    8000417c:	8552                	mv	a0,s4
    8000417e:	00000097          	auipc	ra,0x0
    80004182:	bcc080e7          	jalr	-1076(ra) # 80003d4a <iunlockput>
    ip = next;
    80004186:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004188:	0004c783          	lbu	a5,0(s1)
    8000418c:	01279763          	bne	a5,s2,8000419a <namex+0x11e>
    path++;
    80004190:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004192:	0004c783          	lbu	a5,0(s1)
    80004196:	ff278de3          	beq	a5,s2,80004190 <namex+0x114>
  if(*path == 0)
    8000419a:	cb9d                	beqz	a5,800041d0 <namex+0x154>
  while(*path != '/' && *path != 0)
    8000419c:	0004c783          	lbu	a5,0(s1)
    800041a0:	89a6                	mv	s3,s1
  len = path - s;
    800041a2:	8d5e                	mv	s10,s7
    800041a4:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800041a6:	01278963          	beq	a5,s2,800041b8 <namex+0x13c>
    800041aa:	dbbd                	beqz	a5,80004120 <namex+0xa4>
    path++;
    800041ac:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800041ae:	0009c783          	lbu	a5,0(s3)
    800041b2:	ff279ce3          	bne	a5,s2,800041aa <namex+0x12e>
    800041b6:	b7ad                	j	80004120 <namex+0xa4>
    memmove(name, s, len);
    800041b8:	2601                	sext.w	a2,a2
    800041ba:	85a6                	mv	a1,s1
    800041bc:	8556                	mv	a0,s5
    800041be:	ffffd097          	auipc	ra,0xffffd
    800041c2:	b6a080e7          	jalr	-1174(ra) # 80000d28 <memmove>
    name[len] = 0;
    800041c6:	9d56                	add	s10,s10,s5
    800041c8:	000d0023          	sb	zero,0(s10)
    800041cc:	84ce                	mv	s1,s3
    800041ce:	b7bd                	j	8000413c <namex+0xc0>
  if(nameiparent){
    800041d0:	f00b0ce3          	beqz	s6,800040e8 <namex+0x6c>
    iput(ip);
    800041d4:	8552                	mv	a0,s4
    800041d6:	00000097          	auipc	ra,0x0
    800041da:	acc080e7          	jalr	-1332(ra) # 80003ca2 <iput>
    return 0;
    800041de:	4a01                	li	s4,0
    800041e0:	b721                	j	800040e8 <namex+0x6c>

00000000800041e2 <dirlink>:
{
    800041e2:	7139                	addi	sp,sp,-64
    800041e4:	fc06                	sd	ra,56(sp)
    800041e6:	f822                	sd	s0,48(sp)
    800041e8:	f426                	sd	s1,40(sp)
    800041ea:	f04a                	sd	s2,32(sp)
    800041ec:	ec4e                	sd	s3,24(sp)
    800041ee:	e852                	sd	s4,16(sp)
    800041f0:	0080                	addi	s0,sp,64
    800041f2:	892a                	mv	s2,a0
    800041f4:	8a2e                	mv	s4,a1
    800041f6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800041f8:	4601                	li	a2,0
    800041fa:	00000097          	auipc	ra,0x0
    800041fe:	dd2080e7          	jalr	-558(ra) # 80003fcc <dirlookup>
    80004202:	e93d                	bnez	a0,80004278 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004204:	04c92483          	lw	s1,76(s2)
    80004208:	c49d                	beqz	s1,80004236 <dirlink+0x54>
    8000420a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000420c:	4741                	li	a4,16
    8000420e:	86a6                	mv	a3,s1
    80004210:	fc040613          	addi	a2,s0,-64
    80004214:	4581                	li	a1,0
    80004216:	854a                	mv	a0,s2
    80004218:	00000097          	auipc	ra,0x0
    8000421c:	b84080e7          	jalr	-1148(ra) # 80003d9c <readi>
    80004220:	47c1                	li	a5,16
    80004222:	06f51163          	bne	a0,a5,80004284 <dirlink+0xa2>
    if(de.inum == 0)
    80004226:	fc045783          	lhu	a5,-64(s0)
    8000422a:	c791                	beqz	a5,80004236 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000422c:	24c1                	addiw	s1,s1,16
    8000422e:	04c92783          	lw	a5,76(s2)
    80004232:	fcf4ede3          	bltu	s1,a5,8000420c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004236:	4639                	li	a2,14
    80004238:	85d2                	mv	a1,s4
    8000423a:	fc240513          	addi	a0,s0,-62
    8000423e:	ffffd097          	auipc	ra,0xffffd
    80004242:	b9a080e7          	jalr	-1126(ra) # 80000dd8 <strncpy>
  de.inum = inum;
    80004246:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000424a:	4741                	li	a4,16
    8000424c:	86a6                	mv	a3,s1
    8000424e:	fc040613          	addi	a2,s0,-64
    80004252:	4581                	li	a1,0
    80004254:	854a                	mv	a0,s2
    80004256:	00000097          	auipc	ra,0x0
    8000425a:	c3e080e7          	jalr	-962(ra) # 80003e94 <writei>
    8000425e:	872a                	mv	a4,a0
    80004260:	47c1                	li	a5,16
  return 0;
    80004262:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004264:	02f71863          	bne	a4,a5,80004294 <dirlink+0xb2>
}
    80004268:	70e2                	ld	ra,56(sp)
    8000426a:	7442                	ld	s0,48(sp)
    8000426c:	74a2                	ld	s1,40(sp)
    8000426e:	7902                	ld	s2,32(sp)
    80004270:	69e2                	ld	s3,24(sp)
    80004272:	6a42                	ld	s4,16(sp)
    80004274:	6121                	addi	sp,sp,64
    80004276:	8082                	ret
    iput(ip);
    80004278:	00000097          	auipc	ra,0x0
    8000427c:	a2a080e7          	jalr	-1494(ra) # 80003ca2 <iput>
    return -1;
    80004280:	557d                	li	a0,-1
    80004282:	b7dd                	j	80004268 <dirlink+0x86>
      panic("dirlink read");
    80004284:	00004517          	auipc	a0,0x4
    80004288:	43c50513          	addi	a0,a0,1084 # 800086c0 <syscalls+0x1f8>
    8000428c:	ffffc097          	auipc	ra,0xffffc
    80004290:	2ae080e7          	jalr	686(ra) # 8000053a <panic>
    panic("dirlink");
    80004294:	00004517          	auipc	a0,0x4
    80004298:	53c50513          	addi	a0,a0,1340 # 800087d0 <syscalls+0x308>
    8000429c:	ffffc097          	auipc	ra,0xffffc
    800042a0:	29e080e7          	jalr	670(ra) # 8000053a <panic>

00000000800042a4 <namei>:

struct inode*
namei(char *path)
{
    800042a4:	1101                	addi	sp,sp,-32
    800042a6:	ec06                	sd	ra,24(sp)
    800042a8:	e822                	sd	s0,16(sp)
    800042aa:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800042ac:	fe040613          	addi	a2,s0,-32
    800042b0:	4581                	li	a1,0
    800042b2:	00000097          	auipc	ra,0x0
    800042b6:	dca080e7          	jalr	-566(ra) # 8000407c <namex>
}
    800042ba:	60e2                	ld	ra,24(sp)
    800042bc:	6442                	ld	s0,16(sp)
    800042be:	6105                	addi	sp,sp,32
    800042c0:	8082                	ret

00000000800042c2 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800042c2:	1141                	addi	sp,sp,-16
    800042c4:	e406                	sd	ra,8(sp)
    800042c6:	e022                	sd	s0,0(sp)
    800042c8:	0800                	addi	s0,sp,16
    800042ca:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800042cc:	4585                	li	a1,1
    800042ce:	00000097          	auipc	ra,0x0
    800042d2:	dae080e7          	jalr	-594(ra) # 8000407c <namex>
}
    800042d6:	60a2                	ld	ra,8(sp)
    800042d8:	6402                	ld	s0,0(sp)
    800042da:	0141                	addi	sp,sp,16
    800042dc:	8082                	ret

00000000800042de <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800042de:	1101                	addi	sp,sp,-32
    800042e0:	ec06                	sd	ra,24(sp)
    800042e2:	e822                	sd	s0,16(sp)
    800042e4:	e426                	sd	s1,8(sp)
    800042e6:	e04a                	sd	s2,0(sp)
    800042e8:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800042ea:	0001d917          	auipc	s2,0x1d
    800042ee:	38690913          	addi	s2,s2,902 # 80021670 <log>
    800042f2:	01892583          	lw	a1,24(s2)
    800042f6:	02892503          	lw	a0,40(s2)
    800042fa:	fffff097          	auipc	ra,0xfffff
    800042fe:	fec080e7          	jalr	-20(ra) # 800032e6 <bread>
    80004302:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004304:	02c92683          	lw	a3,44(s2)
    80004308:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000430a:	02d05863          	blez	a3,8000433a <write_head+0x5c>
    8000430e:	0001d797          	auipc	a5,0x1d
    80004312:	39278793          	addi	a5,a5,914 # 800216a0 <log+0x30>
    80004316:	05c50713          	addi	a4,a0,92
    8000431a:	36fd                	addiw	a3,a3,-1
    8000431c:	02069613          	slli	a2,a3,0x20
    80004320:	01e65693          	srli	a3,a2,0x1e
    80004324:	0001d617          	auipc	a2,0x1d
    80004328:	38060613          	addi	a2,a2,896 # 800216a4 <log+0x34>
    8000432c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000432e:	4390                	lw	a2,0(a5)
    80004330:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004332:	0791                	addi	a5,a5,4
    80004334:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80004336:	fed79ce3          	bne	a5,a3,8000432e <write_head+0x50>
  }
  bwrite(buf);
    8000433a:	8526                	mv	a0,s1
    8000433c:	fffff097          	auipc	ra,0xfffff
    80004340:	09c080e7          	jalr	156(ra) # 800033d8 <bwrite>
  brelse(buf);
    80004344:	8526                	mv	a0,s1
    80004346:	fffff097          	auipc	ra,0xfffff
    8000434a:	0d0080e7          	jalr	208(ra) # 80003416 <brelse>
}
    8000434e:	60e2                	ld	ra,24(sp)
    80004350:	6442                	ld	s0,16(sp)
    80004352:	64a2                	ld	s1,8(sp)
    80004354:	6902                	ld	s2,0(sp)
    80004356:	6105                	addi	sp,sp,32
    80004358:	8082                	ret

000000008000435a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000435a:	0001d797          	auipc	a5,0x1d
    8000435e:	3427a783          	lw	a5,834(a5) # 8002169c <log+0x2c>
    80004362:	0af05d63          	blez	a5,8000441c <install_trans+0xc2>
{
    80004366:	7139                	addi	sp,sp,-64
    80004368:	fc06                	sd	ra,56(sp)
    8000436a:	f822                	sd	s0,48(sp)
    8000436c:	f426                	sd	s1,40(sp)
    8000436e:	f04a                	sd	s2,32(sp)
    80004370:	ec4e                	sd	s3,24(sp)
    80004372:	e852                	sd	s4,16(sp)
    80004374:	e456                	sd	s5,8(sp)
    80004376:	e05a                	sd	s6,0(sp)
    80004378:	0080                	addi	s0,sp,64
    8000437a:	8b2a                	mv	s6,a0
    8000437c:	0001da97          	auipc	s5,0x1d
    80004380:	324a8a93          	addi	s5,s5,804 # 800216a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004384:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004386:	0001d997          	auipc	s3,0x1d
    8000438a:	2ea98993          	addi	s3,s3,746 # 80021670 <log>
    8000438e:	a00d                	j	800043b0 <install_trans+0x56>
    brelse(lbuf);
    80004390:	854a                	mv	a0,s2
    80004392:	fffff097          	auipc	ra,0xfffff
    80004396:	084080e7          	jalr	132(ra) # 80003416 <brelse>
    brelse(dbuf);
    8000439a:	8526                	mv	a0,s1
    8000439c:	fffff097          	auipc	ra,0xfffff
    800043a0:	07a080e7          	jalr	122(ra) # 80003416 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043a4:	2a05                	addiw	s4,s4,1
    800043a6:	0a91                	addi	s5,s5,4
    800043a8:	02c9a783          	lw	a5,44(s3)
    800043ac:	04fa5e63          	bge	s4,a5,80004408 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043b0:	0189a583          	lw	a1,24(s3)
    800043b4:	014585bb          	addw	a1,a1,s4
    800043b8:	2585                	addiw	a1,a1,1
    800043ba:	0289a503          	lw	a0,40(s3)
    800043be:	fffff097          	auipc	ra,0xfffff
    800043c2:	f28080e7          	jalr	-216(ra) # 800032e6 <bread>
    800043c6:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800043c8:	000aa583          	lw	a1,0(s5)
    800043cc:	0289a503          	lw	a0,40(s3)
    800043d0:	fffff097          	auipc	ra,0xfffff
    800043d4:	f16080e7          	jalr	-234(ra) # 800032e6 <bread>
    800043d8:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800043da:	40000613          	li	a2,1024
    800043de:	05890593          	addi	a1,s2,88
    800043e2:	05850513          	addi	a0,a0,88
    800043e6:	ffffd097          	auipc	ra,0xffffd
    800043ea:	942080e7          	jalr	-1726(ra) # 80000d28 <memmove>
    bwrite(dbuf);  // write dst to disk
    800043ee:	8526                	mv	a0,s1
    800043f0:	fffff097          	auipc	ra,0xfffff
    800043f4:	fe8080e7          	jalr	-24(ra) # 800033d8 <bwrite>
    if(recovering == 0)
    800043f8:	f80b1ce3          	bnez	s6,80004390 <install_trans+0x36>
      bunpin(dbuf);
    800043fc:	8526                	mv	a0,s1
    800043fe:	fffff097          	auipc	ra,0xfffff
    80004402:	0f2080e7          	jalr	242(ra) # 800034f0 <bunpin>
    80004406:	b769                	j	80004390 <install_trans+0x36>
}
    80004408:	70e2                	ld	ra,56(sp)
    8000440a:	7442                	ld	s0,48(sp)
    8000440c:	74a2                	ld	s1,40(sp)
    8000440e:	7902                	ld	s2,32(sp)
    80004410:	69e2                	ld	s3,24(sp)
    80004412:	6a42                	ld	s4,16(sp)
    80004414:	6aa2                	ld	s5,8(sp)
    80004416:	6b02                	ld	s6,0(sp)
    80004418:	6121                	addi	sp,sp,64
    8000441a:	8082                	ret
    8000441c:	8082                	ret

000000008000441e <initlog>:
{
    8000441e:	7179                	addi	sp,sp,-48
    80004420:	f406                	sd	ra,40(sp)
    80004422:	f022                	sd	s0,32(sp)
    80004424:	ec26                	sd	s1,24(sp)
    80004426:	e84a                	sd	s2,16(sp)
    80004428:	e44e                	sd	s3,8(sp)
    8000442a:	1800                	addi	s0,sp,48
    8000442c:	892a                	mv	s2,a0
    8000442e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004430:	0001d497          	auipc	s1,0x1d
    80004434:	24048493          	addi	s1,s1,576 # 80021670 <log>
    80004438:	00004597          	auipc	a1,0x4
    8000443c:	29858593          	addi	a1,a1,664 # 800086d0 <syscalls+0x208>
    80004440:	8526                	mv	a0,s1
    80004442:	ffffc097          	auipc	ra,0xffffc
    80004446:	6fe080e7          	jalr	1790(ra) # 80000b40 <initlock>
  log.start = sb->logstart;
    8000444a:	0149a583          	lw	a1,20(s3)
    8000444e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004450:	0109a783          	lw	a5,16(s3)
    80004454:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004456:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000445a:	854a                	mv	a0,s2
    8000445c:	fffff097          	auipc	ra,0xfffff
    80004460:	e8a080e7          	jalr	-374(ra) # 800032e6 <bread>
  log.lh.n = lh->n;
    80004464:	4d34                	lw	a3,88(a0)
    80004466:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004468:	02d05663          	blez	a3,80004494 <initlog+0x76>
    8000446c:	05c50793          	addi	a5,a0,92
    80004470:	0001d717          	auipc	a4,0x1d
    80004474:	23070713          	addi	a4,a4,560 # 800216a0 <log+0x30>
    80004478:	36fd                	addiw	a3,a3,-1
    8000447a:	02069613          	slli	a2,a3,0x20
    8000447e:	01e65693          	srli	a3,a2,0x1e
    80004482:	06050613          	addi	a2,a0,96
    80004486:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004488:	4390                	lw	a2,0(a5)
    8000448a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000448c:	0791                	addi	a5,a5,4
    8000448e:	0711                	addi	a4,a4,4
    80004490:	fed79ce3          	bne	a5,a3,80004488 <initlog+0x6a>
  brelse(buf);
    80004494:	fffff097          	auipc	ra,0xfffff
    80004498:	f82080e7          	jalr	-126(ra) # 80003416 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000449c:	4505                	li	a0,1
    8000449e:	00000097          	auipc	ra,0x0
    800044a2:	ebc080e7          	jalr	-324(ra) # 8000435a <install_trans>
  log.lh.n = 0;
    800044a6:	0001d797          	auipc	a5,0x1d
    800044aa:	1e07ab23          	sw	zero,502(a5) # 8002169c <log+0x2c>
  write_head(); // clear the log
    800044ae:	00000097          	auipc	ra,0x0
    800044b2:	e30080e7          	jalr	-464(ra) # 800042de <write_head>
}
    800044b6:	70a2                	ld	ra,40(sp)
    800044b8:	7402                	ld	s0,32(sp)
    800044ba:	64e2                	ld	s1,24(sp)
    800044bc:	6942                	ld	s2,16(sp)
    800044be:	69a2                	ld	s3,8(sp)
    800044c0:	6145                	addi	sp,sp,48
    800044c2:	8082                	ret

00000000800044c4 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800044c4:	1101                	addi	sp,sp,-32
    800044c6:	ec06                	sd	ra,24(sp)
    800044c8:	e822                	sd	s0,16(sp)
    800044ca:	e426                	sd	s1,8(sp)
    800044cc:	e04a                	sd	s2,0(sp)
    800044ce:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800044d0:	0001d517          	auipc	a0,0x1d
    800044d4:	1a050513          	addi	a0,a0,416 # 80021670 <log>
    800044d8:	ffffc097          	auipc	ra,0xffffc
    800044dc:	6f8080e7          	jalr	1784(ra) # 80000bd0 <acquire>
  while(1){
    if(log.committing){
    800044e0:	0001d497          	auipc	s1,0x1d
    800044e4:	19048493          	addi	s1,s1,400 # 80021670 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800044e8:	4979                	li	s2,30
    800044ea:	a039                	j	800044f8 <begin_op+0x34>
      sleep(&log, &log.lock);
    800044ec:	85a6                	mv	a1,s1
    800044ee:	8526                	mv	a0,s1
    800044f0:	ffffe097          	auipc	ra,0xffffe
    800044f4:	c52080e7          	jalr	-942(ra) # 80002142 <sleep>
    if(log.committing){
    800044f8:	50dc                	lw	a5,36(s1)
    800044fa:	fbed                	bnez	a5,800044ec <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800044fc:	5098                	lw	a4,32(s1)
    800044fe:	2705                	addiw	a4,a4,1
    80004500:	0007069b          	sext.w	a3,a4
    80004504:	0027179b          	slliw	a5,a4,0x2
    80004508:	9fb9                	addw	a5,a5,a4
    8000450a:	0017979b          	slliw	a5,a5,0x1
    8000450e:	54d8                	lw	a4,44(s1)
    80004510:	9fb9                	addw	a5,a5,a4
    80004512:	00f95963          	bge	s2,a5,80004524 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004516:	85a6                	mv	a1,s1
    80004518:	8526                	mv	a0,s1
    8000451a:	ffffe097          	auipc	ra,0xffffe
    8000451e:	c28080e7          	jalr	-984(ra) # 80002142 <sleep>
    80004522:	bfd9                	j	800044f8 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004524:	0001d517          	auipc	a0,0x1d
    80004528:	14c50513          	addi	a0,a0,332 # 80021670 <log>
    8000452c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000452e:	ffffc097          	auipc	ra,0xffffc
    80004532:	756080e7          	jalr	1878(ra) # 80000c84 <release>
      break;
    }
  }
}
    80004536:	60e2                	ld	ra,24(sp)
    80004538:	6442                	ld	s0,16(sp)
    8000453a:	64a2                	ld	s1,8(sp)
    8000453c:	6902                	ld	s2,0(sp)
    8000453e:	6105                	addi	sp,sp,32
    80004540:	8082                	ret

0000000080004542 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004542:	7139                	addi	sp,sp,-64
    80004544:	fc06                	sd	ra,56(sp)
    80004546:	f822                	sd	s0,48(sp)
    80004548:	f426                	sd	s1,40(sp)
    8000454a:	f04a                	sd	s2,32(sp)
    8000454c:	ec4e                	sd	s3,24(sp)
    8000454e:	e852                	sd	s4,16(sp)
    80004550:	e456                	sd	s5,8(sp)
    80004552:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004554:	0001d497          	auipc	s1,0x1d
    80004558:	11c48493          	addi	s1,s1,284 # 80021670 <log>
    8000455c:	8526                	mv	a0,s1
    8000455e:	ffffc097          	auipc	ra,0xffffc
    80004562:	672080e7          	jalr	1650(ra) # 80000bd0 <acquire>
  log.outstanding -= 1;
    80004566:	509c                	lw	a5,32(s1)
    80004568:	37fd                	addiw	a5,a5,-1
    8000456a:	0007891b          	sext.w	s2,a5
    8000456e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004570:	50dc                	lw	a5,36(s1)
    80004572:	e7b9                	bnez	a5,800045c0 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004574:	04091e63          	bnez	s2,800045d0 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004578:	0001d497          	auipc	s1,0x1d
    8000457c:	0f848493          	addi	s1,s1,248 # 80021670 <log>
    80004580:	4785                	li	a5,1
    80004582:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004584:	8526                	mv	a0,s1
    80004586:	ffffc097          	auipc	ra,0xffffc
    8000458a:	6fe080e7          	jalr	1790(ra) # 80000c84 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000458e:	54dc                	lw	a5,44(s1)
    80004590:	06f04763          	bgtz	a5,800045fe <end_op+0xbc>
    acquire(&log.lock);
    80004594:	0001d497          	auipc	s1,0x1d
    80004598:	0dc48493          	addi	s1,s1,220 # 80021670 <log>
    8000459c:	8526                	mv	a0,s1
    8000459e:	ffffc097          	auipc	ra,0xffffc
    800045a2:	632080e7          	jalr	1586(ra) # 80000bd0 <acquire>
    log.committing = 0;
    800045a6:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800045aa:	8526                	mv	a0,s1
    800045ac:	ffffe097          	auipc	ra,0xffffe
    800045b0:	d22080e7          	jalr	-734(ra) # 800022ce <wakeup>
    release(&log.lock);
    800045b4:	8526                	mv	a0,s1
    800045b6:	ffffc097          	auipc	ra,0xffffc
    800045ba:	6ce080e7          	jalr	1742(ra) # 80000c84 <release>
}
    800045be:	a03d                	j	800045ec <end_op+0xaa>
    panic("log.committing");
    800045c0:	00004517          	auipc	a0,0x4
    800045c4:	11850513          	addi	a0,a0,280 # 800086d8 <syscalls+0x210>
    800045c8:	ffffc097          	auipc	ra,0xffffc
    800045cc:	f72080e7          	jalr	-142(ra) # 8000053a <panic>
    wakeup(&log);
    800045d0:	0001d497          	auipc	s1,0x1d
    800045d4:	0a048493          	addi	s1,s1,160 # 80021670 <log>
    800045d8:	8526                	mv	a0,s1
    800045da:	ffffe097          	auipc	ra,0xffffe
    800045de:	cf4080e7          	jalr	-780(ra) # 800022ce <wakeup>
  release(&log.lock);
    800045e2:	8526                	mv	a0,s1
    800045e4:	ffffc097          	auipc	ra,0xffffc
    800045e8:	6a0080e7          	jalr	1696(ra) # 80000c84 <release>
}
    800045ec:	70e2                	ld	ra,56(sp)
    800045ee:	7442                	ld	s0,48(sp)
    800045f0:	74a2                	ld	s1,40(sp)
    800045f2:	7902                	ld	s2,32(sp)
    800045f4:	69e2                	ld	s3,24(sp)
    800045f6:	6a42                	ld	s4,16(sp)
    800045f8:	6aa2                	ld	s5,8(sp)
    800045fa:	6121                	addi	sp,sp,64
    800045fc:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800045fe:	0001da97          	auipc	s5,0x1d
    80004602:	0a2a8a93          	addi	s5,s5,162 # 800216a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004606:	0001da17          	auipc	s4,0x1d
    8000460a:	06aa0a13          	addi	s4,s4,106 # 80021670 <log>
    8000460e:	018a2583          	lw	a1,24(s4)
    80004612:	012585bb          	addw	a1,a1,s2
    80004616:	2585                	addiw	a1,a1,1
    80004618:	028a2503          	lw	a0,40(s4)
    8000461c:	fffff097          	auipc	ra,0xfffff
    80004620:	cca080e7          	jalr	-822(ra) # 800032e6 <bread>
    80004624:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004626:	000aa583          	lw	a1,0(s5)
    8000462a:	028a2503          	lw	a0,40(s4)
    8000462e:	fffff097          	auipc	ra,0xfffff
    80004632:	cb8080e7          	jalr	-840(ra) # 800032e6 <bread>
    80004636:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004638:	40000613          	li	a2,1024
    8000463c:	05850593          	addi	a1,a0,88
    80004640:	05848513          	addi	a0,s1,88
    80004644:	ffffc097          	auipc	ra,0xffffc
    80004648:	6e4080e7          	jalr	1764(ra) # 80000d28 <memmove>
    bwrite(to);  // write the log
    8000464c:	8526                	mv	a0,s1
    8000464e:	fffff097          	auipc	ra,0xfffff
    80004652:	d8a080e7          	jalr	-630(ra) # 800033d8 <bwrite>
    brelse(from);
    80004656:	854e                	mv	a0,s3
    80004658:	fffff097          	auipc	ra,0xfffff
    8000465c:	dbe080e7          	jalr	-578(ra) # 80003416 <brelse>
    brelse(to);
    80004660:	8526                	mv	a0,s1
    80004662:	fffff097          	auipc	ra,0xfffff
    80004666:	db4080e7          	jalr	-588(ra) # 80003416 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000466a:	2905                	addiw	s2,s2,1
    8000466c:	0a91                	addi	s5,s5,4
    8000466e:	02ca2783          	lw	a5,44(s4)
    80004672:	f8f94ee3          	blt	s2,a5,8000460e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004676:	00000097          	auipc	ra,0x0
    8000467a:	c68080e7          	jalr	-920(ra) # 800042de <write_head>
    install_trans(0); // Now install writes to home locations
    8000467e:	4501                	li	a0,0
    80004680:	00000097          	auipc	ra,0x0
    80004684:	cda080e7          	jalr	-806(ra) # 8000435a <install_trans>
    log.lh.n = 0;
    80004688:	0001d797          	auipc	a5,0x1d
    8000468c:	0007aa23          	sw	zero,20(a5) # 8002169c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004690:	00000097          	auipc	ra,0x0
    80004694:	c4e080e7          	jalr	-946(ra) # 800042de <write_head>
    80004698:	bdf5                	j	80004594 <end_op+0x52>

000000008000469a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000469a:	1101                	addi	sp,sp,-32
    8000469c:	ec06                	sd	ra,24(sp)
    8000469e:	e822                	sd	s0,16(sp)
    800046a0:	e426                	sd	s1,8(sp)
    800046a2:	e04a                	sd	s2,0(sp)
    800046a4:	1000                	addi	s0,sp,32
    800046a6:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800046a8:	0001d917          	auipc	s2,0x1d
    800046ac:	fc890913          	addi	s2,s2,-56 # 80021670 <log>
    800046b0:	854a                	mv	a0,s2
    800046b2:	ffffc097          	auipc	ra,0xffffc
    800046b6:	51e080e7          	jalr	1310(ra) # 80000bd0 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800046ba:	02c92603          	lw	a2,44(s2)
    800046be:	47f5                	li	a5,29
    800046c0:	06c7c563          	blt	a5,a2,8000472a <log_write+0x90>
    800046c4:	0001d797          	auipc	a5,0x1d
    800046c8:	fc87a783          	lw	a5,-56(a5) # 8002168c <log+0x1c>
    800046cc:	37fd                	addiw	a5,a5,-1
    800046ce:	04f65e63          	bge	a2,a5,8000472a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800046d2:	0001d797          	auipc	a5,0x1d
    800046d6:	fbe7a783          	lw	a5,-66(a5) # 80021690 <log+0x20>
    800046da:	06f05063          	blez	a5,8000473a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800046de:	4781                	li	a5,0
    800046e0:	06c05563          	blez	a2,8000474a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800046e4:	44cc                	lw	a1,12(s1)
    800046e6:	0001d717          	auipc	a4,0x1d
    800046ea:	fba70713          	addi	a4,a4,-70 # 800216a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800046ee:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800046f0:	4314                	lw	a3,0(a4)
    800046f2:	04b68c63          	beq	a3,a1,8000474a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800046f6:	2785                	addiw	a5,a5,1
    800046f8:	0711                	addi	a4,a4,4
    800046fa:	fef61be3          	bne	a2,a5,800046f0 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800046fe:	0621                	addi	a2,a2,8
    80004700:	060a                	slli	a2,a2,0x2
    80004702:	0001d797          	auipc	a5,0x1d
    80004706:	f6e78793          	addi	a5,a5,-146 # 80021670 <log>
    8000470a:	97b2                	add	a5,a5,a2
    8000470c:	44d8                	lw	a4,12(s1)
    8000470e:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004710:	8526                	mv	a0,s1
    80004712:	fffff097          	auipc	ra,0xfffff
    80004716:	da2080e7          	jalr	-606(ra) # 800034b4 <bpin>
    log.lh.n++;
    8000471a:	0001d717          	auipc	a4,0x1d
    8000471e:	f5670713          	addi	a4,a4,-170 # 80021670 <log>
    80004722:	575c                	lw	a5,44(a4)
    80004724:	2785                	addiw	a5,a5,1
    80004726:	d75c                	sw	a5,44(a4)
    80004728:	a82d                	j	80004762 <log_write+0xc8>
    panic("too big a transaction");
    8000472a:	00004517          	auipc	a0,0x4
    8000472e:	fbe50513          	addi	a0,a0,-66 # 800086e8 <syscalls+0x220>
    80004732:	ffffc097          	auipc	ra,0xffffc
    80004736:	e08080e7          	jalr	-504(ra) # 8000053a <panic>
    panic("log_write outside of trans");
    8000473a:	00004517          	auipc	a0,0x4
    8000473e:	fc650513          	addi	a0,a0,-58 # 80008700 <syscalls+0x238>
    80004742:	ffffc097          	auipc	ra,0xffffc
    80004746:	df8080e7          	jalr	-520(ra) # 8000053a <panic>
  log.lh.block[i] = b->blockno;
    8000474a:	00878693          	addi	a3,a5,8
    8000474e:	068a                	slli	a3,a3,0x2
    80004750:	0001d717          	auipc	a4,0x1d
    80004754:	f2070713          	addi	a4,a4,-224 # 80021670 <log>
    80004758:	9736                	add	a4,a4,a3
    8000475a:	44d4                	lw	a3,12(s1)
    8000475c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000475e:	faf609e3          	beq	a2,a5,80004710 <log_write+0x76>
  }
  release(&log.lock);
    80004762:	0001d517          	auipc	a0,0x1d
    80004766:	f0e50513          	addi	a0,a0,-242 # 80021670 <log>
    8000476a:	ffffc097          	auipc	ra,0xffffc
    8000476e:	51a080e7          	jalr	1306(ra) # 80000c84 <release>
}
    80004772:	60e2                	ld	ra,24(sp)
    80004774:	6442                	ld	s0,16(sp)
    80004776:	64a2                	ld	s1,8(sp)
    80004778:	6902                	ld	s2,0(sp)
    8000477a:	6105                	addi	sp,sp,32
    8000477c:	8082                	ret

000000008000477e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000477e:	1101                	addi	sp,sp,-32
    80004780:	ec06                	sd	ra,24(sp)
    80004782:	e822                	sd	s0,16(sp)
    80004784:	e426                	sd	s1,8(sp)
    80004786:	e04a                	sd	s2,0(sp)
    80004788:	1000                	addi	s0,sp,32
    8000478a:	84aa                	mv	s1,a0
    8000478c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000478e:	00004597          	auipc	a1,0x4
    80004792:	f9258593          	addi	a1,a1,-110 # 80008720 <syscalls+0x258>
    80004796:	0521                	addi	a0,a0,8
    80004798:	ffffc097          	auipc	ra,0xffffc
    8000479c:	3a8080e7          	jalr	936(ra) # 80000b40 <initlock>
  lk->name = name;
    800047a0:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800047a4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800047a8:	0204a423          	sw	zero,40(s1)
}
    800047ac:	60e2                	ld	ra,24(sp)
    800047ae:	6442                	ld	s0,16(sp)
    800047b0:	64a2                	ld	s1,8(sp)
    800047b2:	6902                	ld	s2,0(sp)
    800047b4:	6105                	addi	sp,sp,32
    800047b6:	8082                	ret

00000000800047b8 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800047b8:	1101                	addi	sp,sp,-32
    800047ba:	ec06                	sd	ra,24(sp)
    800047bc:	e822                	sd	s0,16(sp)
    800047be:	e426                	sd	s1,8(sp)
    800047c0:	e04a                	sd	s2,0(sp)
    800047c2:	1000                	addi	s0,sp,32
    800047c4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800047c6:	00850913          	addi	s2,a0,8
    800047ca:	854a                	mv	a0,s2
    800047cc:	ffffc097          	auipc	ra,0xffffc
    800047d0:	404080e7          	jalr	1028(ra) # 80000bd0 <acquire>
  while (lk->locked) {
    800047d4:	409c                	lw	a5,0(s1)
    800047d6:	cb89                	beqz	a5,800047e8 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800047d8:	85ca                	mv	a1,s2
    800047da:	8526                	mv	a0,s1
    800047dc:	ffffe097          	auipc	ra,0xffffe
    800047e0:	966080e7          	jalr	-1690(ra) # 80002142 <sleep>
  while (lk->locked) {
    800047e4:	409c                	lw	a5,0(s1)
    800047e6:	fbed                	bnez	a5,800047d8 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800047e8:	4785                	li	a5,1
    800047ea:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800047ec:	ffffd097          	auipc	ra,0xffffd
    800047f0:	1aa080e7          	jalr	426(ra) # 80001996 <myproc>
    800047f4:	591c                	lw	a5,48(a0)
    800047f6:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800047f8:	854a                	mv	a0,s2
    800047fa:	ffffc097          	auipc	ra,0xffffc
    800047fe:	48a080e7          	jalr	1162(ra) # 80000c84 <release>
}
    80004802:	60e2                	ld	ra,24(sp)
    80004804:	6442                	ld	s0,16(sp)
    80004806:	64a2                	ld	s1,8(sp)
    80004808:	6902                	ld	s2,0(sp)
    8000480a:	6105                	addi	sp,sp,32
    8000480c:	8082                	ret

000000008000480e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000480e:	1101                	addi	sp,sp,-32
    80004810:	ec06                	sd	ra,24(sp)
    80004812:	e822                	sd	s0,16(sp)
    80004814:	e426                	sd	s1,8(sp)
    80004816:	e04a                	sd	s2,0(sp)
    80004818:	1000                	addi	s0,sp,32
    8000481a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000481c:	00850913          	addi	s2,a0,8
    80004820:	854a                	mv	a0,s2
    80004822:	ffffc097          	auipc	ra,0xffffc
    80004826:	3ae080e7          	jalr	942(ra) # 80000bd0 <acquire>
  lk->locked = 0;
    8000482a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000482e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004832:	8526                	mv	a0,s1
    80004834:	ffffe097          	auipc	ra,0xffffe
    80004838:	a9a080e7          	jalr	-1382(ra) # 800022ce <wakeup>
  release(&lk->lk);
    8000483c:	854a                	mv	a0,s2
    8000483e:	ffffc097          	auipc	ra,0xffffc
    80004842:	446080e7          	jalr	1094(ra) # 80000c84 <release>
}
    80004846:	60e2                	ld	ra,24(sp)
    80004848:	6442                	ld	s0,16(sp)
    8000484a:	64a2                	ld	s1,8(sp)
    8000484c:	6902                	ld	s2,0(sp)
    8000484e:	6105                	addi	sp,sp,32
    80004850:	8082                	ret

0000000080004852 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004852:	7179                	addi	sp,sp,-48
    80004854:	f406                	sd	ra,40(sp)
    80004856:	f022                	sd	s0,32(sp)
    80004858:	ec26                	sd	s1,24(sp)
    8000485a:	e84a                	sd	s2,16(sp)
    8000485c:	e44e                	sd	s3,8(sp)
    8000485e:	1800                	addi	s0,sp,48
    80004860:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004862:	00850913          	addi	s2,a0,8
    80004866:	854a                	mv	a0,s2
    80004868:	ffffc097          	auipc	ra,0xffffc
    8000486c:	368080e7          	jalr	872(ra) # 80000bd0 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004870:	409c                	lw	a5,0(s1)
    80004872:	ef99                	bnez	a5,80004890 <holdingsleep+0x3e>
    80004874:	4481                	li	s1,0
  release(&lk->lk);
    80004876:	854a                	mv	a0,s2
    80004878:	ffffc097          	auipc	ra,0xffffc
    8000487c:	40c080e7          	jalr	1036(ra) # 80000c84 <release>
  return r;
}
    80004880:	8526                	mv	a0,s1
    80004882:	70a2                	ld	ra,40(sp)
    80004884:	7402                	ld	s0,32(sp)
    80004886:	64e2                	ld	s1,24(sp)
    80004888:	6942                	ld	s2,16(sp)
    8000488a:	69a2                	ld	s3,8(sp)
    8000488c:	6145                	addi	sp,sp,48
    8000488e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004890:	0284a983          	lw	s3,40(s1)
    80004894:	ffffd097          	auipc	ra,0xffffd
    80004898:	102080e7          	jalr	258(ra) # 80001996 <myproc>
    8000489c:	5904                	lw	s1,48(a0)
    8000489e:	413484b3          	sub	s1,s1,s3
    800048a2:	0014b493          	seqz	s1,s1
    800048a6:	bfc1                	j	80004876 <holdingsleep+0x24>

00000000800048a8 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800048a8:	1141                	addi	sp,sp,-16
    800048aa:	e406                	sd	ra,8(sp)
    800048ac:	e022                	sd	s0,0(sp)
    800048ae:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800048b0:	00004597          	auipc	a1,0x4
    800048b4:	e8058593          	addi	a1,a1,-384 # 80008730 <syscalls+0x268>
    800048b8:	0001d517          	auipc	a0,0x1d
    800048bc:	f0050513          	addi	a0,a0,-256 # 800217b8 <ftable>
    800048c0:	ffffc097          	auipc	ra,0xffffc
    800048c4:	280080e7          	jalr	640(ra) # 80000b40 <initlock>
}
    800048c8:	60a2                	ld	ra,8(sp)
    800048ca:	6402                	ld	s0,0(sp)
    800048cc:	0141                	addi	sp,sp,16
    800048ce:	8082                	ret

00000000800048d0 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800048d0:	1101                	addi	sp,sp,-32
    800048d2:	ec06                	sd	ra,24(sp)
    800048d4:	e822                	sd	s0,16(sp)
    800048d6:	e426                	sd	s1,8(sp)
    800048d8:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800048da:	0001d517          	auipc	a0,0x1d
    800048de:	ede50513          	addi	a0,a0,-290 # 800217b8 <ftable>
    800048e2:	ffffc097          	auipc	ra,0xffffc
    800048e6:	2ee080e7          	jalr	750(ra) # 80000bd0 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800048ea:	0001d497          	auipc	s1,0x1d
    800048ee:	ee648493          	addi	s1,s1,-282 # 800217d0 <ftable+0x18>
    800048f2:	0001e717          	auipc	a4,0x1e
    800048f6:	e7e70713          	addi	a4,a4,-386 # 80022770 <ftable+0xfb8>
    if(f->ref == 0){
    800048fa:	40dc                	lw	a5,4(s1)
    800048fc:	cf99                	beqz	a5,8000491a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800048fe:	02848493          	addi	s1,s1,40
    80004902:	fee49ce3          	bne	s1,a4,800048fa <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004906:	0001d517          	auipc	a0,0x1d
    8000490a:	eb250513          	addi	a0,a0,-334 # 800217b8 <ftable>
    8000490e:	ffffc097          	auipc	ra,0xffffc
    80004912:	376080e7          	jalr	886(ra) # 80000c84 <release>
  return 0;
    80004916:	4481                	li	s1,0
    80004918:	a819                	j	8000492e <filealloc+0x5e>
      f->ref = 1;
    8000491a:	4785                	li	a5,1
    8000491c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000491e:	0001d517          	auipc	a0,0x1d
    80004922:	e9a50513          	addi	a0,a0,-358 # 800217b8 <ftable>
    80004926:	ffffc097          	auipc	ra,0xffffc
    8000492a:	35e080e7          	jalr	862(ra) # 80000c84 <release>
}
    8000492e:	8526                	mv	a0,s1
    80004930:	60e2                	ld	ra,24(sp)
    80004932:	6442                	ld	s0,16(sp)
    80004934:	64a2                	ld	s1,8(sp)
    80004936:	6105                	addi	sp,sp,32
    80004938:	8082                	ret

000000008000493a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000493a:	1101                	addi	sp,sp,-32
    8000493c:	ec06                	sd	ra,24(sp)
    8000493e:	e822                	sd	s0,16(sp)
    80004940:	e426                	sd	s1,8(sp)
    80004942:	1000                	addi	s0,sp,32
    80004944:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004946:	0001d517          	auipc	a0,0x1d
    8000494a:	e7250513          	addi	a0,a0,-398 # 800217b8 <ftable>
    8000494e:	ffffc097          	auipc	ra,0xffffc
    80004952:	282080e7          	jalr	642(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    80004956:	40dc                	lw	a5,4(s1)
    80004958:	02f05263          	blez	a5,8000497c <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000495c:	2785                	addiw	a5,a5,1
    8000495e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004960:	0001d517          	auipc	a0,0x1d
    80004964:	e5850513          	addi	a0,a0,-424 # 800217b8 <ftable>
    80004968:	ffffc097          	auipc	ra,0xffffc
    8000496c:	31c080e7          	jalr	796(ra) # 80000c84 <release>
  return f;
}
    80004970:	8526                	mv	a0,s1
    80004972:	60e2                	ld	ra,24(sp)
    80004974:	6442                	ld	s0,16(sp)
    80004976:	64a2                	ld	s1,8(sp)
    80004978:	6105                	addi	sp,sp,32
    8000497a:	8082                	ret
    panic("filedup");
    8000497c:	00004517          	auipc	a0,0x4
    80004980:	dbc50513          	addi	a0,a0,-580 # 80008738 <syscalls+0x270>
    80004984:	ffffc097          	auipc	ra,0xffffc
    80004988:	bb6080e7          	jalr	-1098(ra) # 8000053a <panic>

000000008000498c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000498c:	7139                	addi	sp,sp,-64
    8000498e:	fc06                	sd	ra,56(sp)
    80004990:	f822                	sd	s0,48(sp)
    80004992:	f426                	sd	s1,40(sp)
    80004994:	f04a                	sd	s2,32(sp)
    80004996:	ec4e                	sd	s3,24(sp)
    80004998:	e852                	sd	s4,16(sp)
    8000499a:	e456                	sd	s5,8(sp)
    8000499c:	0080                	addi	s0,sp,64
    8000499e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800049a0:	0001d517          	auipc	a0,0x1d
    800049a4:	e1850513          	addi	a0,a0,-488 # 800217b8 <ftable>
    800049a8:	ffffc097          	auipc	ra,0xffffc
    800049ac:	228080e7          	jalr	552(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    800049b0:	40dc                	lw	a5,4(s1)
    800049b2:	06f05163          	blez	a5,80004a14 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800049b6:	37fd                	addiw	a5,a5,-1
    800049b8:	0007871b          	sext.w	a4,a5
    800049bc:	c0dc                	sw	a5,4(s1)
    800049be:	06e04363          	bgtz	a4,80004a24 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800049c2:	0004a903          	lw	s2,0(s1)
    800049c6:	0094ca83          	lbu	s5,9(s1)
    800049ca:	0104ba03          	ld	s4,16(s1)
    800049ce:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800049d2:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800049d6:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800049da:	0001d517          	auipc	a0,0x1d
    800049de:	dde50513          	addi	a0,a0,-546 # 800217b8 <ftable>
    800049e2:	ffffc097          	auipc	ra,0xffffc
    800049e6:	2a2080e7          	jalr	674(ra) # 80000c84 <release>

  if(ff.type == FD_PIPE){
    800049ea:	4785                	li	a5,1
    800049ec:	04f90d63          	beq	s2,a5,80004a46 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800049f0:	3979                	addiw	s2,s2,-2
    800049f2:	4785                	li	a5,1
    800049f4:	0527e063          	bltu	a5,s2,80004a34 <fileclose+0xa8>
    begin_op();
    800049f8:	00000097          	auipc	ra,0x0
    800049fc:	acc080e7          	jalr	-1332(ra) # 800044c4 <begin_op>
    iput(ff.ip);
    80004a00:	854e                	mv	a0,s3
    80004a02:	fffff097          	auipc	ra,0xfffff
    80004a06:	2a0080e7          	jalr	672(ra) # 80003ca2 <iput>
    end_op();
    80004a0a:	00000097          	auipc	ra,0x0
    80004a0e:	b38080e7          	jalr	-1224(ra) # 80004542 <end_op>
    80004a12:	a00d                	j	80004a34 <fileclose+0xa8>
    panic("fileclose");
    80004a14:	00004517          	auipc	a0,0x4
    80004a18:	d2c50513          	addi	a0,a0,-724 # 80008740 <syscalls+0x278>
    80004a1c:	ffffc097          	auipc	ra,0xffffc
    80004a20:	b1e080e7          	jalr	-1250(ra) # 8000053a <panic>
    release(&ftable.lock);
    80004a24:	0001d517          	auipc	a0,0x1d
    80004a28:	d9450513          	addi	a0,a0,-620 # 800217b8 <ftable>
    80004a2c:	ffffc097          	auipc	ra,0xffffc
    80004a30:	258080e7          	jalr	600(ra) # 80000c84 <release>
  }
}
    80004a34:	70e2                	ld	ra,56(sp)
    80004a36:	7442                	ld	s0,48(sp)
    80004a38:	74a2                	ld	s1,40(sp)
    80004a3a:	7902                	ld	s2,32(sp)
    80004a3c:	69e2                	ld	s3,24(sp)
    80004a3e:	6a42                	ld	s4,16(sp)
    80004a40:	6aa2                	ld	s5,8(sp)
    80004a42:	6121                	addi	sp,sp,64
    80004a44:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004a46:	85d6                	mv	a1,s5
    80004a48:	8552                	mv	a0,s4
    80004a4a:	00000097          	auipc	ra,0x0
    80004a4e:	34c080e7          	jalr	844(ra) # 80004d96 <pipeclose>
    80004a52:	b7cd                	j	80004a34 <fileclose+0xa8>

0000000080004a54 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004a54:	715d                	addi	sp,sp,-80
    80004a56:	e486                	sd	ra,72(sp)
    80004a58:	e0a2                	sd	s0,64(sp)
    80004a5a:	fc26                	sd	s1,56(sp)
    80004a5c:	f84a                	sd	s2,48(sp)
    80004a5e:	f44e                	sd	s3,40(sp)
    80004a60:	0880                	addi	s0,sp,80
    80004a62:	84aa                	mv	s1,a0
    80004a64:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004a66:	ffffd097          	auipc	ra,0xffffd
    80004a6a:	f30080e7          	jalr	-208(ra) # 80001996 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004a6e:	409c                	lw	a5,0(s1)
    80004a70:	37f9                	addiw	a5,a5,-2
    80004a72:	4705                	li	a4,1
    80004a74:	04f76763          	bltu	a4,a5,80004ac2 <filestat+0x6e>
    80004a78:	892a                	mv	s2,a0
    ilock(f->ip);
    80004a7a:	6c88                	ld	a0,24(s1)
    80004a7c:	fffff097          	auipc	ra,0xfffff
    80004a80:	06c080e7          	jalr	108(ra) # 80003ae8 <ilock>
    stati(f->ip, &st);
    80004a84:	fb840593          	addi	a1,s0,-72
    80004a88:	6c88                	ld	a0,24(s1)
    80004a8a:	fffff097          	auipc	ra,0xfffff
    80004a8e:	2e8080e7          	jalr	744(ra) # 80003d72 <stati>
    iunlock(f->ip);
    80004a92:	6c88                	ld	a0,24(s1)
    80004a94:	fffff097          	auipc	ra,0xfffff
    80004a98:	116080e7          	jalr	278(ra) # 80003baa <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004a9c:	46e1                	li	a3,24
    80004a9e:	fb840613          	addi	a2,s0,-72
    80004aa2:	85ce                	mv	a1,s3
    80004aa4:	06093503          	ld	a0,96(s2)
    80004aa8:	ffffd097          	auipc	ra,0xffffd
    80004aac:	bb2080e7          	jalr	-1102(ra) # 8000165a <copyout>
    80004ab0:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004ab4:	60a6                	ld	ra,72(sp)
    80004ab6:	6406                	ld	s0,64(sp)
    80004ab8:	74e2                	ld	s1,56(sp)
    80004aba:	7942                	ld	s2,48(sp)
    80004abc:	79a2                	ld	s3,40(sp)
    80004abe:	6161                	addi	sp,sp,80
    80004ac0:	8082                	ret
  return -1;
    80004ac2:	557d                	li	a0,-1
    80004ac4:	bfc5                	j	80004ab4 <filestat+0x60>

0000000080004ac6 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004ac6:	7179                	addi	sp,sp,-48
    80004ac8:	f406                	sd	ra,40(sp)
    80004aca:	f022                	sd	s0,32(sp)
    80004acc:	ec26                	sd	s1,24(sp)
    80004ace:	e84a                	sd	s2,16(sp)
    80004ad0:	e44e                	sd	s3,8(sp)
    80004ad2:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004ad4:	00854783          	lbu	a5,8(a0)
    80004ad8:	c3d5                	beqz	a5,80004b7c <fileread+0xb6>
    80004ada:	84aa                	mv	s1,a0
    80004adc:	89ae                	mv	s3,a1
    80004ade:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ae0:	411c                	lw	a5,0(a0)
    80004ae2:	4705                	li	a4,1
    80004ae4:	04e78963          	beq	a5,a4,80004b36 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ae8:	470d                	li	a4,3
    80004aea:	04e78d63          	beq	a5,a4,80004b44 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004aee:	4709                	li	a4,2
    80004af0:	06e79e63          	bne	a5,a4,80004b6c <fileread+0xa6>
    ilock(f->ip);
    80004af4:	6d08                	ld	a0,24(a0)
    80004af6:	fffff097          	auipc	ra,0xfffff
    80004afa:	ff2080e7          	jalr	-14(ra) # 80003ae8 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004afe:	874a                	mv	a4,s2
    80004b00:	5094                	lw	a3,32(s1)
    80004b02:	864e                	mv	a2,s3
    80004b04:	4585                	li	a1,1
    80004b06:	6c88                	ld	a0,24(s1)
    80004b08:	fffff097          	auipc	ra,0xfffff
    80004b0c:	294080e7          	jalr	660(ra) # 80003d9c <readi>
    80004b10:	892a                	mv	s2,a0
    80004b12:	00a05563          	blez	a0,80004b1c <fileread+0x56>
      f->off += r;
    80004b16:	509c                	lw	a5,32(s1)
    80004b18:	9fa9                	addw	a5,a5,a0
    80004b1a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004b1c:	6c88                	ld	a0,24(s1)
    80004b1e:	fffff097          	auipc	ra,0xfffff
    80004b22:	08c080e7          	jalr	140(ra) # 80003baa <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004b26:	854a                	mv	a0,s2
    80004b28:	70a2                	ld	ra,40(sp)
    80004b2a:	7402                	ld	s0,32(sp)
    80004b2c:	64e2                	ld	s1,24(sp)
    80004b2e:	6942                	ld	s2,16(sp)
    80004b30:	69a2                	ld	s3,8(sp)
    80004b32:	6145                	addi	sp,sp,48
    80004b34:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004b36:	6908                	ld	a0,16(a0)
    80004b38:	00000097          	auipc	ra,0x0
    80004b3c:	3c0080e7          	jalr	960(ra) # 80004ef8 <piperead>
    80004b40:	892a                	mv	s2,a0
    80004b42:	b7d5                	j	80004b26 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004b44:	02451783          	lh	a5,36(a0)
    80004b48:	03079693          	slli	a3,a5,0x30
    80004b4c:	92c1                	srli	a3,a3,0x30
    80004b4e:	4725                	li	a4,9
    80004b50:	02d76863          	bltu	a4,a3,80004b80 <fileread+0xba>
    80004b54:	0792                	slli	a5,a5,0x4
    80004b56:	0001d717          	auipc	a4,0x1d
    80004b5a:	bc270713          	addi	a4,a4,-1086 # 80021718 <devsw>
    80004b5e:	97ba                	add	a5,a5,a4
    80004b60:	639c                	ld	a5,0(a5)
    80004b62:	c38d                	beqz	a5,80004b84 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004b64:	4505                	li	a0,1
    80004b66:	9782                	jalr	a5
    80004b68:	892a                	mv	s2,a0
    80004b6a:	bf75                	j	80004b26 <fileread+0x60>
    panic("fileread");
    80004b6c:	00004517          	auipc	a0,0x4
    80004b70:	be450513          	addi	a0,a0,-1052 # 80008750 <syscalls+0x288>
    80004b74:	ffffc097          	auipc	ra,0xffffc
    80004b78:	9c6080e7          	jalr	-1594(ra) # 8000053a <panic>
    return -1;
    80004b7c:	597d                	li	s2,-1
    80004b7e:	b765                	j	80004b26 <fileread+0x60>
      return -1;
    80004b80:	597d                	li	s2,-1
    80004b82:	b755                	j	80004b26 <fileread+0x60>
    80004b84:	597d                	li	s2,-1
    80004b86:	b745                	j	80004b26 <fileread+0x60>

0000000080004b88 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004b88:	715d                	addi	sp,sp,-80
    80004b8a:	e486                	sd	ra,72(sp)
    80004b8c:	e0a2                	sd	s0,64(sp)
    80004b8e:	fc26                	sd	s1,56(sp)
    80004b90:	f84a                	sd	s2,48(sp)
    80004b92:	f44e                	sd	s3,40(sp)
    80004b94:	f052                	sd	s4,32(sp)
    80004b96:	ec56                	sd	s5,24(sp)
    80004b98:	e85a                	sd	s6,16(sp)
    80004b9a:	e45e                	sd	s7,8(sp)
    80004b9c:	e062                	sd	s8,0(sp)
    80004b9e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004ba0:	00954783          	lbu	a5,9(a0)
    80004ba4:	10078663          	beqz	a5,80004cb0 <filewrite+0x128>
    80004ba8:	892a                	mv	s2,a0
    80004baa:	8b2e                	mv	s6,a1
    80004bac:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004bae:	411c                	lw	a5,0(a0)
    80004bb0:	4705                	li	a4,1
    80004bb2:	02e78263          	beq	a5,a4,80004bd6 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004bb6:	470d                	li	a4,3
    80004bb8:	02e78663          	beq	a5,a4,80004be4 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004bbc:	4709                	li	a4,2
    80004bbe:	0ee79163          	bne	a5,a4,80004ca0 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004bc2:	0ac05d63          	blez	a2,80004c7c <filewrite+0xf4>
    int i = 0;
    80004bc6:	4981                	li	s3,0
    80004bc8:	6b85                	lui	s7,0x1
    80004bca:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004bce:	6c05                	lui	s8,0x1
    80004bd0:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004bd4:	a861                	j	80004c6c <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004bd6:	6908                	ld	a0,16(a0)
    80004bd8:	00000097          	auipc	ra,0x0
    80004bdc:	22e080e7          	jalr	558(ra) # 80004e06 <pipewrite>
    80004be0:	8a2a                	mv	s4,a0
    80004be2:	a045                	j	80004c82 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004be4:	02451783          	lh	a5,36(a0)
    80004be8:	03079693          	slli	a3,a5,0x30
    80004bec:	92c1                	srli	a3,a3,0x30
    80004bee:	4725                	li	a4,9
    80004bf0:	0cd76263          	bltu	a4,a3,80004cb4 <filewrite+0x12c>
    80004bf4:	0792                	slli	a5,a5,0x4
    80004bf6:	0001d717          	auipc	a4,0x1d
    80004bfa:	b2270713          	addi	a4,a4,-1246 # 80021718 <devsw>
    80004bfe:	97ba                	add	a5,a5,a4
    80004c00:	679c                	ld	a5,8(a5)
    80004c02:	cbdd                	beqz	a5,80004cb8 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004c04:	4505                	li	a0,1
    80004c06:	9782                	jalr	a5
    80004c08:	8a2a                	mv	s4,a0
    80004c0a:	a8a5                	j	80004c82 <filewrite+0xfa>
    80004c0c:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004c10:	00000097          	auipc	ra,0x0
    80004c14:	8b4080e7          	jalr	-1868(ra) # 800044c4 <begin_op>
      ilock(f->ip);
    80004c18:	01893503          	ld	a0,24(s2)
    80004c1c:	fffff097          	auipc	ra,0xfffff
    80004c20:	ecc080e7          	jalr	-308(ra) # 80003ae8 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004c24:	8756                	mv	a4,s5
    80004c26:	02092683          	lw	a3,32(s2)
    80004c2a:	01698633          	add	a2,s3,s6
    80004c2e:	4585                	li	a1,1
    80004c30:	01893503          	ld	a0,24(s2)
    80004c34:	fffff097          	auipc	ra,0xfffff
    80004c38:	260080e7          	jalr	608(ra) # 80003e94 <writei>
    80004c3c:	84aa                	mv	s1,a0
    80004c3e:	00a05763          	blez	a0,80004c4c <filewrite+0xc4>
        f->off += r;
    80004c42:	02092783          	lw	a5,32(s2)
    80004c46:	9fa9                	addw	a5,a5,a0
    80004c48:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004c4c:	01893503          	ld	a0,24(s2)
    80004c50:	fffff097          	auipc	ra,0xfffff
    80004c54:	f5a080e7          	jalr	-166(ra) # 80003baa <iunlock>
      end_op();
    80004c58:	00000097          	auipc	ra,0x0
    80004c5c:	8ea080e7          	jalr	-1814(ra) # 80004542 <end_op>

      if(r != n1){
    80004c60:	009a9f63          	bne	s5,s1,80004c7e <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004c64:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004c68:	0149db63          	bge	s3,s4,80004c7e <filewrite+0xf6>
      int n1 = n - i;
    80004c6c:	413a04bb          	subw	s1,s4,s3
    80004c70:	0004879b          	sext.w	a5,s1
    80004c74:	f8fbdce3          	bge	s7,a5,80004c0c <filewrite+0x84>
    80004c78:	84e2                	mv	s1,s8
    80004c7a:	bf49                	j	80004c0c <filewrite+0x84>
    int i = 0;
    80004c7c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004c7e:	013a1f63          	bne	s4,s3,80004c9c <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004c82:	8552                	mv	a0,s4
    80004c84:	60a6                	ld	ra,72(sp)
    80004c86:	6406                	ld	s0,64(sp)
    80004c88:	74e2                	ld	s1,56(sp)
    80004c8a:	7942                	ld	s2,48(sp)
    80004c8c:	79a2                	ld	s3,40(sp)
    80004c8e:	7a02                	ld	s4,32(sp)
    80004c90:	6ae2                	ld	s5,24(sp)
    80004c92:	6b42                	ld	s6,16(sp)
    80004c94:	6ba2                	ld	s7,8(sp)
    80004c96:	6c02                	ld	s8,0(sp)
    80004c98:	6161                	addi	sp,sp,80
    80004c9a:	8082                	ret
    ret = (i == n ? n : -1);
    80004c9c:	5a7d                	li	s4,-1
    80004c9e:	b7d5                	j	80004c82 <filewrite+0xfa>
    panic("filewrite");
    80004ca0:	00004517          	auipc	a0,0x4
    80004ca4:	ac050513          	addi	a0,a0,-1344 # 80008760 <syscalls+0x298>
    80004ca8:	ffffc097          	auipc	ra,0xffffc
    80004cac:	892080e7          	jalr	-1902(ra) # 8000053a <panic>
    return -1;
    80004cb0:	5a7d                	li	s4,-1
    80004cb2:	bfc1                	j	80004c82 <filewrite+0xfa>
      return -1;
    80004cb4:	5a7d                	li	s4,-1
    80004cb6:	b7f1                	j	80004c82 <filewrite+0xfa>
    80004cb8:	5a7d                	li	s4,-1
    80004cba:	b7e1                	j	80004c82 <filewrite+0xfa>

0000000080004cbc <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004cbc:	7179                	addi	sp,sp,-48
    80004cbe:	f406                	sd	ra,40(sp)
    80004cc0:	f022                	sd	s0,32(sp)
    80004cc2:	ec26                	sd	s1,24(sp)
    80004cc4:	e84a                	sd	s2,16(sp)
    80004cc6:	e44e                	sd	s3,8(sp)
    80004cc8:	e052                	sd	s4,0(sp)
    80004cca:	1800                	addi	s0,sp,48
    80004ccc:	84aa                	mv	s1,a0
    80004cce:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004cd0:	0005b023          	sd	zero,0(a1)
    80004cd4:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004cd8:	00000097          	auipc	ra,0x0
    80004cdc:	bf8080e7          	jalr	-1032(ra) # 800048d0 <filealloc>
    80004ce0:	e088                	sd	a0,0(s1)
    80004ce2:	c551                	beqz	a0,80004d6e <pipealloc+0xb2>
    80004ce4:	00000097          	auipc	ra,0x0
    80004ce8:	bec080e7          	jalr	-1044(ra) # 800048d0 <filealloc>
    80004cec:	00aa3023          	sd	a0,0(s4)
    80004cf0:	c92d                	beqz	a0,80004d62 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004cf2:	ffffc097          	auipc	ra,0xffffc
    80004cf6:	dee080e7          	jalr	-530(ra) # 80000ae0 <kalloc>
    80004cfa:	892a                	mv	s2,a0
    80004cfc:	c125                	beqz	a0,80004d5c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004cfe:	4985                	li	s3,1
    80004d00:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004d04:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004d08:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004d0c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004d10:	00004597          	auipc	a1,0x4
    80004d14:	a6058593          	addi	a1,a1,-1440 # 80008770 <syscalls+0x2a8>
    80004d18:	ffffc097          	auipc	ra,0xffffc
    80004d1c:	e28080e7          	jalr	-472(ra) # 80000b40 <initlock>
  (*f0)->type = FD_PIPE;
    80004d20:	609c                	ld	a5,0(s1)
    80004d22:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004d26:	609c                	ld	a5,0(s1)
    80004d28:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004d2c:	609c                	ld	a5,0(s1)
    80004d2e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004d32:	609c                	ld	a5,0(s1)
    80004d34:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004d38:	000a3783          	ld	a5,0(s4)
    80004d3c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004d40:	000a3783          	ld	a5,0(s4)
    80004d44:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004d48:	000a3783          	ld	a5,0(s4)
    80004d4c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004d50:	000a3783          	ld	a5,0(s4)
    80004d54:	0127b823          	sd	s2,16(a5)
  return 0;
    80004d58:	4501                	li	a0,0
    80004d5a:	a025                	j	80004d82 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004d5c:	6088                	ld	a0,0(s1)
    80004d5e:	e501                	bnez	a0,80004d66 <pipealloc+0xaa>
    80004d60:	a039                	j	80004d6e <pipealloc+0xb2>
    80004d62:	6088                	ld	a0,0(s1)
    80004d64:	c51d                	beqz	a0,80004d92 <pipealloc+0xd6>
    fileclose(*f0);
    80004d66:	00000097          	auipc	ra,0x0
    80004d6a:	c26080e7          	jalr	-986(ra) # 8000498c <fileclose>
  if(*f1)
    80004d6e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004d72:	557d                	li	a0,-1
  if(*f1)
    80004d74:	c799                	beqz	a5,80004d82 <pipealloc+0xc6>
    fileclose(*f1);
    80004d76:	853e                	mv	a0,a5
    80004d78:	00000097          	auipc	ra,0x0
    80004d7c:	c14080e7          	jalr	-1004(ra) # 8000498c <fileclose>
  return -1;
    80004d80:	557d                	li	a0,-1
}
    80004d82:	70a2                	ld	ra,40(sp)
    80004d84:	7402                	ld	s0,32(sp)
    80004d86:	64e2                	ld	s1,24(sp)
    80004d88:	6942                	ld	s2,16(sp)
    80004d8a:	69a2                	ld	s3,8(sp)
    80004d8c:	6a02                	ld	s4,0(sp)
    80004d8e:	6145                	addi	sp,sp,48
    80004d90:	8082                	ret
  return -1;
    80004d92:	557d                	li	a0,-1
    80004d94:	b7fd                	j	80004d82 <pipealloc+0xc6>

0000000080004d96 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004d96:	1101                	addi	sp,sp,-32
    80004d98:	ec06                	sd	ra,24(sp)
    80004d9a:	e822                	sd	s0,16(sp)
    80004d9c:	e426                	sd	s1,8(sp)
    80004d9e:	e04a                	sd	s2,0(sp)
    80004da0:	1000                	addi	s0,sp,32
    80004da2:	84aa                	mv	s1,a0
    80004da4:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004da6:	ffffc097          	auipc	ra,0xffffc
    80004daa:	e2a080e7          	jalr	-470(ra) # 80000bd0 <acquire>
  if(writable){
    80004dae:	02090d63          	beqz	s2,80004de8 <pipeclose+0x52>
    pi->writeopen = 0;
    80004db2:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004db6:	21848513          	addi	a0,s1,536
    80004dba:	ffffd097          	auipc	ra,0xffffd
    80004dbe:	514080e7          	jalr	1300(ra) # 800022ce <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004dc2:	2204b783          	ld	a5,544(s1)
    80004dc6:	eb95                	bnez	a5,80004dfa <pipeclose+0x64>
    release(&pi->lock);
    80004dc8:	8526                	mv	a0,s1
    80004dca:	ffffc097          	auipc	ra,0xffffc
    80004dce:	eba080e7          	jalr	-326(ra) # 80000c84 <release>
    kfree((char*)pi);
    80004dd2:	8526                	mv	a0,s1
    80004dd4:	ffffc097          	auipc	ra,0xffffc
    80004dd8:	c0e080e7          	jalr	-1010(ra) # 800009e2 <kfree>
  } else
    release(&pi->lock);
}
    80004ddc:	60e2                	ld	ra,24(sp)
    80004dde:	6442                	ld	s0,16(sp)
    80004de0:	64a2                	ld	s1,8(sp)
    80004de2:	6902                	ld	s2,0(sp)
    80004de4:	6105                	addi	sp,sp,32
    80004de6:	8082                	ret
    pi->readopen = 0;
    80004de8:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004dec:	21c48513          	addi	a0,s1,540
    80004df0:	ffffd097          	auipc	ra,0xffffd
    80004df4:	4de080e7          	jalr	1246(ra) # 800022ce <wakeup>
    80004df8:	b7e9                	j	80004dc2 <pipeclose+0x2c>
    release(&pi->lock);
    80004dfa:	8526                	mv	a0,s1
    80004dfc:	ffffc097          	auipc	ra,0xffffc
    80004e00:	e88080e7          	jalr	-376(ra) # 80000c84 <release>
}
    80004e04:	bfe1                	j	80004ddc <pipeclose+0x46>

0000000080004e06 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004e06:	711d                	addi	sp,sp,-96
    80004e08:	ec86                	sd	ra,88(sp)
    80004e0a:	e8a2                	sd	s0,80(sp)
    80004e0c:	e4a6                	sd	s1,72(sp)
    80004e0e:	e0ca                	sd	s2,64(sp)
    80004e10:	fc4e                	sd	s3,56(sp)
    80004e12:	f852                	sd	s4,48(sp)
    80004e14:	f456                	sd	s5,40(sp)
    80004e16:	f05a                	sd	s6,32(sp)
    80004e18:	ec5e                	sd	s7,24(sp)
    80004e1a:	e862                	sd	s8,16(sp)
    80004e1c:	1080                	addi	s0,sp,96
    80004e1e:	84aa                	mv	s1,a0
    80004e20:	8aae                	mv	s5,a1
    80004e22:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004e24:	ffffd097          	auipc	ra,0xffffd
    80004e28:	b72080e7          	jalr	-1166(ra) # 80001996 <myproc>
    80004e2c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004e2e:	8526                	mv	a0,s1
    80004e30:	ffffc097          	auipc	ra,0xffffc
    80004e34:	da0080e7          	jalr	-608(ra) # 80000bd0 <acquire>
  while(i < n){
    80004e38:	0b405363          	blez	s4,80004ede <pipewrite+0xd8>
  int i = 0;
    80004e3c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e3e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004e40:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004e44:	21c48b93          	addi	s7,s1,540
    80004e48:	a089                	j	80004e8a <pipewrite+0x84>
      release(&pi->lock);
    80004e4a:	8526                	mv	a0,s1
    80004e4c:	ffffc097          	auipc	ra,0xffffc
    80004e50:	e38080e7          	jalr	-456(ra) # 80000c84 <release>
      return -1;
    80004e54:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004e56:	854a                	mv	a0,s2
    80004e58:	60e6                	ld	ra,88(sp)
    80004e5a:	6446                	ld	s0,80(sp)
    80004e5c:	64a6                	ld	s1,72(sp)
    80004e5e:	6906                	ld	s2,64(sp)
    80004e60:	79e2                	ld	s3,56(sp)
    80004e62:	7a42                	ld	s4,48(sp)
    80004e64:	7aa2                	ld	s5,40(sp)
    80004e66:	7b02                	ld	s6,32(sp)
    80004e68:	6be2                	ld	s7,24(sp)
    80004e6a:	6c42                	ld	s8,16(sp)
    80004e6c:	6125                	addi	sp,sp,96
    80004e6e:	8082                	ret
      wakeup(&pi->nread);
    80004e70:	8562                	mv	a0,s8
    80004e72:	ffffd097          	auipc	ra,0xffffd
    80004e76:	45c080e7          	jalr	1116(ra) # 800022ce <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004e7a:	85a6                	mv	a1,s1
    80004e7c:	855e                	mv	a0,s7
    80004e7e:	ffffd097          	auipc	ra,0xffffd
    80004e82:	2c4080e7          	jalr	708(ra) # 80002142 <sleep>
  while(i < n){
    80004e86:	05495d63          	bge	s2,s4,80004ee0 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004e8a:	2204a783          	lw	a5,544(s1)
    80004e8e:	dfd5                	beqz	a5,80004e4a <pipewrite+0x44>
    80004e90:	0289a783          	lw	a5,40(s3)
    80004e94:	fbdd                	bnez	a5,80004e4a <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004e96:	2184a783          	lw	a5,536(s1)
    80004e9a:	21c4a703          	lw	a4,540(s1)
    80004e9e:	2007879b          	addiw	a5,a5,512
    80004ea2:	fcf707e3          	beq	a4,a5,80004e70 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ea6:	4685                	li	a3,1
    80004ea8:	01590633          	add	a2,s2,s5
    80004eac:	faf40593          	addi	a1,s0,-81
    80004eb0:	0609b503          	ld	a0,96(s3)
    80004eb4:	ffffd097          	auipc	ra,0xffffd
    80004eb8:	832080e7          	jalr	-1998(ra) # 800016e6 <copyin>
    80004ebc:	03650263          	beq	a0,s6,80004ee0 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ec0:	21c4a783          	lw	a5,540(s1)
    80004ec4:	0017871b          	addiw	a4,a5,1
    80004ec8:	20e4ae23          	sw	a4,540(s1)
    80004ecc:	1ff7f793          	andi	a5,a5,511
    80004ed0:	97a6                	add	a5,a5,s1
    80004ed2:	faf44703          	lbu	a4,-81(s0)
    80004ed6:	00e78c23          	sb	a4,24(a5)
      i++;
    80004eda:	2905                	addiw	s2,s2,1
    80004edc:	b76d                	j	80004e86 <pipewrite+0x80>
  int i = 0;
    80004ede:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004ee0:	21848513          	addi	a0,s1,536
    80004ee4:	ffffd097          	auipc	ra,0xffffd
    80004ee8:	3ea080e7          	jalr	1002(ra) # 800022ce <wakeup>
  release(&pi->lock);
    80004eec:	8526                	mv	a0,s1
    80004eee:	ffffc097          	auipc	ra,0xffffc
    80004ef2:	d96080e7          	jalr	-618(ra) # 80000c84 <release>
  return i;
    80004ef6:	b785                	j	80004e56 <pipewrite+0x50>

0000000080004ef8 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ef8:	715d                	addi	sp,sp,-80
    80004efa:	e486                	sd	ra,72(sp)
    80004efc:	e0a2                	sd	s0,64(sp)
    80004efe:	fc26                	sd	s1,56(sp)
    80004f00:	f84a                	sd	s2,48(sp)
    80004f02:	f44e                	sd	s3,40(sp)
    80004f04:	f052                	sd	s4,32(sp)
    80004f06:	ec56                	sd	s5,24(sp)
    80004f08:	e85a                	sd	s6,16(sp)
    80004f0a:	0880                	addi	s0,sp,80
    80004f0c:	84aa                	mv	s1,a0
    80004f0e:	892e                	mv	s2,a1
    80004f10:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004f12:	ffffd097          	auipc	ra,0xffffd
    80004f16:	a84080e7          	jalr	-1404(ra) # 80001996 <myproc>
    80004f1a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004f1c:	8526                	mv	a0,s1
    80004f1e:	ffffc097          	auipc	ra,0xffffc
    80004f22:	cb2080e7          	jalr	-846(ra) # 80000bd0 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f26:	2184a703          	lw	a4,536(s1)
    80004f2a:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f2e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f32:	02f71463          	bne	a4,a5,80004f5a <piperead+0x62>
    80004f36:	2244a783          	lw	a5,548(s1)
    80004f3a:	c385                	beqz	a5,80004f5a <piperead+0x62>
    if(pr->killed){
    80004f3c:	028a2783          	lw	a5,40(s4)
    80004f40:	ebc9                	bnez	a5,80004fd2 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f42:	85a6                	mv	a1,s1
    80004f44:	854e                	mv	a0,s3
    80004f46:	ffffd097          	auipc	ra,0xffffd
    80004f4a:	1fc080e7          	jalr	508(ra) # 80002142 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f4e:	2184a703          	lw	a4,536(s1)
    80004f52:	21c4a783          	lw	a5,540(s1)
    80004f56:	fef700e3          	beq	a4,a5,80004f36 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f5a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f5c:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f5e:	05505463          	blez	s5,80004fa6 <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004f62:	2184a783          	lw	a5,536(s1)
    80004f66:	21c4a703          	lw	a4,540(s1)
    80004f6a:	02f70e63          	beq	a4,a5,80004fa6 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004f6e:	0017871b          	addiw	a4,a5,1
    80004f72:	20e4ac23          	sw	a4,536(s1)
    80004f76:	1ff7f793          	andi	a5,a5,511
    80004f7a:	97a6                	add	a5,a5,s1
    80004f7c:	0187c783          	lbu	a5,24(a5)
    80004f80:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f84:	4685                	li	a3,1
    80004f86:	fbf40613          	addi	a2,s0,-65
    80004f8a:	85ca                	mv	a1,s2
    80004f8c:	060a3503          	ld	a0,96(s4)
    80004f90:	ffffc097          	auipc	ra,0xffffc
    80004f94:	6ca080e7          	jalr	1738(ra) # 8000165a <copyout>
    80004f98:	01650763          	beq	a0,s6,80004fa6 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f9c:	2985                	addiw	s3,s3,1
    80004f9e:	0905                	addi	s2,s2,1
    80004fa0:	fd3a91e3          	bne	s5,s3,80004f62 <piperead+0x6a>
    80004fa4:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004fa6:	21c48513          	addi	a0,s1,540
    80004faa:	ffffd097          	auipc	ra,0xffffd
    80004fae:	324080e7          	jalr	804(ra) # 800022ce <wakeup>
  release(&pi->lock);
    80004fb2:	8526                	mv	a0,s1
    80004fb4:	ffffc097          	auipc	ra,0xffffc
    80004fb8:	cd0080e7          	jalr	-816(ra) # 80000c84 <release>
  return i;
}
    80004fbc:	854e                	mv	a0,s3
    80004fbe:	60a6                	ld	ra,72(sp)
    80004fc0:	6406                	ld	s0,64(sp)
    80004fc2:	74e2                	ld	s1,56(sp)
    80004fc4:	7942                	ld	s2,48(sp)
    80004fc6:	79a2                	ld	s3,40(sp)
    80004fc8:	7a02                	ld	s4,32(sp)
    80004fca:	6ae2                	ld	s5,24(sp)
    80004fcc:	6b42                	ld	s6,16(sp)
    80004fce:	6161                	addi	sp,sp,80
    80004fd0:	8082                	ret
      release(&pi->lock);
    80004fd2:	8526                	mv	a0,s1
    80004fd4:	ffffc097          	auipc	ra,0xffffc
    80004fd8:	cb0080e7          	jalr	-848(ra) # 80000c84 <release>
      return -1;
    80004fdc:	59fd                	li	s3,-1
    80004fde:	bff9                	j	80004fbc <piperead+0xc4>

0000000080004fe0 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004fe0:	de010113          	addi	sp,sp,-544
    80004fe4:	20113c23          	sd	ra,536(sp)
    80004fe8:	20813823          	sd	s0,528(sp)
    80004fec:	20913423          	sd	s1,520(sp)
    80004ff0:	21213023          	sd	s2,512(sp)
    80004ff4:	ffce                	sd	s3,504(sp)
    80004ff6:	fbd2                	sd	s4,496(sp)
    80004ff8:	f7d6                	sd	s5,488(sp)
    80004ffa:	f3da                	sd	s6,480(sp)
    80004ffc:	efde                	sd	s7,472(sp)
    80004ffe:	ebe2                	sd	s8,464(sp)
    80005000:	e7e6                	sd	s9,456(sp)
    80005002:	e3ea                	sd	s10,448(sp)
    80005004:	ff6e                	sd	s11,440(sp)
    80005006:	1400                	addi	s0,sp,544
    80005008:	892a                	mv	s2,a0
    8000500a:	dea43423          	sd	a0,-536(s0)
    8000500e:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005012:	ffffd097          	auipc	ra,0xffffd
    80005016:	984080e7          	jalr	-1660(ra) # 80001996 <myproc>
    8000501a:	84aa                	mv	s1,a0

  begin_op();
    8000501c:	fffff097          	auipc	ra,0xfffff
    80005020:	4a8080e7          	jalr	1192(ra) # 800044c4 <begin_op>

  if((ip = namei(path)) == 0){
    80005024:	854a                	mv	a0,s2
    80005026:	fffff097          	auipc	ra,0xfffff
    8000502a:	27e080e7          	jalr	638(ra) # 800042a4 <namei>
    8000502e:	c93d                	beqz	a0,800050a4 <exec+0xc4>
    80005030:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005032:	fffff097          	auipc	ra,0xfffff
    80005036:	ab6080e7          	jalr	-1354(ra) # 80003ae8 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000503a:	04000713          	li	a4,64
    8000503e:	4681                	li	a3,0
    80005040:	e5040613          	addi	a2,s0,-432
    80005044:	4581                	li	a1,0
    80005046:	8556                	mv	a0,s5
    80005048:	fffff097          	auipc	ra,0xfffff
    8000504c:	d54080e7          	jalr	-684(ra) # 80003d9c <readi>
    80005050:	04000793          	li	a5,64
    80005054:	00f51a63          	bne	a0,a5,80005068 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005058:	e5042703          	lw	a4,-432(s0)
    8000505c:	464c47b7          	lui	a5,0x464c4
    80005060:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005064:	04f70663          	beq	a4,a5,800050b0 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005068:	8556                	mv	a0,s5
    8000506a:	fffff097          	auipc	ra,0xfffff
    8000506e:	ce0080e7          	jalr	-800(ra) # 80003d4a <iunlockput>
    end_op();
    80005072:	fffff097          	auipc	ra,0xfffff
    80005076:	4d0080e7          	jalr	1232(ra) # 80004542 <end_op>
  }
  return -1;
    8000507a:	557d                	li	a0,-1
}
    8000507c:	21813083          	ld	ra,536(sp)
    80005080:	21013403          	ld	s0,528(sp)
    80005084:	20813483          	ld	s1,520(sp)
    80005088:	20013903          	ld	s2,512(sp)
    8000508c:	79fe                	ld	s3,504(sp)
    8000508e:	7a5e                	ld	s4,496(sp)
    80005090:	7abe                	ld	s5,488(sp)
    80005092:	7b1e                	ld	s6,480(sp)
    80005094:	6bfe                	ld	s7,472(sp)
    80005096:	6c5e                	ld	s8,464(sp)
    80005098:	6cbe                	ld	s9,456(sp)
    8000509a:	6d1e                	ld	s10,448(sp)
    8000509c:	7dfa                	ld	s11,440(sp)
    8000509e:	22010113          	addi	sp,sp,544
    800050a2:	8082                	ret
    end_op();
    800050a4:	fffff097          	auipc	ra,0xfffff
    800050a8:	49e080e7          	jalr	1182(ra) # 80004542 <end_op>
    return -1;
    800050ac:	557d                	li	a0,-1
    800050ae:	b7f9                	j	8000507c <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800050b0:	8526                	mv	a0,s1
    800050b2:	ffffd097          	auipc	ra,0xffffd
    800050b6:	9de080e7          	jalr	-1570(ra) # 80001a90 <proc_pagetable>
    800050ba:	8b2a                	mv	s6,a0
    800050bc:	d555                	beqz	a0,80005068 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050be:	e7042783          	lw	a5,-400(s0)
    800050c2:	e8845703          	lhu	a4,-376(s0)
    800050c6:	c735                	beqz	a4,80005132 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800050c8:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050ca:	e0043423          	sd	zero,-504(s0)
    if((ph.vaddr % PGSIZE) != 0)
    800050ce:	6a05                	lui	s4,0x1
    800050d0:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800050d4:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    800050d8:	6d85                	lui	s11,0x1
    800050da:	7d7d                	lui	s10,0xfffff
    800050dc:	ac1d                	j	80005312 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800050de:	00003517          	auipc	a0,0x3
    800050e2:	69a50513          	addi	a0,a0,1690 # 80008778 <syscalls+0x2b0>
    800050e6:	ffffb097          	auipc	ra,0xffffb
    800050ea:	454080e7          	jalr	1108(ra) # 8000053a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800050ee:	874a                	mv	a4,s2
    800050f0:	009c86bb          	addw	a3,s9,s1
    800050f4:	4581                	li	a1,0
    800050f6:	8556                	mv	a0,s5
    800050f8:	fffff097          	auipc	ra,0xfffff
    800050fc:	ca4080e7          	jalr	-860(ra) # 80003d9c <readi>
    80005100:	2501                	sext.w	a0,a0
    80005102:	1aa91863          	bne	s2,a0,800052b2 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80005106:	009d84bb          	addw	s1,s11,s1
    8000510a:	013d09bb          	addw	s3,s10,s3
    8000510e:	1f74f263          	bgeu	s1,s7,800052f2 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80005112:	02049593          	slli	a1,s1,0x20
    80005116:	9181                	srli	a1,a1,0x20
    80005118:	95e2                	add	a1,a1,s8
    8000511a:	855a                	mv	a0,s6
    8000511c:	ffffc097          	auipc	ra,0xffffc
    80005120:	f36080e7          	jalr	-202(ra) # 80001052 <walkaddr>
    80005124:	862a                	mv	a2,a0
    if(pa == 0)
    80005126:	dd45                	beqz	a0,800050de <exec+0xfe>
      n = PGSIZE;
    80005128:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    8000512a:	fd49f2e3          	bgeu	s3,s4,800050ee <exec+0x10e>
      n = sz - i;
    8000512e:	894e                	mv	s2,s3
    80005130:	bf7d                	j	800050ee <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005132:	4481                	li	s1,0
  iunlockput(ip);
    80005134:	8556                	mv	a0,s5
    80005136:	fffff097          	auipc	ra,0xfffff
    8000513a:	c14080e7          	jalr	-1004(ra) # 80003d4a <iunlockput>
  end_op();
    8000513e:	fffff097          	auipc	ra,0xfffff
    80005142:	404080e7          	jalr	1028(ra) # 80004542 <end_op>
  p = myproc();
    80005146:	ffffd097          	auipc	ra,0xffffd
    8000514a:	850080e7          	jalr	-1968(ra) # 80001996 <myproc>
    8000514e:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005150:	05853d03          	ld	s10,88(a0)
  sz = PGROUNDUP(sz);
    80005154:	6785                	lui	a5,0x1
    80005156:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80005158:	97a6                	add	a5,a5,s1
    8000515a:	777d                	lui	a4,0xfffff
    8000515c:	8ff9                	and	a5,a5,a4
    8000515e:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005162:	6609                	lui	a2,0x2
    80005164:	963e                	add	a2,a2,a5
    80005166:	85be                	mv	a1,a5
    80005168:	855a                	mv	a0,s6
    8000516a:	ffffc097          	auipc	ra,0xffffc
    8000516e:	29c080e7          	jalr	668(ra) # 80001406 <uvmalloc>
    80005172:	8c2a                	mv	s8,a0
  ip = 0;
    80005174:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005176:	12050e63          	beqz	a0,800052b2 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000517a:	75f9                	lui	a1,0xffffe
    8000517c:	95aa                	add	a1,a1,a0
    8000517e:	855a                	mv	a0,s6
    80005180:	ffffc097          	auipc	ra,0xffffc
    80005184:	4a8080e7          	jalr	1192(ra) # 80001628 <uvmclear>
  stackbase = sp - PGSIZE;
    80005188:	7afd                	lui	s5,0xfffff
    8000518a:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    8000518c:	df043783          	ld	a5,-528(s0)
    80005190:	6388                	ld	a0,0(a5)
    80005192:	c925                	beqz	a0,80005202 <exec+0x222>
    80005194:	e9040993          	addi	s3,s0,-368
    80005198:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000519c:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000519e:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800051a0:	ffffc097          	auipc	ra,0xffffc
    800051a4:	ca8080e7          	jalr	-856(ra) # 80000e48 <strlen>
    800051a8:	0015079b          	addiw	a5,a0,1
    800051ac:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800051b0:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800051b4:	13596363          	bltu	s2,s5,800052da <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800051b8:	df043d83          	ld	s11,-528(s0)
    800051bc:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800051c0:	8552                	mv	a0,s4
    800051c2:	ffffc097          	auipc	ra,0xffffc
    800051c6:	c86080e7          	jalr	-890(ra) # 80000e48 <strlen>
    800051ca:	0015069b          	addiw	a3,a0,1
    800051ce:	8652                	mv	a2,s4
    800051d0:	85ca                	mv	a1,s2
    800051d2:	855a                	mv	a0,s6
    800051d4:	ffffc097          	auipc	ra,0xffffc
    800051d8:	486080e7          	jalr	1158(ra) # 8000165a <copyout>
    800051dc:	10054363          	bltz	a0,800052e2 <exec+0x302>
    ustack[argc] = sp;
    800051e0:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800051e4:	0485                	addi	s1,s1,1
    800051e6:	008d8793          	addi	a5,s11,8
    800051ea:	def43823          	sd	a5,-528(s0)
    800051ee:	008db503          	ld	a0,8(s11)
    800051f2:	c911                	beqz	a0,80005206 <exec+0x226>
    if(argc >= MAXARG)
    800051f4:	09a1                	addi	s3,s3,8
    800051f6:	fb3c95e3          	bne	s9,s3,800051a0 <exec+0x1c0>
  sz = sz1;
    800051fa:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051fe:	4a81                	li	s5,0
    80005200:	a84d                	j	800052b2 <exec+0x2d2>
  sp = sz;
    80005202:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005204:	4481                	li	s1,0
  ustack[argc] = 0;
    80005206:	00349793          	slli	a5,s1,0x3
    8000520a:	f9078793          	addi	a5,a5,-112
    8000520e:	97a2                	add	a5,a5,s0
    80005210:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005214:	00148693          	addi	a3,s1,1
    80005218:	068e                	slli	a3,a3,0x3
    8000521a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000521e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005222:	01597663          	bgeu	s2,s5,8000522e <exec+0x24e>
  sz = sz1;
    80005226:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000522a:	4a81                	li	s5,0
    8000522c:	a059                	j	800052b2 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000522e:	e9040613          	addi	a2,s0,-368
    80005232:	85ca                	mv	a1,s2
    80005234:	855a                	mv	a0,s6
    80005236:	ffffc097          	auipc	ra,0xffffc
    8000523a:	424080e7          	jalr	1060(ra) # 8000165a <copyout>
    8000523e:	0a054663          	bltz	a0,800052ea <exec+0x30a>
  p->trapframe->a1 = sp;
    80005242:	068bb783          	ld	a5,104(s7)
    80005246:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000524a:	de843783          	ld	a5,-536(s0)
    8000524e:	0007c703          	lbu	a4,0(a5)
    80005252:	cf11                	beqz	a4,8000526e <exec+0x28e>
    80005254:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005256:	02f00693          	li	a3,47
    8000525a:	a039                	j	80005268 <exec+0x288>
      last = s+1;
    8000525c:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005260:	0785                	addi	a5,a5,1
    80005262:	fff7c703          	lbu	a4,-1(a5)
    80005266:	c701                	beqz	a4,8000526e <exec+0x28e>
    if(*s == '/')
    80005268:	fed71ce3          	bne	a4,a3,80005260 <exec+0x280>
    8000526c:	bfc5                	j	8000525c <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    8000526e:	4641                	li	a2,16
    80005270:	de843583          	ld	a1,-536(s0)
    80005274:	168b8513          	addi	a0,s7,360
    80005278:	ffffc097          	auipc	ra,0xffffc
    8000527c:	b9e080e7          	jalr	-1122(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    80005280:	060bb503          	ld	a0,96(s7)
  p->pagetable = pagetable;
    80005284:	076bb023          	sd	s6,96(s7)
  p->sz = sz;
    80005288:	058bbc23          	sd	s8,88(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000528c:	068bb783          	ld	a5,104(s7)
    80005290:	e6843703          	ld	a4,-408(s0)
    80005294:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005296:	068bb783          	ld	a5,104(s7)
    8000529a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000529e:	85ea                	mv	a1,s10
    800052a0:	ffffd097          	auipc	ra,0xffffd
    800052a4:	88c080e7          	jalr	-1908(ra) # 80001b2c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800052a8:	0004851b          	sext.w	a0,s1
    800052ac:	bbc1                	j	8000507c <exec+0x9c>
    800052ae:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    800052b2:	df843583          	ld	a1,-520(s0)
    800052b6:	855a                	mv	a0,s6
    800052b8:	ffffd097          	auipc	ra,0xffffd
    800052bc:	874080e7          	jalr	-1932(ra) # 80001b2c <proc_freepagetable>
  if(ip){
    800052c0:	da0a94e3          	bnez	s5,80005068 <exec+0x88>
  return -1;
    800052c4:	557d                	li	a0,-1
    800052c6:	bb5d                	j	8000507c <exec+0x9c>
    800052c8:	de943c23          	sd	s1,-520(s0)
    800052cc:	b7dd                	j	800052b2 <exec+0x2d2>
    800052ce:	de943c23          	sd	s1,-520(s0)
    800052d2:	b7c5                	j	800052b2 <exec+0x2d2>
    800052d4:	de943c23          	sd	s1,-520(s0)
    800052d8:	bfe9                	j	800052b2 <exec+0x2d2>
  sz = sz1;
    800052da:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052de:	4a81                	li	s5,0
    800052e0:	bfc9                	j	800052b2 <exec+0x2d2>
  sz = sz1;
    800052e2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052e6:	4a81                	li	s5,0
    800052e8:	b7e9                	j	800052b2 <exec+0x2d2>
  sz = sz1;
    800052ea:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052ee:	4a81                	li	s5,0
    800052f0:	b7c9                	j	800052b2 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800052f2:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052f6:	e0843783          	ld	a5,-504(s0)
    800052fa:	0017869b          	addiw	a3,a5,1
    800052fe:	e0d43423          	sd	a3,-504(s0)
    80005302:	e0043783          	ld	a5,-512(s0)
    80005306:	0387879b          	addiw	a5,a5,56
    8000530a:	e8845703          	lhu	a4,-376(s0)
    8000530e:	e2e6d3e3          	bge	a3,a4,80005134 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005312:	2781                	sext.w	a5,a5
    80005314:	e0f43023          	sd	a5,-512(s0)
    80005318:	03800713          	li	a4,56
    8000531c:	86be                	mv	a3,a5
    8000531e:	e1840613          	addi	a2,s0,-488
    80005322:	4581                	li	a1,0
    80005324:	8556                	mv	a0,s5
    80005326:	fffff097          	auipc	ra,0xfffff
    8000532a:	a76080e7          	jalr	-1418(ra) # 80003d9c <readi>
    8000532e:	03800793          	li	a5,56
    80005332:	f6f51ee3          	bne	a0,a5,800052ae <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80005336:	e1842783          	lw	a5,-488(s0)
    8000533a:	4705                	li	a4,1
    8000533c:	fae79de3          	bne	a5,a4,800052f6 <exec+0x316>
    if(ph.memsz < ph.filesz)
    80005340:	e4043603          	ld	a2,-448(s0)
    80005344:	e3843783          	ld	a5,-456(s0)
    80005348:	f8f660e3          	bltu	a2,a5,800052c8 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000534c:	e2843783          	ld	a5,-472(s0)
    80005350:	963e                	add	a2,a2,a5
    80005352:	f6f66ee3          	bltu	a2,a5,800052ce <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005356:	85a6                	mv	a1,s1
    80005358:	855a                	mv	a0,s6
    8000535a:	ffffc097          	auipc	ra,0xffffc
    8000535e:	0ac080e7          	jalr	172(ra) # 80001406 <uvmalloc>
    80005362:	dea43c23          	sd	a0,-520(s0)
    80005366:	d53d                	beqz	a0,800052d4 <exec+0x2f4>
    if((ph.vaddr % PGSIZE) != 0)
    80005368:	e2843c03          	ld	s8,-472(s0)
    8000536c:	de043783          	ld	a5,-544(s0)
    80005370:	00fc77b3          	and	a5,s8,a5
    80005374:	ff9d                	bnez	a5,800052b2 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005376:	e2042c83          	lw	s9,-480(s0)
    8000537a:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000537e:	f60b8ae3          	beqz	s7,800052f2 <exec+0x312>
    80005382:	89de                	mv	s3,s7
    80005384:	4481                	li	s1,0
    80005386:	b371                	j	80005112 <exec+0x132>

0000000080005388 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005388:	7179                	addi	sp,sp,-48
    8000538a:	f406                	sd	ra,40(sp)
    8000538c:	f022                	sd	s0,32(sp)
    8000538e:	ec26                	sd	s1,24(sp)
    80005390:	e84a                	sd	s2,16(sp)
    80005392:	1800                	addi	s0,sp,48
    80005394:	892e                	mv	s2,a1
    80005396:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005398:	fdc40593          	addi	a1,s0,-36
    8000539c:	ffffe097          	auipc	ra,0xffffe
    800053a0:	af6080e7          	jalr	-1290(ra) # 80002e92 <argint>
    800053a4:	04054063          	bltz	a0,800053e4 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800053a8:	fdc42703          	lw	a4,-36(s0)
    800053ac:	47bd                	li	a5,15
    800053ae:	02e7ed63          	bltu	a5,a4,800053e8 <argfd+0x60>
    800053b2:	ffffc097          	auipc	ra,0xffffc
    800053b6:	5e4080e7          	jalr	1508(ra) # 80001996 <myproc>
    800053ba:	fdc42703          	lw	a4,-36(s0)
    800053be:	01c70793          	addi	a5,a4,28 # fffffffffffff01c <end+0xffffffff7ffd901c>
    800053c2:	078e                	slli	a5,a5,0x3
    800053c4:	953e                	add	a0,a0,a5
    800053c6:	611c                	ld	a5,0(a0)
    800053c8:	c395                	beqz	a5,800053ec <argfd+0x64>
    return -1;
  if(pfd)
    800053ca:	00090463          	beqz	s2,800053d2 <argfd+0x4a>
    *pfd = fd;
    800053ce:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800053d2:	4501                	li	a0,0
  if(pf)
    800053d4:	c091                	beqz	s1,800053d8 <argfd+0x50>
    *pf = f;
    800053d6:	e09c                	sd	a5,0(s1)
}
    800053d8:	70a2                	ld	ra,40(sp)
    800053da:	7402                	ld	s0,32(sp)
    800053dc:	64e2                	ld	s1,24(sp)
    800053de:	6942                	ld	s2,16(sp)
    800053e0:	6145                	addi	sp,sp,48
    800053e2:	8082                	ret
    return -1;
    800053e4:	557d                	li	a0,-1
    800053e6:	bfcd                	j	800053d8 <argfd+0x50>
    return -1;
    800053e8:	557d                	li	a0,-1
    800053ea:	b7fd                	j	800053d8 <argfd+0x50>
    800053ec:	557d                	li	a0,-1
    800053ee:	b7ed                	j	800053d8 <argfd+0x50>

00000000800053f0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800053f0:	1101                	addi	sp,sp,-32
    800053f2:	ec06                	sd	ra,24(sp)
    800053f4:	e822                	sd	s0,16(sp)
    800053f6:	e426                	sd	s1,8(sp)
    800053f8:	1000                	addi	s0,sp,32
    800053fa:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800053fc:	ffffc097          	auipc	ra,0xffffc
    80005400:	59a080e7          	jalr	1434(ra) # 80001996 <myproc>
    80005404:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005406:	0e050793          	addi	a5,a0,224
    8000540a:	4501                	li	a0,0
    8000540c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000540e:	6398                	ld	a4,0(a5)
    80005410:	cb19                	beqz	a4,80005426 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005412:	2505                	addiw	a0,a0,1
    80005414:	07a1                	addi	a5,a5,8
    80005416:	fed51ce3          	bne	a0,a3,8000540e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000541a:	557d                	li	a0,-1
}
    8000541c:	60e2                	ld	ra,24(sp)
    8000541e:	6442                	ld	s0,16(sp)
    80005420:	64a2                	ld	s1,8(sp)
    80005422:	6105                	addi	sp,sp,32
    80005424:	8082                	ret
      p->ofile[fd] = f;
    80005426:	01c50793          	addi	a5,a0,28
    8000542a:	078e                	slli	a5,a5,0x3
    8000542c:	963e                	add	a2,a2,a5
    8000542e:	e204                	sd	s1,0(a2)
      return fd;
    80005430:	b7f5                	j	8000541c <fdalloc+0x2c>

0000000080005432 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005432:	715d                	addi	sp,sp,-80
    80005434:	e486                	sd	ra,72(sp)
    80005436:	e0a2                	sd	s0,64(sp)
    80005438:	fc26                	sd	s1,56(sp)
    8000543a:	f84a                	sd	s2,48(sp)
    8000543c:	f44e                	sd	s3,40(sp)
    8000543e:	f052                	sd	s4,32(sp)
    80005440:	ec56                	sd	s5,24(sp)
    80005442:	0880                	addi	s0,sp,80
    80005444:	89ae                	mv	s3,a1
    80005446:	8ab2                	mv	s5,a2
    80005448:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000544a:	fb040593          	addi	a1,s0,-80
    8000544e:	fffff097          	auipc	ra,0xfffff
    80005452:	e74080e7          	jalr	-396(ra) # 800042c2 <nameiparent>
    80005456:	892a                	mv	s2,a0
    80005458:	12050e63          	beqz	a0,80005594 <create+0x162>
    return 0;

  ilock(dp);
    8000545c:	ffffe097          	auipc	ra,0xffffe
    80005460:	68c080e7          	jalr	1676(ra) # 80003ae8 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005464:	4601                	li	a2,0
    80005466:	fb040593          	addi	a1,s0,-80
    8000546a:	854a                	mv	a0,s2
    8000546c:	fffff097          	auipc	ra,0xfffff
    80005470:	b60080e7          	jalr	-1184(ra) # 80003fcc <dirlookup>
    80005474:	84aa                	mv	s1,a0
    80005476:	c921                	beqz	a0,800054c6 <create+0x94>
    iunlockput(dp);
    80005478:	854a                	mv	a0,s2
    8000547a:	fffff097          	auipc	ra,0xfffff
    8000547e:	8d0080e7          	jalr	-1840(ra) # 80003d4a <iunlockput>
    ilock(ip);
    80005482:	8526                	mv	a0,s1
    80005484:	ffffe097          	auipc	ra,0xffffe
    80005488:	664080e7          	jalr	1636(ra) # 80003ae8 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000548c:	2981                	sext.w	s3,s3
    8000548e:	4789                	li	a5,2
    80005490:	02f99463          	bne	s3,a5,800054b8 <create+0x86>
    80005494:	0444d783          	lhu	a5,68(s1)
    80005498:	37f9                	addiw	a5,a5,-2
    8000549a:	17c2                	slli	a5,a5,0x30
    8000549c:	93c1                	srli	a5,a5,0x30
    8000549e:	4705                	li	a4,1
    800054a0:	00f76c63          	bltu	a4,a5,800054b8 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800054a4:	8526                	mv	a0,s1
    800054a6:	60a6                	ld	ra,72(sp)
    800054a8:	6406                	ld	s0,64(sp)
    800054aa:	74e2                	ld	s1,56(sp)
    800054ac:	7942                	ld	s2,48(sp)
    800054ae:	79a2                	ld	s3,40(sp)
    800054b0:	7a02                	ld	s4,32(sp)
    800054b2:	6ae2                	ld	s5,24(sp)
    800054b4:	6161                	addi	sp,sp,80
    800054b6:	8082                	ret
    iunlockput(ip);
    800054b8:	8526                	mv	a0,s1
    800054ba:	fffff097          	auipc	ra,0xfffff
    800054be:	890080e7          	jalr	-1904(ra) # 80003d4a <iunlockput>
    return 0;
    800054c2:	4481                	li	s1,0
    800054c4:	b7c5                	j	800054a4 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800054c6:	85ce                	mv	a1,s3
    800054c8:	00092503          	lw	a0,0(s2)
    800054cc:	ffffe097          	auipc	ra,0xffffe
    800054d0:	482080e7          	jalr	1154(ra) # 8000394e <ialloc>
    800054d4:	84aa                	mv	s1,a0
    800054d6:	c521                	beqz	a0,8000551e <create+0xec>
  ilock(ip);
    800054d8:	ffffe097          	auipc	ra,0xffffe
    800054dc:	610080e7          	jalr	1552(ra) # 80003ae8 <ilock>
  ip->major = major;
    800054e0:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800054e4:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800054e8:	4a05                	li	s4,1
    800054ea:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800054ee:	8526                	mv	a0,s1
    800054f0:	ffffe097          	auipc	ra,0xffffe
    800054f4:	52c080e7          	jalr	1324(ra) # 80003a1c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800054f8:	2981                	sext.w	s3,s3
    800054fa:	03498a63          	beq	s3,s4,8000552e <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800054fe:	40d0                	lw	a2,4(s1)
    80005500:	fb040593          	addi	a1,s0,-80
    80005504:	854a                	mv	a0,s2
    80005506:	fffff097          	auipc	ra,0xfffff
    8000550a:	cdc080e7          	jalr	-804(ra) # 800041e2 <dirlink>
    8000550e:	06054b63          	bltz	a0,80005584 <create+0x152>
  iunlockput(dp);
    80005512:	854a                	mv	a0,s2
    80005514:	fffff097          	auipc	ra,0xfffff
    80005518:	836080e7          	jalr	-1994(ra) # 80003d4a <iunlockput>
  return ip;
    8000551c:	b761                	j	800054a4 <create+0x72>
    panic("create: ialloc");
    8000551e:	00003517          	auipc	a0,0x3
    80005522:	27a50513          	addi	a0,a0,634 # 80008798 <syscalls+0x2d0>
    80005526:	ffffb097          	auipc	ra,0xffffb
    8000552a:	014080e7          	jalr	20(ra) # 8000053a <panic>
    dp->nlink++;  // for ".."
    8000552e:	04a95783          	lhu	a5,74(s2)
    80005532:	2785                	addiw	a5,a5,1
    80005534:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005538:	854a                	mv	a0,s2
    8000553a:	ffffe097          	auipc	ra,0xffffe
    8000553e:	4e2080e7          	jalr	1250(ra) # 80003a1c <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005542:	40d0                	lw	a2,4(s1)
    80005544:	00003597          	auipc	a1,0x3
    80005548:	26458593          	addi	a1,a1,612 # 800087a8 <syscalls+0x2e0>
    8000554c:	8526                	mv	a0,s1
    8000554e:	fffff097          	auipc	ra,0xfffff
    80005552:	c94080e7          	jalr	-876(ra) # 800041e2 <dirlink>
    80005556:	00054f63          	bltz	a0,80005574 <create+0x142>
    8000555a:	00492603          	lw	a2,4(s2)
    8000555e:	00003597          	auipc	a1,0x3
    80005562:	25258593          	addi	a1,a1,594 # 800087b0 <syscalls+0x2e8>
    80005566:	8526                	mv	a0,s1
    80005568:	fffff097          	auipc	ra,0xfffff
    8000556c:	c7a080e7          	jalr	-902(ra) # 800041e2 <dirlink>
    80005570:	f80557e3          	bgez	a0,800054fe <create+0xcc>
      panic("create dots");
    80005574:	00003517          	auipc	a0,0x3
    80005578:	24450513          	addi	a0,a0,580 # 800087b8 <syscalls+0x2f0>
    8000557c:	ffffb097          	auipc	ra,0xffffb
    80005580:	fbe080e7          	jalr	-66(ra) # 8000053a <panic>
    panic("create: dirlink");
    80005584:	00003517          	auipc	a0,0x3
    80005588:	24450513          	addi	a0,a0,580 # 800087c8 <syscalls+0x300>
    8000558c:	ffffb097          	auipc	ra,0xffffb
    80005590:	fae080e7          	jalr	-82(ra) # 8000053a <panic>
    return 0;
    80005594:	84aa                	mv	s1,a0
    80005596:	b739                	j	800054a4 <create+0x72>

0000000080005598 <sys_dup>:
{
    80005598:	7179                	addi	sp,sp,-48
    8000559a:	f406                	sd	ra,40(sp)
    8000559c:	f022                	sd	s0,32(sp)
    8000559e:	ec26                	sd	s1,24(sp)
    800055a0:	e84a                	sd	s2,16(sp)
    800055a2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800055a4:	fd840613          	addi	a2,s0,-40
    800055a8:	4581                	li	a1,0
    800055aa:	4501                	li	a0,0
    800055ac:	00000097          	auipc	ra,0x0
    800055b0:	ddc080e7          	jalr	-548(ra) # 80005388 <argfd>
    return -1;
    800055b4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800055b6:	02054363          	bltz	a0,800055dc <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800055ba:	fd843903          	ld	s2,-40(s0)
    800055be:	854a                	mv	a0,s2
    800055c0:	00000097          	auipc	ra,0x0
    800055c4:	e30080e7          	jalr	-464(ra) # 800053f0 <fdalloc>
    800055c8:	84aa                	mv	s1,a0
    return -1;
    800055ca:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800055cc:	00054863          	bltz	a0,800055dc <sys_dup+0x44>
  filedup(f);
    800055d0:	854a                	mv	a0,s2
    800055d2:	fffff097          	auipc	ra,0xfffff
    800055d6:	368080e7          	jalr	872(ra) # 8000493a <filedup>
  return fd;
    800055da:	87a6                	mv	a5,s1
}
    800055dc:	853e                	mv	a0,a5
    800055de:	70a2                	ld	ra,40(sp)
    800055e0:	7402                	ld	s0,32(sp)
    800055e2:	64e2                	ld	s1,24(sp)
    800055e4:	6942                	ld	s2,16(sp)
    800055e6:	6145                	addi	sp,sp,48
    800055e8:	8082                	ret

00000000800055ea <sys_read>:
{
    800055ea:	7179                	addi	sp,sp,-48
    800055ec:	f406                	sd	ra,40(sp)
    800055ee:	f022                	sd	s0,32(sp)
    800055f0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055f2:	fe840613          	addi	a2,s0,-24
    800055f6:	4581                	li	a1,0
    800055f8:	4501                	li	a0,0
    800055fa:	00000097          	auipc	ra,0x0
    800055fe:	d8e080e7          	jalr	-626(ra) # 80005388 <argfd>
    return -1;
    80005602:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005604:	04054163          	bltz	a0,80005646 <sys_read+0x5c>
    80005608:	fe440593          	addi	a1,s0,-28
    8000560c:	4509                	li	a0,2
    8000560e:	ffffe097          	auipc	ra,0xffffe
    80005612:	884080e7          	jalr	-1916(ra) # 80002e92 <argint>
    return -1;
    80005616:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005618:	02054763          	bltz	a0,80005646 <sys_read+0x5c>
    8000561c:	fd840593          	addi	a1,s0,-40
    80005620:	4505                	li	a0,1
    80005622:	ffffe097          	auipc	ra,0xffffe
    80005626:	892080e7          	jalr	-1902(ra) # 80002eb4 <argaddr>
    return -1;
    8000562a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000562c:	00054d63          	bltz	a0,80005646 <sys_read+0x5c>
  return fileread(f, p, n);
    80005630:	fe442603          	lw	a2,-28(s0)
    80005634:	fd843583          	ld	a1,-40(s0)
    80005638:	fe843503          	ld	a0,-24(s0)
    8000563c:	fffff097          	auipc	ra,0xfffff
    80005640:	48a080e7          	jalr	1162(ra) # 80004ac6 <fileread>
    80005644:	87aa                	mv	a5,a0
}
    80005646:	853e                	mv	a0,a5
    80005648:	70a2                	ld	ra,40(sp)
    8000564a:	7402                	ld	s0,32(sp)
    8000564c:	6145                	addi	sp,sp,48
    8000564e:	8082                	ret

0000000080005650 <sys_write>:
{
    80005650:	7179                	addi	sp,sp,-48
    80005652:	f406                	sd	ra,40(sp)
    80005654:	f022                	sd	s0,32(sp)
    80005656:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005658:	fe840613          	addi	a2,s0,-24
    8000565c:	4581                	li	a1,0
    8000565e:	4501                	li	a0,0
    80005660:	00000097          	auipc	ra,0x0
    80005664:	d28080e7          	jalr	-728(ra) # 80005388 <argfd>
    return -1;
    80005668:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000566a:	04054163          	bltz	a0,800056ac <sys_write+0x5c>
    8000566e:	fe440593          	addi	a1,s0,-28
    80005672:	4509                	li	a0,2
    80005674:	ffffe097          	auipc	ra,0xffffe
    80005678:	81e080e7          	jalr	-2018(ra) # 80002e92 <argint>
    return -1;
    8000567c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000567e:	02054763          	bltz	a0,800056ac <sys_write+0x5c>
    80005682:	fd840593          	addi	a1,s0,-40
    80005686:	4505                	li	a0,1
    80005688:	ffffe097          	auipc	ra,0xffffe
    8000568c:	82c080e7          	jalr	-2004(ra) # 80002eb4 <argaddr>
    return -1;
    80005690:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005692:	00054d63          	bltz	a0,800056ac <sys_write+0x5c>
  return filewrite(f, p, n);
    80005696:	fe442603          	lw	a2,-28(s0)
    8000569a:	fd843583          	ld	a1,-40(s0)
    8000569e:	fe843503          	ld	a0,-24(s0)
    800056a2:	fffff097          	auipc	ra,0xfffff
    800056a6:	4e6080e7          	jalr	1254(ra) # 80004b88 <filewrite>
    800056aa:	87aa                	mv	a5,a0
}
    800056ac:	853e                	mv	a0,a5
    800056ae:	70a2                	ld	ra,40(sp)
    800056b0:	7402                	ld	s0,32(sp)
    800056b2:	6145                	addi	sp,sp,48
    800056b4:	8082                	ret

00000000800056b6 <sys_close>:
{
    800056b6:	1101                	addi	sp,sp,-32
    800056b8:	ec06                	sd	ra,24(sp)
    800056ba:	e822                	sd	s0,16(sp)
    800056bc:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800056be:	fe040613          	addi	a2,s0,-32
    800056c2:	fec40593          	addi	a1,s0,-20
    800056c6:	4501                	li	a0,0
    800056c8:	00000097          	auipc	ra,0x0
    800056cc:	cc0080e7          	jalr	-832(ra) # 80005388 <argfd>
    return -1;
    800056d0:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800056d2:	02054463          	bltz	a0,800056fa <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800056d6:	ffffc097          	auipc	ra,0xffffc
    800056da:	2c0080e7          	jalr	704(ra) # 80001996 <myproc>
    800056de:	fec42783          	lw	a5,-20(s0)
    800056e2:	07f1                	addi	a5,a5,28
    800056e4:	078e                	slli	a5,a5,0x3
    800056e6:	953e                	add	a0,a0,a5
    800056e8:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800056ec:	fe043503          	ld	a0,-32(s0)
    800056f0:	fffff097          	auipc	ra,0xfffff
    800056f4:	29c080e7          	jalr	668(ra) # 8000498c <fileclose>
  return 0;
    800056f8:	4781                	li	a5,0
}
    800056fa:	853e                	mv	a0,a5
    800056fc:	60e2                	ld	ra,24(sp)
    800056fe:	6442                	ld	s0,16(sp)
    80005700:	6105                	addi	sp,sp,32
    80005702:	8082                	ret

0000000080005704 <sys_fstat>:
{
    80005704:	1101                	addi	sp,sp,-32
    80005706:	ec06                	sd	ra,24(sp)
    80005708:	e822                	sd	s0,16(sp)
    8000570a:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000570c:	fe840613          	addi	a2,s0,-24
    80005710:	4581                	li	a1,0
    80005712:	4501                	li	a0,0
    80005714:	00000097          	auipc	ra,0x0
    80005718:	c74080e7          	jalr	-908(ra) # 80005388 <argfd>
    return -1;
    8000571c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000571e:	02054563          	bltz	a0,80005748 <sys_fstat+0x44>
    80005722:	fe040593          	addi	a1,s0,-32
    80005726:	4505                	li	a0,1
    80005728:	ffffd097          	auipc	ra,0xffffd
    8000572c:	78c080e7          	jalr	1932(ra) # 80002eb4 <argaddr>
    return -1;
    80005730:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005732:	00054b63          	bltz	a0,80005748 <sys_fstat+0x44>
  return filestat(f, st);
    80005736:	fe043583          	ld	a1,-32(s0)
    8000573a:	fe843503          	ld	a0,-24(s0)
    8000573e:	fffff097          	auipc	ra,0xfffff
    80005742:	316080e7          	jalr	790(ra) # 80004a54 <filestat>
    80005746:	87aa                	mv	a5,a0
}
    80005748:	853e                	mv	a0,a5
    8000574a:	60e2                	ld	ra,24(sp)
    8000574c:	6442                	ld	s0,16(sp)
    8000574e:	6105                	addi	sp,sp,32
    80005750:	8082                	ret

0000000080005752 <sys_link>:
{
    80005752:	7169                	addi	sp,sp,-304
    80005754:	f606                	sd	ra,296(sp)
    80005756:	f222                	sd	s0,288(sp)
    80005758:	ee26                	sd	s1,280(sp)
    8000575a:	ea4a                	sd	s2,272(sp)
    8000575c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000575e:	08000613          	li	a2,128
    80005762:	ed040593          	addi	a1,s0,-304
    80005766:	4501                	li	a0,0
    80005768:	ffffd097          	auipc	ra,0xffffd
    8000576c:	76e080e7          	jalr	1902(ra) # 80002ed6 <argstr>
    return -1;
    80005770:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005772:	10054e63          	bltz	a0,8000588e <sys_link+0x13c>
    80005776:	08000613          	li	a2,128
    8000577a:	f5040593          	addi	a1,s0,-176
    8000577e:	4505                	li	a0,1
    80005780:	ffffd097          	auipc	ra,0xffffd
    80005784:	756080e7          	jalr	1878(ra) # 80002ed6 <argstr>
    return -1;
    80005788:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000578a:	10054263          	bltz	a0,8000588e <sys_link+0x13c>
  begin_op();
    8000578e:	fffff097          	auipc	ra,0xfffff
    80005792:	d36080e7          	jalr	-714(ra) # 800044c4 <begin_op>
  if((ip = namei(old)) == 0){
    80005796:	ed040513          	addi	a0,s0,-304
    8000579a:	fffff097          	auipc	ra,0xfffff
    8000579e:	b0a080e7          	jalr	-1270(ra) # 800042a4 <namei>
    800057a2:	84aa                	mv	s1,a0
    800057a4:	c551                	beqz	a0,80005830 <sys_link+0xde>
  ilock(ip);
    800057a6:	ffffe097          	auipc	ra,0xffffe
    800057aa:	342080e7          	jalr	834(ra) # 80003ae8 <ilock>
  if(ip->type == T_DIR){
    800057ae:	04449703          	lh	a4,68(s1)
    800057b2:	4785                	li	a5,1
    800057b4:	08f70463          	beq	a4,a5,8000583c <sys_link+0xea>
  ip->nlink++;
    800057b8:	04a4d783          	lhu	a5,74(s1)
    800057bc:	2785                	addiw	a5,a5,1
    800057be:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057c2:	8526                	mv	a0,s1
    800057c4:	ffffe097          	auipc	ra,0xffffe
    800057c8:	258080e7          	jalr	600(ra) # 80003a1c <iupdate>
  iunlock(ip);
    800057cc:	8526                	mv	a0,s1
    800057ce:	ffffe097          	auipc	ra,0xffffe
    800057d2:	3dc080e7          	jalr	988(ra) # 80003baa <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800057d6:	fd040593          	addi	a1,s0,-48
    800057da:	f5040513          	addi	a0,s0,-176
    800057de:	fffff097          	auipc	ra,0xfffff
    800057e2:	ae4080e7          	jalr	-1308(ra) # 800042c2 <nameiparent>
    800057e6:	892a                	mv	s2,a0
    800057e8:	c935                	beqz	a0,8000585c <sys_link+0x10a>
  ilock(dp);
    800057ea:	ffffe097          	auipc	ra,0xffffe
    800057ee:	2fe080e7          	jalr	766(ra) # 80003ae8 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800057f2:	00092703          	lw	a4,0(s2)
    800057f6:	409c                	lw	a5,0(s1)
    800057f8:	04f71d63          	bne	a4,a5,80005852 <sys_link+0x100>
    800057fc:	40d0                	lw	a2,4(s1)
    800057fe:	fd040593          	addi	a1,s0,-48
    80005802:	854a                	mv	a0,s2
    80005804:	fffff097          	auipc	ra,0xfffff
    80005808:	9de080e7          	jalr	-1570(ra) # 800041e2 <dirlink>
    8000580c:	04054363          	bltz	a0,80005852 <sys_link+0x100>
  iunlockput(dp);
    80005810:	854a                	mv	a0,s2
    80005812:	ffffe097          	auipc	ra,0xffffe
    80005816:	538080e7          	jalr	1336(ra) # 80003d4a <iunlockput>
  iput(ip);
    8000581a:	8526                	mv	a0,s1
    8000581c:	ffffe097          	auipc	ra,0xffffe
    80005820:	486080e7          	jalr	1158(ra) # 80003ca2 <iput>
  end_op();
    80005824:	fffff097          	auipc	ra,0xfffff
    80005828:	d1e080e7          	jalr	-738(ra) # 80004542 <end_op>
  return 0;
    8000582c:	4781                	li	a5,0
    8000582e:	a085                	j	8000588e <sys_link+0x13c>
    end_op();
    80005830:	fffff097          	auipc	ra,0xfffff
    80005834:	d12080e7          	jalr	-750(ra) # 80004542 <end_op>
    return -1;
    80005838:	57fd                	li	a5,-1
    8000583a:	a891                	j	8000588e <sys_link+0x13c>
    iunlockput(ip);
    8000583c:	8526                	mv	a0,s1
    8000583e:	ffffe097          	auipc	ra,0xffffe
    80005842:	50c080e7          	jalr	1292(ra) # 80003d4a <iunlockput>
    end_op();
    80005846:	fffff097          	auipc	ra,0xfffff
    8000584a:	cfc080e7          	jalr	-772(ra) # 80004542 <end_op>
    return -1;
    8000584e:	57fd                	li	a5,-1
    80005850:	a83d                	j	8000588e <sys_link+0x13c>
    iunlockput(dp);
    80005852:	854a                	mv	a0,s2
    80005854:	ffffe097          	auipc	ra,0xffffe
    80005858:	4f6080e7          	jalr	1270(ra) # 80003d4a <iunlockput>
  ilock(ip);
    8000585c:	8526                	mv	a0,s1
    8000585e:	ffffe097          	auipc	ra,0xffffe
    80005862:	28a080e7          	jalr	650(ra) # 80003ae8 <ilock>
  ip->nlink--;
    80005866:	04a4d783          	lhu	a5,74(s1)
    8000586a:	37fd                	addiw	a5,a5,-1
    8000586c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005870:	8526                	mv	a0,s1
    80005872:	ffffe097          	auipc	ra,0xffffe
    80005876:	1aa080e7          	jalr	426(ra) # 80003a1c <iupdate>
  iunlockput(ip);
    8000587a:	8526                	mv	a0,s1
    8000587c:	ffffe097          	auipc	ra,0xffffe
    80005880:	4ce080e7          	jalr	1230(ra) # 80003d4a <iunlockput>
  end_op();
    80005884:	fffff097          	auipc	ra,0xfffff
    80005888:	cbe080e7          	jalr	-834(ra) # 80004542 <end_op>
  return -1;
    8000588c:	57fd                	li	a5,-1
}
    8000588e:	853e                	mv	a0,a5
    80005890:	70b2                	ld	ra,296(sp)
    80005892:	7412                	ld	s0,288(sp)
    80005894:	64f2                	ld	s1,280(sp)
    80005896:	6952                	ld	s2,272(sp)
    80005898:	6155                	addi	sp,sp,304
    8000589a:	8082                	ret

000000008000589c <sys_unlink>:
{
    8000589c:	7151                	addi	sp,sp,-240
    8000589e:	f586                	sd	ra,232(sp)
    800058a0:	f1a2                	sd	s0,224(sp)
    800058a2:	eda6                	sd	s1,216(sp)
    800058a4:	e9ca                	sd	s2,208(sp)
    800058a6:	e5ce                	sd	s3,200(sp)
    800058a8:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800058aa:	08000613          	li	a2,128
    800058ae:	f3040593          	addi	a1,s0,-208
    800058b2:	4501                	li	a0,0
    800058b4:	ffffd097          	auipc	ra,0xffffd
    800058b8:	622080e7          	jalr	1570(ra) # 80002ed6 <argstr>
    800058bc:	18054163          	bltz	a0,80005a3e <sys_unlink+0x1a2>
  begin_op();
    800058c0:	fffff097          	auipc	ra,0xfffff
    800058c4:	c04080e7          	jalr	-1020(ra) # 800044c4 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800058c8:	fb040593          	addi	a1,s0,-80
    800058cc:	f3040513          	addi	a0,s0,-208
    800058d0:	fffff097          	auipc	ra,0xfffff
    800058d4:	9f2080e7          	jalr	-1550(ra) # 800042c2 <nameiparent>
    800058d8:	84aa                	mv	s1,a0
    800058da:	c979                	beqz	a0,800059b0 <sys_unlink+0x114>
  ilock(dp);
    800058dc:	ffffe097          	auipc	ra,0xffffe
    800058e0:	20c080e7          	jalr	524(ra) # 80003ae8 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800058e4:	00003597          	auipc	a1,0x3
    800058e8:	ec458593          	addi	a1,a1,-316 # 800087a8 <syscalls+0x2e0>
    800058ec:	fb040513          	addi	a0,s0,-80
    800058f0:	ffffe097          	auipc	ra,0xffffe
    800058f4:	6c2080e7          	jalr	1730(ra) # 80003fb2 <namecmp>
    800058f8:	14050a63          	beqz	a0,80005a4c <sys_unlink+0x1b0>
    800058fc:	00003597          	auipc	a1,0x3
    80005900:	eb458593          	addi	a1,a1,-332 # 800087b0 <syscalls+0x2e8>
    80005904:	fb040513          	addi	a0,s0,-80
    80005908:	ffffe097          	auipc	ra,0xffffe
    8000590c:	6aa080e7          	jalr	1706(ra) # 80003fb2 <namecmp>
    80005910:	12050e63          	beqz	a0,80005a4c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005914:	f2c40613          	addi	a2,s0,-212
    80005918:	fb040593          	addi	a1,s0,-80
    8000591c:	8526                	mv	a0,s1
    8000591e:	ffffe097          	auipc	ra,0xffffe
    80005922:	6ae080e7          	jalr	1710(ra) # 80003fcc <dirlookup>
    80005926:	892a                	mv	s2,a0
    80005928:	12050263          	beqz	a0,80005a4c <sys_unlink+0x1b0>
  ilock(ip);
    8000592c:	ffffe097          	auipc	ra,0xffffe
    80005930:	1bc080e7          	jalr	444(ra) # 80003ae8 <ilock>
  if(ip->nlink < 1)
    80005934:	04a91783          	lh	a5,74(s2)
    80005938:	08f05263          	blez	a5,800059bc <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000593c:	04491703          	lh	a4,68(s2)
    80005940:	4785                	li	a5,1
    80005942:	08f70563          	beq	a4,a5,800059cc <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005946:	4641                	li	a2,16
    80005948:	4581                	li	a1,0
    8000594a:	fc040513          	addi	a0,s0,-64
    8000594e:	ffffb097          	auipc	ra,0xffffb
    80005952:	37e080e7          	jalr	894(ra) # 80000ccc <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005956:	4741                	li	a4,16
    80005958:	f2c42683          	lw	a3,-212(s0)
    8000595c:	fc040613          	addi	a2,s0,-64
    80005960:	4581                	li	a1,0
    80005962:	8526                	mv	a0,s1
    80005964:	ffffe097          	auipc	ra,0xffffe
    80005968:	530080e7          	jalr	1328(ra) # 80003e94 <writei>
    8000596c:	47c1                	li	a5,16
    8000596e:	0af51563          	bne	a0,a5,80005a18 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005972:	04491703          	lh	a4,68(s2)
    80005976:	4785                	li	a5,1
    80005978:	0af70863          	beq	a4,a5,80005a28 <sys_unlink+0x18c>
  iunlockput(dp);
    8000597c:	8526                	mv	a0,s1
    8000597e:	ffffe097          	auipc	ra,0xffffe
    80005982:	3cc080e7          	jalr	972(ra) # 80003d4a <iunlockput>
  ip->nlink--;
    80005986:	04a95783          	lhu	a5,74(s2)
    8000598a:	37fd                	addiw	a5,a5,-1
    8000598c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005990:	854a                	mv	a0,s2
    80005992:	ffffe097          	auipc	ra,0xffffe
    80005996:	08a080e7          	jalr	138(ra) # 80003a1c <iupdate>
  iunlockput(ip);
    8000599a:	854a                	mv	a0,s2
    8000599c:	ffffe097          	auipc	ra,0xffffe
    800059a0:	3ae080e7          	jalr	942(ra) # 80003d4a <iunlockput>
  end_op();
    800059a4:	fffff097          	auipc	ra,0xfffff
    800059a8:	b9e080e7          	jalr	-1122(ra) # 80004542 <end_op>
  return 0;
    800059ac:	4501                	li	a0,0
    800059ae:	a84d                	j	80005a60 <sys_unlink+0x1c4>
    end_op();
    800059b0:	fffff097          	auipc	ra,0xfffff
    800059b4:	b92080e7          	jalr	-1134(ra) # 80004542 <end_op>
    return -1;
    800059b8:	557d                	li	a0,-1
    800059ba:	a05d                	j	80005a60 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800059bc:	00003517          	auipc	a0,0x3
    800059c0:	e1c50513          	addi	a0,a0,-484 # 800087d8 <syscalls+0x310>
    800059c4:	ffffb097          	auipc	ra,0xffffb
    800059c8:	b76080e7          	jalr	-1162(ra) # 8000053a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800059cc:	04c92703          	lw	a4,76(s2)
    800059d0:	02000793          	li	a5,32
    800059d4:	f6e7f9e3          	bgeu	a5,a4,80005946 <sys_unlink+0xaa>
    800059d8:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059dc:	4741                	li	a4,16
    800059de:	86ce                	mv	a3,s3
    800059e0:	f1840613          	addi	a2,s0,-232
    800059e4:	4581                	li	a1,0
    800059e6:	854a                	mv	a0,s2
    800059e8:	ffffe097          	auipc	ra,0xffffe
    800059ec:	3b4080e7          	jalr	948(ra) # 80003d9c <readi>
    800059f0:	47c1                	li	a5,16
    800059f2:	00f51b63          	bne	a0,a5,80005a08 <sys_unlink+0x16c>
    if(de.inum != 0)
    800059f6:	f1845783          	lhu	a5,-232(s0)
    800059fa:	e7a1                	bnez	a5,80005a42 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800059fc:	29c1                	addiw	s3,s3,16
    800059fe:	04c92783          	lw	a5,76(s2)
    80005a02:	fcf9ede3          	bltu	s3,a5,800059dc <sys_unlink+0x140>
    80005a06:	b781                	j	80005946 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005a08:	00003517          	auipc	a0,0x3
    80005a0c:	de850513          	addi	a0,a0,-536 # 800087f0 <syscalls+0x328>
    80005a10:	ffffb097          	auipc	ra,0xffffb
    80005a14:	b2a080e7          	jalr	-1238(ra) # 8000053a <panic>
    panic("unlink: writei");
    80005a18:	00003517          	auipc	a0,0x3
    80005a1c:	df050513          	addi	a0,a0,-528 # 80008808 <syscalls+0x340>
    80005a20:	ffffb097          	auipc	ra,0xffffb
    80005a24:	b1a080e7          	jalr	-1254(ra) # 8000053a <panic>
    dp->nlink--;
    80005a28:	04a4d783          	lhu	a5,74(s1)
    80005a2c:	37fd                	addiw	a5,a5,-1
    80005a2e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005a32:	8526                	mv	a0,s1
    80005a34:	ffffe097          	auipc	ra,0xffffe
    80005a38:	fe8080e7          	jalr	-24(ra) # 80003a1c <iupdate>
    80005a3c:	b781                	j	8000597c <sys_unlink+0xe0>
    return -1;
    80005a3e:	557d                	li	a0,-1
    80005a40:	a005                	j	80005a60 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005a42:	854a                	mv	a0,s2
    80005a44:	ffffe097          	auipc	ra,0xffffe
    80005a48:	306080e7          	jalr	774(ra) # 80003d4a <iunlockput>
  iunlockput(dp);
    80005a4c:	8526                	mv	a0,s1
    80005a4e:	ffffe097          	auipc	ra,0xffffe
    80005a52:	2fc080e7          	jalr	764(ra) # 80003d4a <iunlockput>
  end_op();
    80005a56:	fffff097          	auipc	ra,0xfffff
    80005a5a:	aec080e7          	jalr	-1300(ra) # 80004542 <end_op>
  return -1;
    80005a5e:	557d                	li	a0,-1
}
    80005a60:	70ae                	ld	ra,232(sp)
    80005a62:	740e                	ld	s0,224(sp)
    80005a64:	64ee                	ld	s1,216(sp)
    80005a66:	694e                	ld	s2,208(sp)
    80005a68:	69ae                	ld	s3,200(sp)
    80005a6a:	616d                	addi	sp,sp,240
    80005a6c:	8082                	ret

0000000080005a6e <sys_open>:

uint64
sys_open(void)
{
    80005a6e:	7131                	addi	sp,sp,-192
    80005a70:	fd06                	sd	ra,184(sp)
    80005a72:	f922                	sd	s0,176(sp)
    80005a74:	f526                	sd	s1,168(sp)
    80005a76:	f14a                	sd	s2,160(sp)
    80005a78:	ed4e                	sd	s3,152(sp)
    80005a7a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005a7c:	08000613          	li	a2,128
    80005a80:	f5040593          	addi	a1,s0,-176
    80005a84:	4501                	li	a0,0
    80005a86:	ffffd097          	auipc	ra,0xffffd
    80005a8a:	450080e7          	jalr	1104(ra) # 80002ed6 <argstr>
    return -1;
    80005a8e:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005a90:	0c054163          	bltz	a0,80005b52 <sys_open+0xe4>
    80005a94:	f4c40593          	addi	a1,s0,-180
    80005a98:	4505                	li	a0,1
    80005a9a:	ffffd097          	auipc	ra,0xffffd
    80005a9e:	3f8080e7          	jalr	1016(ra) # 80002e92 <argint>
    80005aa2:	0a054863          	bltz	a0,80005b52 <sys_open+0xe4>

  begin_op();
    80005aa6:	fffff097          	auipc	ra,0xfffff
    80005aaa:	a1e080e7          	jalr	-1506(ra) # 800044c4 <begin_op>

  if(omode & O_CREATE){
    80005aae:	f4c42783          	lw	a5,-180(s0)
    80005ab2:	2007f793          	andi	a5,a5,512
    80005ab6:	cbdd                	beqz	a5,80005b6c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005ab8:	4681                	li	a3,0
    80005aba:	4601                	li	a2,0
    80005abc:	4589                	li	a1,2
    80005abe:	f5040513          	addi	a0,s0,-176
    80005ac2:	00000097          	auipc	ra,0x0
    80005ac6:	970080e7          	jalr	-1680(ra) # 80005432 <create>
    80005aca:	892a                	mv	s2,a0
    if(ip == 0){
    80005acc:	c959                	beqz	a0,80005b62 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005ace:	04491703          	lh	a4,68(s2)
    80005ad2:	478d                	li	a5,3
    80005ad4:	00f71763          	bne	a4,a5,80005ae2 <sys_open+0x74>
    80005ad8:	04695703          	lhu	a4,70(s2)
    80005adc:	47a5                	li	a5,9
    80005ade:	0ce7ec63          	bltu	a5,a4,80005bb6 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005ae2:	fffff097          	auipc	ra,0xfffff
    80005ae6:	dee080e7          	jalr	-530(ra) # 800048d0 <filealloc>
    80005aea:	89aa                	mv	s3,a0
    80005aec:	10050263          	beqz	a0,80005bf0 <sys_open+0x182>
    80005af0:	00000097          	auipc	ra,0x0
    80005af4:	900080e7          	jalr	-1792(ra) # 800053f0 <fdalloc>
    80005af8:	84aa                	mv	s1,a0
    80005afa:	0e054663          	bltz	a0,80005be6 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005afe:	04491703          	lh	a4,68(s2)
    80005b02:	478d                	li	a5,3
    80005b04:	0cf70463          	beq	a4,a5,80005bcc <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005b08:	4789                	li	a5,2
    80005b0a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005b0e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005b12:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005b16:	f4c42783          	lw	a5,-180(s0)
    80005b1a:	0017c713          	xori	a4,a5,1
    80005b1e:	8b05                	andi	a4,a4,1
    80005b20:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005b24:	0037f713          	andi	a4,a5,3
    80005b28:	00e03733          	snez	a4,a4
    80005b2c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005b30:	4007f793          	andi	a5,a5,1024
    80005b34:	c791                	beqz	a5,80005b40 <sys_open+0xd2>
    80005b36:	04491703          	lh	a4,68(s2)
    80005b3a:	4789                	li	a5,2
    80005b3c:	08f70f63          	beq	a4,a5,80005bda <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005b40:	854a                	mv	a0,s2
    80005b42:	ffffe097          	auipc	ra,0xffffe
    80005b46:	068080e7          	jalr	104(ra) # 80003baa <iunlock>
  end_op();
    80005b4a:	fffff097          	auipc	ra,0xfffff
    80005b4e:	9f8080e7          	jalr	-1544(ra) # 80004542 <end_op>

  return fd;
}
    80005b52:	8526                	mv	a0,s1
    80005b54:	70ea                	ld	ra,184(sp)
    80005b56:	744a                	ld	s0,176(sp)
    80005b58:	74aa                	ld	s1,168(sp)
    80005b5a:	790a                	ld	s2,160(sp)
    80005b5c:	69ea                	ld	s3,152(sp)
    80005b5e:	6129                	addi	sp,sp,192
    80005b60:	8082                	ret
      end_op();
    80005b62:	fffff097          	auipc	ra,0xfffff
    80005b66:	9e0080e7          	jalr	-1568(ra) # 80004542 <end_op>
      return -1;
    80005b6a:	b7e5                	j	80005b52 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005b6c:	f5040513          	addi	a0,s0,-176
    80005b70:	ffffe097          	auipc	ra,0xffffe
    80005b74:	734080e7          	jalr	1844(ra) # 800042a4 <namei>
    80005b78:	892a                	mv	s2,a0
    80005b7a:	c905                	beqz	a0,80005baa <sys_open+0x13c>
    ilock(ip);
    80005b7c:	ffffe097          	auipc	ra,0xffffe
    80005b80:	f6c080e7          	jalr	-148(ra) # 80003ae8 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005b84:	04491703          	lh	a4,68(s2)
    80005b88:	4785                	li	a5,1
    80005b8a:	f4f712e3          	bne	a4,a5,80005ace <sys_open+0x60>
    80005b8e:	f4c42783          	lw	a5,-180(s0)
    80005b92:	dba1                	beqz	a5,80005ae2 <sys_open+0x74>
      iunlockput(ip);
    80005b94:	854a                	mv	a0,s2
    80005b96:	ffffe097          	auipc	ra,0xffffe
    80005b9a:	1b4080e7          	jalr	436(ra) # 80003d4a <iunlockput>
      end_op();
    80005b9e:	fffff097          	auipc	ra,0xfffff
    80005ba2:	9a4080e7          	jalr	-1628(ra) # 80004542 <end_op>
      return -1;
    80005ba6:	54fd                	li	s1,-1
    80005ba8:	b76d                	j	80005b52 <sys_open+0xe4>
      end_op();
    80005baa:	fffff097          	auipc	ra,0xfffff
    80005bae:	998080e7          	jalr	-1640(ra) # 80004542 <end_op>
      return -1;
    80005bb2:	54fd                	li	s1,-1
    80005bb4:	bf79                	j	80005b52 <sys_open+0xe4>
    iunlockput(ip);
    80005bb6:	854a                	mv	a0,s2
    80005bb8:	ffffe097          	auipc	ra,0xffffe
    80005bbc:	192080e7          	jalr	402(ra) # 80003d4a <iunlockput>
    end_op();
    80005bc0:	fffff097          	auipc	ra,0xfffff
    80005bc4:	982080e7          	jalr	-1662(ra) # 80004542 <end_op>
    return -1;
    80005bc8:	54fd                	li	s1,-1
    80005bca:	b761                	j	80005b52 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005bcc:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005bd0:	04691783          	lh	a5,70(s2)
    80005bd4:	02f99223          	sh	a5,36(s3)
    80005bd8:	bf2d                	j	80005b12 <sys_open+0xa4>
    itrunc(ip);
    80005bda:	854a                	mv	a0,s2
    80005bdc:	ffffe097          	auipc	ra,0xffffe
    80005be0:	01a080e7          	jalr	26(ra) # 80003bf6 <itrunc>
    80005be4:	bfb1                	j	80005b40 <sys_open+0xd2>
      fileclose(f);
    80005be6:	854e                	mv	a0,s3
    80005be8:	fffff097          	auipc	ra,0xfffff
    80005bec:	da4080e7          	jalr	-604(ra) # 8000498c <fileclose>
    iunlockput(ip);
    80005bf0:	854a                	mv	a0,s2
    80005bf2:	ffffe097          	auipc	ra,0xffffe
    80005bf6:	158080e7          	jalr	344(ra) # 80003d4a <iunlockput>
    end_op();
    80005bfa:	fffff097          	auipc	ra,0xfffff
    80005bfe:	948080e7          	jalr	-1720(ra) # 80004542 <end_op>
    return -1;
    80005c02:	54fd                	li	s1,-1
    80005c04:	b7b9                	j	80005b52 <sys_open+0xe4>

0000000080005c06 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005c06:	7175                	addi	sp,sp,-144
    80005c08:	e506                	sd	ra,136(sp)
    80005c0a:	e122                	sd	s0,128(sp)
    80005c0c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005c0e:	fffff097          	auipc	ra,0xfffff
    80005c12:	8b6080e7          	jalr	-1866(ra) # 800044c4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005c16:	08000613          	li	a2,128
    80005c1a:	f7040593          	addi	a1,s0,-144
    80005c1e:	4501                	li	a0,0
    80005c20:	ffffd097          	auipc	ra,0xffffd
    80005c24:	2b6080e7          	jalr	694(ra) # 80002ed6 <argstr>
    80005c28:	02054963          	bltz	a0,80005c5a <sys_mkdir+0x54>
    80005c2c:	4681                	li	a3,0
    80005c2e:	4601                	li	a2,0
    80005c30:	4585                	li	a1,1
    80005c32:	f7040513          	addi	a0,s0,-144
    80005c36:	fffff097          	auipc	ra,0xfffff
    80005c3a:	7fc080e7          	jalr	2044(ra) # 80005432 <create>
    80005c3e:	cd11                	beqz	a0,80005c5a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c40:	ffffe097          	auipc	ra,0xffffe
    80005c44:	10a080e7          	jalr	266(ra) # 80003d4a <iunlockput>
  end_op();
    80005c48:	fffff097          	auipc	ra,0xfffff
    80005c4c:	8fa080e7          	jalr	-1798(ra) # 80004542 <end_op>
  return 0;
    80005c50:	4501                	li	a0,0
}
    80005c52:	60aa                	ld	ra,136(sp)
    80005c54:	640a                	ld	s0,128(sp)
    80005c56:	6149                	addi	sp,sp,144
    80005c58:	8082                	ret
    end_op();
    80005c5a:	fffff097          	auipc	ra,0xfffff
    80005c5e:	8e8080e7          	jalr	-1816(ra) # 80004542 <end_op>
    return -1;
    80005c62:	557d                	li	a0,-1
    80005c64:	b7fd                	j	80005c52 <sys_mkdir+0x4c>

0000000080005c66 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005c66:	7135                	addi	sp,sp,-160
    80005c68:	ed06                	sd	ra,152(sp)
    80005c6a:	e922                	sd	s0,144(sp)
    80005c6c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005c6e:	fffff097          	auipc	ra,0xfffff
    80005c72:	856080e7          	jalr	-1962(ra) # 800044c4 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c76:	08000613          	li	a2,128
    80005c7a:	f7040593          	addi	a1,s0,-144
    80005c7e:	4501                	li	a0,0
    80005c80:	ffffd097          	auipc	ra,0xffffd
    80005c84:	256080e7          	jalr	598(ra) # 80002ed6 <argstr>
    80005c88:	04054a63          	bltz	a0,80005cdc <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005c8c:	f6c40593          	addi	a1,s0,-148
    80005c90:	4505                	li	a0,1
    80005c92:	ffffd097          	auipc	ra,0xffffd
    80005c96:	200080e7          	jalr	512(ra) # 80002e92 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c9a:	04054163          	bltz	a0,80005cdc <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005c9e:	f6840593          	addi	a1,s0,-152
    80005ca2:	4509                	li	a0,2
    80005ca4:	ffffd097          	auipc	ra,0xffffd
    80005ca8:	1ee080e7          	jalr	494(ra) # 80002e92 <argint>
     argint(1, &major) < 0 ||
    80005cac:	02054863          	bltz	a0,80005cdc <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005cb0:	f6841683          	lh	a3,-152(s0)
    80005cb4:	f6c41603          	lh	a2,-148(s0)
    80005cb8:	458d                	li	a1,3
    80005cba:	f7040513          	addi	a0,s0,-144
    80005cbe:	fffff097          	auipc	ra,0xfffff
    80005cc2:	774080e7          	jalr	1908(ra) # 80005432 <create>
     argint(2, &minor) < 0 ||
    80005cc6:	c919                	beqz	a0,80005cdc <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005cc8:	ffffe097          	auipc	ra,0xffffe
    80005ccc:	082080e7          	jalr	130(ra) # 80003d4a <iunlockput>
  end_op();
    80005cd0:	fffff097          	auipc	ra,0xfffff
    80005cd4:	872080e7          	jalr	-1934(ra) # 80004542 <end_op>
  return 0;
    80005cd8:	4501                	li	a0,0
    80005cda:	a031                	j	80005ce6 <sys_mknod+0x80>
    end_op();
    80005cdc:	fffff097          	auipc	ra,0xfffff
    80005ce0:	866080e7          	jalr	-1946(ra) # 80004542 <end_op>
    return -1;
    80005ce4:	557d                	li	a0,-1
}
    80005ce6:	60ea                	ld	ra,152(sp)
    80005ce8:	644a                	ld	s0,144(sp)
    80005cea:	610d                	addi	sp,sp,160
    80005cec:	8082                	ret

0000000080005cee <sys_chdir>:

uint64
sys_chdir(void)
{
    80005cee:	7135                	addi	sp,sp,-160
    80005cf0:	ed06                	sd	ra,152(sp)
    80005cf2:	e922                	sd	s0,144(sp)
    80005cf4:	e526                	sd	s1,136(sp)
    80005cf6:	e14a                	sd	s2,128(sp)
    80005cf8:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005cfa:	ffffc097          	auipc	ra,0xffffc
    80005cfe:	c9c080e7          	jalr	-868(ra) # 80001996 <myproc>
    80005d02:	892a                	mv	s2,a0
  
  begin_op();
    80005d04:	ffffe097          	auipc	ra,0xffffe
    80005d08:	7c0080e7          	jalr	1984(ra) # 800044c4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005d0c:	08000613          	li	a2,128
    80005d10:	f6040593          	addi	a1,s0,-160
    80005d14:	4501                	li	a0,0
    80005d16:	ffffd097          	auipc	ra,0xffffd
    80005d1a:	1c0080e7          	jalr	448(ra) # 80002ed6 <argstr>
    80005d1e:	04054b63          	bltz	a0,80005d74 <sys_chdir+0x86>
    80005d22:	f6040513          	addi	a0,s0,-160
    80005d26:	ffffe097          	auipc	ra,0xffffe
    80005d2a:	57e080e7          	jalr	1406(ra) # 800042a4 <namei>
    80005d2e:	84aa                	mv	s1,a0
    80005d30:	c131                	beqz	a0,80005d74 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005d32:	ffffe097          	auipc	ra,0xffffe
    80005d36:	db6080e7          	jalr	-586(ra) # 80003ae8 <ilock>
  if(ip->type != T_DIR){
    80005d3a:	04449703          	lh	a4,68(s1)
    80005d3e:	4785                	li	a5,1
    80005d40:	04f71063          	bne	a4,a5,80005d80 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005d44:	8526                	mv	a0,s1
    80005d46:	ffffe097          	auipc	ra,0xffffe
    80005d4a:	e64080e7          	jalr	-412(ra) # 80003baa <iunlock>
  iput(p->cwd);
    80005d4e:	16093503          	ld	a0,352(s2)
    80005d52:	ffffe097          	auipc	ra,0xffffe
    80005d56:	f50080e7          	jalr	-176(ra) # 80003ca2 <iput>
  end_op();
    80005d5a:	ffffe097          	auipc	ra,0xffffe
    80005d5e:	7e8080e7          	jalr	2024(ra) # 80004542 <end_op>
  p->cwd = ip;
    80005d62:	16993023          	sd	s1,352(s2)
  return 0;
    80005d66:	4501                	li	a0,0
}
    80005d68:	60ea                	ld	ra,152(sp)
    80005d6a:	644a                	ld	s0,144(sp)
    80005d6c:	64aa                	ld	s1,136(sp)
    80005d6e:	690a                	ld	s2,128(sp)
    80005d70:	610d                	addi	sp,sp,160
    80005d72:	8082                	ret
    end_op();
    80005d74:	ffffe097          	auipc	ra,0xffffe
    80005d78:	7ce080e7          	jalr	1998(ra) # 80004542 <end_op>
    return -1;
    80005d7c:	557d                	li	a0,-1
    80005d7e:	b7ed                	j	80005d68 <sys_chdir+0x7a>
    iunlockput(ip);
    80005d80:	8526                	mv	a0,s1
    80005d82:	ffffe097          	auipc	ra,0xffffe
    80005d86:	fc8080e7          	jalr	-56(ra) # 80003d4a <iunlockput>
    end_op();
    80005d8a:	ffffe097          	auipc	ra,0xffffe
    80005d8e:	7b8080e7          	jalr	1976(ra) # 80004542 <end_op>
    return -1;
    80005d92:	557d                	li	a0,-1
    80005d94:	bfd1                	j	80005d68 <sys_chdir+0x7a>

0000000080005d96 <sys_exec>:

uint64
sys_exec(void)
{
    80005d96:	7145                	addi	sp,sp,-464
    80005d98:	e786                	sd	ra,456(sp)
    80005d9a:	e3a2                	sd	s0,448(sp)
    80005d9c:	ff26                	sd	s1,440(sp)
    80005d9e:	fb4a                	sd	s2,432(sp)
    80005da0:	f74e                	sd	s3,424(sp)
    80005da2:	f352                	sd	s4,416(sp)
    80005da4:	ef56                	sd	s5,408(sp)
    80005da6:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005da8:	08000613          	li	a2,128
    80005dac:	f4040593          	addi	a1,s0,-192
    80005db0:	4501                	li	a0,0
    80005db2:	ffffd097          	auipc	ra,0xffffd
    80005db6:	124080e7          	jalr	292(ra) # 80002ed6 <argstr>
    return -1;
    80005dba:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005dbc:	0c054b63          	bltz	a0,80005e92 <sys_exec+0xfc>
    80005dc0:	e3840593          	addi	a1,s0,-456
    80005dc4:	4505                	li	a0,1
    80005dc6:	ffffd097          	auipc	ra,0xffffd
    80005dca:	0ee080e7          	jalr	238(ra) # 80002eb4 <argaddr>
    80005dce:	0c054263          	bltz	a0,80005e92 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005dd2:	10000613          	li	a2,256
    80005dd6:	4581                	li	a1,0
    80005dd8:	e4040513          	addi	a0,s0,-448
    80005ddc:	ffffb097          	auipc	ra,0xffffb
    80005de0:	ef0080e7          	jalr	-272(ra) # 80000ccc <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005de4:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005de8:	89a6                	mv	s3,s1
    80005dea:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005dec:	02000a13          	li	s4,32
    80005df0:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005df4:	00391513          	slli	a0,s2,0x3
    80005df8:	e3040593          	addi	a1,s0,-464
    80005dfc:	e3843783          	ld	a5,-456(s0)
    80005e00:	953e                	add	a0,a0,a5
    80005e02:	ffffd097          	auipc	ra,0xffffd
    80005e06:	ff6080e7          	jalr	-10(ra) # 80002df8 <fetchaddr>
    80005e0a:	02054a63          	bltz	a0,80005e3e <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005e0e:	e3043783          	ld	a5,-464(s0)
    80005e12:	c3b9                	beqz	a5,80005e58 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005e14:	ffffb097          	auipc	ra,0xffffb
    80005e18:	ccc080e7          	jalr	-820(ra) # 80000ae0 <kalloc>
    80005e1c:	85aa                	mv	a1,a0
    80005e1e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005e22:	cd11                	beqz	a0,80005e3e <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005e24:	6605                	lui	a2,0x1
    80005e26:	e3043503          	ld	a0,-464(s0)
    80005e2a:	ffffd097          	auipc	ra,0xffffd
    80005e2e:	020080e7          	jalr	32(ra) # 80002e4a <fetchstr>
    80005e32:	00054663          	bltz	a0,80005e3e <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005e36:	0905                	addi	s2,s2,1
    80005e38:	09a1                	addi	s3,s3,8
    80005e3a:	fb491be3          	bne	s2,s4,80005df0 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e3e:	f4040913          	addi	s2,s0,-192
    80005e42:	6088                	ld	a0,0(s1)
    80005e44:	c531                	beqz	a0,80005e90 <sys_exec+0xfa>
    kfree(argv[i]);
    80005e46:	ffffb097          	auipc	ra,0xffffb
    80005e4a:	b9c080e7          	jalr	-1124(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e4e:	04a1                	addi	s1,s1,8
    80005e50:	ff2499e3          	bne	s1,s2,80005e42 <sys_exec+0xac>
  return -1;
    80005e54:	597d                	li	s2,-1
    80005e56:	a835                	j	80005e92 <sys_exec+0xfc>
      argv[i] = 0;
    80005e58:	0a8e                	slli	s5,s5,0x3
    80005e5a:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffd8fc0>
    80005e5e:	00878ab3          	add	s5,a5,s0
    80005e62:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005e66:	e4040593          	addi	a1,s0,-448
    80005e6a:	f4040513          	addi	a0,s0,-192
    80005e6e:	fffff097          	auipc	ra,0xfffff
    80005e72:	172080e7          	jalr	370(ra) # 80004fe0 <exec>
    80005e76:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e78:	f4040993          	addi	s3,s0,-192
    80005e7c:	6088                	ld	a0,0(s1)
    80005e7e:	c911                	beqz	a0,80005e92 <sys_exec+0xfc>
    kfree(argv[i]);
    80005e80:	ffffb097          	auipc	ra,0xffffb
    80005e84:	b62080e7          	jalr	-1182(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e88:	04a1                	addi	s1,s1,8
    80005e8a:	ff3499e3          	bne	s1,s3,80005e7c <sys_exec+0xe6>
    80005e8e:	a011                	j	80005e92 <sys_exec+0xfc>
  return -1;
    80005e90:	597d                	li	s2,-1
}
    80005e92:	854a                	mv	a0,s2
    80005e94:	60be                	ld	ra,456(sp)
    80005e96:	641e                	ld	s0,448(sp)
    80005e98:	74fa                	ld	s1,440(sp)
    80005e9a:	795a                	ld	s2,432(sp)
    80005e9c:	79ba                	ld	s3,424(sp)
    80005e9e:	7a1a                	ld	s4,416(sp)
    80005ea0:	6afa                	ld	s5,408(sp)
    80005ea2:	6179                	addi	sp,sp,464
    80005ea4:	8082                	ret

0000000080005ea6 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005ea6:	7139                	addi	sp,sp,-64
    80005ea8:	fc06                	sd	ra,56(sp)
    80005eaa:	f822                	sd	s0,48(sp)
    80005eac:	f426                	sd	s1,40(sp)
    80005eae:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005eb0:	ffffc097          	auipc	ra,0xffffc
    80005eb4:	ae6080e7          	jalr	-1306(ra) # 80001996 <myproc>
    80005eb8:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005eba:	fd840593          	addi	a1,s0,-40
    80005ebe:	4501                	li	a0,0
    80005ec0:	ffffd097          	auipc	ra,0xffffd
    80005ec4:	ff4080e7          	jalr	-12(ra) # 80002eb4 <argaddr>
    return -1;
    80005ec8:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005eca:	0e054063          	bltz	a0,80005faa <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005ece:	fc840593          	addi	a1,s0,-56
    80005ed2:	fd040513          	addi	a0,s0,-48
    80005ed6:	fffff097          	auipc	ra,0xfffff
    80005eda:	de6080e7          	jalr	-538(ra) # 80004cbc <pipealloc>
    return -1;
    80005ede:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ee0:	0c054563          	bltz	a0,80005faa <sys_pipe+0x104>
  fd0 = -1;
    80005ee4:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ee8:	fd043503          	ld	a0,-48(s0)
    80005eec:	fffff097          	auipc	ra,0xfffff
    80005ef0:	504080e7          	jalr	1284(ra) # 800053f0 <fdalloc>
    80005ef4:	fca42223          	sw	a0,-60(s0)
    80005ef8:	08054c63          	bltz	a0,80005f90 <sys_pipe+0xea>
    80005efc:	fc843503          	ld	a0,-56(s0)
    80005f00:	fffff097          	auipc	ra,0xfffff
    80005f04:	4f0080e7          	jalr	1264(ra) # 800053f0 <fdalloc>
    80005f08:	fca42023          	sw	a0,-64(s0)
    80005f0c:	06054963          	bltz	a0,80005f7e <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f10:	4691                	li	a3,4
    80005f12:	fc440613          	addi	a2,s0,-60
    80005f16:	fd843583          	ld	a1,-40(s0)
    80005f1a:	70a8                	ld	a0,96(s1)
    80005f1c:	ffffb097          	auipc	ra,0xffffb
    80005f20:	73e080e7          	jalr	1854(ra) # 8000165a <copyout>
    80005f24:	02054063          	bltz	a0,80005f44 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005f28:	4691                	li	a3,4
    80005f2a:	fc040613          	addi	a2,s0,-64
    80005f2e:	fd843583          	ld	a1,-40(s0)
    80005f32:	0591                	addi	a1,a1,4
    80005f34:	70a8                	ld	a0,96(s1)
    80005f36:	ffffb097          	auipc	ra,0xffffb
    80005f3a:	724080e7          	jalr	1828(ra) # 8000165a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005f3e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f40:	06055563          	bgez	a0,80005faa <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005f44:	fc442783          	lw	a5,-60(s0)
    80005f48:	07f1                	addi	a5,a5,28
    80005f4a:	078e                	slli	a5,a5,0x3
    80005f4c:	97a6                	add	a5,a5,s1
    80005f4e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005f52:	fc042783          	lw	a5,-64(s0)
    80005f56:	07f1                	addi	a5,a5,28
    80005f58:	078e                	slli	a5,a5,0x3
    80005f5a:	00f48533          	add	a0,s1,a5
    80005f5e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005f62:	fd043503          	ld	a0,-48(s0)
    80005f66:	fffff097          	auipc	ra,0xfffff
    80005f6a:	a26080e7          	jalr	-1498(ra) # 8000498c <fileclose>
    fileclose(wf);
    80005f6e:	fc843503          	ld	a0,-56(s0)
    80005f72:	fffff097          	auipc	ra,0xfffff
    80005f76:	a1a080e7          	jalr	-1510(ra) # 8000498c <fileclose>
    return -1;
    80005f7a:	57fd                	li	a5,-1
    80005f7c:	a03d                	j	80005faa <sys_pipe+0x104>
    if(fd0 >= 0)
    80005f7e:	fc442783          	lw	a5,-60(s0)
    80005f82:	0007c763          	bltz	a5,80005f90 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005f86:	07f1                	addi	a5,a5,28
    80005f88:	078e                	slli	a5,a5,0x3
    80005f8a:	97a6                	add	a5,a5,s1
    80005f8c:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005f90:	fd043503          	ld	a0,-48(s0)
    80005f94:	fffff097          	auipc	ra,0xfffff
    80005f98:	9f8080e7          	jalr	-1544(ra) # 8000498c <fileclose>
    fileclose(wf);
    80005f9c:	fc843503          	ld	a0,-56(s0)
    80005fa0:	fffff097          	auipc	ra,0xfffff
    80005fa4:	9ec080e7          	jalr	-1556(ra) # 8000498c <fileclose>
    return -1;
    80005fa8:	57fd                	li	a5,-1
}
    80005faa:	853e                	mv	a0,a5
    80005fac:	70e2                	ld	ra,56(sp)
    80005fae:	7442                	ld	s0,48(sp)
    80005fb0:	74a2                	ld	s1,40(sp)
    80005fb2:	6121                	addi	sp,sp,64
    80005fb4:	8082                	ret
	...

0000000080005fc0 <kernelvec>:
    80005fc0:	7111                	addi	sp,sp,-256
    80005fc2:	e006                	sd	ra,0(sp)
    80005fc4:	e40a                	sd	sp,8(sp)
    80005fc6:	e80e                	sd	gp,16(sp)
    80005fc8:	ec12                	sd	tp,24(sp)
    80005fca:	f016                	sd	t0,32(sp)
    80005fcc:	f41a                	sd	t1,40(sp)
    80005fce:	f81e                	sd	t2,48(sp)
    80005fd0:	fc22                	sd	s0,56(sp)
    80005fd2:	e0a6                	sd	s1,64(sp)
    80005fd4:	e4aa                	sd	a0,72(sp)
    80005fd6:	e8ae                	sd	a1,80(sp)
    80005fd8:	ecb2                	sd	a2,88(sp)
    80005fda:	f0b6                	sd	a3,96(sp)
    80005fdc:	f4ba                	sd	a4,104(sp)
    80005fde:	f8be                	sd	a5,112(sp)
    80005fe0:	fcc2                	sd	a6,120(sp)
    80005fe2:	e146                	sd	a7,128(sp)
    80005fe4:	e54a                	sd	s2,136(sp)
    80005fe6:	e94e                	sd	s3,144(sp)
    80005fe8:	ed52                	sd	s4,152(sp)
    80005fea:	f156                	sd	s5,160(sp)
    80005fec:	f55a                	sd	s6,168(sp)
    80005fee:	f95e                	sd	s7,176(sp)
    80005ff0:	fd62                	sd	s8,184(sp)
    80005ff2:	e1e6                	sd	s9,192(sp)
    80005ff4:	e5ea                	sd	s10,200(sp)
    80005ff6:	e9ee                	sd	s11,208(sp)
    80005ff8:	edf2                	sd	t3,216(sp)
    80005ffa:	f1f6                	sd	t4,224(sp)
    80005ffc:	f5fa                	sd	t5,232(sp)
    80005ffe:	f9fe                	sd	t6,240(sp)
    80006000:	cc5fc0ef          	jal	ra,80002cc4 <kerneltrap>
    80006004:	6082                	ld	ra,0(sp)
    80006006:	6122                	ld	sp,8(sp)
    80006008:	61c2                	ld	gp,16(sp)
    8000600a:	7282                	ld	t0,32(sp)
    8000600c:	7322                	ld	t1,40(sp)
    8000600e:	73c2                	ld	t2,48(sp)
    80006010:	7462                	ld	s0,56(sp)
    80006012:	6486                	ld	s1,64(sp)
    80006014:	6526                	ld	a0,72(sp)
    80006016:	65c6                	ld	a1,80(sp)
    80006018:	6666                	ld	a2,88(sp)
    8000601a:	7686                	ld	a3,96(sp)
    8000601c:	7726                	ld	a4,104(sp)
    8000601e:	77c6                	ld	a5,112(sp)
    80006020:	7866                	ld	a6,120(sp)
    80006022:	688a                	ld	a7,128(sp)
    80006024:	692a                	ld	s2,136(sp)
    80006026:	69ca                	ld	s3,144(sp)
    80006028:	6a6a                	ld	s4,152(sp)
    8000602a:	7a8a                	ld	s5,160(sp)
    8000602c:	7b2a                	ld	s6,168(sp)
    8000602e:	7bca                	ld	s7,176(sp)
    80006030:	7c6a                	ld	s8,184(sp)
    80006032:	6c8e                	ld	s9,192(sp)
    80006034:	6d2e                	ld	s10,200(sp)
    80006036:	6dce                	ld	s11,208(sp)
    80006038:	6e6e                	ld	t3,216(sp)
    8000603a:	7e8e                	ld	t4,224(sp)
    8000603c:	7f2e                	ld	t5,232(sp)
    8000603e:	7fce                	ld	t6,240(sp)
    80006040:	6111                	addi	sp,sp,256
    80006042:	10200073          	sret
    80006046:	00000013          	nop
    8000604a:	00000013          	nop
    8000604e:	0001                	nop

0000000080006050 <timervec>:
    80006050:	34051573          	csrrw	a0,mscratch,a0
    80006054:	e10c                	sd	a1,0(a0)
    80006056:	e510                	sd	a2,8(a0)
    80006058:	e914                	sd	a3,16(a0)
    8000605a:	6d0c                	ld	a1,24(a0)
    8000605c:	7110                	ld	a2,32(a0)
    8000605e:	6194                	ld	a3,0(a1)
    80006060:	96b2                	add	a3,a3,a2
    80006062:	e194                	sd	a3,0(a1)
    80006064:	4589                	li	a1,2
    80006066:	14459073          	csrw	sip,a1
    8000606a:	6914                	ld	a3,16(a0)
    8000606c:	6510                	ld	a2,8(a0)
    8000606e:	610c                	ld	a1,0(a0)
    80006070:	34051573          	csrrw	a0,mscratch,a0
    80006074:	30200073          	mret
	...

000000008000607a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000607a:	1141                	addi	sp,sp,-16
    8000607c:	e422                	sd	s0,8(sp)
    8000607e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006080:	0c0007b7          	lui	a5,0xc000
    80006084:	4705                	li	a4,1
    80006086:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006088:	c3d8                	sw	a4,4(a5)
}
    8000608a:	6422                	ld	s0,8(sp)
    8000608c:	0141                	addi	sp,sp,16
    8000608e:	8082                	ret

0000000080006090 <plicinithart>:

void
plicinithart(void)
{
    80006090:	1141                	addi	sp,sp,-16
    80006092:	e406                	sd	ra,8(sp)
    80006094:	e022                	sd	s0,0(sp)
    80006096:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006098:	ffffc097          	auipc	ra,0xffffc
    8000609c:	8d2080e7          	jalr	-1838(ra) # 8000196a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800060a0:	0085171b          	slliw	a4,a0,0x8
    800060a4:	0c0027b7          	lui	a5,0xc002
    800060a8:	97ba                	add	a5,a5,a4
    800060aa:	40200713          	li	a4,1026
    800060ae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800060b2:	00d5151b          	slliw	a0,a0,0xd
    800060b6:	0c2017b7          	lui	a5,0xc201
    800060ba:	97aa                	add	a5,a5,a0
    800060bc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800060c0:	60a2                	ld	ra,8(sp)
    800060c2:	6402                	ld	s0,0(sp)
    800060c4:	0141                	addi	sp,sp,16
    800060c6:	8082                	ret

00000000800060c8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800060c8:	1141                	addi	sp,sp,-16
    800060ca:	e406                	sd	ra,8(sp)
    800060cc:	e022                	sd	s0,0(sp)
    800060ce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060d0:	ffffc097          	auipc	ra,0xffffc
    800060d4:	89a080e7          	jalr	-1894(ra) # 8000196a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800060d8:	00d5151b          	slliw	a0,a0,0xd
    800060dc:	0c2017b7          	lui	a5,0xc201
    800060e0:	97aa                	add	a5,a5,a0
  return irq;
}
    800060e2:	43c8                	lw	a0,4(a5)
    800060e4:	60a2                	ld	ra,8(sp)
    800060e6:	6402                	ld	s0,0(sp)
    800060e8:	0141                	addi	sp,sp,16
    800060ea:	8082                	ret

00000000800060ec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800060ec:	1101                	addi	sp,sp,-32
    800060ee:	ec06                	sd	ra,24(sp)
    800060f0:	e822                	sd	s0,16(sp)
    800060f2:	e426                	sd	s1,8(sp)
    800060f4:	1000                	addi	s0,sp,32
    800060f6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800060f8:	ffffc097          	auipc	ra,0xffffc
    800060fc:	872080e7          	jalr	-1934(ra) # 8000196a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006100:	00d5151b          	slliw	a0,a0,0xd
    80006104:	0c2017b7          	lui	a5,0xc201
    80006108:	97aa                	add	a5,a5,a0
    8000610a:	c3c4                	sw	s1,4(a5)
}
    8000610c:	60e2                	ld	ra,24(sp)
    8000610e:	6442                	ld	s0,16(sp)
    80006110:	64a2                	ld	s1,8(sp)
    80006112:	6105                	addi	sp,sp,32
    80006114:	8082                	ret

0000000080006116 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006116:	1141                	addi	sp,sp,-16
    80006118:	e406                	sd	ra,8(sp)
    8000611a:	e022                	sd	s0,0(sp)
    8000611c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000611e:	479d                	li	a5,7
    80006120:	06a7c863          	blt	a5,a0,80006190 <free_desc+0x7a>
    panic("free_desc 1");
  if(disk.free[i])
    80006124:	0001d717          	auipc	a4,0x1d
    80006128:	edc70713          	addi	a4,a4,-292 # 80023000 <disk>
    8000612c:	972a                	add	a4,a4,a0
    8000612e:	6789                	lui	a5,0x2
    80006130:	97ba                	add	a5,a5,a4
    80006132:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006136:	e7ad                	bnez	a5,800061a0 <free_desc+0x8a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006138:	00451793          	slli	a5,a0,0x4
    8000613c:	0001f717          	auipc	a4,0x1f
    80006140:	ec470713          	addi	a4,a4,-316 # 80025000 <disk+0x2000>
    80006144:	6314                	ld	a3,0(a4)
    80006146:	96be                	add	a3,a3,a5
    80006148:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000614c:	6314                	ld	a3,0(a4)
    8000614e:	96be                	add	a3,a3,a5
    80006150:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006154:	6314                	ld	a3,0(a4)
    80006156:	96be                	add	a3,a3,a5
    80006158:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000615c:	6318                	ld	a4,0(a4)
    8000615e:	97ba                	add	a5,a5,a4
    80006160:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006164:	0001d717          	auipc	a4,0x1d
    80006168:	e9c70713          	addi	a4,a4,-356 # 80023000 <disk>
    8000616c:	972a                	add	a4,a4,a0
    8000616e:	6789                	lui	a5,0x2
    80006170:	97ba                	add	a5,a5,a4
    80006172:	4705                	li	a4,1
    80006174:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006178:	0001f517          	auipc	a0,0x1f
    8000617c:	ea050513          	addi	a0,a0,-352 # 80025018 <disk+0x2018>
    80006180:	ffffc097          	auipc	ra,0xffffc
    80006184:	14e080e7          	jalr	334(ra) # 800022ce <wakeup>
}
    80006188:	60a2                	ld	ra,8(sp)
    8000618a:	6402                	ld	s0,0(sp)
    8000618c:	0141                	addi	sp,sp,16
    8000618e:	8082                	ret
    panic("free_desc 1");
    80006190:	00002517          	auipc	a0,0x2
    80006194:	68850513          	addi	a0,a0,1672 # 80008818 <syscalls+0x350>
    80006198:	ffffa097          	auipc	ra,0xffffa
    8000619c:	3a2080e7          	jalr	930(ra) # 8000053a <panic>
    panic("free_desc 2");
    800061a0:	00002517          	auipc	a0,0x2
    800061a4:	68850513          	addi	a0,a0,1672 # 80008828 <syscalls+0x360>
    800061a8:	ffffa097          	auipc	ra,0xffffa
    800061ac:	392080e7          	jalr	914(ra) # 8000053a <panic>

00000000800061b0 <virtio_disk_init>:
{
    800061b0:	1101                	addi	sp,sp,-32
    800061b2:	ec06                	sd	ra,24(sp)
    800061b4:	e822                	sd	s0,16(sp)
    800061b6:	e426                	sd	s1,8(sp)
    800061b8:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800061ba:	00002597          	auipc	a1,0x2
    800061be:	67e58593          	addi	a1,a1,1662 # 80008838 <syscalls+0x370>
    800061c2:	0001f517          	auipc	a0,0x1f
    800061c6:	f6650513          	addi	a0,a0,-154 # 80025128 <disk+0x2128>
    800061ca:	ffffb097          	auipc	ra,0xffffb
    800061ce:	976080e7          	jalr	-1674(ra) # 80000b40 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061d2:	100017b7          	lui	a5,0x10001
    800061d6:	4398                	lw	a4,0(a5)
    800061d8:	2701                	sext.w	a4,a4
    800061da:	747277b7          	lui	a5,0x74727
    800061de:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800061e2:	0ef71063          	bne	a4,a5,800062c2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800061e6:	100017b7          	lui	a5,0x10001
    800061ea:	43dc                	lw	a5,4(a5)
    800061ec:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061ee:	4705                	li	a4,1
    800061f0:	0ce79963          	bne	a5,a4,800062c2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800061f4:	100017b7          	lui	a5,0x10001
    800061f8:	479c                	lw	a5,8(a5)
    800061fa:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800061fc:	4709                	li	a4,2
    800061fe:	0ce79263          	bne	a5,a4,800062c2 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006202:	100017b7          	lui	a5,0x10001
    80006206:	47d8                	lw	a4,12(a5)
    80006208:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000620a:	554d47b7          	lui	a5,0x554d4
    8000620e:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006212:	0af71863          	bne	a4,a5,800062c2 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006216:	100017b7          	lui	a5,0x10001
    8000621a:	4705                	li	a4,1
    8000621c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000621e:	470d                	li	a4,3
    80006220:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006222:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006224:	c7ffe6b7          	lui	a3,0xc7ffe
    80006228:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000622c:	8f75                	and	a4,a4,a3
    8000622e:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006230:	472d                	li	a4,11
    80006232:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006234:	473d                	li	a4,15
    80006236:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006238:	6705                	lui	a4,0x1
    8000623a:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000623c:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006240:	5bdc                	lw	a5,52(a5)
    80006242:	2781                	sext.w	a5,a5
  if(max == 0)
    80006244:	c7d9                	beqz	a5,800062d2 <virtio_disk_init+0x122>
  if(max < NUM)
    80006246:	471d                	li	a4,7
    80006248:	08f77d63          	bgeu	a4,a5,800062e2 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000624c:	100014b7          	lui	s1,0x10001
    80006250:	47a1                	li	a5,8
    80006252:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006254:	6609                	lui	a2,0x2
    80006256:	4581                	li	a1,0
    80006258:	0001d517          	auipc	a0,0x1d
    8000625c:	da850513          	addi	a0,a0,-600 # 80023000 <disk>
    80006260:	ffffb097          	auipc	ra,0xffffb
    80006264:	a6c080e7          	jalr	-1428(ra) # 80000ccc <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006268:	0001d717          	auipc	a4,0x1d
    8000626c:	d9870713          	addi	a4,a4,-616 # 80023000 <disk>
    80006270:	00c75793          	srli	a5,a4,0xc
    80006274:	2781                	sext.w	a5,a5
    80006276:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006278:	0001f797          	auipc	a5,0x1f
    8000627c:	d8878793          	addi	a5,a5,-632 # 80025000 <disk+0x2000>
    80006280:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006282:	0001d717          	auipc	a4,0x1d
    80006286:	dfe70713          	addi	a4,a4,-514 # 80023080 <disk+0x80>
    8000628a:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    8000628c:	0001e717          	auipc	a4,0x1e
    80006290:	d7470713          	addi	a4,a4,-652 # 80024000 <disk+0x1000>
    80006294:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006296:	4705                	li	a4,1
    80006298:	00e78c23          	sb	a4,24(a5)
    8000629c:	00e78ca3          	sb	a4,25(a5)
    800062a0:	00e78d23          	sb	a4,26(a5)
    800062a4:	00e78da3          	sb	a4,27(a5)
    800062a8:	00e78e23          	sb	a4,28(a5)
    800062ac:	00e78ea3          	sb	a4,29(a5)
    800062b0:	00e78f23          	sb	a4,30(a5)
    800062b4:	00e78fa3          	sb	a4,31(a5)
}
    800062b8:	60e2                	ld	ra,24(sp)
    800062ba:	6442                	ld	s0,16(sp)
    800062bc:	64a2                	ld	s1,8(sp)
    800062be:	6105                	addi	sp,sp,32
    800062c0:	8082                	ret
    panic("could not find virtio disk");
    800062c2:	00002517          	auipc	a0,0x2
    800062c6:	58650513          	addi	a0,a0,1414 # 80008848 <syscalls+0x380>
    800062ca:	ffffa097          	auipc	ra,0xffffa
    800062ce:	270080e7          	jalr	624(ra) # 8000053a <panic>
    panic("virtio disk has no queue 0");
    800062d2:	00002517          	auipc	a0,0x2
    800062d6:	59650513          	addi	a0,a0,1430 # 80008868 <syscalls+0x3a0>
    800062da:	ffffa097          	auipc	ra,0xffffa
    800062de:	260080e7          	jalr	608(ra) # 8000053a <panic>
    panic("virtio disk max queue too short");
    800062e2:	00002517          	auipc	a0,0x2
    800062e6:	5a650513          	addi	a0,a0,1446 # 80008888 <syscalls+0x3c0>
    800062ea:	ffffa097          	auipc	ra,0xffffa
    800062ee:	250080e7          	jalr	592(ra) # 8000053a <panic>

00000000800062f2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800062f2:	7119                	addi	sp,sp,-128
    800062f4:	fc86                	sd	ra,120(sp)
    800062f6:	f8a2                	sd	s0,112(sp)
    800062f8:	f4a6                	sd	s1,104(sp)
    800062fa:	f0ca                	sd	s2,96(sp)
    800062fc:	ecce                	sd	s3,88(sp)
    800062fe:	e8d2                	sd	s4,80(sp)
    80006300:	e4d6                	sd	s5,72(sp)
    80006302:	e0da                	sd	s6,64(sp)
    80006304:	fc5e                	sd	s7,56(sp)
    80006306:	f862                	sd	s8,48(sp)
    80006308:	f466                	sd	s9,40(sp)
    8000630a:	f06a                	sd	s10,32(sp)
    8000630c:	ec6e                	sd	s11,24(sp)
    8000630e:	0100                	addi	s0,sp,128
    80006310:	8aaa                	mv	s5,a0
    80006312:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006314:	00c52c83          	lw	s9,12(a0)
    80006318:	001c9c9b          	slliw	s9,s9,0x1
    8000631c:	1c82                	slli	s9,s9,0x20
    8000631e:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006322:	0001f517          	auipc	a0,0x1f
    80006326:	e0650513          	addi	a0,a0,-506 # 80025128 <disk+0x2128>
    8000632a:	ffffb097          	auipc	ra,0xffffb
    8000632e:	8a6080e7          	jalr	-1882(ra) # 80000bd0 <acquire>
  for(int i = 0; i < 3; i++){
    80006332:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006334:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006336:	0001dc17          	auipc	s8,0x1d
    8000633a:	ccac0c13          	addi	s8,s8,-822 # 80023000 <disk>
    8000633e:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006340:	4b0d                	li	s6,3
    80006342:	a0ad                	j	800063ac <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006344:	00fc0733          	add	a4,s8,a5
    80006348:	975e                	add	a4,a4,s7
    8000634a:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    8000634e:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006350:	0207c563          	bltz	a5,8000637a <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006354:	2905                	addiw	s2,s2,1
    80006356:	0611                	addi	a2,a2,4 # 2004 <_entry-0x7fffdffc>
    80006358:	19690c63          	beq	s2,s6,800064f0 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    8000635c:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    8000635e:	0001f717          	auipc	a4,0x1f
    80006362:	cba70713          	addi	a4,a4,-838 # 80025018 <disk+0x2018>
    80006366:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006368:	00074683          	lbu	a3,0(a4)
    8000636c:	fee1                	bnez	a3,80006344 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    8000636e:	2785                	addiw	a5,a5,1
    80006370:	0705                	addi	a4,a4,1
    80006372:	fe979be3          	bne	a5,s1,80006368 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006376:	57fd                	li	a5,-1
    80006378:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000637a:	01205d63          	blez	s2,80006394 <virtio_disk_rw+0xa2>
    8000637e:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006380:	000a2503          	lw	a0,0(s4)
    80006384:	00000097          	auipc	ra,0x0
    80006388:	d92080e7          	jalr	-622(ra) # 80006116 <free_desc>
      for(int j = 0; j < i; j++)
    8000638c:	2d85                	addiw	s11,s11,1
    8000638e:	0a11                	addi	s4,s4,4
    80006390:	ff2d98e3          	bne	s11,s2,80006380 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006394:	0001f597          	auipc	a1,0x1f
    80006398:	d9458593          	addi	a1,a1,-620 # 80025128 <disk+0x2128>
    8000639c:	0001f517          	auipc	a0,0x1f
    800063a0:	c7c50513          	addi	a0,a0,-900 # 80025018 <disk+0x2018>
    800063a4:	ffffc097          	auipc	ra,0xffffc
    800063a8:	d9e080e7          	jalr	-610(ra) # 80002142 <sleep>
  for(int i = 0; i < 3; i++){
    800063ac:	f8040a13          	addi	s4,s0,-128
{
    800063b0:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800063b2:	894e                	mv	s2,s3
    800063b4:	b765                	j	8000635c <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800063b6:	0001f697          	auipc	a3,0x1f
    800063ba:	c4a6b683          	ld	a3,-950(a3) # 80025000 <disk+0x2000>
    800063be:	96ba                	add	a3,a3,a4
    800063c0:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800063c4:	0001d817          	auipc	a6,0x1d
    800063c8:	c3c80813          	addi	a6,a6,-964 # 80023000 <disk>
    800063cc:	0001f697          	auipc	a3,0x1f
    800063d0:	c3468693          	addi	a3,a3,-972 # 80025000 <disk+0x2000>
    800063d4:	6290                	ld	a2,0(a3)
    800063d6:	963a                	add	a2,a2,a4
    800063d8:	00c65583          	lhu	a1,12(a2)
    800063dc:	0015e593          	ori	a1,a1,1
    800063e0:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    800063e4:	f8842603          	lw	a2,-120(s0)
    800063e8:	628c                	ld	a1,0(a3)
    800063ea:	972e                	add	a4,a4,a1
    800063ec:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800063f0:	20050593          	addi	a1,a0,512
    800063f4:	0592                	slli	a1,a1,0x4
    800063f6:	95c2                	add	a1,a1,a6
    800063f8:	577d                	li	a4,-1
    800063fa:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800063fe:	00461713          	slli	a4,a2,0x4
    80006402:	6290                	ld	a2,0(a3)
    80006404:	963a                	add	a2,a2,a4
    80006406:	03078793          	addi	a5,a5,48
    8000640a:	97c2                	add	a5,a5,a6
    8000640c:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    8000640e:	629c                	ld	a5,0(a3)
    80006410:	97ba                	add	a5,a5,a4
    80006412:	4605                	li	a2,1
    80006414:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006416:	629c                	ld	a5,0(a3)
    80006418:	97ba                	add	a5,a5,a4
    8000641a:	4809                	li	a6,2
    8000641c:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006420:	629c                	ld	a5,0(a3)
    80006422:	97ba                	add	a5,a5,a4
    80006424:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006428:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    8000642c:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006430:	6698                	ld	a4,8(a3)
    80006432:	00275783          	lhu	a5,2(a4)
    80006436:	8b9d                	andi	a5,a5,7
    80006438:	0786                	slli	a5,a5,0x1
    8000643a:	973e                	add	a4,a4,a5
    8000643c:	00a71223          	sh	a0,4(a4)

  __sync_synchronize();
    80006440:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006444:	6698                	ld	a4,8(a3)
    80006446:	00275783          	lhu	a5,2(a4)
    8000644a:	2785                	addiw	a5,a5,1
    8000644c:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006450:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006454:	100017b7          	lui	a5,0x10001
    80006458:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000645c:	004aa783          	lw	a5,4(s5)
    80006460:	02c79163          	bne	a5,a2,80006482 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006464:	0001f917          	auipc	s2,0x1f
    80006468:	cc490913          	addi	s2,s2,-828 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    8000646c:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000646e:	85ca                	mv	a1,s2
    80006470:	8556                	mv	a0,s5
    80006472:	ffffc097          	auipc	ra,0xffffc
    80006476:	cd0080e7          	jalr	-816(ra) # 80002142 <sleep>
  while(b->disk == 1) {
    8000647a:	004aa783          	lw	a5,4(s5)
    8000647e:	fe9788e3          	beq	a5,s1,8000646e <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006482:	f8042903          	lw	s2,-128(s0)
    80006486:	20090713          	addi	a4,s2,512
    8000648a:	0712                	slli	a4,a4,0x4
    8000648c:	0001d797          	auipc	a5,0x1d
    80006490:	b7478793          	addi	a5,a5,-1164 # 80023000 <disk>
    80006494:	97ba                	add	a5,a5,a4
    80006496:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    8000649a:	0001f997          	auipc	s3,0x1f
    8000649e:	b6698993          	addi	s3,s3,-1178 # 80025000 <disk+0x2000>
    800064a2:	00491713          	slli	a4,s2,0x4
    800064a6:	0009b783          	ld	a5,0(s3)
    800064aa:	97ba                	add	a5,a5,a4
    800064ac:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800064b0:	854a                	mv	a0,s2
    800064b2:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800064b6:	00000097          	auipc	ra,0x0
    800064ba:	c60080e7          	jalr	-928(ra) # 80006116 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800064be:	8885                	andi	s1,s1,1
    800064c0:	f0ed                	bnez	s1,800064a2 <virtio_disk_rw+0x1b0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800064c2:	0001f517          	auipc	a0,0x1f
    800064c6:	c6650513          	addi	a0,a0,-922 # 80025128 <disk+0x2128>
    800064ca:	ffffa097          	auipc	ra,0xffffa
    800064ce:	7ba080e7          	jalr	1978(ra) # 80000c84 <release>
}
    800064d2:	70e6                	ld	ra,120(sp)
    800064d4:	7446                	ld	s0,112(sp)
    800064d6:	74a6                	ld	s1,104(sp)
    800064d8:	7906                	ld	s2,96(sp)
    800064da:	69e6                	ld	s3,88(sp)
    800064dc:	6a46                	ld	s4,80(sp)
    800064de:	6aa6                	ld	s5,72(sp)
    800064e0:	6b06                	ld	s6,64(sp)
    800064e2:	7be2                	ld	s7,56(sp)
    800064e4:	7c42                	ld	s8,48(sp)
    800064e6:	7ca2                	ld	s9,40(sp)
    800064e8:	7d02                	ld	s10,32(sp)
    800064ea:	6de2                	ld	s11,24(sp)
    800064ec:	6109                	addi	sp,sp,128
    800064ee:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800064f0:	f8042503          	lw	a0,-128(s0)
    800064f4:	20050793          	addi	a5,a0,512
    800064f8:	0792                	slli	a5,a5,0x4
  if(write)
    800064fa:	0001d817          	auipc	a6,0x1d
    800064fe:	b0680813          	addi	a6,a6,-1274 # 80023000 <disk>
    80006502:	00f80733          	add	a4,a6,a5
    80006506:	01a036b3          	snez	a3,s10
    8000650a:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    8000650e:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006512:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006516:	7679                	lui	a2,0xffffe
    80006518:	963e                	add	a2,a2,a5
    8000651a:	0001f697          	auipc	a3,0x1f
    8000651e:	ae668693          	addi	a3,a3,-1306 # 80025000 <disk+0x2000>
    80006522:	6298                	ld	a4,0(a3)
    80006524:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006526:	0a878593          	addi	a1,a5,168
    8000652a:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000652c:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000652e:	6298                	ld	a4,0(a3)
    80006530:	9732                	add	a4,a4,a2
    80006532:	45c1                	li	a1,16
    80006534:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006536:	6298                	ld	a4,0(a3)
    80006538:	9732                	add	a4,a4,a2
    8000653a:	4585                	li	a1,1
    8000653c:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006540:	f8442703          	lw	a4,-124(s0)
    80006544:	628c                	ld	a1,0(a3)
    80006546:	962e                	add	a2,a2,a1
    80006548:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    8000654c:	0712                	slli	a4,a4,0x4
    8000654e:	6290                	ld	a2,0(a3)
    80006550:	963a                	add	a2,a2,a4
    80006552:	058a8593          	addi	a1,s5,88
    80006556:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006558:	6294                	ld	a3,0(a3)
    8000655a:	96ba                	add	a3,a3,a4
    8000655c:	40000613          	li	a2,1024
    80006560:	c690                	sw	a2,8(a3)
  if(write)
    80006562:	e40d1ae3          	bnez	s10,800063b6 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006566:	0001f697          	auipc	a3,0x1f
    8000656a:	a9a6b683          	ld	a3,-1382(a3) # 80025000 <disk+0x2000>
    8000656e:	96ba                	add	a3,a3,a4
    80006570:	4609                	li	a2,2
    80006572:	00c69623          	sh	a2,12(a3)
    80006576:	b5b9                	j	800063c4 <virtio_disk_rw+0xd2>

0000000080006578 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006578:	1101                	addi	sp,sp,-32
    8000657a:	ec06                	sd	ra,24(sp)
    8000657c:	e822                	sd	s0,16(sp)
    8000657e:	e426                	sd	s1,8(sp)
    80006580:	e04a                	sd	s2,0(sp)
    80006582:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006584:	0001f517          	auipc	a0,0x1f
    80006588:	ba450513          	addi	a0,a0,-1116 # 80025128 <disk+0x2128>
    8000658c:	ffffa097          	auipc	ra,0xffffa
    80006590:	644080e7          	jalr	1604(ra) # 80000bd0 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006594:	10001737          	lui	a4,0x10001
    80006598:	533c                	lw	a5,96(a4)
    8000659a:	8b8d                	andi	a5,a5,3
    8000659c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000659e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800065a2:	0001f797          	auipc	a5,0x1f
    800065a6:	a5e78793          	addi	a5,a5,-1442 # 80025000 <disk+0x2000>
    800065aa:	6b94                	ld	a3,16(a5)
    800065ac:	0207d703          	lhu	a4,32(a5)
    800065b0:	0026d783          	lhu	a5,2(a3)
    800065b4:	06f70163          	beq	a4,a5,80006616 <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800065b8:	0001d917          	auipc	s2,0x1d
    800065bc:	a4890913          	addi	s2,s2,-1464 # 80023000 <disk>
    800065c0:	0001f497          	auipc	s1,0x1f
    800065c4:	a4048493          	addi	s1,s1,-1472 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800065c8:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800065cc:	6898                	ld	a4,16(s1)
    800065ce:	0204d783          	lhu	a5,32(s1)
    800065d2:	8b9d                	andi	a5,a5,7
    800065d4:	078e                	slli	a5,a5,0x3
    800065d6:	97ba                	add	a5,a5,a4
    800065d8:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800065da:	20078713          	addi	a4,a5,512
    800065de:	0712                	slli	a4,a4,0x4
    800065e0:	974a                	add	a4,a4,s2
    800065e2:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800065e6:	e731                	bnez	a4,80006632 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800065e8:	20078793          	addi	a5,a5,512
    800065ec:	0792                	slli	a5,a5,0x4
    800065ee:	97ca                	add	a5,a5,s2
    800065f0:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800065f2:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800065f6:	ffffc097          	auipc	ra,0xffffc
    800065fa:	cd8080e7          	jalr	-808(ra) # 800022ce <wakeup>

    disk.used_idx += 1;
    800065fe:	0204d783          	lhu	a5,32(s1)
    80006602:	2785                	addiw	a5,a5,1
    80006604:	17c2                	slli	a5,a5,0x30
    80006606:	93c1                	srli	a5,a5,0x30
    80006608:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    8000660c:	6898                	ld	a4,16(s1)
    8000660e:	00275703          	lhu	a4,2(a4)
    80006612:	faf71be3          	bne	a4,a5,800065c8 <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006616:	0001f517          	auipc	a0,0x1f
    8000661a:	b1250513          	addi	a0,a0,-1262 # 80025128 <disk+0x2128>
    8000661e:	ffffa097          	auipc	ra,0xffffa
    80006622:	666080e7          	jalr	1638(ra) # 80000c84 <release>
}
    80006626:	60e2                	ld	ra,24(sp)
    80006628:	6442                	ld	s0,16(sp)
    8000662a:	64a2                	ld	s1,8(sp)
    8000662c:	6902                	ld	s2,0(sp)
    8000662e:	6105                	addi	sp,sp,32
    80006630:	8082                	ret
      panic("virtio_disk_intr status");
    80006632:	00002517          	auipc	a0,0x2
    80006636:	27650513          	addi	a0,a0,630 # 800088a8 <syscalls+0x3e0>
    8000663a:	ffffa097          	auipc	ra,0xffffa
    8000663e:	f00080e7          	jalr	-256(ra) # 8000053a <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
