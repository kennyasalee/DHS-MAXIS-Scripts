'Required for statistical purposes==========================================================================================
name_of_script = "NOTES - CLOSED PROGRAMS.vbs"
start_time = timer
STATS_counter = 1               'sets the stats counter at one
STATS_manualtime = 420           'manual run time in seconds
STATS_denomination = "C"        'C is for each case
'END OF stats block=========================================================================================================

'LOADING FUNCTIONS LIBRARY FROM GITHUB REPOSITORY===========================================================================
IF IsEmpty(FuncLib_URL) = TRUE THEN	'Shouldn't load FuncLib if it already loaded once
	IF run_locally = FALSE or run_locally = "" THEN	   'If the scripts are set to run locally, it skips this and uses an FSO below.
		IF use_master_branch = TRUE THEN			   'If the default_directory is C:\DHS-MAXIS-Scripts\Script Files, you're probably a scriptwriter and should use the master branch.
			FuncLib_URL = "https://raw.githubusercontent.com/MN-Script-Team/BZS-FuncLib/master/MASTER%20FUNCTIONS%20LIBRARY.vbs"
		Else											'Everyone else should use the release branch.
			FuncLib_URL = "https://raw.githubusercontent.com/MN-Script-Team/BZS-FuncLib/RELEASE/MASTER%20FUNCTIONS%20LIBRARY.vbs"
		End if
		SET req = CreateObject("Msxml2.XMLHttp.6.0")				'Creates an object to get a FuncLib_URL
		req.open "GET", FuncLib_URL, FALSE							'Attempts to open the FuncLib_URL
		req.send													'Sends request
		IF req.Status = 200 THEN									'200 means great success
			Set fso = CreateObject("Scripting.FileSystemObject")	'Creates an FSO
			Execute req.responseText								'Executes the script code
		ELSE														'Error message
			critical_error_msgbox = MsgBox ("Something has gone wrong. The Functions Library code stored on GitHub was not able to be reached." & vbNewLine & vbNewLine &_
                                            "FuncLib URL: " & FuncLib_URL & vbNewLine & vbNewLine &_
                                            "The script has stopped. Please check your Internet connection. Consult a scripts administrator with any questions.", _
                                            vbOKonly + vbCritical, "BlueZone Scripts Critical Error")
            StopScript
		END IF
	ELSE
		FuncLib_URL = "C:\BZS-FuncLib\MASTER FUNCTIONS LIBRARY.vbs"
		Set run_another_script_fso = CreateObject("Scripting.FileSystemObject")
		Set fso_command = run_another_script_fso.OpenTextFile(FuncLib_URL)
		text_from_the_other_script = fso_command.ReadAll
		fso_command.Close
		Execute text_from_the_other_script
	END IF
END IF
'END FUNCTIONS LIBRARY BLOCK================================================================================================

'Checks for county info from global variables, or asks if it is not already defined.
get_county_code

'VARIABLE REQUIRED TO RESIZE DIALOG BASED ON A GLOBAL VARIABLE IN FUNCTIONS FILE
If case_noting_intake_dates = False then dialog_shrink_amt = 65

