// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Welsh (`cy`).
class AppLocalizationsCy extends AppLocalizations {
  AppLocalizationsCy([String locale = 'cy']) : super(locale);

  @override
  String get appTitle => 'Care Attend';

  @override
  String get appSubtitle => 'Asesiad Risg Rhagfynegol GIG';

  @override
  String get welcomeBack => 'Croeso Nôl';

  @override
  String get signInDesc => 'Mewngofnodwch i gyrchu eich dangosfwrdd practis';

  @override
  String get emailAddress => 'E-bost neu Enw Defnyddiwr';

  @override
  String get password => 'Cyfrinair';

  @override
  String get login => 'MEWNGOFNODI';

  @override
  String get createAccount => 'CREU CYFRIF NEWYDD';

  @override
  String get backToLogin => 'YN ÔL I FEWNGOFNODI';

  @override
  String get dataProtection => 'Hysbysiad Diogelu Data';

  @override
  String get noDataStored =>
      'Nid yw data cleifion yn cael ei storio ar y ddyfais hon.';

  @override
  String get sessionCleared =>
      'Mae holl ddata sesiwn yn cael ei glirio ar gau.';

  @override
  String get gdprCompliant => 'Yn cydymffurfio ag Erthygl 5(1)(c) GDPR.';

  @override
  String get patientAssessment => 'Asesiad Claf';

  @override
  String get riskDashboard => 'Dangosfwrdd Risg';

  @override
  String get batchUpload => 'Uwchlwytho Swp';

  @override
  String get biasMonitor => 'Monitor Rhagfarn';

  @override
  String get demographics => 'DEMOGRAFFEG';

  @override
  String get appointmentDetails => 'MANYLION APWYNTIAD';

  @override
  String get clinicalFlags => 'BANERI CLINIGOL';

  @override
  String get socialContext => 'CYDESTUN CYMDEITHASOL';

  @override
  String get assessRisk => 'ASESU RISG';

  @override
  String get age => 'Oedran (0-120)';

  @override
  String get gender => 'Rhyw';

  @override
  String get leadTime => 'Amser Arwain (dyddiau)';

  @override
  String get priorDNA => 'Cyfrif DNA Blaenorol';

  @override
  String get smsReceived => 'Nodyn SMS wedi\'i Dderbyn';

  @override
  String get hypertension => 'Gorbwysedd';

  @override
  String get diabetes => 'Diabetes';

  @override
  String get alcoholism => 'Dibyniaeth Alcohol';

  @override
  String get disability => 'Anabledd Cofrestredig';

  @override
  String get imdDecile => 'Degfed IMD (1-10)';

  @override
  String get riskLevel => 'Lefel Risg DNA';

  @override
  String get whyThisScore => 'Pam y Sgôr Hon? (SHAP)';

  @override
  String get increasesRisk => 'Yn Cynyddu Risg';

  @override
  String get reducesRisk => 'Yn Lleihau Risg';

  @override
  String get interventions => 'Ymyriadau a Argymhellir';

  @override
  String get newAssessment => 'Asesiad Newydd';

  @override
  String get biasDashboard => 'Dangosfwrdd Rhagfarn';

  @override
  String get exportPDF => 'ALLFORIO ADRODDIAD ARCHWILIAD PDF';

  @override
  String get runAudit => 'Rhedeg Archwiliad Rhagfarn';

  @override
  String get riskHistory => 'Hanes Risg (Sesiwn)';

  @override
  String get highRisk => 'RISG UCHEL';

  @override
  String get mediumRisk => 'RISG CANOLIG';

  @override
  String get lowRisk => 'RISG ISEL';

  @override
  String get navResults => 'Canlyniadau';

  @override
  String get navDashboard => 'Dangosfwrdd';

  @override
  String get navClinic => 'Rhestr Clinig';

  @override
  String get navMore => 'Mwy';

  @override
  String get navEthics => 'Moeseg';

  @override
  String get navSlots => 'Slotiau';

  @override
  String get navNudge => 'Anogwr Claf';

  @override
  String get navAdmin => 'Rheoli Defnyddwyr';

  @override
  String get personalAccount => 'Cyfrif Personol';

  @override
  String get logout => 'Allgofnodi';

  @override
  String get language => 'Iaith';

  @override
  String get rememberMe => 'Cofiwch fi';

  @override
  String get forgotPassword => 'Anghofio cyfrinair?';

  @override
  String get orText => 'NEU';

  @override
  String get assessmentIntro =>
      'Rhowch fanylion y claf i gynhyrchu rhagfynegiad risg DNA gydag allbynnau AI esboniadwy.';

  @override
  String get autofill => 'Llenwi\'n awtomatig';

  @override
  String get carerProxy => 'Dirprwy Gofalwr / Teulu';

  @override
  String get female => 'Benyw';

  @override
  String get male => 'Gwryw';

  @override
  String ageGroupLine(String group) {
    return 'Grŵp Oedran: $group (cyfrifo\'n awtomatig)';
  }

