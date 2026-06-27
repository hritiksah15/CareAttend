// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Care Attend';

  @override
  String get appSubtitle => 'NHS Predictive Risk Assessment';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get signInDesc => 'Sign in to access your practice dashboard';

  @override
  String get emailAddress => 'Email or Username';

  @override
  String get password => 'Password';

  @override
  String get login => 'LOG IN';

  @override
  String get createAccount => 'CREATE NEW ACCOUNT';

  @override
  String get backToLogin => 'BACK TO LOGIN';

  @override
  String get dataProtection => 'Data Protection Notice';

  @override
  String get noDataStored => 'No patient data is stored on this device.';

  @override
  String get sessionCleared => 'All session data is cleared on close.';

  @override
  String get gdprCompliant => 'GDPR Article 5(1)(c) compliant.';

  @override
  String get patientAssessment => 'Patient Assessment';

  @override
  String get riskDashboard => 'Risk Dashboard';

  @override
  String get batchUpload => 'Batch Upload';

  @override
  String get biasMonitor => 'Bias Monitor';

  @override
  String get demographics => 'DEMOGRAPHICS';

  @override
  String get appointmentDetails => 'APPOINTMENT DETAILS';

  @override
  String get clinicalFlags => 'CLINICAL FLAGS';

  @override
  String get socialContext => 'SOCIAL CONTEXT';

  @override
  String get assessRisk => 'ASSESS RISK';

  @override
  String get age => 'Age (0-120)';

  @override
  String get gender => 'Gender';

  @override
  String get leadTime => 'Lead Time (days)';

  @override
  String get priorDNA => 'Prior DNA Count';

  @override
  String get smsReceived => 'SMS Reminder Received';

  @override
  String get hypertension => 'Hypertension';

  @override
  String get diabetes => 'Diabetes';

  @override
  String get alcoholism => 'Alcohol Dependency';

  @override
  String get disability => 'Registered Disability';

  @override
  String get imdDecile => 'IMD Decile (1-10)';

  @override
  String get riskLevel => 'DNA Risk Level';

  @override
  String get whyThisScore => 'Why This Score? (SHAP)';

  @override
  String get increasesRisk => 'Increases Risk';

  @override
  String get reducesRisk => 'Reduces Risk';

  @override
  String get interventions => 'Recommended Interventions';

  @override
  String get newAssessment => 'New Assessment';

  @override
  String get biasDashboard => 'Bias Dashboard';

  @override
  String get exportPDF => 'EXPORT PDF AUDIT REPORT';

  @override
  String get runAudit => 'Run Bias Audit';

  @override
  String get riskHistory => 'Risk History (Session)';

  @override
  String get highRisk => 'HIGH RISK';

  @override
  String get mediumRisk => 'MEDIUM RISK';

  @override
  String get lowRisk => 'LOW RISK';

  @override
  String get navResults => 'Results';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navClinic => 'Clinic List';

  @override
  String get navMore => 'More';

  @override
  String get navEthics => 'Ethics';

  @override
  String get navSlots => 'Slot Optimisation';

  @override
  String get navNudge => 'Patient Nudge';

  @override
  String get navAdmin => 'User Management';

  @override
  String get personalAccount => 'Personal Account';

  @override
  String get logout => 'Log Out';

  @override
  String get language => 'Language';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get orText => 'OR';

  @override
  String get assessmentIntro =>
      'Enter patient details to generate a DNA risk prediction with explainable AI outputs.';

  @override
  String get autofill => 'Auto-fill';

  @override
  String get carerProxy => 'Carer / Family Proxy';

  @override
  String get female => 'Female';

  @override
  String get male => 'Male';

  @override
  String ageGroupLine(String group) {
    return 'Age Group: $group (auto-calculated)';
  }

  @override
  String get aboutTool => 'About This Tool';

  @override
  String get aboutToolDesc =>
      'Care Attend uses machine learning to predict DNA risk. Predictions explained via SHAP. System monitors for demographic bias.';

  @override
  String get dataHandling =>
      'Data Handling: No patient data stored. Session-scoped only. GDPR Art 5(1)(c) compliant.';

  @override
  String get noAssessmentYet => 'No Assessment Yet';

  @override
  String get noAssessmentDesc =>
      'Complete a patient assessment to view results.';

  @override
  String get goToAssessment => 'Go to Assessment';

  @override
  String get plainEnglishSummary => 'Plain-English Summary';

  @override
  String get exportReport => 'Export report';

  @override
  String get feedbackQuestion => 'Was this prediction accurate?';

  @override
  String get feedbackDesc => 'Your feedback improves accuracy tracking.';

  @override
  String get feedbackAttended => 'Attended';

  @override
  String get feedbackDna => 'DNA';

  @override
  String get feedbackCorrect => 'Correct';

  @override
  String get feedbackIncorrect => 'Incorrect';

  @override
  String feedbackRecorded(String outcome) {
    return 'Feedback recorded: $outcome';
  }

  @override
  String get practiceDashboard => 'Practice Dashboard';

  @override
  String get practiceOverview =>
      'Practice-wide overview of assessments and outcomes.';

  @override
  String get statTotal => 'Total';

  @override
  String get statHigh => 'High';

  @override
  String get statMedium => 'Medium';

  @override
  String get statLow => 'Low';

  @override
  String get averageRisk => 'Average risk';

  @override
  String get recentAssessments => 'Recent assessments';

  @override
  String get noAssessmentsYet =>
      'No assessments yet. Run a Patient Assessment first.';

  @override
  String get operationalOutcomes => 'Operational Outcomes';

  @override
  String get batchUploadDesc =>
      'Upload a CSV of up to 100 patients. Required columns: Age, Gender, AppointmentLeadTimeDays, SMSReceived, PriorDNACount, IMDDecile.';

  @override
  String get batchScoring => 'Scoring…';

  @override
  String get batchPickCsv => 'Pick CSV & Score';

  @override
  String batchFile(String filename) {
    return 'File: $filename';
  }

  @override
  String get batchReadError => 'Could not read the file.';

  @override
  String get batchPatients => 'Patients';

  @override
  String batchRow(String row) {
    return 'Row $row';
  }

  @override
  String batchTopFactor(String factor) {
    return 'Top factor: $factor';
  }

  @override
  String get ethicsFramework => 'Ethics Framework';

  @override
  String get ethicsSubtitle =>
      'NHS England (2024) six-principle mapping with evidence.';

  @override
  String get ethicsCvTitle => 'Cross-Validation (5-Fold)';

  @override
  String get ethicsCvDesc =>
      'Bootstrap 95% CIs and McNemar significance tests.';

  @override
  String get ethicsCvRunning => 'Running…';

  @override
  String get ethicsCvRun => 'Run Cross-Validation';

  @override
  String get ethicsMcnemar => 'McNemar significance';

  @override
  String get ethicsSignificant => '(significant)';

  @override
  String get ethicsMeanF1 => 'Mean F1';

  @override
  String get ethicsRecall => 'Recall';

  @override
  String get ethicsRocAuc => 'ROC-AUC';

  @override
  String ethicsCi(String lo, String hi) {
    return '95% CI (F1): [$lo, $hi]';
  }

  @override
  String get nudgeTitle => 'Patient Nudge';

  @override
  String get nudgeSubtitle =>
      'Generate a personalised, non-stigmatising outreach message.';

  @override
  String get nudgeName => 'Patient name (optional)';

  @override
  String get nudgeAge => 'Age';

  @override
  String get nudgeImd => 'IMD (1-10)';

  @override
  String get nudgeLeadDays => 'Lead days';

  @override
  String get nudgePriorDnas => 'Prior DNAs';

  @override
  String get nudgeSmsSent => 'SMS reminder sent';

  @override
  String get nudgeGenerating => 'Generating…';

  @override
  String get nudgeGenerate => 'Generate message';

  @override
  String get nudgeCopy => 'Copy message';

  @override
  String get nudgeCopied => 'Message copied to clipboard.';

  @override
  String get nudgeUseAssessment => 'Use last assessment';

  @override
  String get nudgeNoAssessment =>
      'Fill in the Assessment form first, then generate a nudge.';

  @override
  String get adminTitle => 'User Management';

  @override
  String get adminSubtitle =>
      'Admin only. New sign-ups start as read-only users — promote trusted colleagues here.';

  @override
  String get adminRoleUpdated => 'Role updated.';

  @override
  String get adminDeleteTitle => 'Delete user';

  @override
  String adminDeleteConfirm(String username) {
    return 'Delete \"$username\"? This cannot be undone.';
  }

  @override
  String get adminCancel => 'Cancel';

  @override
  String get adminDelete => 'Delete';

  @override
  String get adminDeleted => 'Deleted.';

  @override
  String get adminRolePerms => 'Role Permissions';

  @override
  String get adminFeature => 'Feature';

  @override
  String get adminRoleUser => 'User';

  @override
  String get adminRoleStaff => 'Staff';

  @override
  String get adminRoleAdmin => 'Admin';

  @override
  String get adminPermAssessment => 'Assessment + Results';

  @override
  String get adminPermDashboard => 'Dashboard, Slots, Nudge';

  @override
  String get adminPermBias => 'Bias, Ethics, Model info';

  @override
  String get adminPermAudit => 'Audit log, User management';

  @override
  String get adminRoleLabel => 'Role:';

  @override
  String get slotsTitle => 'Slot Optimisation';

  @override
  String get slotsSubtitle =>
      'Estimate DNA risk for a slot and whether it can be overbooked.';

  @override
  String get slotsSlotMins => 'Slot mins';

  @override
  String get slotsAnalysing => 'Analysing…';

  @override
  String get slotsAnalyse => 'Analyse slot';

  @override
  String get slotsOverbookable => 'Overbookable';

  @override
  String get slotsExpectedWaste => 'Expected waste';

  @override
  String get slotsRecoveryPotential => 'Recovery potential';

  @override
  String slotsRiskLine(String prob, String tier) {
    return '$prob% DNA risk · $tier';
  }

  @override
  String get slotsCanOverbookLabel => 'Can overbook:';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String slotsWastedMinutes(String min) {
    return 'Expected wasted minutes: $min';
  }

  @override
  String get biasMonitorTitle => 'Ethical Bias Monitoring Dashboard';

  @override
  String get biasSubtitle =>
      'Fairness metrics across protected characteristic groups. Threshold: 0.10.';

  @override
  String get biasTabAge => 'Age';

  @override
  String get biasTabImd => 'IMD';

  @override
  String get biasAuditFailed => 'Audit failed. Check server connection.';

  @override
  String get biasExportAudit => 'Export audit';

  @override
  String get biasOverallPerf => 'Overall Model Performance';

  @override
  String get biasF1 => 'F1-Score';

  @override
  String get biasPrecision => 'Precision';

  @override
  String get biasSamples => 'Samples';

  @override
  String get biasAgeGroup => 'Age Group';

  @override
  String get biasImdBand => 'IMD Band';

  @override
  String get biasDpDiff => 'DEMOGRAPHIC PARITY DIFFERENCE';

  @override
  String get biasPass => 'Pass';

  @override
  String get biasFail => 'Fail';

  @override
  String get biasBarPass => 'PASS';

  @override
  String get biasBarWarn => 'WARN';

  @override
  String get biasBarFail => 'FAIL';

  @override
  String get biasNameAge => 'age';

  @override
  String get biasNameGender => 'gender';

  @override
  String get biasNameImd => 'IMD';

  @override
  String get biasFailDp => 'demographic parity';

  @override
  String get biasFailEo => 'equalised odds';

  @override
  String get biasSummaryPass =>
      'Model shows acceptable fairness across all protected attribute groups. All metrics within the 0.10 threshold.';

  @override
  String biasSummaryFail(String failures) {
    return 'Model shows acceptable fairness across most age groups. The following exceed the 0.10 threshold: $failures. This may reflect genuine clinical risk rather than algorithmic bias.';
  }

  @override
  String get clinicTitle => 'Clinic List';

  @override
  String get clinicSubtitle =>
      'Score appointments and track outreach progress.';

  @override
  String get clinicNoAppointments => 'No appointments imported for this date.';

  @override
  String get clinicRefresh => 'Refresh';

  @override
  String get clinicPatientId => 'Patient ID';

  @override
  String get clinicTime => 'Time';

  @override
  String get clinicClinic => 'Clinic';

  @override
  String get clinicWorking => 'Working...';

  @override
  String get clinicAddAppointment => 'Add appointment';

  @override
  String get clinicBulkImport => 'Bulk JSON import';

  @override
  String get clinicApptsJson => 'Appointments JSON';

  @override
  String get clinicImportJson => 'Import JSON';

  @override
  String get clinicApptsLabel => 'Appointments';

  @override
  String get clinicActioned => 'Actioned';

  @override
  String get clinicNeedsAction => 'Needs action';

  @override
  String get clinicStatus => 'Status';

  @override
  String clinicActionsCount(String count) {
    return '$count action(s)';
  }

  @override
  String clinicRemindersCount(String count) {
    return '$count reminder(s)';
  }

  @override
  String get clinicNeedsOutreach => 'Needs outreach action';

  @override
  String get clinicReminder => 'Reminder';

  @override
  String get clinicCall => 'Call';

  @override
  String get clinicEnterPatientId => 'Enter a patient ID.';

  @override
  String get clinicJsonInvalid => 'Appointment JSON is not valid.';

  @override
  String clinicImported(String count) {
    return '$count appointment(s) imported.';
  }

  @override
  String get clinicStatusUpdated => 'Appointment status updated.';

  @override
  String get clinicReminderScheduled => 'Reminder scheduled.';

  @override
  String get clinicCallRecorded => 'Call action recorded.';

  @override
  String get clinicStScheduled => 'Scheduled';

  @override
  String get clinicStConfirmed => 'Confirmed';

  @override
  String get clinicStAttended => 'Attended';

  @override
  String get clinicStDna => 'DNA';

  @override
  String get clinicStCancelled => 'Cancelled';

  @override
  String get clinicStRescheduled => 'Rescheduled';

  @override
  String get profileLogoutClear => 'Log Out & Clear Session';

  @override
  String get profileUsername => 'Username';

  @override
  String get profileRole => 'Role';

  @override
  String get profileMemberSince => 'Member since';

  @override
  String get profilePasswordChanged => 'Password changed';

  @override
  String get profileNever => 'Never';

  @override
  String get profileEdit => 'Edit Profile';

  @override
  String get profileDisplayName => 'Display name';

  @override
  String get profileJobTitle => 'Job title';

  @override
  String get profileDepartment => 'Department';

  @override
  String get profilePronouns => 'Pronouns (e.g. she/her)';

  @override
  String get profilePhone => 'Phone';

  @override
  String get profileBio => 'Bio';

  @override
  String get profileSaving => 'Saving…';

  @override
  String get profileSaveBtn => 'Save Profile';

  @override
  String get profileChangePassword => 'Change Password';

  @override
  String get profileCurrentPw => 'Current password';

  @override
  String get profileNewPw => 'New password';

  @override
  String get profileConfirmPw => 'Confirm new password';

  @override
  String get profileUpdatePw => 'Update password';

  @override
  String get profile2faTitle => 'Two-Factor Authentication';

  @override
  String get profile2faEnabledBadge => 'ENABLED';

  @override
  String get profile2faDisabledBadge => 'DISABLED';

  @override
  String get profile2faDesc =>
      'Add a time-based one-time code from an authenticator app (Google Authenticator, Authy).';

  @override
  String get profile2faPwDisable => 'Password to disable';

  @override
  String get profile2faDisableBtn => 'Disable 2FA';

  @override
  String get profile2faWait => 'Please wait…';

  @override
  String get profile2faEnableBtn => 'Enable 2FA';

  @override
  String get profile2faStep1 => '1. Add this secret to your authenticator app:';

  @override
  String get profile2faStep2 => '2. Enter the 6-digit code to verify:';

  @override
  String get profile2faVerify => 'Verify & enable';

  @override
  String get profilePrivacy => 'Privacy & Data Protection';

  @override
  String get profilePrivGdprT => 'GDPR Article 5(1)(c) compliant';

  @override
  String get profilePrivGdprB =>
      'Data minimisation — only essential fields collected.';

  @override
  String get profilePrivSessionT => 'Session-scoped processing';

  @override
  String get profilePrivSessionB =>
      'No patient data stored. Cleared on logout.';

  @override
  String get profilePrivEncT => 'Encrypted authentication';

  @override
  String get profilePrivEncB =>
      'Passwords hashed with bcrypt; sessions expire on inactivity.';

  @override
  String get profilePrivShareT => 'No third-party data sharing';

  @override
  String get profilePrivShareB =>
      'All processing local. No external analytics or tracking.';

  @override
  String get profileViewPhoto => 'View photo';

  @override
  String get profileChangePhoto => 'Change photo';

  @override
  String get profileAddPhoto => 'Add photo';

  @override
  String get profileRemovePhoto => 'Remove photo';

  @override
  String get profilePhotoRemoved => 'Photo removed.';

  @override
  String get profileUnsupportedImage => 'Unsupported image format.';

  @override
  String get profilePhotoUpdated => 'Photo updated.';

  @override
  String get profileSaved => 'Profile saved.';

  @override
  String get profilePwDifferent =>
      'New password must be different from the current password';

  @override
  String get profilePwMismatch => 'Passwords do not match';

  @override
  String get profilePwChanged => 'Password changed successfully';

  @override
  String get profile2faEnterCode =>
      'Enter the 6-digit code from your authenticator app.';

  @override
  String get profile2faEnabled => 'Two-factor authentication enabled.';

  @override
  String get profile2faEnterPw => 'Enter your password to disable 2FA.';

  @override
  String get profile2faDisabled => 'Two-factor authentication disabled.';

  @override
  String get fpTitle => 'Reset Password';

  @override
  String get fpSubtitle =>
      'We will email you a 6-digit code to reset your password.';

  @override
  String get fpSending => 'Sending…';

  @override
  String get fpSendCode => 'Send reset code';

  @override
  String get fpCodeField => '6-digit code';

  @override
  String get fpResetting => 'Resetting…';

  @override
  String get fpResetBtn => 'Reset password';

  @override
  String get fpResend => 'Resend code';

  @override
  String get fpEnterEmail => 'Enter your email address.';

  @override
  String get fpEnterCode => 'Enter the reset code.';

  @override
  String get fpResetDone => 'Password reset! Please log in.';

  @override
  String get fpCodeSent =>
      'If that email is registered, a 6-digit code has been sent.';

  @override
  String fpDevCode(String code) {
    return 'Email not configured — your test code is $code';
  }

  @override
  String get offlineBanner =>
      'You\'re offline — pull to refresh once reconnected.';

  @override
  String get chatbotTitle => 'Care Attend AI';

  @override
  String get chatbotHint => 'Type a message…';

  @override
  String get chatbotSend => 'Send';

  @override
  String get chatbotAssistant => 'Assistant';

  @override
  String get profilePhotoA11y => 'Profile photo. Tap to change.';

  @override
  String get loadFailed => 'Couldn\'t load. Pull down or retry.';

  @override
  String get commonRetry => 'Retry';
}