'THE DIALOG----------------------------------------------------------------------------------------------------
BeginDialog closed_dialog, 0, 0, 471, 285, "Closed Programs Dialog"
  EditBox 70, 5, 55, 15, MAXIS_case_number
  CheckBox 185, 10, 35, 10, "SNAP", SNAP_check
  CheckBox 220, 10, 35, 10, "Cash", cash_check
  CheckBox 255, 10, 25, 10, "HC", HC_check
  EditBox 70, 25, 55, 15, closure_date
  EditBox 85, 45, 180, 15, reason_for_closure
  EditBox 115, 65, 150, 15, verifs_needed
  EditBox 180, 85, 85, 15, open_progs
  CheckBox 10, 120, 210, 10, "Case is at cash/SNAP renewal (monthy, six-month, annual)", CSR_check
  CheckBox 10, 135, 115, 10, "Case is at HC annual renewal.", HC_ER_check
  CheckBox 10, 150, 215, 10, "Case is entering Sanction.     Enter number of Sanction months:", Sanction_checkbox
  EditBox 230, 145, 30, 15, sanction_months
  CheckBox 10, 165, 195, 10, "Case is closing for not providing postoned verifications.", postponed_verif_checkbox
  CheckBox 10, 195, 120, 10, "Sent DHS-5181 to Case Manager", sent_5181_check
  CheckBox 10, 215, 190, 10, "Check here if closure is due to client death (enter date):", death_check
  EditBox 205, 210, 60, 15, hc_close_for_death_date
  CheckBox 10, 230, 90, 10, "WCOM Added To Notice:", WCOM_check
  ButtonGroup ButtonPressed
    PushButton 105, 230, 50, 10, "SPEC/WCOM", SPEC_WCOM_button
  CheckBox 10, 245, 65, 10, "Updated MMIS?", updated_MMIS_check
  EditBox 75, 260, 50, 15, worker_signature
  ButtonGroup ButtonPressed
    OkButton 365, 245, 50, 15
    CancelButton 415, 245, 50, 15
  Text 10, 10, 50, 10, "Case Number:"
  Text 130, 10, 50, 10, "Progs Closed:"
  Text 10, 30, 55, 10, "Date Of Closure:"
  Text 10, 50, 70, 10, "Reason For Closure:"
  Text 10, 70, 105, 10, "Verifications/Info Still Needed:"
  Text 10, 90, 165, 10, "Are any programs still open? If so, list them here:"
  GroupBox 5, 105, 260, 75, "Elements That May Affect REIN Date:"
  GroupBox 5, 185, 130, 25, "For LTC Cases"
  GroupBox 270, 40, 195, 105, "IMPORTANT - Note for SNAP:"
  Text 275, 100, 180, 45, "As a result, SNAP cases who turn in proofs required (or otherwise become eligible for their remaining budget period) can be REINed (with proration) up until the end of the next month. If you have questions, consult a supervisor."
  Text 275, 50, 180, 50, "Per CM 0005.09.06, we no longer require completion of a CAF when the unit has been closed for less than one month AND the reason for closing has not changed, if the unit fully resolves the reason for the SNAP case closure given on the closing notice sent in MAXIS."
  GroupBox 270, 145, 195, 90, "IMPORTANT - Note for HC: "
  ButtonGroup ButtonPressed
    PushButton 275, 220, 50, 10, "HCPM", HC_EPM_Button
  Text 275, 155, 180, 50, "This script does not case note REIN dates for HC, due to the ever changing nature of these programs at this time. MAGI clients have up to three months (follows retro application policy) after case closure to turn in their renewals and have eligibility determined. They can also reapply online using METS.  "
  Text 10, 265, 60, 10, "Worker Signature: "
  Text 275, 210, 180, 10, "For more information refer to:"
EndDialog




'The script----------------------------------------------------------------------------------------------------
'Connects to BlueZone
EMConnect ""

'Resets variables in case this is run from docs received.
SNAP_check = 0
cash_check = 0
HC_check = 0

'Autofills case number
call MAXIS_case_number_finder(MAXIS_case_number)

'Dialog starts. Checks for MAXIS, includes nav button for SPEC/WCOM, validates the date of closure, confirms that date
'    of closure is last day of a month, checks that a program was selected for closure, and navigates to CASE/NOTE.
DO
	DO
		DO
			DO
				DO
					Dialog closed_dialog
					cancel_confirmation
					If ButtonPressed = SPEC_WCOM_button then call navigate_to_MAXIS_screen("spec", "wcom")
					If ButtonPressed = HC_EPM_Button then CreateObject("WScript.Shell").Run("http://hcopub.dhs.state.mn.us/epm/#t=index_1.htm")
				Loop until ButtonPressed = -1
				If isdate(closure_date) = False then MsgBox "You need to enter a valid date of closure (MM/DD/YYYY)."
				IF (death_check = 1 AND isdate(hc_close_for_death_date) = FALSE) THEN MsgBox "Please enter a date in the correct format (MM/DD/YYYY)."
				IF (death_check <> 1 AND hc_close_for_death_date <> "") THEN MsgBox "Please check the box for client death."
			Loop until isdate(closure_date) = True AND ((death_check = 1 AND isdate(hc_close_for_death_date) = TRUE) OR (death_check <> 1 AND hc_close_for_death_date = ""))
			If datepart("d", dateadd("d", 1, closure_date)) <> 1 then MsgBox "Please use the last date of eligibility, which for an open case, should be the last day of the month. If this is a denial, use the denial script."
	    Loop until datepart("d", dateadd("d", 1, closure_date)) = 1
		If SNAP_check = 0 and HC_check = 0 and cash_check = 0 then MsgBox "You need to select a program to close."
	Loop until SNAP_check = 1 or HC_check = 1 or cash_check = 1
	call check_for_password(are_we_passworded_out)  'Adding functionality for MAXIS v.6 Passworded Out issue'
