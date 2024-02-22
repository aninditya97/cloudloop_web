import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/auth/auth.dart';
import 'package:cloudloop_mobile/features/settings/settings.dart';
import 'package:cloudloop_mobile/features/summary/summary.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PDFPreviewPage extends StatelessWidget {
  const PDFPreviewPage({
    Key? key,
    required this.dateRange,
  }) : super(key: key);

  final DateTimeRange dateRange;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetIt.I<AgpReportBloc>(),
      child: _PDFPreviewView(
        dateRange: dateRange,
      ),
    );
  }
}

class _PDFPreviewView extends StatefulWidget {
  const _PDFPreviewView({
    Key? key,
    required this.dateRange,
  }) : super(key: key);

  final DateTimeRange dateRange;

  @override
  State<_PDFPreviewView> createState() => _PDFPreviewViewState();
}

class _PDFPreviewViewState extends State<_PDFPreviewView> {
  late DateTimeRange? _date;
  UserProfile? _user;

  void _initalizeDateNow() {
    _date = widget.dateRange;
  }

  @override
  void initState() {
    _initalizeDateNow();
    _fetchUserData().whenComplete(_fetchData);

    super.initState();
  }

  void _fetchData() {
    context.read<AgpReportBloc>().add(
          AgpReportFetched(
            page: 1,
            startDate: _date?.start,
            endDate: _date!.end,
            userId: int.parse(_user!.id),
          ),
        );
  }

