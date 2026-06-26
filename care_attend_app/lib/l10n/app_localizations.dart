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