LOOP UNTIL are_we_passworded_out = false

Call check_for_MAXIS(False)

'******HENNEPIN COUNTY SPECIFIC INFORMATION*********
'WCOM informing users that they may be subject to probate claims for their HC case
IF worker_county_code = "x127" THEN
	IF (HC_check = 1 AND death_check = 1) THEN
		'creating date variables
		approval_month = datepart("m", closure_date)
		approval_year = datepart("YYYY", closure_date)
		approval_year = right(approval_year, 2)
		call navigate_to_MAXIS_screen("SPEC", "WCOM")
		EMWriteScreen "Y", 3, 74 'sorts notices by HC only
		EMWriteScreen approval_month, 3, 46
		EMWriteScreen approval_year, 3, 51
		transmit
		DO 	'This DO/LOOP resets to the first page of notices in SPEC/WCOM
			EMReadScreen more_pages, 8, 18, 72
			IF more_pages = "MORE:</>" THEN
				PF8
				EMReadScreen future_month_error, 14, 24, 2
			END IF
		LOOP until future_month_error = "NOTICE BENEFIT"

		read_row = 7 ' sets the variable for the row since this doesn't change in the search for notices
		DO
			waiting_check = ""
			EMReadscreen prog_type, 2, read_row, 26
			EMReadscreen waiting_check, 7, read_row, 71 'finds if notice has been printed
		If waiting_check = "Waiting" and prog_type = "HC" THEN 'checking program type and if it's been printed
			EMSetcursor read_row, 13
			EMSendKey "x"
			Transmit
			pf9
			EMSetCursor 03, 15
			'Writing the verifs needed into the notice
			Call write_variable_in_spec_memo("************************************************************")
			call write_variable_in_spec_memo("Medical Assistance eligibility ends on: " & hc_close_for_death_date & ".")
			call write_variable_in_spec_memo("Hennepin County may have claims against any assets left after funeral expenses.")
			call write_variable_in_spec_memo("Please contact the Probate Unit at 612-348-3244 for more information. Thank you.")
			Call write_variable_in_spec_memo("************************************************************")
			notice_edited = true 'Setting this true lets us know that we successfully edited the notice
			pf4
			pf3
			WCOM_check = 1 'This makes sure to case note that the notice was edited, even if user doesn't check the box.
			WCOM_count = WCOM_count + 1
			exit do
		ELSE
			read_row = read_row + 1
		END IF
		IF read_row = 18 THEN
			PF8    'Navigates to the next page of notices.  DO/LOOP until read_row = 18
			read_row = 7
		End if
		LOOP until prog_type = "  "
	END IF
END IF
'******END OF HENNEPIN COUNTY SPECIFIC INFORMATION*********

'LOGIC and calculations----------------------------------------------------------------------------------------------------
'Converting dates for intake/REIN/reapp date calculations
closure_date = cdate(closure_date)                                                       'just running a cdate on the closure_date variable
closure_month_first_day = dateadd("d", 1, closure_date)                                  'This is the first day of the closure month
closure_month_last_day = dateadd("d", -1, (dateadd("m", 1, closure_month_first_day)))    'This is the last day of the closure month
intake_date = dateadd("m", 1, closure_month_first_day)                                   'Becomes an intake the first of the month after closure (case would be assigned to a new worker if they reapply)

