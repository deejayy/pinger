{$APPTYPE CONSOLE}
uses
	pingsend, sysutils, crt, windows;

const
	errs: array[TICMPError] of string = ('IE_NoError', 'IE_Other', 'IE_TTLExceed', 'IE_UnreachOther', 'IE_UnreachRoute', 'IE_UnreachAdmin', 'IE_UnreachAddr', 'IE_UnreachPort');
	logfile: string = 'hosts.log';

type
	 host = packed record
		ip: string;
		pt: integer;
		last: tdatetime;
		err: TICMPError;
		round: longint;
	end;

var
	ping: tpingsend;
	f: textfile;
	hosts: array[0..255] of host;
	hc, i: integer;
	s: string;

procedure alog(str: string);
var
	f: textfile;
	fname: string;
begin
	{$I-}
	fname := extractfilepath(paramstr(0)) + '/' + logfile;
	assignfile(f, fname);
	if fileexists(fname) then append(f) else rewrite(f);
	{$I+}
	writeln(f, format('[%-20s]'#09'%s', [datetimetostr(now), str]));
	closefile(f);
end;

begin
	textcolor(7);
	clrscr;

	ping := tpingsend.Create;
	ping.timeout := 800;
	{$I-}
	assignfile(f, 'hosts.txt');
	reset(f);
	{$I+}
	hc := 0;
	while not eof(f) do begin
		readln(f, s);
		if s <> '' then begin
			hosts[hc].ip := s;
			hosts[hc].last := 0;
			hosts[hc].round := 0;
			inc(hc);
		end;
	end;
	closefile(f);

	repeat
		for i := 0 to hc-1 do begin
			gotoxy(2, 2+i);
			write(' ':78);
			gotoxy(2, 2+i);
			ping.Ping(hosts[i].ip);
			if hosts[i].round <> 0 then
				if hosts[i].err <> ping.ReplyError then begin
					hosts[i].last := now;
					alog(format('Statechange: %-16s / %s to %s', [hosts[i].ip, errs[hosts[i].err], errs[ping.replyerror]]));
				end;
			hosts[i].err := ping.ReplyError;
			if ping.ReplyError = IE_NoError then begin
				textcolor(15);
			end else begin
				textcolor(7);
			end;
			write(hosts[i].ip:16, ' - ', ping.pingtime:4, 'ms - ');
			if ping.ReplyError = IE_NoError then begin
				textcolor(10)
			end else begin
				textcolor(12);
			end;
			write(errs[ping.ReplyError]:18, ' - ');
			if hosts[i].last <> 0 then write(' ', datetimetostr(hosts[i].last):20);
			inc(hosts[i].round);
		end;
		sleep(1000);
	until false;
end.
