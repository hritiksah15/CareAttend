import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_cy.dart';
import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('cy'),
    Locale('en'),
    Locale('pl'),
    Locale('ur')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Care Attend'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'NHS Predictive Risk Assessment'**
  String get appSubtitle;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @signInDesc.
  ///
  /// In en, this message translates to:
  /// **'Sign in to access your practice dashboard'**
  String get signInDesc;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email or Username'**
  String get emailAddress;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'LOG IN'**
  String get login;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'CREATE NEW ACCOUNT'**
  String get createAccount;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'BACK TO LOGIN'**
  String get backToLogin;

  /// No description provided for @dataProtection.
  ///
  /// In en, this message translates to:
  /// **'Data Protection Notice'**
  String get dataProtection;

  /// No description provided for @noDataStored.
  ///
  /// In en, this message translates to:
  /// **'No patient data is stored on this device.'**
  String get noDataStored;

  /// No description provided for @sessionCleared.
  ///
  /// In en, this message translates to:
  /// **'All session data is cleared on close.'**
  String get sessionCleared;

  /// No description provided for @gdprCompliant.
  ///
  /// In en, this message translates to:
  /// **'GDPR Article 5(1)(c) compliant.'**
  String get gdprCompliant;

  /// No description provided for @patientAssessment.
  ///
  /// In en, this message translates to:
  /// **'Patient Assessment'**
  String get patientAssessment;

  /// No description provided for @riskDashboard.
  ///
  /// In en, this message translates to:
  /// **'Risk Dashboard'**
  String get riskDashboard;

  /// No description provided for @batchUpload.
  ///
  /// In en, this message translates to:
  /// **'Batch Upload'**
  String get batchUpload;

  /// No description provided for @biasMonitor.
  ///
  /// In en, this message translates to:
  /// **'Bias Monitor'**
  String get biasMonitor;

  /// No description provided for @demographics.
  ///
  /// In en, this message translates to:
  /// **'DEMOGRAPHICS'**
  String get demographics;

  /// No description provided for @appointmentDetails.
  ///
  /// In en, this message translates to:
  /// **'APPOINTMENT DETAILS'**
  String get appointmentDetails;

  /// No description provided for @clinicalFlags.
  ///
  /// In en, this message translates to:
  /// **'CLINICAL FLAGS'**
  String get clinicalFlags;

  /// No description provided for @socialContext.
  ///
  /// In en, this message translates to:
  /// **'SOCIAL CONTEXT'**
  String get socialContext;

  /// No description provided for @assessRisk.
  ///
  /// In en, this message translates to:
  /// **'ASSESS RISK'**
  String get assessRisk;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age (0-120)'**
  String get age;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @leadTime.
  ///
  /// In en, this message translates to:
  /// **'Lead Time (days)'**
  String get leadTime;

  /// No description provided for @priorDNA.
  ///
  /// In en, this message translates to:
  /// **'Prior DNA Count'**
  String get priorDNA;

  /// No description provided for @smsReceived.
  ///
  /// In en, this message translates to:
  /// **'SMS Reminder Received'**
  String get smsReceived;

  /// No description provided for @hypertension.
  ///
  /// In en, this message translates to:
  /// **'Hypertension'**
  String get hypertension;

  /// No description provided for @diabetes.
  ///
  /// In en, this message translates to:
  /// **'Diabetes'**
  String get diabetes;

  /// No description provided for @alcoholism.
  ///
  /// In en, this message translates to:
  /// **'Alcohol Dependency'**
  String get alcoholism;

  /// No description provided for @disability.
  ///
  /// In en, this message translates to:
  /// **'Registered Disability'**
  String get disability;

  /// No description provided for @imdDecile.
  ///
  /// In en, this message translates to:
  /// **'IMD Decile (1-10)'**
  String get imdDecile;

  /// No description provided for @riskLevel.
  ///
  /// In en, this message translates to:
  /// **'DNA Risk Level'**
  String get riskLevel;

  /// No description provided for @whyThisScore.
  ///
  /// In en, this message translates to:
  /// **'Why This Score? (SHAP)'**
  String get whyThisScore;

  /// No description provided for @increasesRisk.
  ///
  /// In en, this message translates to:
  /// **'Increases Risk'**
  String get increasesRisk;

  /// No description provided for @reducesRisk.
  ///
  /// In en, this message translates to:
  /// **'Reduces Risk'**
  String get reducesRisk;

  /// No description provided for @interventions.
  ///
  /// In en, this message translates to:
  /// **'Recommended Interventions'**
  String get interventions;

  /// No description provided for @newAssessment.
  ///
  /// In en, this message translates to:
  /// **'New Assessment'**
  String get newAssessment;

  /// No description provided for @biasDashboard.
  ///
  /// In en, this message translates to:
  /// **'Bias Dashboard'**
  String get biasDashboard;

  /// No description provided for @exportPDF.
  ///
  /// In en, this message translates to:
  /// **'EXPORT PDF AUDIT REPORT'**
  String get exportPDF;

  /// No description provided for @runAudit.
  ///
  /// In en, this message translates to:
  /// **'Run Bias Audit'**
  String get runAudit;

  /// No description provided for @riskHistory.
  ///
  /// In en, this message translates to:
  /// **'Risk History (Session)'**
  String get riskHistory;

  /// No description provided for @highRisk.
  ///
  /// In en, this message translates to:
  /// **'HIGH RISK'**
  String get highRisk;

  /// No description provided for @mediumRisk.
  ///
  /// In en, this message translates to:
  /// **'MEDIUM RISK'**
  String get mediumRisk;

  /// No description provided for @lowRisk.
  ///
  /// In en, this message translates to:
  /// **'LOW RISK'**
  String get lowRisk;

  /// No description provided for @navResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get navResults;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navClinic.
  ///
  /// In en, this message translates to:
  /// **'Clinic List'**
  String get navClinic;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @navEthics.
  ///
  /// In en, this message translates to:
  /// **'Ethics'**
  String get navEthics;

  /// No description provided for @navSlots.
  ///
  /// In en, this message translates to:
  /// **'Slot Optimisation'**
  String get navSlots;

  /// No description provided for @navNudge.
  ///
  /// In en, this message translates to:
  /// **'Patient Nudge'**
  String get navNudge;

  /// No description provided for @navAdmin.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get navAdmin;

  /// No description provided for @personalAccount.
  ///
  /// In en, this message translates to:
  /// **'Personal Account'**
  String get personalAccount;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @orText.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orText;

  /// No description provided for @assessmentIntro.
  ///
  /// In en, this message translates to:
  /// **'Enter patient details to generate a DNA risk prediction with explainable AI outputs.'**
  String get assessmentIntro;

  /// No description provided for @autofill.
  ///
  /// In en, this message translates to:
  /// **'Auto-fill'**
  String get autofill;

  /// No description provided for @carerProxy.
  ///
  /// In en, this message translates to:
  /// **'Carer / Family Proxy'**
  String get carerProxy;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @ageGroupLine.
  ///
  /// In en, this message translates to:
  /// **'Age Group: {group} (auto-calculated)'**
  String ageGroupLine(String group);

  /// No description provided for @aboutTool.
  ///
  /// In en, this message translates to:
  /// **'About This Tool'**
  String get aboutTool;

  /// No description provided for @aboutToolDesc.
  ///
  /// In en, this message translates to:
  /// **'Care Attend uses machine learning to predict DNA risk. Predictions explained via SHAP. System monitors for demographic bias.'**
  String get aboutToolDesc;

  /// No description provided for @dataHandling.
  ///
  /// In en, this message translates to:
  /// **'Data Handling: No patient data stored. Session-scoped only. GDPR Art 5(1)(c) compliant.'**
  String get dataHandling;

  /// No description provided for @noAssessmentYet.
  ///
  /// In en, this message translates to:
  /// **'No Assessment Yet'**
  String get noAssessmentYet;

  /// No description provided for @noAssessmentDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete a patient assessment to view results.'**
  String get noAssessmentDesc;

  /// No description provided for @goToAssessment.
  ///
  /// In en, this message translates to:
  /// **'Go to Assessment'**
  String get goToAssessment;

  /// No description provided for @plainEnglishSummary.
  ///
  /// In en, this message translates to:
  /// **'Plain-English Summary'**
  String get plainEnglishSummary;

  /// No description provided for @exportReport.
  ///
  /// In en, this message translates to:
  /// **'Export report'**
  String get exportReport;

  /// No description provided for @feedbackQuestion.
  ///
  /// In en, this message translates to:
  /// **'Was this prediction accurate?'**
  String get feedbackQuestion;

  /// No description provided for @feedbackDesc.
  ///
  /// In en, this message translates to:
  /// **'Your feedback improves accuracy tracking.'**
  String get feedbackDesc;

  /// No description provided for @feedbackAttended.
  ///
  /// In en, this message translates to:
  /// **'Attended'**
  String get feedbackAttended;

  /// No description provided for @feedbackDna.
  ///
  /// In en, this message translates to:
  /// **'DNA'**
  String get feedbackDna;

  /// No description provided for @feedbackCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get feedbackCorrect;

  /// No description provided for @feedbackIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect'**
  String get feedbackIncorrect;

  /// No description provided for @feedbackRecorded.
  ///
  /// In en, this message translates to:
  /// **'Feedback recorded: {outcome}'**
  String feedbackRecorded(String outcome);

  /// No description provided for @practiceDashboard.
  ///
  /// In en, this message translates to:
  /// **'Practice Dashboard'**
  String get practiceDashboard;

  /// No description provided for @practiceOverview.
  ///
  /// In en, this message translates to:
  /// **'Practice-wide overview of assessments and outcomes.'**
  String get practiceOverview;

  /// No description provided for @statTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get statTotal;

  /// No description provided for @statHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get statHigh;

  /// No description provided for @statMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get statMedium;

  /// No description provided for @statLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get statLow;

  /// No description provided for @averageRisk.
  ///
  /// In en, this message translates to:
  /// **'Average risk'**
  String get averageRisk;

  /// No description provided for @recentAssessments.
  ///
  /// In en, this message translates to:
  /// **'Recent assessments'**
  String get recentAssessments;

  /// No description provided for @noAssessmentsYet.
  ///
  /// In en, this message translates to:
  /// **'No assessments yet. Run a Patient Assessment first.'**
  String get noAssessmentsYet;

  /// No description provided for @operationalOutcomes.
  ///
  /// In en, this message translates to:
  /// **'Operational Outcomes'**
  String get operationalOutcomes;

  /// No description provided for @batchUploadDesc.
  ///
  /// In en, this message translates to:
  /// **'Upload a CSV of up to 100 patients. Required columns: Age, Gender, AppointmentLeadTimeDays, SMSReceived, PriorDNACount, IMDDecile.'**
  String get batchUploadDesc;

  /// No description provided for @batchScoring.
  ///
  /// In en, this message translates to:
  /// **'Scoring…'**
  String get batchScoring;

  /// No description provided for @batchPickCsv.
  ///
  /// In en, this message translates to:
  /// **'Pick CSV & Score'**
  String get batchPickCsv;

  /// No description provided for @batchFile.
  ///
  /// In en, this message translates to:
  /// **'File: {filename}'**
  String batchFile(String filename);

  /// No description provided for @batchReadError.
  ///
  /// In en, this message translates to:
  /// **'Could not read the file.'**
  String get batchReadError;

  /// No description provided for @batchPatients.
  ///
  /// In en, this message translates to:
  /// **'Patients'**
  String get batchPatients;

  /// No description provided for @batchRow.
  ///
  /// In en, this message translates to:
  /// **'Row {row}'**
  String batchRow(String row);

  /// No description provided for @batchTopFactor.
  ///
  /// In en, this message translates to:
  /// **'Top factor: {factor}'**
  String batchTopFactor(String factor);

  /// No description provided for @ethicsFramework.
  ///
  /// In en, this message translates to:
  /// **'Ethics Framework'**
  String get ethicsFramework;

  /// No description provided for @ethicsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'NHS England (2024) six-principle mapping with evidence.'**
  String get ethicsSubtitle;

  /// No description provided for @ethicsCvTitle.
  ///
  /// In en, this message translates to:
  /// **'Cross-Validation (5-Fold)'**
  String get ethicsCvTitle;

  /// No description provided for @ethicsCvDesc.
  ///
  /// In en, this message translates to:
  /// **'Bootstrap 95% CIs and McNemar significance tests.'**
  String get ethicsCvDesc;

  /// No description provided for @ethicsCvRunning.
  ///
  /// In en, this message translates to:
  /// **'Running…'**
  String get ethicsCvRunning;

  /// No description provided for @ethicsCvRun.
  ///
  /// In en, this message translates to:
  /// **'Run Cross-Validation'**
  String get ethicsCvRun;

  /// No description provided for @ethicsMcnemar.
  ///
  /// In en, this message translates to:
  /// **'McNemar significance'**
  String get ethicsMcnemar;

  /// No description provided for @ethicsSignificant.
  ///
  /// In en, this message translates to:
  /// **'(significant)'**
  String get ethicsSignificant;

  /// No description provided for @ethicsMeanF1.
  ///
  /// In en, this message translates to:
  /// **'Mean F1'**
  String get ethicsMeanF1;

  /// No description provided for @ethicsRecall.
  ///
  /// In en, this message translates to:
  /// **'Recall'**
  String get ethicsRecall;

  /// No description provided for @ethicsRocAuc.
  ///
  /// In en, this message translates to:
  /// **'ROC-AUC'**
  String get ethicsRocAuc;

  /// No description provided for @ethicsCi.
  ///
  /// In en, this message translates to:
  /// **'95% CI (F1): [{lo}, {hi}]'**
  String ethicsCi(String lo, String hi);

  /// No description provided for @nudgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Patient Nudge'**
  String get nudgeTitle;

  /// No description provided for @nudgeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generate a personalised, non-stigmatising outreach message.'**
  String get nudgeSubtitle;

  /// No description provided for @nudgeName.
  ///
  /// In en, this message translates to:
  /// **'Patient name (optional)'**
  String get nudgeName;

  /// No description provided for @nudgeAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get nudgeAge;

  /// No description provided for @nudgeImd.
  ///
  /// In en, this message translates to:
  /// **'IMD (1-10)'**
  String get nudgeImd;

  /// No description provided for @nudgeLeadDays.
  ///
  /// In en, this message translates to:
  /// **'Lead days'**
  String get nudgeLeadDays;

  /// No description provided for @nudgePriorDnas.
  ///
  /// In en, this message translates to:
  /// **'Prior DNAs'**
  String get nudgePriorDnas;

  /// No description provided for @nudgeSmsSent.
  ///
  /// In en, this message translates to:
  /// **'SMS reminder sent'**
  String get nudgeSmsSent;

  /// No description provided for @nudgeGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating…'**
  String get nudgeGenerating;

  /// No description provided for @nudgeGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate message'**
  String get nudgeGenerate;

  /// No description provided for @adminTitle.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get adminTitle;

  /// No description provided for @adminSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Admin only. New sign-ups start as read-only users — promote trusted colleagues here.'**
  String get adminSubtitle;

  /// No description provided for @adminRoleUpdated.
  ///
  /// In en, this message translates to:
  /// **'Role updated.'**
  String get adminRoleUpdated;

  /// No description provided for @adminDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete user'**
  String get adminDeleteTitle;

  /// No description provided for @adminDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{username}\"? This cannot be undone.'**
  String adminDeleteConfirm(String username);

  /// No description provided for @adminCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get adminCancel;

  /// No description provided for @adminDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get adminDelete;

  /// No description provided for @adminDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted.'**
  String get adminDeleted;

  /// No description provided for @adminRolePerms.
  ///
  /// In en, this message translates to:
  /// **'Role Permissions'**
  String get adminRolePerms;

  /// No description provided for @adminFeature.
  ///
  /// In en, this message translates to:
  /// **'Feature'**
  String get adminFeature;

  /// No description provided for @adminRoleUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get adminRoleUser;

  /// No description provided for @adminRoleStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get adminRoleStaff;

  /// No description provided for @adminRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminRoleAdmin;

  /// No description provided for @adminPermAssessment.
  ///
  /// In en, this message translates to:
  /// **'Assessment + Results'**
  String get adminPermAssessment;

  /// No description provided for @adminPermDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard, Slots, Nudge'**
  String get adminPermDashboard;

  /// No description provided for @adminPermBias.
  ///
  /// In en, this message translates to:
  /// **'Bias, Ethics, Model info'**
  String get adminPermBias;

  /// No description provided for @adminPermAudit.
  ///
  /// In en, this message translates to:
  /// **'Audit log, User management'**
  String get adminPermAudit;

  /// No description provided for @adminRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role:'**
  String get adminRoleLabel;

  /// No description provided for @slotsTitle.
  ///
  /// In en, this message translates to:
  /// **'Slot Optimisation'**
  String get slotsTitle;

  /// No description provided for @slotsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Estimate DNA risk for a slot and whether it can be overbooked.'**
  String get slotsSubtitle;

  /// No description provided for @slotsSlotMins.
  ///
  /// In en, this message translates to:
  /// **'Slot mins'**
  String get slotsSlotMins;

  /// No description provided for @slotsAnalysing.
  ///
  /// In en, this message translates to:
  /// **'Analysing…'**
  String get slotsAnalysing;

  /// No description provided for @slotsAnalyse.
  ///
  /// In en, this message translates to:
  /// **'Analyse slot'**
  String get slotsAnalyse;

  /// No description provided for @slotsOverbookable.
  ///
  /// In en, this message translates to:
  /// **'Overbookable'**
  String get slotsOverbookable;

  /// No description provided for @slotsExpectedWaste.
  ///
  /// In en, this message translates to:
  /// **'Expected waste'**
  String get slotsExpectedWaste;

  /// No description provided for @slotsRecoveryPotential.
  ///
  /// In en, this message translates to:
  /// **'Recovery potential'**
  String get slotsRecoveryPotential;

  /// No description provided for @slotsRiskLine.
  ///
  /// In en, this message translates to:
  /// **'{prob}% DNA risk · {tier}'**
  String slotsRiskLine(String prob, String tier);

  /// No description provided for @slotsCanOverbookLabel.
  ///
  /// In en, this message translates to:
  /// **'Can overbook:'**
  String get slotsCanOverbookLabel;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @slotsWastedMinutes.
  ///
  /// In en, this message translates to:
  /// **'Expected wasted minutes: {min}'**
  String slotsWastedMinutes(String min);

  /// No description provided for @biasMonitorTitle.
  ///
  /// In en, this message translates to:
  /// **'Ethical Bias Monitoring Dashboard'**
  String get biasMonitorTitle;

  /// No description provided for @biasSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fairness metrics across protected characteristic groups. Threshold: 0.10.'**
  String get biasSubtitle;

  /// No description provided for @biasTabAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get biasTabAge;

  /// No description provided for @biasTabImd.
  ///
  /// In en, this message translates to:
  /// **'IMD'**
  String get biasTabImd;

  /// No description provided for @biasAuditFailed.
  ///
  /// In en, this message translates to:
  /// **'Audit failed. Check server connection.'**
  String get biasAuditFailed;

  /// No description provided for @biasExportAudit.
  ///
  /// In en, this message translates to:
  /// **'Export audit'**
  String get biasExportAudit;

  /// No description provided for @biasOverallPerf.
  ///
  /// In en, this message translates to:
  /// **'Overall Model Performance'**
  String get biasOverallPerf;

  /// No description provided for @biasF1.
  ///
  /// In en, this message translates to:
  /// **'F1-Score'**
  String get biasF1;

  /// No description provided for @biasPrecision.
  ///
  /// In en, this message translates to:
  /// **'Precision'**
  String get biasPrecision;

  /// No description provided for @biasSamples.
  ///
  /// In en, this message translates to:
  /// **'Samples'**
  String get biasSamples;

  /// No description provided for @biasAgeGroup.
  ///
  /// In en, this message translates to:
  /// **'Age Group'**
  String get biasAgeGroup;

  /// No description provided for @biasImdBand.
  ///
  /// In en, this message translates to:
  /// **'IMD Band'**
  String get biasImdBand;

  /// No description provided for @biasDpDiff.
  ///
  /// In en, this message translates to:
  /// **'DEMOGRAPHIC PARITY DIFFERENCE'**
  String get biasDpDiff;

  /// No description provided for @biasPass.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get biasPass;

  /// No description provided for @biasFail.
  ///
  /// In en, this message translates to:
  /// **'Fail'**
  String get biasFail;

  /// No description provided for @biasBarPass.
  ///
  /// In en, this message translates to:
  /// **'PASS'**
  String get biasBarPass;

  /// No description provided for @biasBarWarn.
  ///
  /// In en, this message translates to:
  /// **'WARN'**
  String get biasBarWarn;

  /// No description provided for @biasBarFail.
  ///
  /// In en, this message translates to:
  /// **'FAIL'**
  String get biasBarFail;

  /// No description provided for @biasNameAge.
  ///
  /// In en, this message translates to:
  /// **'age'**
  String get biasNameAge;

  /// No description provided for @biasNameGender.
  ///
  /// In en, this message translates to:
  /// **'gender'**
  String get biasNameGender;

  /// No description provided for @biasNameImd.
  ///
  /// In en, this message translates to:
  /// **'IMD'**
  String get biasNameImd;

  /// No description provided for @biasFailDp.
  ///
  /// In en, this message translates to:
  /// **'demographic parity'**
  String get biasFailDp;

  /// No description provided for @biasFailEo.
  ///
  /// In en, this message translates to:
  /// **'equalised odds'**
  String get biasFailEo;

  /// No description provided for @biasSummaryPass.
  ///
  /// In en, this message translates to:
  /// **'Model shows acceptable fairness across all protected attribute groups. All metrics within the 0.10 threshold.'**
  String get biasSummaryPass;

  /// No description provided for @biasSummaryFail.
  ///
  /// In en, this message translates to:
  /// **'Model shows acceptable fairness across most age groups. The following exceed the 0.10 threshold: {failures}. This may reflect genuine clinical risk rather than algorithmic bias.'**
  String biasSummaryFail(String failures);

  /// No description provided for @clinicTitle.
  ///
  /// In en, this message translates to:
  /// **'Clinic List'**
  String get clinicTitle;

  /// No description provided for @clinicSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Score appointments and track outreach progress.'**
  String get clinicSubtitle;

  /// No description provided for @clinicNoAppointments.
  ///
  /// In en, this message translates to:
  /// **'No appointments imported for this date.'**
  String get clinicNoAppointments;

  /// No description provided for @clinicRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get clinicRefresh;

  /// No description provided for @clinicPatientId.
  ///
  /// In en, this message translates to:
  /// **'Patient ID'**
  String get clinicPatientId;

  /// No description provided for @clinicTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get clinicTime;

  /// No description provided for @clinicClinic.
  ///
  /// In en, this message translates to:
  /// **'Clinic'**
  String get clinicClinic;

  /// No description provided for @clinicWorking.
  ///
  /// In en, this message translates to:
  /// **'Working...'**
  String get clinicWorking;

  /// No description provided for @clinicAddAppointment.
  ///
  /// In en, this message translates to:
  /// **'Add appointment'**
  String get clinicAddAppointment;

  /// No description provided for @clinicBulkImport.
  ///
  /// In en, this message translates to:
  /// **'Bulk JSON import'**
  String get clinicBulkImport;

  /// No description provided for @clinicApptsJson.
  ///
  /// In en, this message translates to:
  /// **'Appointments JSON'**
  String get clinicApptsJson;

  /// No description provided for @clinicImportJson.
  ///
  /// In en, this message translates to:
  /// **'Import JSON'**
  String get clinicImportJson;

  /// No description provided for @clinicApptsLabel.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get clinicApptsLabel;

  /// No description provided for @clinicActioned.
  ///
  /// In en, this message translates to:
  /// **'Actioned'**
  String get clinicActioned;

  /// No description provided for @clinicNeedsAction.
  ///
  /// In en, this message translates to:
  /// **'Needs action'**
  String get clinicNeedsAction;

  /// No description provided for @clinicStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get clinicStatus;

  /// No description provided for @clinicActionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} action(s)'**
  String clinicActionsCount(String count);

  /// No description provided for @clinicRemindersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} reminder(s)'**
  String clinicRemindersCount(String count);

  /// No description provided for @clinicNeedsOutreach.
  ///
  /// In en, this message translates to:
  /// **'Needs outreach action'**
  String get clinicNeedsOutreach;

  /// No description provided for @clinicReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get clinicReminder;

  /// No description provided for @clinicCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get clinicCall;

  /// No description provided for @clinicEnterPatientId.
  ///
  /// In en, this message translates to:
  /// **'Enter a patient ID.'**
  String get clinicEnterPatientId;

  /// No description provided for @clinicJsonInvalid.
  ///
  /// In en, this message translates to:
  /// **'Appointment JSON is not valid.'**
  String get clinicJsonInvalid;

  /// No description provided for @clinicImported.
  ///
  /// In en, this message translates to:
  /// **'{count} appointment(s) imported.'**
  String clinicImported(String count);

  /// No description provided for @clinicStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Appointment status updated.'**
  String get clinicStatusUpdated;

  /// No description provided for @clinicReminderScheduled.
  ///
  /// In en, this message translates to:
  /// **'Reminder scheduled.'**
  String get clinicReminderScheduled;

  /// No description provided for @clinicCallRecorded.
  ///
  /// In en, this message translates to:
  /// **'Call action recorded.'**
  String get clinicCallRecorded;

  /// No description provided for @clinicStScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get clinicStScheduled;

  /// No description provided for @clinicStConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get clinicStConfirmed;

  /// No description provided for @clinicStAttended.
  ///
  /// In en, this message translates to:
  /// **'Attended'**
  String get clinicStAttended;

  /// No description provided for @clinicStDna.
  ///
  /// In en, this message translates to:
  /// **'DNA'**
  String get clinicStDna;

  /// No description provided for @clinicStCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get clinicStCancelled;

  /// No description provided for @clinicStRescheduled.
  ///
  /// In en, this message translates to:
  /// **'Rescheduled'**
  String get clinicStRescheduled;

  /// No description provided for @profileLogoutClear.
  ///
  /// In en, this message translates to:
  /// **'Log Out & Clear Session'**
  String get profileLogoutClear;

  /// No description provided for @profileUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get profileUsername;

  /// No description provided for @profileRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get profileRole;

  /// No description provided for @profileMemberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since'**
  String get profileMemberSince;

  /// No description provided for @profilePasswordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get profilePasswordChanged;

  /// No description provided for @profileNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get profileNever;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEdit;

  /// No description provided for @profileDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get profileDisplayName;

  /// No description provided for @profileJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Job title'**
  String get profileJobTitle;

  /// No description provided for @profileDepartment.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get profileDepartment;

  /// No description provided for @profilePronouns.
  ///
  /// In en, this message translates to:
  /// **'Pronouns (e.g. she/her)'**
  String get profilePronouns;

  /// No description provided for @profilePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get profilePhone;

  /// No description provided for @profileBio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get profileBio;

  /// No description provided for @profileSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get profileSaving;

  /// No description provided for @profileSaveBtn.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get profileSaveBtn;

  /// No description provided for @profileChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get profileChangePassword;

  /// No description provided for @profileCurrentPw.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get profileCurrentPw;

  /// No description provided for @profileNewPw.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get profileNewPw;

  /// No description provided for @profileConfirmPw.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get profileConfirmPw;

  /// No description provided for @profileUpdatePw.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get profileUpdatePw;

  /// No description provided for @profile2faTitle.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get profile2faTitle;

  /// No description provided for @profile2faEnabledBadge.
  ///
  /// In en, this message translates to:
  /// **'ENABLED'**
  String get profile2faEnabledBadge;

  /// No description provided for @profile2faDisabledBadge.
  ///
  /// In en, this message translates to:
  /// **'DISABLED'**
  String get profile2faDisabledBadge;

  /// No description provided for @profile2faDesc.
  ///
  /// In en, this message translates to:
  /// **'Add a time-based one-time code from an authenticator app (Google Authenticator, Authy).'**
  String get profile2faDesc;

  /// No description provided for @profile2faPwDisable.
  ///
  /// In en, this message translates to:
  /// **'Password to disable'**
  String get profile2faPwDisable;

  /// No description provided for @profile2faDisableBtn.
  ///
  /// In en, this message translates to:
  /// **'Disable 2FA'**
  String get profile2faDisableBtn;

  /// No description provided for @profile2faWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait…'**
  String get profile2faWait;

  /// No description provided for @profile2faEnableBtn.
  ///
  /// In en, this message translates to:
  /// **'Enable 2FA'**
  String get profile2faEnableBtn;

  /// No description provided for @profile2faStep1.
  ///
  /// In en, this message translates to:
  /// **'1. Add this secret to your authenticator app:'**
  String get profile2faStep1;

  /// No description provided for @profile2faStep2.
  ///
  /// In en, this message translates to:
  /// **'2. Enter the 6-digit code to verify:'**
  String get profile2faStep2;

  /// No description provided for @profile2faVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify & enable'**
  String get profile2faVerify;

  /// No description provided for @profilePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Data Protection'**
  String get profilePrivacy;

  /// No description provided for @profilePrivGdprT.
  ///
  /// In en, this message translates to:
  /// **'GDPR Article 5(1)(c) compliant'**
  String get profilePrivGdprT;

  /// No description provided for @profilePrivGdprB.
  ///
  /// In en, this message translates to:
  /// **'Data minimisation — only essential fields collected.'**
  String get profilePrivGdprB;

  /// No description provided for @profilePrivSessionT.
  ///
  /// In en, this message translates to:
  /// **'Session-scoped processing'**
  String get profilePrivSessionT;

  /// No description provided for @profilePrivSessionB.
  ///
  /// In en, this message translates to:
  /// **'No patient data stored. Cleared on logout.'**
  String get profilePrivSessionB;

  /// No description provided for @profilePrivEncT.
  ///
  /// In en, this message translates to:
  /// **'Encrypted authentication'**
  String get profilePrivEncT;

  /// No description provided for @profilePrivEncB.
  ///
  /// In en, this message translates to:
  /// **'Passwords hashed with bcrypt; sessions expire on inactivity.'**
  String get profilePrivEncB;

  /// No description provided for @profilePrivShareT.
  ///
  /// In en, this message translates to:
  /// **'No third-party data sharing'**
  String get profilePrivShareT;

  /// No description provided for @profilePrivShareB.
  ///
  /// In en, this message translates to:
  /// **'All processing local. No external analytics or tracking.'**
  String get profilePrivShareB;

  /// No description provided for @profileViewPhoto.
  ///
  /// In en, this message translates to:
  /// **'View photo'**
  String get profileViewPhoto;

  /// No description provided for @profileChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get profileChangePhoto;

  /// No description provided for @profileAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get profileAddPhoto;

  /// No description provided for @profileRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get profileRemovePhoto;

  /// No description provided for @profilePhotoRemoved.
  ///
  /// In en, this message translates to:
  /// **'Photo removed.'**
  String get profilePhotoRemoved;

  /// No description provided for @profileUnsupportedImage.
  ///
  /// In en, this message translates to:
  /// **'Unsupported image format.'**
  String get profileUnsupportedImage;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Photo updated.'**
  String get profilePhotoUpdated;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved.'**
  String get profileSaved;

  /// No description provided for @profilePwDifferent.
  ///
  /// In en, this message translates to:
  /// **'New password must be different from the current password'**
  String get profilePwDifferent;

  /// No description provided for @profilePwMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get profilePwMismatch;

  /// No description provided for @profilePwChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get profilePwChanged;

  /// No description provided for @profile2faEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code from your authenticator app.'**
  String get profile2faEnterCode;

  /// No description provided for @profile2faEnabled.
  ///
  /// In en, this message translates to:
  /// **'Two-factor authentication enabled.'**
  String get profile2faEnabled;

  /// No description provided for @profile2faEnterPw.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to disable 2FA.'**
  String get profile2faEnterPw;

  /// No description provided for @profile2faDisabled.
  ///
  /// In en, this message translates to:
  /// **'Two-factor authentication disabled.'**
  String get profile2faDisabled;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['cy', 'en', 'pl', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'cy':
      return AppLocalizationsCy();
    case 'en':
      return AppLocalizationsEn();
    case 'pl':
      return AppLocalizationsPl();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