'If the case is at the CSR then the last REIN date is automatically ahead one month. Otherwise it's the date of closure for all programs except SNAP.
If CSR_check = 1 then
  If HC_check = 1 then HC_last_REIN_date = closure_month_last_day
  If cash_check = 1 then cash_last_REIN_date = closure_month_last_day
Else
  If HC_check = 1 then HC_last_REIN_date = closure_date
  If cash_check = 1 then cash_last_REIN_date = closure_date
End if

'For HC, the client can turn in a HC ER before the end of the next month, or turn in a HCAPP anytime. Either way it's just treated as a new app.
If HC_check = 1 then
  progs_closed = progs_closed & "HC/"
  If HC_ER_check = 1 then
    HC_last_REIN_date = closure_date 'This will force the HC_last_REIN_date variable to show the closure date, in case a SNAP CSR messes with the variable. HC ERs are always treated like a new application if turned in late.
    HC_followup_text = ", after which a new HC renewal or HCAPP is required. A new HCAPP is required after " & closure_month_last_day & "."
  End if
  If HC_ER_check = 0 then HC_followup_text = ", after which a new HCAPP is required."
End if

'SNAP closures have different logic for when to REIN. For SNAP the client gets an additional month to turn in proofs, and can be REINed without a new app.
If SNAP_check = 1 then
	IF postponed_verif_checkbox = 1 THEN					'additional logic fo expedited cases closing for no postponed verifications returned. 
		Call navigate_to_MAXIS_screen("STAT", "PROG")		'must NAV to find appl date to determine if when it was rec'd
		EMReadScreen SNAP_application_date, 8, 10, 33
		SNAP_application_date = replace(SNAP_application_date, " ", "/")
		fifteen_of_appl_month = left(SNAP_application_date, 2) & "/15/" & right(SNAP_application_date, 2)
		IF datediff("D", SNAP_application_date, fifteen_of_appl_month) >= 0 Then							'if rec'd ON or BEFORE 15th client gets 30 days from date of application to be reinstated. 
			progs_closed = progs_closed & "SNAP/"
			SNAP_last_REIN_date = dateadd("d", 30, SNAP_application_date)
			SNAP_followup_text = ", after which a new CAF is required (expedited SNAP closing for postponed verification not returned)."	
			IF cash_check <> 1 THEN intake_date = dateadd("d", 1, SNAP_last_REIN_date)			        'if cash is not being closed the intake date needs to be the day after the rein date
		Else
			progs_closed = progs_closed & "SNAP/"															'if rec'd after the 15th client gets until closure date (end of 2nd month of benefits) to be reinstated. 
			SNAP_last_REIN_date = closure_date
			SNAP_followup_text = ", after which a new CAF is required (expedited SNAP closing for postponed verification not returned)."	
			IF cash_check <> 1 THEN intake_date = dateadd("d", 1, SNAP_last_REIN_date)					'if cash is not being closed the intake date needs to be the day after the rein date
		END IF
	ELSE															'if the case didn't close for postponed verifs then the client gets the regular 30 day reinstate period. 
		progs_closed = progs_closed & "SNAP/"
		SNAP_last_REIN_date = closure_month_last_day
		SNAP_followup_text = ", after which a new CAF is required."
	END IF
End if

'Cash cases use similar logic to HC but don't have the "HC renewal can be used as a new app" issue.
If cash_check = 1 then
  progs_closed = progs_closed & "cash/"
  cash_followup_text = ", after which a new CAF is required."
End if

'Calculating Sanction date
IF Sanction_checkbox = 1 Then
	end_of_sanction = dateadd("d", -1, dateadd("m", Sanction_months, closure_month_first_day))
	sanction_period = closure_month_first_day & "-" & end_of_sanction
END IF

'Removing the last character of the progs_closed variable, as it is always a trailing slash
progs_closed = left(progs_closed, len(progs_closed) - 1)

'The dialog navigated to CASE/NOTE. This will write the info into the case note.
start_a_blank_CASE_NOTE
IF death_check = 1 THEN
	case_note_header = "---Closed " & progs_closed & " due to client death---"
