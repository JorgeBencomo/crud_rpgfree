**free
    Ctl-Opt Option(*nodebugio) Dftactgrp(*No);

    //*----------------------------------------------------
    //*files
    //*----------------------------------------------------
    Dcl-F cust disk(*ext) usage(*update:*delete:*output) Keyed;
    Dcl-F custd02 workstn;

    //*----------------------------------------------------------
    //*constants which stores output messages to users
    //*----------------------------------------------------------
    dcl-c Err1 CONST('Customer number must be greater than zero');
    dcl-c Err2 CONST('Record not on file');
    dcl-c Err3 CONST('No more records');
    dcl-c Err4 CONST('No more records');
    dcl-c Err5 CONST('Zip cannot be blank');
    dcl-c Err6 CONST('Name is mandatory');
    dcl-c Err7 CONST('State is mandatory');
    dcl-c Err8 CONST('Invalid action');
    dcl-c Err10 CONST('Points are not valid');
    dcl-c Msg1 CONST('Record Added');
    dcl-c Msg2 CONST('Record Updated');
    dcl-c Msg3 CONST('Record Deleted');
    dcl-c Msg4 CONST('Hit F9 to delete');
    dcl-c Msg9 CONST('No action taken');
    //*----------------------------------------------------
    //*variables
    //*----------------------------------------------------
    dcl-s RecOk char(1);

    //*----------------------------------------------------------
    //*Program name
    //*----------------------------------------------------------
    dcl-ds PgmDs psds qualified;
      PgmName *proc;
    end-ds;
    Z1SCREEN = %trimr(PgmDs.PgmName) + '-1';

    //*----------------------------------------------------------
    //* main 
    //*----------------------------------------------------------
    *InLR = *On;

    dow *in03 = *off;

      exsr clearfld;
      exfmt scr1;
      errlin = *blanks;

      *in90 = *off;
      if *in03 = *off;

        exsr AddRecord;

      endif;

    enddo;
    //*****end-pgm****************

    //**********************************************
    // Add Record Subroutine
    // Indicator 80 is used by the display file to
    // protect more fields since we are in ADD mode
    // set the indicator off to allow field entry
    //**********************************************
    begSr AddRecord;
      *in80 = *off;
      MODE = 'ADD';

      // See if customer is already on file.
      
      chain csnbr CUST;
      if %found(CUST);
        exsr InqRecord;
      else;
        if csnbr > 0;
          exSr AddScreen;
        else;
          errlin = Err1;
        endif;
      endif;

    endSr;
    // ***End-sr************************************

    //**********************************************
    // AddScreen subroutine - New record
    //**********************************************
    begSr AddScreen;
      //Clear all fields except the key field
      exsr ClearFl2;

      //Display "Record not on file" in errlin
      errlin = Err2;
      *in90 = *on;
      
      RecOK = 'n';
      //Stay on this screen until user gets it right or hits F3
      dow RecOK = 'n' and *in03 = *off;
        exfmt scr2;

        if *in03 = *off;
          ExSr EditRecord;
          if recOK = 'y';
            write CSREC;
            *in90 = *On;
            errlin = Msg1;
          endif;
        else;
          *in90 = *On;
          errlin = Msg9;
        endif;

      enddo;
      *in03 = *off;
    endsr;
    //*****End of sr*****************

    //*****************************************
    // DltRecord - Delete a record from file
    //*****************************************
    begSr DltRecord;
      //*in80 is used by the display file to protect
      //most fields since we are in DLT mode, set the
      //*in on for no field entry
      *in80 = *On;
      MODE = 'DELETE';
      //Display "Hit F9 to delete" in errlin
      errlin = Msg4;
      *in90 = *on;

      //See if customer is in file. If not, show errMsg
      // chain KEYLST CUST;
      chain csnbr CUST;
      if not %found(CUST);
        errlin = Err2;
      else;

        //If customer is on file, show screen again and see
        // if user hit F9 to confirm delete
        exfmt scr2;
        *in90 = *off;
        if *in09 = *on;
          delete CSREC;
          errlin = msg3;
        else;
          errlin = msg9;
        endif;

      endif;

      *in03 = *off;
    endsr;
    //*****end-sr****************

    //*********************************************************
    // InqRecord - Looks for one record
    // Indicator 80 is used by the display file to protect
    // most fields since we are in DLT mode, set the indicator
    // on for no field entry
    //*********************************************************
    begSr InqRecord;
      *in80 = *on;
      mode = 'INQUIRY';

      exfmt scr2;

      if *in05 = *on;
        exsr UpdRecord;
      endif;

      if *in09 = *on;
        exsr DltRecord;
      endif;
      
      *in03 = *off;
    endsr;
    // *****end-sr *****************

    //*************************************************
    // NextRecord - See the next record from selected *
    //*************************************************
    begSr NextRecord;
      *in80 = *On;
      mode = 'INQUIRY';
      errlin = *blanks;

      //Set file cursor at cust from screen
      // setll KEYLST CUST;
      setll csnbr CUST;
      if %equal(CUST);
        errlin = err3;
        *in90 = *On;
      endif;

      //Read file to get next customer
      if errlin = *blanks;
        read cust;
        if not %equal;
          errlin = err3;
          *in90 = *On;
        endif;
      endif;

      //If *in93 = *On, we are at an existing record
      //and need to read pass it
      if errlin = *blanks;
        exfmt scr2;
      endif;

      *in03 = *off;
    endsr;
    //*******end-sr*****************

    //*****************************************************
    // updRecord - Updates existing record                *
    //*****************************************************
    begsr updRecord;
      *in80 = *off;
      mode = 'UPDATE';

      // chain KEYLST CUST;
      chain csnbr CUST;
      if not %found(CUST);
        errlin = Err2;
        *in90 = *On;
      else;
        exSr UpdScreen;
      endif;

    endsr;
    //*******end-sr*****************

    //******************************************************
    // UpdScreen - update the screen during navigation     *
    //******************************************************
    begSr UpdScreen;
      RecOK = 'n';
      DoW RecOk = 'n' and *in03 = *off;
        exfmt scr2;

        if *in03 = *off;
          exSr EditRecord;
          if RecOk = 'y';
            update CSREC;
            errlin = Msg2;
          endif;
        else;
          errlin = Msg9;
        endif;

      enddo;
      *in03 = *off;
    endSr;
    //******end-sr***************************

    //**********************************************
    // EditRecord - Updates selected record        *
    //**********************************************
    begSr EditRecord;
      RecOK = 'y';
      if CSNAME = *blanks;
        RecOK = 'n';
        errlin = Err6;
        *in90 = *on;
      endif;

      if CSSTAT = *blanks;
        RecOK = 'n';
        errlin = Err7;
        *in90 = *On;
      endif;

      if CSZIP = *blanks;
        RecOK = 'n';
        errlin = Err5;
        *in90 = *On;
      endif;

      if CSPOINTS <= 0;
        RecOK = 'n';
        errlin = Err10;
        *in90 = *On;
      endif;
    endSr;
    //*****end-sr****************

    //***********************************
    // ClearFld - Clear all fields used
    //***********************************
    begSr ClearFld;
      CSNBR = *zeros;
    endsr;

    //***********************************
    // ClearFl2 - Clear all fields used
    //***********************************
    begSr ClearFl2;
      CSNAME = *blanks;
      CSADR1 = *blanks;
      CSCITY = *blanks;
      CSSTAT = *blanks;
      CSZIP  = *blanks;
      CSPOINTS = *zeros;
    endsr;