  Future<void> _fetchUserData() async {
    _user = (await GetIt.I<GetProfileUseCase>().call(
      const NoParams(),
    ))
        .foldRight(
      const UserProfile(
        gender: Gender.female,
        name: '',
        id: '',
        weight: 0,
        totalDailyDose: 0,
      ),
      (r, previous) => r,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.whiteColor,
        foregroundColor: AppColors.primarySolidColor,
        centerTitle: true,
        title: HeadingText2(
          text: context.l10n.agpReport,
          textColor: Colors.black,
        ),
      ),
      body: BlocBuilder<AgpReportBloc, AgpReportState>(
        builder: (context, state) {
          if (state is AgpReportSuccess) {
            return PdfPreview(
              maxPageWidth: 700,
              build: (format) async {
                return generateDocument(
                  format,
                  state.data,
                  _user!,
                  _date!,
                );
              },
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  Future<Uint8List> generateDocument(
    PdfPageFormat format,
    AGPReport data,
    UserProfile user,
    DateTimeRange date,
  ) async {
    final doc = pw.Document(pageMode: PdfPageMode.outlines)
      ..addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            pageFormat: format.copyWith(
              marginBottom: 0,
              marginLeft: 0,
              marginRight: 0,
              marginTop: 0,
            ),
            orientation: pw.PageOrientation.portrait,
            // buildBackground: (context) =>
            //     pw.SvgImage(svg: shape, fit: pw.BoxFit.fill),
            // theme: pw.ThemeData.withFont(
            //   base: font1,
            //   bold: font2,
            // ),
          ),
          build: (context) {
            return pw.Column(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(Dimens.appPadding),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Name',
                            style: const pw.TextStyle(color: PdfColors.black),
                          ),
                          pw.Text(
                            user.name,
                            style: const pw.TextStyle(color: PdfColors.black),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: Dimens.dp16),
                      pw.Text(
                        '${DateFormat('yyyy-MM-dd').format(
                          widget.dateRange.start,
                        )} to ${DateFormat('yyyy-MM-dd').format(
                          widget.dateRange.end,
                        )}',
                        style: const pw.TextStyle(color: PdfColors.black),
                      ),
                    ],
                  ),
                ),
                pw.Divider(),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(Dimens.appPadding),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Average glucose',
                            style: const pw.TextStyle(color: PdfColors.black),
                          ),
                          pw.Text(
                            '${data.averageGlucose?.toStringAsFixed(
                              2,
                            )} mol/L',
                            style: const pw.TextStyle(color: PdfColors.black),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: Dimens.dp8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'GMI',
                            style: const pw.TextStyle(color: PdfColors.black),
                          ),
                          pw.Text(
                            '${data.gmiPercentage?.toStringAsFixed(
                              2,
                            )} %',
                            style: const pw.TextStyle(color: PdfColors.black),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: Dimens.dp8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'GMI',
                            style: const pw.TextStyle(color: PdfColors.black),
                          ),
                          pw.Text(
                            '${data.gmiMmol?.toStringAsFixed(2)} mmol/mol',
                            style: const pw.TextStyle(color: PdfColors.black),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: Dimens.dp8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Glucose SD',
                            style: const pw.TextStyle(color: PdfColors.black),
                          ),
                          pw.Text(
                            '${data.glucoseSd?.toStringAsFixed(
                              2,
                            )} mmol/L',
                            style: const pw.TextStyle(color: PdfColors.black),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: Dimens.dp8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Glucose CV',
                            style: const pw.TextStyle(color: PdfColors.black),
                          ),
                          pw.Text(
                            '${data.glucoseCv?.toStringAsFixed(
                              2,
                            )} %',
                            style: const pw.TextStyle(color: PdfColors.black),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: Dimens.dp8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Time in target',
                            style: const pw.TextStyle(color: PdfColors.black),
                          ),
                          pw.Text(
                            '${data.timeInTarget?.toStringAsFixed(
                              2,
                            )} %',
                            style: const pw.TextStyle(color: PdfColors.black),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: Dimens.dp8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Time below target',
                            style: const pw.TextStyle(color: PdfColors.black),
                          ),
                          pw.Text(
                            '${data.timeAboveTarget?.toStringAsFixed(
                              2,
                            )} %',
                            style: const pw.TextStyle(color: PdfColors.black),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: Dimens.dp8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Time above target',
                            style: const pw.TextStyle(color: PdfColors.black),
                          ),
                          pw.Text(
                            '${data.timeBelowTarget?.toStringAsFixed(
                              2,
                            )} %',
                            style: const pw.TextStyle(color: PdfColors.black),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: Dimens.dp8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Number of hypos',
                            style: const pw.TextStyle(color: PdfColors.black),
                          ),
                          pw.Text(
                            '${data.numberOfHypos?.toStringAsFixed(
                              2,
                            )}',
                            style: const pw.TextStyle(color: PdfColors.black),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: Dimens.dp8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Average hypo duration',
                            style: const pw.TextStyle(color: PdfColors.black),
                          ),
                          pw.Text(
                            '${data.averageHypoDuration?.toStringAsFixed(
                              2,
                            )} minutes',
                            style: const pw.TextStyle(color: PdfColors.black),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: Dimens.dp8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Sensor glucose availability',
                            style: const pw.TextStyle(color: PdfColors.black),
                          ),
                          pw.Text(
                            '${data.sensorGlucoseAvailability?.toStringAsFixed(
                              2,
                            )} %',
                            style: const pw.TextStyle(color: PdfColors.black),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.Divider(),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(Dimens.appPadding),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Total daily dose',
                            style: const pw.TextStyle(color: PdfColors.black),
                          ),
                          pw.Text(
                            '${0.toStringAsFixed(
                              2,
                            )} U/day',
                            style: const pw.TextStyle(color: PdfColors.black),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: Dimens.dp8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Total daily bolus',
                            style: const pw.TextStyle(color: PdfColors.black),
                          ),
                          pw.Text(
                            '${0.toStringAsFixed(
                              2,
                            )} U/day',
                            style: const pw.TextStyle(color: PdfColors.black),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: Dimens.dp8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Total daily basal',
                            style: const pw.TextStyle(color: PdfColors.black),
                          ),
                          pw.Text(
                            '${0.toStringAsFixed(
                              2,
                            )} U/day',
                            style: const pw.TextStyle(color: PdfColors.black),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: Dimens.dp8),
                    ],
                  ),
                ),
                pw.Divider(),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(Dimens.appPadding),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Auto mode use',
                            style: const pw.TextStyle(color: PdfColors.black),
                          ),
                          pw.Text(
                            '${0.toStringAsFixed(
                              2,
                            )} %',
                            style: const pw.TextStyle(color: PdfColors.black),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: Dimens.dp8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Auto mode interrupted',
                            style: const pw.TextStyle(color: PdfColors.black),
                          ),
                          pw.Text(
                            '${data.autoModeIntterupted?.toStringAsFixed(
                              2,
                            )} %',
                            style: const pw.TextStyle(color: PdfColors.black),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: Dimens.dp8),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

    return await doc.save();
  }
}
