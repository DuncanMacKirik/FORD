{D-}
{$B-,F-}
{$M $1400, 0, 1024}

program FORD;

uses
  Dos;

var
  Int21h, P: pointer;
  A: pointer absolute 0:$84;
  B: pointer absolute 0:$184;
  R: Registers;
  ProgramName, PNB: String[80];
  I, J, Occ, RL: Byte;
  L0, L1, L2: Byte;
  OldDS, OldDX, LN: Word;
  S: String;
  Act: Boolean;
  INI: Text;

  Name, Run: String;


Type TCommand = (Replace, RPlus, RAll, Execute);
     PStep = ^TStep;
     TStep = record
                   Cmd: TCommand;
                   Str1, Str2: String[80];
                   Next: PStep;
             end;

var First, Current, Last: PStep;

{$F+}
Procedure My21h(Flags, CS, IP, AX, BX, CX, DX, SI, DI, DS, ES, BP: Word); interrupt;

procedure TruncPath; near;
begin
    I := Byte(ProgramName[0]);
    while (I > 0) and (ProgramName[I] <> ':') and (ProgramName[I] <> '\') do Dec(I);
    J := Byte(ProgramName[0]) - I;
    Inc(I);
    Move(ProgramName[I], ProgramName[1], J);
    ProgramName[0] := Char(J);
end;

procedure TruncExt; near;
begin
    ProgramName[0] := Char(Pos('.', ProgramName) - 1);
end;

(* MY21H BODY *)
Begin
  Act := (Hi(AX) = $3D) or (Hi(AX) = $4B);
  OldDS:=DS;
  OldDX:=DX;
  if Act then
{     Process;}
  begin
    Move(Ptr(DS, DX)^, ProgramName[1], 80);
    ProgramName[0] := #$FF;
    ProgramName[0] := Char(Pos(#0, ProgramName) - 1);
    For I := 1 to Byte(ProgramName[0]) do
      ProgramName[I] := UpCase(ProgramName[I]);
    PNB := ProgramName;
    If ProgramName[0] = #$FF then ProgramName[0] := Char(Pos(#0, ProgramName) - 1);

    Current := First;
    While Current <> nil do
    begin
         With Current^ do
         begin
              Occ := Pos(Str1, ProgramName);
              If Occ <> 0 then
              begin
                   L0 := Byte(ProgramName[0]);
                   L1 := Byte(Str1[0]);
                   L2 := Byte(Str2[0]);
                   If (Hi(AX) = $4B) and (Cmd = Execute) then
                   begin
                        S := Str2;
                        Inc(S[0]);
                        S[Byte(S[0])] := #0;
                   end
                   else
                   If (Hi(AX) = $3D) and (Cmd <> Execute) then
                   Case Cmd of
               Replace: begin
                             Move(ProgramName[1],S[1],Occ-1);
                             Move(Str2[1], S[Occ], L2);
                             Move(ProgramName[Occ+L1],
                                  S[Occ+L2], Length(ProgramName)-Occ-L1+1);
                             S[0] := Char(L0-L1+L2+2);
                             S[Byte(S[0])] := #0;
                        end;
                 RPlus: begin
                             Move(Str2[1], S[1], L2);
                             Move(ProgramName[Occ+L1], S[L2+1], L0-L1-Occ+1);
                             S[0] := Char(L0-L1+L2-Occ+2);
                             S[Byte(S[0])] := #0;
                        end;
                  RAll: begin
                             S := Str2;
                             Inc(S[0]);
                             S[Byte(S[0])] := #0;
                        end;
                   end;

                   DS:=Seg(S);
                   DX:=Ofs(S[1]);
              end;
         end;
         Current := Current^.Next;
    end;
  end;
{  Old21h;}

(* OLD INT21H *)
  R.Flags := Flags; R.AX := AX;
  R.BX := BX; R.CX := CX; R.DX := DX; R.SI := SI;
  R.DI := DI; R.DS := DS; R.ES := ES; R.BP := BP;
  inline($FA); P := B; B := Int21h; inline($FB);
  Intr($61, R);
  inline($FA); B := P; inline($FB);
  Flags := R.Flags; AX := R.AX;
  BX := R.BX; CX := R.CX; DX := R.DX; SI := R.SI;
  DI := R.DI; DS := R.DS; ES := R.ES; BP := R.BP;
(* OLD INT21H *)

{  Restore;}
     If Act then
     begin
          DS := OldDS;
          DX := OldDX;
     end;
End;
(* MY21H BODY *)
{$F-}



(* SERVICE PROCS *)

Procedure Error(ErrMsg: String);
begin
     WriteLn(ErrMsg);
     WriteLn;
     Halt;
end;

Procedure Set21h;
begin
  SwapVectors;
  inline($FA);
  Int21h := A;
  A := @My21h;
  inline($FB);
end;

Procedure Restore21h;
begin
  inline($FA);
  A := Int21h;
  inline($FB);
  SwapVectors;
end;

Procedure INI_Sample;
begin
      WriteLn('Creating sample .INI file...');
      Assign(INI, 'FORD.INI');
{$I-}
      Rewrite(INI); If IOResult <> 0 then Error('Cannot create FORD.INI');
{$I+}
      WriteLn(INI,'; Sample .INI file for FORD 2.0');
      WriteLn(INI,'; Copyright (c) Duncan MacKirik, 1999');
      WriteLn(INI);
      WriteLn(INI,'; <-- When a line starts with this character ('';''), it is treated as COMMENT');
      WriteLn(INI,'; Blank lines are allowed.');
      WriteLn(INI,'; All spaces between '':'' or '','' and parameter strings are cut.');
      WriteLn(INI);
      WriteLn(INI,'; Program name to be displayed.');
      WriteLn(INI,'Name: THE GAME');
      WriteLn(INI);
      WriteLn(INI,'; Syntax:');
      WriteLn(INI,';   Replace:str1,str2');
      WriteLn(INI,';');
      WriteLn(INI,'; While opening a file in its f/name str1 will be replaced with str2.');
      WriteLn(INI,'; e.g.:  "C:\GAMES\<str1>\GAME.DAT"  -->  "C:\GAMES\<str2>\GAME.DAT".');
      WriteLn(INI,';');
      WriteLn(INI,'Replace: C:\GAMES, C:\BIN');
      WriteLn(INI);
      WriteLn(INI,'; Syntax:');
      WriteLn(INI,';   Replace+:str1,str2');
      WriteLn(INI,';');
      WriteLn(INI,'; While opening a file in its f/name ALL symbols UNTIL the END of str1 will');
      WriteLn(INI,'; be replaced with str2.');
      WriteLn(INI,'; e.g.:  "C:\GAMES\CD\<str1>\1\GAME.DAT"  -->  "<str2>\1\GAME.DAT".');
      WriteLn(INI,';');
      WriteLn(INI,'Replace+: DATA, C:\BIN');
      WriteLn(INI);
      WriteLn(INI,'; Syntax:');
      WriteLn(INI,';   Replace*:str1,str2');
      WriteLn(INI,';');
      WriteLn(INI,'; While opening a file ALL its f/name which contains str1 will be ENTIRELY');
      WriteLn(INI,'; replaced with str2.');
      WriteLn(INI,'; e.g.:  "C:\GAMES\CD\<str1>\1\GAME.DAT"  -->  "<str2>".');
      WriteLn(INI,';');
      WriteLn(INI,'Replace*: DATA, C:\BIN');
      WriteLn(INI);
      WriteLn(INI,'; Syntax:');
      WriteLn(INI,';   Exec:str1,str2');
      WriteLn(INI,'; Instead of executing a file with its f/name containing str1, one with');
      WriteLn(INI,'; f/name str2 will be executed.');
      WriteLn(INI,'; e.g.:  "C:\BIN\ALL\<str1>.EXE"  -->  "<str2>".');
      WriteLn(INI,';');
      WriteLn(INI,'Exec: FORMAT C:, @ECHO Formatting drive C:...');
      WriteLn(INI);
      WriteLn(INI,'; Program file to be run. Note: FULL path w/extension is required.');
      WriteLn(INI,'Run: START.EXE');
      WriteLn(INI);
      WriteLn(INI,'; That''s all folks!');
      Close(INI);
      WriteLn('FORD.INI successfully created.');
      WriteLn;
      Halt;
end;

Procedure INI_Process(INI_Name: String);
var T: String;

Procedure INI_ProcessLine(INI_Line: String);
var L, O, K, LS, S1, S2: String;
    C, CS, KS, CP, KP: Byte;
    AB, AC, AK: Boolean;
    Ch: Char;

procedure NewItem(Command: TCommand);
begin
     If (S1 = '') and (S2 = '') then
     begin
          If KS = 0 then Error(LS+': 2nd parameter expected.');
          If KS > 1 then Error(LS+': Too many parameters.');
          S1 := Copy(L, CP+1, KP-CP-1);
          S2 := Copy(L, KP+1, Length(L)-KP+1);
     end;

     If First = nil then begin New(First); Current := First; Last := First; end
        else begin New(Current); Last^.Next := Current; Last := Current; end;
     With Current^ do
     begin
          Cmd := Command;
          Str1 := S1;
          Str2 := S2;
          Next := nil;
     end;
end;

begin
     L := INI_Line;
     If (Length(L) = 0) or (L[1] = ';') then Exit;

     For C := 1 to Length(L) do
          L[C] := UpCase(L[C]);

     O := '';
     AB := True;
     AC := False;
     AK := False;
     CS := 0;
     KS := 0;

     For C := 1 to Length(L) do
     begin
          Ch := L[C];

          If Ch = ':' then begin AC := True; Inc(CS); end;
          If Ch = ',' then begin AK := True; Inc(KS); end;

          If not (AB and (Ch = ' ')) then
             If AB then AB := False;
          If not (AC and (Ch = ' ')) then
             If AC and (Ch <> ':') then AC := False;
          If not (AK and (Ch = ' ')) then
             If AK and (Ch <> ',') then AK := False;

          if (not(AB and (Ch = ' '))) and (not(AC and (Ch = ' ')) and
             (not(AK and (Ch = ' '))) ) then
                     O := O+Ch;
     end;

     L := O;
     Str(LN, LS);
     LS := 'Line #'+LS;

     If CS = 0 then Error(LS+': Keyword expected.') else

     CP := Pos(':', L);
     KP := Pos(',', L);

     K := Copy(L, 1, CP-1);

     If K = 'NAME' then Name := Copy(L, CP+1, Length(L)-CP+1) else
     If K = 'RUN' then Run := Copy(L, CP+1, Length(L)-CP+1) else

     begin
          S1 := '';
          S2 := '';
          If K = 'REPLACE' then
             NewItem(Replace) else
          If K = 'REPLACE+' then
             NewItem(RPlus) else
          If K = 'REPLACE*' then
             NewItem(RAll) else
          If K = 'EXEC' then
             NewItem(Execute)
          else
              Error(LS+': Unknown keyword ('+K+')');
     end;
end;

begin
     T := INI_Name;
     If Pos('.',T) = 0 then T := T + '.INI';
     Assign(INI, T);
{$I-}
     Reset(INI); If IOResult <> 0 then Error('Error reading ini-file.');
{$I+}

     LN := 0;
     First := nil;

     Repeat
          ReadLn(INI, T);
          Inc(LN);
          INI_ProcessLine(T);
     Until EOF(INI);

     Close(INI);
end;

Procedure ProcessParams;
var C: Byte;
    P: String;
begin
     If ParamCount <> 1 then
     begin
          WriteLn('Works similar to APPEND, but also supports re-directing for file groups,');
          WriteLn('subdirectories and file execution. See sample .INI file for details.');
          WriteLn;
          WriteLn('Usage:   FORD ini-file');
          WriteLn('or       FORD /s    to create sample .INI file.');
          WriteLn;
          Halt;
     end;
     For C := 1 to ParamCount do
     begin
          P := ParamStr(C);
          If (P[1] = '/') and (UpCase(P[2])='S') and (Length(P)=2) then
             INI_Sample
          else If P[1] = '/' then Error('Unknown parameter.')
          else INI_Process(ParamStr(C));
     end;
end;

procedure Debug;
begin
     Current := First;
     While Current <> nil do
     begin
          With Current^ do
          begin
               Case Cmd of
               Replace: Write(' REPLACE');
                 RPlus: Write(' REPLACE+');
                  RAll: Write(' REPLACE*');
               Execute: Write(' EXEC');
                  else  Write('***UNKNOWN***');
               end;
               WriteLn(':',Str1,',',Str2);
          end;
          Current := Current^.Next;
     end;
end;

begin
  WriteLn('FORD - File Open ReDirector, v2.0   (Build 12/09/1999)');
  WriteLn;
  Name := '';
  Run := '';
  ProcessParams;
  If First = nil then Error('Nothing to do.');
  Set21h;
  If Run = '' then
  begin
       WriteLn('FORD 2.0 going resident.');
       Keep(0);
  end;
  If Name <> '' then WriteLn('Running ',Name,'...');
  WriteLn;
  RL := Pos(' ', Run);
  If RL<>0 then Exec(Copy(Run,1,RL-1),Copy(Run,RL,Length(Run)-RL+1)) else
     Exec(Run,'');
  Restore21h;

  WriteLn;
end.