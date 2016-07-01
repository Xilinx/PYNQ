//
//  Vivado(TM)
//  ISEWrap.js: Vivado Runs Script for WSH 5.1/5.6
//  Copyright 1986-1999, 2001-2013 Xilinx, Inc. All Rights Reserved. 
//

// GLOBAL VARIABLES
var ISEShell = new ActiveXObject( "WScript.Shell" );
var ISEFileSys = new ActiveXObject( "Scripting.FileSystemObject" );
var ISERunDir = "";
var ISELogFile = "runme.log";
var ISELogFileStr = null;
var ISELogEcho = true;
var ISEOldVersionWSH = false;



// BOOTSTRAP
ISEInit();



//
// ISE FUNCTIONS
//
function ISEInit() {

  // 1. RUN DIR setup
  var ISEScrFP = WScript.ScriptFullName;
  var ISEScrN = WScript.ScriptName;
  ISERunDir = 
    ISEScrFP.substr( 0, ISEScrFP.length - ISEScrN.length - 1 );

  // 2. LOG file setup
  ISELogFileStr = ISEOpenFile( ISELogFile );

  // 3. LOG echo?
  var ISEScriptArgs = WScript.Arguments;
  for ( var loopi=0; loopi<ISEScriptArgs.length; loopi++ ) {
    if ( ISEScriptArgs(loopi) == "-quiet" ) {
      ISELogEcho = false;
      break;
    }
  }

  // 4. WSH version check
  var ISEOptimalVersionWSH = 5.6;
  var ISECurrentVersionWSH = WScript.Version;
  if ( ISECurrentVersionWSH < ISEOptimalVersionWSH ) {

    ISEStdErr( "" );
    ISEStdErr( "Warning: ExploreAhead works best with Microsoft WSH " +
	       ISEOptimalVersionWSH + " or higher. Downloads" );
    ISEStdErr( "         for upgrading your Windows Scripting Host can be found here: " );
    ISEStdErr( "             http://msdn.microsoft.com/downloads/list/webdev.asp" );
    ISEStdErr( "" );

    ISEOldVersionWSH = true;
  }

}

function ISEStep( ISEProg, ISEArgs ) {

  // CHECK for a STOP FILE
  if ( ISEFileSys.FileExists(ISERunDir + "/.stop.rst") ) {
    ISEStdErr( "" );
    ISEStdErr( "*** Halting run - EA reset detected ***" );
    ISEStdErr( "" );
    WScript.Quit( 1 );
  }

  // WRITE STEP HEADER to LOG
  ISEStdOut( "" );
  ISEStdOut( "*** Running " + ISEProg );
  ISEStdOut( "    with args " + ISEArgs );
  ISEStdOut( "" );

  // LAUNCH!
  var ISEExitCode = ISEExec( ISEProg, ISEArgs );  
  if ( ISEExitCode != 0 ) {
    WScript.Quit( ISEExitCode );
  }

}

function ISEExec( ISEProg, ISEArgs ) {

  var ISEStep = ISEProg;
  if (ISEProg == "realTimeFpga" || ISEProg == "planAhead" || ISEProg == "vivado") {
    ISEProg += ".bat";
  }

  var ISECmdLine = ISEProg + " " + ISEArgs;
  var ISEExitCode = 1;

  if ( ISEOldVersionWSH ) { // WSH 5.1

    // BEGIN file creation
    ISETouchFile( ISEStep, "begin" );

    // LAUNCH!
    ISELogFileStr.close();
    ISECmdLine = 
      "%comspec% /c " + ISECmdLine + " >> " + ISELogFile + " 2>&1";
    ISEExitCode = ISEShell.Run( ISECmdLine, 0, true );
    ISELogFileStr = ISEOpenFile( ISELogFile );

  } else {  // WSH 5.6

    // LAUNCH!
    ISEShell.CurrentDirectory = ISERunDir;

    // Redirect STDERR to STDOUT
    ISECmdLine = "%comspec% /c " + ISECmdLine + " 2>&1";
    var ISEProcess = ISEShell.Exec( ISECmdLine );
    
    // BEGIN file creation
    var ISENetwork = WScript.CreateObject( "WScript.Network" );
    var ISEHost = ISENetwork.ComputerName;
    var ISEUser = ISENetwork.UserName;
    var ISEPid = ISEProcess.ProcessID;
    var ISEBeginFile = ISEOpenFile( "." + ISEStep + ".begin.rst" );
    ISEBeginFile.WriteLine( "<?xml version=\"1.0\"?>" );
    ISEBeginFile.WriteLine( "<ProcessHandle Version=\"1\" Minor=\"0\">" );
    ISEBeginFile.WriteLine( "    <Process Command=\"" + ISEProg + 
			    "\" Owner=\"" + ISEUser + 
			    "\" Host=\"" + ISEHost + 
			    "\" Pid=\"" + ISEPid +
			    "\">" );
    ISEBeginFile.WriteLine( "    </Process>" );
    ISEBeginFile.WriteLine( "</ProcessHandle>" );
    ISEBeginFile.Close();
    
    var ISEOutStr = ISEProcess.StdOut;
    var ISEErrStr = ISEProcess.StdErr;
    
    // WAIT for ISEStep to finish
    while ( ISEProcess.Status == 0 ) {
      
      // dump stdout then stderr - feels a little arbitrary
      while ( !ISEOutStr.AtEndOfStream ) {
        ISEStdOut( ISEOutStr.ReadLine() );
      }  
      
      WScript.Sleep( 100 );
    }

    ISEExitCode = ISEProcess.ExitCode;
  }

  // END/ERROR file creation
  if ( ISEExitCode != 0 ) {    
    ISETouchFile( ISEStep, "error" );
    
  } else {
    ISETouchFile( ISEStep, "end" );
  }

  return ISEExitCode;
}


//
// UTILITIES
//
function ISEStdOut( ISELine ) {

  ISELogFileStr.WriteLine( ISELine );
  
  if ( ISELogEcho ) {
    WScript.StdOut.WriteLine( ISELine );
  }
}

function ISEStdErr( ISELine ) {
  
  ISELogFileStr.WriteLine( ISELine );

  if ( ISELogEcho ) {
    WScript.StdErr.WriteLine( ISELine );
  }
}

function ISETouchFile( ISERoot, ISEStatus ) {

  var ISETFile = 
    ISEOpenFile( "." + ISERoot + "." + ISEStatus + ".rst" );
  ISETFile.close();
}

function ISEOpenFile( ISEFilename ) {

  var ISEFullPath = ISERunDir + "/" + ISEFilename;
  return ISEFileSys.OpenTextFile( ISEFullPath, 8, true );
}