ELSE
	case_note_header = "---Closed " & progs_closed & " " & closure_date & "---"
END IF
call write_variable_in_case_note(case_note_header)
IF death_check = 1 AND HC_check = 1 THEN call write_bullet_and_variable_in_case_note("HC Closure Date", hc_close_for_death_date)
IF death_check = 1 AND snap_check = 1 THEN call write_bullet_and_variable_in_case_note("SNAP Closure Date", closure_date)
IF death_check = 1 AND cash_check = 1 THEN call write_bullet_and_variable_in_case_note("CASH Closure Date", closure_date)
call write_bullet_and_variable_in_case_note("Reason for closure", reason_for_closure)
If verifs_needed <> "" then call write_bullet_and_variable_in_case_note("Verifs needed", verifs_needed)
If updated_MMIS_check = 1 then call write_variable_in_case_note("* Updated MMIS.")
If WCOM_check = 1 then call write_variable_in_case_note("* Added WCOM to notice.")
IF (worker_county_code = "x127" AND HC_check = 1 AND death_check = 1) THEN call write_variable_in_case_note("* Added Hennepin County probate information to the client's notice.")
If CSR_check = 1 then call write_bullet_and_variable_in_case_note("Case is at renewal", "Client has an additional month to turn in the document and any required proofs.")
If HC_ER_check = 1 then call write_variable_in_case_note("* Case is at HC ER.")
If case_noting_intake_dates = True or case_noting_intake_dates = "" then  																								'Updated bug. With new/updated, scripts this functionality was not being accessed.'
	call write_variable_in_case_note("---")
	If death_check <> 1 and Sanction_checkbox <> 1 and SNAP_check = 1 then
		call write_bullet_and_variable_in_case_note("Last SNAP REIN date", SNAP_last_REIN_date & SNAP_followup_text)
	ELSEIF Sanction_checkbox = 1 THEN
			call write_variable_in_case_note("* SNAP is entering sanction for " & sanction_months & " month(s) " & sanction_period & ". If client does not comply by closure date " & closure_date & " client will enter sanction for SNAP. Refer to worker for details on compliance.")
	END IF
	If death_check <> 1 and cash_check = 1 then call write_bullet_and_variable_in_case_note("Last cash REIN date", cash_last_REIN_date & cash_followup_text)
	If open_progs <> "" and len(open_progs) > 1 and open_progs <> "no" and open_progs <> "NO" and open_progs <> "No" and open_progs <> "n/a" and open_progs <> "N/A" and open_progs <> "NA" and open_progs <> "na" then
		call write_bullet_and_variable_in_case_note("Open programs", open_progs)
	Else
		IF death_check = 1 THEN call write_variable_in_case_note("* All programs closed.")
		IF death_check <> 1 THEN call write_variable_in_case_note("* All programs closed. Cash and/or SNAP (whichever applicable) case becomes intake again on " & intake_date & ".")
	End if
Else
	If open_progs <> "" and len(open_progs) > 1 and open_progs <> "no" and open_progs <> "NO" and open_progs <> "No" and open_progs <> "n/a" and open_progs <> "N/A" and open_progs <> "NA" and open_progs <> "na" then call write_bullet_and_variable_in_case_note("Open programs", open_progs)
End if

IF sent_5181_check = 1 then call write_variable_in_case_note ("* Sent DHS-5181 LTC communication to Case Manager")

call write_variable_in_case_note("---")
call write_variable_in_case_note(worker_signature)

'Runs denied progs if selected
If denied_progs_check = 1 then run_another_script("C:\DHS-MAXIS-Scripts\Script Files\NOTE - denied progs.vbs")

'Script end procedure
script_end_procedure("Success! Please remember to check the generated notice to make sure it reads correctly. If not please add WCOMs to make notice read correctly." & vbnewline & vbnewline & "This script does not case note information related to HC REIN dates due to the ever changing nature of these programs at this time. For more information please refer to the IAPM or HCPM, both are buttons available on the powerpad.")
