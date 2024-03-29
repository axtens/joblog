MODULE JobLog;

    FROM DATETIME IMPORT GetDate, GetTime;
    FROM ASCII IMPORT CR,LF;
    FROM NumberConversion IMPORT CardToString, StringToCard;
    FROM Strings IMPORT Length, Copy, Assign, Append;
    FROM Files IMPORT Create, NORMAL,
                      Write, Open, Close, Seek, SEEKEND, IO, FileStatus;
    FROM System IMPORT Terminate, GetArg;
    FROM InOut IMPORT WriteLine, WriteString, WriteCard, WriteLn;
    FROM SYSTEM IMPORT ADR;
    FROM XString IMPORT Exact, ExactCaseless, UpperCase, LeftTrim;

    CONST
        jMax = 500;
        rMax = 500;
        sMax = 500;
        SPACE = 40C;
        NULL  = 0C;
        TILDE = '~';
        COLON = ':';
(*        JOBLOG= 'c:\bruce\joblog.dat'*)
        JOBLOG = 'joblog.dat';
        FILLER= 15;
        SLASH = '/';

    TYPE
        trLog = RECORD
                    bStartStop : BOOLEAN;
                    sJob       : ARRAY [0..20] OF CHAR;
                    sActivDate : ARRAY [0..7] OF CHAR;
                    sStartTime : ARRAY [0..4] OF CHAR;
                    sDuration  : ARRAY [0..2] OF CHAR;
                    sCRLF      : ARRAY [0..1] OF CHAR
                  END;

    VAR
        rJobLog : trLog;
        sMinutes,
        sTime,
        sDate,
        sFacility,
        sState : ARRAY [0..20] OF CHAR;

        cCnt    : CARDINAL;

        bStart,
        bStop   : BOOLEAN;

        lcLength: LONGCARD;

        iBuff   : INTEGER;

    PROCEDURE TimeToMinutes( sTim : ARRAY OF CHAR; VAR sMin : ARRAY OF CHAR);
        VAR
            sHr, sMn, sSc : ARRAY [0..1] OF CHAR;
            cHr, cMn, cSc : CARDINAL;
            cMinutes      : CARDINAL;
            bFlag         : BOOLEAN;
        BEGIN
            Copy(sTim,0,2,sHr);
            Copy(sTim,3,2,sMn);
            Copy(sTim,6,2,sSc);
            StringToCard(sHr,cHr,bFlag);
            StringToCard(sMn,cMn,bFlag);
            StringToCard(sSc,cSc,bFlag);
            cMinutes := cHr * 60 + cMn;
            CardToString(cMinutes,sMin,5);
        END TimeToMinutes;


    PROCEDURE Help();
        BEGIN
            WriteLine("Syntax: JOBLOG <<jobname> <START|STOP> | /REP [outputfile]>");
        END Help;

    PROCEDURE Fail( cParam : CARDINAL);
        BEGIN
            WriteString("Fail ");
            WriteCard(cParam,5);
            WriteLn
        END Fail;


    PROCEDURE Report();
        BEGIN
            WriteLine("REPORT")
        END Report;

    BEGIN
        GetArg( sFacility, cCnt);
        IF cCnt = 0 THEN
            Help();
            Terminate(0)
        END;
        IF sFacility[0] = SLASH THEN
            Copy(sFacility,1,3,sFacility);
            IF ExactCaseless(sFacility,"REP") THEN
                Report()
            ELSE
                Help()
            END;
            Terminate(0);
        ELSE
            GetArg( sState, cCnt);
            IF cCnt = 0 THEN
                Help();
                Terminate(0)
            END;
        END;
        UpperCase(sFacility);
        UpperCase(sState);
        Copy(sState,0,3,sState);
        bStart := Exact(sState,"STA");
        bStop  := Exact(sState,"STO");
        IF (NOT bStart) AND (NOT bStop ) THEN
            Help();
            Terminate(0)
        END;
        Open(iBuff,JOBLOG,IO);
        IF FileStatus <> 0 THEN
            IF FileStatus = 2 THEN (* file not found *)
                Create(iBuff,JOBLOG,NORMAL);
                IF FileStatus # 0 THEN
                    Fail(FileStatus);
                    Terminate(0)
                END
            END
        END;
        Seek(iBuff,SEEKEND,lcLength);
        GetTime(sTime);
        GetDate(sDate);
        TimeToMinutes(sTime,sMinutes);
        LeftTrim(sMinutes);
        IF bStart THEN
            WriteString("Starting ");
        ELSE
            WriteString("Stopping ");
        END;
        WriteString(sFacility);
        WriteString(SPACE);
        WriteString(sDate);
        WriteString(SPACE);
        WriteString(sTime);
        WriteString(SPACE);
        WriteString(sMinutes);
        WriteLn;
        WITH rJobLog DO
            bStartStop := bStart;
            Assign(sFacility,sJob);
            Assign(sDate,sActivDate);
            Assign(sTime,sStartTime);
            Assign(sMinutes,sDuration);
            sCRLF[0] := CR;
            sCRLF[1] := LF

        END;
        Write(iBuff,ADR(rJobLog),SIZE(rJobLog),cCnt);
        Close(iBuff)


    END JobLog.



