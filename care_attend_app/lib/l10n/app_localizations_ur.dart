// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get appTitle => 'Care Attend';

  @override
  String get appSubtitle => 'NHS پیشن گوئی خطرے کی تشخیص';

  @override
  String get welcomeBack => 'واپسی پر خوش آمدید';

  @override
  String get signInDesc => 'اپنے پریکٹس ڈیش بورڈ تک رسائی کے لیے سائن ان کریں';

  @override
  String get emailAddress => 'ای میل یا صارف نام';

  @override
  String get password => 'پاس ورڈ';

  @override
  String get login => 'لاگ ان';

  @override
  String get createAccount => 'نیا اکاؤنٹ بنائیں';

  @override
  String get backToLogin => 'لاگ ان پر واپس';

  @override
  String get dataProtection => 'ڈیٹا تحفظ کا نوٹس';

  @override
  String get noDataStored => 'مریض کا ڈیٹا اس آلے پر محفوظ نہیں ہے۔';

  @override
  String get sessionCleared => 'تمام سیشن ڈیٹا بند ہونے پر صاف ہو جاتا ہے۔';

  @override
  String get gdprCompliant => 'GDPR آرٹیکل 5(1)(c) کے مطابق۔';

  @override
  String get patientAssessment => 'مریض کی تشخیص';

  @override
  String get riskDashboard => 'خطرے کا ڈیش بورڈ';

  @override
  String get batchUpload => 'بیچ اپ لوڈ';

  @override
  String get biasMonitor => 'تعصب مانیٹر';

  @override
  String get demographics => 'آبادیات';

  @override
  String get appointmentDetails => 'ملاقات کی تفصیلات';

  @override
  String get clinicalFlags => 'طبی جھنڈے';

  @override
  String get socialContext => 'سماجی سیاق و سباق';

  @override
  String get assessRisk => 'خطرے کا جائزہ لیں';

  @override
  String get age => 'عمر (0-120)';

  @override
  String get gender => 'جنس';

  @override
  String get leadTime => 'لیڈ ٹائم (دن)';

  @override
  String get priorDNA => 'پہلے DNA کاؤنٹ';

  @override
  String get smsReceived => 'SMS یاد دہانی موصول ہوئی';

  @override
  String get hypertension => 'ہائی بلڈ پریشر';

  @override
  String get diabetes => 'ذیابیطس';

  @override
  String get alcoholism => 'شراب نوشی';

  @override
  String get disability => 'رجسٹرڈ معذوری';

  @override
  String get imdDecile => 'IMD دسواں حصہ (1-10)';

  @override
  String get riskLevel => 'DNA خطرے کی سطح';

  @override
  String get whyThisScore => 'یہ سکور کیوں؟ (SHAP)';

  @override
  String get increasesRisk => 'خطرہ بڑھاتا ہے';

  @override
  String get reducesRisk => 'خطرہ کم کرتا ہے';

  @override
  String get interventions => 'تجویز کردہ مداخلتیں';

  @override
  String get newAssessment => 'نئی تشخیص';

  @override
  String get biasDashboard => 'تعصب ڈیش بورڈ';

  @override
  String get exportPDF => 'PDF آڈٹ رپورٹ برآمد کریں';

  @override
  String get runAudit => 'تعصب کا آڈٹ چلائیں';

  @override
  String get riskHistory => 'خطرے کی تاریخ (سیشن)';

  @override
  String get highRisk => 'زیادہ خطرہ';

  @override
  String get mediumRisk => 'درمیانہ خطرہ';

  @override
  String get lowRisk => 'کم خطرہ';

  @override
  String get navResults => 'نتائج';

  @override
  String get navDashboard => 'ڈیش بورڈ';

  @override
  String get navClinic => 'کلینک کی فہرست';

  @override
  String get navMore => 'مزید';

  @override
  String get navEthics => 'اخلاقیات';

  @override
  String get navSlots => 'سلاٹ بہتری';

  @override
  String get navNudge => 'مریض کو یاد دہانی';

  @override
  String get navAdmin => 'صارف کا انتظام';

  @override
  String get personalAccount => 'ذاتی اکاؤنٹ';

  @override
  String get logout => 'لاگ آؤٹ';

  @override
  String get language => 'زبان';

  @override
  String get rememberMe => 'مجھے یاد رکھیں';

  @override
  String get forgotPassword => 'پاس ورڈ بھول گئے؟';

  @override
  String get orText => 'یا';

  @override
  String get assessmentIntro =>
      'قابل وضاحت AI نتائج کے ساتھ DNA خطرے کی پیش گوئی پیدا کرنے کے لیے مریض کی تفصیلات درج کریں۔';

  @override
  String get autofill => 'خودکار بھریں';

  @override
  String get carerProxy => 'نگہداشت کنندہ / خاندانی نمائندہ';

  @override
  String get female => 'خاتون';

  @override
  String get male => 'مرد';

  @override
  String ageGroupLine(String group) {
    return 'عمر کا گروپ: $group (خودکار حساب)';
  }

  @override
  String get aboutTool => 'اس آلے کے بارے میں';

  @override
  String get aboutToolDesc =>
      'Care Attend مشین لرننگ کا استعمال کرتے ہوئے DNA خطرے کی پیش گوئی کرتا ہے۔ پیش گوئیاں SHAP کے ذریعے بیان کی جاتی ہیں۔ نظام آبادیاتی تعصب کی نگرانی کرتا ہے۔';

  @override
  String get dataHandling =>
      'ڈیٹا ہینڈلنگ: مریض کا ڈیٹا محفوظ نہیں۔ صرف سیشن۔ GDPR آرٹیکل 5(1)(c) کے مطابق۔';

  @override
  String get noAssessmentYet => 'ابھی تک کوئی تشخیص نہیں';

  @override
  String get noAssessmentDesc => 'نتائج دیکھنے کے لیے مریض کی تشخیص مکمل کریں۔';

  @override
  String get goToAssessment => 'تشخیص پر جائیں';

  @override
  String get plainEnglishSummary => 'سادہ زبان میں خلاصہ';

  @override
  String get exportReport => 'رپورٹ برآمد کریں';

  @override
  String get feedbackQuestion => 'کیا یہ پیش گوئی درست تھی؟';

  @override
  String get feedbackDesc => 'آپ کی رائے درستگی کی نگرانی بہتر بناتی ہے۔';

  @override
  String get feedbackAttended => 'حاضر ہوا';

  @override
  String get feedbackDna => 'غیر حاضر';

  @override
  String get feedbackCorrect => 'درست';

  @override
  String get feedbackIncorrect => 'غلط';

  @override
  String feedbackRecorded(String outcome) {
    return 'رائے درج کی گئی: $outcome';
  }

  @override
  String get practiceDashboard => 'پریکٹس ڈیش بورڈ';

  @override
  String get practiceOverview => 'تشخیص اور نتائج کا پریکٹس وسیع جائزہ۔';

  @override
  String get statTotal => 'کل';

  @override
  String get statHigh => 'زیادہ';

  @override
  String get statMedium => 'درمیانہ';

  @override
  String get statLow => 'کم';

  @override
  String get averageRisk => 'اوسط خطرہ';

  @override
  String get recentAssessments => 'حالیہ تشخیصات';

  @override
  String get noAssessmentsYet =>
      'ابھی تک کوئی تشخیص نہیں۔ پہلے مریض کی تشخیص کریں۔';

  @override
  String get operationalOutcomes => 'آپریشنل نتائج';

  @override
  String get batchUploadDesc =>
      'زیادہ سے زیادہ 100 مریضوں کی CSV اپ لوڈ کریں۔ مطلوبہ کالم: Age, Gender, AppointmentLeadTimeDays, SMSReceived, PriorDNACount, IMDDecile۔';

  @override
  String get batchScoring => 'اسکورنگ…';

  @override
  String get batchPickCsv => 'CSV منتخب کریں اور اسکور کریں';

  @override
  String batchFile(String filename) {
    return 'فائل: $filename';
  }

  @override
  String get batchReadError => 'فائل پڑھی نہیں جا سکی۔';

  @override
  String get batchPatients => 'مریض';

  @override
  String batchRow(String row) {
    return 'قطار $row';
  }

  @override
  String batchTopFactor(String factor) {
    return 'اہم عنصر: $factor';
  }

  @override
  String get ethicsFramework => 'اخلاقی فریم ورک';

  @override
  String get ethicsSubtitle =>
      'NHS England (2024) چھ اصولوں کی نقشہ سازی شواہد کے ساتھ۔';

  @override
  String get ethicsCvTitle => 'کراس ویلیڈیشن (5-فولڈ)';

  @override
  String get ethicsCvDesc => 'بوٹ سٹریپ 95% CI اور McNemar اہمیت کے ٹیسٹ۔';

  @override
  String get ethicsCvRunning => 'چل رہا ہے…';

  @override
  String get ethicsCvRun => 'کراس ویلیڈیشن چلائیں';

  @override
  String get ethicsMcnemar => 'McNemar اہمیت';

  @override
  String get ethicsSignificant => '(اہم)';

  @override
  String get ethicsMeanF1 => 'اوسط F1';

  @override
  String get ethicsRecall => 'ریکال';

  @override
  String get ethicsRocAuc => 'ROC-AUC';

  @override
  String ethicsCi(String lo, String hi) {
    return '95% CI (F1): [$lo، $hi]';
  }

  @override
  String get nudgeTitle => 'مریض کی یاد دہانی';

  @override
  String get nudgeSubtitle =>
      'ذاتی نوعیت کا، غیر داغ دار رابطہ پیغام تیار کریں۔';

  @override
  String get nudgeName => 'مریض کا نام (اختیاری)';

  @override
  String get nudgeAge => 'عمر';

  @override
  String get nudgeImd => 'IMD (1-10)';

  @override
  String get nudgeLeadDays => 'لیڈ دن';

  @override
  String get nudgePriorDnas => 'پہلے کی DNAs';

  @override
  String get nudgeSmsSent => 'SMS یاد دہانی بھیجی گئی';

  @override
  String get nudgeGenerating => 'تیار ہو رہا ہے…';

  @override
  String get nudgeGenerate => 'پیغام تیار کریں';

  @override
  String get adminTitle => 'صارف کا انتظام';

  @override
  String get adminSubtitle =>
      'صرف ایڈمن۔ نئے سائن اپ صرف پڑھنے والے صارفین کے طور پر شروع ہوتے ہیں — قابل اعتماد ساتھیوں کو یہاں ترقی دیں۔';

  @override
  String get adminRoleUpdated => 'کردار اپ ڈیٹ ہو گیا۔';

  @override
  String get adminDeleteTitle => 'صارف کو حذف کریں';

  @override
  String adminDeleteConfirm(String username) {
    return '\"$username\" کو حذف کریں؟ یہ واپس نہیں کیا جا سکتا۔';
  }

  @override
  String get adminCancel => 'منسوخ کریں';

  @override
  String get adminDelete => 'حذف کریں';

  @override
  String get adminDeleted => 'حذف ہو گیا۔';

  @override
  String get adminRolePerms => 'کردار کی اجازتیں';

  @override
  String get adminFeature => 'خصوصیت';

  @override
  String get adminRoleUser => 'صارف';

  @override
  String get adminRoleStaff => 'عملہ';

  @override
  String get adminRoleAdmin => 'ایڈمن';

  @override
  String get adminPermAssessment => 'تشخیص + نتائج';

  @override
  String get adminPermDashboard => 'ڈیش بورڈ، سلاٹس، یاد دہانی';

  @override
  String get adminPermBias => 'تعصب، اخلاقیات، ماڈل معلومات';

  @override
  String get adminPermAudit => 'آڈٹ لاگ، صارف کا انتظام';

  @override
  String get adminRoleLabel => 'کردار:';

  @override
  String get slotsTitle => 'سلاٹ کی اصلاح';

  @override
  String get slotsSubtitle =>
      'ایک سلاٹ کے لیے DNA کے خطرے کا تخمینہ لگائیں اور آیا اسے اوور بک کیا جا سکتا ہے۔';

  @override
  String get slotsSlotMins => 'سلاٹ منٹ';

  @override
  String get slotsAnalysing => 'تجزیہ ہو رہا ہے…';

  @override
  String get slotsAnalyse => 'سلاٹ کا تجزیہ کریں';

  @override
  String get slotsOverbookable => 'اوور بک کے قابل';

  @override
  String get slotsExpectedWaste => 'متوقع ضیاع';

  @override
  String get slotsRecoveryPotential => 'بحالی کی صلاحیت';

  @override
  String slotsRiskLine(String prob, String tier) {
    return '$prob% DNA خطرہ · $tier';
  }

  @override
  String get slotsCanOverbookLabel => 'اوور بک کر سکتے ہیں:';

  @override
  String get commonYes => 'ہاں';

  @override
  String get commonNo => 'نہیں';

  @override
  String slotsWastedMinutes(String min) {
    return 'متوقع ضائع منٹ: $min';
  }

  @override
  String get biasMonitorTitle => 'اخلاقی تعصب کی نگرانی کا ڈیش بورڈ';

  @override
  String get biasSubtitle =>
      'محفوظ خصوصیات کے گروپوں میں انصاف کے میٹرکس۔ حد: 0.10۔';

  @override
  String get biasTabAge => 'عمر';

  @override
  String get biasTabImd => 'IMD';

  @override
  String get biasAuditFailed => 'آڈٹ ناکام ہو گیا۔ سرور کنکشن چیک کریں۔';

  @override
  String get biasExportAudit => 'آڈٹ برآمد کریں';

  @override
  String get biasOverallPerf => 'ماڈل کی مجموعی کارکردگی';

  @override
  String get biasF1 => 'F1 سکور';

  @override
  String get biasPrecision => 'درستگی';

  @override
  String get biasSamples => 'نمونے';

  @override
  String get biasAgeGroup => 'عمر کا گروپ';

  @override
  String get biasImdBand => 'IMD بینڈ';

  @override
  String get biasDpDiff => 'ڈیموگرافک پیریٹی فرق';

  @override
  String get biasPass => 'پاس';

  @override
  String get biasFail => 'ناکام';

  @override
  String get biasBarPass => 'پاس';

  @override
  String get biasBarWarn => 'انتباہ';

  @override
  String get biasBarFail => 'ناکام';

  @override
  String get biasNameAge => 'عمر';

  @override
  String get biasNameGender => 'جنس';

  @override
  String get biasNameImd => 'IMD';

  @override
  String get biasFailDp => 'ڈیموگرافک پیریٹی';

  @override
  String get biasFailEo => 'مساوی امکانات';

  @override
  String get biasSummaryPass =>
      'ماڈل تمام محفوظ خصوصیات کے گروپوں میں قابل قبول انصاف دکھاتا ہے۔ تمام میٹرکس 0.10 کی حد کے اندر ہیں۔';

  @override
  String biasSummaryFail(String failures) {
    return 'ماڈل زیادہ تر عمر کے گروپوں میں قابل قبول انصاف دکھاتا ہے۔ درج ذیل 0.10 کی حد سے تجاوز کرتے ہیں: $failures۔ یہ الگورتھمک تعصب کے بجائے حقیقی طبی خطرے کی عکاسی کر سکتا ہے۔';
  }

  @override
  String get clinicTitle => 'کلینک کی فہرست';

  @override
  String get clinicSubtitle =>
      'ملاقاتوں کو اسکور کریں اور رابطے کی پیش رفت کو ٹریک کریں۔';

  @override
  String get clinicNoAppointments =>
      'اس تاریخ کے لیے کوئی ملاقات درآمد نہیں کی گئی۔';

  @override
  String get clinicRefresh => 'ریفریش کریں';

  @override
  String get clinicPatientId => 'مریض کی شناخت';

  @override
  String get clinicTime => 'وقت';

  @override
  String get clinicClinic => 'کلینک';

  @override
  String get clinicWorking => 'کام جاری ہے...';

  @override
  String get clinicAddAppointment => 'ملاقات شامل کریں';

  @override
  String get clinicBulkImport => 'بلک JSON درآمد';

  @override
  String get clinicApptsJson => 'ملاقاتوں کا JSON';

  @override
  String get clinicImportJson => 'JSON درآمد کریں';

  @override
  String get clinicApptsLabel => 'ملاقاتیں';

  @override
  String get clinicActioned => 'کارروائی شدہ';

  @override
  String get clinicNeedsAction => 'کارروائی درکار';

  @override
  String get clinicStatus => 'حیثیت';

  @override
  String clinicActionsCount(String count) {
    return '$count کارروائیاں';
  }

  @override
  String clinicRemindersCount(String count) {
    return '$count یاد دہانیاں';
  }

  @override
  String get clinicNeedsOutreach => 'رابطے کی کارروائی درکار';

  @override
  String get clinicReminder => 'یاد دہانی';

  @override
  String get clinicCall => 'کال';

  @override
  String get clinicEnterPatientId => 'مریض کی شناخت درج کریں۔';

  @override
  String get clinicJsonInvalid => 'ملاقات کا JSON درست نہیں ہے۔';

  @override
  String clinicImported(String count) {
    return '$count ملاقاتیں درآمد کی گئیں۔';
  }

  @override
  String get clinicStatusUpdated => 'ملاقات کی حیثیت اپ ڈیٹ ہو گئی۔';

  @override
  String get clinicReminderScheduled => 'یاد دہانی طے شدہ۔';

  @override
  String get clinicCallRecorded => 'کال کارروائی ریکارڈ کی گئی۔';

  @override
  String get clinicStScheduled => 'طے شدہ';

  @override
  String get clinicStConfirmed => 'تصدیق شدہ';

  @override
  String get clinicStAttended => 'حاضر ہوا';

  @override
  String get clinicStDna => 'DNA';

  @override
  String get clinicStCancelled => 'منسوخ شدہ';

  @override
  String get clinicStRescheduled => 'دوبارہ طے شدہ';
}
