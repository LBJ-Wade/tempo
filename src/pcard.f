c      $Id$
	subroutine pcard(card,mode,zawgt,deltat,fut,dphase,sigm,offset,
     +  jdcatc,pha1,pha2,efac,emin,equad,jits,lu,track,trkmax,search)

C  Decodes special cards embedded in the arrival-time file, and takes
C  appropriate action.

	implicit REAL*8 (A-H,O-Z)
	character*80 CARD
	logical OFFSET,JDCATC,track,search
	include 'dim.h'
	include 'acom.h'

	if (card(1:2).ne.'C ' .and. card(1:2).ne.'# ') goto 14
C Don't bother printing it unless this is the first iteration
	if (JITS .EQ. 0) WRITE(31,1012) CARD
1012	format(A80)
	go to 200

14	continue
	parm = 0.
	do 17 i = index(card,' ')+1, 70
	    if (card(i:i).ne.' ') then
		read(card(i:i+9),fmt='(f10.0)') parm
		goto 18
	    endif
17	    continue
18	continue

c	if (card(5:5).eq.' ') then
c	    read(card(6:),fmt='(f11.0)') parm
c	  else
c	    read(card(7:),fmt='(f10.0)') parm
c	  endif

	IF(CARD(1:4).NE.'TIME') GO TO 20

C  FOR 'TIME' CARDS, THE PARM IS CONVERTED FROM SECONDS TO DAYS AND ADDED
C  TO ALL SUBSEQUENT ARRIVAL TIMES.

	DELTAT=DELTAT+PARM
	WRITE(31,1015) N,FUT,CARD(1:6),PARM,DELTAT
1015	FORMAT(I5,F11.4,1X,A6,13X,2F11.6)
	go to 200

20    IF(CARD(1:4).NE.'PHAS') GO TO 22

C  FOR 'PHASE' CARDS, THE PARM (IN PERIODS) IS ADDED TO ALL SUBSEQUENT
C  PRE-FIT RESIDUALS.

	DPHASE=DPHASE+PARM
	WRITE(31,1020) N,FUT,CARD(1:6),PARM,DPHASE
1020	FORMAT(I5,F11.4,1X,A6,33X,2F11.6)
	go to 200

22	IF(CARD(1:4).NE.'SIGM') GO TO 24
	SIGM=PARM
	WRITE(31,1022) N,FUT,CARD(1:6),PARM
1022	FORMAT(I5,F11.4,1X,A6,F13.3)
	MODE=1
	go to 200

24	IF(CARD(1:4).NE.'MODE') GO TO 25
	MODE=1
	WRITE(31,1024) N,FUT,CARD(1:6)
1024	FORMAT(I5,F11.4,1X,A6)
	go to 200

25	IF(CARD(1:4).NE.'DITH') GO TO 26
	dither=parm
	WRITE(31,1025) N,CARD(1:6),dither
1025	FORMAT(I5,1X,A6,f8.2,' us.')
	go to 200

26	if(CARD(1:4) .NE. 'PHA1') goto 27
	PHA1 = PARM
	write (31,1026) N, CARD(1:6), PHA1
1026	format (I5,1X,A6,F8.2)
	go to 200

27	if(CARD(1:4) .NE. 'PHA2') goto 28
	PHA2 = PARM
	write (31,1026) N, CARD(1:6), PHA2
	go to 200

28	if(card(1:4).ne.'ZAWG') goto 29
	write(31,1028) 
1028	format('ZA weighting for PSR 1913+16 enabled')
	zawgt=parm
	go to 200

29	if(CARD(1:4) .NE. 'FMIN') goto 30
	fmin = PARM
	write (31,1029) N, CARD(1:6),fmin
1029	format(i5,1x,a6,f8.2,' MHz.')
	go to 200

30	if(CARD(1:4) .NE. 'FMAX') goto 50
	fmax = PARM
	write (31,1029) N, CARD(1:6),fmax
	go to 200

50	if(CARD(1:4) .NE. 'JUMP') goto 60

C  'JUMP' CARD: TURN OFFSET ON (OR OFF) AND PROCESS ACCORDINGLY.

	IF(OFFSET) GO TO 55
C  N.B.: at this point, OFFSET=.F. means an offset is currently
C  in effect.  So we'll now turn it off:
	X(60+NGLT*NGLP+NXOFF)=0.D0
	XJDOFF(2,NXOFF)=FUT
	OFFSET=.TRUE.
	WRITE(31,1050) N,FUT,CARD(1:6),NXOFF
1050	FORMAT(I5,F11.4,1X,A6,I2,' OFF')
	go to 200

55	OFFSET=.FALSE.
	IF(NXOFF.GE.NJUMP) WRITE(31,1100) N,FUT,CARD(1:6)
1100	FORMAT(I5,F11.4,1X,A6,'  **** TOO MANY OFFSETS ****')
	IF(NXOFF.GE.NJUMP) STOP 'PCARD 55'
	NXOFF=NXOFF+1
	JDCATC=.TRUE.
	X(60+NGLT*NGLP+NXOFF)=-1.D0
	NFIT(60+NGLT*NGLP+NXOFF)=1
	NPARAM=NPARAM+1
	MFIT(NPARAM)=60+NGLT*NGLP+NXOFF
	WRITE(31,1032) N,FUT,CARD(1:6),NXOFF
1032	FORMAT(I5,F11.4,1X,A6,I2,'  ON')
	go to 200

60	IF(CARD(1:4).NE.'EFAC') go to 70
	efac = PARM
	write (31,1060) N, CARD(1:6),efac
1060	format(i5,1x,a6,f8.2)
	go to 200
	
70	IF(CARD(1:4).NE.'EMIN') go to 75
	emin = PARM
	write (31,1060) N, CARD(1:6),emin
	go to 200

75	IF(CARD(1:4).ne.'EQUA') goto 80
	equad = PARM
	write (31,1060) N, CARD(1:6),equad
	go to 200

80	IF(CARD(1:4).NE.'SIM ') go to 90
	sim=.true.
	dither = PARM
	write (31,1060) N, CARD(1:6),dither
	go to 200

90	if(card(1:4).ne.'SKIP') go to 100
	do 92 i=1,999999
	read(lu,1090,end=94) card
1090	format(a80)
	if(card(1:4).eq.'NOSK') go to 96
92	continue
94	print*,'Expected NOSKIP command not found'
	stop
96	write(31,1096) i-1
1096	format(i6,' lines of input file skipped.')
	go to 200

100	if(card(1:4).ne.'SEAR') go to 120
	write(31,1060) N,CARD(1:6),parm
	search=.true.
	go to 121		!Now set trkmax=parm and track=.true.

120	if(card(1:4).ne.'TRAC') go to 130
	write(31,1060) N,CARD(1:6),parm
121	track=.true.
	trkmax=parm
	if(trkmax.eq.0.d0) trkmax=9999.d0
	goto 200

130	if (card(1:3).ne.'TOA') goto 999
c       don't do anything -- just skip over this card
	goto 200
		

200	return

999	print*,'*** PCARD: unknown command ',card(1:6)
	stop
	END