  @override
  String get aboutTool => 'Am yr Offeryn Hwn';

  @override
  String get aboutToolDesc =>
      'Mae Care Attend yn defnyddio dysgu peirianyddol i ragfynegi risg DNA. Esbonnir rhagfynegiadau drwy SHAP. Mae\'r system yn monitro am ragfarn ddemograffig.';

  @override
  String get dataHandling =>
      'Trin Data: Ni storir data cleifion. Sesiwn yn unig. Yn cydymffurfio ag Erthygl 5(1)(c) GDPR.';

  @override
  String get noAssessmentYet => 'Dim Asesiad Eto';

  @override
  String get noAssessmentDesc => 'Cwblhewch asesiad claf i weld canlyniadau.';

  @override
  String get goToAssessment => 'Mynd i\'r Asesiad';

  @override
  String get plainEnglishSummary => 'Crynodeb Iaith Glir';

  @override
  String get exportReport => 'Allforio adroddiad';

  @override
  String get feedbackQuestion => 'A oedd y rhagfynegiad hwn yn gywir?';

  @override
  String get feedbackDesc => 'Mae eich adborth yn gwella tracio cywirdeb.';

  @override
  String get feedbackAttended => 'Mynychwyd';

  @override
  String get feedbackDna => 'DNA';

  @override
  String get feedbackCorrect => 'Cywir';

  @override
  String get feedbackIncorrect => 'Anghywir';

  @override
  String feedbackRecorded(String outcome) {
    return 'Adborth wedi\'i gofnodi: $outcome';
  }

  @override
  String get practiceDashboard => 'Dangosfwrdd Practis';

  @override
  String get practiceOverview =>
      'Trosolwg practis-eang o asesiadau a chanlyniadau.';

  @override
  String get statTotal => 'Cyfanswm';

  @override
  String get statHigh => 'Uchel';

  @override
  String get statMedium => 'Canolig';

  @override
  String get statLow => 'Isel';

  @override
  String get averageRisk => 'Risg cyfartalog';

  @override
  String get recentAssessments => 'Asesiadau diweddar';

  @override
  String get noAssessmentsYet =>
      'Dim asesiadau eto. Rhedwch Asesiad Claf yn gyntaf.';

  @override
  String get operationalOutcomes => 'Canlyniadau Gweithredol';

  @override
  String get batchUploadDesc =>
      'Uwchlwythwch CSV o hyd at 100 o gleifion. Colofnau gofynnol: Age, Gender, AppointmentLeadTimeDays, SMSReceived, PriorDNACount, IMDDecile.';

  @override
  String get batchScoring => 'Yn sgorio…';

  @override
  String get batchPickCsv => 'Dewis CSV a Sgorio';

  @override
  String batchFile(String filename) {
    return 'Ffeil: $filename';
  }

  @override
  String get batchReadError => 'Methwyd darllen y ffeil.';

  @override
  String get batchPatients => 'Cleifion';

  @override
  String batchRow(String row) {
    return 'Rhes $row';
  }

  @override
  String batchTopFactor(String factor) {
    return 'Prif ffactor: $factor';
  }

  @override
  String get ethicsFramework => 'Fframwaith Moeseg';

  @override
  String get ethicsSubtitle =>
      'Mapio chwe egwyddor NHS England (2024) gyda thystiolaeth.';

  @override
  String get ethicsCvTitle => 'Croes-Ddilysu (5-Plyg)';

  @override
  String get ethicsCvDesc =>
      'Cyfyngau hyder 95% bootstrap a phrofion arwyddocâd McNemar.';

  @override
  String get ethicsCvRunning => 'Yn rhedeg…';

  @override
  String get ethicsCvRun => 'Rhedeg Croes-Ddilysu';

  @override
  String get ethicsMcnemar => 'Arwyddocâd McNemar';

  @override
  String get ethicsSignificant => '(arwyddocaol)';

  @override
  String get ethicsMeanF1 => 'F1 Cymedrig';

  @override
  String get ethicsRecall => 'Dwyn i gof';

  @override
  String get ethicsRocAuc => 'ROC-AUC';

  @override
  String ethicsCi(String lo, String hi) {
    return '95% CI (F1): [$lo, $hi]';
  }

  @override
  String get nudgeTitle => 'Anogiad Claf';

  @override
  String get nudgeSubtitle =>
      'Cynhyrchu neges allgymorth bersonol, anstigmateiddio.';

  @override
  String get nudgeName => 'Enw\'r claf (dewisol)';

  @override
  String get nudgeAge => 'Oedran';

  @override
  String get nudgeImd => 'IMD (1-10)';

  @override
  String get nudgeLeadDays => 'Dyddiau arwain';

  @override
  String get nudgePriorDnas => 'DNAau blaenorol';

  @override
  String get nudgeSmsSent => 'Nodyn SMS wedi\'i anfon';

  @override
  String get nudgeGenerating => 'Yn cynhyrchu…';

  @override
  String get nudgeGenerate => 'Cynhyrchu neges';