(*
        joblogmax=500
        reportmax=200
        startsmax=300

        NULL=""
        TILDE="~"
        COLON=":"
        JOBLOG="C:\BRUCE\JOBLOG.DAT"
        FILLER=15

        opt=NULL

        P1=argv (1)
        P2=argv (2)
        if left(P1,1)="/"
        then
            opt=mid(P1,2,3)
            ucaserec=opt
            gosub [ucase]
            opt=ucaserec
            if opt="REP"
            then
                goto [rep]
            else
                goto [help]
            end if
        end if

        ucaserec=P1
        gosub [ucase]
        jobname = ucaserec
*        jobname = P1
        ucaserec=left(P2,3)
        gosub [ucase]
        jobstate= ucaserec

        state = 0

        if jobstate = "STA"
        then
           state = 1
           goto [ok]
        end if

        if jobstate = "STO"
        then
           state = 2
           goto [ok]
        end if

        goto [help]


[ok]   joblog = JOBLOG
       if access(joblog) = 0
       then
           open #1, "w", joblog
       else
           open #1, "a", joblog
       end if
       times=time()
       timer=left(times,2)*60+mid(times,4,2)*1
*print timer
       if state=1
       then
           print #1,"Starting~";jobname;"~";date();"~";timer
           print "Starting ";jobname;" at ";date();" ";timer
           goto [end]
       end if
       if state=2
       then
           print #1,"Stopping~";jobname;"~";date();"~";timer
           print "Stopping ";jobname;" at ";date();" ";timer
           goto [end]
       end if
[end]  close #1
       end

[help] print "Syntax: JOBLOG <<jobname> <START|STOP> | /REP [outputfile]>"
       end

[rep]
        fileio = 0
        if P2 <> NULL
        then
            repfile = P2
            fileio = 1
        else
            repfile = NULL
            type lookup ("dos")
            fileio = 0
        end if

        dim joblog(joblogmax)
        for i = 1 to joblogmax
            joblog(i)=NULL
        next i

        dim reports(reportmax,2)
        for i = 1 to reportmax
            reports(i,1)=NULL
            reports(i,2)=NULL
        next i

        dim starts(startsmax,2)
        for i = 1 to startsmax
            starts(i,1)=NULL
            starts(i,1)=NULL
        next i

        nReport = 0
        nStart = 0
        nJobs = 0

        if access(JOBLOG)=0
        then
            print "Cannot open "+JOBLOG
            end
        end if

        open #1, "r", JOBLOG
        if fileio
        then
            open #2, "w", repfile
        end if
[1]     if not eof(1)
        then
            line input #1, rec
            nJobs = nJobs + 1
            joblog(nJobs)=rec
            goto [1]
        end if
        close #1

        for i = 1 to nJobs
            rec = joblog(i)
            ss=parse(rec,NULL,NULL,NULL,TILDE)
            projname=parse(rec,NULL,NULL,NULL,TILDE)
            dt=parse(rec,NULL,NULL,NULL,TILDE)
            tm=rec
            projname=projname+space(FILLER-len(projname))+dt
            if ss="Starting"
            then
                gosub [add]
            else
                gosub [scan]
            end if
        next i

* REPORT UNCLOSED ACCOUNTS
        cls
        if fileio
        then
            print #2,"Unclosed Accounts"
            print #2,
        else
            print "Unclosed Accounts"
            print
        end if

        for i = 1 to nStart
            if starts(i,1) <> NULL
            then
                if fileio
                then
                    print #2, "No terminator for "+starts(i,1)
                else
                    print "No terminator for "+starts(i,1)
                end if
            end if
        next i
        if fileio then print #2,"" else print

* REPORT FINAL TOTALS
        cls
        if fileio
        then
            print #2,"Final Totals"
            print #2,
        else
            print "Final Total"
            print
        end if

        for i = 1 to nReport
            proj = reports(i,1)
            mins = reports(i,2)

            hours = mins \ 60
            minutes = mins mod 60

            roundmins = mins - ((mins \ 60) * 60)
            roundfactor = roundmins \ 30
            if roundfactor = 0
            then
                if roundmins > 15 then rounding = 30 else rounding = 0
                else
                if roundmins > 45 then rounding = 60 else rounding = 30
            end if
            roundmins = ((mins \ 60)*60) + rounding




            if fileio
            then
                print #2, proj+space(2)+hours+" hours "+minutes+" minutes (";mins;")[";roundmins;"]"
            else
                print proj+space(2)+hours+" hours "+minutes+" minutes (";mins;")[";roundmins;"]"
            end if
        next i
        if fileio then print #2,"" else print
        if fileio then close #2
        end


[add]   nStart = nStart + 1
        starts(nStart,1)=projname
        starts(nStart,2)=tm
        return

[scan]  flag = 0
        for j = 1 to nStart
            if projname = starts(j,1)
            then
                flag = 1

                *starttime = starts(j,2)
                *starthh = parse(starttime,NULL,NULL,NULL,COLON)
                *startmm = parse(starttime,NULL,NULL,NULL,COLON)
                *startmins = starthh*60+startmm
                startmins=starts(j,2)

                *endtime = tm
                *endhh   = parse(tm,NULL,NULL,NULL,COLON)
                *endmm   = parse(tm,NULL,NULL,NULL,COLON)
                *endmins = endhh*60+endmm
                stopmins=tm


*                print startmins,stopmins

                gosub [ldrep]
                gosub [no more starts]
                goto [exit]
            end if
        next j
        if flag = 0 then print "Cannot find starter for "+projname
[exit]  return

[no more starts]
        for kk = j+1 to nStart
            if projname = starts(kk,1)
            then
                starts(kk,1)=NULL
                starts(kk,2)=NULL
            end if
        next kk
        return


[ldrep] for k = 1 to nReport
            if projname = reports(k,1)
            then
                reports(k,2)=reports(k,2)+(stopmins-startmins)

                goto [ldxit]
            end if
        next k
        nReport = nReport + 1
        reports(nReport,1)=projname
        reports(nReport,2)=stopmins-startmins

[ldxit] starts(j,1)=NULL
        starts(j,2)=NULL

        return
[ucase]
        ucaselen=len(ucaserec)
        for ui=1 to ucaselen
            c=mid(ucaserec,ui,1)
            if c>="a" and c<="z"
            then
                ucaserec=strovr(ucaserec,ui,chr( asc(c) - 32))
            end if
        next ui
        return
*)