  @override
  String get adminTitle => 'Rheoli Defnyddwyr';

  @override
  String get adminSubtitle =>
      'Gweinyddwyr yn unig. Mae cofrestriadau newydd yn dechrau fel defnyddwyr darllen yn unig — dyrchafwch gydweithwyr dibynadwy yma.';

  @override
  String get adminRoleUpdated => 'Rôl wedi\'i diweddaru.';

  @override
  String get adminDeleteTitle => 'Dileu defnyddiwr';

  @override
  String adminDeleteConfirm(String username) {
    return 'Dileu \"$username\"? Ni ellir dadwneud hyn.';
  }

  @override
  String get adminCancel => 'Canslo';

  @override
  String get adminDelete => 'Dileu';

  @override
  String get adminDeleted => 'Wedi\'i ddileu.';

  @override
  String get adminRolePerms => 'Caniatâd Rôl';

  @override
  String get adminFeature => 'Nodwedd';

  @override
  String get adminRoleUser => 'Defnyddiwr';

  @override
  String get adminRoleStaff => 'Staff';

  @override
  String get adminRoleAdmin => 'Gweinyddwr';

  @override
  String get adminPermAssessment => 'Asesiad + Canlyniadau';

  @override
  String get adminPermDashboard => 'Dangosfwrdd, Slotiau, Anogiad';

  @override
  String get adminPermBias => 'Rhagfarn, Moeseg, Gwybodaeth model';

  @override
  String get adminPermAudit => 'Cofnod archwilio, Rheoli defnyddwyr';

  @override
  String get adminRoleLabel => 'Rôl:';

  @override
  String get slotsTitle => 'Optimeiddio Slot';

  @override
  String get slotsSubtitle =>
      'Amcangyfrif risg DNA ar gyfer slot ac a ellir ei orlenwi.';

  @override
  String get slotsSlotMins => 'Munudau slot';

  @override
  String get slotsAnalysing => 'Yn dadansoddi…';

  @override
  String get slotsAnalyse => 'Dadansoddi slot';

  @override
  String get slotsOverbookable => 'Gorlenwadwy';

  @override
  String get slotsExpectedWaste => 'Gwastraff disgwyliedig';

  @override
  String get slotsRecoveryPotential => 'Potensial adfer';

  @override
  String slotsRiskLine(String prob, String tier) {
    return '$prob% risg DNA · $tier';
  }

  @override
  String get slotsCanOverbookLabel => 'Gellir gorlenwi:';

  @override
  String get commonYes => 'Iawn';

  @override
  String get commonNo => 'Na';

  @override
  String slotsWastedMinutes(String min) {
    return 'Munudau gwastraff disgwyliedig: $min';
  }

  @override
  String get biasMonitorTitle => 'Dangosfwrdd Monitro Rhagfarn Foesegol';

  @override
  String get biasSubtitle =>
      'Metrigau tegwch ar draws grwpiau nodweddion gwarchodedig. Trothwy: 0.10.';

  @override
  String get biasTabAge => 'Oedran';

  @override
  String get biasTabImd => 'IMD';

  @override
  String get biasAuditFailed =>
      'Methodd yr archwiliad. Gwiriwch gysylltiad y gweinydd.';

  @override
  String get biasExportAudit => 'Allforio archwiliad';

  @override
  String get biasOverallPerf => 'Perfformiad Model Cyffredinol';

  @override
  String get biasF1 => 'Sgôr F1';

  @override
  String get biasPrecision => 'Trachywiredd';

  @override
  String get biasSamples => 'Samplau';

  @override
  String get biasAgeGroup => 'Grŵp Oedran';

  @override
  String get biasImdBand => 'Band IMD';

  @override
  String get biasDpDiff => 'GWAHANIAETH CYDRADDOLDEB DEMOGRAFFIG';

  @override
  String get biasPass => 'Pasio';

  @override
  String get biasFail => 'Methu';

  @override
  String get biasBarPass => 'PASIO';

  @override
  String get biasBarWarn => 'RHYBUDD';

  @override
  String get biasBarFail => 'METHU';

  @override
  String get biasNameAge => 'oedran';

  @override
  String get biasNameGender => 'rhyw';

  @override
  String get biasNameImd => 'IMD';

  @override
  String get biasFailDp => 'cydraddoldeb demograffig';

  @override
  String get biasFailEo => 'ods cyfartal';

  @override
  String get biasSummaryPass =>
      'Mae\'r model yn dangos tegwch derbyniol ar draws pob grŵp priodoledd gwarchodedig. Mae pob metrig o fewn y trothwy 0.10.';

  @override
  String biasSummaryFail(String failures) {
    return 'Mae\'r model yn dangos tegwch derbyniol ar draws y rhan fwyaf o grwpiau oedran. Mae\'r canlynol yn fwy na\'r trothwy 0.10: $failures. Gall hyn adlewyrchu risg glinigol go iawn yn hytrach na rhagfarn algorithmig.';
  }
}
